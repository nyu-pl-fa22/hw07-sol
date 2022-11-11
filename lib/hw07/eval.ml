(** {0} The evaluation function of the MiniML interpreter. *)
  
open Ast
open Util

(** Generated a type error at position [pos] for expected type [exp_typ] and actual type [act_typ]. *)
let type_error pos exp_typ act_typ =
  fail pos (Printf.sprintf "Type mismatch\n  Expected type: %s\n  Actual type: %s" exp_typ act_typ)
  
(** Extract bool from BoolVal, generate type error message if value is not a BoolVal *)
let bool_of_value pos = function
  | BoolVal b -> b
  | IntVal i -> type_error pos "bool" "int"
  | Closure _ -> type_error pos "bool" "function"

(** Extract int from IntVal, generate type error message if value is not an IntVal *)
let int_of_value pos = function
  | IntVal i -> i
  | BoolVal _ -> type_error pos "int" "bool"
  | Closure _ -> type_error pos "int" "function"

(** Extract closure from Closure, generate type error message if value is not a Closure *)
let closure_of_value pos = function
  | Closure (x, t, env) -> x, t, env
  | IntVal _ -> type_error pos "function" "int"
  | BoolVal _ -> type_error pos "function" "bool"

(** Convert a value back to a term *)
let term_of_value pos = function
  | IntVal i -> IntConst (i, pos)
  | BoolVal b -> BoolConst (b, pos)
  | Closure (x, t, _) -> Lambda (x, t, pos)
        
(** Evaluate term [t] to a value using call-by-value semantics *)
let eval beta (t: term) : value =
  let rec eval t = match t with
  | FunConst (Fix, pos) ->
      let f = Var ("f", pos) in
      let x = Var ("x", pos) in
      let fn =
        Lambda ("x",
                App (App (f, App (t, f, pos), pos),
                     x, pos),
                pos)
      in
      Closure ("f", fn, [])
  | FunConst (Not, pos) ->
      let x = Var ("x", pos) in
      let fn = App (t, x, pos) in
      Closure ("x", fn, [])
  | IntConst (i, _) -> IntVal i
  | BoolConst (b, _) -> BoolVal b
  | App (FunConst (Not, _), t, pos) ->
      let v = eval t in
      BoolVal (not (bool_of_value pos v))
  | App (t1, t2, pos) -> beta t1 t2 pos
  | BinOp (bop, t1, t2, _) ->
      let pos1 = position_of_term t1 in
      let pos2 = position_of_term t2 in
      (match bop with
      | Mult | Div | Mod | Plus | Minus ->
          let op = match bop with
          | Mult -> ( * )
          | Div -> (/)
          | Mod -> (mod)
          | Plus -> (+)
          | Minus -> (-)
          | _ -> assert false
          in
          let v1 = int_of_value pos1 (eval t1) in
          let v2 = int_of_value pos2 (eval t2) in
          IntVal (op v1 v2)
      | Le | Ge | Lt | Gt ->
          let op = match bop with
          | Le -> (<=)
          | Ge -> (>=)
          | Lt -> (<)
          | Gt -> (>)
          | _ -> assert false
          in
          let v1 = int_of_value pos1 (eval t1) in
          let v2 = int_of_value pos2 (eval t2) in
          BoolVal (op v1 v2)
      | Eq ->
          let v1 = eval t1 in
          let v2 = eval t2 in
          BoolVal (v1 = v2)
      | Ne ->
          let v1 = eval t1 in
          let v2 = eval t2 in
          BoolVal (v1 <> v2)
      | And | Or ->
          (* short-circuit semantics of && and || *)
          let b1 = bool_of_value pos1 (eval t1) in
          (match bop, b1 with
          | And, true | Or, false ->
              let v2 = eval t2 in
              BoolVal (bool_of_value pos2 v2)
          | And, false | Or, true -> BoolVal b1
          | _ -> assert false))     
  | Ite (t1, t2, t3, _) ->
      let pos1 = position_of_term t1 in
      if bool_of_value pos1 (eval t1)
      then eval t2
      else eval t3
  | Lambda (x, t, _) ->
      Closure (x, t, [])
  | Var (x, pos) -> fail pos "unexpected free variable"
  in
  eval t

