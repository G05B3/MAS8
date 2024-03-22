#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX_LINE_LENGTH 128

void get_hexa(FILE *fp, int num)
{
    char hexa[2] = "\0";

    if (num < 0)
        num += 256;

    if (num < 16)
    {
        hexa[0] = '0';
        if (num < 10)
            hexa[1] = num + '0';
        else
            hexa[1] = num - 10 + 'A';
    }
    else
    {
        if (num / 16 < 10)
            hexa[0] = num / 16 + '0';
        else
            hexa[0] = num / 16 - 10 + 'A';
        if (num % 16 < 10)
            hexa[1] = num % 16 + '0';
        else
            hexa[1] = num % 16 - 10 + 'A';
    }
    fprintf(fp, "%s", hexa);
}

int get_opcode(char *op)
{
    if (!strcmp(op, "ADC"))
        return '0';
    else if (!strcmp(op, "ADD"))
        return '1';
    else if (!strcmp(op, "MUL"))
        return '2';
    else if (!strcmp(op, "SRA"))
        return '3';
    else if (!strcmp(op, "AND"))
        return '4';
    else if (!strcmp(op, "OR"))
        return '5';
    else if (!strcmp(op, "NOT"))
        return '6';
    else if (!strcmp(op, "XOR"))
        return '7';
    else if (!strcmp(op, "LW"))
        return '8';
    else if (!strcmp(op, "SW"))
        return '9';
    else if (!strcmp(op, "LT"))
        return 'C';
    else if (!strcmp(op, "LTC"))
        return 'D';
    else if (!strcmp(op, "JMP"))
        return 'F';
    else
        return -1;
}

void initial_print(FILE *fp)
{

    fprintf(fp, "; This .COE file specifies initialization values for a block\n; memory of depth=X and width=16.");
    fprintf(fp, "\n; Values are specified in hexadecimal format.\nmemory_initialization_radix=16;\nmemory_initialization_vector=\n");
}

