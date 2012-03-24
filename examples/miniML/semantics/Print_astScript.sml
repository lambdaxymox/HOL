(* generated by Lem from print_ast.lem *)
open bossLib Theory Parse res_quanTheory
open finite_mapTheory listTheory pairTheory pred_setTheory integerTheory
open set_relationTheory sortingTheory stringTheory wordsTheory

val _ = new_theory "Print_ast"

open MiniMLTheory

(*open MiniML*)

val _ = Hol_datatype `
 stree = S of string | A of stree => stree`;


(*val (^^) : stree -> stree -> stree*)

(*val Num : Int.int -> num*)

(*val CHR : num -> string*)

(*val string_first : string -> string*)

(*val string_last : string -> string*)

(*val (%) : num -> num -> num*)

(*val stree_to_string : stree -> string -> string*)
 val stree_to_string_defn = Hol_defn "stree_to_string" `

(stree_to_string (S s) acc = STRCAT  s  acc)
/\
(stree_to_string (A s1 s2) acc = stree_to_string s1 (stree_to_string s2 acc))`;

val _ = Defn.save_defn stree_to_string_defn;

(*val spaces : num -> stree*)
 val spaces_defn = Hol_defn "spaces" `
 
(spaces n =
  if n = 0 then
    S""
  else A 
    (S" ")  (spaces (n - 1)))`;

val _ = Defn.save_defn spaces_defn;

 val num_to_string_defn = Hol_defn "num_to_string" `
 (num_to_string n =
  if n > 0 then A 
    (num_to_string (n DIV 10))  (S (STRING (CHR  (n MOD 10 + 48)) ""))
  else
    S"")`;

val _ = Defn.save_defn num_to_string_defn;

(*val int_to_stree : bool -> Int.int -> stree*)
val _ = Define `
 (int_to_stree sml n =
  if n = & 0 then
    S"0"
  else if int_gt n (& 0) then
    num_to_string (Num n)
  else A 
    (if sml then S"~" else S"-")  (num_to_string (Num ((int_sub) (& 0) n))))`;


(* Should inculde "^", but I don't know how to get that into HOL, since
 * antiquote seem stronger than strings. *)
val _ = Define `
 sml_infixes = 
  ["mod"; "<>"; ">="; "<="; ":="; "::"; "before"; "div"; "o"; "@"; ">";
   "="; "<"; "/"; "-"; "+"; "*"]`;


val _ = Define `
 ocaml_infixes = ["="; "+"; "-"; "*"; "/"; "mod"; "<"; ">"; "<="; ">="]`;


(*val join_strings : stree -> stree list -> stree*)
 val join_strings_defn = Hol_defn "join_strings" `

(join_strings sep [] = S"")
/\
(join_strings sep [x] = x)
/\
(join_strings sep (x::y::l) = A 
  x (A   sep  (join_strings sep (y::l))))`;

val _ = Defn.save_defn join_strings_defn;

val _ = Define `
 (lit_to_stree sml l = (case l of
  (* Rely on the fact that true and false cannot be rebound in SML *)
    Bool T => S"true"
  | Bool F => S"false"
  | IntLit n => int_to_stree sml n
))`;


val _ = Define `
 (pad_start v =
  if STRING (SUB ( v,0)) "" = "*" then STRCAT 
    " "  v
  else
    v)`;


val _ = Define `
 (pad_end v =
  if STRING (SUB ( v,STRLEN  v - 1)) "" = "*" then STRCAT 
    v  " "
  else
    v)`;


val _ = Define `
 (var_to_stree sml v =
  if sml /\ MEM v sml_infixes then A 
    (S"op ")  (S (pad_end v))
  else if ~ sml /\ MEM v ocaml_infixes then A 
    (S"(") (A   (S (pad_end (pad_start v)))  (S")"))
  else
    S (pad_end (pad_start v)))`;


 val pat_to_stree_defn = Hol_defn "pat_to_stree" `

(pat_to_stree sml (Pvar v) = var_to_stree sml v)
/\
(pat_to_stree sml (Plit l) = lit_to_stree sml l)
/\
(pat_to_stree sml (Pcon c []) =
  var_to_stree sml c)
/\
(pat_to_stree sml (Pcon c ps) = A 
  (S"(") (A   (var_to_stree sml c) (A   
    (S"(") (A   (join_strings (S",") (MAP (pat_to_stree sml) ps)) (A   (S")")  (S")"))))))`;

