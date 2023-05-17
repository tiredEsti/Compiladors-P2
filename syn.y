%{
	#include <stdio.h>
	#include <stdlib.h>
	#include <string.h>
	#include <stdbool.h>
	#include <math.h>
	#include <stdarg.h>
	#include "syn.tab.h"

	#define MAX_QUADS 500

	int errflag = 0;
	int temp = 1;
	int gdb = 0;			//used for debugging

	quad *quad_list;


	int currQuad = 0;

	extern FILE* yyin;
	extern int yylineno;

	extern int yywrap( );
	extern int yylex();
	extern void yyerror(char *explanation);

	FILE* flog;

	int yyterminate()
	{
	  return 0;
	}



	void addQuad(int num_args, ...);	
	variable arithmeticCalc(variable v1, char* op, variable v2);
	void yyerror(char *explanation);
	variable powFunction(variable v1, variable v2);
	char *newTemp();
	void printQuads();
%}

%code requires {
  	#include "symtab.h"
	#include "structs.h"
}

%union {
    variable var;
};

%token <var> FL INT ID A_ID ADD SUB MUL DIV MOD POW
%token ASSIGN LPAREN RPAREN EOL END SCOMMENT MCOMMENT LERR REPEAT DO DONE
%type <var> statement statement_list arithmetic_op1 arithmetic_op2 arithmetic_op3 exp arithmetic flow_statementStart flow_statementEnd id

%start program

%%
program : statement_list;

statement_list : statement_list statement | statement | statement_list flow_statementStart | flow_statementStart | statement_list flow_statementEnd;

flow_statementStart: REPEAT exp {
	
	
	if($2.type == UNDEFINED){
		$$.type = UNDEFINED;
		yyerror($2.place);
		yylineno++;
	} else {
		
		if($2.type == FLOAT){
			$$.type = UNDEFINED;
			yyerror("SEMANTIC ERROR: Loop initiation error detected. Invalid operation for float\n");
			yylineno++;
		} else {

			fprintf(flog, "Line %d, LOOP START\n", yylineno); 
			yylineno++;
			$$ = $2;
			$$.ctr = (char *)malloc(100);
			strcpy($$.ctr, newTemp());
			addQuad(2, $$.ctr, "0");
			$$.repeat = currQuad +1;
		}
	}											
};

flow_statementEnd: flow_statementStart DO EOL statement_list DONE {
	fprintf(flog, "Line %d, LOOP END\n", yylineno); 
	
	if($1.type == UNDEFINED){}
	else if($4.type == UNDEFINED){
		$$.type = UNDEFINED;
		yyerror("SEMANTIC ERROR: Error in loop error detected.\n");
	} else{
		if($1.type == INTEGER) addQuad(4, $1.ctr, "ADDI", $1.ctr, "1");
		else addQuad(4, $1.ctr, "ADDF", $1.ctr, "1");
		
		char str[20];
		sprintf(str, "%d", $1.repeat);
		if ($1.type == INTEGER)	{
			addQuad(4, $1.ctr, "LTI", $1.place, str);
		} else {
			addQuad(4, $1.ctr, "LTF", $1.place, str);
		}
	}
};

