Require Import Reals.

Require Import Lra Lia.
Require Import List Permutation.
Require Import Morphisms EquivDec Program.
Require Import Coquelicot.Rbar Coquelicot.Lub Coquelicot.Lim_seq.
Require Import Classical_Prop.
Require Import Classical.

Require Import Utils.
Require Import DVector.
Require Import NumberIso.
Require Import SigmaAlgebras.
Require Export FunctionsToReal ProbSpace BorelSigmaAlgebra.
Require Export RandomVariable.
Require Export Isomorphism.
Require Import FunctionalExtensionality.
Require Import RealVectorHilbert.

Import ListNotations.

Set Bullet Behavior "Strict Subproofs".

Section VectorRandomVariables.
  
  Context {Ts:Type} {Td:Type}.


  Definition fun_to_vector_to_vector_of_funs
             {n:nat}
             (f: Ts -> vector Td n)
    : vector (Ts->Td) n
    := vector_create 0 n (fun m _ pf => fun x => vector_nth m pf (f x)).

  Definition vector_of_funs_to_fun_to_vector
             {n:nat}
             (fs:vector (Ts->Td) n)
    : Ts -> vector Td n
    := fun x => vector_create 0 n (fun m _ pf => vector_nth m pf fs x).
  
  Program Global Instance vector_iso n : Isomorphism (Ts -> vector Td n) (vector (Ts->Td) n)
    := {
    iso_f := fun_to_vector_to_vector_of_funs
    ; iso_b := vector_of_funs_to_fun_to_vector
      }.
  Next Obligation.
    unfold fun_to_vector_to_vector_of_funs, vector_of_funs_to_fun_to_vector.
    apply vector_nth_eq; intros.
    rewrite vector_nth_create'; simpl.
    apply functional_extensionality; intros.
    now rewrite vector_nth_create'.
  Qed.
  Next Obligation.
    unfold fun_to_vector_to_vector_of_funs, vector_of_funs_to_fun_to_vector.
    apply functional_extensionality; intros.
    erewrite vector_create_ext.
    2: {
      intros.
      rewrite vector_nth_create'.
      reflexivity.
    }
    now rewrite (vector_create_nth).
  Qed.

End VectorRandomVariables.

Require Import Expectation.

Lemma listo_to_olist_length {A:Type} (l:list (option A)) (r:list A)
  : listo_to_olist l = Some r ->
    length l = length r.
Proof.
  revert r.
  induction l; simpl; intros.
  - now invcs H; simpl.
  - destruct a; try discriminate.
    match_option_in H; try discriminate.
    invcs H.
    simpl.
    now rewrite (IHl _ eqq).
Qed.

Program Definition vectoro_to_ovector {A} {n} (v:vector (option A) n) : option (vector A n)
  := match listo_to_olist v with
     | None => None
     | Some x => Some x
     end.
Next Obligation.
  symmetry in Heq_anonymous.
  apply listo_to_olist_length in Heq_anonymous.
  now rewrite vector_length in Heq_anonymous.
Qed.

Section vector_ops.
Context 
  {Ts:Type}
  {dom: SigmaAlgebra Ts}
  {prts: ProbSpace dom}.

Definition vector_Expectation {n} (rv_X : Ts -> vector R n) : option (vector Rbar n)
  := vectoro_to_ovector (vector_map Expectation (iso_f rv_X)).
Print SimpleRandomVariable.


