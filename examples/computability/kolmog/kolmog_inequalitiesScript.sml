open HolKernel Parse boolLib bossLib

open arithmeticTheory whileTheory logrootTheory pred_setTheory listTheory
open reductionEval;
open churchoptionTheory churchlistTheory recfunsTheory numsAsCompStatesTheory
     kolmogorov_complexityTheory invarianceResultsTheory boolListsTheory
open churchDBTheory
open recursivefnsTheory primrecfnsTheory prtermTheory
open unary_recfnsTheory

val _ = new_theory "kolmog_inequalities"
val _ = intLib.deprecate_int()

(* UCKC is conditional kolmogorov complexity, UKCB is kolmogorov complexity typed the right way *)
Theorem pair_11[simp]:
  pair a b = pair c d <=> a=c ∧ b=d
Proof
  rw[EQ_IMP_THM,pair_def,bar_def] >>
  `LENGTH a = LENGTH c ∧ a++b = c++d` by
    (`Tpow (LENGTH a) ++ [F] ++ (a ++ b) = Tpow (LENGTH c) ++ [F] ++ (c ++ d)` by metis_tac[APPEND_ASSOC] >> metis_tac[Tpow_Fapp_eq]) >>
  `DROP (LENGTH a) (a++b) = DROP (LENGTH c) (c++d)` by fs[] >>
  `TAKE (LENGTH a) (a++b) = TAKE (LENGTH c) (c++d)` by fs[] >>
  fs[rich_listTheory.DROP_LENGTH_APPEND,rich_listTheory.TAKE_LENGTH_APPEND]
QED



Definition univ_mach_def:
  univ_mach U <=>
     (∀i y x. U (pair y (pair i x)) = on2bl (Phi (bl2n i) (bl2n (pair y x)))) ∧
     ∀m. (∀i y x. m <> pair y (pair i x)) ==> U m = NONE
End

Theorem Tpow_0[simp]:
  Tpow 0 = []
Proof
  fs[Tpow_def]
QED

Theorem pair_nil[simp]:
  pair [] x = F::x
Proof
  fs[pair_def,bar_def]
QED

Definition subndiv2_def:
  subndiv2 n = recCn (recCn (SOME o pr_div)
                            [SOME o proj 0;K (SOME 2)])
                     [recCn (SOME o (pr2 $-)) [SOME o proj 0;K (SOME n)]]
End

Theorem subndiv2_rec[simp]:
  recfn (subndiv2 n) 1
Proof
  simp[subndiv2_def] >> rpt (irule recfnCn >> rw[]) >>
  irule primrec_recfn >> fs[primrec_rules]
QED

Theorem subndiv2_correct[simp]:
  subndiv2 n [m] = SOME ((m-n) DIV 2)
Proof
  fs[subndiv2_def, recursivefnsTheory.recCn_def]
QED

Theorem recfn_rec2_Phi[simp]:
  recfn (rec2 Phi) 2
Proof
  mp_tac prtermTheory.recfn_recPhi >> rw[Excl"recfn_recPhi"]
QED

Theorem unary_rec_fns_phi:
  recfn f 1 ==> ∃i. ∀x. Phi i x = f [x]
Proof
  rw[] >> drule_then strip_assume_tac recfns_in_Phi >> qexists_tac`i` >> rw[] >>
  `Phi i (fold [x]) = f [x]` by fs[] >> fs[unary_recfnsTheory.fold_def]
QED

Theorem univ_mach_rf:
  univ_mach U ==> univ_rf U
Proof
  rw[univ_mach_def,univ_rf_def] >>
  qabbrev_tac`G=recCn recPhi [K (SOME f);subndiv2 1]` >>
  `recfn G 1` by (simp[Abbr`G`] >> rpt (irule recfnCn >> rw[])) >>
  ‘∀x. G [bl2n (F::x)] = Phi f (bl2n x)’ by
    (simp[Abbr`G`,recCn_def,bool_list_to_num_def]) >>
  drule_then strip_assume_tac recfns_in_Phi >>
  LAST_X_ASSUM (qspecl_then [`n2bl i`,`[]`] mp_tac) >> rw[] >> fs[pair_def] >>
  qexists_tac`F::bar (n2bl i)` >> rw[] >> `Phi f x = Phi i (bl2n (F::n2bl x))` suffices_by fs[]>>
  `G [bl2n (F::n2bl x)] = Phi f (bl2n (n2bl x))` by fs[] >>
  `Phi i (fold [bl2n (F::n2bl x)]) = G [bl2n (F::n2bl x)]` by simp[] >> fs[]
QED

Theorem on2bl_SOME:
  on2bl x = SOME y <=> (∃z. x = SOME z ∧ y = n2bl z)
Proof
 simp[on2bl_def]
QED



(* rename pair to bl pair etc *)

Definition blsnd_def:
  blsnd l = let l' = dropWhile ((=) T) l; sz = LENGTH l - LENGTH l'; in DROP (sz+1) l'
End

Theorem dropWhile_Tpow:
  dropWhile ((=) T) (Tpow n ++ [F] ++ a ++ b) = [F]++a++b
Proof
  Induct_on`n` >> fs[tpow_suc]
QED

Theorem blsnd_pair[simp]:
  blsnd (pair a b) = b
Proof
  fs[blsnd_def,pair_def,bar_def,dropWhile_Tpow] >> qmatch_abbrev_tac`DROP m _ = _` >>
  `m = LENGTH a` suffices_by fs[rich_listTheory.DROP_LENGTH_APPEND] >>
  fs[Abbr`m`]
QED

Definition nblsnd0_def:
  nblsnd0 x = if EVEN x ∧ x<>0 then let (nr) = nblsnd0 ((x-2) DIV 2) in
                ((nfst nr)+1) *, (nsnd nr)
              else 0 *, x
Termination
WF_REL_TAC`$<` >>rw[DIV_LT_X]
End

Theorem bl2n_eq0[simp]:
  bl2n x = 0 <=> x = []
Proof
  Cases_on`x` >> simp[bool_list_to_num_def] >> rw[]
QED

Theorem nblsnd0_correct:
  nblsnd0 (bl2n (Tpow n ++ [F] ++ x)) = n *, bl2n ([F] ++ x)
Proof
  Induct_on`n` >-  fs[Once nblsnd0_def,bool_list_to_num_def,tpow_suc,EVEN_ADD,EVEN_MULT] >>
  simp[Once nblsnd0_def] >> simp[bool_list_to_num_def,tpow_suc,EVEN_ADD,EVEN_MULT]
QED

Definition nblsr_def[simp]:
  nblsr x 0 = x ∧
  nblsr x (SUC n) = nblsr ((x-1) DIV 2) n
End

Theorem nblsr0[simp]:
  nblsr 0 n = 0
Proof
  Induct_on`n` >> simp[]
QED



Theorem DROP_n2bl:
  ∀n x. DROP n (n2bl x) = n2bl (nblsr x n)