statement: id ASSIGN exp 	{	
									if($3.type == UNDEFINED){
										yyerror($3.place);
									} else {
										
										$3.name = (char *)malloc(100);
										strcpy($3.name, $1.name);
										sym_enter($1.name, &$3);
										addQuad(2, $1.name, $3.place);
										fprintf(flog, "Line %d, ASSIGNATION %s := %s\n", yylineno, $1.name, $3.place); 
									}
									yylineno++; 
								}
		| id ASSIGN exp EOL	{	
									if($3.type == UNDEFINED){
										yyerror($3.place);
									} else {
										
										$3.name = (char *)malloc(100);
										strcpy($3.name, $1.name);
										sym_enter($1.name, &$3);
										addQuad(2, $1.name, $3.place);
										fprintf(flog, "Line %d, ASSIGNATION %s := %s\n", yylineno, $1.name, $3.place); 
									}
									yylineno++; 
								}
		| id EOL				{	
									if($1.type == UNDEFINED){
										yyerror($1.place);
									} else {	
												
											if(sym_lookup($1.name, &$1) == SYMTAB_NOT_FOUND) {	
												yyerror("SEMANTIC ERROR: VARIABLE NOT FOUND.\n"); errflag = 1; YYERROR;
											} 
											else { 
												addQuad(2, "PARAM", $1.name);
												fprintf(flog, "Line %d, PARAM %s set\n", yylineno, $1.name);

												if($1.type == INTEGER){
													addQuad(3, "CALL", "PUTI", "1");
													fprintf(flog, "Line %d, calling PUTI\n", yylineno);
												}
												else{
													addQuad(3, "CALL", "PUTF", "1");
													fprintf(flog, "Line %d, calling PUTF\n", yylineno);
												}
											}
										}	
									yylineno++;
								}
		| EOL					{yylineno++;}
		| SCOMMENT			{ fprintf(flog, "Line %d, SINGLE LINE COMMENT DETECTED\n", yylineno);yylineno++; }
		| MCOMMENT			{ fprintf(flog, "Line %d, MULTIPLE LINE COMMENT DETECTED\n", yylineno);yylineno++; }
		| END					{fprintf(flog, "Line %d, End of the file, execution COMPLETED\n", yylineno); YYABORT;}
		| LERR EOL			{yyerror("LEXICAL ERROR: invalid character.\n"); $$.type = UNDEFINED; yylineno++; }
		| LERR 				{yyerror("LEXICAL ERROR: invalid character.\n");$$.type = UNDEFINED; } 
		| error	EOL			{	$$.type = UNDEFINED;
								if (errflag == 1){ errflag = 0;}
								else {	//printf("\tSYNTAX ERROR: no matching rule found\n");
    									fprintf(flog,"\tSYNTAX ERROR: no matching rule found\n");} yylineno++;};
id: ID | A_ID;

exp: arithmetic;

arithmetic: arithmetic_op1 | arithmetic ADD arithmetic_op1	{$$ = arithmeticCalc($1, "+", $3);}
		| arithmetic SUB arithmetic_op1 					{$$ = arithmeticCalc($1, "-", $3);}
		| ADD arithmetic_op1								{($$ = $2);}
		| SUB arithmetic_op2								{	$$.type = $2.type;
																$$.place = (char *)malloc(5);
																strcpy($$.place, newTemp());
																if($2.type == INTEGER) addQuad(3, $$.place, "CHSI", $2.place);
																else addQuad(3, $$.place, "CHSF", $2.place);
															};

arithmetic_op1: arithmetic_op2 | arithmetic_op1 MUL arithmetic_op2 	{$$ = arithmeticCalc($1, "*", $3);}
		| arithmetic_op1 DIV arithmetic_op2 						{$$ = arithmeticCalc($1, "/", $3);}
		| arithmetic_op1 MOD arithmetic_op2							{$$ = arithmeticCalc($1, "%", $3);};

arithmetic_op2: arithmetic_op3 | arithmetic_op2 POW arithmetic_op3	{$$ = arithmeticCalc($1, "**", $3);};

arithmetic_op3: LPAREN arithmetic RPAREN	{$$ = $2;}
			| INT 							{ 	if($1.type == UNDEFINED){
													yyerror($1.name);
												} else $$ = $1;
											}
		| FL								{ 	if($1.type == UNDEFINED){
													yyerror($1.name);
												} else $$ = $1;
											}
		| A_ID								{ 	if(sym_lookup($1.name, &$1) == SYMTAB_NOT_FOUND) {	yyerror("SEMANTIC ERROR: VARIABLE NOT FOUND.\n");errflag = 1; $$.type = UNDEFINED; YYERROR;} 
												else { $$.type = $1.type; $$.place = (char *)malloc(100);strcpy($$.place, $1.name); $$.name = (char *)malloc(100);strcpy($$.name, $1.name);}}
		|ID								{ 	if(sym_lookup($1.name, &$1) == SYMTAB_NOT_FOUND) {	yyerror("SEMANTIC ERROR: VARIABLE NOT FOUND.\n"); errflag = 1; $$.type = UNDEFINED; YYERROR;} 
												else { $$.type = $1.type; $$.place = (char *)malloc(50); strcpy($$.place, $1.name); $$.name = (char *)malloc(100);strcpy($$.name, $1.name);}}



		| LERR EOL			{$$.type = UNDEFINED; yyerror("LEXICAL ERROR: invalid character.\n"); yylineno++; }
		| LERR 				{$$.type = UNDEFINED; yyerror("LEXICAL ERROR: invalid character.\n");} 
		| error	EOL			{	$$.type = UNDEFINED;
								if (errflag == 1){ errflag = 0;}
								else {	//printf("\tSYNTAX ERROR: no matching rule found\n");
    									fprintf(flog,"\tSYNTAX ERROR: no matching rule found\n");} yylineno++;};


