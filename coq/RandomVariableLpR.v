Require Import Morphisms.
Require Import Equivalence.
Require Import Program.Basics.
Require Import Lra Lia.
Require Import Classical.
Require Import FunctionalExtensionality.

Require Import hilbert.

Require Export RandomVariableFinite.
Require Import quotient_space.

Require Import AlmostEqual.
Require Import utils.Utils.
Require Import List.

Set Bullet Behavior "Strict Subproofs".

Section Lp.
  Context {Ts:Type} 
          {dom: SigmaAlgebra Ts}
          (prts: ProbSpace dom).

  (* generalize this to real p using rvpower? *)
  Definition IsLp (n:R) (rv_X:Ts->R)
    := IsFiniteExpectation prts (rvpower (rvabs rv_X) (const n)).

  Existing Class IsLp.
  Typeclasses Transparent IsLp.

  Global Instance Lp_FiniteLp n rv_X
         {islp:IsLp n rv_X}
    : IsFiniteExpectation prts (rvpower (rvabs rv_X) (const n))
    := islp.

  Global Instance IsLp_proper
    : Proper (eq ==> rv_eq ==> iff) IsLp.
  Proof.
    intros ?? eqq1 x y eqq2.
    unfold IsLp.
    now rewrite eqq1, eqq2.
  Qed.

  (* Note that IsLp 0 always holds, so it says that we are not making any assumptions *)
  Global Instance IsL0_True (rv_X:Ts->R) : IsLp 0 rv_X.
  Proof.
    red.
    assert(eqq:rv_eq (rvpower (rvabs rv_X) (const 0))
                     (rvchoice (fun x => if Req_EM_T (rv_X x) 0 then true else false)
                               (const 0)
                               (const 1))).
    {
      intros a.
      rv_unfold.
      unfold power.
      destruct (Req_EM_T (rv_X a)).
      - rewrite Rabs_pos_eq by lra.
        match_destr; congruence.
      - match_destr.
        + apply Rabs_eq_0 in e; congruence.
        + rewrite Rpower_O; trivial.
          generalize (Rabs_pos (rv_X a)); lra.
    } 
    rewrite eqq.
    typeclasses eauto.
  Qed.

  Lemma IsL1_Finite (rv_X:Ts->R)
        {rrv:RandomVariable dom borel_sa rv_X}
        {lp:IsLp 1 rv_X} : IsFiniteExpectation prts rv_X.
  Proof.
    red.
    red in lp.
    apply Expectation_abs_then_finite; trivial.
    now rewrite rvabs_pow1 in lp.
  Qed.

  Lemma IsL1_abs_Finite (rv_X:Ts->R)
        {lp:IsLp 1 rv_X} : IsFiniteExpectation prts (rvabs rv_X).
  Proof.
    red.
    red in lp.
    now rewrite rvabs_pow1 in lp.
  Qed.

  Lemma Finite_abs_IsL1 (rv_X:Ts->R)
        {isfe:IsFiniteExpectation prts (rvabs rv_X)} :
    IsLp 1 rv_X.
  Proof.
    red.
    now rewrite rvabs_pow1.
  Qed.

  Lemma IsLp_bounded n rv_X1 rv_X2
        (rle:rv_le (rvpower (rvabs rv_X1) (const n)) rv_X2)
        {islp:IsFiniteExpectation prts rv_X2}
    :
      IsLp n rv_X1.
  Proof.
    unfold IsLp in *.
    intros.
    eapply (IsFiniteExpectation_bounded prts (const 0) _ rv_X2); trivial.
    intros a.
    unfold const, rvabs, rvpower.
    apply power_nonneg.
  Qed.      

    Lemma IsLp_down_le m n (rv_X:Ts->R)
        {rrv:RandomVariable dom borel_sa rv_X}
        (pfle:0 <= n <= m)
        {lp:IsLp m rv_X} : IsLp n rv_X.
    Proof.
      red in lp; red.
      apply (@IsLp_bounded _ _
                           (rvmax
                              (const 1)
                              (rvpower (rvabs rv_X) (const m))))
      ; [| typeclasses eauto].
      intros a.
      rv_unfold.
      destruct (Rle_lt_dec 1 (Rabs (rv_X a))).
      - eapply Rle_trans; [| eapply Rmax_r].
        now apply Rle_power.
      - eapply Rle_trans; [| eapply Rmax_l].
        unfold power.
        match_destr; [lra | ].
        generalize (Rabs_pos (rv_X a)); intros.
        destruct (Req_EM_T n 0).
        + subst.
          rewrite Rpower_O; lra.
        + assert (eqq:1 = Rpower 1 n).
          {
            unfold Rpower.
            rewrite ln_1.
            rewrite Rmult_0_r.
            now rewrite exp_0.
          }
          rewrite eqq.
          apply Rle_Rpower_l; lra.
  Qed.

  Lemma IsLp_Finite n (rv_X:Ts->R)
        {rrv:RandomVariable dom borel_sa rv_X}
        (nbig:1<=n)
        {lp:IsLp n rv_X} : IsFiniteExpectation prts rv_X.
  Proof.
    apply IsL1_Finite; trivial.
    eapply IsLp_down_le; try eapply lp; trivial; lra.
  Qed.

  Lemma IsLSp_abs_Finite n (rv_X:Ts->R)
        {rrv:RandomVariable dom borel_sa rv_X}
        (nbig:1<=n)
        {lp:IsLp n rv_X} : IsFiniteExpectation prts (rvabs rv_X).
  Proof.
    apply IsL1_abs_Finite; trivial.
    apply (IsLp_down_le n 1); trivial.
    lra.
  Qed.

  Lemma Expectation_abs_neg_part_finite (rv_X : Ts -> R)
        {rv:RandomVariable dom borel_sa rv_X} :
    is_finite (Expectation_posRV (rvabs rv_X)) ->
    is_finite (Expectation_posRV (neg_fun_part rv_X)).
  Proof.
    apply Finite_Expectation_posRV_le.
    apply neg_fun_part_le.
  Qed.
  
  Lemma Expectation_neg_part_finite (rv_X : Ts -> R)
        {rv:RandomVariable dom borel_sa rv_X}
        {isfe:IsFiniteExpectation prts rv_X} :
    is_finite (Expectation_posRV (neg_fun_part rv_X)).
  Proof.
    red in isfe.
    unfold Expectation in isfe.
    destruct (Expectation_posRV (fun x : Ts => pos_fun_part rv_X x)).
    destruct (Expectation_posRV (fun x : Ts => neg_fun_part rv_X x)).     
    now unfold is_finite.
    simpl in isfe; tauto.
    simpl in isfe; tauto.     
    destruct (Expectation_posRV (fun x : Ts => neg_fun_part rv_X x));
      simpl in isfe; tauto.
    destruct (Expectation_posRV (fun x : Ts => neg_fun_part rv_X x));
      simpl in isfe; tauto.
  Qed.
  
  Lemma Rbar_pos_finite (r : Rbar):
    0 < r -> is_finite r.
  Proof.
    intros.
    destruct r.
    now unfold is_finite.
    simpl in H; lra.
    simpl in H; lra.
  Qed.

  Lemma power_ineq_convex p :
    1 <= p ->
    forall (x y : R), 0 < x -> 0 < y -> 
                 power (x + y) p <= (power 2 (p-1))*(power x p + power y p).
  Proof.
    intros.
    assert (0 <= (/2) <= 1) by lra.
    generalize (power_convex_pos p (/2) H x y _ H0 H1 H2); intros.
    replace (1 - /2) with (/2) in H3 by lra.
    repeat rewrite <- Rmult_plus_distr_l in H3.
    rewrite <- power_mult_distr in H3 by lra.
    apply Rmult_le_compat_l with (r := power 2 p) in H3
    ; [| apply power_nonneg].
    repeat rewrite <- Rmult_assoc in H3.
    replace (power 2 p * power (/2) p) with (1) in H3.
    + replace (power 2 p * (/2)) with (power 2 (p - 1)) in H3.
      * now repeat rewrite Rmult_1_l in H3.
      * replace (/2) with (power 2 ((Ropp 1))).
        -- now rewrite <- power_plus.
        -- rewrite power_Ropp by lra.
           rewrite power_1; lra.
    + rewrite power_mult_distr by lra.
      replace (2 * /2) with (1) by lra.
      now rewrite power_base_1.
  Qed.
  
  Lemma power_abs_ineq (p : R) (x y : R) :
    1 <= p ->
    power (Rabs (x + y)) p <= (power 2 p)*(power (Rabs x) p + power (Rabs y) p).
  Proof.
    intros.
    destruct (Req_EM_T x 0).
    - subst.
      rewrite Rabs_R0.
      rewrite power0_Sbase by lra.
      repeat rewrite Rplus_0_l.
      assert (0 <= power (Rabs y) p)
        by apply power_nonneg.
      assert (0 <= power 2 (p-1))
        by apply power_nonneg.
      rewrite <- (Rmult_1_l (power (Rabs y) p)) at 1.
      apply Rmult_le_compat_r; trivial.
      rewrite <- (power_base_1 p).
      apply Rle_power_l; lra.
    - destruct (Req_EM_T y 0).
      + subst.
        rewrite Rabs_R0.
        rewrite power0_Sbase by lra.
        repeat rewrite Rplus_0_r.
        assert (0 <= power (Rabs x) p)
          by apply power_nonneg.
        assert (0 <= power 2 (p-1))
          by apply power_nonneg.
        rewrite <- (Rmult_1_l (power (Rabs x) p)) at 1.
        apply Rmult_le_compat_r; trivial.
        rewrite <- (power_base_1 p).
        apply Rle_power_l; lra.
      + apply Rle_trans with (r2 := power (Rabs x + Rabs y) p).
        * apply Rle_power_l; try lra.
          split.
          -- apply Rabs_pos.
          -- apply Rabs_triang.
        * eapply Rle_trans
          ; try eapply power_ineq_convex; trivial.
          -- now apply Rabs_pos_lt.
          -- now apply Rabs_pos_lt.
          -- eapply Rmult_le_compat_r.
             ++ apply Rplus_le_le_0_compat; left; apply power_pos
                ; now apply Rabs_no_R0.
             ++ apply Rle_power; lra.
  Qed.

  Instance IsLp_plus p
         (rv_X1 rv_X2 : Ts -> R)
         {rv1 : RandomVariable dom borel_sa rv_X1}
         {rv2 : RandomVariable dom borel_sa rv_X2} 
         {islp1:IsLp p rv_X1}
         {islp2:IsLp p rv_X2} :
    1 <= p ->
    IsLp p (rvplus rv_X1 rv_X2).
  Proof.
    intros bigp.
    apply (IsLp_bounded _ _ (rvscale ((power 2 p)) (rvplus (rvpower (rvabs rv_X1) (const p)) (rvpower (rvabs rv_X2) (const p)))))
    ; [| typeclasses eauto].
    intros x.
    rv_unfold.
    now apply power_abs_ineq.
  Qed.

  Lemma rvpower_abs_scale c (X:Ts->R) n :
      rv_eq (rvpower (rvscale (Rabs c) (rvabs X)) (const n)) (rvscale (power (Rabs c) n) (rvpower (rvabs X) (const n))).
  Proof.
    intros x.
    unfold rvpower, rvscale.
    rewrite power_mult_distr; trivial.
    - apply Rabs_pos.
    - apply rvabs_pos.
  Qed.

  Global Instance IsLp_scale p (c:R) (rv_X:Ts->R)
         {islp:IsLp p rv_X} :
    IsLp p (rvscale c rv_X).
  Proof.
    unfold IsLp in *.
    rewrite rv_abs_scale_eq.
    rewrite rvpower_abs_scale.
    typeclasses eauto.
  Qed.

  Lemma IsLp_scale_inv p c rv_X 
        {islp:IsLp p (rvscale c rv_X)} :
    c <> 0 ->
    IsLp p rv_X.
  Proof.
    intros.
    unfold IsLp in *.
    rewrite rv_abs_scale_eq in islp.
    rewrite rvpower_abs_scale in islp.
    eapply IsFiniteExpectation_scale_inv; try eassumption.
    generalize (power_pos (Rabs c) p); intros HH.
    cut_to HH.
    - lra.
    - now apply Rabs_no_R0.
  Qed.
  
  Global Instance IsLp_opp p (rv_X:Ts->R)
         {islp:IsLp p rv_X} :
    IsLp p (rvopp rv_X).
  Proof.
    now apply IsLp_scale.
  Qed.
                                       
  Global Instance IsLp_const p c : IsLp p (const c).
  Proof.
    red.
    rewrite rv_abs_const_eq, rvpower_const.
    typeclasses eauto.
  Qed.

  Global Instance IsLp_minus p
         (rv_X1 rv_X2 : Ts -> R)
         {rv1 : RandomVariable dom borel_sa rv_X1}
         {rv2 : RandomVariable dom borel_sa rv_X2} 
         {islp1:IsLp p rv_X1}
         {islp2:IsLp p rv_X2} :
    1 <= p ->
    IsLp p (rvminus rv_X1 rv_X2).
  Proof.
    unfold rvminus.
    apply IsLp_plus; 
      typeclasses eauto.
  Qed.

  Lemma rv_abs_abs (rv_X:Ts->R) :
    rv_eq (rvabs (rvabs rv_X)) (rvabs rv_X).
  Proof.
    intros a.
    unfold rvabs.
    now rewrite Rabs_Rabsolu.
  Qed.
  
  Global Instance IsLp_abs p
         (rv_X : Ts -> R)
         {islp:IsLp p rv_X} :
    IsLp p (rvabs rv_X).
  Proof.
    unfold IsLp.
    rewrite rv_abs_abs.
    apply islp.
  Qed.

  Lemma rvpowabs_choice_le c (rv_X1 rv_X2 : Ts -> R) p :
    rv_le (rvpower (rvabs (rvchoice c rv_X1 rv_X2)) (const p))
          (rvplus (rvpower (rvabs rv_X1) (const p)) (rvpower (rvabs rv_X2) (const p))).
  Proof.
    intros a.
    rv_unfold; simpl.
    match_destr.
    - assert (0 <= power (Rabs (rv_X2 a)) p) by apply power_nonneg.
      lra.
    - assert (0 <= power (Rabs (rv_X1 a)) p) by apply power_nonneg.
      lra.
  Qed.

  Global Instance IsLp_choice p
         c
         (rv_X1 rv_X2 : Ts -> R)
         {rv1 : RandomVariable dom borel_sa rv_X1}
         {rv2 : RandomVariable dom borel_sa rv_X2}
         {islp1:IsLp p rv_X1}
         {islp2:IsLp p rv_X2} :
    IsLp p (rvchoice c rv_X1 rv_X2).
  Proof.
    unfold IsLp in *.
    eapply (IsLp_bounded _)
    ; try eapply rvpowabs_choice_le.
    apply IsFiniteExpectation_plus; eauto
    ; typeclasses eauto. 
  Qed.
  
  Global Instance IsLp_max p
         (rv_X1 rv_X2 : Ts -> R)
         {rv1 : RandomVariable dom borel_sa rv_X1}
         {rv2 : RandomVariable dom borel_sa rv_X2}
         {islp1:IsLp p rv_X1}
         {islp2:IsLp p rv_X2} :
    IsLp p (rvmax rv_X1 rv_X2).
  Proof.
    rewrite rvmax_choice.
    typeclasses eauto.
  Qed.

  Global Instance IsLp_min p
         (rv_X1 rv_X2 : Ts -> R)
         {rv1 : RandomVariable dom borel_sa rv_X1}
         {rv2 : RandomVariable dom borel_sa rv_X2}
         {islp1:IsLp p rv_X1}
         {islp2:IsLp p rv_X2} :
    IsLp p (rvmin rv_X1 rv_X2).
  Proof.
    rewrite rvmin_choice.
    typeclasses eauto.
  Qed.

  Section packed.

    Context {p:R}.
    
    Record LpRRV : Type
      := LpRRV_of {
             LpRRV_rv_X :> Ts -> R
             ; LpRRV_rv :> RandomVariable dom borel_sa LpRRV_rv_X
             ; LpRRV_lp :> IsLp p LpRRV_rv_X
           }.

    Global Existing Instance LpRRV_rv.
    Global Existing Instance LpRRV_lp.

    Global Instance LpRRV_LpS_FiniteLp (rv_X:LpRRV)
      : IsFiniteExpectation prts (rvpower (rvabs rv_X) (const p))
      := LpRRV_lp _.


    Definition pack_LpRRV (rv_X:Ts -> R) {rv:RandomVariable dom borel_sa rv_X} {lp:IsLp p rv_X}
      := LpRRV_of rv_X rv lp.
    
    Definition LpRRV_eq (rv1 rv2:LpRRV)
      := rv_almost_eq prts rv1 rv2.

    Local Hint Resolve Hsigma_borel_eq_pf : prob.

    Global Instance LpRRV_eq_equiv : Equivalence LpRRV_eq.
    Proof.
      unfold LpRRV_eq.
      constructor.
      - intros [x?].
        now apply rv_almost_eq_rv_refl.
      - intros [x?] [y?] ps1; simpl in *.
        now apply rv_almost_eq_rv_sym.
      - intros [x??] [y??] [z??] ps1 ps2.
        simpl in *.
        now apply rv_almost_eq_rv_trans with (y0:=y).
    Qed.

    Definition LpRRVconst (x:R) : LpRRV
      := pack_LpRRV (const x).

    Definition LpRRVzero : LpRRV := LpRRVconst 0.

    Program Definition LpRRVscale (x:R) (rv:LpRRV) : LpRRV
      := pack_LpRRV (rvscale x rv).

    Global Instance LpRRV_scale_proper : Proper (eq ==> LpRRV_eq ==> LpRRV_eq) LpRRVscale.
    Proof.
      unfold Proper, respectful, LpRRV_eq.
      intros ? x ? [x1??] [x2??] eqqx.
      subst.
      simpl in *.
      unfold rvscale.
      red.
      destruct (Req_EM_T x 0).
      - subst.
        erewrite ps_proper; try eapply ps_one.
        red.
        unfold Ω.
        split; trivial.
        lra.
      - erewrite ps_proper; try eapply eqqx.
        red; intros.
        split; intros.
        + eapply Rmult_eq_reg_l; eauto.
        + congruence.
    Qed.

    Program Definition LpRRVopp (rv:LpRRV) : LpRRV
      := pack_LpRRV (rvopp rv).
    
    Global Instance LpRRV_opp_proper : Proper (LpRRV_eq ==> LpRRV_eq) LpRRVopp.
    Proof.
      unfold Proper, respectful.
      intros x y eqq.
      generalize (LpRRV_scale_proper (-1) _ (eq_refl _) _ _ eqq)
      ; intros HH.
      destruct x as [x?]
      ; destruct y as [y?].
      apply HH.
    Qed.
    
    Lemma LpRRVopp_scale (rv:LpRRV) :
      LpRRV_eq 
        (LpRRVopp rv) (LpRRVscale (-1) rv).
    Proof.
      red.
      apply rv_almost_eq_eq.
      reflexivity.
    Qed.

    Context (pbig:1 <= p).

    Definition LpRRVplus (rv1 rv2:LpRRV) : LpRRV
      := pack_LpRRV (rvplus rv1  rv2) (lp:=IsLp_plus _ _ _ pbig).

    Global Instance LpRRV_plus_proper : Proper (LpRRV_eq ==> LpRRV_eq ==> LpRRV_eq) LpRRVplus.
    Proof.
      unfold Proper, respectful, LpRRV_eq.
      intros [x1??] [x2??] eqqx [y1??] [y2??] eqqy.
      simpl in *.
      now apply rv_almost_eq_plus_proper.
    Qed.
    
    Definition LpRRVminus (rv1 rv2:LpRRV) : LpRRV
      := pack_LpRRV (rvminus rv1 rv2)  (lp:=IsLp_minus _ _ _ pbig).

    Lemma LpRRVminus_plus (rv1 rv2:LpRRV) :
      LpRRV_eq 
        (LpRRVminus rv1 rv2) (LpRRVplus rv1 (LpRRVopp rv2)).
    Proof.
      apply rv_almost_eq_eq.
      reflexivity.
    Qed.
    
    Global Instance LpRRV_minus_proper : Proper (LpRRV_eq ==> LpRRV_eq ==> LpRRV_eq) LpRRVminus.
    Proof.
      unfold Proper, respectful, LpRRV_eq.

      intros x1 x2 eqq1 y1 y2 eqq2.
      
      generalize (LpRRV_plus_proper _ _ eqq1 _ _ (LpRRV_opp_proper _ _ eqq2)) 
      ; intros HH.
      destruct x1 as [???]; destruct x2 as [???]
      ; destruct y1 as [???]; destruct y2 as [???].
      apply HH.
    Qed.

    Ltac LpRRV_simpl
      := repeat match goal with
                | [H : LpRRV |- _ ] => destruct H as [???]
                end
         ; unfold LpRRVplus, LpRRVminus, LpRRVopp, LpRRVscale
         ; simpl.

    
    Lemma LpRRV_plus_comm x y : LpRRV_eq (LpRRVplus x y) (LpRRVplus y x).
    Proof.
      red; intros.
      LpRRV_simpl.
      apply rv_almost_eq_eq; intros ?.
      unfold rvplus; lra.
    Qed.
    
    Lemma LpRRV_plus_assoc (x y z : LpRRV) : LpRRV_eq (LpRRVplus x (LpRRVplus y z)) (LpRRVplus (LpRRVplus x y) z).
    Proof.
      red; intros.
      LpRRV_simpl.
      apply rv_almost_eq_eq; intros ?.
      unfold rvplus.
      lra.
    Qed.

    Lemma LpRRV_plus_zero (x : LpRRV) : LpRRV_eq (LpRRVplus x (LpRRVconst 0)) x.
    Proof.
      red; intros.
      LpRRV_simpl.
      apply rv_almost_eq_eq; intros ?.
      unfold rvplus, const.
      lra.
    Qed.

    Lemma LpRRV_plus_inv (x: LpRRV) : LpRRV_eq (LpRRVplus x (LpRRVopp x)) (LpRRVconst 0).
    Proof.
      red; intros.
      LpRRV_simpl.
      apply rv_almost_eq_eq; intros ?.
      unfold rvplus, rvopp, rvscale, const.
      lra.
    Qed.

    Lemma LpRRV_scale_scale (x y : R) (u : LpRRV) :
      LpRRV_eq (LpRRVscale x (LpRRVscale y u)) (LpRRVscale (x * y) u).
    Proof.
      red; intros.
      LpRRV_simpl.
      apply rv_almost_eq_eq; intros ?.
      unfold rvplus, rvopp, rvscale, const, mult; simpl.
      lra.
    Qed.

    Lemma LpRRV_scale1 (u : LpRRV) :
      LpRRV_eq (LpRRVscale one u) u.
    Proof.
      red; intros.
      LpRRV_simpl.
      apply rv_almost_eq_eq; intros ?.
      unfold rvplus, rvopp, rvscale, const, mult, one; simpl.
      lra.
    Qed.
    
    Lemma LpRRV_scale_plus_l (x : R) (u v : LpRRV) :
      LpRRV_eq (LpRRVscale x (LpRRVplus u v)) (LpRRVplus (LpRRVscale x u) (LpRRVscale x v)).
    Proof.
      red; intros.
      LpRRV_simpl.
      apply rv_almost_eq_eq; intros ?.
      unfold rvplus, rvopp, rvscale, const, mult; simpl.
      lra.
    Qed.
    
    Lemma LpRRV_scale_plus_r (x y : R) (u : LpRRV) :
      LpRRV_eq (LpRRVscale (x + y) u) (LpRRVplus (LpRRVscale x u) (LpRRVscale y u)).
    Proof.
      red; intros.
      LpRRV_simpl.
      apply rv_almost_eq_eq; intros ?.
      unfold rvplus, rvopp, rvscale, const, mult; simpl.
      lra.
    Qed.

    Section quot.

      Definition LpRRVq : Type := quot LpRRV_eq.

      Definition LpRRVq_const (x:R) : LpRRVq := Quot _ (LpRRVconst x).

      Lemma LpRRVq_constE x : LpRRVq_const x = Quot _ (LpRRVconst x).
      Proof.
        reflexivity.
      Qed.

      Hint Rewrite LpRRVq_constE : quot.

      Definition LpRRVq_zero : LpRRVq := LpRRVq_const 0.

      Lemma LpRRVq_zeroE : LpRRVq_zero = LpRRVq_const 0.
      Proof.
        reflexivity.
      Qed.

      Hint Rewrite LpRRVq_zeroE : quot.

      Definition LpRRVq_scale (x:R) : LpRRVq -> LpRRVq
        := quot_lift _ (LpRRVscale x).

      Lemma LpRRVq_scaleE x y : LpRRVq_scale x (Quot _ y)  = Quot _ (LpRRVscale x y).
      Proof.
        apply quot_liftE.
      Qed.

      Hint Rewrite LpRRVq_scaleE : quot.
      
      Definition LpRRVq_opp  : LpRRVq -> LpRRVq
        := quot_lift _ LpRRVopp.

      Lemma LpRRVq_oppE x : LpRRVq_opp (Quot _ x)  = Quot _ (LpRRVopp x).
      Proof.
        apply quot_liftE.
      Qed.

      Hint Rewrite LpRRVq_oppE : quot.

      Definition LpRRVq_plus  : LpRRVq -> LpRRVq -> LpRRVq
        := quot_lift2 _ LpRRVplus.
      
      Lemma LpRRVq_plusE x y : LpRRVq_plus (Quot _ x) (Quot _ y) = Quot _ (LpRRVplus x y).
      Proof.
        apply quot_lift2E.
      Qed.

      Hint Rewrite LpRRVq_plusE : quot.

      Definition LpRRVq_minus  : LpRRVq -> LpRRVq -> LpRRVq
        := quot_lift2 _ LpRRVminus.

      Lemma LpRRVq_minusE x y : LpRRVq_minus (Quot _ x) (Quot _ y) = Quot _ (LpRRVminus x y).
      Proof.
        apply quot_lift2E.
      Qed.

      Hint Rewrite LpRRVq_minusE : quot.

      Ltac LpRRVq_simpl
        := repeat match goal with
                  | [H: LpRRVq |- _ ] =>
                    let xx := fresh H in destruct (Quot_inv H) as [xx ?]; subst H; rename xx into H
                  end
           ; try autorewrite with quot
           ; try apply (@eq_Quot _ _ LpRRV_eq_equiv).

      Lemma LpRRVq_minus_plus (rv1 rv2:LpRRVq) :
        LpRRVq_minus rv1 rv2 = LpRRVq_plus rv1 (LpRRVq_opp rv2).
      Proof.
        LpRRVq_simpl.
        apply LpRRVminus_plus.
      Qed.

      Lemma LpRRVq_opp_scale (rv:LpRRVq) :
        LpRRVq_opp rv =LpRRVq_scale (-1) rv.
      Proof.
        LpRRVq_simpl.
        apply LpRRVopp_scale.
      Qed.
      
      Lemma LpRRVq_plus_comm x y : LpRRVq_plus x y = LpRRVq_plus y x.
      Proof.
        LpRRVq_simpl.
        apply LpRRV_plus_comm.
      Qed.
      
      Lemma LpRRVq_plus_assoc (x y z : LpRRVq) : LpRRVq_plus x (LpRRVq_plus y z) = LpRRVq_plus (LpRRVq_plus x y) z.
      Proof.
        LpRRVq_simpl.
        apply LpRRV_plus_assoc.
      Qed.


      Lemma LpRRVq_plus_zero (x : LpRRVq) : LpRRVq_plus x LpRRVq_zero = x.
      Proof.
        LpRRVq_simpl.
        apply LpRRV_plus_zero.
      Qed.

      Lemma LpRRVq_plus_inv (x: LpRRVq) : LpRRVq_plus x (LpRRVq_opp x) = LpRRVq_zero.
      Proof.
        LpRRVq_simpl.
        apply LpRRV_plus_inv.
      Qed.
      
      Definition LpRRVq_AbelianGroup_mixin : AbelianGroup.mixin_of LpRRVq
        := AbelianGroup.Mixin LpRRVq LpRRVq_plus LpRRVq_opp LpRRVq_zero
                              LpRRVq_plus_comm LpRRVq_plus_assoc
                              LpRRVq_plus_zero LpRRVq_plus_inv.

      Canonical LpRRVq_AbelianGroup :=
        AbelianGroup.Pack LpRRVq LpRRVq_AbelianGroup_mixin LpRRVq.


      Ltac LpRRVq_simpl ::=
        repeat match goal with
               | [H: LpRRVq |- _ ] =>
                 let xx := fresh H in destruct (Quot_inv H) as [xx ?]; subst H; rename xx into H
               | [H: AbelianGroup.sort LpRRVq_AbelianGroup |- _ ] =>
                 let xx := fresh H in destruct (Quot_inv H) as [xx ?]; subst H; rename xx into H
               end
        ; try autorewrite with quot
        ; try apply (@eq_Quot _ _ LpRRV_eq_equiv).
      
      Lemma LpRRVq_scale_scale (x y : R_Ring) (u : LpRRVq_AbelianGroup) :
        LpRRVq_scale x (LpRRVq_scale y u) = LpRRVq_scale (x * y) u.
      Proof.
        LpRRVq_simpl.
        apply LpRRV_scale_scale.
      Qed.
      
      Lemma LpRRVq_scale1 (u : LpRRVq_AbelianGroup) :
        LpRRVq_scale one u = u.
      Proof.
        LpRRVq_simpl.
        apply LpRRV_scale1.
      Qed.
      
      Lemma LpRRVq_scale_plus_l (x : R_Ring) (u v : LpRRVq_AbelianGroup) :
        LpRRVq_scale x (plus u v) = plus (LpRRVq_scale x u) (LpRRVq_scale x v).
      Proof.
        LpRRVq_simpl.
        apply LpRRV_scale_plus_l.
      Qed.

      Lemma LpRRVq_scale_plus_r (x y : R_Ring) (u : LpRRVq_AbelianGroup) :
        LpRRVq_scale (plus x y) u = plus (LpRRVq_scale x u) (LpRRVq_scale y u).
      Proof.
        LpRRVq_simpl.
        apply LpRRV_scale_plus_r.
      Qed.

      Definition LpRRVq_ModuleSpace_mixin : ModuleSpace.mixin_of R_Ring LpRRVq_AbelianGroup
        := ModuleSpace.Mixin R_Ring LpRRVq_AbelianGroup
                             LpRRVq_scale LpRRVq_scale_scale LpRRVq_scale1
                             LpRRVq_scale_plus_l LpRRVq_scale_plus_r.

      Canonical LpRRVq_ModuleSpace :=
        ModuleSpace.Pack R_Ring LpRRVq (ModuleSpace.Class R_Ring LpRRVq LpRRVq_AbelianGroup_mixin LpRRVq_ModuleSpace_mixin) LpRRVq.
      
    End quot.

  End packed.

  Global Arguments LpRRV : clear implicits.
  Global Arguments LpRRVq : clear implicits.

  (** Lp 0 is a degenerate case; representing the space of all RandomVariables, quotiented by a.e.
      It is still a ModuleSpace.

      For Lp (S p), we can further define a norm (and the ball induced by the distance function defined by the norm),
      and show that it is a UniformSapce and NormedModuleSpace.

      For the special case of Lp 2, it is also a HilbertSpace.  This is shown in RandomVaribleL2.

 *)
  Section packed.

    (* we should probably merge this with the earlier section now *)
    Context {p:R}.
    Context (pbig:1 <= p).
    
    Definition LpRRVnorm (rv_X:LpRRV p) : R
      := power (FiniteExpectation prts (rvpower (rvabs rv_X) (const p))) (Rinv p).

    Global Instance LpRRV_norm_proper : Proper (LpRRV_eq ==> eq) LpRRVnorm.
    Proof.
      unfold Proper, respectful, LpRRVnorm, LpRRV_eq.
      intros.
      f_equal.
      apply FiniteExpectation_proper_almost
      ; try typeclasses eauto.
      apply rv_almost_eq_power_abs_proper
      ; try typeclasses eauto.
      apply rv_almost_eq_abs_proper
      ; trivial
      ; try typeclasses eauto.
    Qed.

    Lemma almost0_lpf_almost0 (rv_X:Ts->R)
          {rrv:RandomVariable dom borel_sa rv_X}
          {isfe: IsFiniteExpectation prts (rvpower (rvabs rv_X) (const p))}:
      rv_almost_eq prts rv_X (const 0) <->
      rv_almost_eq prts (rvpower (rvabs rv_X) (const p)) (const 0).
    Proof.
      intros.
      unfold rv_almost_eq in *.
      erewrite ps_proper.
      - split; intros H; exact H.
      - red; intros a.
        rv_unfold.
        split; intros eqq.
        + rewrite eqq.
          rewrite Rabs_R0.
          rewrite power0_Sbase; lra.
        + apply power_integral in eqq.
          now apply Rabs_eq_0 in eqq.
    Qed.

    (* move to RealRandomVariable *)


    Lemma LpFin0_almost0 (rv_X:Ts->R)
          {rrv:RandomVariable dom borel_sa rv_X}
          {isfe: IsFiniteExpectation prts (rvpower (rvabs rv_X) (const p))}:
      FiniteExpectation prts (rvpower (rvabs rv_X) (const p)) = 0 ->
      rv_almost_eq prts rv_X (const 0).
    Proof.
      intros fin0.
      apply FiniteExpectation_zero_pos in fin0
      ; try typeclasses eauto.
      apply almost0_lpf_almost0
      ; try typeclasses eauto.
      apply fin0.
    Qed.

    (*
    Lemma Rsqr_power_com x n : x² ^ n = (x ^ n)².
    Proof.
      repeat rewrite Rsqr_pow2.
      repeat rewrite <- pow_mult.
      now rewrite mult_comm.
    Qed.
    
    Lemma pow_incr_inv (x y:R) (n : nat) :
      0 <= x ->
      0 <= y ->
      x ^ (S n) <= y ^ (S n) ->
      x <= y.
    Proof.
      intros.
      destruct (Rle_lt_dec x y); trivial.
      assert (y ^ S n <= x ^ S n).
      {
        apply pow_incr.
        split; trivial.
        lra.
      }
      assert (x ^ S n = y ^ S n).
      {
        now apply Rle_antisym.
      }
      replace x with (Rabs x) in H3 by now apply Rabs_pos_eq.
      replace y with (Rabs y) in H3 by now apply Rabs_pos_eq.
      apply Rabs_pow_eq_inv in H3.
      rewrite Rabs_pos_eq in H3 by trivial.
      rewrite Rabs_pos_eq in H3 by trivial.
      lra.
    Qed.
    
    Lemma pow_root_inv x :
      0 <= x ->
      root (INR (S p)) x ^ S p = x.
    Proof.
      intros.
      unfold root.
      match_destr.
      - now rewrite pow0_Sbase.
      - rewrite <- Rpower_pow.
        + rewrite Rpower_mult.
          rewrite Rinv_l.
          * rewrite Rpower_1; trivial.
            lra.
          * apply INR_nzero; lia.
        + apply exp_pos.
    Qed.
    
    Lemma root_pow_inv x :
      0 <= x ->
      root (INR (S p)) (x ^ S p) = x.
    Proof.
      intros.
      unfold root.
      match_destr.
      - now apply pow_integral in e.
      - assert (x <> 0).
        {
          intro; subst.
          rewrite pow_i in n; try lra; try lia.
        }
        rewrite <- Rpower_pow; try lra.
        rewrite Rpower_mult.
        rewrite Rinv_r.
        + rewrite Rpower_1; trivial.
          lra.
        + apply INR_nzero; lia.
    Qed.
     *)
    
    Lemma Minkowski_rv (x y : LpRRV p) (t:R): 
       0 < t < 1 -> 
       rv_le (rvpower (rvplus (rvabs x) (rvabs y)) (const p))
             (rvplus
                (rvscale (power (/t) p) (rvpower (rvabs x) (const p))) 
                (rvscale (power (/(1-t)) p) (rvpower (rvabs y) (const p)))).
    Proof.
      intros.
      intro x0.
      generalize (@minkowski_helper p (rvabs x x0) (rvabs y x0) t); intros.
      unfold rvpow, rvscale, rvplus.
      unfold rvabs in *.
      apply H0; trivial.
      apply Rabs_pos.
      apply Rabs_pos.
   Qed.

    Lemma rvpow_plus_le (x y : LpRRV (S p)) :
      rv_le (rvpow (rvabs (rvplus x y)) (S p)) (rvpow (rvplus (rvabs x) (rvabs y)) (S p)).
    Proof.
      intro x0.
      unfold rvpow, rvabs, rvplus.
      apply pow_maj_Rabs.
      rewrite Rabs_Rabsolu.      
      apply Rabs_triang.
    Qed.
    
    Lemma Minkowski_1 (x y : LpRRV (S p)) (t:R):
       0 < t < 1 -> 
       (FiniteExpectation prts (rvpow (rvabs (rvplus x y)) (S p)))  <=
       (pow (/t) p) * (FiniteExpectation prts (rvpow (rvabs x) (S p))) + 
       (pow (/(1-t)) p) * (FiniteExpectation prts (rvpow (rvabs y) (S p))).
    Proof.
      intros.
      generalize (Minkowski_rv x y t H); intros.
      generalize (rvpow_plus_le x y); intros.
      assert (IsFiniteExpectation prts (rvpow (rvplus (rvabs x) (rvabs y)) (S p))).
      apply (IsFiniteExpectation_bounded _ _ _ _ H1 H0).
      assert (FiniteExpectation prts (rvpow (rvabs (rvplus x y)) (S p)) <=
              FiniteExpectation prts (rvpow (rvplus (rvabs x) (rvabs y)) (S p))).
      apply FiniteExpectation_le.
      apply rvpow_plus_le.
      generalize (FiniteExpectation_le _ _ _ H0); intros.
      rewrite FiniteExpectation_plus in H4.
      rewrite FiniteExpectation_scale in H4.
      rewrite FiniteExpectation_scale in H4.
      apply Rle_trans with 
          (r2 := FiniteExpectation prts (rvpow (rvplus (rvabs x) (rvabs y)) (S p))); trivial.
   Qed.

    Lemma root_nneg x a :
      0 <= root x a.
    Proof.
      intros.
      unfold root.
      match_destr; try lra.
      unfold Rpower.
      left.
      apply exp_pos.
    Qed.

    Lemma root_pos (a : R) :
      0 < a -> 0 < root (INR (S p)) a.
    Proof.
      intros.
      unfold root.
      match_destr.
      congruence.
      apply Rpower_pos.
    Qed.

    Lemma Minkowski_2 (x y : LpRRV (S p))
          (xexppos : 0 < FiniteExpectation prts (rvpow (rvabs x) (S p)))
          (yexppos : 0 < FiniteExpectation prts (rvpow (rvabs y) (S p))) :
       FiniteExpectation prts (rvpow (rvabs (rvplus x y)) (S p))  <=
       pow ((root (INR (S p)) (FiniteExpectation prts (rvpow (rvabs x) (S p)))) +
            (root (INR (S p)) (FiniteExpectation prts (rvpow (rvabs y) (S p))))) (S p).
    Proof.
      generalize (Minkowski_1 x y); intros.
      pose (a := root (INR (S p)) (FiniteExpectation prts (rvpow (rvabs x) (S p)))).
      pose (b := root (INR (S p)) (FiniteExpectation prts (rvpow (rvabs y) (S p)))).
      assert (0 < a).
      unfold a.
      now apply root_pos.
      assert (0 < b).
      now apply root_pos.
      replace (FiniteExpectation prts (rvpow (rvabs x) (S p))) with (pow a (S p)) in H.
      replace (FiniteExpectation prts (rvpow (rvabs y) (S p))) with (pow b (S p)) in H.
      specialize (H (a /(a + b))).
      cut_to H.
      rewrite (minkowski_subst p H0 H1) in H.
      unfold a in H.
      unfold b in H.
      apply H.
      now apply minkowski_range.
      unfold b.
      apply pow_root_inv; now left.
      apply pow_root_inv; now left.      
    Qed.

    Lemma Rle_root_l (a b : R) :
      0 < a -> a  <= b -> root (INR (S p)) a <= root (INR (S p)) b.
    Proof.
      unfold root.
      intros.
      match_destr; [lra |].
      match_destr; [lra |].      
      apply Rle_Rpower_l.
      left; apply Rinv_0_lt_compat.
      apply lt_0_INR; lia.
      split; lra.
    Qed.

    Lemma Minkowski (x y : LpRRV (S p))
          (xexppos : 0 < FiniteExpectation prts (rvpow (rvabs x) (S p)))
          (yexppos : 0 < FiniteExpectation prts (rvpow (rvabs y) (S p))) 
          (xyexppos : 0 < FiniteExpectation prts (rvpow (rvabs (rvplus x y)) (S p))) :
       root (INR (S p)) (FiniteExpectation prts (rvpow (rvabs (rvplus x y)) (S p)))  <=
       (root (INR (S p)) (FiniteExpectation prts (rvpow (rvabs x) (S p)))) +
       (root (INR (S p)) (FiniteExpectation prts (rvpow (rvabs y) (S p)))).
    Proof.
      generalize (Minkowski_2 x y xexppos yexppos); intros.
      apply Rle_root_l in H; trivial.
      rewrite root_pow_inv in H.
      apply H.
      left.
      apply Rplus_lt_0_compat.
      now apply root_pos.
      now apply root_pos.
    Qed.   

    Lemma Minkowski_power (x y : LpRRV (S p))
          (xexppos : 0 < FiniteExpectation prts (rvpow (rvabs x) (S p)))
          (yexppos : 0 < FiniteExpectation prts (rvpow (rvabs y) (S p))) 
          (xyexppos : 0 < FiniteExpectation prts (rvpow (rvabs (rvplus x y)) (S p))) :
       Rpower (FiniteExpectation prts (rvpow (rvabs (rvplus x y)) (S p))) (/ INR (S p)) <=
       Rpower (FiniteExpectation prts (rvpow (rvabs x) (S p))) (/ INR (S p)) +
       Rpower (FiniteExpectation prts (rvpow (rvabs y) (S p))) (/ INR (S p)).
    Proof.
      generalize (Minkowski x y xexppos yexppos xyexppos); intros.
      unfold root in H.
      repeat match_destr_in H; try lra.
    Qed.   

    Lemma LpRRV_norm_plus x y : LpRRVnorm (LpRRVplus x y) <= LpRRVnorm x + LpRRVnorm y.
    Proof.
      unfold Proper, respectful, LpRRVnorm, LpRRVplus.
      simpl LpRRV_rv_X.
      simpl LpRRV_LpS_FiniteLp.
      unfold root.

      (* first we show that the zero cases (which are special cased by root
         work out
       *)

      destruct (Req_EM_T (@FiniteExpectation Ts dom prts (@rvpow Ts (@rvabs Ts (@LpRRV_rv_X (S p) x)) (S p))
             (@LpRRV_LpS_FiniteLp (S p) x)) 0).
      {
        field_simplify.
        apply LpFin0_almost0 in e; try typeclasses eauto.
        rewrite (FiniteExpectation_proper_almost prts (rvpow (rvabs (rvplus x y)) (S p)) (rvpow (rvabs y) (S p))).
        - lra.
        - apply rv_almost_eq_pow_abs_proper
          ; try typeclasses eauto.
          apply rv_almost_eq_abs_proper
          ; try typeclasses eauto.
          generalize (rv_almost_eq_plus_proper prts x (const 0) y y e)
          ; intros HH.
          cut_to HH.
          + apply (rv_almost_eq_rv_trans prts _ (rvplus (const 0) y))
            ; trivial
            ; try typeclasses eauto.
            apply rv_almost_eq_eq.
            intros a.
            rv_unfold.
            lra.
          + apply rv_almost_eq_rv_refl.
            typeclasses eauto.
      }
      destruct (Req_EM_T (FiniteExpectation prts (rvpow (rvabs y) (S p))) 0).
      {
        field_simplify.
        apply LpFin0_almost0 in e; try typeclasses eauto.
        rewrite (FiniteExpectation_proper_almost prts (rvpow (rvabs (rvplus x y)) (S p)) (rvpow (rvabs x) (S p))).
        - match_destr; try lra.
        - apply rv_almost_eq_pow_abs_proper
          ; try typeclasses eauto.
          apply rv_almost_eq_abs_proper
          ; try typeclasses eauto.
          generalize (rv_almost_eq_plus_proper prts x x y (const 0))
          ; intros HH.
          cut_to HH
          ; trivial
          ; try typeclasses eauto.
          + apply (rv_almost_eq_rv_trans prts _ (rvplus x (const 0)))
            ; trivial
            ; try typeclasses eauto.
            apply rv_almost_eq_eq.
            intros a.
            rv_unfold.
            lra.
          + apply rv_almost_eq_rv_refl.
            typeclasses eauto.
      }
      destruct (Req_EM_T (FiniteExpectation prts (rvpow (rvabs (rvplus x y)) (S p))) 0).
      {
        unfold Rpower.
        apply Rplus_le_le_0_compat
        ; left; apply exp_pos.
      }

      assert (xexppos:0 < (@FiniteExpectation Ts dom prts (@rvpow Ts (@rvabs Ts (@LpRRV_rv_X (S p) x)) (S p))
                                              _)).
      {
        destruct (FiniteExpectation_pos prts (rvpow (rvabs x) (S p)) )
        ; congruence.
      } 

      assert (yexppos:0 < (@FiniteExpectation Ts dom prts (@rvpow Ts (@rvabs Ts (@LpRRV_rv_X (S p) y)) (S p)) _
                                             )).
      {
        destruct (FiniteExpectation_pos prts (rvpow (rvabs y) (S p)))
        ; congruence.
      } 

      assert (xyexppos:0 < (@FiniteExpectation Ts dom prts
                                      (rvpow (rvabs (rvplus x y)) (S p))) 
                             _).
      { 
        destruct (FiniteExpectation_pos prts
                                        (rvpow (rvabs (rvplus x y)) (S p)) (isfe:=
          _))
        ; trivial.
        elim n1.
        rewrite H.
        apply FiniteExpectation_pf_irrel.
      }
      now apply Minkowski_power.
    Qed.

    Lemma root_mult_distr x a b :
      0 <= a ->
      0 <= b ->
      root x (a * b) = root x a * root x b.
    Proof.
      intros.
      unfold root.
      match_destr.
      - apply Rmult_integral in e.
        destruct e; subst; simpl
        ; repeat match_destr; lra.
      - repeat (match_destr; subst; try lra).
        rewrite Rpower_mult_distr; trivial; lra.
    Qed.


    Lemma FiniteExpectation_Lp_pos y
          {islp:IsLp (S p) y} :
      0 <= FiniteExpectation prts (rvpow (rvabs y) (S p)).
    Proof.
      apply FiniteExpectation_pos.
      typeclasses eauto.
    Qed.

    Lemma LpRRV_norm_scal_strong x y : LpRRVnorm (LpRRVscale x y) = Rabs x * LpRRVnorm y.
    Proof.
      unfold LpRRVnorm, LpRRVscale.
      simpl LpRRV_rv_X.
      assert (eqq:rv_eq
                    (rvpow (rvabs (rvscale x y)) (S p))
                    (rvscale (Rabs x ^ S p) (rvpow (rvabs y) (S p))))
        by now rewrite rv_abs_scale_eq, rvpow_scale.
      rewrite (FiniteExpectation_ext prts _ _ eqq).
      rewrite FiniteExpectation_scale.
      rewrite root_mult_distr.
      - f_equal.
        rewrite root_pow_inv.
        + lra.
        + apply Rabs_pos.
      - apply pow_le; apply Rabs_pos.
      - apply FiniteExpectation_Lp_pos.
    Qed.

    Lemma LpRRV_norm_scal x y : LpRRVnorm (LpRRVscale x y) <= Rabs x * LpRRVnorm y.
    Proof.
      right.
      apply LpRRV_norm_scal_strong.
    Qed.

    Lemma LpRRV_norm0 x : LpRRVnorm x = 0 -> rv_almost_eq prts x (LpRRVzero (p:=S p)).
    Proof.
      unfold LpRRVnorm, LpRRVzero, LpRRVconst.
      intros.
      apply root_integral in H.
      apply FiniteExpectation_zero_pos in H; try typeclasses eauto.
      erewrite ps_proper in H; try eapply H.
      intros a; simpl; unfold const.
      split; intros eqq.
      + apply pow_integral in eqq.
        now apply Rabs_eq_0.
      + rv_unfold.
        rewrite eqq.
        rewrite Rabs_R0.
        rewrite pow_i; trivial.
        lia.
    Qed.

    Definition LpRRVball (x:LpRRV (S p)) (e:R) (y:LpRRV (S p)): Prop
      := LpRRVnorm (LpRRVminus x y) < e.

    Ltac LpRRV_simpl
      := repeat match goal with
                | [H : LpRRV _ |- _ ] => destruct H as [???]
                end;
         unfold LpRRVball, LpRRVnorm, LpRRVplus, LpRRVminus, LpRRVopp, LpRRVscale, LpRRVnorm in *
         ; simpl pack_LpRRV; simpl LpRRV_rv_X in *.


    Global Instance LpRRV_ball_proper : Proper (LpRRV_eq ==> eq ==> LpRRV_eq ==> iff) LpRRVball.
    Proof.
      intros ?? eqq1 ?? eqq2 ?? eqq3.
      unfold LpRRVball in *.
      rewrite <- eqq1, <- eqq2, <- eqq3.
      reflexivity.
    Qed.

    Definition LpRRVpoint : LpRRV (S p) := LpRRVconst 0.

    Lemma LpRRV_ball_refl x (e : posreal) : LpRRVball x e x.
    Proof.
      LpRRV_simpl.
      assert (eqq1:rv_eq (rvpow (rvabs (rvminus LpRRV_rv_X0 LpRRV_rv_X0)) (S p))
                         (const 0)).
      {
        rewrite rvminus_self.
        rewrite rv_abs_const_eq.
        rewrite Rabs_pos_eq by lra.
        rewrite rvpow_const.
        rewrite pow0_Sbase.
        reflexivity.
      }
      rewrite (FiniteExpectation_ext _ _ _ eqq1).
      rewrite FiniteExpectation_const.
      unfold root.
      match_destr; try lra.
      apply cond_pos.
    Qed.
    
    Lemma LpRRV_ball_sym x y e : LpRRVball x e y -> LpRRVball y e x.
    Proof.
      LpRRV_simpl.
      intros.
      rewrite (FiniteExpectation_ext _ _  (rvpow (rvabs (rvminus LpRRV_rv_X1 LpRRV_rv_X0)) (S p)))
      ; trivial.
      rewrite rvabs_rvminus_sym.
      reflexivity.
    Qed.

    Lemma LpRRV_ball_trans x y z e1 e2 : LpRRVball x e1 y -> LpRRVball y e2 z -> LpRRVball x (e1+e2) z.
    Proof.
      generalize (LpRRV_norm_plus
                       (LpRRVminus x y)
                       (LpRRVminus y z)).
      LpRRV_simpl.
      intros.

      apply (Rle_lt_trans
               _ 
               ((root (INR (S p)) (FiniteExpectation prts (rvpow (rvabs (rvminus LpRRV_rv_X2 LpRRV_rv_X1)) (S p)))) +
                (root (INR (S p)) (FiniteExpectation prts (rvpow (rvabs (rvminus LpRRV_rv_X1 LpRRV_rv_X0)) (S p))))))
      ; [ | now apply Rplus_lt_compat].

      (* by minkowski *)
      rewrite (FiniteExpectation_ext _ (rvpow (rvabs (rvminus LpRRV_rv_X2 LpRRV_rv_X0)) (S p))
                                     (rvpow (rvabs (rvplus (rvminus LpRRV_rv_X2 LpRRV_rv_X1) (rvminus LpRRV_rv_X1 LpRRV_rv_X0))) (S p))); trivial.
      intros a.
      rv_unfold.
      f_equal.
      f_equal.
      lra.
    Qed.

    Lemma LpRRV_close_close (x y : LpRRV (S p)) (eps : R) :
      LpRRVnorm (LpRRVminus y x) < eps ->
      LpRRVball x eps y.
    Proof.
      intros.
      apply LpRRV_ball_sym.
      apply H.
    Qed.

    Definition LpRRVnorm_factor : R := 1.
    
    Lemma LpRRV_norm_ball_compat (x y : LpRRV (S p)) (eps : posreal) :
      LpRRVball x eps y -> LpRRVnorm (LpRRVminus y x) < LpRRVnorm_factor * eps.
    Proof.
      intros HH.
      apply LpRRV_ball_sym in HH.
      unfold LpRRVnorm_factor.
      field_simplify.
      apply HH.
    Qed.

    Lemma LpRRV_plus_opp_minus (x y : LpRRV (S p)) :
      LpRRV_eq (LpRRVplus x (LpRRVopp y)) (LpRRVminus x y).
    Proof.
      unfold LpRRVminus, LpRRVplus, LpRRVopp.
      simpl.
      apply rv_almost_eq_eq.
      intros ?.
      reflexivity.
    Qed.
    
    Section quot.

      
      Ltac LpRRVq_simpl :=
        repeat match goal with
               | [H: LpRRVq _ |- _ ] =>
                 let xx := fresh H in destruct (Quot_inv H) as [xx ?]; subst H; rename xx into H
               | [H: AbelianGroup.sort LpRRVq_AbelianGroup |- _ ] =>
                 let xx := fresh H in destruct (Quot_inv H) as [xx ?]; subst H; rename xx into H
               end
        ; try autorewrite with quot in *
        ; try apply (@eq_Quot _ _ LpRRV_eq_equiv).
      
      Hint Rewrite @LpRRVq_constE : quot.
      Hint Rewrite @LpRRVq_zeroE : quot.
      Hint Rewrite @LpRRVq_scaleE : quot.
      Hint Rewrite @LpRRVq_oppE : quot.
      Hint Rewrite @LpRRVq_plusE : quot.
      Hint Rewrite @LpRRVq_minusE : quot.
      Hint Rewrite @LpRRVq_constE : quot.

      Definition LpRRVq_ball : LpRRVq (S p) -> R -> LpRRVq (S p) -> Prop
        := quot_lift_ball LpRRV_eq LpRRVball.
      
      Lemma LpRRVq_ballE x e y : LpRRVq_ball (Quot _ x) e (Quot _ y)  = LpRRVball x e y.
      Proof.
        apply quot_lift_ballE.
      Qed.

      Hint Rewrite LpRRVq_ballE : quot.
      
      Definition LpRRVq_point : LpRRVq (S p)
        := Quot _ LpRRVpoint.


      Lemma LpRRVq_pointE : LpRRVq_point = Quot _ LpRRVpoint.
      Proof.
        reflexivity.
      Qed.

      Hint Rewrite LpRRVq_pointE : quot.

      Lemma LpRRVq_ball_refl x (e : posreal) : LpRRVq_ball x e x.
      Proof.
        LpRRVq_simpl.
        apply LpRRV_ball_refl.
      Qed.
      
      Lemma LpRRVq_ball_sym x y e : LpRRVq_ball x e y -> LpRRVq_ball y e x.
      Proof.
        LpRRVq_simpl.
        apply LpRRV_ball_sym.
      Qed.

      Lemma LpRRVq_ball_trans x y z e1 e2 : LpRRVq_ball x e1 y -> LpRRVq_ball y e2 z -> LpRRVq_ball x (e1+e2) z.
      Proof.
        LpRRVq_simpl.
        apply LpRRV_ball_trans.
      Qed.

      Definition LpRRVq_UniformSpace_mixin : UniformSpace.mixin_of (LpRRVq (S p))
        := UniformSpace.Mixin  (LpRRVq (S p)) LpRRVq_point LpRRVq_ball
                               LpRRVq_ball_refl
                               LpRRVq_ball_sym
                               LpRRVq_ball_trans.

      Canonical LpRRVq_UniformSpace :=
        UniformSpace.Pack (LpRRVq (S p)) LpRRVq_UniformSpace_mixin (LpRRVq (S p)).

      Canonical LpRRVq_NormedModuleAux :=
        NormedModuleAux.Pack R_AbsRing (LpRRVq (S p))
                             (NormedModuleAux.Class R_AbsRing (LpRRVq (S p))
                                                    (ModuleSpace.class _ (LpRRVq_ModuleSpace))
                                                    (LpRRVq_UniformSpace_mixin)) (LpRRVq (S p)).

      
      Definition LpRRVq_norm : LpRRVq (S p) -> R
        := quot_rec LpRRV_norm_proper.

      Lemma LpRRVq_normE x : LpRRVq_norm (Quot _ x)  = LpRRVnorm x.
      Proof.
        apply quot_recE.
      Qed.

      Hint Rewrite LpRRVq_normE : quot.

      Lemma LpRRVq_norm_plus x y : LpRRVq_norm (LpRRVq_plus x y) <= LpRRVq_norm x + LpRRVq_norm y.
      Proof.
        LpRRVq_simpl.
        now apply LpRRV_norm_plus.
      Qed.
      
      Lemma LpRRVq_norm_scal_strong x y : LpRRVq_norm (LpRRVq_scale x y) = Rabs x * LpRRVq_norm y.
      Proof.
        LpRRVq_simpl.
        now apply LpRRV_norm_scal_strong.
      Qed.

      Lemma LpRRVq_norm_scal x y : LpRRVq_norm (LpRRVq_scale x y) <= Rabs x * LpRRVq_norm y.
      Proof.
        LpRRVq_simpl.
        now apply LpRRV_norm_scal.
      Qed.

      Lemma LpRRVq_norm0 x : LpRRVq_norm x = 0 -> x = LpRRVq_zero.
      Proof.
        intros.
        LpRRVq_simpl.
        now apply LpRRV_norm0.
      Qed.

      Lemma LpRRVq_minus_minus (x y : LpRRVq (S p)) :
        minus x y = LpRRVq_minus x y.
      Proof.
        unfold minus, plus, opp; simpl.
        LpRRVq_simpl.
        apply LpRRVminus_plus.
      Qed.

      Lemma LpRRVq_close_close (x y : LpRRVq (S p)) (eps : R) :
        LpRRVq_norm (minus y x) < eps ->
        LpRRVq_ball x eps y.
      Proof.
        intros.
        rewrite LpRRVq_minus_minus in H.
        LpRRVq_simpl.
        now apply LpRRV_close_close.
      Qed.

      Lemma LpRRVq_norm_ball_compat (x y : LpRRVq (S p)) (eps : posreal) :
        LpRRVq_ball x eps y -> LpRRVq_norm (minus y x) < LpRRVnorm_factor * eps.
      Proof.
        intros.
        rewrite LpRRVq_minus_minus.
        LpRRVq_simpl.
        now apply LpRRV_norm_ball_compat.
      Qed.
 
      Definition LpRRVq_NormedModule_mixin : NormedModule.mixin_of R_AbsRing LpRRVq_NormedModuleAux
        := NormedModule.Mixin R_AbsRing LpRRVq_NormedModuleAux
                              LpRRVq_norm
                              LpRRVnorm_factor
                              LpRRVq_norm_plus
                              LpRRVq_norm_scal
                              LpRRVq_close_close
                              LpRRVq_norm_ball_compat
                              LpRRVq_norm0.

      Definition LpRRVq_NormedModule :=
        NormedModule.Pack R_AbsRing (LpRRVq (S p))
                          (NormedModule.Class R_AbsRing (LpRRVq (S p))
                                              (NormedModuleAux.class _ LpRRVq_NormedModuleAux)
                                              LpRRVq_NormedModule_mixin)
                          (LpRRVq (S p)).

    End quot.
    
  End packed.
  
End Lp.

Hint Rewrite LpRRVq_constE : quot.
Hint Rewrite LpRRVq_zeroE : quot.
Hint Rewrite LpRRVq_scaleE : quot.
Hint Rewrite LpRRVq_oppE : quot.
Hint Rewrite LpRRVq_plusE : quot.
Hint Rewrite LpRRVq_minusE : quot.
Hint Rewrite @LpRRVq_constE : quot.
Hint Rewrite @LpRRVq_zeroE : quot.
Hint Rewrite @LpRRVq_scaleE : quot.
Hint Rewrite @LpRRVq_oppE : quot.
Hint Rewrite @LpRRVq_plusE : quot.
Hint Rewrite @LpRRVq_minusE : quot.
Hint Rewrite @LpRRVq_constE : quot.
Hint Rewrite LpRRVq_normE : quot.

Global Arguments LpRRVq_AbelianGroup {Ts} {dom} prts p.
Global Arguments LpRRVq_ModuleSpace {Ts} {dom} prts p.

Global Arguments LpRRVq_UniformSpace {Ts} {dom} prts p.
Global Arguments LpRRVq_NormedModule {Ts} {dom} prts p.

Ltac LpRRVq_simpl :=
  repeat match goal with
         | [H: LpRRVq _ _ |- _ ] =>
           let xx := fresh H in destruct (Quot_inv H) as [xx ?]; subst H; rename xx into H
         | [H: AbelianGroup.sort (LpRRVq_AbelianGroup _ _) |- _ ] =>
           let xx := fresh H in destruct (Quot_inv H) as [xx ?]; subst H; rename xx into H
         | [H: ModuleSpace.sort R_Ring (LpRRVq_ModuleSpace _ _) |- _ ] =>
           let xx := fresh H in destruct (Quot_inv H) as [xx ?]; subst H; rename xx into H
         end
  ; try autorewrite with quot in *
  ; try apply (@eq_Quot _ _ (LpRRV_eq_equiv _)).

Ltac LpRRV_simpl
  := repeat match goal with
            | [H : LpRRV _ _ |- _ ] => destruct H as [???]
            end
     ; unfold LpRRVplus, LpRRVminus, LpRRVopp, LpRRVscale
     ; simpl.
