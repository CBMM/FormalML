Require Import Reals Coquelicot.Coquelicot.
Require Import Lra.

Set Bullet Behavior "Strict Subproofs".

(*
Lemma is_derive_comp :
  forall (f : R -> R) (g : R -> R) (x : R) (df : R) (dg : R),
  is_derive f (g x) df ->
  is_derive g x dg ->
  is_derive (fun x => f (g x)) x (dg  * df).

Lemma Derive_comp (f g : R -> R) (x : R) :
  ex_derive f (g x) -> ex_derive g x
    -> Derive (fun x => f (g x)) x = Derive g x * Derive f (g x).

Lemma is_derive_plus :
  forall (f g : K -> V) (x : K) (df dg : V),
  is_derive f x df ->
  is_derive g x dg ->
  is_derive (fun x => plus (f x) (g x)) x (plus df dg).

Lemma is_derive_minus :
  forall (f g : K -> V) (x : K) (df dg : V),
  is_derive f x df ->
  is_derive g x dg ->
  is_derive (fun x => minus (f x) (g x)) x (minus df dg).

Lemma is_derive_mult :
  forall (f g : R -> R) (x : R) (df dg : R),
  is_derive f x df ->
  is_derive g x dg ->
  is_derive (fun t : R => f t * g t) x (df * g x + f x * dg) .

Lemma is_derive_div :
  forall (f g : R -> R) (x : R) (df dg : R),
  is_derive f x df ->
  is_derive g x dg ->
  g x <> 0 ->
  is_derive (fun t : R => f t / g t) x ((df * g x - f x * dg) / (g x ^ 2)).

Lemma is_derive_unique f x l :
  is_derive f x l -> Derive f x = l.
*)

Lemma is_derive_exp (x:R) : is_derive exp x (exp x).
Proof.
  rewrite is_derive_Reals.
  apply derivable_pt_lim_exp.
Qed.

Lemma Derive_exp (x:R) : Derive exp x = exp x.
Proof.
  apply is_derive_unique.
  apply is_derive_exp.
Qed.

Lemma is_derive_ln (x:R) : 0 < x -> is_derive ln x (/ x).
Proof.
  rewrite is_derive_Reals.
  apply (derivable_pt_lim_ln x).
Qed.
  
Lemma Derive_ln (x:R) : 0 < x -> Derive ln x = /x.
Proof.
  intros.
  apply is_derive_unique.
  now apply is_derive_ln.
Qed.

Lemma is_derive_abs_pos (x:R): 0 < x -> is_derive Rabs x 1.
Proof.
  rewrite is_derive_Reals.
  apply Rabs_derive_1.
Qed.

Lemma Derive_abs_pos (x:R): 0 < x -> Derive Rabs x = 1.
Proof.
  intros.
  apply is_derive_unique.
  now apply is_derive_abs_pos.
Qed.

Lemma is_derive_abs_neg (x:R): 0 > x -> is_derive Rabs x (-1).
Proof.
  rewrite is_derive_Reals.
  apply Rabs_derive_2.
Qed.

Lemma Derive_abs_neg (x:R): 0 > x -> Derive Rabs x = -1.
Proof.
  intros.
  apply is_derive_unique.
  now apply is_derive_abs_neg.
Qed.

Lemma is_derive_abs (x:R): 0 <> x -> is_derive Rabs x (sign x).
Proof.
  intros.
  generalize (Rdichotomy); trivial; intros.
  apply H0 in H.
  unfold sign.
  destruct H.
  - destruct (total_order_T 0 x); trivial; [|lra].
    destruct s; [|lra].
    now apply is_derive_abs_pos.
  - destruct (total_order_T 0 x).
    + destruct s; [lra|lra].
    + now apply is_derive_abs_neg.
Qed.

Lemma Derive_abs (x:R): 0 <> x -> Derive Rabs x = sign x.
Proof.
  intros.
  apply is_derive_unique.
  now apply is_derive_abs.
Qed.

