%{
  #include <stdio.h>
  #include <stdlib.h>
  #include "structs.h"
  #include "symtab.h"
  extern FILE *yyin;
  extern FILE* yyout;
  #include "syn.tab.h"

%}

%option noyywrap
%x IN_COMMENT

int [0-9]*
float [0-9]*\.[0-9]*([eE][-+]?[0-9]+)?
string \".*\"



%%
"repeat"  {return REPEAT;}
"do"      {return DO;}
"done"    {return DONE;}

{float} {
  yylval.var.type = FLOAT;
  yylval.var.place = (char *)malloc(sizeof(char)*yyleng+1);
  strncpy(yylval.var.place, yytext, yyleng+1);
  return FL;
}
{int} {
  yylval.var.type = INTEGER;
  yylval.var.place = (char *)malloc(sizeof(char)*yyleng+1);
  strncpy(yylval.var.place, yytext, yyleng+1);
  return INT;
}

":="            { return ASSIGN; }
"+"             { return ADD; }
"-"             { return SUB; }
"*"             { return MUL; }
"/"             { return DIV; }
"%"             { return MOD; }
"**"            { return POW; }
"("             { return LPAREN; }
")"             { return RPAREN; }



"\n"            { return EOL; }
"\t"            {}
"\r"            {}
" "             {}



"//".*"\n"       { return SCOMMENT; }                  /* one line comments */



<INITIAL>{
"/*"            BEGIN(IN_COMMENT);
}
<IN_COMMENT>{
"*/"            BEGIN(INITIAL);
[^*\n]+                             /* eat comment in chunks */
"*"                                 /* eat the lone star */
\n    { return MCOMMENT;}
}

[a-zA-Z0-9]*   { yylval.var.name = (char *)malloc(sizeof(char)*yyleng+1);
                  strncpy(yylval.var.name, yytext, yyleng+1);
                  variable aux;
                  if (sym_lookup(yytext, &aux) == SYMTAB_NOT_FOUND){
                    return ID;
                  } 
                  else return A_ID;
              }


. {return LERR;}


<<EOF>>                 { return END; }

%%