Proof
  Induct_on`n` >> simp[] >> rw[] >>
  Cases_on`x=0`  >> simp[]
  >- (rpt (simp[Once num_to_bool_list_def]) ) >>
  Cases_on`n2bl x` >> simp[]
  >- (pop_assum (mp_tac o Q.AP_TERM `bl2n`) >> simp[bool_list_to_num_def,Excl"bl2n_11"] ) >>
  FIRST_X_ASSUM (qspecl_then [`bl2n t`] mp_tac) >> rw[] >>
  `bl2n t = (x-1) DIV 2` suffices_by fs[] >>
  pop_assum kall_tac >> pop_assum (mp_tac o Q.AP_TERM `bl2n`) >>
  simp[bool_list_to_num_def,Excl"bl2n_11"] >> rw[]
QED

Definition nblsnd_def:
  nblsnd x = let nr = nblsnd0 x; n = nfst nr; r = nsnd nr; in nblsr r (n+1)
End

Theorem nblsnd_correct:
  n2bl (nblsnd (bl2n (pair a b))) = b
Proof
  fs[nblsnd_def,GSYM DROP_n2bl,pair_def,bar_def] >>
  ` DROP (nfst (nblsnd0 (bl2n (Tpow (LENGTH a) ++ [F] ++ (a ++ b))))+1)
     (n2bl (nsnd (nblsnd0 (bl2n (Tpow (LENGTH a) ++ [F] ++ (a ++ b)))))) = b` suffices_by fs[] >>
  `nblsnd0 (bl2n (Tpow (LENGTH a) ++ [F] ++ (a ++ b))) =  (LENGTH a)  ⊗ bl2n ([F] ++ (a ++ b))`
    by metis_tac[nblsnd0_correct] >> fs[rich_listTheory.DROP_LENGTH_APPEND]
QED


Definition pr_nblsr_def:
  pr_nblsr = Pr (proj 0)
                (Cn (pr_div) [Cn (pr2 $-) [proj 1;K 1];K 2])
End

Theorem pr_nblsr_correct:
  ∀n r. pr_nblsr [n;r] = nblsr r n
Proof
  Induct_on`n` >> simp[pr_nblsr_def,nblsr_def] >> rw[] >>
  ` (Pr (proj 0) (Cn pr_div [Cn (pr2 $-) [proj 1; K 1]; K 2]) [n; r] − 1) DIV
        2 = pr_nblsr [n; (r − 1) DIV 2]` suffices_by fs[] >> pop_assum kall_tac >>
  rw[pr_nblsr_def] >> Induct_on`n` >> simp[]
QED

Theorem primrec_pr_nblsr:
  primrec (pr_nblsr) 2
Proof
  simp[pr_nblsr_def,primrec_rules]
QED

Theorem recfn_pr_nblsr:
  recfn (SOME o pr_nblsr) 2
Proof
  irule primrec_recfn >> simp[pr_nblsr_def,primrec_rules]
QED





Definition pr_nblsnd0_def:
  pr_nblsnd0 =
  WFM (λf n. if (EVEN n ∧ n<>0) then (nfst (f ((n-2) DIV 2)) + 1) *, (nsnd (f ((n-2) DIV 2)))
             else 0 *, n)
End

Theorem n_sub2_div2:
  ¬((n-2) DIV 2 < n) ==> n=0
Proof
  rw[] >> `n <= (n-2) DIV 2` by fs[] >> `2*n <= 2* ((n-2) DIV 2)` by fs[] >>
  `2*n <= n-2` by fs[X_LE_DIV] >> Cases_on`n=0` >> simp[]
QED

Theorem pr_nblsnd0_correct:
  pr_nblsnd0 [n] = (pr1 nblsnd0) [n]
Proof
  completeInduct_on`n` >> simp[Once pr_nblsnd0_def,Once nblsnd0_def,Once prnlistTheory.WFM_correct] >>
  rw[]
  >- (qmatch_abbrev_tac`nfst a = nfst b` >> `a=b` suffices_by fs[] >> simp[Abbr`a`,Abbr`b`] >>
      `pr_nblsnd0 [(n-2) DIV 2] = pr1 nblsnd0 [(n-2) DIV 2]` by fs[] >> fs[] >> fs[Once pr_nblsnd0_def])
  >- (qmatch_abbrev_tac`nsnd a = nsnd b` >> `a=b` suffices_by fs[] >> simp[Abbr`a`,Abbr`b`] >>
       `pr_nblsnd0 [(n-2) DIV 2] = pr1 nblsnd0 [(n-2) DIV 2]` by fs[] >> fs[] >> fs[Once pr_nblsnd0_def]) >> metis_tac[n_sub2_div2]
QED



Definition pr_pr_nblsnd0:
pr_pr_nblsnd0 = pr_cond (Cn pr_eq
                          [Cn pr_mod
                              [Cn succ
                                  [proj 0];
                               K 2];
                           K 0])
                      (Cn (pr2 npair)
                          [Cn succ
                              [Cn (pr1 nfst)
                                   [Cn (λl. restr (proj 0 l) (proj 1 l) (proj 2 l) ) [proj 0;proj 1; Cn pr_div [Cn (pr1 PRE) [proj 0];K 2 ] ] ] ];
                           Cn (pr1 nsnd)
                              [Cn (λl. restr (proj 0 l) (proj 1 l) (proj 2 l) ) [proj 0;proj 1; Cn pr_div [Cn (pr1 PRE) [proj 0];K 2 ] ] ] ] )
                      (Cn (pr2 npair)
                          [zerof;
                           Cn succ
                              [proj 0] ] )
End

Theorem primrec_restr_lem:
  primrec (λl. restr (proj 0 l) (proj 1 l) (proj 2 l)) 3
Proof
  `(λl. restr (proj 0 l) (proj 1 l) (proj 2 l)) = pr_cond (Cn pr_le [proj 2;proj 0]) (Cn (pr2 nel) [proj 2;proj 1]) (zerof)` by (fs[FUN_EQ_THM] >> rw[prnlistTheory.restr_def]) >> rw[] >>
  irule primrec_pr_cond >> rw[primrec_rules]
QED

Theorem primrec_pr_nblsnd0:
  primrec pr_nblsnd0 1
Proof
  fs[pr_nblsnd0_def] >> irule prnlistTheory.primrec_WFM >> irule primrec_pr2 >> fs[] >>
  qexists_tac`pr_cond (Cn pr_eq
                          [Cn pr_mod
                              [Cn succ
                                  [proj 0];
                               K 2];
                           K 0])
                      (Cn (pr2 npair)
                          [Cn succ
                              [Cn (pr1 nfst)
                                   [Cn (λl. restr (proj 0 l) (proj 1 l) (proj 2 l) )
                                       [proj 0;proj 1; Cn pr_div [Cn (pr1 PRE) [proj 0];K 2 ] ] ] ];
                           Cn (pr1 nsnd)
                              [Cn (λl. restr (proj 0 l) (proj 1 l) (proj 2 l) )
                                  [proj 0;proj 1; Cn pr_div [Cn (pr1 PRE) [proj 0];K 2 ] ] ] ] )
                      (Cn (pr2 npair)
                          [zerof;
                           Cn succ
                              [proj 0] ] )` >> rw[]
  >- (irule primrec_pr_cond >> rw[primrec_rules] >> rpt (irule unary_recfnsTheory.primrec_Cn >>
      rw[primrec_rules]) >> fs[primrec_restr_lem] )
  >- (`¬EVEN (SUC m)` by fs[ADD1] >> fs[MOD_2] >> rw[ADD1])
  >- (`EVEN (SUC m)` by fs[ADD1] >> fs[MOD_2] >> rw[ADD1])
