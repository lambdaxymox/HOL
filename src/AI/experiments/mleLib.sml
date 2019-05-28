(* ========================================================================= *)
(* FILE          : mleLib.sml                                                *)
(* DESCRIPTION   : Useful functions for the experiments                      *)
(* AUTHOR        : (c) Thibault Gauthier, University of Innsbruck            *)
(* DATE          : 2018                                                      *)
(* ========================================================================= *)

structure mleLib :> mleLib =
struct

open HolKernel Abbrev boolLib aiLib

val ERR = mk_HOL_ERR "mleLib"


(* -------------------------------------------------------------------------
   Arithmetic
   ------------------------------------------------------------------------- *)

fun mk_suc x = mk_comb (``SUC``,x);
fun mk_add (a,b) = list_mk_comb (``$+``,[a,b]);
val zero = ``0:num``;
fun mk_sucn n = funpow n mk_suc zero;
fun mk_mult (a,b) = list_mk_comb (``$*``,[a,b]);

fun dest_suc x =
  let val (a,b) = dest_comb x in
    if not (term_eq  a ``SUC``) then raise ERR "" "" else b
  end

fun dest_add tm =
  let val (oper,argl) = strip_comb tm in
    if not (term_eq oper ``$+``) then raise ERR "" "" else pair_of_list argl
  end

fun is_suc_only tm =
  if term_eq tm zero then true else
  (is_suc_only (dest_suc tm)  handle HOL_ERR _ => false)


(* -------------------------------------------------------------------------
   Position
   ------------------------------------------------------------------------- *)

type pos = int list

fun subst_pos (tm,pos) res =
  if null pos then res else
  let
    val (oper,argl) = strip_comb tm
    fun f i x = if i = hd pos then subst_pos (x,tl pos) res else x
    val newargl = mapi f argl
  in
    list_mk_comb (oper,newargl)
  end

fun find_subtm (tm,pos) =
  if null pos then tm else
  let val (oper,argl) = strip_comb tm in
    find_subtm (List.nth (argl,hd pos), tl pos)
  end

fun narg_ge n (tm,pos) =
  let val (_,argl) = strip_comb (find_subtm (tm,pos)) in length argl >= n end

fun all_pos tm =
  let
    val (oper,argl) = strip_comb tm
    fun f i arg = map (fn x => i :: x) (all_pos arg)
  in
    [] :: List.concat (mapi f argl)
  end

(* -------------------------------------------------------------------------
   Equality
   ------------------------------------------------------------------------- *)

fun sym x = mk_eq (swap (dest_eq x))

fun unify a b = Unify.simp_unify_terms [] a b

fun paramod_ground eq (tm,pos) =
  let
    val (eql,eqr) = dest_eq eq
    val subtm = find_subtm (tm,pos)
    val sigma = unify eql subtm
    val eqrsig = subst sigma eqr
    val tmsig = subst sigma tm
    val result = subst_pos (tmsig,pos) eqrsig
  in
    if term_eq result tm orelse length (free_vars_lr result) > 0
    then NONE
    else SOME result
  end
  handle Interrupt => raise Interrupt | _ => NONE


end (* struct *)