%%

void yyerror(char *explanation){
    if (strcmp(explanation, "End of the file, execution COMPLETED\n") == 0){
    	//printf("%s", explanation);
    	fprintf(flog,"%s", explanation);
    } else{ 
    	//printf("Line %d\t%s", yylineno, explanation);
    	fprintf(flog,"Line %d\t%s", yylineno, explanation);
    }
}

void addQuad(int num_args, ...) {
  va_list args;
  va_start(args, num_args);
  quad q;
  q.one = (char *)malloc(100);
  q.two = (char *)malloc(100);
  q.three = (char *)malloc(100);
  q.four = (char *)malloc(100);
  if (num_args > 0) strcpy(q.one, va_arg(args, char*));
  if (num_args > 1) strcpy(q.two, va_arg(args, char*));
  if (num_args > 2) strcpy(q.three, va_arg(args, char*));
  if (num_args > 3) strcpy(q.four, va_arg(args, char*));
  quad_list[currQuad] = q;
  currQuad++;
  va_end(args);
 
}




char *newTemp() {
  char tempString[50];
  sprintf(tempString, "$t%d", temp);
  temp++;
  char *tempPointer = tempString;
  return tempPointer;
}


variable arithmeticCalc(variable v1, char *op, variable v2) {
    
    variable result = {.type = UNDEFINED};
    result.place = (char *)malloc(100);
    if(strcmp(op, "**")==0){
    	result = powFunction(v1, v2);
    	return result;
    } 

    if (v1.type == INTEGER && v2.type == INTEGER) {
        result.type = INTEGER;
        strcpy(result.place, newTemp());
        if (strcmp(op, "+") == 0) {
            addQuad(4, result.place, v1.place, "ADDI", v2.place);
        } else if (strcmp(op, "-") == 0) {
            addQuad(4, result.place, v1.place, "SUBI", v2.place);
        } else if (strcmp(op, "*") == 0) {
            addQuad(4, result.place, v1.place, "MULI", v2.place);
        } else if (strcmp(op, "/") == 0) {
            if(strcmp(v2.place, "0") == 0)
            {
                result.type = UNDEFINED;
                strcpy(result.place, "SEMANTIC ERROR: Division by zero\n");
                return result;
            }
            addQuad(4, result.place, v1.place, "DIVI", v2.place);
        } else if (strcmp(op, "%") == 0) {
            addQuad(4, result.place, v1.place, "MODI", v2.place);
        }
    } else if ((v1.type == INTEGER || v1.type == FLOAT) && (v2.type == INTEGER || v2.type == FLOAT)) {
        result.type = FLOAT;

        char * chTemp = (char *)malloc(100);
        strcpy(chTemp, newTemp());
        if (v1.type == INTEGER) {
            addQuad(3, chTemp, "I2F", v1.place);
            v1.type = FLOAT;
            strcpy(v1.place, chTemp);
        } 
        if (v2.type == INTEGER) {
            addQuad(3, chTemp, "I2F", v2.place);
            v2.type = FLOAT;
            strcpy(v2.place, chTemp);
        }
        strcpy(result.place, newTemp());
		if (strcmp(op, "+") == 0) {
			addQuad(4, result.place, v1.place, "ADDF", v2.place);
		} else if (strcmp(op, "-") == 0) {
			addQuad(4, result.place, v1.place, "SUBF", v2.place);
		} else if (strcmp(op, "*") == 0) {
			addQuad(4, result.place, v1.place, "MULF", v2.place);
		} else if (strcmp(op, "/") == 0) {
			if(strcmp(v2.place, "0") == 0)
			{
				result.type = UNDEFINED;
                strcpy(result.place, "SEMANTIC ERROR: Division by zero\n");
                return result;
			}
			addQuad(4, result.place, v1.place, "DIVF", v2.place);
		} else if (strcmp(op, "%") == 0) {
			result.type = UNDEFINED;
            strcpy(result.place, "SEMANTIC ERROR: Invalid operation for float type.\n");
            return result;
		} 
    } else {
		result.type = UNDEFINED;
        strcpy(result.place, "SEMANTIC ERROR: Invalid type for arithmetic operation.\n");
        return result;
	}
	fprintf(flog, "Line %d, OPERATION %s stored in %s SUCCESS\n", yylineno, op, result.place);
	return result;
}

