%{
    #include <stdio.h>
    #include "strutture.h"
	int yylex(void);
    void yyerror(char *);
    
    nodeType *opr(int oper, int nops, ...);
    nodeType *con( valueU d, typeData tipo);
    
    nodeType *id (char * nome);
    nodeType *tipo(typeData t);
    
    
	entry table[DIM];
	int size = 0;
%}

%union {
    int iValue;
    char* sName;
    double rValue;
    nodeType * nPtr;
};

%token <iValue> INTEGER BOOL       
%token <sName> VARIABLE T_INT T_REAL T_BOOL
%token <rValue> REAL
%token WHILE IF PRINT 
%nonassoc IFX
%nonassoc UMINUS
%nonassoc ELSE

%left GE LE EQ NE '>' '<'
%left '+' '-'
%left '*' '/'

%type <nPtr> stmt expr type function program

%%


program: 
    function   {printf("sono un bravo parser\n");}
    ;

function:
    function stmt				
    | stmt
    ;

expr:  
    VARIABLE						{ $$ = id($1); }				
    | INTEGER					{ 
    									valueU tmp;
    									tmp.ivalue = $1;
    									$$ = con(tmp,t_int); 
    								}
    | BOOL						{ 
    									valueU tmp;
    									tmp.bvalue = $1;
    									$$ = con(tmp,t_bool); 
    								}
    | REAL						{ 
    									valueU tmp;
    									tmp.rvalue = $1;
    									$$ = con(tmp,t_real); 
    								}
    | expr '+' expr				{ $$ = opr('+',2,$1,$3); }
    | expr '-' expr				{ $$ = opr('-',2,$1,$3); }
    | expr '*' expr				{ $$ = opr('*',2,$1,$3); }
    | expr '/' expr				{ $$ = opr('/',2,$1,$3); }
    | '-' expr %prec UMINUS		{ $$ = opr(UMINUS,1,$2); }
    | expr '<' expr         		{ $$ = opr('<',2,$1,$3); }
    | expr '>' expr         		{ $$ = opr('>',2,$1,$3); }
    | expr GE expr          		{ $$ = opr(GE,2,$1,$3); }
    | expr LE expr          		{ $$ = opr(LE,2,$1,$3); }
    | expr NE expr         		{ $$ = opr(NE,2,$1,$3); }
    | expr EQ expr				{ $$ = opr(EQ,2,$1,$3); }
    | '(' expr ')'				{ $$ = $2; }
    ;

type: 
    T_INT						{ $$ = tipo(t_int); }
    | T_BOOL						{ $$ = tipo(t_bool); }
    | T_REAL						{ $$ = tipo(t_real); }
    ;

stmt: 
    expr ';'								{ $$ = $1; }
    | '{' function '}'					{ $$ = $2; }
    | ';'								{ $$ = opr(';',2,NULL,NULL); }
    | PRINT expr ';'						{ $$ = opr(PRINT,1,$2); }
    | VARIABLE '=' expr ';'				{ $$ = opr('=',2,id($1),$3); }
    | type VARIABLE ';'					{ $$ = opr('D',2,$1,id($2)); }
    | WHILE '(' expr ')' stmt			{ $$ = opr(WHILE,2,$3,$5); }
    | IF '(' expr ')' stmt %prec IFX		{ $$ = opr(IF,2,$3,$5); }
    | IF '(' expr ')' stmt ELSE stmt    	{ $$ = opr(IF,3,$3,$5,$7); }
	;

%%


nodeType *con( valueU d, typeData tipo){
    nodeType *p;
    /* allocate node space in memory */
    if((p=malloc(sizeof(nodeType))) == NULL){
        yyerror("out of memory");
    }
    /* copy information */
    p->type = typeCon;
    p->con.tipo = tipo;
    switch (tipo) {
		case (t_int): p->con.ivalue = d.ivalue;
			break;
		case (t_bool): p->con.bvalue = d.bvalue;
			break;
		case (t_real): p->con.rvalue = d.rvalue;
			break;
	}

    return p;
}

nodeType *id (char * nome){
    nodeType *p;
    if((p=malloc(sizeof(nodeType))) == NULL){
        yyerror("out of memory");
    }
    p->type = typeId;
    p->id.index = cerca(nome);
    return p;
}

nodeType *tipo(typeData t){
	nodeType *p;
    if((p=malloc(sizeof(nodeType))) == NULL){
        yyerror("out of memory");
    }
    p->type = typeType;
    p->ty.type = t;
    return p;
}

nodeType *opr(int oper, int nops, ...){
    va_list ap; /* (ap = argument pointer) va_list is used to declare a variable
                 which, from time to time, is referring to an argument*/
    nodeType *p;
    int i;

    if ((p = malloc(sizeof(nodeType))) == NULL){
        yyerror("out of memory");
    }
    if((p->opr.op = malloc(nops*sizeof(nodeType)))== NULL){
        yyerror("out of memory");
    }
    p->type = typeOpr;
    p->opr.oper = oper;
    p->opr.nops = nops;
    va_start(ap, nops);/* initialize the sequence, makes ap point to the first
                        anonymous argument. Must call it once before reading all
                        the parameters*/
    for(i = 0; i<nops;i++){
        p->opr.op[i]=va_arg(ap,nodeType*); 
    }
    va_end(ap); /* MUST be called BEFORE THE FUNCTION TERMINATES. it provides
                 the necessary cleaning functions.*/


    return p;
}

void yyerror(char * s){
  fprintf(stderr, "%s\n",s);
}

int main(void){
  yyparse();
  return 0;
}