# Homework 7 (30 Points + 5 Bonus Points)

The deadline for Homework 7 is ~Friday, April 5~ Monday, April 8, 6pm. The late
submission deadline is Thursday, April 11, 6pm.

## Getting the code template

Before you perform the next steps, you first need to create your own
private copy of this git repository. To do so, click on the link
provided in the announcement of this homework assignment on
Piazza. After clicking on the link, you will receive an email from
GitHub, when your copy of the repository is ready. It will be
available at
`https://github.com/nyu-pl-sp19/hw07-<YOUR-GITHUB-USERNAME>`.
Note that this may take a few minutes.

* Open a browser at `https://github.com/nyu-pl-sp19/hw07-<YOUR-GITHUB-USERNAME>` with your Github username inserted at the appropriate place in the URL.
* Choose a place on your computer for your homework assignments to reside and open a terminal to that location.
* Execute the following git command: <br/>
  ```git clone https://github.com/nyu-pl-sp19/hw07-<YOUR-GITHUB-USERNAME>.git```<br/>
  ```cd hw07```

## Preliminaries

We assume that you have installed a working OCaml distribution,
including the packages `ocamlfind`, `ocamlbuild`, and `ounit`. Follow
the instructions in the notes
for
[Class 7](https://github.com/nyu-pl-sp19/class07#installation-build-tools-and-ides) if
you haven't done this yet.

## Submitting your solution

Once you have completed the assignment, you can submit your solution
by pushing the modified code template to GitHub. This can be done by
opening a terminal in the project's root directory and executing the
following commands:

```bash
git add .
git commit -m "solution"
git push
```

You can replace "solution" by a more meaningful commit message.

Refresh your browser window pointing at
```
https://github.com/nyu-pl-sp19/hw07-<YOUR-GITHUB-USERNAME>/
```
and double-check that your solution has been uploaded correctly.

You can resubmit an updated solution anytime by reexecuting the above
git commands. Though, please remember the rules for submitting
solutions after the homework deadline has passed.

## Problem 1: Lambda Calculus Warm-Up (12 Points)

Put your solution for Problem 1 into the file `solution.md`. When
submitting your solution to this problem, you may use the notation
`(fun x -> t)` for lambda terms *(λ x. t)*.

1. Consider the lambda term

   *t = λ y. (λ x. y (λ y. (λ x. x) x)) z (λ z. z x) y*
   
   1. Construct a new term *t'* from *t* by α-renaming all variables
      bound in *t* such that they are unique (i.e. the same variable
      name should not be bound by two different λs in *t'*).
   
   1. Calculate the set of free variables appearing in *t*.

2. Using the definitions from class, compute the normal form of the
   following lambda term. Show all β-reduction steps.

   *`iszero` (`mult` `0` `1`) `2` `3`*

3. Give an alternative definition for the lambda term *`exp`* such
   that *`exp` m n* computes the Church encoding of the number *mⁿ*
   for two Church numerals *m* and *n*. (Hint: you can e.g. use
   *`mult`* to define *`exp`*). You can test your definition by
   transferring it to OCaml and then using your implementation of the
   interpreter from Problem 2.

## Problem 2: MiniML

In this exercise we will practice the features of the OCaml language
that we have studied so far and apply them to implement an interpreter
for the untyped lambda calculus.

More precisely, the goal is to implement an interpreter for a
dynamically typed subset of OCaml, called *MiniML*. We will implement
the interpreter in OCaml itself. Most of the code will be given to
you. Your task will be to implement several functions that are missing
in the given code. These functions are relatively small but critical
for the interpreter to work correctly.

### Syntax

We consider a core language built around the untyped lambda
calculus. For convenience, we extend the basic lambda calculus with
primitive operations on Booleans and integers. We also introduce a fixpoint
operator to ease the implementation of recursive functions. The
concrete syntax of the language is described by the following grammar:

```
(Variables)
x: var

(Integer constants)
i: int  ::= 
   ... | -1 | 0 | 1 | ...

(Boolean constants)
b: bool ::= true | false

(inbuilt functions)
f: inbuilt_fun ::=
     not                   (logical negation)
   | fix                   (fixpoint operator)

(Binary infix operators)
bop: binop ::=
     * | / | mod           (multiplicative operators)
   | + | - |               (additive operators)
   | && | ||               (logical operators)
   | = | <>                ((dis)equality operators)
   | < | > | <= | >=       (comparison operators)

(Terms)
t: term ::= 
     f                     (inbuilt functions)
   | i                     (integer constants)
   | b                     (Boolean constants)
   | x                     (variables) 
   | t1 t2                 (function application)
   | t1 bop t2             (binary infix operators)
   | if t1 then t2 else t3 (conditionals)
   | fun x -> t1           (lambda abstraction)
```

The rules for operator precedence and associativity are the
same [as in OCaml](https://caml.inria.fr/pub/docs/manual-ocaml/expr.html).

For notational convenience, we also allow OCaml's basic `let`
bindings, which we introduce as syntactic sugar. That is, the OCaml
expression

```ocaml
let x = t1 in t2
```

is syntactic sugar for the following term in our core calculus:

```ocaml
(fun x -> t2) t1
```

Similarly, the OCaml expression

```ocaml
let rec x = t1 in t2
```

is syntactic sugar for the term

```ocaml
(fun x -> t2) (fix (fun x -> t1))
```

We represent the core calculus of MiniML using algebraic data types
as follows:

```ocaml
(** source code position, line:column *)
type pos = { pos_line: int; pos_col: int }

(** variables *)
type var = string

(** inbuilt functions *)
type inbuilt_fun =
  | Fix (* fix (fixpoint operator) *)
  | Not (* not *)

(** binary infix operators *)
type binop =
  | Mult  (* * *)
  | Div   (* / *)
  | Mod   (* mod *)
  | Plus  (* + *)
  | Minus (* - *)
  | And   (* && *)
  | Or    (* || *)
  | Eq    (* = *)
  | Lt    (* < *)
  | Gt    (* > *)
  | Le    (* <= *)
  | Ge    (* >= *)

(** terms *)
type term =
  | FunConst of inbuilt_fun * pos      (* f (inbuilt function) *)
  | IntConst of int * pos              (* i (int constant) *)
  | BoolConst of bool * pos            (* b (bool constant) *)
  | Var of var * pos                   (* x (variable) *)
  | App of term * term * pos           (* t1 t2 (function application) *)
  | BinOp of binop * term * term * pos (* t1 bop t2 (binary infix operator) *)
  | Ite of term * term * term * pos    (* if t1 then t2 else t3 (conditional) *)
  | Lambda of var * term * pos         (* fun x -> t1 (lambda abstraction) *)
```

Note that the mapping between the various syntactic constructs and the
variants of the type `term` is fairly direct. The only additional
complexity in our implementation is that we tag every term with a
value of type `pos`, which indicates the source code position where
that term starts in the textual representation of the term given as
input to our interpreter. We will use this information to provide more
meaningful error reporting to the programmer.

### Code Structure, Compiling and Editing the Code, Running the Interpreter

The code template contains various OCaml modules that already
implement most of the functionality needed for our interpreter:

* [src/util.ml](src/util.ml): some useful utility
  functions and modules (the type `pos` is defined here)

* [src/ast.ml](src/ast.ml): definition of abstract syntax
  of MiniML (see above) and related utility functions

* [src/grammar.mly](src/grammar.mly): grammar definition
  for a parser that parses a MiniML term and converts it into an
  abstract syntax tree

* [src/lexer.mll](src/lexer.mll): associated grammar
  definitions for lexer phase of parser

* [src/parser.ml](src/parser.ml): interface to MiniML
  parser generated from grammar

* [src/eval.ml](src/eval.ml): the actual MiniML interpreter

* [src/miniml.ml](src/miniml.ml): the main entry point of
  our interpreter application (parses command line parameters and the
  input file, runs the input program and outputs the result, error
  reporting)

* [src/hw07_spec.ml](src/hw07_spec.ml): module with unit tests for
  your code using
  the [OUnit framework](http://ounit.forge.ocamlcore.org/).

The interpreter is almost complete. However, it misses several
functions that are only implemented as stubs (see below). These
functions are found in the modules `Ast` and `Eval`. That is, the
files `ast.ml` and `eval.ml` are the only files that you need to edit
to complete this part of the homework. Though, we also encourage you
to add additional unit tests to `hw07_spec.ml` for testing your code.

The root directory of the repository contains a shell
script [`build.sh`](build.sh) that you can use to compile
your code. Simply execute

```bash
./build.sh
```

and this will compile everything. You will have to install
`ocamlbuild` and `ounit` for this to work. Follow
the
[OCaml setup instructions](https://github.com/nyu-pl-sp19/ocaml-setup)
to do this. Assuming there are no compilation errors, this script will
produce two executable files in the root directory:

* `miniml.native`: the executable of the MiniML interpreter.

* `hw07_spec.native`: the executable for running the unit tests.

You can find some test inputs for the interpreter in the directory `tests`.
In order to run the interpreter, execute e.g.

```bash
./miniml.native tests/test01.ml
```

Note that the interpreter will initially fail with an error message
`"Not yet implement"` when you run it on some of the tests because you
first need to implement the missing functions described below.

The interpreter supports the option `-v` which you can use to get some
additional debug output. In particular, once you have implemented the
pretty printer for MiniML, using the interpreter with this option will
print the input program on standard output after it has been parsed.

To run the unit tests, simply execute
```bash
./hw07_spec.native
```

The root directory of the repository also contains a
file [`.merlin`](.merlin), which is used by
the [Merlin toolkit](https://github.com/ocaml/merlin) to provide
editing support for OCaml code in various editors and IDEs. Assuming
you have set up an editor or IDE with Merlin, you should be able to
just open the source code files and start editing. Merlin should
automatically highlight syntax and type errors in your code and
provide other useful functionality. 

You will need to run `build.sh` at least once so that Merlin is able
to resolve the dependencies between the different source code files.

### Part 1: MiniML Pretty Printer (6 Points)

Your first task is to implement a pretty printer for MiniML. That is,
you need to implement the two functions

```ocaml
string_of_term: term -> string

print_term: out_channel -> term -> unit
```

in `ast.ml`. The function `string_of_term` takes the AST of a MiniML
term as input and is supposed to convert it into its textual
representation. E.g. the code

```ocaml
let t =
  Lambda ("x", BinOp (Mult, IntConst (2, dummy_pos),
                      BinOp (Plus, Var ("x", dummy_pos), IntConst (3, dummy_pos), dummy_pos),
                      dummy_pos), dummy_pos)
in
string_of_term t
```

should yield the string

```ocaml
fun x -> 2 * (x + 3)
```

Here, we use `dummy_pos` as a place-holder value for the source code
position of each subterm.

You are allowed to have additional redundant parenthesis in the output
string as in

```ocaml
(fun x -> (2 * (x + 3)))
```

In general, your implementation of the function `string_of_term`
should satisfy the following specification: for all terms `t`

```
equal t (Parser.parse_from_string (string_of_term t)) = true
```

Here, the predefined function `Parser.parse_from_string` parses the
string representation of a MiniML term and produces its AST
representation as a value of type `term`. The function `equal` is
defined in `ast.ml` and checks whether two MiniML terms are
structurally equal when one ignores the source code position
tags. Thus, the above requirement expresses that pretty printing a
term represented as an AST and parsing it back to an AST, yields the
same AST (modulo source code positions). The file `tests.ml`
contains several unit tests that uses this condition to test your
implementation. We encourage you to add more test cases there.

The second function `print_term`, which you also need to implement,
should print the string representation of the given term to the given
output channel. E.g. calling

```ocaml
print_term stdout t
```

will print the term `t` to standard output.

A straightforward implementation of these two functions is to
implement `string_of_term` by building the string representation of
the term recursively from its parts using string concatenation (`^`),
and then implement `print_term` using `string_of_term` and one of the
functions provided by the
module
[`Printf`](https://caml.inria.fr/pub/docs/manual-ocaml/libref/Printf.html) in
the OCaml standard library. However, this is both inefficient and
nonidiomatic, and therefore strongly discouraged.

Instead, use
OCaml's
[Format](https://caml.inria.fr/pub/docs/manual-ocaml/libref/Format.html) module
to implement the pretty printer by implementing a function:

```ocaml
pr_term: Format.formatter -> term -> unit
```

The function `pr_term` can then be used to implement both
`string_of_term` and `print_term`. These implementations are already
provided for you.

Study how the `Format` module works. Challenge yourself and try to
produce nicely formatted output that uses the functionality of
`Format` to automatically add line breaks and indentation in your
output as needed. Also, try to minimize the number of parenthesis that
you produce in your output by taking advantage of operator precedence
and associativity. You will find the predefined functions `precedence`
and `is_left_associative` in the `Ast` module helpful for this. You
may even want to reintroduce `let` bindings in your generated output
to make it easier to read.

**Hint:** [this tutorial](https://ocaml.org/learn/tutorials/format.html)
discusses how to use the `Format` module and provides an
example towards the end that solves a very similar
problem than the one you have to implement here. So use that tutorial
to get started.

### Part 2: Finding a Free Variable in a Term (4 Points)

Your second task is to implement a function `find_free_var` that,
given a term `t`, checks whether `t` contains a free variable and if
so, returns that variable together with its source code position. We
use an `option` type to capture the case that `t` may not contain any
free variables:

```ocaml
find_free_var: term -> (var * pos) option
```

You can find some unit tests for this function in `tests.ml`.

The main function in `miniml.ml` uses the function `find_free_var` to
check whether all the variables occurring in the input program given
to the interpreter are properly declared and if not, produce an
appropriate error message.

Hint: you might find the functions provided by the module `Opt` in
`util.ml` helpful when implementing `find_free_var` (especially, the
functions `Opt.or_else` respectively `Opt.lazy_or_else`).

### Part 3: Substitution for Beta Reduction (5 Points)

Your next task for this problem is to implement a function

```ocaml
subst: term -> var -> term -> term
```

such that for given terms `t` and `s` and variable `x`,

```ocaml
subst t x s
```

computes the term `t[s/x]` obtained from `t` by substituting all free
occurrences of `x` in `t` by `s`. This function is used by the
interpreter in module `Eval` to evaluate function applications via
beta-reduction.

Since our interpreter will only evaluate closed terms (i.e. terms that
have no free variables), the interpreter maintains the invariant that
the terms `t` and `s` on which `subst` will be called are also
closed. This significantly simplifies the implementation of `subst` as
we do not have to account for alpha-renaming of bound variables within
`t` to avoid capturing free variables in `s` (since there are no free
variables that could be captured).

Some unit tests are already provided for you. Write additional unit
tests on your own. In addition, you can run the interpreter on the
input programs in [`tests/`](tests/) to make sure that it works as
expected. Feel free to write more input programs yourself and use them
for further testing.

### Part 4: Call-by-name Evaluation (3 Points)

The actual MiniML interpreter is implemented by the function `eval` in
module `Eval` (`eval.ml`). This function takes in a MiniML term and
reduces it to a value using beta reduction. The function `eval` is
parameterized by another function

```ocaml
beta: term -> term -> pos -> value`
```

that implements the beta reduction step and determines the evaluation
strategy used for evaluating function applications. The `eval`
function calls `beta t1 t2 pos` whenever it encounters a function
application term `t1 t2` at some source position `pos`. The function
`beta` should then evaluate `t1 t2` and return the resulting value
back to `eval`. The source code position `pos` is only used for error
reporting.

The module `Eval` already provides one implementation of `beta`, which
is given by the function `beta_call_by_value`. This function
implements the evaluation of function applications using call-by-value
semantics. The interpreter resulting from combining `eval` and
`beta_call_by_value` is given by the function `eval_by_value`.

Familiarize yourself with the implementations of the functions `eval`
and `beta_call_by_value`, then add the missing implementation for the
function `beta_call_by_name`. This function should be like
`beta_call_by_value` but instead implement the beta-reduction step for
function applications using call-by-name semantics.

You can test your code using the provided unit tests. Additionally, if
you run `miniml.native` with the option `-call-by-name`, then it will
use your implementation of `beta_call_by_name` to evaluate the input
program. Note that since MiniML is completely side-effect free, the
only way in which call-by-value and call-by-name can be easily
distinguished (without peeking into the interpreter) is by their
termination behavior. For example, the following MiniML term evaluates
to `0` when using call-by-name semantics, while it diverges when it is
evaluated with call-by-value semantics:

```ocaml
(fun f -> 0) ((fun x -> x x) (fun x -> x x))
```


### Part 5: (optional, 5 Bonus Points)

Implementing the interpreter using beta-reduction is conceptually nice
because it highlights how this ties back to the lambda
calculus. However, it is not how one would actually go about
implementing this in practice because it is not very
efficient. Computing the substitutions in the beta-reduction step
potentially does a lot of wasteful and unnecessary work.

A more realistic implementation would instead keep track of the
current reference environment during the interpretation. In this
reference environment one would store the bindings of the variables
that are currently in scope (i.e. the variables that are free in the
term that we currently interpret). We can e.g. use lists of pairs of
variables and values to represent such environments:

```ocaml
type env = (var * value) list
```

Though, remember that we have to deal with function values and so the
question of whether we want to have deep or shallow binding semantics
in our language arises. If we want deep binding semantics, then
whenever we construct a function value, we need to remember the
current reference environment so that we can restore it whenever we
call that function later. So we also have to define our notion of
closures in the type value accordingly. This leads to the following
mutually recursive type definition in `ast.ml`:

```ocaml
(** Values *)
type value =
  | IntVal of int (* i *)
  | BoolVal of bool (* b *)
  | Closure of var * term * env (* fun x -> t, created in environment env *)

(** Environments *)
and env = (var * value) list
```

The challenge is now to change the definition of `eval` to adhere to the type signature:

```ocaml
eval: env -> term -> value
```

That is, the definition will now look like this:

```ocaml
let eval (env: env) (t: term) : value = ...
```

where `env` is the current reference environment that stores the
bindings for the free variables in the term `t` that we want to
evaluate.

For the most part, this is straightforward. E.g. the case for addition
operations could now look something like this:

```ocaml
...
| BinOp (Plus, t1, t2, pos) -> 
  let v1 = eval env t1 in
  let v2 = eval env t2 in
  let pos1 = pos_of_term t1 in
  let pos2 = pos_of_term t2 in
  IntVal (int_of_value pos1 v1 + int_of_value pos2 v2)
```

Here, we simply pass the current reference environment `env` to the
recursive calls that evaluate the subexpressions `t1` and `t2`.

The tricky cases will be the ones that create `Closure` values and the
case for function applications. Function applications should no longer
use `subst` but instead simply evaluate the body expression of the
closure with the appropriate environment. Depending on how you
implement this, you will end up with static scoping + deep binding or
dynamic scoping + shallow binding.

Since terms that are interpreted can now contain free variables, you
also need to consider the case in `eval` where `t` is of the form `Var x`. 
In the current implementation, an exception is thrown because
beta-reduction with `subst` guarantees that we will never have free
variables. Think about how to implement this case in the new
version. Hint: an important invariant that your interpreter must
maintain is that all the free variables of the input term `t` must
have a binding in the current environment `env` (so this is something
to remember when you implement the case for function applications
since you have to consider the parameter of the function).

A stub of the environment-based interpreter is provided by the
function `eval_with_envs` in `eval.ml`. You only need to complete the
missing nested function `eval`, which is the actual interpreter and
has the type given above.  Since we ensure that prog is closed
(i.e. has no free variables) we can start evaluation of the term `t`
passed to `eval_with_envs` with an empty environment `[]`.

You will have to write your own unit tests to test your code. If you
want to test your code using the main executable `miniml.native`, you
can use the command line option `-bonus`, which will call
`eval_with_envs` with the parsed input program.

