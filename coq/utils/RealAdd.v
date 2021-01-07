Require Import Program.Basics.
Require Import Coq.Reals.Rbase Coq.Reals.RList.
Require Import Coq.Reals.Rfunctions.
Require Import Ranalysis_reg.
Require Import Coquelicot.Hierarchy Coquelicot.PSeries Coquelicot.Series Coquelicot.ElemFct.
Require Import Coquelicot.Lim_seq Coquelicot.Lub Coquelicot.Rbar.
Require Import Lia Lra.
Require Import Reals.Integration.
Require Import Rtrigo_def.
Require Import List.
Require Import Morphisms Permutation.
Require Import EquivDec.

Require Import LibUtils ListAdd.
Require Import Relation_Definitions Sorted.

Set Bullet Behavior "Strict Subproofs".

Import ListNotations.

Local Open Scope R.


Lemma INR_nzero {n} :
  (n > 0)%nat -> INR n <> 0.
Proof.
  destruct n.
  - lia.
  - rewrite S_INR.
    generalize (pos_INR n); intros.
    lra.
Qed.

Lemma INR_nzero_eq {n} :
  (~ n = 0)%nat -> INR n <> 0.
Proof.
  destruct n.
  - lia.
  - rewrite S_INR.
    generalize (pos_INR n); intros.
    lra.
Qed.

Lemma INR_zero_lt {n} :
  (n > 0)%nat -> 0 < INR n.
Proof.
  destruct n.
  - lia.
  - rewrite S_INR.
    generalize (pos_INR n); intros.
    lra.
Qed.

Lemma Rinv_pos n :
  0 < n ->
  0 < / n.
Proof.
  intros.
  rewrite <- (Rmult_1_l ( / n)).
  apply Rdiv_lt_0_compat; lra.
Qed.

Lemma pos_Rl_nth (l:list R) n : pos_Rl l n = nth n l 0.
Proof.
  revert n.
  induction l; destruct n; simpl in *; trivial.
Qed.

Hint Rewrite pos_Rl_nth  : R_iso.

Lemma Rlt_le_sub : subrelation Rlt Rle.
Proof.
  repeat red; intuition.
Qed.

Lemma find_bucket_nth_finds_Rle needle l idx d1 d2:
  StronglySorted Rle l ->
  (S idx < length l)%nat ->
  nth idx l d1 < needle ->
  needle <= nth (S idx) l d2 ->
  find_bucket Rle_dec needle l = Some (nth idx l d1, nth (S idx) l d2).
Proof.
  intros.
  apply find_bucket_nth_finds; trivial
  ; repeat red; intros; lra.
Qed.

Lemma find_bucket_bounded_Rle_exists {a b needle} :
  a <= needle <= b ->
  forall l,
  exists lower upper,
    find_bucket Rle_dec needle (a::l++[b]) = Some (lower, upper).
Proof.
  intros.
  apply find_bucket_bounded_le_exists; intros; lra.
Qed.

Lemma telescope_plus_fold_right_sub_seq f s n :
  fold_right Rplus 0 (map (fun x => (f (INR x)) -  (f (INR (x+1)))) (seq s n)) = (f (INR s)) - (f (INR (s+n))).
Proof.
  Opaque INR.
  revert s.
  induction n; simpl; intros s.
  - replace (s+0)%nat with s by lia.
    lra.
  - specialize (IHn (S s)).
    unfold Rminus in *.    
    rewrite Rplus_assoc in *.
    f_equal.
    simpl in IHn.
    replace (S (s + n))%nat with (s + (S n))%nat in IHn by lia.
    rewrite IHn.
    replace (s+1)%nat with (S s) by lia.
    lra.
    Transparent INR.
Qed.

Lemma fold_right_Rplus_mult_const {A:Type} (f:A->R) c l :
  fold_right Rplus 0 (map (fun x : A => f x * c) l) =
  (fold_right Rplus 0 (map (fun x : A => f x) l))*c.
Proof.
  induction l; simpl; lra.
Qed.

Lemma bounded_dist_le  x lower upper :
  lower <= x <= upper ->
  R_dist x upper <= R_dist lower upper.
Proof.
  intros.
  rewrite (R_dist_sym x).
  rewrite (R_dist_sym lower).
  unfold R_dist.
  repeat rewrite Rabs_pos_eq by lra.
  lra.
Qed.

Lemma bounded_dist_le_P2  x lower upper :
  lower <= x <= upper ->
  R_dist x lower <= R_dist upper lower.
Proof.
  intros.
  unfold R_dist.
  repeat rewrite Rabs_pos_eq by lra.
  lra.
Qed.

Definition interval_increasing f (a b:R) : Prop :=
  forall x y :R, a <= x -> y <= b -> x<=y -> f x <= f y.

Definition interval_decreasing f (a b:R) : Prop :=
  forall x y :R, a <= x -> y <= b -> x<=y -> f y <= f x.

Lemma bounded_increasing_dist_le (f : R -> R) x lower upper :
  interval_increasing f lower upper ->
  lower <= x <= upper ->
  R_dist (f x) (f upper) <= R_dist (f lower) (f upper).
Proof.
  intros df xin.
  apply bounded_dist_le.
  destruct xin as [ltx gtx].
  red in df.
  split; apply df; trivial.
  apply Rle_refl.
  apply Rle_refl.  
Qed.

Lemma bounded_decreasing_dist_le (f : R -> R) x lower upper :
  interval_decreasing f lower upper ->
  lower <= x <= upper ->
  R_dist (f x) (f upper) <= R_dist (f lower) (f upper).
Proof.
  intros df xin.
  apply bounded_dist_le_P2.
  destruct xin as [ltx gtx].
  red in df.
  split; apply df; trivial.
  apply Rle_refl.
  apply Rle_refl.
Qed.

Lemma subinterval_increasing (f : R -> R) (a b x y : R) :
  a <= x -> x <= y -> y <= b -> interval_increasing f a b -> interval_increasing f x y.
Proof.
  intros.
  red in H2.
  red.
  intros.
  cut (y0 <= b).
  cut (a <= x0).
  intuition.
  lra.
  lra.
Qed.

Lemma subinterval_decreasing (f : R -> R) (a b x y : R) :
  a <= x -> x <= y -> y <= b -> interval_decreasing f a b -> interval_decreasing f x y.
Proof.
  intros.
  red in H2.
  red.
  intros.
  cut (y0 <= b).
  cut (a <= x0).
  intuition.
  lra.
  lra.
Qed.

Lemma increasing_decreasing_opp (f : R -> R) (a b:R) :
  a <= b -> interval_increasing f a b -> interval_decreasing (fun x => -f x) a b.
Proof.
  unfold interval_increasing.
  unfold interval_decreasing.
  intros.
  apply Ropp_le_contravar.
  apply H0.
  trivial.
  trivial.
  trivial.
Qed.

