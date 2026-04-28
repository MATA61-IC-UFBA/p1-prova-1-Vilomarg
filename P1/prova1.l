%{
#include "prova1.tab.h"
#include <stdlib.h>
#include <string.h>


void yyerror(const char *msg);
%}

%option noyywrap
%option yylineno

%%

"//".* { /* Ignora comentários de linha // */ }
[ \t\n\r]+              { /* Ignora espaços e quebras de linha */ }

"print"                 { return PRINT; }
"concat"                { return CONCAT; }
"length"                { return LENGTH; }

[0-9]+                  { 
                          yylval.ival = atoi(yytext); 
                          return NUM; 
                        }

\"[^\n"]*\"             { 
                          /* Remove as aspas das bordas */
                          yytext[yyleng-1] = '\0'; 
                          yylval.sval = strdup(yytext+1); 
                          return STRING; 
                        }

[a-zA-Z_][a-zA-Z0-9_]* { 
                          yylval.sval = strdup(yytext); 
                          return IDENT; 
                        }

"="                     { return ASSIGN; }
"("                     { return LPAREN; }
")"                     { return RPAREN; }
","                     { return COMMA; }
"+"                     { return PLUS; }
"-"                     { return MINUS; }
"*"                     { return TIMES; }
"/"                     { return DIV; }

.                       { return ERROR; }

%%