val _ = Defn.save_defn pat_to_stree_defn;

val _ = Define `
 (inc_indent i = 
  if i < 30 then
    i + 2
  else
    i)`;


val _ = Define `
 (newline indent = A  
  (S"\n")  (spaces indent))`;


 val exp_to_stree_defn = Hol_defn "exp_to_stree" `

(exp_to_stree sml indent (Raise r) =
  if sml then
    S"(raise Bind)"
  else
    S"(raise (Match_failure (string_of_bool true,0,0)))")
/\
(exp_to_stree sml indent (Val (Lit l)) =
  lit_to_stree sml l)
/\
(exp_to_stree sml indent (Val _) =
  (* This shouldn't happen in source *)
  S"")
/\
(exp_to_stree sml indent (Con c []) =
  var_to_stree sml c)
/\
(exp_to_stree sml indent (Con c es) = A 
  (S"(") (A   
  (var_to_stree sml c) (A   
  (S"(") (A   
  (join_strings (S",") (MAP (exp_to_stree sml indent) es))  
  (S"))")))))
/\
(exp_to_stree sml indent (Var v) =
  var_to_stree sml v)
/\
(exp_to_stree sml indent (Fun v e) = A 
  (newline indent) (A  
  (if sml then S"(fn " else S"(fun ") (A  
  (var_to_stree sml v) (A   
  (if sml then S" => " else S" -> ") (A   
  (exp_to_stree sml (inc_indent indent) e)  
  (S")"))))))
/\
(exp_to_stree sml indent (App Opapp e1 e2) = A 
  (S"(") (A   
  (exp_to_stree sml indent e1) (A   
  (S" ") (A   
  (exp_to_stree sml indent e2)  
  (S")")))))
/\
(exp_to_stree sml indent (App Equality e1 e2) = A 
  (S"(") (A   
  (exp_to_stree sml indent e1) (A   
  (S" = ") (A   
  (exp_to_stree sml indent e2)  
  (S")")))))
/\
(exp_to_stree sml indent (App (Opn o0) e1 e2) =
  let s = (case o0 of
      Plus => "+"
    | Minus => "-"
    | Times => "*"
    | Divide => if sml then "div" else "/"
    | Modulo => "mod"
  )
  in A 
    (S"(") (A   
    (exp_to_stree sml indent e1) (A   
    (S" ") (A   
    (S s) (A   
    (S" ") (A   
    (exp_to_stree sml indent e2)  
    (S")")))))))
/\
(exp_to_stree sml indent (App (Opb o') e1 e2) =
  let s = (case o' of
      Lt => "<"
    | Gt => ">"
    | Leq => "<="
    | Geq => ">"
  )
  in A 
    (S"(") (A   
    (exp_to_stree sml indent e1) (A   
    (S" ") (A   
    (S s) (A   
    (S" ") (A   
    (exp_to_stree sml indent e2)  
    (S")")))))))
/\
(exp_to_stree sml indent (Log lop e1 e2) = A 
  (S"(") (A   
  (exp_to_stree sml indent e1) (A   
  (if lop = And then 
     if sml then S" andalso " else S" && " 
   else 
     if sml then S" orelse " else S" || ") (A  
  (exp_to_stree sml indent e2)  
  (S")")))))
/\
(exp_to_stree sml indent (If e1 e2 e3) = A 
  (newline indent) (A  
  (S"(if ") (A   
  (exp_to_stree sml indent e1) (A   
  (newline indent) (A  
  (S"then ") (A   
  (exp_to_stree sml (inc_indent indent) e2) (A  
  (newline indent) (A  
  (S"else ") (A  
  (exp_to_stree sml (inc_indent indent) e3)  
  (S")"))))))))))
/\
(exp_to_stree sml indent (Mat e pes) = A 
  (newline indent) (A  
  (if sml then S"(case " else S"(match ") (A   
  (exp_to_stree sml indent e) (A   
  (if sml then S" of" else S" with") (A  
  (newline (inc_indent (inc_indent indent))) (A  
  (join_strings ( A (newline (inc_indent indent))  (S"| ")) 
               (MAP (pat_exp_to_stree sml (inc_indent indent)) pes))  
  (S")")))))))
/\
(exp_to_stree sml indent (Let v e1 e2) = A 
  (newline indent) (A  
  (if sml then S"let val " else S"(let ") (A   
  (var_to_stree sml v) (A   
  (S" = ") (A   
  (exp_to_stree sml indent e1) (A   
  (newline indent) (A  
  (S"in ") (A  
  (exp_to_stree sml (inc_indent indent) e2)  
  (if sml then A  (newline indent)  (S"end") else S")")))))))))
/\
(exp_to_stree sml indent (Letrec funs e) = A 
  (newline indent) (A  
  (if sml then S"let fun " else S"(let rec") (A   
  (join_strings ( A (newline indent)  (S"and ")) 
               (MAP (fun_to_stree sml indent) funs)) (A   
  (newline indent) (A  
  (S"in ") (A  
  (exp_to_stree sml indent e)  
  (if sml then A  (newline indent)  (S"end") else S")")))))))
/\
(pat_exp_to_stree sml indent (p,e) = A 
  (pat_to_stree sml p) (A   
  (if sml then S" => " else S" -> ") 
  (exp_to_stree sml (inc_indent (inc_indent indent)) e)))
/\
(fun_to_stree sml indent (v1,v2,e) = A 
  (var_to_stree sml v1) (A  
  (S" ") (A   
  (var_to_stree sml v2) (A   
  (S" = ")  
  (exp_to_stree sml (inc_indent indent) e)))))`;

