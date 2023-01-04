#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include <stdlib.h>
#include <ctype.h>
#define ROM_SIZE 1<<8

#define X 0
#define Y 1
void __citire(char *);
void __flags();
void __syntax();
void __compile(char *out_name);
int check_arg(int instr_index, int arg_index, char *arg);
int arg_type(char *arg);
char c[1000][100];
typedef struct{
    char *name;
    uint16_t addr;
}FLAG;
typedef struct{
    char *name;
    uint8_t bits;
    uint8_t argn;
    uint8_t args;
}INSTR;
FLAG flags[1000];
const INSTR instructions[34]={
    {"HLT", 0x00, 0, 0x00},
    {"ADD", 0x01, 2, 0x3F},
    {"SUB", 0x02, 2, 0x3F},
    {"LSR", 0x03, 2, 0x3F},
    {"LSL", 0x04, 2, 0x3F},
    {"RSR", 0x05, 2, 0x3F},
    {"RSL", 0x06, 2, 0x3F},
    {"MUL", 0x07, 2, 0x3F},
    {"DIV", 0x08, 2, 0x3F},
    {"MOD", 0x09, 2, 0x3F},
    {"AND", 0x0A, 2, 0x3F},
    {"OR" , 0x0B, 2, 0x3F},
    {"XOR", 0x0C, 2, 0x3F},
    {"NOT", 0x0D, 2, 0x3F},
    {"CMP", 0x0E, 2, 0x3F},
    {"TST", 0x0F, 2, 0x3F},
    {"INC", 0x10, 1, 0x30},
    {"DEC", 0x11, 1, 0x30},
    {"MOV", 0x12, 2, 0x3F},
    {"STR", 0x13, 2, 0x3F},
    {"LDR", 0x14, 2, 0x3F},
    {"BRZ", 0x15, 1, 0xC0},
    {"BRN", 0x16, 1, 0xC0},
    {"BRC", 0x17, 1, 0xC0},
    {"BRO", 0x18, 1, 0xC0},
    {"BRA", 0x19, 1, 0xC0},
    {"PSH", 0x1A, 1, 0xF0},
    {"POP", 0x1B, 1, 0xF0},
    {"JMP", 0x1C, 1, 0xC0},
    {"RET", 0x1D, 0, 0x00},
    {"OUT", 0x1E, 2, 0x3C},
    {"INP", 0x1E, 2, 0x3C},
    {"DAT", 0x1F, 1, 0xC0},
    {"NOP", 0x1F, 0, 0x00},
};
int ops[1000];
char *args[1000][2];
int n, flags_len;
int check_instr(char *c){
    int s=strlen(c);
    if(s>3||s<2)
        return -1;
    for(int i=0;i<34;i++){
        if(strcmp(c, instructions[i].name)==0)
            return i;
    }
    return -1;
}
int search_flag(char *c){
    for(int i=0;i<flags_len;i++){
        if(strcmp(c, flags[i].name)==0)
            return i;
    }
    return -1;
}
int check_valid_flag_name(char *flag){
    if(strcmp(flag, "X") ==0)
        return 0;
    if(strcmp(flag, "Y") ==0)
        return 0;
    if(check_instr(flag) != -1)
        return 0;
    if(isdigit(flag[0]))
        return 0;
    return 1;
}
uint8_t ishexnumber(char c){
    if(isdigit(c))
        return 1;
    if(c>='a' && c<='f')
        return 1;
    if(c>='A' && c<='F')
        return 1;
    return 0;
}
uint16_t opcode2(uint16_t instr, uint16_t imm){
    uint16_t res=instr<<10;
    res = res | (imm & 0x03FF);
    return res;
}
uint16_t opcode_reg(uint16_t instr, uint16_t reg1, uint16_t reg2){
    uint16_t res=instr<<11;
    res = res | 1<<10;
    res = res | (reg1<<9);
    res = res | (reg2<<8);
    return res;
}
uint16_t opcode_imm(uint16_t instr, uint16_t reg, uint16_t imm){
    uint16_t res=instr<<11;
    res = res & ~(1<<10);
    res = res | (reg<<9);
    res = res | (imm &  0x01FF);
    return res;
}
int main(int argc, char **argv){
    if(argc != 3){
        printf("Usage %s input output\n", argv[0]);
        return 0;
    }
    
    __citire(argv[1]);
    __flags();
    __syntax();
    __compile(argv[2]);
    return 0;
}
/*
Flag: Instr X, Y
Instr X, Imm
Instr X
Instr Imm
Instr

*/