Lemma is_derive_sqr (x:R): is_derive Rsqr x (2 * x).
Proof.
  rewrite is_derive_Reals.
  apply derivable_pt_lim_Rsqr.
Qed.

Lemma Derive_sqr (x:R): Derive Rsqr x = 2 * x.
Proof.
  apply is_derive_unique.
  now apply is_derive_sqr.
Qed.
  
Lemma ball_abs (x y:R_AbsRing) (eps : posreal):
  ball x eps y <-> Rabs(y - x) < eps.
Proof.
  unfold ball; simpl.
  unfold AbsRing_ball; simpl; tauto.
Qed.

Lemma is_derive_sign_pos :
  forall (x:R), 0<x -> is_derive sign x 0.
Proof.
  intros.
  apply (is_derive_ext_loc (fun _ => 1) sign x 0).
  - unfold locally.
    assert ( 0 < x/2) by lra.
    exists (mkposreal (x/2) H0).
    intro.
    rewrite ball_abs; simpl.
    unfold Rabs; intros.
    destruct (Rcase_abs (y - x)) in H1
    ; assert (0<y) by lra
    ; apply sym_eq
    ; now apply sign_eq_1.
  - apply (@is_derive_const R_AbsRing).
Qed.

Lemma is_derive_sign_neg :
  forall (x:R), 0>x -> is_derive sign x 0.
Proof.
  intros.
  apply (is_derive_ext_loc (fun _ => -1) sign x 0).
  - unfold locally.
    assert ( 0 < -x/2) by lra.
    exists (mkposreal (-x/2) H0).
    intro.
    rewrite ball_abs; simpl.
    unfold Rabs; intros.
    destruct (Rcase_abs (y - x)) in H1
    ; assert (0>y) by lra
    ; apply sym_eq
    ; now apply sign_eq_m1.
  - apply (@is_derive_const R_AbsRing).
Qed.

Lemma is_derive_sign (x:R) : 0 <> x -> is_derive sign x 0.
Proof.
  intros.
  generalize (Rdichotomy); trivial; intros.
  apply H0 in H.
  destruct H.
  + now apply is_derive_sign_pos.
  + now apply is_derive_sign_neg.
Qed.

Lemma Derive_sign (x:R) : 0 <> x -> Derive sign x = 0.
Proof.
  intros.
  apply is_derive_unique.
  now apply is_derive_sign.
Qed.

Definition psign (x:R) := if Rge_dec x 0 then 1 else -1.

Lemma is_derive_psign_pos :
  forall (x:R), 0<x -> is_derive psign x 0.
Proof.
  intros.
  apply (is_derive_ext_loc (fun _ => 1) psign x 0).
  - unfold locally.
    assert ( 0 < x/2) by lra.
    exists (mkposreal (x/2) H0).
    intro.
    rewrite ball_abs; simpl.
    unfold Rabs; intros.
    unfold psign.
    destruct (Rcase_abs (y - x)) in H1
    ; assert (0<y) by lra
    ; apply sym_eq.
    + now destruct Rge_dec; [|lra].
    + now destruct Rge_dec; [|lra].
  - apply (@is_derive_const R_AbsRing).
Qed.

Lemma is_derive_psign_neg :
  forall (x:R), 0>x -> is_derive psign x 0.
Proof.
  intros.
  apply (is_derive_ext_loc (fun _ => -1) psign x 0).
  - unfold locally.
    assert ( 0 < -x/2) by lra.
    exists (mkposreal (-x/2) H0).
    intro.
    rewrite ball_abs; simpl.
    unfold Rabs; intros.
    unfold psign.
    destruct (Rcase_abs (y - x)) in H1
    ; assert (0>y) by lra
    ; apply sym_eq.
    + now destruct Rge_dec; [lra|].
    + now destruct Rge_dec; [lra|].
  - apply (@is_derive_const R_AbsRing).
Qed.

