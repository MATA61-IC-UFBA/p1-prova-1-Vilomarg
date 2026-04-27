%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern int yylex();
extern int yylineno;
void yyerror(const char *msg);


typedef struct {
    char *name;
    int type; /* 0 = inteiro, 1 = string */
    int ival;
    char *sval;
} Symbol;

Symbol symtab[256];
int sym_count = 0;

/* Busca uma variável pelo nome */
Symbol* get_sym(char *name) {
    for(int i = 0; i < sym_count; i++) {
        if(strcmp(symtab[i].name, name) == 0) return &symtab[i];
    }
    return NULL;
}

/* Cria ou atualiza o valor de uma variável (Ex: a = 5 ou a = "oi") */
void set_sym(char *name, int type, int ival, char *sval) {
    Symbol *s = get_sym(name);
    if(!s) {
        s = &symtab[sym_count++];
        s->name = strdup(name);
    } else {
        if(s->type == 1 && s->sval) free(s->sval); /* Limpa a string antiga da memória */
    }
    s->type = type;
    if(type == 0) {
        s->ival = ival;
        s->sval = NULL;
    } else {
        s->ival = 0;
        s->sval = strdup(sval);
    }
}
%}

/* Define os "tipos" possíveis que um token ou regra pode retornar para cima */
%union {
    int ival;
    char *sval;
    struct {
        int type; /* 0 = int, 1 = string */
        int ival;
        char *sval;
    } val;
}

%token ERROR
%token <ival> NUM
%token <sval> IDENT STRING
%token PRINT CONCAT LENGTH ASSIGN LPAREN RPAREN COMMA
%token PLUS MINUS TIMES DIV

/* Tipando as regras da gramática */
%type <val> expr
%type <sval> str_list

/* Prioridade das contas matemáticas */
%left PLUS MINUS
%left TIMES DIV

%start program

%%

program
: stmt_list 
;

stmt_list
: stmt
| stmt_list stmt
;

/* Regras principais de ação */
stmt
: IDENT ASSIGN expr {
    set_sym($1, $3.type, $3.ival, $3.sval);
    free($1);
}
| PRINT LPAREN exprlist RPAREN {
    printf("\n"); /* Pula a linha depois de imprimir todos os itens */
}
| expr {
    /* Avalia a conta, mas como não tem print ou assign, apenas ignora o resultado */
}
;

/* Estrutura para print(a, b, c). Ele vai imprimindo na hora que lê! */
exprlist
: expr {
    if($1.type == 0) printf("%d", $1.ival);
    else if($1.type == 1) printf("%s", $1.sval);
}
| exprlist COMMA expr {
    if($3.type == 0) printf("%d", $3.ival);
    else if($3.type == 1) printf("%s", $3.sval);
}
;

/* Estrutura para concat("a", "b", 5). Acumula a string e joga pra cima */
str_list
: expr {
    if($1.type == 1) {
        $$ = strdup($1.sval);
    } else {
        char buf[64];
        sprintf(buf, "%d", $1.ival); /* Converte inteiro para texto pra conseguir juntar */
        $$ = strdup(buf);
    }
}
| str_list COMMA expr {
    char *s2;
    if($3.type == 1) {
        s2 = $3.sval;
    } else {
        char buf[64];
        sprintf(buf, "%d", $3.ival);
        s2 = buf;
    }
    $$ = malloc(strlen($1) + strlen(s2) + 1); /* Aloca o tamanho da união */
    strcpy($$, $1);
    strcat($$, s2);
    free($1); 
}
;

/* O Motor Matemático e de Texto */
expr
: NUM {
    $$.type = 0;
    $$.ival = $1;
    $$.sval = NULL;
}
| STRING {
    $$.type = 1;
    $$.ival = 0;
    $$.sval = strdup($1);
}
| IDENT {
    Symbol *s = get_sym($1);
    if(s) {
        $$.type = s->type;
        $$.ival = s->ival;
        $$.sval = s->type == 1 ? strdup(s->sval) : NULL;
    } else {
        $$.type = 0;
        $$.ival = 0;
        $$.sval = NULL;
    }
    free($1);
}
| expr PLUS expr { $$.type = 0; $$.ival = $1.ival + $3.ival; }
| expr MINUS expr { $$.type = 0; $$.ival = $1.ival - $3.ival; }
| expr TIMES expr { $$.type = 0; $$.ival = $1.ival * $3.ival; }
| expr DIV expr { 
    $$.type = 0; 
    if($3.ival != 0) $$.ival = $1.ival / $3.ival; 
    else { fprintf(stderr, "Divisao por zero\n"); $$.ival = 0; }
}
| LPAREN expr RPAREN { $$ = $2; }
| CONCAT LPAREN str_list RPAREN {
    $$.type = 1;
    $$.ival = 0;
    $$.sval = $3; /* O str_list já mastigou e nos devolveu a string concatenada completa! */
}
| LENGTH LPAREN expr RPAREN {
    $$.type = 0;
    $$.sval = NULL;
    if($3.type == 1 && $3.sval != NULL) {
        $$.ival = strlen($3.sval); /* Devolve tamanho da string */
    } else {
        $$.ival = 0; /* Se tentar tirar o tamanho de um inteiro, devolve 0 */
    }
}
;

%%

void yyerror(const char *msg) {
    fprintf(stderr, "Erro na prova: %s\n", msg);
}