QED

Definition pr_nblsnd_def:
  pr_nblsnd = Cn pr_nblsr
                 [Cn succ [Cn (pr1 nfst)
                              [Cn pr_nblsnd0
                                  [proj 0]]];
                  Cn (pr1 nsnd)
                     [Cn pr_nblsnd0
                         [proj 0] ] ]
End

Theorem pr_nblsnd_correct:
  pr_nblsnd [n] = (pr1 nblsnd) [n]
Proof
  fs[pr_nblsnd_def,nblsnd_def] >>
  `nsnd (pr_nblsnd0 [n]) = nsnd (nblsnd0 n)` by simp[pr_nblsnd0_correct] >>
  `SUC (nfst (pr_nblsnd0 [n])) = nfst (nblsnd0 n) + 1` by simp[pr_nblsnd0_correct] >>
  simp[pr_nblsr_correct,Excl"nblsr_def"]
QED

Theorem primrec_nblsnd:
  primrec pr_nblsnd 1
Proof
  simp[pr_nblsnd_def] >>
  rpt (irule unary_recfnsTheory.primrec_Cn >>
       rw[primrec_rules,primrec_pr_nblsr,primrec_pr_nblsnd0])
QED

Theorem recfn_nblsnd:
  recfn (SOME o (pr1 nblsnd)) 1
Proof
  irule primrec_recfn >> irule primrecfnsTheory.primrec_pr1 >> qexists_tac`pr_nblsnd` >> rw[primrec_nblsnd,pr_nblsnd_correct]
QED

Theorem nblsnd_index:
  ∃i. ∀x. Phi i x = (SOME o (pr1 nblsnd)) [x]
Proof
  assume_tac recfn_nblsnd >> drule recfns_in_Phi >> rw[] >> qexists_tac`i` >> rw[] >>
  first_x_assum (qspec_then `[x]` mp_tac) >> rw[]
QED

Theorem pair_LENGTH:
  LENGTH (pair a b) = 2*LENGTH a + 1 + LENGTH b
Proof
  simp[pair_def]
QED

Theorem nblsnd_correct2[simp] =
  nblsnd_correct |> AP_TERM``bl2n`` |> SIMP_RULE (srw_ss()) [Excl"bl2n_11"]

Theorem univ_rf_pair_nonempty:
   univ_mach U  ⇒ {p | U (pair y p) = SOME x} ≠ ∅
Proof
  rw[] >>
  ‘{p | U p = SOME x} ≠ ∅’ by fs[univ_rf_nonempty,univ_mach_rf] >>
  fs[EXTENSION, univ_mach_def] >>
  rename [‘U a = SOME result’] >>
  ‘∃i b c. a = pair b (pair i c)’
    by metis_tac[pair_11, optionTheory.NOT_NONE_SOME] >>
  rw[] >> rfs[on2bl_SOME] >>
  qx_choose_then ‘nbli’ strip_assume_tac nblsnd_index >>
  qexists_tac ‘pair (n2bl (bl2n i o nbli)) (pair b c)’ >>
  simp[computable_composition_def, on2bl_SOME, PULL_EXISTS]
QED

Theorem univ_mach_pair_pair:
  univ_mach U ==> ∀p x. U p = SOME x <=>
                        ∃a i b. p = pair a (pair i b) ∧
                                Phi (bl2n i) (bl2n (pair a b)) = SOME (bl2n x)
Proof
  reverse (rw[univ_mach_def,EQ_IMP_THM]) >- rw[on2bl_def] >>
  `∃a b c. p=pair a (pair b c)` by metis_tac[optionTheory.NOT_NONE_SOME] >>
  qexists_tac`a` >> qexists_tac`b` >> qexists_tac`c` >> rw[] >>
  `on2bl (Phi (bl2n b) (bl2n (pair a c)) ) = SOME x` by metis_tac[] >> fs[on2bl_def]
QED

Definition nblft_def:
  nblft x 0 = 0n ∧
  nblft x (SUC n) = if x=0 then 0
                    else (if EVEN x then (2 + 2* (nblft ((x-2) DIV 2) n) )
                          else (1 + 2*(nblft ((x-1) DIV 2) n)))
End

Theorem nblft_zero[simp]:
  nblft 0 x = 0
Proof
  Induct_on`x` >> fs[nblft_def]
QED

Theorem n2bl_zero[simp]:
  n2bl 0 = []
Proof
  simp[Once num_to_bool_list_def]
QED


Theorem n2bl_2_EVEN_lem:
   T::n2bl (x) = n2bl (2 * x + 2)
Proof
  `EVEN (2 * x + 2)` by
    (`EVEN (2*(x+1))` suffices_by rw[LEFT_ADD_DISTRIB] >> metis_tac[EVEN_DOUBLE]) >>
  `n2bl (2*x + 2) = T::(n2bl x)` by (simp[Once num_to_bool_list_def]) >> metis_tac[]
QED

Theorem n2bl_1_ODD_lem:
   F::n2bl (x) = n2bl (2 * x + 1)
Proof
  `ODD (2 * x + 1)` by
    (`∃m. 2*x + 1 = SUC (2*m)` by (qexists_tac`x` >> fs[]) >> metis_tac[ODD_EXISTS] ) >>
  `~EVEN (2 * x + 1)` by fs[ODD_EVEN] >>
  `n2bl (2*x + 1) = F::(n2bl x)` by (simp[Once num_to_bool_list_def]) >> metis_tac[]
QED

Theorem TAKE_n2bl:
  ∀n x. TAKE n (n2bl x) = n2bl (nblft x n)
Proof
  Induct_on`n` >> simp[] >> rw[]  >>
  simp[nblft_def] >>rw[] >>
  simp[Once num_to_bool_list_def] >> rw[n2bl_1_ODD_lem,n2bl_2_EVEN_lem]
QED

Definition nblfst_def:
  nblfst x = (let nr = nblsnd0 x;n=nfst nr;r = nsnd nr in nblft (nblsr r (1)) n)
End

Theorem DROP_bl2n:
  ∀x n. DROP n x = n2bl (nblsr (bl2n x) n)
Proof
  rw[] >> `DROP n (n2bl (bl2n x)) = n2bl (nblsr (bl2n (n2bl (bl2n x))) n)` suffices_by
    (rw[] >> fs[bool_num_inv]) >>
  metis_tac[DROP_n2bl,bool_num_inv]
QED

Theorem nblfst_correct[simp]:
  nblfst (bl2n (pair a b)) = bl2n a