Lemma is_derive_psign (x:R) : 0 <> x -> is_derive psign x 0.
Proof.
  intros.
  generalize (Rdichotomy); trivial; intros.
  apply H0 in H.
  destruct H.
  + now apply is_derive_psign_pos.
  + now apply is_derive_psign_neg.
Qed.

Lemma Derive_psign (x:R) : 0 <> x -> Derive psign x = 0.
Proof.
  intros.
  apply is_derive_unique.
  now apply is_derive_psign.
Qed.

Lemma is_derive_max_1_pos (y:R) :
  forall (x:R), y<x -> is_derive (fun x => Rmax x y) x 1.
Proof.
  intros.
  apply (is_derive_ext_loc id (fun x => Rmax x y) x 1).
  - unfold locally.
    assert ( 0 < (x-y)/2) by lra.
    exists (mkposreal ((x-y)/2) H0).
    intro.
    rewrite ball_abs; simpl.
    unfold Rabs, Rmax, id; intros.
    case_eq (Rcase_abs (y0 - x)); intros
    ; rewrite H2 in H1
    ; destruct (Rle_dec y0 y); lra.
  - apply (@is_derive_id R_AbsRing).
Qed.

Lemma Derive_max_1_pos (y:R) : 
  forall (x:R), y<x -> Derive (fun x => Rmax x y) x = 1.
Proof.
  intros.
  apply is_derive_unique.
  now apply is_derive_max_1_pos.
Qed.


Lemma is_derive_max_1_neg (y:R) :
  forall (x:R), y>x -> is_derive (fun x => Rmax x y) x 0.
Proof.
  intros.
  apply (is_derive_ext_loc (fun _ => y) (fun x => Rmax x y) x 0).
  - unfold locally.
    assert ( 0 < (y-x)/2) by lra.
    exists (mkposreal ((y-x)/2) H0).
    intro.
    rewrite ball_abs; simpl.
    unfold Rabs, Rmax, id; intros.
    case_eq (Rcase_abs (y0 - x)); intros
    ; rewrite H2 in H1
    ; destruct (Rle_dec y0 y); lra.
  - apply (@is_derive_const R_AbsRing).
Qed.

Lemma Derive_max_1_neg (y:R) : 
  forall (x:R), y>x -> Derive (fun x => Rmax x y) x = 0.
Proof.
  intros.
  apply is_derive_unique.
  now apply is_derive_max_1_neg.
Qed.

Require FunctionalExtensionality.

Lemma is_derive_max_2_pos (y:R) :
  forall (x:R), y<x -> is_derive (fun x => Rmax y x) x 1.
Proof.
  intros.
  replace (fun x0 : AbsRing.sort R_AbsRing => Rmax y x0) with (fun x0 => Rmax x0 y).
  - now apply (is_derive_max_1_pos y x).
  - apply FunctionalExtensionality.functional_extensionality; intros.
    apply Rmax_comm.
Qed.

Lemma Derive_max_2_pos (y:R) : 
  forall (x:R), y<x -> Derive (fun x => Rmax y x ) x = 1.
Proof.
  intros.
  apply is_derive_unique.
  now apply is_derive_max_2_pos.
Qed.

Lemma is_derive_max_2_neg (y:R) :
  forall (x:R), y>x -> is_derive (fun x => Rmax y x) x 0.
Proof.
  intros.
  replace (fun x0 : AbsRing.sort R_AbsRing => Rmax y x0) with (fun x0 => Rmax x0 y).
  - now apply (is_derive_max_1_neg y x).
  - apply FunctionalExtensionality.functional_extensionality; intros.
    apply Rmax_comm.
Qed.

Lemma Derive_max_2_neg (y:R) : 
  forall (x:R), y>x -> Derive (fun x => Rmax y x ) x = 0.
Proof.
  intros.
  apply is_derive_unique.
  now apply is_derive_max_2_neg.
Qed.