variable powFunction(variable v1, variable v2) {
  fprintf(flog, "Line %d, POW OPERATION DETECTED\n", yylineno);
  variable result;
  result.place = (char *)malloc(100);
  if (v2.type != INTEGER) {
    result.place = "SEMANTIC ERROR: Invalid operation for float type.\n";
    result.type = UNDEFINED;
    return result;
  }

  int v2_int = atoi(v2.place);
  char * prevResult = (char *)malloc(100);

  result.type = v1.type;
  strcpy(result.place, newTemp());

  int i;
  for (i = 1; i < v2_int; i++) {
  	fprintf(flog, "POW LOOP %d\n", i);
  	strcpy(prevResult, result.place);
  	strcpy(result.place, newTemp());
    addQuad(4, result.place, v1.place, "*", prevResult);
  }

  return result;
}


void printQuads(){
	fprintf(flog, "Line %d, Printing intermediate code\n", yylineno);
	
	if (currQuad == 0) {
  		printf("quad_list is empty\n");
  		return;
	}
	int i;
	for (i= 0; i < currQuad; i++) {
   		quad *q = &quad_list[i];
   		if (strcmp(q->one, "PARAM") == 0){
   			printf("%d: PARAM %s\n", i+1, q->two);
   		} else if (strcmp(q->one, "CALL") == 0){
   			printf("%d: CALL %s, %s\n", i+1, q->two, q->three);
   		} else if (strcmp(q->two, "I2F") == 0){
   			printf("%d: %s := I2F %s\n", i+1, q->one, q->three);
   		} else if (strcmp(q->two, "CHSI" ) == 0){
   			printf("%d: %s := CHSI %s\n", i+1, q->one, q->three);
   		} else if (strcmp(q->two, "CHSF" ) == 0){
   			printf("%d: %s := CHSF %s\n", i+1, q->one, q->three);
   		} else if (q->two[0] == 'L' && q->two[1] == 'T'){
   			printf("%d: IF %s %s %s GOTO %s\n", i+1, q->one, q->two, q->three, q->four);
   		} else if (q->one[0] == '$'){
   			printf("%d: %s := %s %s %s\n", i+1, q->one, q->two, q->three, q->four);
   		} else {
   			printf("%d: %s := %s\n", i+1, q->one, q->two);
   		}

	}

	printf("%d: HALT\n", i+1);
	
}



int main(int argc, char** argv) {
    flog = fopen("log.txt", "w");
    if(flog == NULL){
        printf("Error: Unable to open log file log.txt\n");
        return 1;
    }

    if (argc > 1) {
        yyin = fopen(argv[1], "r");
        if (yyin == NULL) {
            printf("Error: Unable to open file %s\n", argv[1]);
            return 1;
        }
    }
    else {
        printf("Error: No input file specified\n");
        return 1;
    }
    
    quad_list = (quad *)malloc(sizeof(quad) * MAX_QUADS);
    yyparse();
    printQuads();
    free(quad_list);
    if(fclose(flog) != 0){
        printf("Error: Unable to close log file log.txt\n");
        return 1;
    }

    return 0;
}