Definition Int_SF_alt l k
  := fold_right Rplus 0
                (map (fun '(x,y) => x * y)
                     (combine l
                              (map (fun '(x,y) => y - x) (adjacent_pairs k)))).

Lemma Int_SF_alt_eq l k :
  Int_SF l k = Int_SF_alt l k.
Proof.
  unfold Int_SF_alt.
  revert k.
  induction l; simpl; trivial.
  destruct k; simpl; trivial.
  destruct k; simpl; trivial.
  rewrite IHl; trivial.
Qed.

Lemma up_IZR n : up (IZR n) = (Z.succ n)%Z.
Proof.
  symmetry.
  apply tech_up; try rewrite succ_IZR; lra.
Qed.

Lemma up0 : up 0 = 1%Z.
Proof.
  apply up_IZR.
Qed.

Lemma up_pos (r:R) :
  r>0 -> ((up r) > 0)%Z.
Proof.
  intros.
  destruct (archimed r) as [lb ub].
  assert (IZR (up r) > 0) by lra.
  apply lt_IZR in H0.
  lia.
Qed.

Lemma up_nonneg (r:R) :
  r>=0 -> ((up r) >= 0)%Z.
Proof.
  inversion 1.
  - unfold Z.ge; rewrite up_pos; congruence.
  - subst. rewrite up0.
    lia.
Qed.

Lemma INR_up_pos r :
  r >= 0 -> INR (Z.to_nat (up r)) = IZR (up r).
Proof.
  intros.
  rewrite INR_IZR_INZ.
  rewrite Z2Nat.id; trivial.
  generalize (up_nonneg _ H).
  lia.
Qed.

Lemma frac_max_frac_le (x y:R) :
  1 <= x ->
  x <= y ->
  x / (x + 1) <= y / (y + 1).
Proof.
  intros.
  assert (1 <= x) by lra.
  cut (x * (y + 1) <= y * (x + 1)).
  - intros HH.
    apply (Rmult_le_compat_r (/ (x+1))) in HH.
    + rewrite Rinv_r_simpl_l in HH by lra.
      apply (Rmult_le_compat_r (/ (y+1))) in HH.
      * eapply Rle_trans; try eassumption.
        unfold Rdiv.
        repeat rewrite Rmult_assoc.
        apply Rmult_le_compat_l; [lra | ].
        rewrite <- Rmult_assoc.
        rewrite Rinv_r_simpl_m by lra.
        right; trivial.
      * left; apply Rinv_0_lt_compat; lra.
    + left; apply Rinv_0_lt_compat; lra.
  - lra.
Qed.

Section list_sum.


  Fixpoint list_sum (l : list R) : R :=
    match l with
    | nil => 0
    | x :: xs => x + list_sum xs
    end.

  Lemma list_sum_cat (l1 l2 : list R) :
    list_sum (l1 ++ l2) = (list_sum l1) + (list_sum l2).
  Proof.
    induction l1.
    * simpl ; nra.
    * simpl.  nra.
  Qed.

  Lemma list_sum_map_concat (l : list(list R)) :
    list_sum (concat l) = list_sum (map list_sum l).
  Proof.
    induction l.
    - simpl ; reflexivity.
    - simpl ; rewrite list_sum_cat. now rewrite IHl.
  Qed.



  Global Instance list_sum_Proper : Proper (@Permutation R ==> eq) list_sum.
  Proof.
    unfold Proper. intros x y H.
    apply (@Permutation_ind_bis R (fun a b => list_sum a = list_sum b)).
    - simpl ; lra.
    - intros x0 l l' Hpll' Hll'. simpl ; f_equal. assumption.
    - intros x0 y0 l l' H0 H1. simpl. rewrite H1 ; lra.
    - intros l l' l'' H0 H1 H2 H3. rewrite H1. rewrite <-H3. reflexivity.
    - assumption.
  Qed.

  Lemma list_sum_perm_eq (l1 l2 : list R) : Permutation l1 l2 -> list_sum l1 = list_sum l2.
  Proof.
    intro H.
    now rewrite H.
  Qed.

  Lemma list_sum_const_mul {A : Type} f (l : list A) :
    forall r, list_sum (map (fun x => r*f x) l)  =
              r* list_sum (map (fun x => f x) l).
  Proof.
    intro r.
    induction l.
    simpl; lra.
    simpl. rewrite IHl ; lra.
  Qed.

  Lemma list_sum_map_const {A} (l : list A) (a : A) (f : A -> R) :
    list_sum (map (fun x => f a) l) = INR(length l)* (f a).
  Proof.
    induction l.
    - simpl ; lra.
    - simpl. rewrite IHl.
      enough (match length l with
              | 0%nat => 1
              | S _ => INR (length l) + 1
              end = INR(length l) + 1).
      rewrite H ; lra.
      generalize (length l) as n.
      intro n.  induction n.
      + simpl ; lra.
      + lra.
  Qed.

  Lemma list_sum_map_zero {A} (s : list A)  :
    list_sum (List.map (fun _ => 0) s) = 0.
  Proof.
    induction s.
    - simpl; reflexivity.
    - simpl. rewrite IHs ; lra.
  Qed.


  Lemma list_sum_le {A} (l : list A) (f g : A -> R) :
    (forall a, f a <= g a) ->
    list_sum (List.map f l) <= list_sum (List.map g l).
  Proof.
    intros Hfg.
    induction l.
    - simpl ; right ; trivial.
    - simpl. specialize (Hfg a).
      apply Rplus_le_compat ; trivial.
  Qed.

  Lemma list_sum_mult_const (c : R) (l : list R) :
    list_sum (List.map (fun z => c*z) l) = c*list_sum (List.map (fun z => z) l).
  Proof.
    induction l.
    simpl; lra.
    simpl in *. rewrite IHl.
    lra.
  Qed.

  Lemma list_sum_const_mult_le {x y : R} (l : list R) (hl : list_sum l = R1) (hxy : x <= y) :
    list_sum (List.map (fun z => x*z) l) <= y.
  Proof.
    rewrite list_sum_mult_const. rewrite map_id.
    rewrite hl. lra.
  Qed.

  Lemma list_sum_fun_mult_le {x y D : R} {f g : R -> R}(l : list R)(hf : forall z, f z <= D) (hg : forall z , 0 <= g z) :
    list_sum (List.map (fun z => (f z)*(g z)) l) <= D*list_sum (List.map (fun z => g z) l).
  Proof.
    induction l.
    simpl. lra.
    simpl. rewrite Rmult_plus_distr_l.
    assert (f a * g a <= D * g a). apply Rmult_le_compat_r. exact (hg a). exact (hf a).
    exact (Rplus_le_compat _ _ _ _ H IHl).
  Qed.

  Lemma list_sum_map (A:Type) (f g : A -> R) (l : list A) :
    list_sum (map f l) + list_sum (map g l) = 
    list_sum (map (fun x => f x + g x) l).
  Proof.
    rewrite <- list_sum_cat.
    rewrite map2_app_interleave_perm.
    rewrite list_sum_map_concat.
    rewrite map_map.
    simpl.
    f_equal.
    apply map_ext; intros.
    lra.
  Qed.

  Lemma list_sum_fold_right l : list_sum l = fold_right Rplus 0 l.
  Proof.
    induction l; firstorder.
  Qed.

  Lemma list_sum_pos_pos l :
    Forall (fun x => x >= 0) l ->
    list_sum l >= 0.
  Proof.
    induction l; simpl; try lra.
    intros HH; invcs HH.
    specialize (IHl H2).
    lra.
  Qed.

  Lemma list_sum_all_pos_zero_all_zero l : list_sum l = 0 ->
                                           Forall (fun x => x >= 0) l ->
                                           Forall (fun x => x = 0) l.
  Proof.
    induction l; intros.
    - constructor.
    - invcs H0.
      simpl in H.
      generalize (list_sum_pos_pos _ H4); intros HH.
      assert (a = 0) by lra.
      subst.
      field_simplify in H.
      auto.
  Qed.

End list_sum.

Lemma Rsqrt_le (x y : nonnegreal) : 
  x <= y <-> Rsqrt x <= Rsqrt y.
Proof.
  split; intros.
  - apply Rsqr_incr_0; try apply Rsqrt_positivity.
    unfold Rsqr.
    now repeat rewrite Rsqrt_Rsqrt.
  - rewrite <- (Rsqrt_Rsqrt x).
    rewrite <- (Rsqrt_Rsqrt y).
    apply Rsqr_incr_1; try apply Rsqrt_positivity.
    trivial.
Qed.

Lemma Rsqrt_lt (x y : nonnegreal) : 
  x < y <-> Rsqrt x < Rsqrt y.
Proof.
  split.
  - generalize (Rsqr_incrst_0 (Rsqrt x) (Rsqrt y)); intros.
    apply H.
    unfold Rsqr.
    now repeat rewrite Rsqrt_Rsqrt.
    apply Rsqrt_positivity.
    apply Rsqrt_positivity.    
  - rewrite <- (Rsqrt_Rsqrt x).
    rewrite <- (Rsqrt_Rsqrt y).
    generalize (Rsqr_incrst_1 (Rsqrt x) (Rsqrt y)); unfold Rsqr; intros.
    apply H; trivial.
    apply Rsqrt_positivity.
    apply Rsqrt_positivity.    
Qed.

Lemma Rsqrt_sqr (x:nonnegreal) :
  Rsqrt {| nonneg := x²; cond_nonneg := Rle_0_sqr x |} = x.
Proof.
  unfold Rsqr.
  apply Rsqr_inj.
  - apply Rsqrt_positivity.
  - apply cond_nonneg.
  - unfold Rsqr. rewrite Rsqrt_Rsqrt.
    trivial.
Qed.

Lemma Rsqr_lt_to_Rsqrt (x r:nonnegreal) :
  r < x² <-> Rsqrt r < x.
Proof.
  intros.
  etransitivity.
  - eapply (Rsqrt_lt r (mknonnegreal _ (Rle_0_sqr x))).
  - rewrite Rsqrt_sqr.
    intuition.
Qed.


Lemma Rsqr_le_to_Rsqrt (r x:nonnegreal):
  x² <= r <-> x <= Rsqrt r.
Proof.
  intros.
  etransitivity.
  - eapply (Rsqrt_le (mknonnegreal _ (Rle_0_sqr x)) r).
  - rewrite Rsqrt_sqr.
    intuition.
Qed.

Lemma Rsqr_continuous :
  continuity Rsqr.
Proof.
  apply derivable_continuous.
  apply derivable_Rsqr.
Qed.

Global Instance EqDecR : EqDec R eq := Req_EM_T.

Section sum_n.


  Lemma sum_n_pos {a : nat -> R} (n:nat) : (forall n, 0 < a n) -> 0 < sum_n a n.
  Proof.
    intros.
    induction n.
    - unfold sum_n.
      now rewrite sum_n_n.
    - unfold sum_n.
      rewrite sum_n_Sm.
      apply Rplus_lt_0_compat ; trivial.
      lia.
  Qed.

  Lemma sum_n_zero (n : nat): sum_n (fun _ => 0) n = 0.
  Proof.
    induction n.
    + unfold sum_n. now rewrite sum_n_n.
    + unfold sum_n. rewrite sum_n_Sm.
      unfold sum_n in IHn. rewrite IHn.
      unfold plus. simpl ; lra.
      lia.
  Qed.

  (* TODO(Kody) : Maybe get rid of Functional Extensionality? *)
  Lemma Series_nonneg {a : nat -> R} : ex_series a -> (forall n, 0 <= a n) -> 0 <= Series a.
  Proof.
    intros Ha Hpos.
    generalize (Series_le (fun n => 0) a).
    intros H.
    assert (forall n, 0 <= 0 <= a n) by (intro n; split ; try (lra ; trivial) ; try (trivial)).
    specialize (H H0 Ha).
    assert (Series (fun _ => 0) = 0).
    unfold Series.
    assert (sum_n (fun _ => 0) = (fun _ => 0))
      by (apply FunctionalExtensionality.functional_extensionality ; intros ; apply sum_n_zero).
    rewrite H1. now rewrite Lim_seq_const.
    now rewrite H1 in H.
  Qed.


  Lemma Series_pos {a : nat -> R} : ex_series a -> (forall n, 0 < a n) -> 0 < Series a.
  Proof.
    intros Ha Hpos.
    rewrite Series_incr_1 ; trivial.
    apply Rplus_lt_le_0_compat ; trivial.
    apply Series_nonneg.
    + now rewrite <-ex_series_incr_1.
    + intros n. left. apply (Hpos (S n)).
  Qed.

End sum_n.



Section expprops.

  Lemma ex_series_exp_even (x:R): ex_series (fun k :nat => /INR(fact(2*k))*(x^2)^k).
  Proof.
    generalize (ex_series_le (fun k : nat => /INR(fact (2*k))*(x^2)^k) (fun k : nat => (x^2)^k /INR(fact k)));intros.
    apply H. unfold norm. simpl.
    intros n. replace (n+(n+0))%nat with (2*n)%nat by lia.
    replace (x*1) with x by lra.
    replace ((x*x)^n) with (x^(2*n)).
    rewrite Rabs_mult. rewrite Rmult_comm.
    replace (Rabs (x^(2*n))) with (x^(2*n)).
    apply Rmult_le_compat_l.
    rewrite pow_mult. apply pow_le.
    apply Ratan.pow2_ge_0.
    generalize Rprod.INR_fact_lt_0;intros.
    rewrite Rabs_right.
    apply Rinv_le_contravar ; trivial.
    apply le_INR.
    apply fact_le ; lia.
    left.  apply Rlt_gt.
    apply Rinv_0_lt_compat ; trivial.
    symmetry. apply Rabs_right.
    rewrite pow_mult. apply Rle_ge.
    apply pow_le. apply Ratan.pow2_ge_0.
    rewrite pow_mult. f_equal ; lra.
    exists (exp (x^2)).
    generalize (x^2) as y. intro y.
    apply is_exp_Reals.
  Qed.


  Lemma ex_series_exp_odd (x:R): ex_series (fun k :nat => /INR(fact(2*k + 1)) * (x^2)^k).
  Proof.
    generalize (ex_series_le (fun k : nat => (/INR(fact (2*k + 1))*(x^2)^k)) (fun k : nat => (x^2)^k /INR(fact k)));intros.
    apply H ; intros.
    unfold norm ; simpl.
    replace (n+(n+0))%nat with (2*n)%nat by lia.
    replace (x*1) with x by lra.
    replace ((x*x)^n) with (x^(2*n)) by (rewrite pow_mult ; f_equal ; lra).
    rewrite Rabs_mult.
    replace (Rabs (x^(2*n))) with (x^(2*n)).
    rewrite Rmult_comm. unfold Rdiv.
    apply Rmult_le_compat_l.
    rewrite pow_mult ; apply pow_le ;apply Ratan.pow2_ge_0.
    generalize Rprod.INR_fact_lt_0;intros.
    rewrite Rabs_right.
    apply Rinv_le_contravar ; trivial.
    apply le_INR.
    apply fact_le ; lia.
    left. apply Rlt_gt.
    apply Rinv_0_lt_compat ; trivial.
    symmetry. apply Rabs_right.
    rewrite pow_mult. apply Rle_ge.
    apply pow_le. apply Ratan.pow2_ge_0.
    exists (exp (x^2)).
    generalize (x^2) as y. intro y.
    apply is_exp_Reals.
  Qed.

  Lemma exp_even_odd (x : R) :
    exp x = (Series (fun n => (x^(2*n)/INR(fact (2*n)) + x^(2*n + 1)/INR(fact (2*n + 1))))).
  Proof.
    rewrite exp_Reals.
    rewrite PSeries_odd_even ;
      try (rewrite ex_pseries_R ; apply ex_series_exp_even) ;
      try (rewrite ex_pseries_R ; apply ex_series_exp_odd).
    unfold PSeries.
    rewrite <-Series_scal_l.
    rewrite <-Series_plus ; try (apply ex_series_exp_even).
    -- apply Series_ext ; intros. f_equal.
       rewrite pow_mult.
       now rewrite Rmult_comm.
       rewrite Rmult_comm. rewrite <-pow_mult.
       rewrite Rmult_assoc.
       replace (x^(2*n)*x) with (x^(2*n +1)) by (rewrite pow_add ; f_equal ; lra).
       now rewrite Rmult_comm.
    --  generalize (ex_series_scal x (fun n => (/ INR (fact (2 * n + 1)) * (x ^ 2) ^ n)))
        ;intros.
        apply H.
        apply ex_series_exp_odd.
  Qed.

  Lemma ex_series_even_odd (x:R) :
    ex_series (fun n : nat => x ^ (2 * n) / INR (fact (2 * n)) + x ^ (2 * n + 1) / INR (fact (2 * n + 1))).
  Proof.
    generalize ex_series_exp_odd ; intros Hodd.
    generalize ex_series_exp_even ; intros Heven.
    specialize (Hodd x).
    specialize (Heven x).
    assert (Heven' : ex_series (fun n => x^(2*n)/INR (fact (2*n)))).
    {
      eapply (ex_series_ext); intros.
      assert (/INR(fact(2*n))*(x^2)^n = x^(2*n)/INR(fact (2*n)))
        by (rewrite pow_mult; apply Rmult_comm).
      apply H.
      apply Heven.
    }
    assert (Hodd' : ex_series (fun n => x^(2*n + 1)/INR (fact (2*n + 1)))).
    {
      eapply (ex_series_ext); intros.
      assert (x*(/INR(fact(2*n + 1))*(x^2)^n) = x^(2*n + 1)/INR(fact (2*n + 1))).
      rewrite Rmult_comm. rewrite <-pow_mult.
      rewrite pow_add. rewrite pow_1. rewrite Rmult_assoc.
      now rewrite Rmult_comm at 1.
      apply H.
      generalize (ex_series_scal x (fun n => (/ INR (fact (2 * n + 1)) * (x ^ 2) ^ n)))
      ;intros.
      apply H. apply Hodd.
    }
    generalize (ex_series_plus _ _ Heven' Hodd') ; intros.
    exact H.
  Qed.


  Lemma exp_even_odd_incr_1 (x : R) :
    exp x = (1 + x) + (Series (fun n =>
                                 (x^(2*(S n)))/INR(fact (2*(S n)))
                                 + x^(2*(S n) + 1)/INR(fact (2*(S n) + 1)))).
  Proof.
    rewrite exp_even_odd.
    rewrite Series_incr_1 at 1.
    + simpl.
      f_equal.
      field.
    + apply ex_series_even_odd.
  Qed.


  Lemma exp_ineq2 : forall x : R, x <= -1 -> (1 + x < exp x).
  Proof.
    intros x Hx.
    eapply Rle_lt_trans with 0.
    - lra.
    - apply exp_pos.
  Qed.


  Lemma exp_ineq3_aux (n : nat) {x : R}:
    (-1 < x < 0) -> 0 < (x^(2*n)/INR(fact (2*n)) + x^(2*n + 1)/INR(fact (2*n + 1))).
  Proof.
    intros Hx.
    replace (x^(2*n + 1)) with (x^(2*n) * x) by (rewrite pow_add ; ring).
    unfold Rdiv.
    rewrite Rmult_assoc.
    rewrite <-Rmult_plus_distr_l.
    apply Rmult_gt_0_compat.
    -- rewrite pow_mult.
       apply Rgt_lt. apply pow_lt.
       apply Rcomplements.pow2_gt_0 ; lra.
    -- replace (/INR(fact (2*n))) with (1 / INR(fact (2*n))) by lra.
       replace (x*/INR(fact(2*n+1))) with (x/INR(fact(2*n + 1))) by trivial.
       rewrite Rcomplements.Rdiv_plus.
       2,3 : (apply (not_0_INR _ (fact_neq_0 _))).
       rewrite <-mult_INR. unfold Rdiv.
       apply Rmult_gt_0_compat.
       2: apply Rinv_pos ; rewrite mult_INR ;
         apply Rmult_gt_0_compat ; apply Rprod.INR_fact_lt_0.
       eapply Rlt_le_trans with (INR(fact(2*n)) + x*INR(fact(2*n))).
       --- replace (INR(fact(2*n)) + x*INR(fact(2*n)))
             with (1*INR(fact(2*n)) + x* INR(fact(2*n))) by (f_equal ; now rewrite Rmult_1_l).
           rewrite <-Rmult_plus_distr_r.
           apply Rmult_lt_0_compat ; try lra ; try (apply Rprod.INR_fact_lt_0).
       --- rewrite Rmult_1_l.
           apply Rplus_le_compat_r. apply le_INR.
           apply fact_le ; lia.
  Qed.

  Lemma exp_ineq3 {x : R} : -1 < x < 0 -> 1+x < exp x.
  Proof.
    intro Hx.
    rewrite exp_even_odd.
    rewrite Series_incr_1. 2 : apply ex_series_even_odd.
    replace (1+x) with (1+x+ 0) by ring.
    replace (2*0) with 0 by lra.
    replace (fact(2*0)) with 1%nat by (simpl;trivial).
    replace (fact(2*0 + 1)) with 1%nat by (simpl;trivial).
    replace (x^(2*0)) with 1 by (simpl;trivial).
    replace (x^(2*0 + 1)) with x by (simpl;trivial;ring).
    replace (INR 1) with 1 by (simpl;trivial).
    replace (1/1 + x/1) with (1+x) by field.
    apply Rplus_lt_compat_l.
    apply Series_pos.
    + generalize (ex_series_even_odd x) ;intros.
      now rewrite ex_series_incr_1 in H.
    + intro n. now apply exp_ineq3_aux.
  Qed.


  Lemma exp_ineq (x : R) : 1+x <= exp x.
  Proof.
    destruct (Rlt_or_le (-1) x).
    + destruct (Rlt_or_le x 0).
      -- left. apply exp_ineq3. lra.
      -- destruct H0.
         ++ left. now apply exp_ineq1.
         ++ right. subst ; simpl.
            rewrite exp_0 ; lra.
    + left. now apply exp_ineq2.
  Qed.

End expprops.

Section convex.

  Definition convex (f : R -> R) (a x y : R) :=
    0<=a<=1 -> f (a * x + (1-a) * y) <= a * f x + (1-a)*f y.

  Lemma compose_convex (f g : R -> R) (a x y : R) :
    (forall (x y : R), convex f a x y) ->
    convex g a x y -> 
    increasing f ->
    convex (fun z => f (g z)) a x y.
  Proof.
    unfold convex, increasing.
    intros.
    apply Rle_trans with (r2 := f (a * g x + (1 - a) * g y)).
    apply H1.
    now apply H0.
    now apply H.
  Qed.

  Lemma abs_convex : forall (a x y : R), convex Rabs a x y.
  Proof.
    unfold convex; intros.
    generalize (Rabs_triang (a*x) ((1-a)*y)); intros.
    do 2 rewrite Rabs_mult in H0.
    replace (Rabs a) with a in H0.
    replace (Rabs (1-a)) with (1-a) in H0.
    apply H0.
    now rewrite Rabs_right; lra.
    now rewrite Rabs_right; lra.
  Qed.
  
  Lemma convex_deriv (f f' : R -> R) :
    (forall c : R,  derivable_pt_lim f c (f' c)) ->
    (forall x y : R, f y >= f x + f' x * (y - x)) ->
    forall x y c : R, convex f c x y.
  Proof.
    unfold convex.
    intros.
    generalize (H0 (c * x + (1-c)*y) x); intros.
    generalize (H0 (c * x + (1-c)*y) y); intros.
    apply Rge_le in H2.
    apply Rge_le in H3.
    apply Rmult_le_compat_l with (r := c) in H2; try lra.
    apply Rmult_le_compat_l with (r := 1-c) in H3; try lra.
  Qed.

  Lemma pos_convex_deriv (f f' : R -> R) :
    (forall c : R,  0 <= c -> derivable_pt_lim f c (f' c)) ->
    (forall x y : R, 0 <= x -> 0 <= y  -> f y >= f x + f' x * (y - x)) ->
    forall x y c : R, 0 <= x -> 0 <= y -> convex f c x y.
  Proof.
    unfold convex.
    intros.
    assert (0 <= c * x + (1-c)*y).
    apply Rmult_le_compat_l with (r := c) in H1; try lra.
    apply Rmult_le_compat_l with (r := 1-c) in H2; try lra.     
    
    generalize (H0 (c * x + (1-c)*y) x H4 H1); intros.
    generalize (H0 (c * x + (1-c)*y) y H4 H2); intros.
    apply Rge_le in H5.
    apply Rge_le in H6.
    apply Rmult_le_compat_l with (r := c) in H5; try lra.
    apply Rmult_le_compat_l with (r := 1-c) in H6; try lra.
  Qed.

  Lemma ppos_convex_deriv (f f' : R -> R) :
    (forall c : R,  0 < c -> derivable_pt_lim f c (f' c)) ->
    (forall x y : R, 0 < x -> 0 < y  -> f y >= f x + f' x * (y - x)) ->
    forall x y c : R, 0 < x -> 0 < y -> convex f c x y.
  Proof.
    unfold convex.
    intros.
    assert (ineq:0 < c * x + (1-c)*y).
    {
      destruct (Req_EM_T c 0).
      - subst.
        lra.
      - apply Rplus_lt_le_0_compat.
        + apply Rmult_lt_0_compat; lra.
        + apply Rmult_le_pos; lra.
    }
    generalize (H0 (c * x + (1-c)*y) x ineq H1); intros HH1.
    generalize (H0 (c * x + (1-c)*y) y ineq H2); intros HH2.
    apply Rge_le in HH1.
    apply Rge_le in HH2.
    apply Rmult_le_compat_l with (r := c) in HH1; try lra.
    apply Rmult_le_compat_l with (r := 1-c) in HH2; try lra.
  Qed.

  Lemma deriv_incr_convex (f f' : R -> R) :
    (forall c : R,   derivable_pt_lim f c (f' c)) ->
    (forall (x y : R), x <= y -> f' x <= f' y) ->
    forall (x y : R), f y >= f x + f' x * (y-x).
  Proof.
    intros.
    generalize (MVT_cor3 f f'); intros.
    destruct (Rtotal_order x y).
    - specialize (H1 x y H2).
      cut_to H1.
      + destruct H1 as [x0 [? [? ?]]].
        assert (f' x <= f' x0) by (apply H0; lra).
        apply Rmult_le_compat_r with (r := (y-x)) in H5; lra.
      + intros; apply H; lra.
    - destruct H2; [subst; lra| ].
      specialize (H1 y x H2).
      cut_to H1.
      + destruct H1 as [x0 [? [? ?]]].
        assert (f' x0 <= f' x) by (apply H0; lra).
        apply Rmult_le_compat_r with (r := (x-y)) in H5; lra.
      + intros; apply H; lra.
  Qed.

  Lemma pos_deriv_incr_convex (f f' : R -> R) :
    (forall c : R,  0 <= c -> derivable_pt_lim f c (f' c)) ->
    (forall (x y : R), 0<=x -> 0 <= y -> x <= y -> f' x <= f' y) ->
    forall (x y : R), 0 <= x -> 0 <= y -> f y >= f x + f' x * (y-x).
  Proof.
    intros.
    generalize (MVT_cor3 f f'); intros.
    destruct (Rtotal_order x y).
    - specialize (H3 x y H4).
      cut_to H3.
      + destruct H3 as [x0 [? [? ?]]].
        assert (f' x <= f' x0) by (apply H0; lra).
        apply Rmult_le_compat_r with (r := (y-x)) in H7; lra.
      + intros; apply H; lra.
    - destruct H4; [subst; lra| ].
      specialize (H3 y x H4).
      cut_to H3.
      + destruct H3 as [x0 [? [? ?]]].
        assert (f' x0 <= f' x) by (apply H0; lra).
        apply Rmult_le_compat_r with (r := (x-y)) in H7; lra.
      + intros; apply H; lra.
  Qed.

  Lemma ppos_deriv_incr_convex (f f' : R -> R) :
    (forall c : R,  0 < c -> derivable_pt_lim f c (f' c)) ->
    (forall (x y : R), 0<x -> 0 < y -> x <= y -> f' x <= f' y) ->
    forall (x y : R), 0 < x -> 0 < y -> f y >= f x + f' x * (y-x).
  Proof.
    intros.
    generalize (MVT_cor3 f f'); intros.
    destruct (Rtotal_order x y).
    - specialize (H3 x y H4).
      cut_to H3.
      + destruct H3 as [x0 [? [? ?]]].
        assert (f' x <= f' x0) by (apply H0; lra).
        apply Rmult_le_compat_r with (r := (y-x)) in H7; lra.
      + intros; apply H; lra.
    - destruct H4; [subst; lra| ].
      specialize (H3 y x H4).
      cut_to H3.
      + destruct H3 as [x0 [? [? ?]]].
        assert (f' x0 <= f' x) by (apply H0; lra).
        apply Rmult_le_compat_r with (r := (x-y)) in H7; lra.
      + intros; apply H; lra.
  Qed.

  Lemma pow_convex (n : nat) :
    forall (a x y : R), 0<=x -> 0<=y ->  convex (fun z => pow z n) a x y.
  Proof.
    intros.
    apply pos_convex_deriv with (f' := fun z => INR n * pow z (pred n)); trivial.
    - intros; apply derivable_pt_lim_pow.
    - intros.
      apply (pos_deriv_incr_convex (fun z => pow z n) (fun z => INR n * pow z (pred n))); trivial.
      + intros; apply derivable_pt_lim_pow.
      + intros.
        apply Rmult_le_compat_l; [apply pos_INR |].
        apply pow_maj_Rabs; trivial.
        rewrite Rabs_right; lra.
  Qed.

  Lemma exp_convex (r : R):
    forall (x y : R), convex exp r x y.
  Proof.
    intros.
    eapply convex_deriv with  (f' := exp) ; trivial.
    - intros; apply derivable_pt_lim_exp.
    - intros.
      apply deriv_incr_convex; trivial.
      + intros; apply derivable_pt_lim_exp.
      + intros.
        destruct H ; trivial.
        -- left. apply exp_increasing ; trivial.
        -- subst ; trivial.
           right ; trivial.
  Qed.

End convex.

Section Rpower.

  Lemma Rpower_pos b e : 0 < Rpower b e.
  Proof.
    unfold Rpower.
    apply exp_pos.
  Qed.

  Lemma Rpower_nzero b e : ~ (Rpower b e = 0).
  Proof.
    generalize (Rpower_pos b e).
    lra.
  Qed.


  Lemma Rpower_inv_cancel x n :
    0 < x ->
    n <> 0 ->
    Rpower (Rpower x n) (Rinv n) = x.
  Proof.
    intros.
    rewrite Rpower_mult.
    rewrite <- Rinv_r_sym; trivial.
    now rewrite Rpower_1.
  Qed.

  Lemma pow0_Sbase n : pow 0 (S n) = 0.
  Proof.
    simpl; field.
  Qed.

  Lemma pow_integral n y :
    y ^ S n = 0 -> y = 0.
  Proof.
    intros.
    induction n; simpl in *.
    - lra.
    - apply Rmult_integral in H.
      destruct H; lra.
  Qed.
  
  Lemma Rabs_pow_eq_inv x y n :
    Rabs x ^ S n = Rabs y ^ S n ->
    Rabs x = Rabs y.
  Proof.
    intros.
    destruct (Req_EM_T x 0).
    - subst.
      rewrite Rabs_pos_eq in H by lra.
      rewrite pow0_Sbase in H.
      symmetry in H.
      apply pow_integral in H.
      apply Rcomplements.Rabs_eq_0 in H.
      congruence.
    - destruct (Req_EM_T y 0).
      + subst.
        symmetry in H.
        rewrite Rabs_pos_eq in H by lra.
        rewrite pow0_Sbase in H.
        symmetry in H.
        apply pow_integral in H.
        apply Rcomplements.Rabs_eq_0 in H.
        congruence.
      + assert (0 < Rabs x) by now apply Rabs_pos_lt.
        assert (0 < Rabs y) by now apply Rabs_pos_lt.
        rewrite <- (Rpower_inv_cancel (Rabs x) (INR (S n))); trivial
        ; try (apply not_0_INR; congruence).
        rewrite <- (Rpower_inv_cancel (Rabs y) (INR (S n))); trivial
        ; try (apply not_0_INR; congruence).
        f_equal.
        repeat rewrite Rpower_pow by trivial.
        trivial.
  Qed.
End Rpower.

Section power.

  (* Rpower at 0 is problematic, so we define a variant that defines it to be 0. *)
  Definition power (b e : R)
    := if Req_EM_T b 0
       then 0
       else Rpower b e.

  Lemma power_Rpower (b e : R) :
    b <> 0 ->
    power b e = Rpower b e.
  Proof.
    unfold power.
    match_destr; congruence.
  Qed.

  Lemma power_nonneg (b e : R) :
    0 <= power b e .
  Proof.
    unfold power.
    match_destr; [lra |].
    left; apply Rpower_pos.
  Qed.

  Lemma power_pos (b e : R) :
    b <> 0 ->
    0 < power b e .
  Proof.
    unfold power.
    match_destr; [lra |].
    intros; apply Rpower_pos.
  Qed.

  Lemma power_Ropp (x y : R) :
    x <> 0 ->
    power x (- y) = / power x y.
  Proof.
    intros.
    repeat rewrite power_Rpower by trivial.
    apply Rpower_Ropp.
  Qed.
  
  Lemma power_integral b e :
    power b e = 0 ->
    b = 0.
  Proof.
    unfold power.
    match_destr.
    intros; eelim Rpower_nzero; eauto.
  Qed.

  Lemma power_mult (x y z : R) :
    power (power x y) z = power x (y * z).
  Proof.
    unfold power.
    repeat match_destr.
    - eelim Rpower_nzero; eauto.
    - congruence.
    - apply Rpower_mult.
  Qed.

  Lemma power_plus (x y z : R) :
    power z (x + y) = power z x * power z y.
  Proof.
    unfold power.
    repeat match_destr.
    - lra.
    - apply Rpower_plus.
  Qed.

  Lemma power_1 (x : R) :
    0 <= x ->
    power x 1 = x.
  Proof.
    unfold power; intros.
    match_destr; [lra |].
    apply Rpower_1; lra.
  Qed.
  
  Lemma power_O (x : R) :
    0 < x ->
    power x 0 = 1.
  Proof.
    unfold power; intros.
    match_destr; [lra |].
    now apply Rpower_O.
  Qed.

  Lemma powerRZ_power (x : R) (z : Z) :
    0 < x ->
    powerRZ x z = power x (IZR z).
  Proof.
    intros.
    unfold power.
    match_destr; [lra |].
    now apply powerRZ_Rpower.
  Qed.

  Lemma Rle_power (e n m : R) :
    1 <= e ->
    n <= m ->
    power e n <= power e m.
  Proof.
    unfold power; intros.
    match_destr; [lra |].
    now apply Rle_Rpower.
  Qed.

  Lemma power_lt (x y z : R) :
    1 < x ->
    y < z ->
    power x y < power x z.
  Proof.
    unfold power; intros.
    match_destr; [lra |].
    now apply Rpower_lt.
  Qed.

  Lemma power0_Sbase e :
    power 0 e = 0.
  Proof.
    unfold power.
    match_destr.
    congruence.
  Qed.

  Lemma power_inv_cancel b e :
    0 <= b ->
    e <> 0 ->
    power (power b (/ e)) e = b.
  Proof.
    intros.
    rewrite power_mult.
    rewrite Rinv_l; trivial.
    now rewrite power_1.
  Qed.

  Lemma inv_power_cancel b e :
    0 <= b ->
    e <> 0 ->
    power (power b e) (/ e) = b.
  Proof.
    intros.
    rewrite power_mult.
    rewrite Rinv_r; trivial.
    now rewrite power_1.
  Qed.

  Lemma power_eq_inv x y n :
    0 <> n ->
    0 <= x ->
    0 <= y ->
    power x n = power y n ->
    x = y.
  Proof.
    intros.
    apply (f_equal (fun x => power x (/n))) in H2.
    now repeat rewrite inv_power_cancel in H2 by lra.
  Qed.

  Lemma power_pow (n : nat) (x : R) :
    0 < x ->
    power x (INR n) = x ^ n.
  Proof.
    unfold power; intros.
    match_destr; [lra |].
    now apply Rpower_pow.
  Qed.

  Lemma power_Spow (n : nat) (x : R) :
    0 <= x ->
    power x (INR (S n)) = x ^ (S n).
  Proof.
    unfold power; intros.
    match_destr.
    - subst.
      now rewrite pow0_Sbase.
    - apply Rpower_pow; lra.
  Qed.

  Lemma power2_sqr (x : R) :
    0 <= x ->
    power x 2 = Rsqr x.
  Proof.
    intros.
    replace 2 with (INR 2%nat) by reflexivity.
    rewrite power_Spow by trivial.
    now rewrite Rsqr_pow2.
  Qed.

  Lemma power_abs2_sqr (x : R) :
    power (Rabs x) 2 = Rsqr x.
  Proof.
    rewrite power2_sqr.
    - now rewrite <- Rsqr_abs.
    - apply Rabs_pos.
  Qed.

  Lemma power_2_sqrt (x : nonnegreal) :
    power x (/2) = Rsqrt x.
  Proof.
    intros.
    generalize (Rsqr_eq_abs_0 (power x (/ 2)) (Rsqrt x))
    ; intros HH.
    cut_to HH.
    - rewrite Rabs_right in HH.
      + rewrite Rabs_right in HH; trivial.
        apply Rle_ge.
        apply Rsqrt_positivity.
      + apply Rle_ge.
        apply power_nonneg.
    - unfold Rsqr at 2.
      rewrite Rsqrt_Rsqrt.
      rewrite <- power2_sqr.
      + rewrite power_inv_cancel; trivial.
        apply cond_nonneg.
      + apply power_nonneg.
  Qed.

  Lemma Rlt_power_l (a b c : R) :
    0 < c ->
    0 <= a < b ->
    power a c < power b c.
  Proof.
    unfold power; intros.
    repeat (match_destr; [try lra |]).
    - apply Rpower_pos.
    - apply Rlt_Rpower_l; lra.
  Qed.
  
  Lemma Rle_power_l (a b c : R) :
    0 <= c ->
    0 <= a <= b ->
    power a c <= power b c.
  Proof.
    unfold power; intros.
    repeat (match_destr; [try lra |]).
    - left; apply Rpower_pos.
    - apply Rle_Rpower_l; lra.
  Qed.

  Lemma power_sqrt (x : R) :
    0 <= x ->
    power x (/ 2) = sqrt x.
  Proof.
    unfold power; intros.
    match_destr.
    - subst.
      now rewrite sqrt_0.
    - apply Rpower_sqrt; lra.
  Qed.

  Lemma power_mult_distr (x y z : R) :
    0 <= x ->
    0 <= y ->
    power x z * power y z = power (x * y) z.
  Proof.
    unfold power; intros.
    repeat match_destr; subst; try lra.
    - apply Rmult_integral in e; intuition lra.
    - apply Rpower_mult_distr; lra.
  Qed.

  
  Lemma power_incr_inv (x y:R) (n : R) :
    0 < n ->
    0 <= x ->
    0 <= y ->
    power x n <= power y n ->
    x <= y.
  Proof.
    intros.
    generalize (Rle_power_l (power x n) (power y n) (/n))
    ; intros HH.
    repeat rewrite inv_power_cancel in HH by lra.
    apply HH.
    - now left; apply Rinv_pos.
    - split; trivial.
      apply power_nonneg.
  Qed.

  Lemma derivable_pt_lim_power' (x y : R) :
    0 < x ->
    derivable_pt_lim (fun x0 : R => power x0 y) x (y * power x (y - 1)).
  Proof.
    intros.
    unfold power.
    match_destr.
    - lra.
    - generalize (derivable_pt_lim_power x y H); intros HH.
      apply derivable_pt_lim_locally_ext with (f := fun x => Rpower x y) (a := x/2) (b := x + x/2); trivial.
      + lra.
      + intros.
        match_destr.
        lra.
  Qed.
  
  Lemma Dpower' (y z : R) :
    0 < y ->
    D_in (fun x : R => power x z) (fun x : R => z * power x (z - 1))
         (fun x : R => 0 < x) y.
  Proof.
    intros.
    generalize (derivable_pt_lim_D_in (fun x : R => power x z)
                                      (fun x : R => z * power x (z - 1)) y); intros.
    apply D_in_imp with (D := no_cond).
    intros.
    now unfold no_cond.
    apply H0.
    now apply derivable_pt_lim_power'.
  Qed.

End power.

Section ineqs.

  Lemma Rpower_ln : forall x y : R, ln (Rpower x y) = y*ln x.
  Proof.
    unfold Rpower ; intros.
    now rewrite ln_exp.
  Qed.

  Lemma Rpower_base_1 : forall x : R, Rpower 1 x = 1.
  Proof.
    intros.
    unfold Rpower.
    rewrite ln_1.
    replace (x*0) with 0 by lra.
    apply exp_0.
  Qed.

  Lemma power_base_1 e : power 1 e = 1.
  Proof.
    unfold power.
    match_destr; try lra.
    apply Rpower_base_1.
  Qed.

  Lemma sum_one_le : forall x y : R, 0 <= x -> 0 <= y -> x + y = 1 -> x <= 1.
  Proof.
    intros.
    rewrite <-H1.
    replace (x) with (x+0) by lra.
    replace (x+0+y) with (x+y) by lra.
    apply Rplus_le_compat_l ; trivial.
  Qed.

  Lemma Rmult_four_assoc (a b c d : R) : a * b * (c * d) = a * (b*c) * d.
  Proof.
    ring.
  Qed.

  (*
   This theorem also holds for a b : nonnegreal. But it is awkward since
   Rpower x y is defined in terms of exp and ln.
   *)
  Theorem Rpower_youngs_ineq {p q : posreal} {a b : R} (Hpq : 1/p + 1/q = 1) :
    0 < a -> 0 < b -> a*b <= (Rpower a p)/p + (Rpower b q)/q.
  Proof.
    intros apos bpos.
    replace (a*b) with (exp (ln (a*b)))
      by (rewrite exp_ln ; trivial ; apply Rmult_lt_0_compat ; trivial).
    rewrite ln_mult ; trivial.
    destruct p as [p ppos] ; destruct q as [q qpos] ; simpl in *.
    assert (Hp : p <> 0) by lra.
    assert (Hq : q <> 0) by lra.
    replace (ln a) with (/p*p*(ln a)) by (rewrite Rinv_l ; lra).
    replace (ln b) with (/q*q*(ln b)) by (rewrite Rinv_l ; lra).
    rewrite Rmult_assoc; rewrite Rmult_assoc.
    replace (p*ln a) with (ln(Rpower a p)) by (apply Rpower_ln).
    replace (q*ln b) with (ln(Rpower b q)) by (apply Rpower_ln).
    generalize (exp_convex (/p) (ln (Rpower a p)) (ln(Rpower b q))); intros.
    unfold convex in H. unfold Rdiv.
    replace (/q) with (1 - /p) by lra.
    eapply Rle_trans.
    - apply H.
      split.
      + left ; apply Rinv_pos ; trivial.
      + apply sum_one_le with (y := /q) ; try (left ; apply Rinv_pos ; trivial) ; try lra.
    - right.
      repeat (rewrite exp_ln; try (unfold Rpower ; apply exp_pos)).
      ring.
  Qed.

  Theorem youngs_ineq {p q : posreal} {a b : R} (Hpq : 1/p + 1/q = 1) :
    0 <= a -> 0 <= b -> a*b <= (power a p)/p + (power b q)/q.
  Proof.
    unfold power; intros apos bpos.
    repeat match_destr; subst.
    - lra.
    - destruct p; destruct q; simpl in *.
      field_simplify; [| lra].
      apply Rmult_le_pos.
      + apply Rmult_le_pos; try lra.
        generalize (Rpower_pos b pos0); lra.
      + left.
        apply Rinv_pos.
        now apply Rmult_lt_0_compat.
    - destruct p; destruct q; simpl in *.
      field_simplify; [| lra].
      apply Rmult_le_pos.
      + apply Rmult_le_pos; try lra.
        generalize (Rpower_pos a pos); lra.
      + left.
        apply Rinv_pos.
        now apply Rmult_lt_0_compat.
    - apply Rpower_youngs_ineq; lra.
  Qed.

  (*
    Young's inequality is needed in the proof of Holder's inequality.
   *)

  Theorem youngs_ineq_2 {p q : posreal} (Hpq : 1/p + 1/q = 1):
    forall (t a b : R), 0 <= a -> 0 <= b -> 0 < t ->
                   (power a (1/p))*(power b (1/q)) <= (power t (-1/q))*a/p + (power t (1/p))*b/q.
  Proof.
    intros t a b apos bpos tpos.
    assert (Hq : pos q <> 0)
      by (generalize (cond_pos q) ; intros H notq ; rewrite notq in H ; lra).
    assert (Hp : pos p <> 0)
      by (generalize (cond_pos p) ; intros H notp ; rewrite notp in H ; lra).
    assert (Hap : 0 <= ((power a (1/p))*power t (-1/(q*p))))
      by (apply Rmult_le_pos; apply power_nonneg).
    assert (Hbq : 0 <= (power t (1/(q*p))*(power b (1/q))))
      by (apply Rmult_le_pos; apply power_nonneg).
    generalize (youngs_ineq Hpq Hap Hbq) ; intros.
    rewrite Rmult_four_assoc in H.
    replace (power t (-1/(q*p)) * power t (1/(q*p))) with 1 in H.
    -- ring_simplify in H.
       eapply Rle_trans.
       apply H. clear H.
       repeat (rewrite <-power_mult_distr ; try apply power_nonneg).
       unfold Rdiv.
       repeat (rewrite power_mult).
       replace (1 */p *p) with 1 by (field ; trivial).
       replace (1 */q *q) with 1 by (field ; trivial).
    + repeat (rewrite power_1 ; trivial).
      right.
      f_equal.
      ++  rewrite Rmult_assoc.  rewrite Rmult_comm.
          replace (-1 * /(q*p) * p) with (-1 * /q).
          ring. field ; split ; trivial.
      ++  rewrite Rmult_assoc.
          replace (1 * /(q*p) * q) with (1 * /p).
          ring. field ; split ; trivial.
      -- unfold Rdiv.
         rewrite <-power_plus.
         rewrite <-power_O with (x := t) ; trivial.
         f_equal. rewrite power_O;trivial.
         ring.
  Qed.

  Theorem Rpower_youngs_ineq_2 {p q : posreal} (Hpq : 1/p + 1/q = 1):
    forall (t a b : R), 0 < a -> 0 < b -> 0 < t ->
                   (Rpower a (1/p))*(Rpower b (1/q)) <= (Rpower t (-1/q))*a/p + (Rpower t (1/p))*b/q.
  Proof.
    intros.
    generalize (youngs_ineq_2 Hpq t a b) ; intros HH.
    cut_to HH; try lra.
    now repeat rewrite power_Rpower in HH by lra.
  Qed.        

  
  Corollary ag_ineq (a b : R):
    0 <= a -> 0 <= b ->  sqrt (a*b) <= (a+b)/2.
  Proof.
    intros Ha Hb.
    destruct Ha as [Hapos | Haz].
    destruct Hb as [Hbpos | Hbz].
    ++ rewrite <-Rpower_sqrt ; try (apply Rmult_lt_0_compat ; trivial).
       rewrite <-Rpower_mult_distr ; trivial.
       rewrite Rdiv_plus_distr.
       assert (Hpq : 1/pos(mkposreal 2 Rlt_0_2) + 1/pos(mkposreal 2 Rlt_0_2) = 1)
         by (simpl;field).
       generalize (Rpower_youngs_ineq_2 Hpq 1 a b Hapos Hbpos Rlt_0_1) ; simpl ; intros.
       replace (/2) with (1/2) by lra.
       eapply Rle_trans. apply H.
       repeat rewrite Rpower_base_1.
       right ; field.
    ++ subst. left.
       rewrite Rmult_0_r.
       rewrite sqrt_0 ; lra.
    ++ subst.
       rewrite Rmult_0_l.
       rewrite sqrt_0; lra.
  Qed.

  Lemma pow_minkowski_helper_aux (p:nat) (a t : R) : 0 < t ->
                                                   t*(pow(a/t) (S p)) = (pow a (S p))*(pow (/t) p).
  Proof.
    intros.
    unfold Rdiv.
    rewrite Rpow_mult_distr.
    rewrite Rmult_comm, Rmult_assoc.
    f_equal.
    simpl.
    rewrite Rmult_comm.
    rewrite <- Rmult_assoc.
    rewrite Rinv_r.
    now rewrite Rmult_1_l.
    now apply Rgt_not_eq.
  Qed.

  Lemma pow_minkowski_helper (p : nat) {a b t : R}:
    (0 <= a) -> (0 <= b) -> 0<t<1 ->
    (pow (a+b) (S p)) <= (pow (/t) p)*(pow a (S p)) + (pow (/(1-t)) p)*(pow b (S p)).
  Proof.
    intros Ha Hb Ht.
    assert (Ht1 : t <> 0) by (intro not; destruct Ht as [h1 h2] ; subst ; lra).
    assert (Ht2 : 1-t <> 0) by (intro not; destruct Ht as [h1 h2] ; subst ; lra).
    assert (Hat : 0 <= a/t) by (apply Rcomplements.Rdiv_le_0_compat ; lra).
    assert (Hbt : 0 <= b/(1-t)) by  (apply Rcomplements.Rdiv_le_0_compat ; lra).
    assert (Ht' : 0 <= t <= 1) by lra.
    replace (a+b) with (t*(a/t) + (1-t)*(b/(1-t))) by (field ; split ; trivial).
    generalize (pow_convex (S p) t (a/t) (b/(1-t)) Hat Hbt Ht'); intros.
    eapply Rle_trans. apply H.
    repeat (rewrite pow_minkowski_helper_aux ; try lra).
  Qed.

  Lemma pow_minkowski_subst (p : nat) {a b : R} :
    (0 < a) -> (0 < b) -> 
    (pow (/(a / (a + b))) p)*(pow a (S p)) +
    (pow (/(1-(a / (a + b)))) p)*(pow b (S p)) = (pow (a + b) (S p)).
  Proof.
    intros; simpl.
    assert (a <> 0) by now apply Rgt_not_eq.
    assert (a + b <> 0) by (apply Rgt_not_eq; now apply Rplus_lt_0_compat).
    replace (/ (a / (a + b))) with ((a+b)* (/a)).
    - rewrite Rpow_mult_distr, Rmult_assoc.
      replace ((/ a) ^ p * (a * a ^ p)) with (a).
      + replace (/ (1 - a / (a + b))) with ((a+b)/b).
        * unfold Rdiv; rewrite Rpow_mult_distr, Rmult_assoc.
          replace ((/ b) ^ p * (b * b ^ p)) with (b).
          ring.
          rewrite <- Rmult_assoc, Rmult_comm.
          rewrite <- Rmult_assoc, <- Rpow_mult_distr.      
          rewrite Rinv_r, pow1; lra.
        * field; split; trivial.
          replace (a + b - a) with b by lra.
          now apply Rgt_not_eq.
      + rewrite <- Rmult_assoc, Rmult_comm.
        rewrite <- Rmult_assoc, <- Rpow_mult_distr.
        rewrite Rinv_r, pow1; lra.
    - field; now split.
  Qed.

  Lemma minkowski_range (a b : R) :
    (0 < a) -> (0 < b) -> 
    0 < a / (a + b) < 1.
    split.
    - apply Rdiv_lt_0_compat; trivial.
      now apply Rplus_lt_0_compat.
    - apply Rmult_lt_reg_r with (r := a+b).
      now apply Rplus_lt_0_compat.
      unfold Rdiv.
      rewrite Rmult_assoc, Rinv_l.
      + rewrite Rmult_1_r, Rmult_1_l.
        replace (a) with (a + 0) at 1 by lra.
        now apply Rplus_lt_compat_l.
      + apply Rgt_not_eq.
        now apply Rplus_lt_0_compat.
  Qed.

End ineqs.

Lemma Rpower_neg1 b e : b < 0 -> Rpower b e = 1.
Proof.
  intros.
  unfold Rpower.
  unfold ln.
  match_destr; try lra.
  - elimtype False; try tauto; lra.
  - rewrite Rmult_0_r.
    now rewrite exp_0.
Qed.

Lemma derivable_pt_lim_abs_power2' (x y : R) :
  0 <= x ->
  1 < y ->
  derivable_pt_lim (fun x0 : R => power (Rabs x0) y) x (y * power x (y - 1)).
Proof.
  intros.
  unfold power.
  match_destr.
  - red; intros.
    match_destr; try lra.
    clear e0.
    subst.
    assert (dpos:0 <  (power eps (Rinv (y-1)))).
    {
      apply power_pos; lra.
    } 
    exists (mkposreal _ dpos); intros.
    rewrite Rplus_0_l.
    match_destr.
    -- apply Rcomplements.Rabs_eq_0 in e; lra.
    -- simpl in *.
       rewrite Rmult_0_r.
       repeat rewrite Rminus_0_r.
       generalize (Rlt_power_l (Rabs h) (power eps (Rinv (y - 1))) (y-1))
       ; intros HH.
       cut_to HH.
    + rewrite power_mult in HH.
      rewrite Rinv_l in HH by lra.
      rewrite power_1 in HH by lra.
      unfold power in HH.
      match_destr_in HH; try lra.
      unfold Rminus in HH.
      rewrite Rpower_plus in HH.
      rewrite Rpower_Ropp in HH.
      rewrite Rpower_1 in HH
        by now apply Rabs_pos_lt.
      unfold Rdiv.
      rewrite Rabs_mult.
      rewrite Rabs_Rinv by trivial.
      rewrite (Rabs_pos_eq (Rpower (Rabs h) y)); trivial.
      left.
      apply Rpower_pos.
    + lra.
    + split; trivial.
      apply Rabs_pos.
      -- subst.
         rewrite Rabs_R0 in n; lra.
  -
    generalize (derivable_pt_lim_comp
                  Rabs
                  (fun x0 : R => if Req_EM_T x0 0 then 0 else Rpower x0 y)
                  x
                  1
                  (y * Rpower x (y - 1)))
    ; intros HH2.
    rewrite Rmult_1_r in HH2.
    apply HH2.
    + apply Rabs_derive_1; lra.
    + rewrite Rabs_pos_eq by lra.
      generalize (derivable_pt_lim_power' x y); intros HH.
      cut_to HH; [| lra].
      unfold power in HH.
      match_destr_in HH; try lra.
Qed.

Lemma Rpower_convex_pos (e:R) :
  1 <= e ->
  forall (x y a : R), 0<x -> 0<y -> convex (fun z => Rpower z e) a x y.
Proof.
  intros.
  eapply ppos_convex_deriv; trivial.
  - intros.
    now apply derivable_pt_lim_power.
  - intros.
    apply (ppos_deriv_incr_convex (fun z => Rpower z e)); trivial.
    + intros; now apply derivable_pt_lim_power.
    + intros.
      apply Rmult_le_compat_l; [lra |].
      apply Rle_Rpower_l; lra.
Qed.

Lemma Rpower_base_0 e : Rpower 0 e = 1.
Proof.
  unfold Rpower, ln.
  match_destr.
  - elimtype False; try tauto; lra.
  - rewrite Rmult_0_r.
    now rewrite exp_0.
Qed.

Lemma power_convex_pos (e:R) :
  1 <= e ->
  forall (x y a : R), 0<x -> 0<y -> convex (fun z => power z e) a x y.
Proof.
  intros.
  eapply ppos_convex_deriv; trivial.
  - intros.
    now apply derivable_pt_lim_power'.
  - intros.
    apply (ppos_deriv_incr_convex (fun z => power z e)); trivial.
    + intros; now apply derivable_pt_lim_power'.
    + intros.
      apply Rmult_le_compat_l; [lra |].
      apply Rle_power_l; lra.
Qed.

Section power_minkowski.

  Lemma power_minkowski_helper_aux (p:R) (a t : R) :
    0 <= a ->
    0 < t ->
    1 <= p ->
    t*(power (a/t) p) = (power a p)*(power (/t) (p-1)).
  Proof.
    intros.
    unfold Rdiv.
    rewrite <- power_mult_distr; trivial.
    - rewrite Rmult_comm, Rmult_assoc.
      f_equal.
      unfold Rminus.
      rewrite power_plus.
      f_equal.
      rewrite power_Ropp.
      + rewrite power_1.
        * rewrite Rinv_involutive; lra.
        * left.
          now apply Rinv_pos.
      + apply Rinv_neq_0_compat; lra.
    - left.
      now apply Rinv_pos.
  Qed.

  Lemma power_minkowski_helper_lt (p : R) {a b t : R}:
    (0 < a) ->
    (0 < b) ->
    0<t<1 ->
    1 <= p ->
    (power (a+b) p) <= (power (/t) (p-1))*(power a p) + (power (/(1-t)) (p-1))*(power b p).
  Proof.
    intros Ha Hb Ht pbig.
    assert (Ht1 : t <> 0) by (intro not; destruct Ht as [h1 h2] ; subst ; lra).
    assert (Ht2 : 1-t <> 0) by (intro not; destruct Ht as [h1 h2] ; subst ; lra).
    assert (Hat : 0 < a/t) by (apply Rcomplements.Rdiv_lt_0_compat ; lra).
    assert (Hbt : 0 < b/(1-t)) by  (apply Rcomplements.Rdiv_lt_0_compat ; lra).
    assert (Ht' : 0 <= t <= 1) by lra.
    replace (a+b) with (t*(a/t) + (1-t)*(b/(1-t))) by (field ; split ; trivial).
    
    generalize (power_convex_pos p pbig (a/t) (b/(1-t)) t Hat Hbt Ht'); intros.
    eapply Rle_trans. apply H.
    repeat (rewrite power_minkowski_helper_aux ; try lra).
  Qed.

  Lemma Rmult_bigpos_le_l a b :
    0 <= a ->
    1 <= b ->
    a <= b * a.
  Proof.
    intros.
    rewrite <- (Rmult_1_l a) at 1.
    now apply Rmult_le_compat_r.
  Qed.

  Lemma power_big_big a e :
    0 <= e ->
    1 <= a ->
    1 <= power a e.
  Proof.
    intros nne pbig.
    generalize (Rle_power a 0 e pbig nne).
    rewrite power_O; lra.
  Qed.
    
  Lemma power_minkowski_helper (p : R) {a b t : R}:
    (0 <= a) ->
    (0 <= b) ->
    0<t<1 ->
    1 <= p ->
    (power (a+b) p) <= (power (/t) (p-1))*(power a p) + (power (/(1-t)) (p-1))*(power b p).
  Proof.
    intros Ha Hb Ht pbig.
    destruct (Req_EM_T a 0).
    - subst.
      rewrite power0_Sbase by lra.
      rewrite Rmult_0_r.
      repeat rewrite Rplus_0_l.
      apply Rmult_bigpos_le_l.
      + apply power_nonneg.
      + assert (1 <= / (1 - t)).
        * rewrite <- Rinv_1 at 1.
          apply Rinv_le_contravar; lra.
        * apply power_big_big; lra.
    - destruct (Req_EM_T b 0).
      + subst.
        rewrite power0_Sbase by lra.
        rewrite Rmult_0_r.
        repeat rewrite Rplus_0_r.
        apply Rmult_bigpos_le_l.
      * apply power_nonneg.
      * assert (1 <= / t).
        -- rewrite <- Rinv_1 at 1.
          apply Rinv_le_contravar; lra.
        -- apply power_big_big; lra.
      + apply power_minkowski_helper_lt; trivial; lra.
  Qed.

  Lemma power_minus1 b e :
    0 <= b ->
    power b e = b * power b (e-1).
  Proof.
    intros.
    replace e with ((e-1)+1) at 1 by lra.
    rewrite power_plus.
    rewrite power_1; trivial.
    lra.
  Qed.

  Lemma power_minkowski_subst (p : R) {a b : R} :
    (0 < a) ->
    (0 < b) ->
    1 <= p ->
    (power (/(a / (a + b))) (p-1))*(power a p) +
    (power (/(1-(a / (a + b)))) (p-1))*(power b p) = (power (a + b) p).
  Proof.
    intros; simpl.
    assert (a <> 0) by auto with real. 
    assert (a + b <> 0) by lra. 
    replace (/ (a / (a + b))) with ((a+b)* (/a))
      by (field; now split).
    rewrite <- power_mult_distr, Rmult_assoc by (try lra; auto with real).
    replace (power (/ a) (p-1) * (power a p)) with (a).
    - replace (/ (1 - a / (a + b))) with ((a+b)/b).
      + unfold Rdiv; rewrite <- power_mult_distr, Rmult_assoc by (try lra; auto with real).
       replace (power (/ b) (p-1) * ( power b p)) with (b).
       * rewrite <- Rmult_plus_distr_l.
         rewrite Rmult_comm.
         rewrite <- power_minus1; trivial.
         lra.
       * rewrite (power_minus1 b) by lra.
         rewrite <-  Rmult_assoc, Rmult_comm, <- Rmult_assoc.
         rewrite power_mult_distr by (try lra; auto with real).
         rewrite Rinv_r by lra.
         rewrite power_base_1.
         lra.
      + rewrite <- (Rinv_r (a+b)) by lra.
        fold (Rdiv (a+b) (a+b)).
        rewrite <- Rdiv_minus_distr.
        field_simplify; try lra; auto with real.
    - rewrite (power_minus1 a p) by auto with real.
      rewrite <- Rmult_assoc, Rmult_comm, <- Rmult_assoc.
      rewrite power_mult_distr by auto with real.
      rewrite Rinv_r, power_base_1 by lra.
      lra.
  Qed.

End power_minkowski.
