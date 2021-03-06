# Kacc

Yacc & Lex for Kinx.

## Introduction

`Kacc` is an LALR(1) parser generator based on [`kmyacc`](https://github.com/Kray-G/kmyacc).
Moreover, a lexical analyzer is already included in this project.
Therefore you can start developing a parser with a lexer very quickly.

Note that `Kacc` is published under MIT license, but `kmyacc` is licensed by GPLv2.
`Kacc` is just including `kmyacc` as just a binary, so the license is separated.

## Installation

Use `kip` to install `Kacc` because `Kacc` is provided as a package of `Kinx`.

```
$ kip install kacc
```

## How To Use

### Command Line

Use the `kacc` command with some options if necessary to generate your own parser.

```
$ kacc [-vltpod] parser.y
```

* The generated parser will be outputted to the `parser.kx` file.
* If you want to see the detail of a state, use `-v` to output the `parser.output` file.
* If you want to debug it, use `-t` to make it be able to run with a debug mode.

### Options

`kacc` has the following options.

|  Option   |                                              Meaning                                               |
| --------- | -------------------------------------------------------------------------------------------------- |
| `-v`      | Generates the file of `parser.output` which contains human-readable parser tables and diagnostics. |
| `-l`      | Does not insert #line control directives in `parser.kx`.                                           |
| `-t`      | Generates a debugging code.                                                                        |
| `-p XX`   | Uses `XX` rather than `Kacc` as a namespace of the parser.                                         |
| `-o FILE` | `FILE` will be used as an output file instead of `parser.kx` which is by default.                  |
| `-d FILE` | `FILE` will be used instead of `parser.output`.                                                    |

## Example

The parser definition file is written in the same manner as the Yacc/Bison.
This is an example of a calculator.

```javascript
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

/* Parser */
var vars = {};
var parser = new Kacc.Parser(lexer, {
    yyerror: &(msg)         => System.println(("ERROR! " + msg).red().bold()),
    setVar:  &(name, value) => vars[name] = value,
    getVar:  &(name)        => vars[name],
});

/* Calculation */
parser.parse("2 + 3 * 5") {
    System.println(_1.value);   // => 17
};
```

## License

`Kacc` is published under MIT license.

> Note that the `kmyacc` included in `kacc` as a binary module is published
> under GPLv2 license. See details for https://github.com/Kray-G/kmyacc.