void __flags(){
for(int i=0;i<n;i++){
        char *f=strchr(c[i], ':');
        if(f != NULL){
            char *flag_name=malloc(50);
            strncpy(flag_name, c[i], f-c[i]);
            flag_name[f-c[i]]=0;
            int flag_pos=search_flag(flag_name);
            if(flag_pos == -1){
                if(!check_valid_flag_name(flag_name)){
                    printf("Error on line %d: Invalid flag name '%s'\n", i+1, flag_name);
                    exit(0);
                }
                flags[flags_len].name = flag_name;
                flags[flags_len].addr = i;
                flags_len++;

            }else{
                printf("Error on line %d: Flag '%s' redefined on line %i\n", i+1, flag_name, 1+(flags[flag_pos].addr/2));
                exit(0);
            }
            f++;
            while(*f==' ')
            f++;
            int l=strlen(c[i])-(f-c[i]);
            int L=strlen(c[i]);
            for(int j=0;j<l;j++)
                c[i][j]=f[j];
            for(int j=l;j<L; j++)
               c[i][j]=0;

        }
    }
}
void __citire(char *nume){
    FILE *in=fopen(nume, "r");
    if(in==NULL){
        printf("eroare la deschiderea %s\n", nume);
        exit(0);
    }
    while(!feof(in)){
        fgets(c[n], 100, in);
        c[n][strlen(c[n])-1]=0;
        if(strlen(c[n])<3)
            continue;
        for(int i=0;i<strlen(c[n]); i++)
            c[n][i] = toupper(c[n][i]);
        n++;
    }
    fclose(in);
}
void __syntax(){
    for(int i=0;i<n;i++){

        if(check_instr(c[i]) != -1){
            ops[i] = check_instr(c[i]);
            continue;
        }
        char *f=strchr(c[i], ' ');
        if(f==NULL){
            printf("Illegal instruction on line %d: '%s'\n", i+1, c[i]);
            exit(0);
        }
        char *in=malloc(50);
        strncpy(in, c[i], f-c[i]);
        int instr_index=check_instr(in);
        if(instr_index == -1){
            printf("Illegal instruction '%s' on line %d: '%s'\n",in, i+1, c[i]);
            exit(0);
        }

            
        while((*f)==' ' && *f != 0)
        f++;
        char *a1=f;

        char *a2=NULL;
        if(a1 != NULL)
            a2=strchr(a1, ' ');
        if(a2 != NULL)
            while((*a2)==' ' && *a2 != 0)
                a2++;

        char *a3=NULL;
        if(a2 != NULL)
            a3=strchr(a2, ' ');
        if(a3 != NULL)
            while((*a3)==' ' && *a3 != 0)
                a3++;

        int num_args=0;
        if(a1!=NULL)
            num_args=1;
        if(a2 != NULL)
            num_args=2;
        if(a3 != NULL)
            num_args=3;
        if(num_args != instructions[instr_index].argn){
            printf("Error on line %d: %s\nInstruction %s only takes %d arguments\n", i+1, c[i], in, instructions[instr_index].argn);
            exit(0);
        }
        ops[i]=instr_index;
        if(num_args == 1){
            char *arg1=malloc(50);
            int j=0;
            while(1){
                if(*a1==' ' || *a1 == ',' || *a1==0){
                    arg1[j]=0;
                    break;
                }
                arg1[j]=*a1;
                a1++;
                j++;
            }
            if(check_arg(instr_index, 1, arg1)==0){
                printf("Error on line %d: %s\nArgument 1: '%s' is invalid for instruction %s\n", i+1, c[i], arg1, in);
                exit(0);
            }
            args[i][0]=arg1;
        }else{
            char *arg1=malloc(50);
            int j=0;
            while(1){
                if(*a1==' ' || *a1 == ',' || *a1==0){
                    arg1[j]=0;
                    break;
                }
                arg1[j]=*a1;
                a1++;
                j++;
            }
            char *arg2=malloc(50);
            j=0;
            while(1){
                if(*a2==' ' || *a2 == ',' || *a2==0){
                    arg2[j]=0;
                    break;
                }
                arg2[j]=*a2;
                a2++;
                j++;
            }
            if(check_arg(instr_index, 1, arg1)==0){
                printf("Error on line %d: %s\nArgument 1: '%s' is invalid for instruction %s\n", i+1, c[i], arg1, in);
                exit(0);
            }
            if(check_arg(instr_index, 2, arg2)==0){
                printf("Error on line %d: %s\nArgument 2: '%s' is invalid for instruction %s\n", i+1, c[i], arg2, in);
                exit(0);
            }
            args[i][0]=arg1;
            args[i][1]=arg2;
        }
    }
}
int check_arg(int instr_index, int arg_index, char *arg){
    int _imm=instructions[instr_index].args & (1<<(2+4*(2-arg_index)));
    int _reg=instructions[instr_index].args & (1<<(4*(2-arg_index)));
    int a_type=arg_type(arg);
    if(strcmp(instructions[instr_index].name, "DAT")==0){
        if(a_type<4)
            return 0;
        return a_type;
    }
    if((a_type==1 || a_type==2) && !_reg)
        return 0;
    if(a_type>2 && !_imm)
        return 0;
    return a_type;
}
//0 invalid, 1X, 2Y, 3FLAG, 4NUM, 5HEX
int arg_type(char *arg){
    if(strcmp(arg, "X") == 0)
        return 1;
    if(strcmp(arg, "Y") == 0)
        return 2;
    if(search_flag(arg) != -1)
        return 3;
    int hex=1;
    if(strlen(arg)<3)
        hex=0;
    if(hex)
        if(arg[0] != '0' || arg[1] != 'X')
            hex=0;
    if(hex){
        for(int i=2;i<strlen(arg);i++)
            if(!ishexnumber(arg[i]))
                return 0;
        return 5;
    }else{
        for(int i=0;i<strlen(arg);i++)
            if(!isdigit(arg[i]))
                return 0;
        return 4;
    }
    return 0;
}
void __compile(char *out_name){
    int total_size=0;
    FILE *out=fopen(out_name, "w");
    for(int i=0;i<n;i++){
        uint16_t fw=0;
        if(instructions[ops[i]].argn ==0){
            fw = instructions[ops[i]].bits<<11;
        }else if(strcmp(instructions[ops[i]].name, "DAT")==0){
            if(arg_type(args[i][0]) == 4)
                fw = (uint16_t)strtol(args[i][0], NULL, 10);
            else
                fw = (uint16_t)strtol(args[i][0], NULL, 0);
        }else if(strcmp(instructions[ops[i]].name, "OUT")==0 || strcmp(instructions[ops[i]].name, "INP")==0){
            fw = instructions[ops[i]].bits<<11;
            int at = arg_type(args[i][1]);
            if(strcmp(instructions[ops[i]].name, "OUT")==0)
                fw = fw | (1<<10);
            if(arg_type(args[i][0]) == 2)
                fw = fw | (1<<9);
            if(at == 1)
                fw = fw;
            if(at == 2)
                fw = fw | (1<<8);
            if(at == 3)
                fw = fw | (flags[search_flag(args[i][1])].addr & 0x01FF);
            if(at == 4)
                fw = fw | ((uint16_t)strtol(args[i][1], NULL, 10) & 0x01FF);
            if(at == 5)
                fw = fw | ((uint16_t)strtol(args[i][1], NULL, 0) & 0x01FF);
        }else if(instructions[ops[i]].argn == 1){
            fw = instructions[ops[i]].bits<<11;
            int at = arg_type(args[i][0]);
            if(at < 3)
                fw = fw | (1<<10);
            if(at == 1)
                fw = fw;
            if(at == 2)
                fw = fw | (1<<9);
            uint16_t mask=0x01FF;
            if(instructions[ops[i]].args == 0xC0)
                mask=0x03FF;
            if(at == 3)
                fw = fw | (flags[search_flag(args[i][0])].addr & mask);
            if(at == 4)
                fw = fw | ((uint16_t)strtol(args[i][0], NULL, 10) & mask);
            if(at == 5)
                fw = fw | ((uint16_t)strtol(args[i][0], NULL, 0) & mask);
        }else{
            fw = instructions[ops[i]].bits<<11;
            int at = arg_type(args[i][1]);
            if(at < 3)
                fw = fw | (1<<10);
            if(arg_type(args[i][0]) == 2)
                fw = fw | (1<<9);
            if(at == 1)
                fw = fw;
            if(at == 2)
                fw = fw | (1<<8);
            if(at == 3)
                fw = fw | (flags[search_flag(args[i][1])].addr & 0x01FF);
            if(at == 4)
                fw = fw | ((uint16_t)strtol(args[i][1], NULL, 10) & 0x01FF);
            if(at == 5)
                fw = fw | ((uint16_t)strtol(args[i][1], NULL, 0) & 0x01FF);
        }
        printf("0x%04x\n", fw);
        fprintf(out, "%04x ", fw);
        total_size++;
        // fwrite(&fw, 2, 1, out);
    }
    for(int i=total_size; i<(ROM_SIZE);i++){
        fprintf(out, "0000 ");
    }
    fprintf(out, "\n");
    fclose(out);
}