Require Import String.
Require Import EquivDec.
Require Import RelationClasses.
Require Import List.
Require Import NPeano.
Require Import Lra Omega.
Require Reals.
Require Import Eqdep_dec.

Require Import Floatish.
Require Import Utils.
Require Import derivlemmas.
Require Import DefinedFunctions.
Set Bullet Behavior "Strict Subproofs".

Section DefinedFunctions.

  Context {floatish_impl:floatish}.
  Local Open Scope float.


Section real_pfs.

  Local Existing Instance floatish_R.
  Import Reals.
  Import List.

   Definition addBinding σ v x := (mk_env_entry (v,DTfloat) x)::σ.

   Definition df_eval_at_point {Ann T} σ (df:DefinedFunction Ann T) v x
     := df_eval (addBinding σ v x) df.
   
   Definition df_R {Ann} (σ:df_env) (df:DefinedFunction Ann DTfloat) v : R -> R
     := fun x => match df_eval_at_point σ df v x with
        | Some y => y
        | None => 0%R
        end.

   Require Import Coquelicot.Coquelicot.
                        
    Definition ex_deriv_df {Ann} σ (df:DefinedFunction Ann DTfloat) v (x:R)
     :=  fully_closed_over df ((v,DTfloat)::map (@projT1 _ _) σ) /\
         ex_derive (df_R σ df v) x.

   Definition is_deriv_df {Ann} σ (df:DefinedFunction Ann DTfloat) v (x y:R)
     :=  fully_closed_over df ((v,DTfloat)::map (@projT1 _ _) σ) /\
         is_derive (df_R σ df v) x y.


   Lemma eval_at_point_fully_closed_total {T} (σ:df_env) (df:DefinedFunction UnitAnn T) v x :
      let vl := (v,DTfloat)::map (fun ve => projT1 ve) σ in
      fully_closed_over df vl -> 
      {d:definition_function_types_interp T | df_eval_at_point σ df v x = Some d}.
   Proof.
     intros.
     unfold df_eval_at_point.
     destruct (eval_fully_closed_total (addBinding σ v x) df) as [dd pfd]
     ; simpl; eauto.
   Defined.

   Lemma eval_at_point_diferentiable_total {σ} {df:DefinedFunction UnitAnn DTfloat} {v x y} :
     is_deriv_df σ df v x y ->
     {xve | df_eval_at_point σ df v x = Some xve}.
   Proof.
     intros [closed _ ].
     destruct (eval_at_point_fully_closed_total σ df v x); eauto.
   Defined.

   Definition eval_differentiable_at_point {σ} {df:DefinedFunction UnitAnn DTfloat} {v x y}
              (pf_deriv:is_deriv_df σ df v x y) :=
     proj1_sig (eval_at_point_diferentiable_total pf_deriv).

   Lemma is_derive_df_exp
         (df:DefinedFunction UnitAnn DTfloat) (σ:df_env) v x y
         (pf_deriv:is_deriv_df σ df v x y) :
     forall a,
     is_deriv_df σ (Exp a df) v x (y * exp (eval_differentiable_at_point pf_deriv)).
   Proof.
     unfold eval_differentiable_at_point.
     destruct (eval_at_point_diferentiable_total pf_deriv) as [xve eqqx]; simpl.
     unfold is_deriv_df; simpl; destruct pf_deriv as [base_closed base_deriv].
     split; trivial.
     generalize (is_derive_comp exp (df_R σ df v) x (exp xve) y)
     ; intros isd.
     unfold df_R, df_eval_at_point in *.
     eapply is_derive_ext; [ | eapply isd]; trivial.
     - intros; simpl.
       match_option; simpl.
       eelim eval_fully_closed_not_none; [ | eapply eqq].
       simpl; trivial.
     - rewrite eqqx.
       apply is_derive_exp.
   Qed.

   Lemma is_derive_df_mult
         (df1 df2:DefinedFunction UnitAnn DTfloat) (σ:df_env) v x y1 y2 
         (pf_deriv1:is_deriv_df σ df1 v x y1) 
         (pf_deriv2:is_deriv_df σ df2 v x y2) :
     forall a,
     is_deriv_df σ (Times a df1 df2) v x ((y1 * eval_differentiable_at_point pf_deriv2 + eval_differentiable_at_point pf_deriv1 * y2)).
   Proof.
     unfold eval_differentiable_at_point.
     intros.
     destruct (eval_at_point_diferentiable_total pf_deriv1) as [xve1 eqqx1]; simpl.
     destruct (eval_at_point_diferentiable_total pf_deriv2) as [xve2 eqqx2]; simpl.
     unfold is_deriv_df; simpl
     ; destruct pf_deriv1 as [base_closed1 base_deriv1]
     ; destruct pf_deriv2 as [base_closed2 base_deriv2].
     split; [tauto | ].
     generalize (is_derive_mult (df_R σ df1 v) (df_R σ df2 v) x y1 y2 base_deriv1 base_deriv2)
     ; intros HH.
     unfold df_R in *.
     rewrite eqqx1, eqqx2 in HH.
     eapply is_derive_ext; [ | eapply HH]; trivial.
     - intros; simpl.
       unfold df_eval_at_point; simpl.
       repeat match_option; unfold mult; simpl; lra.
       (*
       + eelim eval_fully_closed_not_none; [ | eapply eqq0].
         simpl; eauto.
       + eelim eval_fully_closed_not_none; [ | eapply eqq].
         simpl; eauto.
       + eelim eval_fully_closed_not_none; [ | eapply eqq0].
         simpl; eauto.
        *)
     - simpl; intros.
       unfold mult; simpl.
       lra.
   Qed.

