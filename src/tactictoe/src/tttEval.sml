(* ========================================================================= *)
(* FILE          : tacticToe.sml                                             *)
(* DESCRIPTION   : Automated theorem prover based on tactic selection        *)
(* AUTHOR        : (c) Thibault Gauthier, University of Innsbruck            *)
(* DATE          : 2017                                                      *)
(* ========================================================================= *)

structure tttEval :> tttEval =
struct

open HolKernel Abbrev boolLib aiLib tttSetup tacticToe

val ERR = mk_HOL_ERR "tacticToe"

(* -------------------------------------------------------------------------
   Evaluation function called by tttUnfold.run_evalscript_thy
   ------------------------------------------------------------------------- *)

fun print_status r = case r of
   ProofSaturated => print_endline "tactictoe: saturated"
 | ProofTimeout   => print_endline "tactictoe: timeout"
 | Proof s        => print_endline ("tactictoe: proven\n  " ^ s)

fun ttt_eval (thmdata,tacdata) goal =
  let
    val b = !hide_flag
    val _ = hide_flag := false
    val _ = print_endline ("ttt_eval: " ^ string_of_goal goal)
    val (status,t) = add_time (main_tactictoe (thmdata,tacdata)) goal
  in
    print_status status;
    print_endline ("ttt_eval time: " ^ rts_round 6 t ^ "\n");
    hide_flag := b
  end

(* ------------------------------------------------------------------------
   Evaluation: requires recorded savestates.
   The recorded savestates can be produced by setting ttt_savestate_flag
   before calling ttt_clean_record () and ttt_record ().
   Warning: requires ~100 GB of hard disk space. Possibly avoid using MLTON?
   ------------------------------------------------------------------------ *)

fun sreflect_real s r = ("val _ = " ^ s ^ " := " ^ rts (!r) ^ ";")
fun sreflect_flag s flag = ("val _ = " ^ s ^ " := " ^ bts (!flag) ^ ";")

fun write_evalscript prefix file =
  let
    val file1 = mlquote (file ^ "_savestate")
    val file2 = mlquote (file ^ "_goal")
    val sl =
    ["PolyML.SaveState.loadState " ^ file1 ^ ";",
     "val tactictoe_goal = mlTacticData.import_goal " ^ file2 ^ ";",
     "load " ^ mlquote "tacticToe" ^ ";",
     sreflect_real "tttSetup.ttt_search_time" ttt_search_time,
     sreflect_real "tttSetup.ttt_policy_coeff" ttt_policy_coeff,
     sreflect_real "tttSetup.ttt_explo_coeff" ttt_explo_coeff,
     sreflect_flag "tttSetup.thml_explo_flag" thml_explo_flag,
     sreflect_flag "aiLib.debug_flag" debug_flag,
     "tttEval.ttt_eval " ^
     "(!tttRecord.thmdata_glob, !tttRecord.tacdata_glob) " ^
     "tactictoe_goal;"]
  in
    writel (file ^ "_eval.sml") sl
  end

fun bare file = OS.Path.base (OS.Path.file file)

fun run_evalscript dir file =
  (
  write_evalscript (bare file) file;
  run_buildheap_nodep dir (file ^ "_eval.sml")
  )

fun run_evalscript_thyl expname b ncore thyl =
  let
    val dir = ttt_eval_dir ^ "/" ^ expname ^ (if b then "" else "_tenth")
    val _ = (mkDir_err ttt_eval_dir; mkDir_err dir)
    val thyl' = filter (fn x => not (mem x ["min","bool"])) thyl
    val pbl = map (fn x => tactictoe_dir ^ "/savestate/" ^ x ^ "_pbl") thyl'
    fun f x = (readl x handle Interrupt => raise Interrupt 
      | _ => (print_endline x; []))
    val filel1 = List.concat (map f pbl)
    val filel2 = if b then filel1 else one_in_n 10 0 filel1
    val _ = print_endline ("evaluation: " ^ its (length filel2) ^ " problems")
    val (_,t) = add_time (parapp_queue ncore (run_evalscript dir)) filel2
  in
    print_endline ("evaluation time: " ^ rts_round 6 t)
  end

(* One example
load "tttUnfold"; open tttUnfold;
tttSetup.ttt_search_time := 5.0;
run_evalscript (tttSetup.tactictoe_dir ^ "/savestate/arithmetic170");
*)

(* One theory
load "tttUnfold"; open tttUnfold;
tttSetup.record_savestate_flag := true;
tttSetup.learn_abstract_term := true;
aiLib.debug_flag := true;
ttt_clean_record (); ttt_record_thy "arithmetic";
load "tacticToe"; open tacticToe; tactictoe ``1+1=2``;

tttSetup.ttt_search_time := 10.0;
run_evalscript_thyl "test_arithmetic-e1" false 1 ["arithmetic"];
*)

(* Core theories
load "tttUnfold"; open tttUnfold;
tttSetup.record_savestate_flag := true;
tttSetup.learn_abstract_term := false;
aiLib.debug_flag := true;
ttt_clean_record (); ttt_record ();

load "tttUnfold"; open tttUnfold;
tttSetup.ttt_search_time := 30.0;
aiLib.debug_flag := false;
tttSetup.thml_explo_flag := false;
val thyl = aiLib.sort_thyl (ancestry (current_theory ()));
val _ = run_evalscript_thyl "june4-e1" true 30 thyl;

tttSetup.ttt_search_time := 30.0;
aiLib.debug_flag := false;
tttSetup.thml_explo_flag := true;
val thyl = aiLib.sort_thyl (ancestry (current_theory ()));
val _ = run_evalscript_thyl "june4-e2" true 30 thyl;
*)









end (* struct *)
