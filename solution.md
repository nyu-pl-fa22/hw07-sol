# Solution for Problem 1

## Part 1

a. *t' = λ y1. (λ x1. y1 (λ y2. (λ x2. x2) x1)) z (λ z1. z1 x) y1*

   Note that the chosen names of the bound variables don't matter as
   long as every variable is bound at most once. Here is an
   alternative solution:
   
   *t' = λ y. (λ x. y1 (λ y'. (λ x'. x') x)) z (λ z. z x) y*
   

b. *{x,z}*

## Part 2

*`iszero` (`mult` `0` `1`) `2` `3`*

   *= `iszero` ((λ m n. m (`plus` n) `0`) `0` `1`) `2` `3`*  ; Def. of *`mult`*

   *→ `iszero` ((λ n. `0` (`plus` n) `0`) `1`)  `2` `3`*
   
   *→ `iszero` (`0` (`plus` `1`) `0`) `2` `3`*
   
   *= `iszero` ((λ s z. z) (`plus` `1`) `0`) `2` `3`* ; Def. of *`0`*
   
   *→ `iszero` ((λ z. z) `0`) `2` `3`*
   
   *→ `iszero` `0` `2` `3`*
   
   *= (λ n. n (λ x. `false`) `true`) `0` `2` `3`* ; Def. of *`iszero`*
   
   *→ `0` (λ x. `false`) `true` `2` `3`*
   
   *= (λ s z. z) (λ x. `false`) `true` `2` `3`* ; Def. of *`0`*
   
   *→ (λ z. z) `true` `2` `3`*
   
   *→ `true` `2` `3`*
   
   *= (λ x y. x) `2` `3`* ; Def. of *`true`*
   
   *→ (λ y. `2`) `3`*

   *→ `2`*


## Part 3

3. *`exp` = (λ m n. n (`mult` `m`) `1`)*