Proof
  `n2bl (nblfst (bl2n (pair a b))) = a` suffices_by
    (rw[] >> `bl2n (n2bl (nblfst (bl2n (pair a b)))) = bl2n a` by fs[] >>
     metis_tac[bool_num_inv]) >>
  fs[nblfst_def,nblsnd_def,GSYM TAKE_n2bl,pair_def,bar_def] >>
  `TAKE (nfst (nblsnd0 (bl2n (Tpow (LENGTH a) ++ [F] ++ (a ++ b) ))))
     (n2bl
        (nblsr (nsnd (nblsnd0 (bl2n (Tpow (LENGTH a) ++ [F] ++ (a ++ b))))) 1)) =
   a` suffices_by fs[] >>
  `nblsnd0 (bl2n (Tpow (LENGTH a) ++ [F] ++ (a ++ b))) =  (LENGTH a)  ⊗ bl2n ([F] ++ (a ++ b))`
    by metis_tac[nblsnd0_correct] >> fs[rich_listTheory.TAKE_LENGTH_APPEND] >>
  simp[GSYM DROP_bl2n] >> fs[rich_listTheory.TAKE_LENGTH_APPEND]
QED

Definition rUMibl_def:
  rUMibl = recCn recPhi
                [recCn (SOME o (pr1 nblfst))
                       [SOME o proj 0];
                 recCn (SOME o (pr1 nblsnd))
                       [SOME o proj 0]]
End

Theorem rUMibl_correct:
  rUMibl [bl2n (pair a b)] = Phi (bl2n a) (bl2n b)
Proof
  fs[rUMibl_def,rec2_def,recCn_def,nblfst_correct,nblsnd_correct2]
QED

Definition lam_nblft_def:
  lam_nblft = LAM "x" (
    LAM "y" (
      VAR "y"
       @@ (K @@ church 0)
       @@ (LAM "r" (
             LAM "x'" (
               cis_zero @@ VAR "x'"
                        @@ church 0
                        @@ (cis_zero
                             @@ (cmod @@ VAR "x'" @@ church 2)
                             @@ (cplus @@ church 2
                                       @@ (cmult @@ church 2
                                                 @@ (VAR "r" @@ (cdiv @@ (cminus @@ VAR"x'"
                                                                                 @@ church 2)
                                                                      @@ church 2) )  ) )
                             @@ (cplus @@ church 1
                                       @@ (cmult @@ church 2
                                                 @@ (VAR "r" @@ (cdiv @@ (cminus @@ VAR"x'"
                                                                                 @@ church 1)
                                                                      @@ church 2) )  ) )  ) )))
       @@ VAR "x"
    )
  )
End

Theorem FV_lam_nblft:
  FV lam_nblft = {}
Proof
  simp[lam_nblft_def,EXTENSION]
QED

Theorem lam_nblft_equiv = brackabs.brackabs_equiv [] lam_nblft_def

Theorem lam_nblft_behaviour:
   ∀x y. lam_nblft @@ church x @@ church y == church (nblft x y)
Proof
  Induct_on`y` >> simp_tac (bsrw_ss()) [lam_nblft_equiv,nblft_def] >> rw[] >>
  simp_tac (bsrw_ss()) [churchboolTheory.cB_behaviour] >> fs[EVEN_MOD2] >>
  simp_tac (bsrw_ss()) [churchboolTheory.cB_behaviour] >>
  full_simp_tac (bsrw_ss()) [lam_nblft_equiv] >> simp[]
QED

Theorem lam_nblft_phi:
  Phi (dBnum (fromTerm (S @@ (B @@ lam_nblft @@ cnfst) @@ cnsnd) ) ) (m *, n) = SOME (nblft m n)
Proof
  simp[Phi_def] >> simp_tac (bsrw_ss()) [lam_nblft_behaviour,normal_orderTheory.bnf_bnf_of]
QED



Theorem nblft_phiii:
  ∀z1 z2. rec2 (λx y. SOME (nblft x y)) [z1;z2] =
  recCn
    (recCn
       recPhi
       [(λx. SOME (K (dBnum (fromTerm (S @@ (B @@ lam_nblft @@ cnfst) @@ cnsnd) ) ) x ) ) ;
        SOME o proj 0 ]) [(SOME ∘ pr2 $*,)] [z1;z2]
Proof
  rpt strip_tac >> simp[Excl"fromTerm_def",recPhi_correct,recCn_def,lam_nblft_phi ]
QED

Theorem nblft_phi_lem:
rec2 (λx y. SOME (nblft x y)) =
  recCn
    (recCn
       recPhi
       [(λx. SOME (K (dBnum (fromTerm (S @@ (B @@ lam_nblft @@ cnfst) @@ cnsnd) ) ) x ) ) ;
        SOME o proj 0 ]) [(SOME ∘ pr2 $*,)]
Proof
  rw[FUN_EQ_THM,Excl"fromTerm_def"] >> Cases_on`x` >> rw[Excl"fromTerm_def"]
  >-(simp[recCn_def,Excl"fromTerm_def"] >> `SOME 0 =
     Phi (dBnum (fromTerm (S @@ (B @@ lam_nblft @@ cnfst) @@ cnsnd))) (0 *, 0)`
       suffices_by simp[Excl"fromTerm_def"] >> simp[lam_nblft_phi]) >>
  Cases_on`t` >> rw[Excl"fromTerm_def"]
  >-(simp[recCn_def,Excl"fromTerm_def"] >> simp[lam_nblft_phi]) >>
  simp[recCn_def,Excl"fromTerm_def"] >> simp[lam_nblft_phi]
QED

Theorem recfn_some_num:
  recfn (λx. SOME (a:num)) 1
Proof
  `(λ(x:num list). SOME a) = K (SOME a)` by (simp[FUN_EQ_THM,combinTheory.K_THM]) >>
  `recfn (K (SOME a)) 1` suffices_by simp[] >> simp[recfn_K]
QED

Theorem recfn_nblfst:
  recfn (rec1 (SOME o nblfst)) 1
Proof
  irule recfn_rec1 >> fs[nblfst_def] >>
  qexists_tac`recCn (rec2 (λx y. SOME (nblft x y) )) [SOME o Cn pr_nblsr [K 1;Cn (pr1 nsnd) [Cn pr_nblsnd0 [proj 0]] ];
                    SOME o Cn (pr1 nfst) [Cn pr_nblsnd0 [proj 0]] ]` >> rw[]
  >- (irule recfnCn >> rw[recfn_rules]
      >- (irule primrec_recfn >>
          rpt (irule unary_recfnsTheory.primrec_Cn >> simp[primrec_pr_nblsr,primrec_rules,primrec_pr_nblsnd0]) )
      >- (irule primrec_recfn >>
          rpt (irule unary_recfnsTheory.primrec_Cn >> simp[primrec_pr_nblsr,primrec_rules,primrec_pr_nblsnd0]))
      >- (simp[nblft_phi_lem,Excl"fromTerm_def"] >> irule recfnCn >>
          rw[recfn_rules,Excl"fromTerm_def"]
          >- (irule primrec_recfn >> simp[primrec_npair]) >> irule recfnCn >>
         rw[recfn_rules,Excl"fromTerm_def"] >> simp[recfn_some_num] )  )
  >- (simp[recCn_def] >>  simp[pr_nblsr_correct,Excl"nblsr_def",ADD1,pr_nblsnd0_correct])
QED

Theorem rec1_pr1:
  SOME o pr1 f = rec1 (SOME o f)