int op_processing(FILE *fp, char *op, char *arg1, char *arg2, char *arg3, int mode, int ps)
{
    //printf("Found Instruction: %s\n",op);
    int regs = 0;

    if (op[0] == '#') // commented line
        return 1;

    if (ps == 1){ // Pseudo-Instructions
        if (!strcmp(op, "NOP")){ // <=> ADC R0,R0,0
            if (strcmp(arg2, "\0") != 0 || strcmp(arg3, "\0") != 0)
                return 3;
            for (int i = 0; i < atoi(arg1); i++)
                op_processing(fp, "ADC", "R0", "R0", "0", mode, 0);
            return 1;
        }
        else if (!strcmp(op, "SUB")){
            if (arg1[1] >= '0' && arg1[1] <= '3' && arg2[1] >= '0' && arg2[1] <= '3' && arg3[1] >= '0' && arg3[1] <= '3')
            { // Print registers RD and RA codes in hexa
                op_processing(fp, "NOT", arg3, arg3, "\0", mode, 0);
                op_processing(fp, "ADC", arg3, arg3, "1", mode, 0);
                op_processing(fp, "ADD", arg1, arg2, arg3, mode, 0);
                return 1;
            }
            else
            { // Syntax error
                fprintf(fp, "X\n");
                return 2;
            }
        }
        else if (!strcmp(op, "GE")){
            if (arg1[1] >= '0' && arg1[1] <= '3' && arg2[1] >= '0' && arg2[1] <= '3' && arg3[1] >= '0' && arg3[1] <= '3')
            { // Print registers RD and RA codes in hexa
                op_processing(fp, "ADC", arg3, arg3, "-1", mode, 0);
                op_processing(fp, "LT", arg1, arg3, arg2, mode, 0);
                op_processing(fp, "ADC", arg3, arg3, "1", mode, 0);
                return 1;
            }
            else
            { // Syntax error
                fprintf(fp, "X\n");
                return 2;
            }
        }
        else if (!strcmp(op, "GEC")){ // INCOMPLETO

            if (arg1[1] >= '0' && arg1[1] <= '3' && arg2[1] >= '0' && arg2[1] <= '3' && atoi(arg3) <= 127 && atoi(arg3) >= -128)
            { // Print registers RD and RA codes in hexa
                op_processing(fp, "NOT", arg2, arg2, "\0", mode, 0); // !RB = -(RB+1)
                char *C = (char*)malloc(sizeof(arg3)+1);
                if (C == NULL)
                    return 2;
                if (arg3[0] == '-'){
                    strncpy(C,arg3+1,sizeof(arg3));
                }
                else{
                    strncpy(C+1,arg3,sizeof(arg3));
                    C[0] = '-';
                }
                op_processing(fp, "LTC", arg1, arg2, C, mode, 0); // LTC RA,RB,-C
                free(C);
                op_processing(fp, "NOT", arg2, arg2, "\0", mode, 0); // Recover RB
                return 1;
            }
            else
            { // Syntax error
                fprintf(fp, "X\n");
                return 2;
            }
        }
    }


    if (!strcmp(op, "JMP"))
    { // JMP RD,C --> F[D*4][C]h
        if (strcmp(arg3,"\0") != 0)
            return 3;
        strcpy(arg3, arg2);
        strcpy(arg2, arg1);
        strcpy(arg1, "R0");
    }

    // Print Opcode in hexa
    if (get_opcode(op) != -1)
    {
        fprintf(fp, "%c", get_opcode(op));
        if (arg1[1] >= '0' && arg1[1] <= '3' && arg2[1] >= '0' && arg2[1] <= '3')
        { // Print registers RD and RA codes in hexa
            regs = 4 * (arg1[1] - 48) + arg2[1] - 48;
            if (regs < 10)
                fprintf(fp, "%c", regs + '0');
            else
                fprintf(fp, "%c", regs + 'A' - 10);
        }
        else
        { // Syntax error
            fprintf(fp, "X\n");
            return 2;
        }
    }
    else
    { // Syntax error
        fprintf(fp, "X\n");
        return 0;
    }

    if (!strcmp(op, "ADD") || !strcmp(op, "MUL") || !strcmp(op, "SRA") || !strcmp(op, "AND") || !strcmp(op, "OR") || !strcmp(op, "XOR") || !strcmp(op, "LT"))
    {

        fprintf(fp, "0");
        if (arg3[1] >= '0' && arg3[1] <= '3')
        {
            fprintf(fp, "%c", arg3[1]);
            if (mode)
                fprintf(fp, ",");
            fprintf(fp, "\n");
        }
        else
        {
            fprintf(fp, "X\n");
            return 2;
        }
    }
    else if (!strcmp(op, "ADC") || !strcmp(op, "LW") || !strcmp(op, "SW") || !strcmp(op, "LTC") || !strcmp(op, "JMP"))
    {
        if (atoi(arg3) <= 127 && atoi(arg3) >= -128)
            get_hexa(fp, atoi(arg3));
        else
            return 2;
        if (mode)
            fprintf(fp, ",");
        fprintf(fp, "\n");
    }
    else if (!strcmp(op, "NOT"))
    {
        if (strcmp(arg3,"\0") != 0)
            return 3;
        fprintf(fp, "00");
        if (mode)
            fprintf(fp, ",");
        fprintf(fp, "\n");
    }

    return 1;
}

