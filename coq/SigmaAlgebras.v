Require Import Classical.
Require Import ClassicalChoice.


Require Import Coq.Reals.Rbase.
Require Import Coq.Reals.Rfunctions.
Require Import Lra Omega.
Require Import List.
Require Import Morphisms EquivDec.

Require Import BasicTactics Sums ListAdd.
Require Import ProbSpace.
Import ListNotations.

Local Open Scope prob.

Lemma classic_event_lem {T} : forall a:event T, event_lem a.
Proof.
  intros ??; apply classic.
Qed.

Local Hint Resolve classic_event_lem.

Lemma event_complement_swap_classic {T} (A B:event T) : ¬ A === B <-> A === ¬ B.
Proof.
  intros.
  apply event_complement_swap; auto.
Qed.

Instance trivial_sa (T:Type) : SigmaAlgebra T
  := {
      sa_sigma (f:event T) := (f === ∅ \/ f === Ω)
    }.
Proof.
  - intros ?? eqq.
    repeat rewrite eqq.
    tauto.
  - auto.
  - intros.
    (* sigh. more classical reasoning needed *)
    destruct (classic (exists n, collection n === Ω))
    ; [right|left]; firstorder.
  - firstorder.
  - firstorder.
Qed.

Instance discrete_sa (T:Type) : SigmaAlgebra T
  := {
      sa_sigma := fun _ => True 
    }.
Proof.
  all: trivial.
  - firstorder.
Qed.

Instance subset_sa (T:Type) (A:event T) : SigmaAlgebra T
  := {
      sa_sigma f := (f === ∅ \/ f === A \/ f === ¬ A \/ f === Ω)
    }.
Proof.
  - intros ?? eqq.
    repeat rewrite eqq.
    tauto.
  - intros ??; apply classic.
  - intros.
    (* sigh. more classical reasoning needed *)
    destruct (classic (exists n, collection n === Ω))
    ; [repeat right; firstorder | ].
    destruct (classic (exists n, collection n === A))
    ; destruct (classic (exists n, collection n === ¬ A)).
    + right; right; right.
      unfold union_of_collection, equiv, event_equiv; intros x.
      split; [firstorder | ].
      destruct (classic (A x)).
      * destruct H1 as [n1 H1].
        exists n1.
        apply H1; trivial.
      * destruct H2 as [n2 H2].
        exists n2.
        apply H2; trivial.
    + right; left.
      unfold union_of_collection, equiv, event_equiv; intros x.
      split.
      * intros [n cn].
        specialize (H n).
        destruct H as [eqq|[eqq|[eqq|eqq]]]
        ; apply eqq in cn
        ; firstorder.
      * intros ax.
        destruct H1 as [n1 H1].
        exists n1.
        apply H1; trivial.
    + right; right. left.
      unfold union_of_collection, equiv, event_equiv; intros x.
      split.
      * intros [n cn].
        specialize (H n).
        destruct H as [eqq|[eqq|[eqq|eqq]]]
        ; apply eqq in cn
        ; firstorder.
      * intros ax.
        destruct H2 as [n2 H2].
        exists n2.
        apply H2; trivial.
    + left.
      split; [| firstorder].
      intros [n cn].
        destruct (H n) as [eqq|[eqq|[eqq|eqq]]]
        ; apply eqq in cn
        ; firstorder.
  - intros.
    repeat rewrite event_complement_swap_classic.
    autorewrite with prob.
    rewrite event_not_not by auto.
    tauto.
  - repeat right.
    reflexivity.
Qed.


Definition is_partition {T} (part:nat->event T)
  := collection_is_pairwise_disjoint part 
     /\ union_of_collection part === Ω.

Definition sub_partition {T} (part1 part2 : nat -> event T)
  := forall n, part1 n === part2 n \/ part1 n === ∅.

Instance sub_partition_pre {T} : PreOrder (@sub_partition T).
Proof.
  constructor; red; unfold sub_partition; intuition eauto.
  - left; reflexivity.
  - specialize (H n).
    specialize (H0 n).
    intuition.
    + rewrite H1.
      tauto.
    + rewrite H1.
      tauto.