Definition vector_SimpleExpectation {n} (rv_X : Ts -> vector R n)
           (simp : forall (x:Ts->R), In x  (` (iso_f rv_X)) -> SimpleRandomVariable x)
 : vector R n
  := vector_map_onto (iso_f rv_X) (fun x pf => SimpleExpectation x (srv:=simp x pf)).

Definition vecrvplus {n} (rv_X1 rv_X2 : Ts -> vector R n) :=
  (fun omega =>  Rvector_plus (rv_X1 omega) (rv_X2 omega)).

Definition vecrvmult {n} (rv_X1 rv_X2 : Ts -> vector R n) :=
  (fun omega =>  Rvector_mult (rv_X1 omega) (rv_X2 omega)).

Definition vecrvscale {n} (c:R) (rv_X : Ts -> vector R n) :=
  fun omega => Rvector_scale c (rv_X omega).

Definition vecrvopp {n} (rv_X : Ts -> vector R n) := 
  vecrvscale (-1) rv_X.

Definition vecrvsum {n} (rv_X : Ts -> vector R n) : Ts -> R :=
  (fun omega => Rvector_sum (rv_X omega)).

Definition rvinner {n} (rv_X1 rv_X2 : Ts -> vector R n) :=
  fun omega => Rvector_inner (rv_X1 omega) (rv_X2 omega).

Lemma rvinner_unfold {n} (rv_X1 rv_X2 : Ts -> vector R n)
  : rvinner rv_X1 rv_X2 === vecrvsum (vecrvmult rv_X1 rv_X2).
Proof.
  intros ?.
  reflexivity.
Qed.

Class RealVectorMeasurable {n} (rv_X : Ts -> vector R n) :=
  vecmeasurable : forall i pf, RealMeasurable dom (vector_nth i pf (iso_f rv_X)).

Definition event_set_vector_product {T} {n} (v:vector ((event T)->Prop) n) : event (vector T n) -> Prop
  := fun (e:event (vector T n)) =>
       exists (sub_e:vector (event T) n),
         (forall i pf, (vector_nth i pf v) (vector_nth i pf sub_e))
         /\
         e === (fun (x:vector T n) => forall i pf, (vector_nth i pf sub_e) (vector_nth i pf x)).

Instance event_set_vector_product_proper {n} {T} : Proper (equiv ==> equiv) (@event_set_vector_product T n).
Proof.
  repeat red.
  unfold equiv, event_equiv, event_set_vector_product; simpl; intros.
  split; intros [v [HH1 HH2]].
  - unfold equiv in *.
    exists v.
    split; intros.
    + apply H; eauto.
    + rewrite HH2.
      reflexivity.
  - unfold equiv in *.
    exists v.
    split; intros.
    + apply H; eauto.
    + rewrite HH2.
      reflexivity.
Qed.

Instance vector_sa {n} {T} (sav:vector (SigmaAlgebra T) n) : SigmaAlgebra (vector T n)
  := generated_sa (event_set_vector_product (vector_map (@sa_sigma _) sav)).

Global Instance product_sa_proper {T} {n} : Proper (equiv ==> equiv) (@vector_sa T n).
Proof.
  repeat red; unfold equiv, sa_equiv; simpl.
  intros.
  split; intros HH.
  - intros.
    apply HH.
    revert H0.
    apply all_included_proper.
    apply event_set_vector_product_proper.
    intros ??.
    repeat rewrite vector_nth_map.
    specialize (H i pf).
    apply H.
  - intros.
    apply HH.
    revert H0.
    apply all_included_proper.
    apply event_set_vector_product_proper.
    intros ??.
    repeat rewrite vector_nth_map.
    specialize (H i pf).
    symmetry.
    apply H.
Qed.

Definition Rvector_borel_sa (n:nat) : SigmaAlgebra (vector R n)
  := vector_sa (vector_const borel_sa n).

Instance RealVectorMeasurableRandomVariable {n}
         (rv_X : Ts -> vector R n)
         {rvm:RealVectorMeasurable rv_X} :
  RandomVariable dom (Rvector_borel_sa n) rv_X.
Proof.
  
Admitted.


Instance RandomVariableRealVectorMeasurable {n}
         (rv_X : Ts -> vector R n)
         {rrv:RandomVariable dom (Rvector_borel_sa n) rv_X} :
  RealVectorMeasurable rv_X.
Proof.
  
Admitted.

Lemma vector_nth_fun_to_vector {n} (f:Ts->vector R n) i pf : 
  vector_nth i pf (fun_to_vector_to_vector_of_funs f) = fun x => vector_nth i pf (f x).
Proof.
  unfold fun_to_vector_to_vector_of_funs.
  now rewrite vector_nth_create'.
Qed.


Lemma RealVectorMeasurableComponent_simplify {n} (f:Ts->vector R n) : 
  (forall (i : nat) (pf : (i < n)%nat),
   RealMeasurable dom (vector_nth i pf (fun_to_vector_to_vector_of_funs f))) ->   
  (forall (i : nat) (pf : (i < n)%nat),
      RealMeasurable dom (fun x => vector_nth i pf (f x))).
Proof.
  intros HH i pf.
  eapply RealMeasurable_proper; try eapply HH.
  rewrite vector_nth_fun_to_vector.
  reflexivity.
Qed.
                  
Instance Rvector_plus_measurable {n} (f g : Ts -> vector R n) :
  RealVectorMeasurable f ->
  RealVectorMeasurable g ->
  RealVectorMeasurable (vecrvplus f g).
Proof.
  unfold RealVectorMeasurable, vecrvplus; simpl; intros.
  rewrite vector_nth_fun_to_vector.
  eapply RealMeasurable_proper.
  - intros ?.
    rewrite Rvector_plus_explode.
    rewrite vector_nth_create'.
    reflexivity.
  - apply plus_measurable; eauto
    ; now apply RealVectorMeasurableComponent_simplify.
Qed.

Instance Rvector_mult_measurable {n} (f g : Ts -> vector R n) :
  RealVectorMeasurable f ->
  RealVectorMeasurable g ->
  RealVectorMeasurable (vecrvmult f g).
Proof.
  unfold RealVectorMeasurable, vecrvmult; simpl; intros.
  rewrite vector_nth_fun_to_vector.
  eapply RealMeasurable_proper.
  - intros ?.
    rewrite Rvector_mult_explode.
    rewrite vector_nth_create'.
    reflexivity.
  - apply mult_measurable; eauto
    ; now apply RealVectorMeasurableComponent_simplify.
Qed.
    
Lemma vecrvsum_rvsum {n} (f : Ts -> vector R n) :
  (vecrvsum f) === (rvsum (fun i x => match lt_dec i n with
                                  | left pf => vector_nth i pf (f x)
                                  | right _ => 0%R
                                  end)
                          n).
Proof.
  intros a.
  unfold vecrvsum, Rvector_sum, rvsum; simpl.
  destruct (f a); simpl.
  subst.
  rewrite list_sum_sum_n.
  apply (@Hierarchy.sum_n_ext Hierarchy.R_AbelianGroup); intros.
  destruct (lt_dec n (length x)).
  - unfold vector_nth.
    match goal with
      [|- context [proj1_sig ?x]] => destruct x
    end; simpl in *.
    now rewrite <- e.
  - destruct (nth_error_None x n) as [_ HH].
    rewrite HH; trivial.
    lia.
Qed.
  
Instance Rvector_sum_measurable {n} (f : Ts -> vector R n) :
  RealVectorMeasurable f ->
  RealMeasurable dom (vecrvsum f).
Proof.
  unfold RealVectorMeasurable; simpl; intros.
  rewrite vecrvsum_rvsum.
  apply rvsum_measurable; intros.
  match_destr.
  - now apply RealVectorMeasurableComponent_simplify.
  - apply constant_measurable.
Qed.  

Instance Rvector_inner_measurable {n} (f g : Ts -> vector R n) :
  RealVectorMeasurable f ->
  RealVectorMeasurable g ->
  RealMeasurable dom (rvinner f g).
Proof.
  unfold RealVectorMeasurable; simpl; intros.
  rewrite rvinner_unfold.
  apply Rvector_sum_measurable.
  apply Rvector_mult_measurable; trivial.
Qed.

End vector_ops.
