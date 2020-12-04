Require Import Reals Lra.

Local Open Scope R.

Lemma exp_gt1 (x : R) : 0 < x -> 1 < exp x.
Proof.
  intro xgt.
  generalize (exp_ineq1 x xgt); intros.
  apply Rlt_trans with (r2 := 1+x); lra.
Qed.

Lemma exp_ineq (x : R) : 1 + x <= exp x.
Proof.
  destruct (total_order_T 0 x) as [[xlt|xeq]|xgt].
  - left; now apply exp_ineq1.
  - rewrite <- xeq, exp_0; lra.
  - destruct (MVT_cor2 (fun x => exp x - (x + 1)) (fun x => exp x - 1) x 0 xgt) as [c [HH1 HH2]].
    + intros.
      apply derivable_pt_lim_minus; [apply derivable_pt_lim_exp | ].
      replace (1) with (1 + 0) at 1 by lra.
      apply derivable_pt_lim_plus; 
        [apply derivable_pt_lim_id | apply derivable_pt_lim_const].
    + rewrite exp_0 in HH1; ring_simplify in HH1.
      apply Ropp_eq_compat in HH1; ring_simplify in HH1.
      apply Rge_le; apply Rminus_ge.
      ring_simplify; rewrite HH1; left.
      replace (x * exp c - x) with ((-x)*(1-exp c)) by lra.
      apply Rmult_lt_0_compat; [lra | ].
      apply Rgt_minus.
      replace (c) with (- - c) by lra.
      rewrite exp_Ropp.
      replace (1) with (/ 1) by lra.
      apply  Rinv_1_lt_contravar; [lra |].
      apply exp_gt1; lra.
Qed.
