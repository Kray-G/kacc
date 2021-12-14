/* Calculator in Kacc. */

%{
using @kacc.Lexer;
%}

%token TOKEN_NUMBER TOKEN_IDENTIFIER

%left '+' '-'
%left '*' '/'

%%

start:    lines;

lines
    : line { $$ = $1; }
    | lines '\n' line { $$ = $3; }
    ;

line
    : assign  { $$ = $1; }
    | expr { $$ = $1; }
    | error { $$.value = "<error>"; }
    ;

assign
    : TOKEN_IDENTIFIER '=' expr { @setVar($1.value, $3.value); $$ = $3; }
    ;

expr
    : expr '+' expr { $$.value = $1.value + $3.value; }
    | expr '-' expr { $$.value = $1.value - $3.value; }
    | expr '*' expr { $$.value = $1.value * $3.value; }
    | expr '/' expr { $$.value = $1.value / $3.value; }
    | '(' expr ')' { $$ = $2; }
    | TOKEN_NUMBER { $$ = $1; }
    | TOKEN_IDENTIFIER { $$.value = @getVar($1.value); }
    ;

%%

/* Lexical analyzer */
var lexer = new Kacc.Lexer();
lexer.addSkip(/[ \t\r]+/);
lexer.addRule(/[_a-zA-Z][_a-zA-Z0-9]*/, TOKEN_IDENTIFIER);
lexer.addRule(/[0-9]+/, TOKEN_NUMBER) { &(value) => Integer.parseInt(value) };
lexer.addRule(/\/\*/) { &(value, this)
    ++@commentCount;
    return @$('COMMENT', KACC_LEXER_SKIP);
};
lexer.addStateRule('COMMENT', /\*\/|\/\*|./) { &(value, this)
    if (value.value == '/*') {
        ++@commentCount;
    }
    if (value.value == '*/') {
        if (--@commentCount == 0) {
            return @$(KACC_LEXER_STATE_INITIAL, KACC_LEXER_SKIP);
        }
    }
    return KACC_LEXER_SKIP;
};
// lexer.debugOn(lexer.DEBUG_STATE|lexer.DEBUG_TOKEN|lexer.DEBUG_VALUE);

/* Parser */
var vars = {};
var parser = new Kacc.Parser(lexer, {
    yyerror: &(msg)         => System.println(("ERROR! " + msg).red().bold()),
    setVar:  &(name, value) => vars[name] = value,
    getVar:  &(name)        => vars[name],
});

/* Parse expressions */
var exprs = [
    "2+3",
    "3 + 5 * 9",
    "(3 + 5) * 9",
    "c= /*comment*/ 24",
    "a 1",  // Syntax error
    "a= 10",
    "b=70+/* aaa /* nested comment is also available */*/a",
    "a+b+c",
];
exprs.each { &(expr)
    parser.parse(expr.trim()) { &(r)
        if (r.value != "<error>") {
            System.println(expr, " => ", r.value);
        }
    };
};