(** beta-reduction step using call-by-value semantics *)
let rec beta_call_by_value (t1: term) (t2: term) (pos: pos) : value =
  print_endline ("t1: " ^ string_of_term t1);
  print_endline ("t2: " ^ string_of_term t2);
  let v1 = eval beta_call_by_value t1 in
  let x, t, _ = closure_of_value (position_of_term t1) v1 in
  print_endline ("body: " ^ string_of_term t);
  let v2 = eval beta_call_by_value t2 in
  print_endline ("subst: " ^ string_of_term (subst t x (term_of_value (position_of_term t2) v2)));
  eval beta_call_by_value (subst t x (term_of_value (position_of_term t2) v2))


(** Evaluate term [t] to a value using call-by-value semantics *)
let eval_by_value (t: term) : value = eval beta_call_by_value t


(** beta-reduction step using call-by-value semantics *)
let rec beta_call_by_name  (t1: term) (t2: term) (pos: pos) : value =
  let v1 = eval beta_call_by_name t1 in
  let x, t, _ = closure_of_value (position_of_term t1) v1 in
  eval beta_call_by_name (subst t x t2)
    

(** Evaluate term [t] to a value using call-by-name semantics *)
let eval_by_name (t: term) : value = eval beta_call_by_name t

(** {1} Bonus part *)
    
(** Evaluate term [t] using value environments instead of substitutions *)
let eval_with_envs (t: term) : value =
  let rec eval (env: env) (t: term) = match t with
  | FunConst (Fix, pos) ->
      let f = Var ("f", pos) in
      let x = Var ("x", pos) in
      let fn =
        Lambda ("x",
                App (App (f, App (t, f, pos), pos),
                     x, pos),
                pos)
      in
      Closure ("f", fn, env)
  | FunConst (Not, pos) ->
      let x = Var ("x", pos) in
      let fn = Lambda ("x", App (t, x, pos), pos) in
      Closure ("x", fn, env)
  | IntConst (i, _) -> IntVal i
  | BoolConst (b, _) -> BoolVal b
  | App (FunConst (Not, _), t, pos) ->
      let v = eval env t in
      BoolVal (not (bool_of_value pos v))
  | App (t1, t2, pos) ->
      let v1 = eval env t1 in
      let x, t, v1_env = closure_of_value (position_of_term t1) v1 in
      let v2 = eval env t2 in
      eval ((x, v2) :: List.remove_assoc x v1_env) t
  | BinOp (bop, t1, t2, _) ->
      let pos1 = position_of_term t1 in
      let pos2 = position_of_term t2 in
      (match bop with
      | Mult | Div | Mod | Plus | Minus ->
          let op = match bop with
          | Mult -> ( * )
          | Div -> (/)
          | Mod -> (mod)
          | Plus -> (+)
          | Minus -> (-)
          | _ -> assert false
          in
          let v1 = int_of_value pos1 (eval env t1) in
          let v2 = int_of_value pos2 (eval env t2) in
          IntVal (op v1 v2)
      | Le | Ge | Lt | Gt ->
          let op = match bop with
          | Le -> (<=)
          | Ge -> (>=)
          | Lt -> (<)
          | Gt -> (>)
          | _ -> assert false
          in
          let v1 = int_of_value pos1 (eval env t1) in
          let v2 = int_of_value pos2 (eval env t2) in
          BoolVal (op v1 v2)
      | Eq ->
          let v1 = eval env t1 in
          let v2 = eval env t2 in
          BoolVal (v1 = v2)
      | Ne ->
          let v1 = eval env t1 in
          let v2 = eval env t2 in
          BoolVal (v1 <> v2)
      | And | Or ->
          (* short-circuit semantics of && and || *)
          let b1 = bool_of_value pos1 (eval env t1) in
          (match bop, b1 with
          | And, true | Or, false ->
              let v2 = eval env t2 in
              BoolVal (bool_of_value pos2 v2)
          | And, false | Or, true -> BoolVal b1
          | _ -> assert false))     
  | Ite (t1, t2, t3, _) ->
      let pos1 = position_of_term t1 in
      if bool_of_value pos1 (eval env t1)
      then eval env t2
      else eval env t3
  | Lambda (x, t, _) ->
      Closure (x, t, env)
  | Var (x, pos) -> List.assoc x env
  in
  eval [] t