Proof
  simp[FUN_EQ_THM] >> Cases_on`x` >> rw[rec1_def,pr1_def]
QED

Theorem rUMibl_recfn:
  recfn rUMibl 1
Proof
  fs[rUMibl_def] >> irule recfnCn >> rw[] >> irule recfnCn >> rw[recfn_rules,recfn_nblsnd,recfn_nblfst] >> `(SOME ∘ pr1 nblfst) = rec1 (SOME o nblfst)` suffices_by fs[recfn_nblfst] >> fs[rec1_pr1]
QED

Theorem rUMibl_index:
  ∃i. ∀x. Phi i x = rUMibl [x]
Proof
  fs[unary_rec_fns_phi,rUMibl_recfn]
QED

Theorem extra_information1:
  univ_mach U ==> ∃c. ∀x y. (CKC U x y) <= (KC U x) + c
Proof
  rw[KC_def,CKC_def,cond_core_complexity_def,core_complexity_def] >>
  fs[univ_rf_nonempty,univ_rf_pair_nonempty,univ_mach_rf] >>
  `univ_rf U` by fs[univ_mach_rf] >>
  strip_assume_tac nblsnd_index >>
  pop_assum (qspec_then `bl2n (pair a b)` (assume_tac o Q.GENL[`a`,`b`])) >>
  fs[nblsnd_correct2]>> fs[univ_mach_def] >>
  `∀a b. U (pair b (pair (n2bl i) a)) = SOME a` by fs[on2bl_def] >>
  assume_tac rUMibl_index >> fs[] >> rename [`∀x. Phi rUMi x = rUMibl [x]`] >>

  qabbrev_tac`j = rUMi o i` >>
  `∀x y. Phi j (bl2n (pair x y)) = Phi rUMi (bl2n y)` by
    (simp[Abbr`j`,computable_composition_def,nblsnd_correct2]) >>
  pop_assum (qspecl_then [`x`,`pair a b`] (assume_tac o Q.GENL[`x`,`a`,`b`])) >>
  `∀x a b. U (pair x (pair (n2bl j) (pair a b))) = U (pair a (pair (n2bl rUMi) b))` by fs[] >>
  `univ_mach U` by metis_tac[GSYM univ_mach_def] >>
  `∀x a b. Phi j (bl2n (pair x (pair a b))) = Phi (bl2n a) (bl2n b)` by fs[rUMibl_correct] >>

  qexists_tac`2*(LENGTH (n2bl j)) + 1` >> rw[] >> DEEP_INTRO_TAC MIN_SET_ELIM >> rw[]
  >- (simp[EXTENSION] >> metis_tac[]) >>
  DEEP_INTRO_TAC MIN_SET_ELIM >> rw[]
  >-(fs[EXTENSION] >> `{p | U p = SOME x} ≠ ∅` by fs[univ_rf_nonempty] >>
     fs[EXTENSION] >> metis_tac[] ) >> fs[PULL_EXISTS] >>
  `U (pair y (pair (n2bl j) p')) = SOME x` by metis_tac[] >>
  last_x_assum drule >> simp[pair_LENGTH]
QED


val nblfst_i_def =  new_specification ("nblfst_i_def",["nblfst_i"],MATCH_MP unary_rec_fns_phi recfn_nblfst |> SIMP_RULE (srw_ss()) [rec1_def] )


Definition nblconcat_def:
  nblconcat a b = a + b * 2 ** (LENGTH (n2bl a))
End

Theorem nblconcat_correct[simp]:
  nblconcat (bl2n a) (bl2n b) = bl2n (a++b)
Proof
  fs[nblconcat_def,bl2n_append]
QED


Theorem pr_log2_thm[compute]:
  pr_log2 [i] = if i <= 1 then 1 else 1 + pr_log2 [i DIV 2]
Proof
  fs[pr_log2_def,Once prnlistTheory.WFM_correct]
QED

Definition pr_ell:
  pr_ell = WFM (λf n. if n=0 then 0
                      else if EVEN n then 1 + f ((n-2) DIV 2)
                           else 1 + f ((n-1) DIV 2) )
End

Theorem pr_ell_thm:
  pr_ell [n] = if n=0 then 0
               else if EVEN n then 1 + pr_ell [(n-2) DIV 2]
                    else 1 + pr_ell [(n-1) DIV 2]
Proof
  fs[pr_ell,Once prnlistTheory.WFM_correct] >> rw[] >> intLib.ARITH_TAC
QED




Theorem primrec_ell:
  primrec (pr1 ℓ) 1
Proof
  irule primrec_pr1 >> qexists_tac`pr_ell` >> rw[]
  >- (fs[pr_ell] >> irule prnlistTheory.primrec_WFM >>
      rw[prnlistTheory.restr_def,DIV_LESS_EQ] >>
      `∀n. (n-1) DIV 2 <= n` by (intLib.ARITH_TAC) >> simp[] >> irule primrec_pr2 >> simp[] >>
      qexists_tac`pr_cond (Cn pr_mod [proj 0; K 2])
                          (Cn succ [Cn (pr2 nel) [Cn (pr_div) [Cn (pr2 $-) [proj 0;K 1]; K 2];proj 1]])
                          (Cn succ [Cn (pr2 nel) [Cn (pr_div) [proj 0; K 2];proj 1]])` >> rw[]
      >- (irule primrec_pr_cond >> rw[] >> rpt (irule primrec_Cn >> simp[primrec_rules] ) ) >>
      rw[pr_cond_def] >- (`m MOD 2 = 1` suffices_by simp[] >> fs[EVEN_ADD,MOD_2]) >>
      `m MOD 2 = 0` suffices_by simp[] >> fs[EVEN_ADD,MOD_2]  ) >>

  completeInduct_on`n` >> simp[Once pr_ell_thm,Once num_to_bool_list_def] >>  rw[ADD1]>>
  first_x_assum irule >> intLib.ARITH_TAC
QED



Theorem primrec_nblconcat[simp]:
  primrec (pr2 nblconcat) 2
Proof
  irule primrec_pr2 >> fs[nblconcat_def] >>
  qexists_tac
  `Cn (pr2 $+ )
      [proj 0 ;
       Cn (pr2 $* )
          [proj 1 ;
           Cn (λl. FUNPOW (λx. 2*x ) ((proj 0) l) ((K 1n) l)  )
              [Cn (pr1 ℓ )
                  [proj 0] ] ] ] ` >> rw[]
  >- (rpt (irule unary_recfnsTheory.primrec_Cn >>
           rw[primrec_pr_mult,primrec_pr_add,primrec_rules,primrec_ell]) >>
      HO_MATCH_MP_TAC primrec_FUNPOW >> rw[]
      >- (irule primrec_pr1 >> qexists_tac`Cn (pr2 $*) [K 2;proj 0]` >> simp[primrec_rules])
      >- (`(λ(l:num list). 1n) = K 1` suffices_by simp[] >> simp[FUN_EQ_THM] ) >>
      simp_tac (srw_ss()++boolSimps.ETA_ss) [primrec_rules] ) >>
  Q.SPEC_TAC (`ℓ m`,`k`) >> Induct >> simp[FUNPOW_SUC,EXP]
