# Homework 7 (30 Points + 5 Bonus Points)

The deadline for Homework 7 is Friday, Nov 11, 10pm. The late
submission deadline is Tuesday, Nov 15, 10pm.

## Getting the code template

Before you perform the next steps, you first need to create your own
private copy of this git repository. To do so, click on the link
provided in the announcement of this homework assignment on
Brightspace. After clicking on the link, you will receive an email from
GitHub, when your copy of the repository is ready. It will be
available at
`https://github.com/nyu-pl-fa22/hw07-<YOUR-GITHUB-USERNAME>`.
Note that this may take a few minutes.

* Open a browser at `https://github.com/nyu-pl-fa22/hw07-<YOUR-GITHUB-USERNAME>` with your Github username inserted at the appropriate place in the URL.
* Choose a place on your computer for your homework assignments to reside and open a terminal to that location.
* Execute the following git command: <br/>
  ```bash
  git clone https://github.com/nyu-pl-fa22/hw07-<YOUR-GITHUB-USERNAME>.git
  cd hw07
  ```

## Preliminaries

We assume that you have installed a working OCaml distribution. Follow
the [OCaml Setup instructions](https://github.com/nyu-pl-fa22/ocaml-in-class-code) if
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
https://github.com/nyu-pl-fa22/hw07-<YOUR-GITHUB-USERNAME>/
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
   following lambda term where *`iszero`*, *`mult`*, *`0`*, etc refer
   to the Church encodings of natural numbers and their operations
   given in the notes for Class 7. Show all β-reduction steps.

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
dynamically typed subset of OCaml that we'll call *MiniML*. We will
implement the interpreter in OCaml itself. Most of the code will be
given to you. Your task will be to implement several functions that
are missing in the given code. These functions are critical for the
interpreter to work correctly.

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
input to our interpreter. We will use this information for error
reporting.

### Code Structure, Compiling and Editing the Code, Running the Interpreter

The code template contains various OCaml modules that already
implement most of the functionality needed for our interpreter:

* [lib/hw07/util.ml](lib/hw07/util.ml): some useful utility
  functions (the type `pos` is defined here)

* [lib/hw07/ast.ml](lib/hw07/ast.ml): definition of abstract syntax
  of MiniML (see above) and related utility functions

* [lib/hw07/grammar.mly](lib/hw07/grammar.mly): grammar definition
  for a parser that parses a MiniML term and converts it into an
  abstract syntax tree of type `term`

* [lib/hw07/lexer.mll](lib/hw07/lexer.mll): associated grammar
  definitions for lexer phase of parser

* [lib/hw07/parser.ml](lib/hw07/parser.ml): interface to MiniML
  parser generated from grammar

* [lib/hw07/eval.ml](lib/hw07/eval.ml): the actual MiniML interpreter

* [bin/miniml.ml](bin/miniml.ml): the main entry point of
  our interpreter application (parses command line parameters and the
  input file, runs the input program and outputs the result, error
  reporting)

* [test/hw07_spec.ml](test/hw07_spec.ml): module with unit tests for
  your code.

The interpreter is almost complete. However, it misses several
functions that are only implemented as stubs (see below). These
functions are found in the modules `Ast` and `Eval`. That is, the
files `ast.ml` and `eval.ml` are the only files that you need to edit
to complete this part of the homework. Though, we also encourage you
to add additional unit tests to `hw07_spec.ml` for testing.

The directory structure is configured for the OCaml build tool `dune`.

You can find some test inputs for the interpreter in the directory `tests`.
To compile and run the executable program on a test input, execute e.g. the following command in the root directory of the repository:
```bash
dune exec -- bin/miniml.exe tests/test01.ml
```

The interpreter supports the option `-v` which you can use to get some
additional debug output. In particular, the interpreter will
print the input program on standard output after it has been parsed.

Note that the interpreter will initially fail with an error message
`"Not yet implement"` for each unit test.

To run the unit tests, simply execute
```bash
dune runtest
```

To provide editing support for OCaml in your IDE, we use 
the [Merlin toolkit](https://github.com/ocaml/merlin). Assuming
you have set up an editor or IDE with Merlin, you should be able to
just open the source code files and start editing. Merlin should
automatically highlight syntax and type errors in your code and
provide other useful functionality. 

**Important**: Execute `dune build` once immediately after cloning the
repository. This is needed so that Merlin is able to resolve the
dependencies between the different source code files.

### Part 0: Preliminaries (0 Points)

Before you get started, familiarize yourself with the algebraic data
types defined in `ast.ml` that we use to represent MiniML terms. Also
familiarize yourself with the predefined functions in `ast.ml` and
`eval.ml`.

You'll find the following two functions useful for pretty printing MiniML terms:

```ocaml
string_of_term: term -> string

print_term: out_channel -> term -> unit
```

These functions are defined in `ast.ml`. Moreover, `parser.ml` defines a function

```ocaml
parse_from_string: string -> term
```

that takes the string representation of a MiniML term and parses it
into its AST representation. You may find this function useful for
testing your code.


### Part 1: Finding a Free Variable in a Term (3 Points)

Your first task is to implement a function `find_free_var` that,
given a term `t`, checks whether `t` contains a free variable and if
so, returns that variable together with its source code position. We
use an `option` type to capture the case when `t` does not contain any
free variables:

```ocaml
find_free_var: term -> (var * pos) option
```

Recall that the type `'a option` is defined as follows:

```ocaml
type 'a option =
  | None
  | Some of 'a
```

That is, your implementation should return `None` if `t` does not contain
any free variables. Otherwise, it should return `Some (x, pos)` where
`x` is the first variable that occurs free in `t` if `t` is traversed
left-to-right and `pos` is the associated source code position of that
occurrence of `x`.

You can find some unit tests for this function in `tests.ml`.

The main function in `miniml.ml` uses the function `find_free_var` to
check whether in input file contains a valid MiniML program, i.e.,
that the term in the input file is closed. If the term contains a free
variable, the main function generates an appropriate error message
using the information provided by `find_free_var`.

Hint: use pattern matching on the values of type `(var * pos) option`
when recursively searching for free occurrences of variables in
subterms.

### Part 2: Substitution for Beta Reduction (5 Points)

Your next task for this problem is to implement a function

```ocaml
subst: term -> var -> term -> term
```

such that for given terms `t` and `s` and variable `x`,

```ocaml
subst t x s
```

computes the term `t[s/x]` obtained from `t` by substituting all free
occurrences of `x` in `t` by `s`. You will use this function later to
implement the interpreter in module `Eval`. Specifically, it will be
used to evaluate function applications using beta-reduction.

Since our interpreter will only evaluate closed terms (i.e. terms that
have no free variables), the interpreter maintains the invariant that
the terms `t` and `s` on which `subst` will be called are also
closed. This significantly simplifies the implementation of `subst` as
we do not have to account for alpha-renaming of bound variables within
`t` to avoid capturing free variables in `s` (since there are no free
variables that could be captured).

Some unit tests are already provided for you. Write additional unit
tests on your own. 

### Part 3: Call-by-value Evaluation (8 Points)

The actual MiniML interpreter is implemented by the function `eval` in
module `Eval` (`eval.ml`). This function takes in a MiniML term and
reduces it to a `value` using beta-reduction. The type `value` is defined as follows:

```ocaml
type value =
  | IntVal of int (* An integer value i *)
  | BoolVal of bool (* A Boolean value b *)
  | Closure of var * term * env (* A closure (x,t,e) that abstracts x in t in environemnt e *)
```

The three variants correspond to the three possible normal forms that
evaluation of a MiniML term can produce. In particular, a value
`Closure (x, t, e)` represents an anonymous function value `fun x -> t`. 
You can ignore the third component `e` of `Closure` values for
now. It will only be relevant for the optional bonus problem (Part 5).

The function `eval` is parameterized by another function

```ocaml
beta: term -> term -> pos -> value
```
that implements the beta reduction step and determines the evaluation
strategy used for evaluating function applications. The `eval`
function calls `beta t1 t2 pos` whenever it encounters a function
application term `t1 t2` at some source position `pos` (i.e., `App (t1, t2, pos)`). The function
`beta` should then evaluate `t1 t2` and return the resulting value
back to `eval`. The source code position `pos` is only used for error
reporting.

Your first task is to implement the missing cases in the function
`eval`. In particular, you will need to implement the cases for
evaluating Boolean negation, binary operators, and conditional
expressions. For instance, if you want to evaluate a term of the shape
`BinOp (Add, t1, t2, pos)`, then you can call `eval` recursively
to evaluate the subterms `t1` and `t2` and then combine the result
values appropriately (e.g., add them in the case of `Add`).

We aim for a dynamically typed semantics of our language. In
particular, evaluating expressions like `2 + false` or `if 3 then 1
else 2` should produce a *dynamic type error*. You'll find the
following predefined functions useful for implementing this
behavior:

```ocaml
int_of_value: pos -> value -> int
bool_of_value: pos -> value -> bool
closure_of_value: pos -> value -> var * term * env
```

Each of these function takes a source code position and a value and
then coerces the given value to the appropriate OCaml type.  For
instance, `int_of_value pos (IntVal i)` will return `i`. On the other
hand, `int_of_value pos (BoolVal b)` will throw an exception that
indicates a dynamic type error because we are expecting an `int` value
but got a `bool`. The generated type error message will use `pos` to
indicate the source code position where the error occurred.

Hence, when you evaluate `BinOp (Add, t1, t2, pos)`, you can use
`int_of_value` to coerce the result values obtained from the recursive
evaluation of `t1` and `t2` to type `int` so that you can add them and
produce a result value `IntVal r` for `BinOp (Add, t1, t2, pos)`. Here,
`r` is the result of the addition. Proceed similarly for all the cases
that you need to implement.

Your next task is to implement the function
```ocaml
beta_by_value: term -> term -> pos -> value
```
This function should implement the beta-reduction rule for function
applications following the applicative-order evaluation strategy (i.e.,
call-by-value semantics). Use your function `subst` from Part 2 for
your implementation.

The predefined function `eval_by_value` then combines `eval` and
`beta_by_value` to obtain a complete implementation of our MiniML
interpreter based on call-by-value semantics. The file `hw07_spec.ml`
has a series of unit tests that calls this function. Use this to test
your code and feel free to add additional unit tests.

Also, if you run the MiniML executable without any options,
then it will use your implementation of
`eval_by_value` to evaluate the input program:

```bash
dune exec -- bin/miniml.exe tests/test01.ml
```

You can add the option `-v` to get more verbose output.


### Part 4: Call-by-name Evaluation (2 Points)

Similar to the second task in Part 3, implement the function
```ocaml
beta_by_name: term -> term -> pos -> value`
```
This function should implement the beta-reduction rule for function
applications following the normal-order evaluation strategy (i.e.,
call-by-name semantics). Again, use your function `subst` from Part 2 for
your implementation.

The predefined function `eval_by_name` then combines `eval` and
`beta_by_name` to obtain a complete implementation of our MiniML
interpreter based on call-by-name semantics. The file `hw07_spec.ml`
has a series of unit tests that calls this function. Use this to test
your code and feel free to add additional unit tests.

Additionally, if you run the MiniML executable with the option
`-call-by-name`, then it will use your implementation of
`eval_by_name` to evaluate the input program:

```bash
dune exec -- bin/miniml.exe tests/test01.ml -call-by-name
```

Note that since MiniML is completely side-effect free, the only way in
which call-by-value and call-by-name can be easily distinguished
(without peeking into the interpreter) is by their termination
behavior. For example, consider the following MiniML term:
```ocaml
(fun x -> 0) (1 / 0)
```
This term evaluates to `0` under call-by-name semantics, while it
crashes with an integer division error under call-by-value semantics.

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
closures in the type `value` accordingly. This leads to the following
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

For the most part, this is straightforward. 
The tricky cases will be the ones that create `Closure` values and the
case for function applications. Function applications should no longer
use `subst` but instead simply evaluate the body expression of the
closure with the appropriate environment. Depending on how you
implement this, you will end up with static scoping + deep binding or
dynamic scoping + shallow binding.

Since the interpreted terms can now contain free variables, you also
need to consider the case in `eval` where `t` is of the form `Var x`.
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
has the type given above.  Since we ensure that the initial input term is closed
(i.e. has no free variables) we can start evaluation of the term `t`
passed to `eval_with_envs` with an empty environment `[]`.

You will have to write your own unit tests to test your code. If you
want to test your code using the MiniML executable, you
can use the command line option `-bonus`, which will call
`eval_with_envs` with the parsed input program.

