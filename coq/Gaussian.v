Require Import mathcomp.ssreflect.ssreflect mathcomp.ssreflect.ssrbool mathcomp.ssreflect.eqtype mathcomp.ssreflect.seq.
Require Import Coquelicot.Hierarchy.
Require Import Coquelicot.RInt.
Require Import Coquelicot.RInt_gen.
Require Import Coquelicot.RInt_analysis.
Require Import Coquelicot.Continuity.
Require Import Coquelicot.Rbar.
Require Import Coquelicot.Derive.
Require Import Coquelicot.AutoDerive.
Require Import Coquelicot.ElemFct.

Require Import Reals.Rbase.
Require Import Reals.Rfunctions.
Require Import Reals.R_sqrt.
Require Import Reals.Ratan.
Require Import Streams.
Require Import Ranalysis_reg.
Require Import Reals.Integration.
Require Import Rtrigo_def.
Require Import Rtrigo1.
Require Import Ranalysis1.
Require Import Lra Omega.

Require Import Utils.

Set Bullet Behavior "Strict Subproofs".

(* main results:
  Definition Standard_Gaussian_PDF (t:R) := (/ (sqrt (2*PI))) * exp (-t^2/2).

  Lemma Standard_Gaussian_PDF_normed : 
     is_RInt_gen Standard_Gaussian_PDF (Rbar_locally m_infty) (Rbar_locally p_infty) 1.

  Definition Standard_Gaussian_CDF (t:Rbar) := 
      RInt_gen Standard_Gaussian_PDF (Rbar_locally m_infty) (at_point t).

  Lemma std_CDF_from_erf :
     forall x:R, Standard_Gaussian_CDF x = (/ 2) + (/2)*erf (x/sqrt 2).

  Lemma mean_standard_gaussian :
     is_RInt_gen (fun t => t*Standard_Gaussian_PDF t) 
           (Rbar_locally m_infty) (Rbar_locally p_infty) 0.
   
  Lemma variance_standard_gaussian :
     is_RInt_gen (fun t => t^2*Standard_Gaussian_PDF t) 
           (Rbar_locally m_infty) (Rbar_locally p_infty) 1.

  CoFixpoint mkGaussianStream (uniformStream : Stream R) : Stream R

  Lemma General_Gaussian_PDF_normed (mu sigma:R) : 
     sigma>0 ->
     ex_RInt_gen Standard_Gaussian_PDF (Rbar_locally' m_infty) (at_point (- mu / sigma)) ->
     ex_RInt_gen Standard_Gaussian_PDF (at_point (- mu / sigma)) (Rbar_locally' p_infty) ->
     is_RInt_gen (General_Gaussian_PDF mu sigma) (Rbar_locally' m_infty) (Rbar_locally' p_infty) 1.

  Lemma mean_general_gaussian (mu sigma:R) :
    sigma > 0 ->
    ex_RInt_gen Standard_Gaussian_PDF (Rbar_locally' m_infty) (at_point (- mu / sigma)) ->
    ex_RInt_gen Standard_Gaussian_PDF (at_point (- mu / sigma)) (Rbar_locally' p_infty) ->

    is_RInt_gen (fun t => t*General_Gaussian_PDF mu sigma t) 
                           (Rbar_locally' m_infty) (Rbar_locally' p_infty) mu.
 
  Lemma variance_general_gaussian (mu sigma : R) :
    sigma > 0 ->
    ex_RInt_gen (fun t : R => sigma ^ 2 * t ^ 2 * Standard_Gaussian_PDF t)
              (Rbar_locally' m_infty) (at_point (- mu / sigma)) ->
    ex_RInt_gen (fun t : R => sigma ^ 2 * t ^ 2 * Standard_Gaussian_PDF t)
              (at_point (- mu / sigma)) (Rbar_locally' p_infty) ->
    is_RInt_gen (fun t => (t-mu)^2*General_Gaussian_PDF mu sigma t) 
              (Rbar_locally' m_infty) (Rbar_locally' p_infty) (sigma^2).

  Definition Indicator (a b t:R) :=
    (if Rlt_dec t a then 0 else 
     (if Rgt_dec t b then 0 else 1)).

  Definition Uniform_PDF (a b t:R) := 
    (/ (b-a)) * Indicator a b t.

  Lemma Uniform_normed (a b:R) :
    a < b -> is_RInt_gen (Uniform_PDF a b) (Rbar_locally' m_infty) (Rbar_locally' p_infty) 1.

  Lemma Uniform_mean (a b:R) :
    a < b -> is_RInt_gen (fun t => t*(Uniform_PDF a b t)) (Rbar_locally' m_infty) (Rbar_locally' p_infty) ((b+a)/2).

  Lemma Uniform_variance (a b:R) :
    a < b -> is_RInt_gen (fun t => (t-(b+a)/2)^2*(Uniform_PDF a b t)) (Rbar_locally' m_infty) (Rbar_locally' p_infty) ((b-a)^2/12).

*)

Local Open Scope R_scope.
Implicit Type f : R -> R.

Definition erf' (x:R) := (2 / sqrt PI) * exp(-x^2).
Definition erf (x:R) := RInt erf' 0 x.

Axiom erf_pinfty : Lim erf p_infty = 1.
Axiom erf_minfty : Lim erf m_infty = -1.
Axiom erf_ex_lim : forall (x:Rbar), ex_lim erf x.

(* following is standard normal density, i.e. has mean 0 and std=1 *)
(* CDF(x) = RInt_gen Standard_Gaussian_PDF (Rbar_locally m_infty) (Rbar_locally x) *)
Definition Standard_Gaussian_PDF (t:R) := (/ (sqrt (2*PI))) * exp (-t^2/2).

(* general gaussian density with mean = mu and std = sigma *)
Definition General_Gaussian_PDF (mu sigma t : R) :=
   (/ (sigma * (sqrt (2*PI)))) * exp (- (t - mu)^2/(2*sigma^2)).

Lemma gen_from_std (mu sigma : R) :
   sigma > 0 -> forall x:R,  General_Gaussian_PDF mu sigma x = 
                             / sigma * Standard_Gaussian_PDF ((x-mu)/sigma).
Proof.
  intros.
  assert (sigma <> 0).
  now apply Rgt_not_eq.
  generalize sqrt_2PI_nzero; intros.

  unfold General_Gaussian_PDF.
  unfold Standard_Gaussian_PDF.
  field_simplify.
  unfold Rdiv.
  apply Rmult_eq_compat_r.
  apply f_equal.
  now field_simplify.
  lra.
  lra.
Qed.  

(* standard normal distribution *)

Definition Standard_Gaussian_CDF (t:R) := 
  RInt_gen Standard_Gaussian_PDF (Rbar_locally m_infty) (at_point t).

Definition General_Gaussian_CDF (mu sigma : R) (t:R) := 
  RInt_gen (General_Gaussian_PDF mu sigma) (Rbar_locally m_infty) (at_point t).

Lemma continuous_Standard_Gaussian_PDF :
  forall (x:R), continuous Standard_Gaussian_PDF x.
Proof.
  intros.
  unfold Standard_Gaussian_PDF.
  apply continuous_mult with (f:= fun t => / sqrt (2*PI)) (g:=fun t=> exp(-t^2/2)).
  apply continuous_const.
  apply continuous_comp with (g := exp).
  unfold Rdiv.
  apply continuous_mult with (f := fun t => -t^2) (g := fun t => /2).
  apply continuous_opp with (f := fun t =>  t^2).
  apply continuous_mult with (f := id).
  apply continuous_id.
  apply continuous_mult with (f := id).
  apply continuous_id.
  apply continuous_const.
  apply continuous_const.  
  apply ex_derive_continuous with (f := exp) (x0 := -x^2/2).
  apply ex_derive_Reals_1.
  unfold derivable_pt.
  unfold derivable_pt_abs.
  exists (exp (- x ^ 2 / 2)).
  apply derivable_pt_lim_exp.
Qed.

Lemma ex_RInt_Standard_Gaussian_PDF (a b:R) :
  ex_RInt Standard_Gaussian_PDF a b.
Proof.
  intros.
  apply ex_RInt_continuous with (f:=Standard_Gaussian_PDF).
  intros.
  apply continuous_Standard_Gaussian_PDF.
Qed.

Lemma derive_xover_sqrt2 (x:R):
  Derive (fun x => x/sqrt 2) x = /sqrt 2.
Proof.
  generalize sqrt2_neq0; intros.
  unfold Rdiv.
  rewrite Derive_mult.
  rewrite Derive_id.
  rewrite Derive_const.
  now field_simplify.
  apply ex_derive_id.
  apply ex_derive_const.
Qed.
  
Lemma continuous_erf' :
  forall (x:R), continuous erf' x.
Proof.
  intros.
  unfold erf'.
  apply continuous_mult with (f := fun x => 2 / sqrt PI).
  apply continuous_const.
  apply continuous_comp with (g := exp).
  apply continuous_opp with (f := fun x => x^2).
  apply continuous_mult with (f:=id).
  apply continuous_id.
  apply continuous_mult with (f:=id).
  apply continuous_id.
  apply continuous_const.
  apply ex_derive_continuous with (f := exp).
  apply ex_derive_Reals_1.
  apply derivable_pt_exp.
Qed.

Lemma std_pdf_from_erf' (x:R):
  Standard_Gaussian_PDF x = / (2*sqrt 2) * (erf' (x / sqrt 2)).
Proof.
  unfold Standard_Gaussian_PDF.
  unfold erf'.
  field_simplify.
  replace (sqrt (2*PI)) with (sqrt(2)*sqrt(PI)).
  unfold Rdiv.
  apply Rmult_eq_compat_r.
  apply f_equal.
  field_simplify.
  replace (sqrt 2 ^ 2) with (2); trivial.
  rewrite <- Rsqr_pow2.  
  rewrite -> Rsqr_sqrt with (x:=2); trivial; lra.
  apply sqrt2_neq0.
  rewrite sqrt_mult_alt; trivial; lra.
  split.
  assert (PI > 0) by apply PI_RGT_0.
  apply Rgt_not_eq.
  apply sqrt_lt_R0; lra.
  apply sqrt2_neq0.
  apply sqrt_2PI_nzero.
Qed.

Lemma std_pdf_from_erf (x:R):
  Derive (fun t=> erf (t/sqrt 2)) x = 2 * Standard_Gaussian_PDF x.
Proof.
  generalize sqrt2_neq0; intros.
  assert (PI > 0) by apply PI_RGT_0.
  assert (sqrt PI <> 0).
  apply Rgt_not_eq.
  apply sqrt_lt_R0; lra.
  unfold erf.
  assert (forall y:R, ex_RInt erf' 0 y).
  intros.
  apply (@ex_RInt_continuous R_CompleteNormedModule).
  intros.
  apply continuous_erf'.
  rewrite Derive_comp.
  rewrite Derive_RInt.
  rewrite derive_xover_sqrt2.
  rewrite std_pdf_from_erf'.
  now field_simplify.
  apply locally_open with (D:=fun _ => True); trivial.
  apply open_true.
  apply continuous_erf'.
  unfold ex_derive.
  exists (erf' (x / sqrt 2)).
  apply is_derive_RInt with (a:=0).
  apply locally_open with (D:=fun _ => True); trivial.
  apply open_true.
  intros.
  now apply RInt_correct with (f:=erf') (a:=0) (b:=x0).
  apply continuous_erf'.
  unfold Rdiv.
  apply ex_derive_mult.
  apply ex_derive_id.
  apply ex_derive_const.
Qed.

Lemma scale_mult (a x : R) : (scal a x) = (a * x).
Proof.
  reflexivity.
Qed.

Hint Resolve Rlt_sqrt2_0 sqrt2_neq0 Rinv_pos : Rarith.

Lemma std_from_erf0 (x:R) : 
  RInt Standard_Gaussian_PDF 0 x = / 2 * erf(x/sqrt 2).
Proof.
  unfold erf.
  replace (/ 2 * RInt erf' 0 (x / sqrt 2)) with (scal (/ 2) (RInt erf' 0 (x / sqrt 2))).
  - rewrite <- RInt_scal with (l := /2) (f:=erf') (a := 0) (b := x / sqrt 2).
    + replace (0) with (/ sqrt 2 * 0 + 0) at 2 by lra.
      replace (x / sqrt 2) with (/ sqrt 2 * x + 0) by lra.
      rewrite <- RInt_comp_lin with (v:=0) (u:=/sqrt 2) (a:=0) (b:=x).
      * apply RInt_ext.
        intros.
        rewrite std_pdf_from_erf'.
        { replace (erf'(/ sqrt 2 * x0 + 0)) with (erf' (x0/sqrt 2)).
          - repeat rewrite scale_mult.
            field_simplify; auto with Rarith.
          - f_equal.
            field_simplify; auto with Rarith.
        }
      * apply ex_RInt_scal with (f := erf').
        field_simplify; auto with Rarith.
        apply ex_RInt_continuous with (f := erf') (a:=0 / sqrt 2) (b := x /sqrt 2).
        intros.
        apply continuous_erf'.
    + apply ex_RInt_continuous with (f := erf') (a:=0) (b := x /sqrt 2).  
      intros.
      apply continuous_erf'.
  - reflexivity.
Qed.

Lemma erf0_limit_p_infty : Lim (fun x => erf(x/sqrt 2)) p_infty = 1.
Proof.
  assert (A1:Lim (fun x : R => x / sqrt 2) p_infty = p_infty).
  {
    unfold Rdiv.
    rewrite Lim_scal_r.
    rewrite Lim_id.
    apply Rbar_mult_p_infty_pos.
    auto with Rarith.
  }
  rewrite (Lim_comp erf (fun x => x / sqrt 2)).
  - now rewrite A1 erf_pinfty.
  - rewrite A1.
    apply erf_ex_lim.
  - apply ex_lim_scal_r.
    apply ex_lim_id.
  - rewrite A1.
    red.
    exists 0; intros.
    discriminate.
Qed.

Lemma erf0_limit_m_infty : Lim (fun x => erf(x/sqrt 2)) m_infty = -1.
Proof.
  assert (A1:Lim (fun x : R => x / sqrt 2) m_infty = m_infty).
  {
    unfold Rdiv.
    rewrite Lim_scal_r.
    rewrite Lim_id.
    apply Rbar_mult_m_infty_pos.
    auto with Rarith.
  }
  rewrite (Lim_comp erf (fun x => x / sqrt 2)).
  - now rewrite A1 erf_minfty.
  - rewrite A1.
    apply erf_ex_lim.
  - apply ex_lim_scal_r.
    apply ex_lim_id.
  - rewrite A1.
    red.
    exists 0; intros.
    discriminate.
Qed.

Lemma ex_lim_Standard_Gaussian_PDF :
  ex_lim (fun a : R => RInt Standard_Gaussian_PDF 0 a) m_infty.
Proof.
  apply ex_lim_ext with (f := fun a => (/2) * erf (/sqrt 2 * a + 0)).
  intros.
  symmetry.
  replace (erf(/sqrt 2 * y + 0) ) with (erf(y/sqrt 2)).
  apply std_from_erf0.
  apply f_equal.
  field.
  apply sqrt2_neq0.
  apply ex_lim_comp_lin with (f := fun x => /2 * erf x) (a := /sqrt 2) (b := 0).
  apply ex_lim_scal_l with (a:=/2). 
  apply erf_ex_lim.
Qed.


(* generates 2 gaussian samples from 2 uniform samples *)
(* with mean 0 and variance 1 *)
Definition Box_Muller (uniform1 uniform2: R) : (R * R) :=
  let r := sqrt (-2 * (ln uniform1)) in
  let theta := 2 * PI * uniform2 in
  (r * cos theta, r * sin theta).

CoFixpoint mkGaussianStream (uniformStream : Stream R) : Stream R :=
  let u1 := hd uniformStream in
  let ust2 := tl uniformStream in
  let u2 := hd ust2 in
  let ust3 := tl ust2 in
  let '(g1,g2) := Box_Muller u1 u2 in
  Cons g1 (Cons g2 (mkGaussianStream ust3)).

Lemma continuous_Standard_Gaussian_mean_PDF : 
  forall (x:R), continuous (fun t => t * (Standard_Gaussian_PDF t)) x.
Proof.  
  intros.
  apply continuous_scal with (f:=Standard_Gaussian_PDF).
  apply continuous_id.
  apply continuous_Standard_Gaussian_PDF.
Qed.

Lemma continuous_Standard_Gaussian_variance_PDF : 
  forall (x:R), continuous (fun t => t^2 * (Standard_Gaussian_PDF t)) x.
Proof.  
  intros.
  apply continuous_scal with  (f:=Standard_Gaussian_PDF).
  unfold pow.
  apply continuous_scal with  (f:=fun y=> y*1).
  apply continuous_id.
  apply continuous_scal with  (f:=fun y=> 1).
  apply continuous_id.
  apply continuous_const.
  apply continuous_Standard_Gaussian_PDF.
Qed.

Lemma ex_RInt_Standard_Gaussian_mean_PDF (a b:R) :
    ex_RInt (fun t => t * (Standard_Gaussian_PDF t)) a b.
Proof.
  intros.
  apply ex_RInt_continuous with (f := fun t => t * (Standard_Gaussian_PDF t)).
  intros.
  apply continuous_Standard_Gaussian_mean_PDF.
Qed.

Lemma ex_RInt_Standard_Gaussian_variance_PDF (a b:R) :
    ex_RInt (fun t => t^2 * (Standard_Gaussian_PDF t)) a b.
Proof.
  intros.
  apply ex_RInt_continuous with (f := fun t => t^2 * (Standard_Gaussian_PDF t)).
  intros.
  apply continuous_Standard_Gaussian_variance_PDF.
Qed.

Lemma variance_exint0 (a b:Rbar) :
  ex_RInt (fun t => (t^2-1)*Standard_Gaussian_PDF t) a b.
Proof.
  intros.
  assert (ex_RInt (fun t => t^2*Standard_Gaussian_PDF t - Standard_Gaussian_PDF t) a b).
  apply ex_RInt_minus with (f := fun t=> t^2*Standard_Gaussian_PDF t)
                           (g := Standard_Gaussian_PDF).
  now apply ex_RInt_Standard_Gaussian_variance_PDF.
  now apply ex_RInt_Standard_Gaussian_PDF.
  apply ex_RInt_ext with (f := (fun t : R => t ^ 2 * Standard_Gaussian_PDF t - Standard_Gaussian_PDF t)) (g := (fun t : R => (t ^ 2 - 1) * Standard_Gaussian_PDF t)).
  intros.
  lra.
  trivial.
Qed.  

Lemma variance_int0 (a b:Rbar) :
  RInt (fun t => t^2*Standard_Gaussian_PDF t) a b =
  RInt (fun t => (t^2-1)*Standard_Gaussian_PDF t) a b +
  RInt (fun t => Standard_Gaussian_PDF t) a b.
Proof.
  intros.
  replace (RInt (fun t : R => t ^ 2 * Standard_Gaussian_PDF t) a b) with
      (RInt (fun t : R => (t^2-1)*Standard_Gaussian_PDF t + Standard_Gaussian_PDF t) a b).
  apply RInt_plus with (f := (fun t => (t^2-1)*Standard_Gaussian_PDF t))
                       (g := (fun t => Standard_Gaussian_PDF t)).
  apply variance_exint0; trivial.
  now apply ex_RInt_Standard_Gaussian_PDF.
  apply RInt_ext.
  intros.
  lra.
Qed.

Lemma derivable_pt_std_nmean (x:R) : 
  derivable_pt (fun t => -t*Standard_Gaussian_PDF t) x.
Proof.

  repeat first [
           apply derivable_pt_mult
         | apply derivable_pt_opp
         | apply derivable_pt_id
         | apply derivable_pt_const
         | apply derivable_pt_div
         | apply derivable_pt_comp with (f1 := (fun t => -t^2/2))
         | apply derivable_pt_exp
         ].
Qed.

Ltac solve_derive := try solve [auto_derive; trivial | lra].

Lemma variance_derive (x:R) : 
      Derive (fun t => -t*Standard_Gaussian_PDF t) x = (x^2-1)*Standard_Gaussian_PDF x.
Proof.

  generalize sqrt_2PI_nzero; intros.

  rewrite -> Derive_mult with (f := fun t => -t) (g := Standard_Gaussian_PDF)
  ; try solve [unfold Standard_Gaussian_PDF; solve_derive].
  rewrite Derive_opp.
  rewrite Derive_id.
  ring_simplify.
  unfold Rminus.
  rewrite -> Rplus_comm with (r1 := Standard_Gaussian_PDF x * x ^ 2).
  apply Rplus_eq_compat_l.
  unfold Standard_Gaussian_PDF.
  rewrite Derive_mult; solve_derive.
  rewrite Derive_const; solve_derive.
  ring_simplify.
  rewrite Derive_comp; solve_derive.
  rewrite Derive_div; solve_derive.
  rewrite Derive_const.
  rewrite Derive_opp.
  rewrite Derive_mult; solve_derive.
  rewrite Derive_mult; solve_derive.
  rewrite Derive_id.
  rewrite Derive_const.
  field_simplify; try lra. 
  rewrite <- Derive_Reals with (pr := derivable_pt_exp (-x^2/2)).
  rewrite derive_pt_exp.
  field_simplify; lra.
Qed.

Lemma limxexp_inv_inf : is_lim (fun t => exp(t^2/2) / t) p_infty p_infty.
Proof.
  eapply is_lim_le_p_loc; [idtac | apply is_lim_div_exp_p].
  unfold Rbar_locally'.
  exists 3; intros.
  apply Rmult_le_compat_r.
  - left.
    apply Rinv_0_lt_compat.
    lra.
  - left.
    apply exp_increasing.
    simpl.
    replace x with (x*1) at 1 by lra.
    unfold Rdiv.
    repeat rewrite Rmult_assoc.
    apply Rmult_lt_compat_l; lra.
Qed.
  
Lemma limxexp_inf : is_lim (fun t => t*exp(-t^2/2)) p_infty 0.
Proof.
  generalize (limxexp_inv_inf); intros HH.
  apply is_lim_inv in HH; try discriminate.
  simpl in HH.
  eapply is_lim_ext_loc; try apply HH.
  intros.
  simpl.
  exists 0.
  intros x xpos.
  replace (- (x * (x * 1)) / 2) with (- ((x * (x * 1)) / 2)) by lra.
  rewrite exp_Ropp.
  field.
  split; try lra.
  generalize (exp_pos (x * (x * 1) / 2)).
  lra.
Qed.

Lemma limxexp_minf : is_lim (fun t => t*exp(-t^2/2)) m_infty 0.
Proof.
  generalize limxexp_inf; intros HH.
  generalize (is_lim_comp (fun t => t*exp(-t^2/2)) Ropp m_infty 0 p_infty HH); intros HH2.
  cut_to HH2.
  - apply is_lim_opp in HH2.
    simpl in HH2.
    replace (- 0) with 0 in HH2 by lra.
    eapply is_lim_ext; try eapply HH2.
    intros; simpl.
    field_simplify.
    do 3 f_equal.
    lra.
  - generalize (is_lim_id m_infty); intros HH3.
    apply is_lim_opp in HH3.
    simpl in HH3.
    apply HH3.
  - simpl.
    exists 0; intros; discriminate.
Qed.

Lemma continuous_derive_gaussian_opp_mean x :
  continuous (Derive (fun t : R => - t * Standard_Gaussian_PDF t)) x.
Proof.
  apply (continuous_ext (fun t => (t^2-1)*Standard_Gaussian_PDF t)).
  intros.
  now rewrite variance_derive.
  apply continuous_mult with (f := fun t => t^2-1).
  apply continuous_minus with (f := fun t => t^2).
  apply continuous_mult with (f:=id).
  apply continuous_id.
  apply continuous_mult with (f:=id).
  apply continuous_id.
  apply continuous_const.
  apply continuous_const.
  apply continuous_Standard_Gaussian_PDF.
Qed.

Lemma plim_gaussian_opp_mean : is_lim (fun t => - t*(Standard_Gaussian_PDF t)) p_infty 0.
Proof.
  replace (0) with ((- / sqrt (2*PI)) * 0) by lra.  
  unfold Standard_Gaussian_PDF.
  apply (is_lim_ext (fun t : R => (- / sqrt (2 * PI)) * (t * exp (- t ^ 2 / 2)))).
  intros.
  field_simplify; trivial.
  apply sqrt_2PI_nzero.
  apply sqrt_2PI_nzero.
  apply is_lim_scal_l with (a:=- / sqrt (2 * PI)) (l := 0).
  apply limxexp_inf.  
Qed.  

Lemma mlim_gaussian_opp_mean : is_lim (fun t => - t*(Standard_Gaussian_PDF t)) m_infty 0.
Proof.
  replace (0) with ((- / sqrt (2*PI)) * 0) by lra.  
  unfold Standard_Gaussian_PDF.
  apply (is_lim_ext (fun t : R => (- / sqrt (2 * PI)) * (t * exp (- t ^ 2 / 2)))).
  intros.
  field_simplify; trivial.
  apply sqrt_2PI_nzero.
  apply sqrt_2PI_nzero.
  apply is_lim_scal_l with (a:=- / sqrt (2 * PI)) (l := 0).
  apply limxexp_minf.  
Qed.

Lemma variance_int1_middle :
  is_RInt_gen (fun t => (t^2-1)*Standard_Gaussian_PDF t) (Rbar_locally m_infty) (Rbar_locally p_infty) 0.
Proof.
  apply (is_RInt_gen_ext (Derive (fun t : R => - t * Standard_Gaussian_PDF t))).
  - simpl.
    eapply (Filter_prod _ _ _ (fun _ => True) (fun _ => True))
    ; simpl; eauto.
    intros.
    now rewrite variance_derive.
  - replace 0 with (0 - 0) by lra.
    apply is_RInt_gen_Derive.
    + eapply (Filter_prod _ _ _ (fun _ => True) (fun _ => True))
      ; simpl; eauto.
      intros; simpl.
      unfold Standard_Gaussian_PDF.
      now auto_derive.
    + eapply (Filter_prod _ _ _ (fun _ => True) (fun _ => True))
      ; simpl; eauto.
      intros; simpl.
      apply continuous_derive_gaussian_opp_mean.
    + apply mlim_gaussian_opp_mean.
    + apply plim_gaussian_opp_mean.
  Unshelve.
  exact 0.
  exact 0.
  exact 0.
  exact 0.
  exact 0.
  exact 0.
Qed.

Lemma Standard_Gaussian_PDF_int1_pinf : 
  is_RInt_gen Standard_Gaussian_PDF (at_point 0) (Rbar_locally' p_infty)  (/2).
Proof.
  apply lim_rint_gen_Rbar.
  apply ex_RInt_Standard_Gaussian_PDF.
  apply is_lim_ext with (f := (fun x => / 2 * erf(x/sqrt 2))).
  intros.
  symmetry.
  apply std_from_erf0.
  replace (Finite (/ 2)) with (Rbar_mult (/ 2) (Finite 1)).
  apply is_lim_scal_l with (a:=/2) (f:= fun x:R => erf(x/sqrt 2)) (l := 1).
  replace (Finite 1) with (Lim (fun x : R => erf (x / sqrt 2)) p_infty).
  apply Lim_correct.
  apply ex_lim_ext with (f := fun x => erf ((/ sqrt 2) * x + 0)).
  intros.
  apply f_equal; lra.
  apply ex_lim_comp_lin with (f := erf) (a := / sqrt 2) (b:=0).
  apply erf_ex_lim.
  apply erf0_limit_p_infty.
  apply Rbar_finite_eq; lra.
Qed.

Lemma Standard_Gaussian_PDF_int1_minf : 
  is_RInt_gen Standard_Gaussian_PDF (at_point 0) (Rbar_locally' m_infty)  (-/2).
Proof.
  apply lim_rint_gen_Rbar.
  apply ex_RInt_Standard_Gaussian_PDF.
  apply is_lim_ext with (f := (fun x => / 2 * erf(x/sqrt 2))).
  intros.
  symmetry.
  apply std_from_erf0.
  replace (Finite (-/ 2)) with (Rbar_mult (/ 2) (Finite (-1))).
  apply is_lim_scal_l with (a:=/2) (f:= fun x:R => erf(x/sqrt 2)) (l := -1).
  replace (Finite (-1)) with (Lim (fun x : R => erf (x / sqrt 2)) m_infty).
  apply Lim_correct.
  apply ex_lim_ext with (f := fun x => erf ((/ sqrt 2) * x + 0)).
  intros.
  apply f_equal; lra.
  apply ex_lim_comp_lin with (f := erf) (a := / sqrt 2) (b:=0).
  apply erf_ex_lim.
  apply erf0_limit_m_infty.
  apply Rbar_finite_eq; lra.
Qed.

Lemma std_CDF_from_erf0 :
  forall x:R, is_RInt_gen Standard_Gaussian_PDF (Rbar_locally' m_infty) (at_point x)  ((/ 2) + (/2)*erf (x/sqrt 2)).
Proof.
  intros.
  apply (@is_RInt_gen_Chasles R_CompleteNormedModule) with (b := 0) (l1 := /2) (l2 := /2 * erf (x / sqrt 2)).
  apply Rbar_locally'_filter.
  apply at_point_filter.
  replace (/2) with (opp (- /2)).
  apply (@is_RInt_gen_swap R_CompleteNormedModule).
  apply Rbar_locally'_filter.
  apply at_point_filter.
  apply Standard_Gaussian_PDF_int1_minf.
  compute; field_simplify; auto.
  rewrite is_RInt_gen_at_point.
  replace (/ 2 * erf (x / sqrt 2)) with (RInt Standard_Gaussian_PDF 0 x).
  apply RInt_correct.
  apply ex_RInt_Standard_Gaussian_PDF.
  apply std_from_erf0.
Qed.

Lemma std_CDF_from_erf :
  forall x:R, Standard_Gaussian_CDF x =  (/ 2) + (/2)*erf (x/sqrt 2).
Proof.
  intros.
  unfold Standard_Gaussian_CDF.
  apply is_RInt_gen_unique.
  apply std_CDF_from_erf0.
Qed.

Lemma Standard_Gaussian_PDF_normed : 
  is_RInt_gen Standard_Gaussian_PDF (Rbar_locally m_infty) (Rbar_locally p_infty) 1.
Proof.  
  replace (1) with (plus (/ 2) (/ 2)).
  apply (@is_RInt_gen_Chasles R_CompleteNormedModule) with (b := 0) (l1 := /2) (l2 := /2).  
  apply Rbar_locally_filter.
  apply Rbar_locally_filter.  
  replace (/ 2) with (opp (opp (/2))).
  apply (@is_RInt_gen_swap R_CompleteNormedModule) with (l := (opp (/2))).
  apply Rbar_locally_filter.  
  apply at_point_filter.
  apply Standard_Gaussian_PDF_int1_minf.
  apply opp_opp.
  apply Standard_Gaussian_PDF_int1_pinf.
  compute; lra.
Qed.

Lemma variance_standard_gaussian0 :
  is_RInt_gen (fun t => (t^2-1)*Standard_Gaussian_PDF t + Standard_Gaussian_PDF t) (Rbar_locally m_infty) (Rbar_locally p_infty) 1.
Proof.
  intros.
  replace (1) with (0 + 1) at 1 by lra.
  apply is_RInt_gen_plus with 
      (f:=(fun t => (t^2-1)*Standard_Gaussian_PDF t)) (lf :=0)
      (g:=(fun t => Standard_Gaussian_PDF t)) (lg := 1).
  apply variance_int1_middle.
  apply Standard_Gaussian_PDF_normed.
Qed.

Lemma variance_standard_gaussian :
  is_RInt_gen (fun t => t^2*Standard_Gaussian_PDF t) 
           (Rbar_locally m_infty) (Rbar_locally p_infty) 1.
Proof.
  eapply is_RInt_gen_ext; try eapply variance_standard_gaussian0.
  eapply (Filter_prod _ _ _ (fun _ => True) (fun _ => True))
  ; simpl; eauto.
  intros; simpl.
  unfold Standard_Gaussian_PDF.
  lra.
  Unshelve.
  exact 0.
  exact 0.
Qed.

Lemma limexp_inf : is_lim (fun t => exp(t^2/2)) p_infty p_infty.
Proof.
  eapply is_lim_le_p_loc; [idtac | apply is_lim_exp_p].
  unfold Rbar_locally'.
  exists 2; intros.
  left.
  apply exp_increasing.
  simpl.
  replace (x) with (x*1) at 1 by lra.
  replace (x * (x * 1) / 2) with (x * (x / 2)) by lra.
  apply Rmult_lt_compat_l; lra.
Qed.

Lemma limexp_neg_inf : is_lim (fun t => exp(-t^2/2)) p_infty 0.
Proof.
  apply (is_lim_ext (fun t => / exp(t^2/2))).
  intros.
  symmetry.
  replace (- y^2/2) with (- (y^2/2)).
  apply exp_Ropp with (x:=y^2/2).
  lra.
  replace (Finite 0) with (Rbar_inv p_infty).
  apply is_lim_inv.
  apply limexp_inf.
  discriminate.
  now compute.
Qed.

Lemma limexp_neg_minf : is_lim (fun t => exp(-t^2/2)) m_infty 0.
Proof.
  replace (0) with ((-1) * 0 + 0).
  apply (is_lim_ext (fun t => exp(-(-1*t+0)^2/2))).
  intros.
  apply f_equal.
  now field_simplify.
  apply is_lim_comp_lin with (a := -1) (b := 0) (f := fun t => exp(-t^2/2)).
  replace (Rbar_plus (Rbar_mult (-1) m_infty) 0) with (p_infty).
  replace (-1 * 0 + 0) with (0) by lra.
  apply limexp_neg_inf.
  rewrite Rbar_plus_0_r.
  symmetry.
  rewrite Rbar_mult_comm.
  apply is_Rbar_mult_unique.
  apply is_Rbar_mult_m_infty_neg.
  compute; lra.
  apply Rlt_not_eq; lra.
  compute.
  field_simplify.
  reflexivity.
Qed.

Lemma Derive_opp_Standard_Gaussian_PDF (x:R):
  Derive (fun t => - Standard_Gaussian_PDF t) x = x*Standard_Gaussian_PDF x.
Proof.
  rewrite Derive_opp.
  unfold Standard_Gaussian_PDF.
  rewrite Derive_scal.
  rewrite Derive_comp.
  rewrite <- Derive_Reals with (pr := derivable_pt_exp (-x^2/2)).
  rewrite derive_pt_exp.
  unfold Rdiv at 1.
  rewrite Derive_scal_l.
  rewrite Derive_opp.
  rewrite Derive_pow.
  simpl.
  rewrite Derive_id.
  apply Rminus_diag_uniq.
  field_simplify.
  lra.
  apply sqrt_2PI_nzero.
  apply ex_derive_id.
  solve_derive.
  solve_derive.  
Qed.
  
Lemma ex_derive_opp_Standard_Gaussian_PDF (x:R):
  ex_derive (fun t => - Standard_Gaussian_PDF t) x.
Proof.
  unfold Standard_Gaussian_PDF.
  solve_derive.
Qed.

Lemma continuous_Derive_opp_Standard_Gaussian_PDF (x:R):
  continuous (Derive (fun t => - Standard_Gaussian_PDF t)) x.
Proof.
  apply continuous_ext with (f:=fun t => t*Standard_Gaussian_PDF t).
  symmetry.
  apply Derive_opp_Standard_Gaussian_PDF.
  apply (@continuous_mult R_CompleteNormedModule).
  apply continuous_id.
  apply continuous_Standard_Gaussian_PDF.
Qed.

Lemma mean_standard_gaussian :
  is_RInt_gen (fun t => t*Standard_Gaussian_PDF t) 
           (Rbar_locally m_infty) (Rbar_locally p_infty) 0.
Proof.  
  replace (0) with (0 - 0) by lra.
  apply (is_RInt_gen_ext (Derive (fun t => - Standard_Gaussian_PDF t))).
  apply filter_forall.
  intros; trivial.
  apply Derive_opp_Standard_Gaussian_PDF.
  apply is_RInt_gen_Derive with (f := fun t => - Standard_Gaussian_PDF t) (la := 0) (lb := 0).
  apply filter_forall.  
  intros; trivial.
  apply ex_derive_opp_Standard_Gaussian_PDF.
  apply filter_forall.
  intros; trivial.
  apply continuous_Derive_opp_Standard_Gaussian_PDF.
  replace (filterlim (fun t : R => - Standard_Gaussian_PDF t) (Rbar_locally m_infty) (locally 0)) with (is_lim (fun t : R => - Standard_Gaussian_PDF t) m_infty 0).
  unfold Standard_Gaussian_PDF.
  apply (is_lim_ext (fun t : R => (- / sqrt (2 * PI)) *  exp (- t ^ 2 / 2))).
  intros.
  field_simplify; trivial.
  apply sqrt_2PI_nzero.
  apply sqrt_2PI_nzero. 
  replace (0) with ((- / sqrt (2*PI)) * 0) by lra.  
  apply is_lim_scal_l with (a:=- / sqrt (2 * PI)) (l := 0).
  apply limexp_neg_minf.
  unfold is_lim.
  reflexivity.
  replace (filterlim (fun t : R => - Standard_Gaussian_PDF t) (Rbar_locally p_infty) (locally 0)) with (is_lim (fun t : R => - Standard_Gaussian_PDF t) p_infty 0).
  unfold Standard_Gaussian_PDF.
  apply (is_lim_ext (fun t : R => (- / sqrt (2 * PI)) *  exp (- t ^ 2 / 2))).
  intros.
  field_simplify; trivial.
  apply sqrt_2PI_nzero.
  apply sqrt_2PI_nzero. 
  replace (0) with ((- / sqrt (2*PI)) * 0) by lra.  
  apply is_lim_scal_l with (a:=- / sqrt (2 * PI)) (l := 0).
  apply limexp_neg_inf.
  unfold is_lim.
  reflexivity.
Qed.

Lemma Positive_General_Gaussian_PDF (mu sigma x : R):
  sigma > 0 -> General_Gaussian_PDF mu sigma x > 0.
Proof.  
  intros.
  unfold General_Gaussian_PDF.
  apply Rmult_gt_0_compat.
  apply Rinv_0_lt_compat.
  apply Rmult_gt_0_compat; trivial.
  apply sqrt_lt_R0.
  apply Rmult_gt_0_compat.
  apply Rle_lt_0_plus_1; lra.
  apply PI_RGT_0.
  apply exp_pos.
Qed.

Lemma Derive_General_Gaussian_PDF (mu sigma x:R):
  sigma > 0 -> Derive (General_Gaussian_PDF mu sigma) x = / (sigma^2)*(mu-x)*General_Gaussian_PDF mu sigma x.
Proof.
  intros.
  assert (sigma <> 0).
  now apply Rgt_not_eq.
  unfold General_Gaussian_PDF.
  rewrite Derive_scal.
  rewrite Derive_comp.
  rewrite <- Derive_Reals with (pr := derivable_pt_exp (-(x-mu)^2/(2*sigma^2))).
  rewrite derive_pt_exp.
  unfold Rdiv at 1.
  rewrite Derive_scal_l.
  rewrite Derive_opp.
  rewrite Derive_pow.
  rewrite Derive_minus.
  rewrite Derive_id.
  rewrite Derive_const.
  apply Rminus_diag_uniq.
  simpl.
  field_simplify.
  lra.
  split.
  apply sqrt_2PI_nzero.
  trivial.
  apply ex_derive_id.
  apply ex_derive_const.
  solve_derive.
  solve_derive.
  solve_derive.  
Qed.  

Lemma ex_derive_General_Gaussian_PDF (mu sigma:R) (x:R):
  sigma > 0 -> ex_derive (General_Gaussian_PDF mu sigma) x.
Proof.
  intros.
  unfold General_Gaussian_PDF.
  solve_derive.
Qed.

Lemma continuous_General_Gaussian_PDF (mu sigma : R) :
  forall (x:R), continuous (General_Gaussian_PDF mu sigma) x.
Proof.
  intros.
  unfold General_Gaussian_PDF.
  apply continuous_mult with (f:= fun t => / (sigma * sqrt (2*PI))).
  apply continuous_const.
  apply continuous_comp with (g := exp).
  unfold Rdiv.
  apply continuous_mult with (f := fun t => -(t-mu)^2) (g := fun t => /(2*sigma^2)).
  apply continuous_opp with (f := fun t =>  (t-mu)^2).
  apply continuous_mult with (f := fun t => t - mu).
  apply continuous_minus with (f := id).
  apply continuous_id.
  apply continuous_const.
  apply continuous_mult with (f := fun t => t-mu).
  apply continuous_minus with (f := id).
  apply continuous_id.
  apply continuous_const.
  apply continuous_const.
  apply continuous_const.    
  apply ex_derive_continuous with (f := exp) (x0 := -(x-mu)^2/(2*sigma^2)).
  apply ex_derive_Reals_1.
  unfold derivable_pt.
  unfold derivable_pt_abs.
  exists (exp (- (x-mu) ^ 2 / (2*sigma^2))).
  apply derivable_pt_lim_exp.
Qed.

Lemma continuous_Derive_General_Gaussian_PDF (mu sigma x:R):
  sigma > 0 -> continuous (Derive (General_Gaussian_PDF mu sigma)) x.
Proof.
  intros.
  apply (continuous_ext (fun x => / (sigma^2)*((mu-x)*General_Gaussian_PDF mu sigma x))).
  intros.
  rewrite Derive_General_Gaussian_PDF.
  now rewrite Rmult_assoc.
  trivial.
  apply continuous_scal_r with (k := / sigma^2) (f := fun x => (mu-x)*General_Gaussian_PDF mu sigma x).
  apply continuous_mult with (f := fun t => mu-t).
  apply continuous_minus with (f := fun t => mu).
  apply continuous_const.
  apply continuous_id.
  apply continuous_General_Gaussian_PDF.
Qed.

Lemma General_Gaussian_PDF_normed (mu sigma:R) : 
  sigma>0 ->
  ex_RInt_gen Standard_Gaussian_PDF (Rbar_locally' m_infty) (at_point (- mu / sigma)) ->
  ex_RInt_gen Standard_Gaussian_PDF (at_point (- mu / sigma)) (Rbar_locally' p_infty) ->
  is_RInt_gen (General_Gaussian_PDF mu sigma) (Rbar_locally' m_infty) (Rbar_locally' p_infty) 1.
Proof.
  intros.
  assert (Rbar_plus (Rbar_mult (/ sigma) m_infty) (- mu / sigma) = m_infty).
  rewrite Rbar_mult_comm.
  rewrite Rbar_mult_m_infty_pos.
  now compute.
  apply Rinv_0_lt_compat; lra.  
  assert (Rbar_plus (Rbar_mult (/ sigma) p_infty) (- mu / sigma) = p_infty).
  rewrite Rbar_mult_comm.
  rewrite Rbar_mult_p_infty_pos.
  now compute.
  apply Rinv_0_lt_compat; lra.  
  
  apply (is_RInt_gen_ext (fun x =>  / sigma * Standard_Gaussian_PDF (/sigma *x + (-mu/sigma)))).
  apply filter_forall.
  intros.
  rewrite gen_from_std.
  apply Rmult_eq_compat_l.
  apply f_equal; lra.
  trivial.
  apply is_RInt_gen_comp_lin with (u := /sigma) (v := -mu/sigma) 
                                  (f:=Standard_Gaussian_PDF).
  apply Rinv_neq_0_compat.
  now apply Rgt_not_eq.
  replace (Rbar_locally' (Rbar_plus (Rbar_mult (/ sigma) m_infty) (- mu / sigma))) with
          (Rbar_locally' m_infty).
  replace (at_point (/ sigma * 0 + - mu / sigma)) with (at_point (-mu/sigma)).
  trivial.
  apply f_equal; lra.
  now apply f_equal; symmetry.
  replace (at_point (/ sigma * 0 + - mu / sigma)) with (at_point (-mu/sigma)).  
  replace (Rbar_locally' (Rbar_plus (Rbar_mult (/ sigma) p_infty) (- mu / sigma))) with
          (Rbar_locally' p_infty).
  trivial.
  apply f_equal; now symmetry.
  apply f_equal; lra.
  apply ex_RInt_Standard_Gaussian_PDF.
  replace (Rbar_locally' (Rbar_plus (Rbar_mult (/ sigma) m_infty) (- mu / sigma))) with
          (Rbar_locally' m_infty).
  replace (Rbar_locally' (Rbar_plus (Rbar_mult (/ sigma) p_infty) (- mu / sigma))) with
          (Rbar_locally' p_infty).
  apply Standard_Gaussian_PDF_normed.
  rewrite Rbar_mult_comm.
  rewrite Rbar_mult_p_infty_pos.
  now compute.
  apply Rinv_0_lt_compat; lra.  
  rewrite Rbar_mult_comm.
  rewrite Rbar_mult_m_infty_pos.
  now compute.
  apply Rinv_0_lt_compat; lra.  
Qed.  

Lemma mean_general_gaussian (mu sigma:R) :
  sigma > 0 ->
    ex_RInt_gen Standard_Gaussian_PDF (Rbar_locally' m_infty) (at_point (- mu / sigma)) ->
    ex_RInt_gen Standard_Gaussian_PDF (at_point (- mu / sigma)) (Rbar_locally' p_infty) ->

    is_RInt_gen (fun t => t*General_Gaussian_PDF mu sigma t) 
                           (Rbar_locally' m_infty) (Rbar_locally' p_infty) mu.
Proof.
  intros.
  assert (sigma <> 0).
  now apply Rgt_not_eq.
  apply (is_RInt_gen_ext (fun t => mu*General_Gaussian_PDF mu sigma t - (mu-t)*General_Gaussian_PDF mu sigma t)). 
  apply filter_forall.
  intros.
  apply Rminus_diag_uniq; lra.
  replace (mu) with (mu*1 - 0) at 1.
  apply (@is_RInt_gen_minus R_CompleteNormedModule).
  apply Rbar_locally'_filter.
  apply Rbar_locally'_filter.  
  apply (@is_RInt_gen_scal R_CompleteNormedModule).  
  apply Rbar_locally'_filter.
  apply Rbar_locally'_filter.  
  apply General_Gaussian_PDF_normed.
  trivial.
  trivial.
  trivial.
  apply (is_RInt_gen_ext (fun t => sigma^2 * Derive (General_Gaussian_PDF mu sigma) t)).
  apply filter_forall.
  intros.
  rewrite Derive_General_Gaussian_PDF.
  apply Rminus_diag_uniq.
  field_simplify; lra.
  trivial.
  replace (0) with (sigma^2 * 0).
  apply (@is_RInt_gen_scal R_CompleteNormedModule).
  apply Rbar_locally'_filter.
  apply Rbar_locally'_filter.    
  replace (0) with (0 - 0).
  apply is_RInt_gen_Derive.
  apply filter_forall.
  intros.
  apply ex_derive_General_Gaussian_PDF.
  trivial.
  apply filter_forall.
  intros.
  apply continuous_Derive_General_Gaussian_PDF.
  unfold General_Gaussian_PDF.
  trivial.
  replace (0) with ( / (sigma * sqrt (2*PI)) * 0) by lra.  
  apply is_lim_scal_l with (a:= / (sigma * sqrt (2 * PI))) (l := 0).
  apply (is_lim_ext (fun t => exp(-((/sigma * t)+ (-mu/sigma))^2/2))).
  intros.
  apply f_equal.
  now field_simplify.
  apply is_lim_comp_lin with (f := fun t => exp(-t^2/2)) (a := /sigma) (b:= -mu/sigma).
  replace (Rbar_plus (Rbar_mult (/ sigma) m_infty) (- mu / sigma)) with (m_infty).
  apply limexp_neg_minf.
  rewrite Rbar_mult_comm.
  rewrite Rbar_mult_m_infty_pos.
  now compute.
  apply Rinv_0_lt_compat; lra.
  apply Rinv_neq_0_compat; trivial.
  unfold General_Gaussian_PDF.
  replace (0) with ( / (sigma * sqrt (2*PI)) * 0) by lra.  
  apply is_lim_scal_l with (a:= / (sigma * sqrt (2 * PI))) (l := 0).
  apply (is_lim_ext (fun t => exp(-((/sigma * t)+ (-mu/sigma))^2/2))).
  intros.
  apply f_equal.
  now field_simplify.
  apply is_lim_comp_lin with (f := fun t => exp(-t^2/2)) (a := /sigma) (b:= -mu/sigma).
  replace (Rbar_plus (Rbar_mult (/ sigma) p_infty) (- mu / sigma)) with (p_infty).  
  apply limexp_neg_inf.
  rewrite Rbar_mult_comm.
  rewrite Rbar_mult_p_infty_pos.
  compute; trivial.
  apply Rinv_0_lt_compat; lra.
  now apply Rinv_neq_0_compat.
  lra.
  lra.
  lra.
Qed.
  
Lemma variance_general_gaussian (mu sigma : R) :
  sigma > 0 ->
  ex_RInt_gen (fun t : R => sigma ^ 2 * t ^ 2 * Standard_Gaussian_PDF t)
              (Rbar_locally' m_infty) (at_point (- mu / sigma)) ->
  ex_RInt_gen (fun t : R => sigma ^ 2 * t ^ 2 * Standard_Gaussian_PDF t)
              (at_point (- mu / sigma)) (Rbar_locally' p_infty) ->
  is_RInt_gen (fun t => (t-mu)^2*General_Gaussian_PDF mu sigma t) 
              (Rbar_locally' m_infty) (Rbar_locally' p_infty) (sigma^2).
Proof.
  intros.
  assert (sigma <> 0).
  now apply Rgt_not_eq.
  assert (Rbar_plus (Rbar_mult (/ sigma) m_infty) (- mu / sigma) = m_infty).
  rewrite Rbar_mult_comm.
  rewrite Rbar_mult_m_infty_pos.
  now compute.
  apply Rinv_0_lt_compat; lra.  
  assert (Rbar_plus (Rbar_mult (/ sigma) p_infty) (- mu / sigma) = p_infty).
  rewrite Rbar_mult_comm.
  rewrite Rbar_mult_p_infty_pos.
  now compute.
  apply Rinv_0_lt_compat; lra.  
  apply (is_RInt_gen_ext (fun t => /sigma * (sigma^2 * (/sigma * t + (-mu/sigma))^2 * Standard_Gaussian_PDF(/sigma*t + (-mu/sigma))))).
  apply filter_forall.
  intros.
  rewrite gen_from_std.
  replace (/sigma * x0 + - mu/sigma) with ((x0-mu)/sigma).
  apply Rminus_diag_uniq.
  field_simplify; lra.
  lra.
  trivial.
  apply is_RInt_gen_comp_lin with (u := /sigma) (v := -mu/sigma) 
                                  (f:=fun t => sigma^2 * t^2 * Standard_Gaussian_PDF t).
  apply Rinv_neq_0_compat; trivial.
  replace (Rbar_locally' (Rbar_plus (Rbar_mult (/ sigma) m_infty) (- mu / sigma))) with
          (Rbar_locally' m_infty).
  replace (at_point (/ sigma * 0 + - mu / sigma)) with (at_point (-mu/sigma)).
  trivial.
  apply f_equal; lra.
  apply f_equal; now symmetry.
  replace (at_point (/ sigma * 0 + - mu / sigma)) with (at_point (-mu/sigma)).
  replace (Rbar_locally' (Rbar_plus (Rbar_mult (/ sigma) p_infty) (- mu / sigma))) with
          (Rbar_locally' p_infty).
  trivial.
  apply f_equal; now symmetry.
  apply f_equal; lra.  
  intros.
  apply (ex_RInt_ext (fun t => sigma^2 * (t^2 * Standard_Gaussian_PDF t))).
  intros.
  lra.
  apply (@ex_RInt_scal R_CompleteNormedModule) with (k := sigma^2) (f := fun t => t^2 * Standard_Gaussian_PDF t).
  apply ex_RInt_Standard_Gaussian_variance_PDF.
  replace (sigma^2) with (sigma^2 * 1) at 1.
  apply (is_RInt_gen_ext (fun t=>sigma^2 * (t^2 * Standard_Gaussian_PDF t))).
  apply filter_forall.
  intros.
  lra.
  apply (@is_RInt_gen_scal R_CompleteNormedModule).
  apply Rbar_locally'_filter.
  apply Rbar_locally'_filter.      
  replace (Rbar_locally' (Rbar_plus (Rbar_mult (/ sigma) m_infty) (- mu / sigma))) with 
      (Rbar_locally' m_infty).
  replace (Rbar_locally' (Rbar_plus (Rbar_mult (/ sigma) p_infty) (- mu / sigma))) with 
      (Rbar_locally' p_infty).
  apply variance_standard_gaussian.
  apply f_equal.
  rewrite Rbar_mult_comm.
  rewrite Rbar_mult_p_infty_pos.
  now compute.
  apply Rinv_0_lt_compat; lra.  
  rewrite Rbar_mult_comm.
  rewrite Rbar_mult_m_infty_pos.
  now compute.
  apply Rinv_0_lt_compat; lra.  
  lra.
Qed.

Definition Indicator (a b t:R) :=
  (if Rlt_dec t a then 0 else 
     (if Rgt_dec t b then 0 else 1)).

Definition Uniform_PDF (a b t:R) := 
  (/ (b-a)) * Indicator a b t.

Lemma Uniform_normed0 (a b:R) :
  a < b -> is_RInt (fun t => (/ (b-a))) a b 1.
Proof.  
  intros.
  replace (1) with (scal (b-a) (/ (b-a))).
  apply (@is_RInt_const R_CompleteNormedModule).
  compute; field_simplify; lra.
Qed.

Lemma Indicator_left (a b:R) (f : R -> R) :
  a < b -> is_RInt_gen (fun t => (f t) * (Indicator a b t)) (Rbar_locally' m_infty) (at_point a) 0.
Proof.  
  - intros.
    unfold Indicator.
    apply (is_RInt_gen_ext (fun _ =>  0)).
    + exists (fun y => y<a) (fun x => x=a).
      unfold Rbar_locally'.
      exists (a).
      intros.
      trivial.
      unfold at_point.
      reflexivity.
      intros x y H0 H1.
      replace (fst (x, y)) with (x) by trivial.
      replace (snd (x, y)) with (y) by trivial.
      replace (y) with (a).
      rewrite Rmin_left.
      rewrite Rmax_right.
      intros.
      replace (is_left (Rlt_dec x0 a)) with true.
      lra.
      destruct (Rlt_dec x0 a); trivial.
      intuition.
      lra.
      lra.
    + apply (is_RInt_gen_ext (Derive (fun _ => 0))).
      * apply filter_forall.
        intros.
        apply Derive_const.
      * replace (0) with (0 - 0) at 1.
        apply is_RInt_gen_Derive with (f0 := fun _ => 0) (la := 0) (lb := 0).
        ++ apply filter_forall.
           intros.
           apply ex_derive_const.
        ++ apply filter_forall.
           intros.
           apply continuous_const.
        ++ apply filterlim_const.
        ++ apply filterlim_const.
        ++ lra.
Qed.

Lemma Indicator_right (a b:R) (f : R -> R) :
  a < b -> is_RInt_gen (fun t => (f t) * (Indicator a b t)) (at_point b) (Rbar_locally' p_infty)  0.
Proof.  
  - intros.
    unfold Indicator.
    apply (is_RInt_gen_ext (fun _ =>  0)).
    + exists (fun x => x=b) (fun y => b<y).
      unfold at_point.
      reflexivity.
      unfold Rbar_locally'.
      exists (b).
      intros; trivial.
      intros x y H0 H1.
      replace (fst (x, y)) with (x) by trivial.
      replace (snd (x, y)) with (y) by trivial.
      replace (x) with (b).
      rewrite Rmin_left.
      rewrite Rmax_right.
      intros.
      replace (is_left (Rlt_dec x0 a)) with false.
      replace (is_left (Rgt_dec x0 b)) with true.
      lra.
      destruct (Rgt_dec x0 b).
      intuition.
      intuition.
      destruct (Rlt_dec x0 a).
      lra.
      intuition.
      lra.
      lra.
    + apply (is_RInt_gen_ext (Derive (fun _ => 0))).
      apply filter_forall.
      intros.
      apply Derive_const.
      replace (0) with (0 - 0) at 1.
      apply is_RInt_gen_Derive with (f0 := fun _ => 0) (la := 0) (lb := 0).
      * apply filter_forall.
        intros.
        apply ex_derive_const.
      * apply filter_forall.
        intros.
        apply continuous_const.
      * apply filterlim_const.
      * apply filterlim_const.
      * lra.
Qed.

Lemma Indicator_full (a b:R) (f : R -> R) (l:R):
  a < b -> is_RInt f a b l -> is_RInt_gen (fun t => (f t) * (Indicator a b t)) (Rbar_locally' m_infty) (Rbar_locally' p_infty) l.
Proof.
  - intros.
    replace (l) with (0 + l).
    apply (@is_RInt_gen_Chasles R_CompleteNormedModule) with (b:=a).
    + apply Rbar_locally'_filter.
    + apply Rbar_locally'_filter.    
    + apply (is_RInt_gen_ext (fun t => (f t) * (Indicator a b t))).
      * apply filter_forall.
        intros.
        apply Rmult_eq_compat_l; trivial.
      * now apply Indicator_left with (f := f).
    + replace (l) with (l + 0).
      apply (@is_RInt_gen_Chasles R_CompleteNormedModule) with (b:=b).
      * apply at_point_filter.
      * apply Rbar_locally'_filter.  
      * apply is_RInt_gen_at_point.
        apply (is_RInt_ext f).
        rewrite Rmin_left.
        rewrite Rmax_right.
        intros.
        ++ unfold Indicator.
           replace (is_left (Rlt_dec x a)) with false.
           replace (is_left (Rgt_dec x b)) with false.
           lra.
           destruct (Rgt_dec x b).
           lra.
           tauto.
           destruct (Rlt_dec x a).
           lra.
           tauto.
        ++ lra.
        ++ lra.
        ++ trivial.
      * now apply Indicator_right.
      * lra.
    + lra.
Qed.

Lemma Uniform_full (a b:R) (f : R -> R) (l:R):
  a < b -> is_RInt (fun t => (f t)*(/ (b-a))) a b l -> is_RInt_gen (fun t => (f t) * (Uniform_PDF a b t)) (Rbar_locally' m_infty) (Rbar_locally' p_infty) l.
Proof.
  intros.
  apply (is_RInt_gen_ext (fun t => (f t) * (/ (b-a)) * Indicator a b t)).
  apply filter_forall.
  intros.
  unfold Uniform_PDF.
  now ring_simplify.
  now apply Indicator_full with (f := fun t => f t * (/ (b - a))).
Qed.

Lemma Uniform_PDF_non_neg (a b t :R) :
  a < b -> Uniform_PDF a b t >= 0.
Proof.  
  intros.
  unfold Uniform_PDF.
  replace (0) with ((/ (b-a)) * 0) by lra.
  apply Rmult_ge_compat_l with (r2 := 0).
  left.
  apply Rinv_0_lt_compat; lra.
  unfold Indicator.
  destruct (is_left (Rlt_dec t a)).
  lra.
  destruct (is_left (Rgt_dec t b)).
  lra.
  lra.
Qed.

Lemma Uniform_normed (a b:R) :
  a < b -> is_RInt_gen (Uniform_PDF a b) (Rbar_locally' m_infty) (Rbar_locally' p_infty) 1.
Proof.
  intros.
  apply (is_RInt_gen_ext (fun t => 1 * (Uniform_PDF a b t))).
  apply filter_forall.
  intros.
  lra.
  apply Uniform_full with (f := fun _ => 1) (l := 1).
  trivial.
  apply (is_RInt_ext (fun t => (/ (b-a)))).
  intros.
  now ring_simplify.
  now apply Uniform_normed0.
Qed.

Lemma Uniform_mean0 (a b:R) :
  a < b -> is_RInt (fun t => t*(/ (b-a))) a b ((b+a)/2).
Proof.  
  - intros.
    replace ((b+a)/2) with  (/(b-a)*(b^2/2) - (/(b-a)*(a^2/2))).
    + apply (@is_RInt_derive R_CompleteNormedModule) with (f := fun t => (/(b-a))*(t^2/2)).
      rewrite Rmin_left.
      rewrite Rmax_right.
      intros.
      replace (x * (/ (b-a))) with (/(b-a) * x).
      apply is_derive_scal with (k := /(b-a)) (f:= (fun t => t^2/2)).
      apply (is_derive_ext (fun t => t * ((/2) * t))).
      intros.
      now field_simplify.
      replace (x) with (1 * (/2 * x) + x * /2) at 2.
      apply (@is_derive_mult R_AbsRing) with (f := id) (g:= fun t => (/2) * t).
      apply (@is_derive_id R_AbsRing).
      replace (/2) with (/2 * 1) at 1.
      apply is_derive_scal.
      apply (@is_derive_id R_AbsRing).
      lra.
      intros.
      apply Rmult_comm.
      ring_simplify; lra.
      apply Rmult_comm.  
      lra.
      lra.
      intros.
      apply (@continuous_scal_l R_CompleteNormedModule) with (f := id).
      apply continuous_id.
    + apply Rminus_diag_uniq; field_simplify; lra.
Qed.

Lemma Uniform_mean (a b:R) :
  a < b -> is_RInt_gen (fun t => t*(Uniform_PDF a b t)) (Rbar_locally' m_infty) (Rbar_locally' p_infty) ((b+a)/2).
Proof.
  intros.
  apply Uniform_full with (f := fun t => t); trivial.
  now apply Uniform_mean0.
Qed.

Lemma Uniform_variance0 (a b:R) :
  a < b -> is_RInt (fun t => (/ (b-a)) * (t-(b+a)/2)^2) a b ((b-a)^2/12).
Proof.
  - intros.
    replace ((b-a)^2/12) with (scal (/(b-a)) ((b-a)^3/12)).
    + apply (@is_RInt_scal  R_CompleteNormedModule) with (k := /(b-a)) (f := fun t => (t - (b+a)/2)^2) (If := (b-a)^3/12).
      apply (is_RInt_ext (fun t => t^2 - (b+a)*t + (b+a)^2/4)).
      * intros.
        now field_simplify.
      * replace ((b-a)^3/12) with ((a-b)*(b^2+4*a*b+a^2)/6 + ((b+a)^2/4)*(b-a)).
        apply is_RInt_plus with (f:= fun t=> t^2 - (b+a)*t) (g := fun t=> (b+a)^2/4).
        -- replace ((a - b) * (b ^ 2 + 4 * a * b + a ^ 2) / 6) with ((b^3/3-a^3/3) - (b-a)*(b+a)^2/2).
           apply is_RInt_minus with (f := fun t => t^2) (g := fun t => (b+a)*t).
           apply (@is_RInt_derive R_CompleteNormedModule) with (f := fun t => t^3/3).
           ++ intros.
              apply (is_derive_ext (fun t => (/3) * t^3)).
              intros; now field_simplify.
              replace (x^2) with (/3 * (INR(3%nat) * 1 * x^2)).
              apply is_derive_scal.
              apply is_derive_pow with (f:=id) (n := 3%nat) (l:=1).
              apply (@is_derive_id R_AbsRing).
              simpl; now field_simplify.
           ++ rewrite Rmax_right.
              rewrite Rmin_left.
              intros.
              simpl.
              apply continuous_mult with (f := id).
              apply continuous_id.
              apply (@continuous_scal_l R_UniformSpace) with (f := id ) (k := 1).
              apply continuous_id.
              lra.
              lra.
           ++ replace ((b - a) * (b + a) ^ 2 / 2) with ((b+a)*((b^2/2-a^2/2))).
              apply (@is_RInt_scal  R_CompleteNormedModule) with (k := b+a).
              apply is_RInt_derive with (f:=fun x => x^2/2).
              rewrite Rmax_right; try lra.
              rewrite Rmin_left; try lra.
              ** intros.
                 apply (is_derive_ext (fun t => (/2) * t^2)).
                 intros.
                 now field_simplify.
                 replace (x) with (/2 * (2 * x)) at 2 by lra.
                 apply is_derive_scal.
                 replace (2 * x) with (INR(2%nat) * 1 * x^1) by
                 (simpl; field_simplify; lra).
                 apply is_derive_pow with (f:=id) (n := 2%nat) (l:=1).
                 apply (@is_derive_id R_AbsRing).
              ** rewrite Rmax_right; try lra.
                 rewrite Rmin_left; try lra.
                 intros.
                 apply continuous_id.
              ** now field_simplify.
           ++ apply Rminus_diag_uniq.
              compute.
              field_simplify; lra.
        -- replace ((b + a) ^ 2 / 4 * (b - a)) with (scal (b-a) ((b+a)^2/4)).
           apply (@is_RInt_const R_NormedModule).
           compute.
           now field_simplify.
        -- apply Rminus_diag_uniq.
           field_simplify; lra.
    + compute.
      field_simplify; lra.
Qed.

Lemma Uniform_variance (a b:R) :
  a < b -> is_RInt_gen (fun t => (t-(b+a)/2)^2*(Uniform_PDF a b t)) (Rbar_locally' m_infty) (Rbar_locally' p_infty) ((b-a)^2/12).
Proof.
  intros.
  apply Uniform_full with (f := (fun t => (t-(b+a)/2)^2)); trivial.
  apply (is_RInt_ext (fun t => (/ (b-a)) * (t-(b+a)/2)^2)).
  intros.
  now ring_simplify.
  now apply Uniform_variance0.
Qed.

Axiom Fubini:
  forall (a b c d: R) (f: R -> R -> R) (x y: R), 
    a < x < b -> c < y < d -> 
    continuity_2d_pt f x y -> 
    RInt (fun u => RInt (fun v => f u v) a b) c d =  RInt (fun v => RInt (fun u => f u v) c d) a b.

(* the iterated integrals below are equal in the sense either they are both infinite, or they are both finite with the same value *)

Axiom Fubini_gen :
  forall (Fa Fb Fc Fd: (R -> Prop) -> Prop)
         (f: R -> R -> R) ,
 filter_prod Fa Fb
             (fun ab => forall (x : R), Rmin (fst ab) (snd ab) <= x <= Rmax (fst ab) (snd ab) ->
                                filter_prod Fc Fd
                                            (fun bc => forall (y : R), Rmin (fst bc) (snd bc) <= y <= Rmax (fst bc) (snd bc) -> continuity_2d_pt f x y)) ->    
 filter_prod Fa Fb
             (fun ab => forall (x : R), Rmin (fst ab) (snd ab) <= x <= Rmax (fst ab) (snd ab) ->
                                filter_prod Fc Fd
                                            (fun bc => forall (y : R), Rmin (fst bc) (snd bc) <= y <= Rmax (fst bc) (snd bc) -> f x y >= 0)) ->    
  RInt_gen (fun u => RInt_gen (fun v => f u v) Fa Fb) Fc Fd =  RInt_gen (fun v => RInt_gen (fun u => f u v) Fc Fd) Fa Fb.

Lemma sqr_plus1_gt (x:R):
  x^2 + 1 > 0.
Proof.
  intros.
  apply Rplus_le_lt_0_compat.
  apply pow2_ge_0.
  lra.
Qed.  

Lemma sqr_plus1_neq (x:R):
  x^2 + 1 <> 0.
Proof.
  apply Rgt_not_eq.  
  apply sqr_plus1_gt.
Qed.

Lemma deriv_erf00 (x0 x2:R) :
  Derive (fun u : R => - / (2 * x0 ^ 2 + 2) * exp (- (u ^ 2 + (u * x0) ^ 2))) x2 =
    x2 * exp (- (x2 ^ 2 + (x2 * x0) ^ 2)). 
Proof.
  rewrite Derive_scal; solve_derive.
  rewrite Derive_comp; solve_derive.
  rewrite Derive_opp; solve_derive.
  rewrite Derive_plus; solve_derive.
  rewrite Derive_pow; solve_derive.
  rewrite Derive_id; solve_derive.
  rewrite Derive_pow; solve_derive.
  rewrite Derive_mult; solve_derive.
  rewrite Derive_id.
  rewrite Derive_const.
  rewrite <- Derive_Reals with (pr := derivable_pt_exp (- (x2 ^ 2 + (x2 * x0) ^ 2))).
  rewrite derive_pt_exp.
  simpl.
  apply Rminus_diag_uniq.
  field_simplify; try lra.
  replace (2*(x0 * x0) + 2) with (2*(x0^2 + 1)) by lra.
  apply Rmult_integral_contrapositive_currified.
  lra.
  apply sqr_plus1_neq.
Qed.

Lemma atan_tan_inv (x:R) :
  -PI/2 < x < PI/2 -> atan (tan x) = x.
Proof.
  intros.
  unfold atan.
  destruct (pre_atan (tan x)) as [y [yrang yinv]].
  now apply tan_is_inj in yinv.
Qed.

Lemma lim_atan_inf:
  is_lim atan p_infty (PI/2).
Proof.
  apply is_lim_spec.
  unfold is_lim'.
  intros.
  assert(atan_upper:forall x, atan x < PI/2)
    by apply atan_bound.
  unfold Rbar_locally'.
  destruct (Rlt_dec (PI/2-eps) 0).
  - exists (0).
    intros.
    rewrite Rabs_left.
    + assert (atan 0 < atan x)
             by now apply atan_increasing.
      rewrite atan_0 in H0; try lra.
    + now apply Rlt_minus.
  - exists (tan (PI/2 - eps)).
    assert (eps > 0)
      by now destruct eps.
    intros.
    rewrite Rabs_left; try lra.
    + assert (atan (tan (PI/2 - eps)) < atan x)
       by now apply atan_increasing.
      rewrite atan_tan_inv in H1; try lra.
    + now apply Rlt_minus.
Qed.
                                          
Lemma erf_atan:
  is_RInt_gen (fun s : R => / (2 * s ^ 2 + 2)) (at_point 0) 
              (Rbar_locally' p_infty) (PI / 4).
Proof.
    + apply (is_RInt_gen_ext (Derive (fun s => /2 * atan s))).
      * apply filter_forall.
        intros.
        replace (/ (2 * x0^2 + 2)) with ( (/2) * (/ (x0^2+1))).
        rewrite Derive_scal.
        apply Rmult_eq_compat_l.
        rewrite <- Derive_Reals with (pr := derivable_pt_atan x0).
        rewrite derive_pt_atan.
        unfold Rsqr.
        field_simplify; trivial.
        apply sqr_plus1_neq.
        replace (x0 * x0) with (x0^2) by lra.
        rewrite Rplus_comm; trivial.
        apply sqr_plus1_neq.
        replace (2*x0^2 + 2) with (2*(x0^2+1)) by lra.
        rewrite Rinv_mult_distr; trivial.
        apply sqr_plus1_neq.        
      * replace (PI/4) with (PI/4 - 0).
        apply is_RInt_gen_Derive.
        - apply filter_forall.
           intros.
           apply ex_derive_scal.
           apply ex_derive_Reals_1.
           apply derivable_pt_atan.
        - apply filter_forall.
           intros.
           apply (continuous_ext (fun s => /2 * /(s^2+1))).
           intros.
           symmetry.
           replace (/ (x1^2+1)) with (Derive atan x1).
           apply Derive_scal with (f := atan ) (k := /2) (x := x1).
           rewrite <- Derive_Reals with (pr := derivable_pt_atan x1).
           rewrite derive_pt_atan.
           unfold Rsqr.
           replace (1 + x1*x1) with (x1^2 + 1) by lra; lra.
           apply continuous_scal_r with (k := /2) (f := fun s => /(s^2+1)).
           apply continuous_comp.
           apply continuous_plus with (f := fun x1 => x1^2) (g := fun _ => 1); simpl.
           apply continuous_mult with (f := id).
           apply continuous_id.
           apply continuous_mult with (f := id).
           apply continuous_id.
           apply continuous_const.
           apply continuous_const.
           unfold continuous.
           apply continuity_pt_filterlim.
           apply continuity_pt_inv.
           apply continuity_pt_id.
           apply sqr_plus1_neq.
        - unfold filterlim.
          unfold filter_le.
          intros.
          unfold filtermap.
          unfold at_point.
          replace (/2 * atan 0) with (0).
          now apply locally_singleton.
          rewrite atan_0.
          lra.
        - replace (filterlim (fun s : R => / 2 * atan s) (Rbar_locally' p_infty) (locally (PI / 4))) with (is_lim (fun s : R => / 2 * atan s) p_infty (Rbar_mult (/2) (PI/2))).
           apply is_lim_scal_l with (a := /2) (f := atan).
           apply lim_atan_inf.
           unfold is_lim.
           replace (Rbar_locally (Rbar_mult (/2) (PI/2))) with (Rbar_locally (PI/4)).
           trivial.
           f_equal.
           unfold Rbar_mult.
           unfold Rbar_mult'.
           rewrite Rmult_comm.
           unfold Rdiv.
           rewrite Rmult_assoc.
           replace (/2 * /2) with (/4); try lra.
           easy.
        - apply Rminus_0_r.
Qed.

Lemma erf_exp0 (x0:R) :
   is_RInt_gen (fun u : R => u * exp (- (u ^ 2 + (u * x0) ^ 2))) 
               (at_point 0) (Rbar_locally' p_infty) (/ (2 * x0 ^ 2 + 2)).
Proof.
      replace (/ (2*x0^2+2)) with (0 - (- / (2*x0^2+2))).
      * apply (is_RInt_gen_ext (Derive (fun u => -/(2*x0^2+2) * exp(-(u^2+(u*x0)^2))))).
        -- apply filter_forall.
           intros.
           apply deriv_erf00.
        -- apply is_RInt_gen_Derive with (f := fun u => -/(2*x0^2+2)* exp(-(u^2+(u*x0)^2))) (lb:=0) (la := - / (2*x0^2+2)).
           ++ apply filter_forall.
              intros.
              solve_derive.
           ++ apply filter_forall.
              intros.
              apply (continuous_ext (fun x2 => x2 * exp (- (x2 ^ 2 + (x2 * x0) ^ 2)))).
              ** intros.
                 symmetry.
                 apply deriv_erf00.
              ** apply continuous_mult with (f := id).
                 apply continuous_id.
                 apply continuous_comp with (g := exp).
                 apply continuous_opp with (f := fun x3 => (x3 ^ 2 + (x3 * x0) ^ 2)).
                 apply continuous_plus with (f := fun x3 => x3^2); simpl.
                 apply continuous_mult with (f := id).
                 apply continuous_id.
                 apply continuous_mult with (f := id).
                 apply continuous_id.
                 apply continuous_const; simpl.
                 apply continuous_mult with (f := fun x => x * x0).
                 apply continuous_mult with (f := id).
                 apply continuous_id.
                 apply continuous_const.
                 apply continuous_mult with (f := fun x => x * x0).
                 apply continuous_mult with (f := id).
                 apply continuous_id.
                 apply continuous_const.
                 apply continuous_const.    
                 apply ex_derive_continuous with (f := exp).
                 apply ex_derive_Reals_1.
                 apply derivable_pt_exp.
           ++ unfold filterlim.
              unfold filter_le.
              intros.
              unfold filtermap.
              unfold at_point.
              replace (- / (2 * x0 ^ 2 + 2) * exp (- (0 ^ 2 + (0 * x0) ^ 2))) with (- / (2 * x0 ^ 2 + 2)).
              now apply locally_singleton.
              replace (- (0 ^ 2 + (0 * x0) ^ 2)) with (0) by lra.
              rewrite exp_0.
              lra.
           ++ replace (filterlim (fun u : R => - / (2 * x0 ^ 2 + 2) * exp (- (u ^ 2 + (u * x0) ^ 2)))
                                 (Rbar_locally' p_infty) (locally 0)) with 
                  (is_lim (fun u : R => - / (2 * x0 ^ 2 + 2) * exp (- (u ^ 2 + (u * x0) ^ 2))) p_infty 0).
              ** replace  (Finite 0) with (Rbar_mult  (- / (2 * x0 ^ 2 + 2)) 0).
                 apply is_lim_scal_l with (a := - / (2 * x0 ^ 2 + 2) ).
                 apply is_lim_comp with (l:=m_infty).
                 apply is_lim_exp_m.
                 replace (m_infty) with (Rbar_opp p_infty).
                 apply is_lim_opp.
                 apply (is_lim_ext (fun y => y * y * (1 + Rsqr x0))).
                 intros.
                 unfold Rsqr.
                 now ring_simplify.
                 replace (p_infty) with (Rbar_mult (Rbar_mult p_infty p_infty) (1 + Rsqr x0)) at 2.
                 apply is_lim_mult.
                 apply is_lim_mult.
                 apply is_lim_id.
                 apply is_lim_id.
                 now compute.
                 apply is_lim_const.
                 compute.
                 replace (x0 * x0) with (x0^2) by lra.
                 rewrite Rplus_comm.
                 apply sqr_plus1_neq.
                 replace (Rbar_mult p_infty p_infty) with (p_infty).
                 apply is_Rbar_mult_unique.
                 apply is_Rbar_mult_p_infty_pos.                 
                 compute.
                 replace (x0 * x0) with (x0^2) by lra.
                 apply Rgt_lt.
                 rewrite Rplus_comm.
                 apply sqr_plus1_gt.
                 now compute.
                 now compute.
                 unfold Rbar_locally'.
                 exists x0.
                 intros.
                 discriminate.
                 unfold Rbar_mult.
                 unfold Rbar_mult'.
                 now rewrite Rmult_0_r.
              ** now unfold is_lim.
      * now ring_simplify.
Qed.

Lemma erf_int00 : 
  is_RInt_gen (fun s => RInt_gen (fun u => u*exp(-(u^2+(u*s)^2))) (at_point 0)  (Rbar_locally' p_infty)) (at_point 0) (Rbar_locally' p_infty) (PI / 4).
Proof.
  - apply (is_RInt_gen_ext (fun s => / (2*s^2+2))).
    apply filter_forall.
    + intros.
      symmetry.
      apply is_RInt_gen_unique.
      apply erf_exp0.
    + apply erf_atan.
Qed.

Lemma erf_ex_RInt0 (x0:R):
  ex_RInt_gen
   (fun v : R =>
    (if  (Rlt_dec v 1) then 1 else v * exp (- v ^ 2)) * exp (- x0 ^ 2))
   (at_point 0) (Rbar_locally' p_infty).
Proof.
  unfold ex_RInt_gen.
  exists (exp(-x0^2) + / (2* exp 1) * exp(-x0^2)).
  apply is_RInt_gen_Chasles with (b:=1) (l1 := exp(-x0^2)) (l2 := / (2 * exp 1) * exp(-x0^2))
                                 (f :=    (fun v : R =>
    (if (Rlt_dec v 1) then 1 else v * exp (- v ^ 2)) * exp (- x0 ^ 2))).
  apply is_RInt_gen_at_point.
  apply (is_RInt_ext (fun v => exp(-x0^2))).
  intros.
  rewrite Rmin_left in H.
  rewrite Rmax_right in H.
  destruct (Rlt_dec x 1).
  unfold is_left.
  lra.
  lra.
  lra.
  lra.
  replace (exp(-x0^2)) with ((1 - 0) * (exp(-x0^2))) at 1.
  apply (@is_RInt_const R_CompleteNormedModule).
  lra.
  apply (is_RInt_gen_ext (fun v => v* exp(-v^2)*exp(-x0^2))).  
  exists (fun a => a = 1) (fun b => b>1000).
  now unfold at_point.
  unfold Rbar_locally'.
  exists 1000.
  trivial.
  intros.
  subst.
  unfold fst in H1.
  unfold snd in H1.
  rewrite Rmin_left in H1.
  rewrite Rmax_right in H1.
  destruct (Rlt_dec x1 1).
  lra.
  now unfold is_left.
  lra.
  lra.
  apply (is_RInt_gen_ext (Derive (fun v => -(/2)*exp(-x0^2) * exp(-v^2)))).  
  apply filter_forall.
  intros.
  rewrite Derive_scal.  
  rewrite Derive_comp; solve_derive.
  rewrite Derive_opp; solve_derive.
  rewrite Derive_mult; solve_derive.    
  rewrite Derive_id.
  rewrite Derive_mult; solve_derive.
  rewrite Derive_id.
  rewrite Derive_const.
  rewrite <- Derive_Reals with (pr := derivable_pt_exp (- (x1 ^ 2))).
  rewrite derive_pt_exp.
  ring_simplify.
  lra.
  replace  (/ (2 * exp 1) * exp (- x0 ^ 2)) with (0 - -  (/ (2 * exp 1) * exp (- x0 ^ 2))) by lra.
  apply is_RInt_gen_Derive.
  apply filter_forall.
  intros.
  solve_derive.
  apply filter_forall.  
  intros.
  apply (continuous_ext (fun v => exp(-x0^2)*v*exp(-v^2))).
  intros.
  rewrite Derive_scal.
  rewrite Derive_comp; solve_derive.  
  rewrite Derive_opp; solve_derive.
  rewrite Derive_mult; solve_derive.    
  rewrite Derive_id.
  rewrite Derive_mult; solve_derive.
  rewrite Derive_id.
  rewrite Derive_const.
  rewrite <- Derive_Reals with (pr := derivable_pt_exp (- (x2 ^ 2))).
  rewrite derive_pt_exp.
  ring_simplify.
  lra.
  apply continuous_mult with (f := fun v => exp(-x0^2)*v).
  apply continuous_scal_r with (k:= exp(-x0^2)) (f:= id).
  apply continuous_id.
  apply continuous_comp.
  apply (@continuous_opp).
  apply continuous_mult with (f := id).
  apply continuous_id.
  apply (@continuous_scal_l) with (f := id).
  apply continuous_id.
  apply (@ex_derive_continuous).
  apply ex_derive_Reals_1.
  apply derivable_pt_exp.
  unfold filterlim.
  unfold filter_le.
  intros.
  unfold filtermap.
  unfold at_point.
  apply locally_singleton.
  replace (- / 2 * exp (- x0 ^ 2) * exp (- 1 ^ 2)) with (- (/ (2 * exp 1) * exp (- x0 ^ 2))); trivial.
  apply Rminus_diag_uniq.
  field_simplify.
  replace (exp (-1^2)) with (/ exp 1).
  field_simplify.
  lra.
  apply Rgt_not_eq.  
  apply exp_pos.
  replace (-1^2) with (-1) by lra.
  rewrite exp_Ropp.
  unfold IPR.
  trivial.
  apply Rgt_not_eq.  
  apply exp_pos.
  replace (filterlim (fun v : R => - / 2 * exp (- x0 ^ 2) * exp (- v ^ 2))
    (Rbar_locally' p_infty) (locally 0)) with (is_lim (fun v : R => - / 2 * exp (- x0 ^ 2) * exp (- v ^ 2)) p_infty 0).
  replace (Finite 0) with (Rbar_mult (-/2 * exp(-x0^2)) 0).
  apply is_lim_scal_l.
  apply (is_lim_ext (fun t => / exp(t^2))).
  intros.
  symmetry.
  apply exp_Ropp.
  replace (Finite 0) with (Rbar_inv p_infty).
  apply is_lim_inv.
  eapply is_lim_le_p_loc; [idtac | apply is_lim_exp_p].
  unfold Rbar_locally'.
  exists 2; intros.
  left.
  apply exp_increasing.
  replace (x) with (x*1) at 1 by lra.
  replace (x^2) with (x*x) by lra.
  apply Rmult_lt_compat_l.
  lra.
  lra.
  discriminate.
  now compute.
  apply Rbar_mult_0_r.
  now unfold is_lim.
Qed.

Lemma erf_ex_RInt1 (x0:R):
  ex_RInt_gen
   (fun v : R => exp(-(x0^2 + v^2)))
   (at_point 0) (Rbar_locally' p_infty).
Proof.
    apply (ex_RInt_gen_ext (fun v => exp(-(x0^2))*exp(-v^2))).
    apply filter_forall.
    intros.
    replace (-(x0^2 + x1^2)) with ((-x0^2) + (-x1^2)) by lra.
    symmetry.
    apply exp_plus.
    apply ex_RInt_gen_bound with (g := fun v => (if (Rlt_dec v 1) then 1 else v*exp(-v^2))*exp(-x0^2)).
    apply at_point_filter.
    apply Rbar_locally'_filter.
    unfold filter_Rlt.
    exists 1.
    exists (fun x => x=0) (fun y => y>1000).
    now unfold at_point.
    unfold Rbar_locally'.
    now exists 1000.
    intros.
    subst.
    unfold fst.
    unfold snd.
    lra.
    apply erf_ex_RInt0.
    exists (fun x => x=0) (fun y => y>1000).
    now unfold at_point.    
    unfold Rbar_locally'.
    now exists 1000.
    intros.
    subst.
    unfold fst.
    unfold snd.
    split.
    intros.
    split.
    rewrite <- exp_plus.
    left.
    apply exp_pos.
    rewrite Rmult_comm.
    apply Rmult_le_compat_r.
    left.
    apply exp_pos.
    destruct (Rlt_dec x 1).
    unfold is_left.
    rewrite exp_Ropp.
    replace (1) with (/ 1) by lra.
    apply Rcomplements.Rinv_le_contravar.
    lra.
    replace (1) with (exp 0).
    left.
    apply exp_increasing.
    replace (x ^ 2) with (Rsqr x).
    apply Rlt_0_sqr.
    lra.
    simpl.
    unfold Rsqr.
    lra.
    apply exp_0.
    unfold is_left.
    replace (exp(-x^2)) with (1 * exp(-x^2)) at 1 by lra.
    apply  Rmult_le_compat_r.
    left.
    apply exp_pos.
    lra.
    apply (@ex_RInt_continuous).
    intros.
    apply continuous_scal_r with (k:=exp(-x0^2)) (f:= fun v => exp(-v^2)).
    apply continuous_comp.
    apply continuous_opp with (f := fun x => x^2).
    apply continuous_mult with (f := id).
    apply continuous_id.
    apply continuous_mult with (f := id).
    apply continuous_id.
    apply continuous_const.
    apply (@ex_derive_continuous R_AbsRing).
    apply ex_derive_Reals_1.
    apply derivable_pt_exp.
Qed.

Lemma erf_ex_RInt2:
  ex_RInt_gen
   (fun v : R => exp(-v^2))
   (at_point 0) (Rbar_locally' p_infty).
Proof.
  apply (ex_RInt_gen_ext (fun v => exp(-(0^2 + v^2)))).  
  apply filter_forall.
  intros.
  f_equal.
  lra.
  apply erf_ex_RInt1.
Qed.  

Lemma erf_ex_RInt3 :
  ex_RInt_gen
    (fun u : R =>
     RInt_gen (fun v : R => u * exp (- (u ^ 2 + (u * v + 0) ^ 2))) 
       (at_point 0) (Rbar_locally' p_infty)) (at_point 0) (Rbar_locally' p_infty).
Proof.
  Admitted.

Lemma erf_int1  :
  is_RInt_gen (fun u => RInt_gen (fun v => exp(-(u^2+v^2))) (at_point 0)  (Rbar_locally' p_infty)) (at_point 0) (Rbar_locally' p_infty) (PI / 4).
Proof.
  apply (is_RInt_gen_ext (fun u => RInt_gen (fun v => u*exp(-(u^2+(u*v+0)^2))) (at_point 0) (Rbar_locally' p_infty))).
  - exists (fun x => x=0) (fun y => y>1000).
    now unfold at_point.
    unfold Rbar_locally'.
    now exists 1000.
    intros.
    unfold fst in H1.
    unfold snd in H1.
    subst.
    rewrite Rmin_left in H1.
    rewrite Rmax_right in H1.
    apply is_RInt_gen_unique.
    apply is_RInt_gen_comp_lin0 with (u:=x0) (v:=0) (f := fun v => exp(-(x0^2 + v^2))).
    lra.
    intros.
    apply ex_RInt_continuous with (f:= (fun v : R => exp (- (x0 ^ 2 + v ^ 2)))).
    intros.
    apply continuous_comp.
    apply continuous_opp with (f := fun x2 => x0^2 + x2^2).
    apply continuous_plus with (f := fun _ => x0^2) (g := fun x2 => x2^2).
    apply continuous_const.
    simpl.
    apply continuous_mult with (f := id).
    apply continuous_id.
    apply continuous_mult with (f := id).
    apply continuous_id.
    apply continuous_const.
    apply (@ex_derive_continuous).
    apply ex_derive_Reals_1.
    apply derivable_pt_exp.
    replace (at_point (x0*0 + 0)) with (at_point 0).
    replace (Rbar_locally' (Rbar_plus (Rbar_mult x0 p_infty) 0)) with (Rbar_locally' p_infty).
    apply (@RInt_gen_correct).
    apply Proper_StrongProper.
    apply at_point_filter.
    apply Proper_StrongProper.
    apply Rbar_locally'_filter.
    apply erf_ex_RInt1.
    f_equal.
    rewrite Rbar_plus_0_r.
    rewrite Rbar_mult_comm.
    rewrite Rbar_mult_p_infty_pos; trivial.
    lra.
    + f_equal; lra.
    + lra.
    + lra.
  - replace (PI/4) with (RInt_gen
                           (fun u : R =>
                              RInt_gen (fun v : R => u * exp (- (u ^ 2 + (u * v + 0) ^ 2))) 
                                       (at_point 0) (Rbar_locally' p_infty)) (at_point 0) (Rbar_locally' p_infty)).
    apply RInt_gen_correct.
    apply erf_ex_RInt3.
    rewrite -> Fubini_gen with (Fa := at_point 0) (Fc := at_point 0) (Fb := Rbar_locally' p_infty) (Fd := Rbar_locally' p_infty) (f := fun u => fun v => u* exp (- (u^2 + (u*v+0) ^ 2))).
    apply is_RInt_gen_unique.
    apply (is_RInt_gen_ext (fun v : R =>
                              RInt_gen (fun u : R => u * exp (- (u ^ 2 + (u * v) ^ 2))) 
                                       (at_point 0) (Rbar_locally' p_infty))).
    apply filter_forall.
    intros.
    apply (RInt_gen_ext (fun u : R => u * exp (- (u ^ 2 + (u * x0) ^ 2)))).
    apply filter_forall.
    intros.
    now replace (x2*x0+0) with (x2*x0) by lra.
    unfold ex_RInt_gen.
    exists (/ (2 * x0^2 + 2)).
    apply erf_exp0.
    + apply erf_int00.
    + apply filter_forall.  
      intros.
      apply filter_forall.  
      intros.
      apply continuity_2d_pt_mult.
      apply continuity_2d_pt_id1.
      apply continuity_1d_2d_pt_comp.
      apply derivable_continuous_pt.
      apply derivable_pt_exp.
      repeat first [
               apply continuity_2d_pt_opp
             | apply continuity_2d_pt_plus
             | apply continuity_2d_pt_mult
             | apply continuity_2d_pt_id1
             | apply continuity_2d_pt_id2
             | apply continuity_2d_pt_const
             ].
    + eapply Filter_prod with (Q:=(eq 0)) (R:=fun x => x > 1000).
      * now red.
      * simpl;
          exists 1000; trivial.
      * intros.
        simpl in *.
        subst.
        eapply Filter_prod with (Q:=(eq 0)) (R:=fun x => x > 1000).
        -- now red.
        -- simpl;
             exists 1000; trivial.
        -- intros.
           simpl in *.
           subst.
           rewrite Rmin_left in H1; try lra.
           apply Rle_ge.
           apply Rmult_le_pos; try lra.
           left.
           apply exp_pos.
Qed.


Lemma erf_int_sq :
  Rsqr (RInt_gen (fun u => exp(-(u^2))) (at_point 0) (Rbar_locally' p_infty)) = PI/4.
Proof.
  unfold Rsqr.
  rewrite <- RInt_gen_scal.
  rewrite <- (RInt_gen_ext (fun u => RInt_gen (fun v => exp(-(u^2+v^2))) (at_point 0)  (Rbar_locally' p_infty)) ).
  apply is_RInt_gen_unique.
  apply erf_int1.
  apply filter_forall.
  intros.
  rewrite scale_mult.
  rewrite Rmult_comm.
  rewrite <- RInt_gen_scal.
  symmetry.
  rewrite <- (RInt_gen_ext (fun y => exp (-(x0^2 + y^2)))).
  trivial.
  apply filter_forall.
  intros.
  rewrite scale_mult.
  replace (-(x0^2 + x2^2)) with ((-x0^2)+(-x2^2)).
  apply exp_plus.
  lra.
  apply erf_ex_RInt1.
  apply erf_ex_RInt2.  
  unfold ex_RInt_gen.
  exists (PI/4).
  apply erf_int1.
  apply erf_ex_RInt2.  
Qed.

Lemma erf_int2: 
  RInt_gen (fun u => exp(-(u^2))) (at_point 0) (Rbar_locally' p_infty) = (sqrt PI/2).
Proof.
  replace (sqrt PI/2) with (Rabs (sqrt PI/2)).
  replace ( RInt_gen (fun u => exp(-(u^2))) (at_point 0) (Rbar_locally' p_infty)) with
      (Rabs ( RInt_gen (fun u => exp(-(u^2))) (at_point 0) (Rbar_locally' p_infty))).
  apply Rsqr_eq_abs_0.
  replace (Rsqr (sqrt PI/2)) with (PI/4).
  apply erf_int_sq.
  rewrite Rsqr_div.
  rewrite Rsqr_sqrt.
  unfold Rsqr; lra.
  left.
  apply PI_RGT_0.
  lra.
  rewrite Rabs_pos_eq; trivial.
  apply RInt_gen_Rle0.
  apply at_point_filter.
  apply Rbar_locally'_filter.
  apply filter_Rlt_at_point_p_infty.
  apply erf_ex_RInt2.
  apply filter_forall.
  intros.
  left.
  apply exp_pos.
  rewrite Rabs_pos_eq; trivial.
  apply Rcomplements.Rle_div_r.
  lra.
  left.
  replace (0 * 2) with (0) by lra.
  apply sqrt_lt_R0.
  apply PI_RGT_0.
Qed.

Lemma erf_int21: 
  is_RInt_gen (fun u => exp(-(u^2))) (at_point 0) (Rbar_locally' p_infty) (sqrt PI/2).
Proof.
  replace (sqrt PI/2) with (RInt_gen (fun u => exp(-(u^2))) (at_point 0) (Rbar_locally' p_infty)).
  apply (@RInt_gen_correct).
  apply Proper_StrongProper.
  apply at_point_filter.
  apply Proper_StrongProper.
  apply Rbar_locally'_filter.
  apply erf_ex_RInt2.
  apply erf_int2.
Qed.


Lemma erf_int31: 
  is_RInt_gen (fun u => exp(-(u^2))) (at_point 0) (Rbar_locally' m_infty) ( -sqrt PI/2).
Proof.
  apply (is_RInt_gen_ext (fun y => (-1) * ((-1) * (exp (-((-1*y+0)^2)))))).
  apply filter_forall.
  intros.
  replace ((-1*x0+0)^2) with (x0^2).
  now ring_simplify.
  now ring_simplify.
  replace (-sqrt PI/2) with (scal  (-1) (sqrt PI/2)).
  apply (@is_RInt_gen_scal).
  apply at_point_filter.
  apply Rbar_locally'_filter.
  apply is_RInt_gen_comp_lin0 with (f := fun y => exp(-y^2)).
  lra.
  intros.
  apply (@ex_RInt_continuous).
  intros.
  apply continuous_comp.
  apply (@continuous_opp).
  apply (@continuous_mult).
  apply continuous_id.
  apply (@continuous_mult).
  apply continuous_id.
  apply continuous_const.
  apply (@ex_derive_continuous).
  apply ex_derive_Reals_1.
  apply derivable_pt_exp.
  replace (-1*0+0) with (0) by lra.
  replace  (Rbar_plus (Rbar_mult (-1) m_infty) 0) with (p_infty).
  apply erf_int21.
  rewrite Rbar_plus_0_r.
  symmetry.
  rewrite Rbar_mult_comm.
  apply Rbar_mult_m_infty_neg.
  lra.
  replace (- sqrt PI/2) with ((-1)*(sqrt PI/2)).
  apply scale_mult.
  lra.
Qed.

Lemma erf_p_infty : 
  is_RInt_gen erf' (at_point 0) (Rbar_locally' p_infty) 1.
Proof.
  unfold erf'.
  replace (1) with ((2 / sqrt PI)*(sqrt PI/2)).
  apply (@is_RInt_gen_scal).
  apply at_point_filter.
  apply Rbar_locally'_filter.
  apply erf_int21.
  field_simplify.
  lra.
  apply Rgt_not_eq.
  apply sqrt_lt_R0.
  apply PI_RGT_0.
Qed.

Lemma erf_m_infty : 
  is_RInt_gen erf' (at_point 0) (Rbar_locally' m_infty) (-1).
Proof.
  unfold erf'.
  replace (-1) with ((2 / sqrt PI)*(-sqrt PI/2)).
  apply (@is_RInt_gen_scal).
  apply at_point_filter.
  apply Rbar_locally'_filter.
  apply erf_int31.
  apply Rminus_diag_uniq.
  field_simplify.
  lra.
  apply Rgt_not_eq.
  apply sqrt_lt_R0.
  apply PI_RGT_0.
Qed.