QED



Definition nblpair_to_concat_def:
  nblpair_to_concat = recCn (SOME o pr2 nblconcat) [rec1 (SOME o nblfst);SOME o pr1 nblsnd]
End

Theorem recfn_nblpair_to_concat:
  recfn nblpair_to_concat 1
Proof
  simp[nblpair_to_concat_def] >> irule recfnCn >> rw[recfn_nblsnd,recfn_nblfst,primrec_recfn]
QED

Theorem nblpair_to_concat_correct[simp]:
  nblpair_to_concat [bl2n (pair x y)] = SOME (bl2n (x++y))
Proof
  simp[nblpair_to_concat_def,recCn_def,nblfst_correct,nblsnd_correct2]
QED

val nblpc_i_def =  new_specification ("nblpc_i_def",["nblpc_i"],MATCH_MP unary_rec_fns_phi recfn_nblpair_to_concat)


Definition comp_machine_t_def:
  comp_machine_t =
  LAM "ijx" (
    LAM "ij" (
      LAM "i" (
        LAM "j" (
          LAM "x" (
            cbnf_ofk
              @@ (LAM "r" (UM @@ (cnpair @@ (cnfst @@ VAR "ij")
                                         @@ (cforce_num @@ VAR "r"))))
              @@ (cdAPP @@ (cnumdB @@ (cnsnd @@ VAR "ij"))
                        @@ (cchurch @@ VAR "x"))
          ) @@ (cnsnd @@ VAR "ijx")
        ) @@ (cnsnd @@ VAR "ij")
      ) @@ (cnfst @@ VAR "ij")
    ) @@ (cnfst @@ VAR "ijx")
  )
End

Theorem FV_comp_machine_t[simp]:
  FV comp_machine_t = ∅
Proof
  simp[comp_machine_t_def, EXTENSION]
QED

Triviality comp_machine_equiv = brackabs.brackabs_equiv [] comp_machine_t_def

Theorem comp_machine_t_behaviour_good:
  Phi j x = SOME n ∧ Phi i n = SOME r ⇒
  (comp_machine_t @@ church ((i ⊗ j) ⊗ x) == church r)
Proof
  strip_tac >>
  Q.UNDISCH_THEN ‘Phi j x = SOME n’ mp_tac >>
  simp_tac (bsrw_ss()) [comp_machine_equiv, Phi_def] >> strip_tac >>
  drule cbnf_of_works1 >>
  simp[] >> simp_tac (bsrw_ss())[] >> disch_then (K ALL_TAC) >>
  drule PhiSOME_UM_I >> rw[] >> asm_simp_tac(bsrw_ss()) []
QED

Theorem comp_machine_t_behaviour_bad1:
  Phi j x = NONE ⇒
  bnf_of (comp_machine_t @@ church ((i ⊗ j) ⊗ x)) = NONE
Proof
  strip_tac >>
  simp_tac (bsrw_ss()) [comp_machine_equiv] >>
  simp[PhiNONE_cbnf_ofk]
QED

Theorem comp_machine_t_behaviour_bad2:
  Phi j x = SOME n ∧ Phi i n = NONE ⇒
  bnf_of (comp_machine_t @@ church ((i ⊗ j) ⊗ x)) = NONE
Proof
  strip_tac >>
  Q.UNDISCH_THEN ‘Phi j x = SOME n’ mp_tac >>
  simp_tac (bsrw_ss()) [comp_machine_equiv, Phi_def] >> strip_tac >>
  drule cbnf_of_works1 >> simp_tac (bsrw_ss()) [] >> disch_then (K ALL_TAC) >>
  fs[PhiNONE_UM, normal_orderTheory.bnf_of_NONE]
QED

Definition comp_machine_i_def:
  comp_machine_i = dBnum (fromTerm comp_machine_t)
End

Theorem Phi_comp:
  Phi comp_machine_i ((i ⊗ j) ⊗ x) = Phi (i o j) x
Proof
  simp[computable_composition_def] >>
  simp[SimpLHS, Phi_def, comp_machine_i_def] >>
  Cases_on ‘Phi j x’
  >- simp[comp_machine_t_behaviour_bad1] >>
  rename [‘Phi j x = SOME r’] >>
  Cases_on ‘Phi i r’
  >- (drule_all comp_machine_t_behaviour_bad2 >> simp[]) >>
  drule_all comp_machine_t_behaviour_good >>
  asm_simp_tac (bsrw_ss()) [normal_orderTheory.bnf_bnf_of]
QED

Definition comp_machine_bl:
  comp_machine_bl =
    recCn recPhi [
      SOME o K comp_machine_i;
      recCn (SOME o pr2 $*,) [
        recCn (SOME o pr2 $*,) [
          recCn (rec1 (SOME o nblfst)) [
            recCn (rec1 (SOME o nblfst)) [SOME o proj 0]
          ];
          recCn (SOME o pr1 nblsnd) [
            recCn (rec1 (SOME o nblfst)) [SOME o proj 0]
          ]
        ];
        recCn (SOME o pr1 nblsnd) [SOME o proj 0]
      ]
    ]
End

Theorem recfn_comp_machine_bl[simp]:
  recfn comp_machine_bl 1
Proof
  simp[comp_machine_bl] >>
  rpt (irule recfnCn >> simp[recfn_SOMEnpair, recfn_nblsnd, recfn_rules,
                             recfn_nblfst] >> rw[])
QED

Theorem comp_machine_bl_correct:
  comp_machine_bl [bl2n (pair (pair i j) x)] =
  Phi (bl2n i o bl2n j) (bl2n x)
Proof
  simp[comp_machine_bl, recCn_def, Phi_comp]
QED

val comp_bli = new_specification (
  "comp_bli", ["comp_bli"],
  MATCH_MP unary_rec_fns_phi recfn_comp_machine_bl
);

Theorem subadditivity1:
  univ_mach U ==> ∃c. ∀x y. KC U (x++y) <= KC U (pair x y) + c
Proof
  rw[KC_def,core_complexity_def] >>
  fs[univ_rf_nonempty,univ_rf_pair_nonempty,univ_mach_rf] >>
  `univ_rf U` by fs[univ_mach_rf] >> fs[univ_mach_def] >>
  assume_tac nblpc_i_def >>
  qexists_tac‘4 * ℓ nblpc_i + 2 * ℓ comp_bli + 5’ >>
  rw[] >> DEEP_INTRO_TAC MIN_SET_ELIM >> rw[]
  >-(fs[EXTENSION] >> `{p | U p = SOME (x++y)} ≠ ∅` by fs[univ_rf_nonempty] >>
     fs[EXTENSION] >> metis_tac[] ) >>
  DEEP_INTRO_TAC MIN_SET_ELIM >> rw[]
  >-(fs[EXTENSION] >>
     ‘{p | U p = SOME (pair x y)} ≠ ∅’
      by fs[univ_rf_nonempty] >>
     fs[EXTENSION] >> metis_tac[] ) >>
  fs[PULL_EXISTS] >> rename[`U pp = SOME (pair x y)`] >>
  ‘∃pi a b. pp = pair a (pair pi b)’ by metis_tac[optionTheory.NOT_SOME_NONE] >>
  rw[] >> rfs[on2bl_SOME] >>
  qabbrev_tac ‘
    ARG = pair (pair (n2bl nblpc_i) pi) (pair (n2bl comp_bli) (pair a b))
  ’ >>
  ‘U ARG = SOME (x++y)’
     by (simp[on2bl_SOME, comp_bli, comp_machine_bl_correct, Abbr‘ARG’,
              computable_composition_def] >>
         ‘z = bl2n (pair x y)’ by simp[] >> rw[]) >>
  qmatch_abbrev_tac ‘LENGTH p ≤ RR’ >>
  ‘LENGTH ARG <= RR’ suffices_by metis_tac[LESS_EQ_TRANS] >>
  simp[pair_LENGTH, Abbr‘ARG’, Abbr‘RR’, LEFT_ADD_DISTRIB]