Tactic Notation "DefinedFunction_scalar_cases" tactic(first) ident(c) :=
  first;
  [ Case_aux c "Number"%string
  | Case_aux c "Constant"%string                 
  | Case_aux c "Var"%string
  | Case_aux c "Plus"%string
  | Case_aux c "Minus"%string
  | Case_aux c "Times"%string
  | Case_aux c "Divide"%string
  | Case_aux c "Square"%string
  | Case_aux c "Exp"%string
  | Case_aux c "Log"%string
  | Case_aux c "Abs"%string
  | Case_aux c "Sign"%string
  | Case_aux c "PSign"%string
  | Case_aux c "Max"%string].


   Require FunctionalExtensionality.

   Theorem df_eval_deriv_correct σ (df:DefinedFunction UnitAnn DTfloat) v (x:R) y
     : is_scalar_function df ->
       df_eval_deriv (addBinding σ v x) df (v,DTfloat) = Some y ->
       is_derive (df_R σ df v) x y.
   Proof.
     simpl.
     intros is_scalar.
     generalize is_scalar.
     revert y.
     pattern df.
     revert df is_scalar.
     DefinedFunction_scalar_cases (apply is_scalar_function_ind) Case; simpl; intros.
     admit.
     admit.
     admit.
     - Case "Plus"%string.
       do 2 match_option_in H1.
       invcs H1.
       destruct is_scalar as [isc1 isc2].
       specialize (H _ isc1 eqq).
       specialize (H0 _ isc2 eqq0).         
   Admitted.
       
 

   Theorem df_eval_deriv_complete σ (df:DefinedFunction UnitAnn DTfloat) v (x:R)
     : is_scalar_function df -> 
       ex_deriv_df σ df v x  ->
       df_eval_deriv (addBinding σ v x) df (v,DTfloat) = Some (Derive (df_R σ df v) x).
   Proof.
     simpl.
     intros is_scalar.
     generalize is_scalar.
     pattern df.
     revert df is_scalar.
     DefinedFunction_scalar_cases (apply is_scalar_function_ind) Case; simpl; intros.
     - Case "Number"%string.
       unfold df_R; simpl.
       now rewrite Derive_const.
     - Case "Constant"%string.
       unfold df_R; simpl.
       now rewrite Derive_const.
     - Case "Var"%string.
       f_equal.
       unfold df_R.
       unfold ex_deriv_df in H.
       destruct H.
       match_case; intros.
       + unfold df_eval_at_point; simpl.
         rewrite H1; simpl.
         refl_simpler; simpl.
         now rewrite Derive_id.
       + unfold df_eval_at_point; simpl.
         rewrite H1; simpl.
         match_option.
         * now rewrite Derive_const.
         * now rewrite Derive_const.
     - Case "Plus"%string.
       unfold ex_deriv_df in H1.
       destruct H1.
       destruct is_scalar.
       assert ((ex_deriv_df σ l v x) /\  (ex_deriv_df σ r v x)).
       admit.
       destruct H5.
       generalize (eval_deriv_fully_closed_not_none (addBinding σ v x) l (v,DTfloat)); simpl; intros.
       cut_to H7; [|apply H1].
       match_option; [|tauto].
       generalize (eval_deriv_fully_closed_not_none (addBinding σ v x) r (v,DTfloat)); simpl; intros.       
       cut_to H8; [|apply H1].
       match_option; [|tauto].
       rewrite eqq in H.
       rewrite eqq0 in H0.
       cut_to H; trivial.
       cut_to H0; trivial.
       unfold ex_deriv_df in H5; destruct H5.
       unfold ex_deriv_df in H6; destruct H6.
       replace (df_R σ (Plus a l r) v) with (fun x0 => ((df_R σ l v)x0) + ((df_R σ r v)x0)).
       + rewrite Derive_plus; trivial.
         inversion H; inversion H0.
         now subst.
       + unfold df_R.
         apply FunctionalExtensionality.functional_extensionality; intros.
         unfold df_eval_at_point.
         generalize (eval_fully_closed_not_none (addBinding σ v x0) l); simpl; intros.
         generalize (eval_fully_closed_not_none (addBinding σ v x0) r); simpl; intros.
         cut_to H11; [|apply H1].
         cut_to H12; [|apply H1].
         match_option; [|tauto].
         case_eq (df_eval (addBinding σ v x0) r); [|tauto]; trivial.
     - Case "Minus"%string.
       unfold ex_deriv_df in H1.
       destruct H1.
       destruct is_scalar.
       assert ((ex_deriv_df σ l v x) /\  (ex_deriv_df σ r v x)).
       admit.
       destruct H5.
       generalize (eval_deriv_fully_closed_not_none (addBinding σ v x) l (v,DTfloat)); simpl; intros.
       cut_to H7; [|apply H1].
       match_option; [|tauto].
       generalize (eval_deriv_fully_closed_not_none (addBinding σ v x) r (v,DTfloat)); simpl; intros.       
       cut_to H8; [|apply H1].
       match_option; [|tauto].
       rewrite eqq in H.
       rewrite eqq0 in H0.
       cut_to H; trivial.
       cut_to H0; trivial.
       unfold ex_deriv_df in H5; destruct H5.
       unfold ex_deriv_df in H6; destruct H6.
       replace (df_R σ (Minus a l r) v) with (fun x0 => ((df_R σ l v)x0) - ((df_R σ r v)x0)).
       + rewrite Derive_minus; trivial.
         inversion H; inversion H0.
         now subst.
       + unfold df_R.
         apply FunctionalExtensionality.functional_extensionality; intros.
         unfold df_eval_at_point.
         generalize (eval_fully_closed_not_none (addBinding σ v x0) l); simpl; intros.
         generalize (eval_fully_closed_not_none (addBinding σ v x0) r); simpl; intros.
         cut_to H11; [|apply H1].
         cut_to H12; [|apply H1].
         match_option; [|tauto].
         case_eq (df_eval (addBinding σ v x0) r); [|tauto]; trivial.
     - Case "Times"%string.
       unfold ex_deriv_df in H1.
       destruct H1.
       destruct is_scalar.
       assert ((ex_deriv_df σ l v x) /\  (ex_deriv_df σ r v x)).
       admit.
       destruct H5.
       generalize (eval_fully_closed_not_none (addBinding σ v x) l); simpl; intros.
       generalize (eval_fully_closed_not_none (addBinding σ v x) r); simpl; intros.
       cut_to H7; [|apply H1].
       cut_to H8; [|apply H1].
       match_option; [|tauto].
       generalize (eval_deriv_fully_closed_not_none (addBinding σ v x) l (v,DTfloat)); simpl; intros.
       cut_to H9; [|apply H1].
       match_option; [|tauto].
       match_option; [|tauto].       
       generalize (eval_deriv_fully_closed_not_none (addBinding σ v x) r (v,DTfloat)); simpl; intros.       
       cut_to H10; [|apply H1].
       match_option; [|tauto].       
       cut_to H; trivial.
       cut_to H0; trivial.
       unfold ex_deriv_df in H5; destruct H5.
       unfold ex_deriv_df in H6; destruct H6.
       replace (df_R σ (Times a l r) v) with (fun x0 => ((df_R σ l v)x0) * ((df_R σ r v)x0)).
       + rewrite Derive_mult; trivial.
         rewrite eqq0 in H.
         rewrite eqq2 in H0.
         inversion H; inversion H0.
         rewrite <- H14.
         rewrite <- H15.
         unfold df_R.
         unfold df_eval_at_point.
         rewrite eqq, eqq1.
         f_equal; lra.
       + apply FunctionalExtensionality.functional_extensionality; intros.
         unfold df_R.
         unfold df_eval_at_point.
         generalize (eval_fully_closed_not_none (addBinding σ v x0) l); simpl; intros.
         generalize (eval_fully_closed_not_none (addBinding σ v x0) r); simpl; intros.
         cut_to H13; [|apply H1].
         cut_to H14; [|apply H1].
         match_option; [|tauto].
         case_eq (df_eval (addBinding σ v x0) r); [|tauto]; trivial.
     - Case "Divide"%string.
       unfold ex_deriv_df in H1.
       destruct H1.
       destruct is_scalar.
       assert ((ex_deriv_df σ l v x) /\  (ex_deriv_df σ r v x)).
       admit.
       destruct H5.
       generalize (eval_fully_closed_not_none (addBinding σ v x) l); simpl; intros.
       generalize (eval_fully_closed_not_none (addBinding σ v x) r); simpl; intros.
       cut_to H7; [|apply H1].
       cut_to H8; [|apply H1].
       match_option; [|tauto].
       generalize (eval_deriv_fully_closed_not_none (addBinding σ v x) l (v,DTfloat)); simpl; intros.
       cut_to H9; [|apply H1].
       match_option; [|tauto].
       match_option; [|tauto].       
       generalize (eval_deriv_fully_closed_not_none (addBinding σ v x) r (v,DTfloat)); simpl; intros.       
       cut_to H10; [|apply H1].
       match_option; [|tauto].       
       cut_to H; trivial.
       cut_to H0; trivial.
       unfold ex_deriv_df in H5; destruct H5.
       unfold ex_deriv_df in H6; destruct H6.
       assert (d1 <> 0).
       admit.
       replace (df_R σ (Divide a l r) v) with (fun x0 => ((df_R σ l v)x0) / ((df_R σ r v)x0)).
       + rewrite Derive_div; trivial.
         rewrite eqq0 in H.
         rewrite eqq2 in H0.
         inversion H; inversion H0.
         rewrite <- H15.
         rewrite <- H16.
         unfold df_R.
         unfold df_eval_at_point.
         rewrite eqq, eqq1.
         f_equal; field; trivial.
         unfold df_R.
         unfold df_eval_at_point.
         now rewrite eqq1.
       + apply FunctionalExtensionality.functional_extensionality; intros.
         unfold df_R.
         unfold df_eval_at_point.
         generalize (eval_fully_closed_not_none (addBinding σ v x0) l); simpl; intros.
         generalize (eval_fully_closed_not_none (addBinding σ v x0) r); simpl; intros.
         cut_to H14; [|apply H1].
         cut_to H15; [|apply H1].
         match_option; [|tauto].
         case_eq (df_eval (addBinding σ v x0) r); [|tauto]; trivial.
     - Case "Square"%string.
       assert (ex_deriv_df σ e v x).
       admit.
       generalize (eval_fully_closed_not_none (addBinding σ v x) e); simpl; intros.       
       assert (H1c := H1).
       unfold ex_deriv_df in H1.
       destruct H1.
       match_option; [|tauto].
       generalize (eval_deriv_fully_closed_not_none (addBinding σ v x) e (v,DTfloat)); simpl; intros.
       match_option; [|tauto].
       unfold ex_deriv_df in H0.
       destruct H0.
       replace (df_R σ (Square a e) v) with (fun x0 => Rsqr ((df_R σ e v) x0)).
       + rewrite Derive_comp; trivial.
         * rewrite Derive_sqr.
           rewrite eqq0 in H.
           cut_to H; trivial; inversion H.
           rewrite <- H7.
           unfold df_R, df_eval_at_point.
           rewrite eqq; f_equal.
           now lra.
         * unfold ex_derive; eexists; eapply is_derive_sqr.
       + apply FunctionalExtensionality.functional_extensionality; intros.
         unfold df_R, df_eval_at_point; simpl.
         match_option.
         unfold Rsqr.
         lra.
     - Case "Exp"%string.
       assert (ex_deriv_df σ e v x).
       admit.
       generalize (eval_fully_closed_not_none (addBinding σ v x) e); simpl; intros.       
       assert (H1c := H1).
       unfold ex_deriv_df in H1; destruct H1.
       match_option; [|tauto].
       generalize (eval_deriv_fully_closed_not_none (addBinding σ v x) e (v,DTfloat)); simpl; intros.
       match_option; [|tauto].
       unfold ex_deriv_df in H0.
       destruct H0.
       replace (df_R σ (Exp a e) v) with (fun x0 => exp ((df_R σ e v) x0)).
       + rewrite Derive_comp; trivial.
         * rewrite Derive_exp.
           cut_to H; trivial.
           rewrite eqq0 in H.
           inversion H.
           rewrite <- H7.
           unfold df_R, df_eval_at_point.
           now rewrite eqq.
         * unfold ex_derive; eexists; eapply is_derive_exp.
       + apply FunctionalExtensionality.functional_extensionality; intros.
         unfold df_R, df_eval_at_point; simpl.
         generalize (eval_fully_closed_not_none (addBinding σ v x0) e); simpl; intros.       
         match_option; tauto.
     - Case "Log"%string.
       assert (ex_deriv_df σ e v x).
       admit.
       generalize (eval_fully_closed_not_none (addBinding σ v x) e); simpl; intros.       
       assert (H1c := H1).
       unfold ex_deriv_df in H1; destruct H1.
       match_option; [|tauto].
       generalize (eval_deriv_fully_closed_not_none (addBinding σ v x) e (v,DTfloat)); simpl; intros.
       match_option; [|tauto].
       unfold ex_deriv_df in H0.
       destruct H0.
       assert (0 < df_R σ e v x).
       admit.
       replace (df_R σ (Log a e) v) with (fun x0 => ln ((df_R σ e v) x0)).
       + rewrite Derive_comp; trivial.
         * rewrite Derive_ln; trivial.
           cut_to H; trivial.
           rewrite eqq0 in H.
           inversion H.
           rewrite <- H8.
           unfold df_R, df_eval_at_point.
           now rewrite eqq.
         * unfold ex_derive; eexists; eapply is_derive_ln; trivial.
       + apply FunctionalExtensionality.functional_extensionality; intros.
         unfold df_R, df_eval_at_point; simpl.
         generalize (eval_fully_closed_not_none (addBinding σ v x0) e); simpl; intros.       
         match_option; tauto.
     - Case "Abs"%string.
       assert (ex_deriv_df σ e v x).
       admit.
       assert (H1c := H1).
       unfold ex_deriv_df in H1; destruct H1.
       generalize (eval_fully_closed_not_none (addBinding σ v x) e ); simpl; intros.
       match_option; [|tauto].
       generalize (eval_deriv_fully_closed_not_none (addBinding σ v x) e (v,DTfloat)); simpl; intros.
       match_option; [|tauto].
       unfold ex_deriv_df in H0.
       destruct H0.
       assert (0 <> df_R σ e v x).
       admit.
       replace (df_R σ (Abs a e) v) with (fun x0 => abs ((df_R σ e v) x0)).
       + rewrite Derive_comp; trivial.
         * rewrite Derive_abs; trivial.
           cut_to H; trivial.
           rewrite eqq0 in H.
           inversion H.
           rewrite <- H8; f_equal.
           unfold df_R, df_eval_at_point.
           rewrite eqq.
           unfold sign, FloatishOps.sign.
           destruct (total_order_T 0 d).
           -- destruct s; simpl.
              ++ destruct (Rlt_dec d 0); [lra|].
                 destruct (Rgt_dec d 0); lra.
              ++ destruct (Rlt_dec d 0); [lra|].
                 destruct (Rgt_dec d 0); lra.
           -- simpl; destruct (Rlt_dec d 0); lra.
         * unfold ex_derive; eexists; eapply is_derive_abs; trivial.
       + apply FunctionalExtensionality.functional_extensionality; intros.
         unfold df_R, df_eval_at_point; simpl.
         generalize (eval_fully_closed_not_none (addBinding σ v x0) e); simpl; intros. 
         match_option.
         unfold abs; simpl.
         unfold Rabs.
         match_case; intros; lra.
     - Case "Sign"%string.
       assert (ex_deriv_df σ e v x).
       admit.
       assert (H1c := H1).
       unfold ex_deriv_df in H1; destruct H1.
       generalize (eval_deriv_fully_closed_not_none (addBinding σ v x) e (v,DTfloat)); simpl; intros.
       match_option; [|tauto].
       unfold ex_deriv_df in H0.
       destruct H0.
       assert (0 <> df_R σ e v x).
       admit.
       replace (df_R σ (Sign a e) v) with (fun x0 => sign ((df_R σ e v) x0)).
       + rewrite Derive_comp; trivial.
         * rewrite Derive_sign; trivial.
           cut_to H; trivial.
           rewrite eqq in H.
           inversion H.
           rewrite <- H7; f_equal; lra.
         * unfold ex_derive; eexists; eapply is_derive_sign; trivial.
       + apply FunctionalExtensionality.functional_extensionality; intros.
         unfold df_R, df_eval_at_point; simpl.
         generalize (eval_fully_closed_not_none (addBinding σ v x0) e); simpl; intros. 
         match_option; [|tauto].
         unfold sign.
         unfold FloatishOps.sign.
         match_case; intros; simpl.
         * destruct s; simpl.
           -- destruct (Rlt_dec d0 0); [lra|].
              now destruct (Rgt_dec d0 0); [|lra].
           -- destruct (Rlt_dec d0 0); [lra|].
              now destruct (Rgt_dec d0 0); [lra|].
         * destruct (Rlt_dec d0 0); [lra|].
           now destruct (Rgt_dec d0 0); [|lra].
     - Case "PSign"%string.
       assert (ex_deriv_df σ e v x).
       admit.
       assert (H1c := H1).
       unfold ex_deriv_df in H1; destruct H1.
       generalize (eval_deriv_fully_closed_not_none (addBinding σ v x) e (v,DTfloat)); simpl; intros.
       match_option; [|tauto].
       unfold ex_deriv_df in H0.
       destruct H0.
       assert (0 <> df_R σ e v x).
       admit.
       replace (df_R σ (PSign a e) v) with (fun x0 => psign ((df_R σ e v) x0)).
       + rewrite Derive_comp; trivial.
         * rewrite Derive_psign; trivial.
           cut_to H; trivial.
           rewrite eqq in H.
           inversion H.
           rewrite <- H7; f_equal; lra.
         * unfold ex_derive; eexists; eapply is_derive_psign; trivial.
       + apply FunctionalExtensionality.functional_extensionality; intros.
         unfold df_R, df_eval_at_point; simpl.
         generalize (eval_fully_closed_not_none (addBinding σ v x0) e); simpl; intros. 
         match_option; [|tauto].
         unfold psign, pos_sign.
         match_case; intros; simpl.
         * destruct (Rge_dec d0 0); lra.
         * destruct (Rge_dec d0 0); lra.
     - Case "Max"%string.
       destruct H1.
       destruct is_scalar.
       assert ((ex_deriv_df σ l v x) /\  (ex_deriv_df σ r v x)).
       admit.
       destruct H5.
       generalize (eval_fully_closed_not_none (addBinding σ v x) l); simpl; intros.
       generalize (eval_fully_closed_not_none (addBinding σ v x) r); simpl; intros.
       cut_to H7; [|apply H1].
       cut_to H8; [|apply H1].
       match_option; [|tauto].
       generalize (eval_deriv_fully_closed_not_none (addBinding σ v x) l (v,DTfloat)); simpl; intros.
       generalize (eval_deriv_fully_closed_not_none (addBinding σ v x) r (v,DTfloat)); simpl; intros.       
       match_option; [|tauto].
       assert (df_R σ l v x <> df_R σ r v x).
       admit.
       cut_to H; trivial.
       cut_to H0; trivial.

       replace (df_R σ (Max a l r) v) with (fun x0 => Rmax ((df_R σ l v)x0) ((df_R σ r v)x0)).       
       + unfold ex_deriv_df in H5; destruct H5.
         unfold ex_deriv_df in H6; destruct H6.
         case_eq (df_eval_deriv (addBinding σ v x) l (v, DTfloat)); intros; [|tauto].
         case_eq (df_eval_deriv (addBinding σ v x) r (v, DTfloat)); intros; [|tauto].
         rewrite Derive_max; trivial.
         rewrite H14 in H.
         rewrite H15 in H0.
         inversion H; inversion H0.
         rewrite <- H17.
         rewrite <- H18.
         unfold df_R, df_eval_at_point.
         rewrite eqq0; rewrite eqq.
         unfold df_R,df_eval_at_point in H11.
         rewrite eqq in H11; rewrite eqq0 in H11.
         case_eq (Rle_dec d d0); intros.
         * f_equal; unfold sign.
           match_case; intros.
           -- destruct s; lra.
           -- lra.
         * f_equal; unfold sign.
           match_case; intros.
           -- destruct s; lra.
           -- lra.
       + apply FunctionalExtensionality.functional_extensionality; intros.
         unfold df_R.
         unfold df_eval_at_point.
         generalize (eval_fully_closed_not_none (addBinding σ v x0) l); simpl; intros.
         generalize (eval_fully_closed_not_none (addBinding σ v x0) r); simpl; intros.
         cut_to H13; [|apply H1].
         cut_to H12; [|apply H1].
         match_option; [|tauto].
         case_eq (df_eval (addBinding σ v x0) r); [|tauto]; trivial.
         intros.
         unfold Rmax, Fmax.
         case_eq (Rle_dec d1 d2); intros; simpl.
         case_eq (Rlt_dec d1 d2); intros; simpl; trivial; lra.
         case_eq (Rlt_dec d1 d2); intros; simpl; lra.
   Admitted.

   Definition df_R_vec {Ann} {n} (σ:df_env) (df:DefinedFunction Ann (DTVector n)) v : 
     R -> Vector R n
     := fun x => match df_eval_at_point σ df v x with
        | Some y => y
        | None => ConstVector n 0
        end.

   Definition df_R_mat {Ann} {n m} (σ:df_env) (df:DefinedFunction Ann (DTMatrix n m)) v : 
     R -> Matrix R n m
     := fun x => match df_eval_at_point σ df v x with
        | Some y => y
        | None => ConstMatrix n m 0
        end.

   Definition df_R_gen Ann T σ :
     (DefinedFunction Ann T) -> SubVar -> R -> (definition_function_types_interp T) :=
     match T with
     | DTfloat => fun df v => df_R σ df v
     | DTVector n => fun df v => df_R_vec σ df v 
     | DTMatrix n m => fun df v => df_R_mat σ df v                      
     end.
   
    Definition ex_deriv_df_vec {Ann} {n} σ (df:DefinedFunction Ann (DTVector n)) v (x:R)
     :=  fully_closed_over df ((v,DTfloat)::map (@projT1 _ _) σ) /\
         forall i,  ex_derive (fun x0 => (df_R_vec σ df v) x0 i) x.

    Definition ex_deriv_df_mat {Ann} {n m} σ (df:DefinedFunction Ann (DTMatrix n m)) v (x:R)
     :=  fully_closed_over df ((v,DTfloat)::map (@projT1 _ _) σ) /\
         forall i j,  ex_derive (fun x0 => (df_R_mat σ df v) x0 i j) x.

    Definition ex_deriv_df_gen (T:definition_function_types) (σ:df_env) :  
       DefinedFunction UnitAnn T -> SubVar -> R -> Prop :=
      match T with
     | DTfloat => fun df v x => ex_deriv_df σ df v x
     | DTVector n => fun df v x => ex_deriv_df_vec σ df v x
     | DTMatrix n m => fun df v x => ex_deriv_df_mat σ df v x
     end.
   
    Definition Derive_vec {n} (f : R -> Vector R n) (x:R) : Vector R n :=
      fun i => Derive (fun x0 => f x0 i) x.

    Definition Derive_mat {n m} (f : R -> Matrix R n m) (x:R) : Matrix R n m :=
      fun i j => Derive (fun x0 => f x0 i j) x.

    Definition Derive_gen {T} (f: R->definition_function_types_interp T) (x:R)
        :=
          (match T return (R -> definition_function_types_interp T) ->
                     definition_function_types_interp T
           with
           | DTfloat => fun f =>  Derive f x
           | DTVector n => fun f => Derive_vec f x
           | DTMatrix n m => fun f => Derive_mat f x
           end) f.
    
   Theorem df_eval_deriv_correct_gen {T} (σ:df_env) (df:DefinedFunction UnitAnn T) v (x:R) :
       ex_deriv_df_gen T σ df v x  ->
       df_eval_deriv (addBinding σ v x) df (v,DTfloat) =
       Some (Derive_gen (df_R_gen UnitAnn T σ df v) x).
   Proof.
     DefinedFunction_cases (induction T, df using DefinedFunction_ind_simpl) Case; simpl; intros.
     - Case "Number"%string.
       unfold df_R; simpl.
       now rewrite Derive_const.
     - Case "Constant"%string.
       unfold df_R_gen, Derive_gen; simpl.
       destruct t.
       + unfold df_R; simpl.
         now rewrite Derive_const.
       + unfold df_R_vec; simpl.
         unfold Derive_vec; f_equal.
         unfold ConstVector.
         apply FunctionalExtensionality.functional_extensionality; intros.
         now rewrite Derive_const.
       + unfold df_R_mat; simpl.
         unfold Derive_mat; f_equal.
         unfold ConstMatrix.
         apply FunctionalExtensionality.functional_extensionality; intros.
         apply FunctionalExtensionality.functional_extensionality; intros.         
         now rewrite Derive_const.
     - Case "DVector"%string; admit.
     - Case "DMatrix"%string; admit.
     - Case "Var"%string.
       f_equal.
       unfold Derive_gen.
       unfold var_type in v0.
       destruct v0.
       simpl.
       destruct d; simpl; unfold var_type.
       + destruct (equiv_dec (s, DTfloat) (v, DTfloat)); simpl.
         * admit.
         * admit.
       + admit.
     - Case "Plus"%string.
       unfold ex_deriv_df in H.
       destruct H.
       generalize (eval_deriv_fully_closed_not_none (addBinding σ v x) df1 (v,DTfloat)); simpl; intros.
       cut_to H1; [|apply H].
       match_option; [|tauto].
       generalize (eval_deriv_fully_closed_not_none (addBinding σ v x) df2 (v,DTfloat)); simpl; intros.       
       cut_to H2; [|apply H].
       match_option; [|tauto].
       rewrite eqq in H.
       rewrite eqq0 in H0.
       cut_to H; trivial.
       cut_to H0; trivial.
       unfold ex_deriv_df in H5; destruct H5.
       unfold ex_deriv_df in H6; destruct H6.
       replace (df_R σ (Plus a l r) v) with (fun x0 => ((df_R σ l v)x0) + ((df_R σ r v)x0)).
       + rewrite Derive_plus; trivial.
         inversion H; inversion H0.
         now subst.
       + unfold df_R.
         apply FunctionalExtensionality.functional_extensionality; intros.
         unfold df_eval_at_point.
         generalize (eval_fully_closed_not_none (addBinding σ v x0) l); simpl; intros.
         generalize (eval_fully_closed_not_none (addBinding σ v x0) r); simpl; intros.
         cut_to H11; [|apply H1].
         cut_to H12; [|apply H1].
         match_option; [|tauto].
         case_eq (df_eval (addBinding σ v x0) r); [|tauto]; trivial.
     - Case "Minus"%string.
       unfold ex_deriv_df in H1.
       destruct H1.
       destruct is_scalar.
       assert ((ex_deriv_df σ l v x) /\  (ex_deriv_df σ r v x)).
       admit.
       destruct H5.
       generalize (eval_deriv_fully_closed_not_none (addBinding σ v x) l (v,DTfloat)); simpl; intros.
       cut_to H7; [|apply H1].
       match_option; [|tauto].
       generalize (eval_deriv_fully_closed_not_none (addBinding σ v x) r (v,DTfloat)); simpl; intros.       
       cut_to H8; [|apply H1].
       match_option; [|tauto].
       rewrite eqq in H.
       rewrite eqq0 in H0.
       cut_to H; trivial.
       cut_to H0; trivial.
       unfold ex_deriv_df in H5; destruct H5.
       unfold ex_deriv_df in H6; destruct H6.
       replace (df_R σ (Minus a l r) v) with (fun x0 => ((df_R σ l v)x0) - ((df_R σ r v)x0)).
       + rewrite Derive_minus; trivial.
         inversion H; inversion H0.
         now subst.
       + unfold df_R.
         apply FunctionalExtensionality.functional_extensionality; intros.
         unfold df_eval_at_point.
         generalize (eval_fully_closed_not_none (addBinding σ v x0) l); simpl; intros.
         generalize (eval_fully_closed_not_none (addBinding σ v x0) r); simpl; intros.
         cut_to H11; [|apply H1].
         cut_to H12; [|apply H1].
         match_option; [|tauto].
         case_eq (df_eval (addBinding σ v x0) r); [|tauto]; trivial.
     - Case "Times"%string.
       unfold ex_deriv_df in H1.
       destruct H1.
       destruct is_scalar.
       assert ((ex_deriv_df σ l v x) /\  (ex_deriv_df σ r v x)).
       admit.
       destruct H5.
       generalize (eval_fully_closed_not_none (addBinding σ v x) l); simpl; intros.
       generalize (eval_fully_closed_not_none (addBinding σ v x) r); simpl; intros.
       cut_to H7; [|apply H1].
       cut_to H8; [|apply H1].
       match_option; [|tauto].
       generalize (eval_deriv_fully_closed_not_none (addBinding σ v x) l (v,DTfloat)); simpl; intros.
       cut_to H9; [|apply H1].
       match_option; [|tauto].
       match_option; [|tauto].       
       generalize (eval_deriv_fully_closed_not_none (addBinding σ v x) r (v,DTfloat)); simpl; intros.       
       cut_to H10; [|apply H1].
       match_option; [|tauto].       
       cut_to H; trivial.
       cut_to H0; trivial.
       unfold ex_deriv_df in H5; destruct H5.
       unfold ex_deriv_df in H6; destruct H6.
       replace (df_R σ (Times a l r) v) with (fun x0 => ((df_R σ l v)x0) * ((df_R σ r v)x0)).
       + rewrite Derive_mult; trivial.
         rewrite eqq0 in H.
         rewrite eqq2 in H0.
         inversion H; inversion H0.
         rewrite <- H14.
         rewrite <- H15.
         unfold df_R.
         unfold df_eval_at_point.
         rewrite eqq, eqq1.
         f_equal; lra.
       + apply FunctionalExtensionality.functional_extensionality; intros.
         unfold df_R.
         unfold df_eval_at_point.
         generalize (eval_fully_closed_not_none (addBinding σ v x0) l); simpl; intros.
         generalize (eval_fully_closed_not_none (addBinding σ v x0) r); simpl; intros.
         cut_to H13; [|apply H1].
         cut_to H14; [|apply H1].
         match_option; [|tauto].
         case_eq (df_eval (addBinding σ v x0) r); [|tauto]; trivial.
     - Case "Divide"%string.
       unfold ex_deriv_df in H1.
       destruct H1.
       destruct is_scalar.
       assert ((ex_deriv_df σ l v x) /\  (ex_deriv_df σ r v x)).
       admit.
       destruct H5.
       generalize (eval_fully_closed_not_none (addBinding σ v x) l); simpl; intros.
       generalize (eval_fully_closed_not_none (addBinding σ v x) r); simpl; intros.
       cut_to H7; [|apply H1].
       cut_to H8; [|apply H1].
       match_option; [|tauto].
       generalize (eval_deriv_fully_closed_not_none (addBinding σ v x) l (v,DTfloat)); simpl; intros.
       cut_to H9; [|apply H1].
       match_option; [|tauto].
       match_option; [|tauto].       
       generalize (eval_deriv_fully_closed_not_none (addBinding σ v x) r (v,DTfloat)); simpl; intros.       
       cut_to H10; [|apply H1].
       match_option; [|tauto].       
       cut_to H; trivial.
       cut_to H0; trivial.
       unfold ex_deriv_df in H5; destruct H5.
       unfold ex_deriv_df in H6; destruct H6.
       assert (d1 <> 0).
       admit.
       replace (df_R σ (Divide a l r) v) with (fun x0 => ((df_R σ l v)x0) / ((df_R σ r v)x0)).
       + rewrite Derive_div; trivial.
         rewrite eqq0 in H.
         rewrite eqq2 in H0.
         inversion H; inversion H0.
         rewrite <- H15.
         rewrite <- H16.
         unfold df_R.
         unfold df_eval_at_point.
         rewrite eqq, eqq1.
         f_equal; field; trivial.
         unfold df_R.
         unfold df_eval_at_point.
         now rewrite eqq1.
       + apply FunctionalExtensionality.functional_extensionality; intros.
         unfold df_R.
         unfold df_eval_at_point.
         generalize (eval_fully_closed_not_none (addBinding σ v x0) l); simpl; intros.
         generalize (eval_fully_closed_not_none (addBinding σ v x0) r); simpl; intros.
         cut_to H14; [|apply H1].
         cut_to H15; [|apply H1].
         match_option; [|tauto].
         case_eq (df_eval (addBinding σ v x0) r); [|tauto]; trivial.
     - Case "Square"%string.
       assert (ex_deriv_df σ e v x).
       admit.
       generalize (eval_fully_closed_not_none (addBinding σ v x) e); simpl; intros.       
       assert (H1c := H1).
       unfold ex_deriv_df in H1.
       destruct H1.
       match_option; [|tauto].
       generalize (eval_deriv_fully_closed_not_none (addBinding σ v x) e (v,DTfloat)); simpl; intros.
       match_option; [|tauto].
       unfold ex_deriv_df in H0.
       destruct H0.
       replace (df_R σ (Square a e) v) with (fun x0 => Rsqr ((df_R σ e v) x0)).
       + rewrite Derive_comp; trivial.
         * rewrite Derive_sqr.
           rewrite eqq0 in H.
           cut_to H; trivial; inversion H.
           rewrite <- H7.
           unfold df_R, df_eval_at_point.
           rewrite eqq; f_equal.
           now lra.
         * unfold ex_derive; eexists; eapply is_derive_sqr.
       + apply FunctionalExtensionality.functional_extensionality; intros.
         unfold df_R, df_eval_at_point; simpl.
         match_option.
         unfold Rsqr.
         lra.
     - Case "Exp"%string.
       assert (ex_deriv_df σ e v x).
       admit.
       generalize (eval_fully_closed_not_none (addBinding σ v x) e); simpl; intros.       
       assert (H1c := H1).
       unfold ex_deriv_df in H1; destruct H1.
       match_option; [|tauto].
       generalize (eval_deriv_fully_closed_not_none (addBinding σ v x) e (v,DTfloat)); simpl; intros.
       match_option; [|tauto].
       unfold ex_deriv_df in H0.
       destruct H0.
       replace (df_R σ (Exp a e) v) with (fun x0 => exp ((df_R σ e v) x0)).
       + rewrite Derive_comp; trivial.
         * rewrite Derive_exp.
           cut_to H; trivial.
           rewrite eqq0 in H.
           inversion H.
           rewrite <- H7.
           unfold df_R, df_eval_at_point.
           now rewrite eqq.
         * unfold ex_derive; eexists; eapply is_derive_exp.
       + apply FunctionalExtensionality.functional_extensionality; intros.
         unfold df_R, df_eval_at_point; simpl.
         generalize (eval_fully_closed_not_none (addBinding σ v x0) e); simpl; intros.       
         match_option; tauto.
     - Case "Log"%string.
       assert (ex_deriv_df σ e v x).
       admit.
       generalize (eval_fully_closed_not_none (addBinding σ v x) e); simpl; intros.       
       assert (H1c := H1).
       unfold ex_deriv_df in H1; destruct H1.
       match_option; [|tauto].
       generalize (eval_deriv_fully_closed_not_none (addBinding σ v x) e (v,DTfloat)); simpl; intros.
       match_option; [|tauto].
       unfold ex_deriv_df in H0.
       destruct H0.
       assert (0 < df_R σ e v x).
       admit.
       replace (df_R σ (Log a e) v) with (fun x0 => ln ((df_R σ e v) x0)).
       + rewrite Derive_comp; trivial.
         * rewrite Derive_ln; trivial.
           cut_to H; trivial.
           rewrite eqq0 in H.
           inversion H.
           rewrite <- H8.
           unfold df_R, df_eval_at_point.
           now rewrite eqq.
         * unfold ex_derive; eexists; eapply is_derive_ln; trivial.
       + apply FunctionalExtensionality.functional_extensionality; intros.
         unfold df_R, df_eval_at_point; simpl.
         generalize (eval_fully_closed_not_none (addBinding σ v x0) e); simpl; intros.       
         match_option; tauto.
     - Case "Abs"%string.
       assert (ex_deriv_df σ e v x).
       admit.
       assert (H1c := H1).
       unfold ex_deriv_df in H1; destruct H1.
       generalize (eval_fully_closed_not_none (addBinding σ v x) e ); simpl; intros.
       match_option; [|tauto].
       generalize (eval_deriv_fully_closed_not_none (addBinding σ v x) e (v,DTfloat)); simpl; intros.
       match_option; [|tauto].
       unfold ex_deriv_df in H0.
       destruct H0.
       assert (0 <> df_R σ e v x).
       admit.
       replace (df_R σ (Abs a e) v) with (fun x0 => abs ((df_R σ e v) x0)).
       + rewrite Derive_comp; trivial.
         * rewrite Derive_abs; trivial.
           cut_to H; trivial.
           rewrite eqq0 in H.
           inversion H.
           rewrite <- H8; f_equal.
           unfold df_R, df_eval_at_point.
           rewrite eqq.
           unfold sign, FloatishOps.sign.
           destruct (total_order_T 0 d).
           -- destruct s; simpl.
              ++ destruct (Rlt_dec d 0); [lra|].
                 destruct (Rgt_dec d 0); lra.
              ++ destruct (Rlt_dec d 0); [lra|].
                 destruct (Rgt_dec d 0); lra.
           -- simpl; destruct (Rlt_dec d 0); lra.
         * unfold ex_derive; eexists; eapply is_derive_abs; trivial.
       + apply FunctionalExtensionality.functional_extensionality; intros.
         unfold df_R, df_eval_at_point; simpl.
         generalize (eval_fully_closed_not_none (addBinding σ v x0) e); simpl; intros. 
         match_option.
         unfold abs; simpl.
         unfold Rabs.
         match_case; intros; lra.
     - Case "Sign"%string.
       assert (ex_deriv_df σ e v x).
       admit.
       assert (H1c := H1).
       unfold ex_deriv_df in H1; destruct H1.
       generalize (eval_deriv_fully_closed_not_none (addBinding σ v x) e (v,DTfloat)); simpl; intros.
       match_option; [|tauto].
       unfold ex_deriv_df in H0.
       destruct H0.
       assert (0 <> df_R σ e v x).
       admit.
       replace (df_R σ (Sign a e) v) with (fun x0 => sign ((df_R σ e v) x0)).
       + rewrite Derive_comp; trivial.
         * rewrite Derive_sign; trivial.
           cut_to H; trivial.
           rewrite eqq in H.
           inversion H.
           rewrite <- H7; f_equal; lra.
         * unfold ex_derive; eexists; eapply is_derive_sign; trivial.
       + apply FunctionalExtensionality.functional_extensionality; intros.
         unfold df_R, df_eval_at_point; simpl.
         generalize (eval_fully_closed_not_none (addBinding σ v x0) e); simpl; intros. 
         match_option; [|tauto].
         unfold sign.
         unfold FloatishOps.sign.
         match_case; intros; simpl.
         * destruct s; simpl.
           -- destruct (Rlt_dec d0 0); [lra|].
              now destruct (Rgt_dec d0 0); [|lra].
           -- destruct (Rlt_dec d0 0); [lra|].
              now destruct (Rgt_dec d0 0); [lra|].
         * destruct (Rlt_dec d0 0); [lra|].
           now destruct (Rgt_dec d0 0); [|lra].
     - Case "PSign"%string.
       assert (ex_deriv_df σ e v x).
       admit.
       assert (H1c := H1).
       unfold ex_deriv_df in H1; destruct H1.
       generalize (eval_deriv_fully_closed_not_none (addBinding σ v x) e (v,DTfloat)); simpl; intros.
       match_option; [|tauto].
       unfold ex_deriv_df in H0.
       destruct H0.
       assert (0 <> df_R σ e v x).
       admit.
       replace (df_R σ (PSign a e) v) with (fun x0 => psign ((df_R σ e v) x0)).
       + rewrite Derive_comp; trivial.
         * rewrite Derive_psign; trivial.
           cut_to H; trivial.
           rewrite eqq in H.
           inversion H.
           rewrite <- H7; f_equal; lra.
         * unfold ex_derive; eexists; eapply is_derive_psign; trivial.
       + apply FunctionalExtensionality.functional_extensionality; intros.
         unfold df_R, df_eval_at_point; simpl.
         generalize (eval_fully_closed_not_none (addBinding σ v x0) e); simpl; intros. 
         match_option; [|tauto].
         unfold psign, pos_sign.
         match_case; intros; simpl.
         * destruct (Rge_dec d0 0); lra.
         * destruct (Rge_dec d0 0); lra.
     - Case "Max"%string.
       destruct H1.
       destruct is_scalar.
       assert ((ex_deriv_df σ l v x) /\  (ex_deriv_df σ r v x)).
       admit.
       destruct H5.
       generalize (eval_fully_closed_not_none (addBinding σ v x) l); simpl; intros.
       generalize (eval_fully_closed_not_none (addBinding σ v x) r); simpl; intros.
       cut_to H7; [|apply H1].
       cut_to H8; [|apply H1].
       match_option; [|tauto].
       generalize (eval_deriv_fully_closed_not_none (addBinding σ v x) l (v,DTfloat)); simpl; intros.
       generalize (eval_deriv_fully_closed_not_none (addBinding σ v x) r (v,DTfloat)); simpl; intros.       
       match_option; [|tauto].
       assert (df_R σ l v x <> df_R σ r v x).
       admit.
       cut_to H; trivial.
       cut_to H0; trivial.

       replace (df_R σ (Max a l r) v) with (fun x0 => Rmax ((df_R σ l v)x0) ((df_R σ r v)x0)).       
       + unfold ex_deriv_df in H5; destruct H5.
         unfold ex_deriv_df in H6; destruct H6.
         case_eq (df_eval_deriv (addBinding σ v x) l (v, DTfloat)); intros; [|tauto].
         case_eq (df_eval_deriv (addBinding σ v x) r (v, DTfloat)); intros; [|tauto].
         rewrite Derive_max; trivial.
         rewrite H14 in H.
         rewrite H15 in H0.
         inversion H; inversion H0.
         rewrite <- H17.
         rewrite <- H18.
         unfold df_R, df_eval_at_point.
         rewrite eqq0; rewrite eqq.
         unfold df_R,df_eval_at_point in H11.
         rewrite eqq in H11; rewrite eqq0 in H11.
         case_eq (Rle_dec d d0); intros.
         * f_equal; unfold sign.
           match_case; intros.
           -- destruct s; lra.
           -- lra.
         * f_equal; unfold sign.
           match_case; intros.
           -- destruct s; lra.
           -- lra.
       + apply FunctionalExtensionality.functional_extensionality; intros.
         unfold df_R.
         unfold df_eval_at_point.
         generalize (eval_fully_closed_not_none (addBinding σ v x0) l); simpl; intros.
         generalize (eval_fully_closed_not_none (addBinding σ v x0) r); simpl; intros.
         cut_to H13; [|apply H1].
         cut_to H12; [|apply H1].
         match_option; [|tauto].
         case_eq (df_eval (addBinding σ v x0) r); [|tauto]; trivial.
         intros.
         unfold Rmax, Fmax.
         case_eq (Rle_dec d1 d2); intros; simpl.
         case_eq (Rlt_dec d1 d2); intros; simpl; trivial; lra.
         case_eq (Rlt_dec d1 d2); intros; simpl; lra.
   Admitted.

