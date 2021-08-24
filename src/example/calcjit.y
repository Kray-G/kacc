/* Calculator in Kacc. */

%{
using @kacc.Lexer;
using Jit;
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
    | error { $$.op = "<error>"; }
    ;

assign
    : TOKEN_IDENTIFIER '=' expr { @setVar($1.value, $3); $$ = $3; }
    ;

expr
    : expr '+' expr { $$ = { lhs: $1, op: '+', rhs: $3 }; }
    | expr '-' expr { $$ = { lhs: $1, op: '-', rhs: $3 }; }
    | expr '*' expr { $$ = { lhs: $1, op: '*', rhs: $3 }; }
    | expr '/' expr { $$ = { lhs: $1, op: '/', rhs: $3 }; }
    | '(' expr ')' { $$ = $2; }
    | TOKEN_NUMBER { $$ = $1.value; }
    | TOKEN_IDENTIFIER { $$ = @getVar($1.value); }
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

/* Interpreter */
class Interpreter(opts_) {
    private sequence(r, op, lhs, rhs) {
        return if (!opts_.enableSequence);
        System.println("%d %s %d -> %d" % lhs % op % rhs % r);
    }
    public eval(ast) {
        var lhs = ast.lhs.isObject ? eval(ast.lhs) : ast.lhs;
        var rhs = ast.rhs.isObject ? eval(ast.rhs) : ast.rhs;
        var r = 0;
        switch (ast.op) {
        case '+':
            r = lhs + rhs;
            break;
        case '-':
            r = lhs - rhs;
            break;
        case '*':
            r = lhs * rhs;
            break;
        case '/':
            r = lhs / rhs;
            break;
        case '%':
            r = lhs % rhs;
            break;
        default:
            throw RuntimeException('Invalid operator');
        }
        sequence(r, ast.op, lhs, rhs);
        return r;
    }
}

/* Compiler */
class Compiler(opts_) {
    var regs_, regsLen_;
    enum { MOV, BOP, DIVMOD, RET }
    private initialize() {
        regs_ = [
            // Jit.R0 and Jit.R1 is used as a work register when it is division.
            { reg: Jit.R2, used: false, name: "R2" },
            { reg: Jit.R3, used: false, name: "R3" },
            { reg: Jit.R4, used: false, name: "R4" },
            { reg: Jit.R5, used: false, name: "R5" },
            { reg: Jit.S0, used: false, name: "S0" },
            { reg: Jit.S1, used: false, name: "S1" },
            { reg: Jit.S2, used: false, name: "S2" },
            { reg: Jit.S3, used: false, name: "S3" },
            { reg: Jit.S4, used: false, name: "S4" },
            { reg: Jit.S5, used: false, name: "S5" },
        ];
        regsLen_ = regs_.length();
    }
    private listing(type, op, dst, op1, op2) {
        return if (!opts_.enableListing);
        switch (type) {
        case MOV:
            System.println("%s <- %s" % dst % op1);
            break;
        case BOP:
            System.println("%s <- %s %s %s" % dst % op1 % op % op2);
            break;
        case DIVMOD:
            System.println("R0 <- %s" % op1);
            System.println("R1 <- %s" % op2);
            System.println("%s <- R0 %s R1" % dst % op);
            break;
        case RET:
            System.println("ret %s" % dst);
            break;
        }
    }
    private getReg() {
        for (var i = 0; i < regsLen_; ++i) {
            if (!regs_[i].used) {
                regs_[i].used = true;
                return i;
            }
        }
        throw RuntimeException("Not enough register");
    }
    private releaseReg(i) {
        regs_[i].used = false;
    }
    private compileLeaf(c, leaf) {
        var r = getReg();
        c.mov(regs_[r].reg, Jit.IMM(leaf));
        listing(MOV, null, regs_[r].name, leaf);
        return r;
    }
    private compileNode(c, ast) {
        var rl = ast.lhs.isObject ? compileNode(c, ast.lhs) : compileLeaf(c, ast.lhs);
        var rr = ast.rhs.isObject ? compileNode(c, ast.rhs) : compileLeaf(c, ast.rhs);
        var r = getReg();
        switch (ast.op) {
        case '+':
            c.add(regs_[r].reg, regs_[rl].reg, regs_[rr].reg);
            listing(BOP, ast.op, regs_[r].name, regs_[rl].name, regs_[rr].name);
            break;
        case '-':
            c.sub(regs_[r].reg, regs_[rl].reg, regs_[rr].reg);
            listing(BOP, ast.op, regs_[r].name, regs_[rl].name, regs_[rr].name);
            break;
        case '*':
            c.mul(regs_[r].reg, regs_[rl].reg, regs_[rr].reg);
            listing(BOP, ast.op, regs_[r].name, regs_[rl].name, regs_[rr].name);
            break;
        case '/':
            c.mov(Jit.R0, regs_[rl].reg);
            c.mov(Jit.R1, regs_[rr].reg);
            c.sdiv();
            c.mov(regs_[r].reg, Jit.R0);
            listing(DIVMOD, ast.op, regs_[r].name, regs_[rl].name, regs_[rr].name);
            break;
        case '%':
            c.mov(Jit.R0, regs_[rl].reg);
            c.mov(Jit.R1, regs_[rr].reg);
            c.sdivmod();
            c.mov(regs_[r].reg, Jit.R1);
            listing(DIVMOD, ast.op, regs_[r].name, regs_[rl].name, regs_[rr].name);
            break;
        default:
            throw RuntimeException('Invalid operator');
        }
        releaseReg(rl);
        releaseReg(rr);
        return r;
    }
    public compile(ast) {
        var c = new Jit.Compiler();
        c.enter();
        var r = compileNode(c, ast);
        c.ret(regs_[r].reg);
        listing(RET, null, regs_[r].name);
        return c.generate();
    }
    public run(ast) {
        var code = compile(ast);
        return code.run();
    }
}

/* Parse expressions */
var exprs = [
    "2+3",
    "3 + 5 * 9",
    "(3 + 5) * 9",
    "c=24",
    "a 1",  // Syntax error
    "a=10",
    "b=70+a",
    "a+b+c",
];
exprs.each { &(expr)
    parser.parse(expr.trim()) { &(r)
        if (r.isObject && r.op != "<error>") {
            // Try it with Interpreter.
            var i = new Interpreter({ enableSequence: false });
            var iv = i.eval(r);

            // Try it with Compile & Run.
            var c = new Compiler({ enableListing: false });
            var cv = c.run(r);

            // Check the result.
            System.print("Result = (Interpreter: %4d, Compiler: %4d) => " % iv % cv);
            System.println(iv == cv ? "Success".green().bold() : "Failed".red().bold());
        }
    };
};