val _ = Defn.save_defn exp_to_stree_defn;

 val type_to_stree_defn = Hol_defn "type_to_stree" `

(type_to_stree (Tvar tn) =
  S tn)
/\
(type_to_stree (Tapp ts tn) =
  if ts = [] then
    S tn
  else A 
    (S"(") (A   (join_strings (S",") (MAP type_to_stree ts)) (A   (S") ")  (S tn))))
/\
(type_to_stree (Tfn t1 t2) = A 
  (S"(") (A   (type_to_stree t1) (A   (S" -> ") (A   (type_to_stree t2)  (S")")))))
/\
(type_to_stree Tnum =
  S"int")
/\
(type_to_stree Tbool =
  S"bool")`;

val _ = Defn.save_defn type_to_stree_defn;

val _ = Define `
 (variant_to_stree sml (c,ts) = A 
  (var_to_stree sml c) (A   (if ts = [] then S"" else S" of ") 
  (join_strings (S" * ") (MAP type_to_stree ts))))`;


(*val typedef_to_stree : bool -> num -> tvarN list * typeN * (conN * t list) list -> stree*)
val _ = Define `
 (typedef_to_stree sml indent (tvs, name, variants) = A 
  (if tvs = [] then 
     S"" 
   else A  
     (S"(") (A   (join_strings (S",") (MAP S tvs))  (S") "))) (A  
  (S name) (A   
  (S " =") (A  
  (newline (inc_indent (inc_indent indent))) 
  (join_strings ( A (newline (inc_indent indent))  (S"| ")) 
               (MAP (variant_to_stree sml) variants))))))`;


val _ = Define `
 (dec_to_stree sml indent d =
  (case d of
      Dlet p e => A 
        (if sml then S"val " else S"let ") (A  
        (pat_to_stree sml p) (A   
        (S" = ") (A   
        (exp_to_stree sml (inc_indent indent) e) 
        (if sml then S";" else S";;"))))
    | Dletrec funs => A 
        (if sml then S"fun " else S"let rec ") (A   
        (join_strings ( A (newline indent)  (S"and ")) 
                     (MAP (fun_to_stree sml indent) funs)) 
        (if sml then S";" else S";;"))
    | Dtype types => A 
        (if sml then S"datatype " else S"type ") (A   
        (join_strings ( A (newline indent)  (S"and ")) 
                     (MAP (typedef_to_stree sml indent) types)) 
        (if sml then S";" else S";;"))
  ))`;


val _ = Define `
 (dec_to_sml_string d = stree_to_string (dec_to_stree T 0 d) "")`;

val _ = Define `
 (dec_to_ocaml_string d = stree_to_string (dec_to_stree F 0 d) "")`;

val _ = export_theory()

