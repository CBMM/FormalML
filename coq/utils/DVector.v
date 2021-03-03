Require Import List Lia.
Require Import Eqdep_dec.
Require Import Equivalence EquivDec.
Require Import LibUtils ListAdd.

Import ListNotations.

Definition vector (T:Type) (n:nat)
  := { l : list T | length l = n}.

Lemma length_pf_irrel {T} {n:nat} {l:list T} (pf1 pf2:length l = n) : pf1 = pf2.
Proof.
  apply UIP_dec.
  apply PeanoNat.Nat.eq_dec.
Qed.

Lemma vector_pf_irrel {T:Type} {n:nat} {l:list T} pf1 pf2
  : exist (fun x=>length x = n) l pf1 = exist _ l pf2.
Proof.
  f_equal.
  apply length_pf_irrel.
Qed.

Lemma vector_ext {T:Type} {n:nat} {l1 l2:list T} pf1 pf2
  : l1 = l2 ->
    exist (fun x=>length x = n) l1 pf1 = exist _ l2 pf2.
Proof.
  intros; subst.
  apply vector_pf_irrel.
Qed.

Lemma vector_eq {T} {n:nat} (x y:vector T n)
  : proj1_sig x = proj1_sig y -> x = y.
Proof.
  destruct x; destruct y; simpl.
  apply vector_ext.
Qed.

Lemma vector_eqs {T} {n:nat} (x y:vector T n)
  : Forall2 eq (proj1_sig x) (proj1_sig y) -> x = y.
Proof.
  destruct x; destruct y; simpl.
  intros eqq.
  apply vector_ext.
  now apply Forall2_eq.
Qed.

Definition vector0 {T} : vector T 0%nat := exist _ [] (eq_refl _).

Lemma vector0_0 {T} (v:vector T 0%nat) : v = vector0.
Proof.
  apply vector_eq.
  destruct v; simpl.
  destruct x; simpl in *; trivial.
  congruence.
Qed.

Program Lemma vector_length {T:Type} {n:nat} (v:vector T n)
  : length v = n.
Proof.
  now destruct v; simpl.
Qed.

(* This should move *)
Program Fixpoint map_onto {A B} (l:list A) (f:forall a, In a l -> B) : list B
  := match l with
     | [] => []
     | x::l' => f x _ :: map_onto l' (fun a pf => f a _)
     end.
Next Obligation.
  simpl; auto.
Qed.
Next Obligation.
  simpl; auto.
Qed.

Lemma map_onto_length  {A B} (l:list A) (f:forall a, In a l -> B) :
  length (map_onto l f) = length l.
Proof.
  induction l; simpl; congruence.
Qed.

Program Definition vector_map_onto {A B:Type}
           {n:nat} (v:vector A n) (f:forall a, In a v->B) : vector B n
  := map_onto v f.
Next Obligation.
  rewrite map_onto_length.
  now destruct v; simpl.
Qed.


  Program Definition vector_nth_packed
         {T:Type}
         {n:nat}
         (i:nat)
         (pf:(i<n)%nat)
         (v:vector T n)
    : {x:T | Some x = nth_error v i}
       := match nth_error v i with
          | Some x => x
          | None => _
          end.
  Next Obligation.
    symmetry in Heq_anonymous.
    apply nth_error_None in Heq_anonymous.
   rewrite vector_length in Heq_anonymous.
   lia.
  Defined.

  Program Definition vector_nth
         {T:Type}
         {n:nat}
         (i:nat)
         (pf:(i<n)%nat)
         (v:vector T n)
    : T
    := vector_nth_packed i pf v.

  Program Lemma vector_nth_in
         {T:Type}
         {n:nat}
         (i:nat)
         (pf:(i<n)%nat)
         (v:vector T n)
    : Some (vector_nth i pf v) = nth_error v i.
  Proof.
    unfold vector_nth.
    now destruct ((vector_nth_packed i pf v)); simpl.
  Qed.

Program Definition vector_nth_rect
        {T:Type}
        (P:T->Type)
        {n:nat}
        (i:nat)
        (pf:(i<n)%nat)
        (v:vector T n)
        (Psome:forall x, nth_error v i = Some x -> P x) :
  P (vector_nth i pf v).
Proof.
  unfold vector_nth.
  destruct (vector_nth_packed i pf v); simpl.
  auto.
Qed.


