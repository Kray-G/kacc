# Kacc

## Introduction

`kacc` is a parser generator like `yacc`, which includes the `Lexer` class.
It is easy to use a Kacc Parser with a Lexer.

## Options

`kacc` has the following options.

* `-v`
  * Generates the file of `parser.output` which contains human-readable
    parser tables and diagnostics.
* `-l`
  * Does not insert #line control directives in `parser.kx`.
* `-t`
  * Generates debugging code.
* `-p XX`
  * Uses `XX` as a namespace of the parser rather than `Kacc`.
    You can avoid collision of external symbols when you use more than one
    parser in the same program by specifing this option.

# License

This product is published under MIT license.

> Note that the `kmyacc` included in `kacc` as a binary module is published
> under GPLv2 license. See details for https://github.com/Kray-G/kmyacc.