int main(int argc, char *argv[])
{

    if (argc != 2 && argc != 3 && argc != 4 && argc != 5)
        exit(0);
    if ((argc >= 3 && strcmp(argv[2], "-coe") != 0 && strcmp(argv[2], "-h") != 0)
        || (argc >= 4 && strcmp(argv[3], "-v") != 0 && strcmp(argv[3], "-e") != 0 && strcmp(argv[3], "-ps") != 0
        && strcmp(argv[3], "-verbose") != 0 && strcmp(argv[3], "-extra") != 0)
        || (argc == 5 && strcmp(argv[4], "-v") != 0 && strcmp(argv[4], "-e") != 0 && strcmp(argv[4], "-ps") != 0
        && strcmp(argv[4], "-verbose") != 0 && strcmp(argv[4], "-extra") != 0))
    {
        printf("Wrong program invocation. Program should be called: ./[program] [file] [OPTIONAL: -coe / -h]\n");
        exit(0);
    }
    FILE *fp = fopen(argv[1], "r+");
    char *filename = (char *)malloc((strlen(argv[1]) + 5) * sizeof(char));
    strcpy(filename, argv[1]);
    if (argc >= 3 && !strcmp(argv[2], "-h"))
    {
        filename[strlen(filename) - 4] = '.';
        filename[strlen(filename) - 3] = 'h';
        filename[strlen(filename) - 2] = 'e';
        filename[strlen(filename) - 1] = 'x';
        filename[strlen(filename)] = '\0';
    }
    else
    {
        filename[strlen(filename) - 4] = '.';
        filename[strlen(filename) - 3] = 'c';
        filename[strlen(filename) - 2] = 'o';
        filename[strlen(filename) - 1] = 'e';
        filename[strlen(filename)] = '\0';
    }
    FILE *out = fopen(filename, "w+");

    if (fp == NULL)
    {
        printf("Could not open input file.\n");
        exit(0);
    }
    if (out == NULL)
    {
        printf("Could not open output file.\n");
        exit(0);
    }

    if (argv[1][strlen(argv[1]) - 4] != '.' || argv[1][strlen(argv[1]) - 3] != 'm' || argv[1][strlen(argv[1]) - 2] != 'a' || argv[1][strlen(argv[1]) - 1] != 's')
    {
        printf("Input file isn't a MAS file!\n");
        exit(0);
    }

    int i, check, l = 1;
    int verbose = 0, pseudoinstructions = 0;
    char line[MAX_LINE_LENGTH] = "\0";
    char token_collection[5][MAX_LINE_LENGTH];

    if ((argc >= 4 && (!strcmp(argv[3], "-verbose") || !strcmp(argv[3], "-v")))
        || (argc >= 5 && (!strcmp(argv[4], "-verbose") || !strcmp(argv[4], "-v"))))
        verbose = 1;   
    if ((argc >= 4 && (!strcmp(argv[3], "-extra") || !strcmp(argv[3], "-e") || !strcmp(argv[3], "-ps")))
        || (argc == 5 && (!strcmp(argv[4], "-extra") || !strcmp(argv[4], "-e") || !strcmp(argv[4], "-ps"))))
        pseudoinstructions = 1;    

    if (argc == 2 || !strcmp(argv[2], "-coe"))
        initial_print(out);

    for (int k = 0; k < 5; k++)
        memset(token_collection[k],0, sizeof(token_collection[k]));

    // Reading each instruction
    while (fgets(line, MAX_LINE_LENGTH, fp) != NULL)
    {
        //printf("Reading Line: %s\n",line);
        char *token = strtok(line, " ");
        strcpy(token_collection[0], token);
        i = 0;
        // Iterate through the tokens and print each one
        while (token != NULL)
        {
            //printf("token is %s\n",token);
            char* chr_id;
            if ((chr_id = strchr((token), '#')) != NULL){
                *chr_id = 0;
                //strcpy(token_collection[++i], token);
                break;
            }
            //printf("token is %s\n",token);
            token = strtok(NULL, ",");
            if (token != NULL && *token != '#' && i <= 3) // i <= 3 to take care of in-line comments
                strcpy(token_collection[++i], token);
            if (token != NULL && *token == '#')
                break;
        }
        if (i > 3)
            check = 3;
        else if (i > 1 || !strcmp(token_collection[0], "NOP"))
            check = op_processing(out, token_collection[0], token_collection[1], token_collection[2], token_collection[3],
                                    argc == 2 || !strcmp(argv[2], "-coe"), pseudoinstructions);
        else
            continue;
            
        if (!check)
        { // Syntax Error
            remove(filename);
            printf("Syntax Error on instruction %d.\n", l);
            exit(0);
        }
        else if (check == 2) 
        { // Invalid Operand
            remove(filename);
            printf("Invalid Operand on instruction %d.\n", l);
        }
        else if (check == 3){ // Wrong Number of Operands
            remove(filename);
            printf("Wrong Number of Operands on instruction %d.\n", l);
        }
        l++;

        for (int k = 0; k < 5; k++)
            memset(token_collection[k],0, sizeof(token_collection[k]));
    }

    if ((argc >= 3 && !strcmp(argv[2], "-coe")) || argc == 2)
    {
        fseek(out, -2, SEEK_CUR);
        fprintf(out, ";");
    }

    fclose(out);
    fclose(fp);
    free(filename);
    return 0;
}