Program Lemma vector_Forall2_nth_iff {A B} {n} (P:A->B->Prop) (v1:vector A n) (v2:vector B n) :
  (forall (i : nat) (pf : (i < n)%nat), P (vector_nth i pf v1) (vector_nth i pf v2)) <->
  Forall2 P v1 v2.
Proof.
  destruct v1 as [v1 ?]; destruct v2 as [v2 ?]; simpl in *; subst.
  split
  ; revert v2 e0
  ; induction v1
  ; destruct v2; simpl in *; try discriminate
  ; intros e; intros.
  - trivial.
  - constructor.
    + assert (pf0:(0 < S (length v1))%nat) by lia.
      specialize (H _ pf0).
      unfold vector_nth, proj1_sig in H.
      repeat match_destr_in H; simpl in *.
      congruence.
    + assert (pf1:length v2 = length v1) by lia.
      apply (IHv1 _ pf1); intros.
      unfold vector_nth, proj1_sig.
      repeat match_destr; simpl in *.
      assert (pf2:(S i < S (length v1))%nat) by lia.
      specialize (H (S i) pf2).      
      unfold vector_nth, proj1_sig in H.
      repeat match_destr_in H; simpl in *.
      congruence.
  - lia.
  - invcs H.
    unfold vector_nth, proj1_sig.
    repeat match_destr; simpl in *.
    destruct i; simpl in *.
    + congruence.
    + invcs e.
      assert (pf1:(i < length v1)%nat) by lia.
      specialize (IHv1 _ H0 H5 i pf1).
      unfold vector_nth, proj1_sig in IHv1.
      repeat match_destr_in IHv1; simpl in *.
      congruence.
Qed.

Lemma vector_nth_eq {T} {n} (v1 v2:vector T n) :
  (forall i pf, vector_nth i pf v1 = vector_nth i pf v2) ->
  v1 = v2.
Proof.
  intros.
  apply vector_eqs.
  now apply vector_Forall2_nth_iff.
Qed.


Program Lemma vector_nth_In {A}
        {n}
        (v:vector A n)
        i
        pf
  : In (vector_nth i pf v) v.
Proof.
  unfold vector_nth, proj1_sig.
  repeat match_destr.
  simpl in *.
  symmetry in e.
  now apply nth_error_In in e.
Qed.  

Lemma nth_error_map_onto {A B} (l:list A) (f:forall a, In a l->B) i d :
  nth_error (map_onto l f) i = Some d ->
  exists d' pfin, nth_error l i = Some d' /\
             d = f d' pfin.