QED


Theorem extra_information2:
  univ_mach U ==> ∃c. ∀x y. KC U x <= KC U (pair x y) + c
Proof
  rw[KC_def,core_complexity_def] >>
  fs[univ_rf_nonempty,univ_rf_pair_nonempty,univ_mach_rf] >>
  `univ_rf U` by fs[univ_mach_rf] >> fs[univ_mach_def] >>
  assume_tac rUMibl_index >>  assume_tac composition_ub >> fs[] >>
  rename [`∀x. Phi rUMi x = rUMibl [x]`,`∀a b. ℓ (a ∘ b) ≤ Ccom + (ℓ a + ℓ b)`] >>
  qabbrev_tac`j = nblfst_i` >>
  qexists_tac`2*(LENGTH (n2bl j)) + 1 + 2*Ccom` >> rw[] >> DEEP_INTRO_TAC MIN_SET_ELIM >> rw[]
  >-(fs[EXTENSION] >> `{p | U p = SOME x} ≠ ∅` by fs[univ_rf_nonempty] >>
     fs[EXTENSION] >> metis_tac[] ) >>
  DEEP_INTRO_TAC MIN_SET_ELIM >> rw[]
  >-(fs[EXTENSION] >> `{p | U p = SOME (pair x y)} ≠ ∅` by fs[univ_rf_nonempty] >>
     fs[EXTENSION] >> metis_tac[] ) >> fs[PULL_EXISTS] >>
  rename[`U pp = SOME (pair x y)`]  >>
  `∃a b c. pp = pair a (pair b c)` by metis_tac[optionTheory.NOT_SOME_NONE] >> rw[] >>
  `U (pair a (pair (n2bl (j o bl2n b)) c) ) = SOME x` by
    (simp[computable_composition_def] >> rfs[on2bl_SOME] >> `z = bl2n (pair x y)` by simp[] >>
     rw[] >> simp[Abbr`j`,computable_composition_def] >> qexists_tac`bl2n x` >> simp[nblfst_i_def,nblfst_correct]) >>
  `LENGTH (pair a (pair (n2bl (j ∘ bl2n b)) c)) <= 2*Ccom + (2 * ℓ j + (LENGTH (pair a (pair b c)) + 1))` suffices_by metis_tac[LESS_EQ_TRANS] >> simp[pair_LENGTH] >>
  `ℓ (j ∘ bl2n b) <= Ccom + LENGTH b + ℓ j` suffices_by fs[] >>
  `ℓ (j ∘ bl2n b) <= Ccom + LENGTH (n2bl (bl2n b)) + ℓ j` suffices_by fs[] >>
   fs[Excl"num_bool_inv.1"]
QED


Theorem subadditivity3:
  univ_mach U ==> ∃c. ∀x y. KC U x + CKC U y x <= KC U x + KC U y + c
Proof
  strip_tac >> `∃c. ∀x y. CKC U y x ≤ KC U y + c`
    suffices_by (rw[] >> qexists_tac`c` >> rw[LE_ADD_LCANCEL] >> `CKC U y x <= KC U y + c` by fs[] >> simp[] ) >>
  metis_tac[extra_information1]
QED

Definition nblTpow_def:
  nblTpow = Cn (pr2 $-) [(λl. FUNPOW (λx. 2*x ) (Cn succ [proj 0] l) ((K 1n) l)  );K 2]
End

Theorem nblTpow_compute:
  nblTpow [n] = 2**(n+1) - 2
Proof
  Induct_on`n` >> fs[nblTpow_def,FUNPOW_SUC,EXP,GSYM ADD1] >>
  `2*FUNPOW (λx. 2 * x) n 1 -2 + 2 = 2*2 ** n -2 + 2` by fs[] >> Cases_on`n=0` >> simp[] >>
  `2*FUNPOW (λx. 2 * x) n 1 = 2*2 ** n` suffices_by rw[] >>
  `2 <= FUNPOW (λx. 2 * x) n 1 ∧ 2<= 2**n` suffices_by fs[SUB_ADD] >> rw[X_LE_X_EXP] >>
  pop_assum mp_tac >> rpt (pop_assum kall_tac) >> rw[] >>
  Induct_on`n` >> rw[FUNPOW_SUC] >>  pop_assum kall_tac >> Induct_on`n` >> rw[FUNPOW_SUC]
QED




Theorem primrec_nblTpow:
  primrec nblTpow 1
Proof
  simp[nblTpow_def,Excl"K_THM.1",Excl"Cn0123.1"] >> irule primrec_Cn >> rw[Excl"K_THM.1",Excl"Cn0123.1"] >> irule primrec_FUNPOW >> rw[primrec_rules] >> irule primrec_pr1 >> rw[] >> qexists_tac`Cn (pr2 $*) [K 2;proj 0]` >> rw[] >> irule primrec_Cn >> rw[primrec_rules]
QED




Definition nblpair_def:
  nblpair = Cn (pr2 nblconcat)
               [Cn (pr2 nblconcat)
                   [Cn (pr2 nblconcat)
                       [Cn nblTpow
                           [Cn (pr1 (λp. ℓ p))
                               [proj 0]];
                        K 1];
                    proj 0];
                proj 1]
End



Theorem primrec_nblpair:
  primrec nblpair 2
Proof
  simp[nblpair_def] >> rpt (irule primrec_Cn >> rw[primrec_rules,primrec_nblconcat,primrec_nblTpow,primrec_ell])
QED

Theorem nblconcat_correct2:
  nblconcat a b = bl2n ((n2bl a)++(n2bl b))
Proof
  `∃x. a = bl2n x ∧ ∃y. b=bl2n y` by (qexists_tac`n2bl a` >> rw[] >> qexists_tac`n2bl b` >> rw[]) >>  fs[nblconcat_correct]
QED

Theorem nblTpow_correct:
  nblTpow [n] = bl2n (Tpow n)
Proof
  simp[Tpow_def,nblTpow_compute] >> Induct_on`n` >> rw[] >- simp[Once bool_list_to_num_def] >>
  simp[GSYM ADD1,EXP,GENLIST_CONS,Once bool_list_to_num_def] >> fs[EXP,GSYM ADD1] >>
  Cases_on`n=0` >- fs[Once bool_list_to_num_def] >>
  `4 * 2 ** n − 2 - 2 = 2 * bl2n (GENLIST (K T) n) + 2 - 2 ` by fs[CANCEL_SUB] >>
  fs[] >>
  `4 * 2 ** n − 4 + 2 = 2 * bl2n (GENLIST (K T) n) + 2` by fs[] >>
  `4 * 2 ** n − 4 + 2 = 4 * 2 ** n − 2` suffices_by fs[] >>
  rpt (pop_assum kall_tac) >>
  Induct_on`n` >> simp[EXP]