Qed.

Definition in_partition_union {T} (part:nat->event T) (f:event T) : Prop
  := exists subpart, sub_partition subpart part /\ (union_of_collection subpart) === f.

Instance in_partition_union_proper {T} (part:nat->event T) :
  Proper (event_equiv ==> iff) (in_partition_union part).
Proof.
  cut (Proper (event_equiv ==> Basics.impl) (in_partition_union part))
  ; unfold in_partition_union, Basics.impl.
  { intros HH x y xyeq.
    intuition eauto.
    symmetry in xyeq.
    intuition eauto.
  }
  intros x y xyeq [sub [sp uc]].
  rewrite xyeq in uc.
  eauto.
Qed.

Lemma sub_partition_diff {T} (sub part:nat->event T) :
  sub_partition sub part ->
  sub_partition (fun x : nat => part x \ sub x) part.
Proof.
  intros is_sub n.
  specialize (is_sub n).
  destruct is_sub as [eqq|eqq]
  ; rewrite eqq
  ; autorewrite with prob
  ; intuition.
Qed.

Instance countable_partition_sa {T} (part:nat->event T) (is_part:is_partition part) : SigmaAlgebra T
  := {
      sa_sigma := in_partition_union part
    }.
Proof.
  - intros ??; apply classic.
  - intros.
    unfold in_partition_union in *.
    unfold is_partition in *.
    apply choice in H.
    destruct H as [partish pH].
    exists (fun n => union_of_collection (fun x => partish x n)).
    split.
    + intros n.
      unfold union_of_collection.

      unfold union_of_collection in *.
      unfold is_partition in is_part.
      destruct (classic ((fun t : T => exists n0 : nat, partish n0 n t) === ∅)); [eauto | ].
      left.
      apply not_all_ex_not in H.
      destruct H as [nn Hnn].
      unfold event_none in Hnn.
      assert (HH':~ ~ (exists n0 : nat, partish n0 n nn)) by intuition.
      apply NNPP in HH'.
      destruct HH' as [nn2 pnn2].
      destruct (pH nn2) as [HH1 HH2].
      red in HH1.
      intros x.
      split.
      * intros [nn3 pnn3].
        destruct (pH nn3) as [HH31 HH32].
        red in HH31.
        destruct (HH31 n); apply H in pnn3; trivial.
        vm_compute in pnn3; intuition.
      * intros pnnn.
        specialize (HH1 n).
        destruct HH1 as [eqq|eqq]; [ | apply eqq in pnn2; vm_compute in pnn2; intuition ].
        apply eqq in pnnn.
        eauto.
    + intros x; unfold union_of_collection in *.
      split.
      * intros [n1 [n2 pnn]].
        exists n2.
        apply pH.
        eauto.
      * intros [n cn].
        apply pH in cn.
        destruct cn.
        eauto.
  - destruct is_part as [disj tot].
    intros A [sub [is_sub uc2]].
    rewrite <- uc2.
    exists (fun x => part x \ sub x).
    split.
    + apply sub_partition_diff; trivial.
    + intros x.
      unfold union_of_collection, event_complement, event_diff.
      { split.
        -
          intros [n [part1 sub1]].
          intros [nn sub2].
          destruct (n == nn); unfold equiv, complement in *.
          + subst; tauto.
          + specialize (disj _ _ c x part1).
            destruct (is_sub nn); [ | firstorder].
            apply H in sub2.
            tauto.
        - intros.
          unfold union_of_collection in tot.
          assert (xin:Ω x) by firstorder.
          apply tot in xin.
          destruct xin as [n partn].
          exists n.
          split; trivial.
          intros subx.
          eauto.
      } 
  - exists part.
    destruct is_part as [disj tot].
    rewrite tot.
    split; reflexivity.
Qed.

(*
Definition is_countable {T} (e:event T)
  := exists (coll:nat -> T -> Prop),
    (forall n t1 t2, coll n t1 -> coll n t2 -> t1 = t2) /\
    e === (fun a => exists n, coll n a).

Lemma is_countable_empty {T} : @is_countable T ∅.
Proof.
  exists (fun n t => False).
  firstorder.
Qed.

Instance is_countable_proper_sub {T} : Proper (event_sub --> Basics.impl) (@is_countable T).
Proof.
  unfold Proper, respectful, Basics.impl, Basics.flip, is_countable.
  intros x y sub [c cx].
  red in sub.
  exists (fun n t =>
            c n t /\ y t).
  firstorder.
Qed.

Instance is_countable_proper {T} : Proper (event_equiv ==> iff) (@is_countable T).
Proof.
  unfold Proper, respectful.
  intros x y eqq.
  split; intros.
  - apply (is_countable_proper_sub x y); trivial.
    apply event_equiv_sub; trivial.
    symmetry; trivial.
  - apply (is_countable_proper_sub y x); trivial.
    apply event_equiv_sub; trivial.
Qed.

Definition cantor_pair (k1 k2 : nat) : nat
  := (((k1 + k2) * (k1 + k2 + 1))/2 + k2)%nat.

Definition Rfloor x := (up x - 1)%Z.
Require Import Rbase R_sqrt.

Definition cantor_pair_inv (k:nat) : nat*nat
  := let i := Z.to_nat (Rfloor((sqrt(INR ((8 * k + 1)%nat)) - 1)/2)) in
     ((k-(i*i + i)/2), ((i*i + 3*i)/2-k)).

Lemma union_of_collection_sup {T} (coll:nat->event T) n : (coll n) ≤ (union_of_collection coll).
Proof.
  unfold event_sub, union_of_collection.
  eauto.
Qed.

Require Import FinFun.

Definition F {T} (coll:nat->event T) (n:nat) : ({x:T | coll n x} -> nat) -> Prop
  := fun f => Injective f.


Lemma F_non_empty {T} (coll:nat->event T) (n:nat) :
  is_countable (coll n) ->
  exists f, F coll n f.
Proof.
  exists (fun _ => n).
  red.
  unfold is_countable, Injective in *.
  intros.

Lemma union_of_collection_is_countable {T} (coll:nat->event T) :
  (forall n : nat, is_countable (coll n)) -> is_countable (union_of_collection coll).
Proof.
  intros isc.

  
  intros isc.
  apply choice in isc.
  destruct isc as [f fprop]. 
  exists (fun n t => union_of_collection (fun x => f n x) t).
  split.
  - intros n t1 t2 [x1 xc1] [x2 xc2].
    specialize (fprop n).
    destruct fprop as [p1 p2].
    eapply p1; eauto.
    
    
  - intros t; split.
    + intros [x cx].
      specialize (fprop x).
      destruct fprop as [p1 p2].
      apply p2 in cx.
      destruct cx as [n fn].
      exists n.
      red; eauto.
    + intros [n [n1 fnn]].
      red.
      specialize (fprop n1).
      destruct fprop as [p1 p2].
      exists n1.
      apply p2.
      eauto.
Qed.


Instance countable_sa (T:Type) : SigmaAlgebra T
  := {
      sa_sigma (f:event T) := is_countable f \/ is_countable (¬ f)
    }.
Proof.
  - unfold is_countable.
    intros ?? eqq.
    split; intros [[? HH]|[? HH]]
    ; rewrite eqq in HH || rewrite <- eqq in HH
    ; eauto.
  - intros ??; apply classic.
  - intros coll colln.
    destruct (classic (forall n, is_countable (coll n))).
    + (* they are all countable *)
      left.
      apply union_of_collection_is_countable; trivial.
    + apply not_all_ex_not in H.
      destruct H as [n ncn].
      assert (iscnn:is_countable (¬ coll n)).
      { destruct (colln n); intuition. }
      generalize (union_of_collection_sup coll n); intros subs.
      apply event_complement_sub_proper in subs.
      rewrite <- subs in iscnn.
      eauto.
  - intros.
    rewrite event_not_not by auto with prob.
    tauto.
  - right.
    rewrite event_not_all.
    apply is_countable_empty.
Qed.

*)