Proof.
  revert l f d.
  induction i; destruct l; simpl; intros; try discriminate.
  - invcs H.
    eauto.
  - destruct (IHi _ _ _ H) as [d' [pfin [??]]]; subst.
    eauto.
Qed.

Program Lemma vector_nth_map_onto
  {A B:Type}
  {n:nat} (v:vector A n) (f:forall a, In a v->B)
  i
  (pf:i<n) :
  exists pfin, vector_nth i pf (vector_map_onto v f) = f (vector_nth i pf v) pfin.
Proof.
  unfold vector_map_onto.
  unfold vector_nth, proj1_sig.
  repeat match_destr.
  simpl in *.
  symmetry in e1.
  destruct (nth_error_map_onto _ _ _ _ e1) as [?[?[??]]].
  subst.
  rewrite H in e.
  invcs e.
  eauto.
Qed.

Program Fixpoint vector_list_create
           {T:Type}
           (start:nat)
           (len:nat)
           (f:(forall m, start <= m -> m < start + len -> T)%nat) : list T
  := match len with
     | 0 => []
     | S m => f start _ _ :: vector_list_create (S start) m (fun x pf1 pf2 => f x _ _)
     end.
Solve All Obligations with lia.

Lemma vector_list_create_length
           {T:Type}
           (start:nat)
           (len:nat)
           (f:(forall m, start <= m -> m < start + len -> T)%nat) :
  length (vector_list_create start len f) = len.
Proof.
  revert start f.
  induction len; simpl; trivial; intros.
  f_equal.
  auto.
Qed.

Program Definition vector_create
           {T:Type}
           (start:nat)
           (len:nat)
           (f:(forall m, start <= m -> m < start + len -> T)%nat) : vector T len
  := vector_list_create start len f.
Next Obligation.
  apply vector_list_create_length.
Qed.

Lemma vector_list_create_ext
      {T:Type}
      (start len:nat)
      (f1 f2:(forall m, start <= m -> m < start + len -> T)%nat) :
  (forall i pf1 pf2, f1 i pf1 pf2 = f2 i pf1 pf2) ->
  vector_list_create start len f1 = vector_list_create start len f2.
Proof.
  revert f1 f2.
  revert start.
  induction len; simpl; trivial; intros.
  f_equal; auto.
Qed.

Lemma vector_create_ext
           {T:Type}
           (start len:nat)
           (f1 f2:(forall m, start <= m -> m < start + len -> T)%nat) :
  (forall i pf1 pf2, f1 i pf1 pf2 = f2 i pf1 pf2) ->
  vector_create start len f1 = vector_create start len f2.
Proof.
  intros.
  apply vector_eq; simpl.
  now apply vector_list_create_ext.
Qed.

Definition vector_const {T} (c:T) n : vector T n
  := vector_create 0 n (fun _ _ _ => c).


Lemma vector_list_create_const_Forall {A} (c:A) start len :
  Forall (fun a : A => a = c)
         (vector_list_create start len (fun (m : nat) (_ : start <= m) (_ : m < start + len) => c)).
Proof.
  revert start.
  induction len; simpl; trivial; intros.
  constructor; trivial.
  now specialize (IHlen (S start)).
Qed.

Program Lemma vector_const_Forall {A} (c:A) n : Forall (fun a => a = c) (vector_const c n).
Proof.
  unfold vector_const, vector_create; simpl.
  apply vector_list_create_const_Forall.
Qed.

Lemma vector_list_create_const_shift {A} (c:A) start1 start2 len :
  vector_list_create start1 len (fun (m : nat) _ _ => c) =
  vector_list_create start2 len (fun (m : nat) _ _ => c).
Proof.
  revert start1 start2.
  induction len; simpl; trivial; intros.
  f_equal.
  now specialize (IHlen (S start1) (S start2)).
Qed.

Lemma vector_list_create_const_vector_eq {A} x c start :
  Forall (fun a : A => a = c) x ->
  x = vector_list_create start (length x) (fun m _ _ => c).
Proof.
  revert start.
  induction x; simpl; trivial; intros.
  invcs H.
  f_equal.
  now apply IHx.
Qed.
  
Program Lemma vector_const_eq {A} {n} (x:vector A n) c : x = vector_const c n <-> Forall (fun a => a = c) x.
Proof.
  split; intros HH.
  - subst.
    apply vector_const_Forall.
  - apply vector_eq.
    destruct x; simpl in *.
    subst n.
    rewrite (vector_list_create_const_vector_eq x c 0); trivial.
    now rewrite vector_list_create_length.
Qed.

Lemma vector_create_fun_ext
      {T}
      (start len:nat)
      (f:(forall m, start <= m -> m < start + len -> T)%nat)
      m1 m2
      pf1 pf1'
      pf2 pf2'
  : m1 = m2 ->
    f m1 pf1 pf2 = f m2 pf1' pf2'.
Proof.
  intros eqq.
  destruct eqq.
  f_equal; apply le_uniqueness_proof.
Qed.

Lemma vector_create_fun_simple_ext
      {T}
      (len:nat)
      (f:(forall m, m < len -> T)%nat)
      m1 m2
      pf pf'
  : m1 = m2 ->
    f m1 pf = f m2 pf'.
Proof.
  intros eqq.
  destruct eqq.
  f_equal; apply le_uniqueness_proof.
Qed.

Lemma vector_nth_create
      {T : Type}
      (start len : nat)
      (i : nat)
      (pf2: i < len)
      (f:(forall m, start <= m -> m < start + len -> T)%nat) :
  vector_nth i pf2 (vector_create start len f) = f (start + i) (PeanoNat.Nat.le_add_r start i) (Plus.plus_lt_compat_l _ _ start pf2).
Proof.
  unfold vector_nth, proj1_sig.
  repeat match_destr.
  unfold vector_create in *.
  simpl in *.
  match goal with
    [|- ?x = ?y] => cut (Some x = Some y); [now inversion 1 |]
  end.
  rewrite e; clear e.
  revert start len pf2 f.

  induction i; simpl; intros
  ; destruct len; simpl; try lia. 
  - f_equal.
    apply vector_create_fun_ext.
    lia.
  - assert (pf2':i < len) by lia.
    rewrite (IHi (S start) len pf2').
    f_equal.
    apply vector_create_fun_ext.
    lia.
Qed.

Lemma vector_nth_create'
      {T : Type}
      (len : nat)
      (i : nat)
      (pf: i < len)
      (f:(forall m, m < len -> T)%nat) :
  vector_nth i pf (vector_create 0 len (fun m _ pf => f m pf)) = f i pf.
Proof.
  rewrite vector_nth_create.
  apply vector_create_fun_simple_ext.
  lia.
Qed.

Lemma vector_create_nth {T} {n} (v:vector T n) :
  vector_create 0 n (fun i _ pf => vector_nth i pf v) = v.
Proof.
  apply vector_nth_eq; intros.
  now rewrite vector_nth_create'.
Qed.  

Program Definition vector_map {A B:Type}
           {n:nat} (f:A->B) (v:vector A n) : vector B n
  := map f v.
Next Obligation.
  rewrite map_length.
  now destruct v; simpl.
Qed.


Program Definition vector_zip {A B:Type}
           {n:nat} (v1:vector A n) (v2:vector B n) : vector (A*B) n
  := combine v1 v2.
Next Obligation.
  rewrite combine_length.
  repeat rewrite vector_length.
  now rewrite Min.min_idempotent.
Qed.

(* move this *)
Lemma nth_error_combine {A B} (x:list A) (y:list B) i :
  match nth_error (combine x y) i with
  | Some (a,b) => nth_error x i = Some a /\
                 nth_error y i = Some b
  | None => nth_error x i = None \/
           nth_error y i = None
  end.
Proof.
  revert i y.
  induction x; simpl; intros i y.
  - destruct i; simpl; eauto.
  - destruct y; simpl.
    + destruct i; simpl; eauto.
    + destruct i; simpl; [eauto | ].
      apply IHx.
Qed.

Lemma vector_nth_zip {A B:Type}
           {n:nat} (x:vector A n) (y:vector B n) i pf : 
  vector_nth i pf (vector_zip x y) = (vector_nth i pf x, vector_nth i pf y).
Proof.
  unfold vector_nth, vector_zip, proj1_sig; simpl.
  repeat match_destr.
  simpl in *.
  destruct x; destruct y; simpl in *.
  specialize (nth_error_combine x x3 i).
  rewrite <- e.
  destruct x0.
  intros [??].
  congruence.
Qed.
  
Program Definition vector_fold_left {A B:Type} (f:A->B->A)
           {n:nat} (v:vector B n) (a0:A) : A
  := fold_left f v a0.

Lemma vector_zip_explode {A B} {n} (x:vector A n) (y:vector B n):
  vector_zip x y = vector_create 0 n (fun i _ pf => (vector_nth i pf x, vector_nth i pf y)).
Proof.
  apply vector_nth_eq; intros.
  rewrite vector_nth_create'.
  now rewrite vector_nth_zip.
Qed.

Lemma vector_nth_map {A B:Type}
           {n:nat} (f:A->B) (v:vector A n) i pf
  : vector_nth i pf (vector_map f v) = f (vector_nth i pf v).
Proof.
  unfold vector_nth, vector_map, proj1_sig.
  repeat match_destr.
  simpl in *.
  symmetry in e0.
  rewrite (map_nth_error _ _ _ e0) in e.
  congruence.
Qed.

Lemma vector_map_create {A B} (start len:nat) f (g:A->B) :
  vector_map g (vector_create start len f) = vector_create start len (fun x pf1 pf2 => g (f x pf1 pf2)).
Proof.
  apply vector_nth_eq; intros.
  rewrite vector_nth_map.
  now repeat rewrite vector_nth_create.
Qed.

Lemma vector_nth_const {T} n (c:T) i pf : vector_nth i pf (vector_const c n) = c.
Proof.
  unfold vector_const.
  now rewrite vector_nth_create.
Qed.

Lemma vector_nth_ext {T} {n} (v:vector T n) i pf1 pf2:
  vector_nth i pf1 v = vector_nth i pf2 v.
Proof.
  f_equal.
  apply le_uniqueness_proof.
Qed.

Lemma vector_map_const {A B} {n} (c:A) (f:A->B) : vector_map f (vector_const c n) = vector_const (f c) n.
Proof.
  apply vector_nth_eq; intros.
  rewrite vector_nth_map.
  now repeat rewrite vector_nth_const.
Qed.

Definition vector_equiv {T:Type} (R:T->T->Prop) {eqR:Equivalence R} (n:nat) : vector T n -> vector T n -> Prop
  := fun v1 v2 => forall i pf, vector_nth i pf v1 === vector_nth i pf v2.

Global Instance vector_equiv_equiv {T:Type} (R:T->T->Prop) {eqR:Equivalence R} {n:nat} : Equivalence (vector_equiv R n).
Proof.
  constructor
  ; repeat red; intros.
  - reflexivity.
  - symmetry.
    apply H.
  - etransitivity.
    + apply H.
    + apply H0.
Qed.

Global Instance vector_equiv_dec {T:Type} (R:T->T->Prop) {eqR:Equivalence R} {eqdecR:EqDec T R} {n:nat}
  : EqDec (vector T n) (vector_equiv R n).
Proof.
  repeat red.
  destruct x; destruct y; simpl.
  revert x x0 e e0.
  induction n; intros x y e1 e2.
  - left.
    intros ??; lia.
  - destruct x; try discriminate.
    destruct y; try discriminate.
    destruct (eqdecR t t0).
    + simpl in *.
      assert (pfx: (length x = n)%nat) by lia.
      assert (pfy: (length y = n)%nat) by lia.
      destruct (IHn x y pfx pfy).
      * left.
        intros ??.
        unfold vector_nth, proj1_sig.
        repeat match_destr.
        simpl in *.
        destruct i; simpl in *.
        -- invcs e3.
           invcs e4.
           trivial.
        -- assert (pf2:(i < n)%nat) by lia.
           specialize (e0 i pf2).
           unfold vector_nth, proj1_sig in e0.
           repeat match_destr_in e0.
           simpl in *.
           congruence.
      * right.
        intros HH.
        apply c.
        intros i pf.
        assert (pf2:(S i < S n)%nat) by lia.
        specialize (HH (S i) pf2).
        unfold vector_nth, proj1_sig in *.
        repeat match_destr_in HH.
        repeat match_destr.
        simpl in *.
        congruence.
    + right.
      intros HH.
      red in HH.
      assert (pf1:(0 < S n)%nat) by lia.
      specialize (HH 0%nat pf1).
      unfold vector_nth in HH; simpl in HH.
      congruence.
Defined.

Global Instance vector_eq_dec {T:Type} {eqdecR:EqDec T eq} {n:nat}
  : EqDec (vector T n) eq.
Proof.
  intros x y.
  destruct (vector_equiv_dec eq x y).
  - left.
    unfold equiv in *.
    apply vector_nth_eq.
    apply e.
  - right.
    unfold equiv, complement in *.
    intros ?; subst.
    apply c.
    reflexivity.
Defined.

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

Definition vector_list {A} (l:list A) : vector A (length l)
  := exist _ l (eq_refl _).

Definition Forall_vectorize {T} {n} (l:list (list T)) 
           (flen:Forall (fun x => length x = n) l) : list (vector T n)
  := list_dep_zip l flen.

Lemma Forall_vectorize_length {T} {n} (l:list (list T)) 
      (flen:Forall (fun x => length x = n) l) :
  length (Forall_vectorize l flen) = length l.
Proof.
  apply list_dep_zip_length.
Qed.

Lemma Forall_vectorize_in {T} {n} (l:list (list T)) 
      (flen:Forall (fun x => length x = n) l) (x:vector T n) :
  In x (Forall_vectorize l flen) <-> In (proj1_sig x) l.
Proof.
  rewrite <- (list_dep_zip_map1 l flen) at 2.
  rewrite in_map_iff.
  split; intros.
  - eauto.
  - destruct H as [? [??]].
    apply vector_eq in H.
    now subst.
Qed.

Program Definition vector_list_product {n} {T} (l:vector (list T) n)
  : list (vector T n)
  := Forall_vectorize (list_cross_product l) _.
Next Obligation.
  destruct l.
  subst.
  apply list_cross_product_inner_length.
Qed.

Program Lemma vector_list_product_length {n} {T} (lnnil:n <> 0) (l:vector (list T) n) :
  length (vector_list_product l) = fold_left Peano.mult (vector_map (@length T) l) 1%nat.
Proof.
  unfold vector_list_product.
  rewrite Forall_vectorize_length.
  rewrite list_cross_product_length; simpl; trivial.
  destruct l; simpl.
  destruct x; simpl in *; congruence.
Qed.

Program Lemma vector_list_product_in_iff {n} {T} (lnnil:n <> 0) (l:vector (list T) n) (x:vector T n):
  In x (vector_list_product l) <-> Forall2 (@In T) x l.
Proof.
  unfold vector_list_product.
  rewrite Forall_vectorize_in.
  apply list_cross_product_in_iff.
  destruct l; simpl.
  destruct x0; simpl in *; congruence.
Qed.