QED



Theorem nblpair_correct:
  nblpair [x;y] = bl2n (pair (n2bl x) (n2bl y))
Proof
  rw[nblpair_def,nblconcat_correct2,pair_def,bar_def,nblTpow_correct] >>
  simp[Once num_to_bool_list_def]
QED

Definition nblpair_flip_def:
  nblpair_flip = recCn (SOME o nblpair) [SOME o pr1 nblsnd;rec1 (SOME o nblfst)]
End



Theorem recfn_nblpair_flip:
  recfn nblpair_flip 1
Proof
  simp[nblpair_flip_def] >> irule recfnCn >> rw[recfn_nblsnd,recfn_nblfst,primrec_recfn] >>
  irule primrec_recfn >> simp[primrec_nblpair]
QED

Theorem nblpair_flip_correct[simp]:
  nblpair_flip [bl2n (pair x y)] = SOME (bl2n (pair y x))
Proof
  simp[nblpair_flip_def,recCn_def,nblfst_correct,nblsnd_correct2,nblpair_correct]
QED

val nblpf_i_def =  new_specification ("nblpf_i_def",["nblpf_i"],MATCH_MP unary_rec_fns_phi recfn_nblpair_flip)

Theorem symmetry_of_information2a:
  univ_mach U ==> ∃c. ∀x y. KC U (pair x y) <= KC U (pair y x) + c
Proof
  rw[KC_def,core_complexity_def] >>
  fs[univ_rf_nonempty,univ_rf_pair_nonempty,univ_mach_rf] >>
  `univ_rf U` by fs[univ_mach_rf] >> fs[univ_mach_def] >>
  assume_tac composition_ub >> fs[] >>
  rename [`∀a b. ℓ (a ∘ b) ≤ Ccom + (ℓ a + ℓ b)`] >>
  qabbrev_tac`j = nblpf_i` >>
  qexists_tac`2*(LENGTH (n2bl j)) + 1 + 2*Ccom` >> rw[] >> DEEP_INTRO_TAC MIN_SET_ELIM >> rw[]
  >-(fs[EXTENSION] >> `{p | U p = SOME (pair x y)} ≠ ∅` by fs[univ_rf_nonempty] >>
     fs[EXTENSION] >> metis_tac[] ) >>
  DEEP_INTRO_TAC MIN_SET_ELIM >> rw[]
  >-(fs[EXTENSION] >> `{p | U p = SOME (pair y x)} ≠ ∅` by fs[univ_rf_nonempty] >>
     fs[EXTENSION] >> metis_tac[] ) >> fs[PULL_EXISTS] >>
  rename[`U pp = SOME (pair y x)`]  >>
  `∃a b c. pp = pair a (pair b c)` by metis_tac[optionTheory.NOT_SOME_NONE] >> rw[] >>
  `U (pair a (pair (n2bl (j o bl2n b)) c) ) = SOME (pair x y)` by
    (simp[computable_composition_def] >> rfs[on2bl_SOME] >> `z = bl2n (pair y x)` by simp[] >>
     rw[] >> simp[Abbr`j`,computable_composition_def] >> qexists_tac`bl2n (pair x y)` >> simp[nblpf_i_def,nblpair_correct]) >>
  `LENGTH (pair a (pair (n2bl (j ∘ bl2n b)) c)) <= 2*Ccom + (2 * ℓ j + (LENGTH (pair a (pair b c)) + 1))` suffices_by metis_tac[LESS_EQ_TRANS] >> simp[pair_LENGTH] >>
  `ℓ (j ∘ bl2n b) <= Ccom + LENGTH b + ℓ j` suffices_by fs[] >>
  `ℓ (j ∘ bl2n b) <= Ccom + LENGTH (n2bl (bl2n b)) + ℓ j` suffices_by fs[] >>
   fs[Excl"num_bool_inv.1"]
QED

(* up to here *)

Theorem subadditivity2:
  univ_mach U ==> ∃c. ∀x y. KC U (pair x y) <= KC U x +  CKC U y x + c
Proof
  rw[KC_def,core_complexity_def,CKC_def,cond_core_complexity_def] >>
  fs[univ_rf_nonempty,univ_rf_pair_nonempty,univ_mach_rf] >>
  `univ_rf U` by fs[univ_mach_rf] >> fs[univ_mach_def] >>


  strip_assume_tac nblsnd_index >>
  pop_assum (qspec_then `bl2n (pair a b)` (assume_tac o Q.GENL[`a`,`b`])) >>
  fs[nblsnd_correct2]>> fs[univ_mach_def] >>
  `∀a b. U (pair b (pair (n2bl i) a)) = SOME a` by fs[on2bl_def] >>
  assume_tac rUMibl_index >> fs[] >> rename [`∀x. Phi rUMi x = rUMibl [x]`] >>

  qabbrev_tac`j = rUMi o i` >>
  `∀x y. Phi j (bl2n (pair x y)) = Phi rUMi (bl2n y)` by
    (simp[Abbr`j`,computable_composition_def,nblsnd_correct2]) >>
  pop_assum (qspecl_then [`x`,`pair a b`] (assume_tac o Q.GENL[`x`,`a`,`b`])) >>
  `∀x a b. U (pair x (pair (n2bl j) (pair a b))) = U (pair a (pair (n2bl rUMi) b))` by fs[] >>
  `univ_mach U` by metis_tac[GSYM univ_mach_def] >>
  `∀x a b. Phi j (bl2n (pair x (pair a b))) = Phi (bl2n a) (bl2n b)` by fs[rUMibl_correct] >>

  qexists_tac`2*(LENGTH (n2bl j)) + 1` >> rw[] >> DEEP_INTRO_TAC MIN_SET_ELIM >> rw[]
  >- () >>
  DEEP_INTRO_TAC MIN_SET_ELIM >> rw[] >- () >>
  DEEP_INTRO_TAC MIN_SET_ELIM >> rw[] >- () >>

  `U (pair y (pair (n2bl j) p')) = SOME x` by metis_tac[] >>
  last_x_assum drule >> simp[pair_LENGTH]
QED




Theorem symmetry_of_information1a:
  univ_mach U ==> ∃c. ∀x y.  CKC U x (pair y (KC U y)) + KC U y <= KC U (pair x y) + c
Proof

QED

Theorem symmetry_of_information1b:
  univ_mach U ==> ∃c. ∀x y. KC U (pair x y) <=  CKC U x (pair y (KC U y)) + KC U y + c
Proof

QED

Theorem symmetry_of_information2b:
  univ_mach U ==> ∃c. ∀x y.  CKC U y (pair x (KC U x)) + KC U x <=
                           CKC U x (pair y (KC U y)) + KC U y + c
Proof

QED



val _ = export_theory()