(*
(* Ranalysis1 *)
Definition derivable_pt_lim f (x l:R) : Prop :=
  forall eps:R,
    0 < eps ->
    exists delta : posreal,
      (forall h:R,
        h <> 0 -> Rabs h < delta -> Rabs ((f (x + h) - f x) / h - l) < eps).

Definition derivable_pt_abs f (x l:R) : Prop := derivable_pt_lim f x l.
Definition derivable_pt f (x:R) := { l:R | derivable_pt_abs f x l }.
Definition derive_pt f (x:R) (pr:derivable_pt f x) := proj1_sig pr.
Definition derive f (pr:derivable f) (x:R) := derive_pt f x (pr x).

(* Ranalysis4 *)
Lemma derivable_pt_exp : forall x:R, derivable_pt exp x.
Lemma derive_pt_exp :
  forall x:R, derive_pt exp x (derivable_pt_exp x) = exp x.

(* Rpower *)
Lemma derivable_pt_lim_ln : forall x:R, 0 < x -> derivable_pt_lim ln x (/ x).

(* coquelicot/Derive.v *)

Definition Derive (f : R -> R) (x : R) := real (Lim (fun h => (f (x+h) - f x)/h) 0).

Lemma Derive_Reals (f : R -> R) (x : R) (pr : derivable_pt f x) :
  derive_pt f x pr = Derive f x.

Lemma is_derive_Reals (f : R -> R) (x l : R) :
  is_derive f x l <-> derivable_pt_lim f x l.

Lemma is_derive_unique f x l :
  is_derive f x l -> Derive f x = l.

Definition ex_derive (f : K -> V) (x : K) :=
  exists l : V, is_derive f x l.

Lemma ex_derive_Reals_0 (f : R -> R) (x : R) :
  ex_derive f x -> derivable_pt f x.

Lemma ex_derive_Reals_1 (f : R -> R) (x : R) :
  derivable_pt f x -> ex_derive f x.

Lemma Derive_Reals (f : R -> R) (x : R) (pr : derivable_pt f x) :
  derive_pt f x pr = Derive f x.

Lemma Derive_correct f x :
  ex_derive f x -> is_derive f x (Derive f x).

Lemma Derive_comp (f g : R -> R) (x : R) :
  ex_derive f (g x) -> ex_derive g x
    -> Derive (fun x => f (g x)) x = Derive g x * Derive f (g x).

Lemma is_derive_comp :
  forall (f : K -> V) (g : K -> K) (x : K) (df : V) (dg : K),
  is_derive f (g x) df ->
  is_derive g x dg ->
  is_derive (fun x => f (g x)) x (scal dg df).

Lemma Derive_const :
  forall (a x : R),
  Derive (fun _ => a) x = 0.

Lemma Derive_id :
  forall x,
  Derive id x = 1.

Lemma Derive_opp :
  forall f x,
  Derive (fun x => - f x) x = - Derive f x.

Lemma Derive_plus :
  forall f g x, ex_derive f x -> ex_derive g x ->
  Derive (fun x => f x + g x) x = Derive f x + Derive g x.

Lemma Derive_minus :
  forall f g x, ex_derive f x -> ex_derive g x ->
  Derive (fun x => f x - g x) x = Derive f x - Derive g x.

Lemma Derive_inv (f : R -> R) (x : R) :
  ex_derive f x -> f x <> 0
    -> Derive (fun y => / f y) x = - Derive f x / (f x) ^ 2.

Lemma Derive_scal :
  forall f k x,
  Derive (fun x => k * f x) x = k * Derive f x.

Lemma Derive_mult (f g : R -> R) (x : R) :
  ex_derive f x -> ex_derive g x
    -> Derive (fun x => f x * g x) x = Derive f x * g x + f x * Derive g x.

Lemma Derive_pow (f : R -> R) (n : nat) (x : R) :
  ex_derive f x -> Derive (fun x => (f x)^n) x = (INR n * Derive f x * (f x)^(pred n)).

Lemma Derive_div (f g : R -> R) (x : R) :
  ex_derive f x -> ex_derive g x -> g x <> 0
    -> Derive (fun y => f y / g y) x = (Derive f x * g x - f x * Derive g x) / (g x) ^ 2.

*)
