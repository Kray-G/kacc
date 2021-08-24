# Kacc

## Introduction

`kacc` is an LALR(1) parser generator like `yacc/bison`, which includes the `Lexer` class.
It is easy to use a Kacc Parser with a Lexer.

## Usage

Use the `kacc` command with some options if necessary to generate your own parser.

```
$ kacc [-vltpod] parser.y
```

* The generated parser will be outputted to the `parser.kx` file.
* If you want to see the detail of a state, use `-v` to output the `parser.output` file.
* If you want to debug it, use `-t` to make it be able to run with a debug mode.

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
* `-o FILE`
  * `FILE` will be used as an output file instead of `parser.kx` which is
    by default.
* `-d FILE`
  * `FILE` will be used instead of `parser.output`.

# License

`Kacc` is published under MIT license.

> Note that the `kmyacc` included in `kacc` as a binary module is published
> under GPLv2 license. See details for https://github.com/Kray-G/kmyacc.
