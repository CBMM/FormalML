Require Import Reals Coquelicot.Coquelicot Sums.
Require Import Fourier FunctionalExtensionality Psatz ProofIrrelevance Coq.Bool.Bool.
From mathcomp Require Import ssreflect ssrbool ssrfun eqtype ssrnat div seq.


Set Bullet Behavior "Strict Subproofs".


(*

****************************************************************************************
This file defines the pmf monad (also called the finitary Giry monad) which is a monad 
of finitely supported probability measures on a set. The construction is very general, 
and we don't need to work in that generality. We instead work with a finite state space, 
since that is what we will use in our construction of MDPs. 
****************************************************************************************

 *)


Open Scope list_scope. 

Fixpoint list_fst_sum {A : Type} (l : list (nonnegreal*A)): R  :=
  match l with
  | nil => 0
  | (n,_) :: ns => n + list_fst_sum ns                
  end.

Lemma list_sum_is_nonneg {A : Type} (l : list(nonnegreal*A)) : 0 <= list_fst_sum l. 
Proof.
  induction l.
  simpl ; lra.
  simpl. destruct a as [n].
  assert (0 <= n) by apply (cond_nonneg n).
  apply (Rplus_le_le_0_compat _ _ H).
  lra.
Qed.


Lemma list_sum_cat {A : Type} (l1 l2 : list (nonnegreal * A)) :
  list_fst_sum (l1 ++ l2) = (list_fst_sum l1) + (list_fst_sum l2).
Proof.
  induction l1.
  * simpl ; nra.
  * simpl ; destruct a; nra.
Qed.


Definition nonneg_list_sum {A : Type} (l : list (nonnegreal * A)) : nonnegreal
  := {|
  nonneg := list_fst_sum l;
  cond_nonneg := (list_sum_is_nonneg l)
|}.
                                                                         
Record Pmf (A : Type) := mkPmf {
  outcomes :> list (nonnegreal * A);
  sum1 : list_fst_sum outcomes = R1
 }.

 Arguments outcomes {_}.
 Arguments sum1 {_}.
 Arguments mkPmf {_}.
 

Lemma Pmf_ext  {A} (p q : Pmf A)  : outcomes p = outcomes q -> p = q.
Proof.
destruct p as [op sp].
destruct q as [oq sq].
rewrite /outcomes => ?. (* what's happening here? *)
subst. f_equal. apply proof_irrelevance.
Qed.


Lemma pure_sum1 {A} (a : A) : list_fst_sum [:: ({| nonneg := R1; cond_nonneg := Rlt_le 0 1 Rlt_0_1 |}, a)] = R1. 
Proof.
  simpl. nra.
Qed.

Definition Pmf_pure {A} (a : A) : Pmf A := {|
outcomes := [::(mknonnegreal R1 (Rlt_le _ _ Rlt_0_1),a)];
sum1 := pure_sum1 _
|}.

Lemma prod_nonnegreal : forall (a b : nonnegreal), 0 <= a*b.
Proof.
  intros (a,ha) (b,hb).
  exact (Rmult_le_pos a b ha hb).
Qed.


Fixpoint dist_bind_outcomes
         {A B : Type} (f : A -> Pmf B) (p : list (nonnegreal*A)) : list(nonnegreal*B) :=
  match p with
   | nil => nil
   | (n,a) :: ps =>
     map (fun (py:nonnegreal*B) => (mknonnegreal _ (prod_nonnegreal n py.1),py.2)) (f a).(outcomes) ++ (dist_bind_outcomes f ps)
  end.


Lemma list_fst_sum_eq {A B : Type} (f : A -> Pmf B) (n : nonnegreal) (a : A):
  list_fst_sum [seq (mknonnegreal _ (prod_nonnegreal n py.1), py.2) | py <- f a] = n*list_fst_sum [seq py | py <- f a].
Proof.
  induction (f a) as [ p Hp].
  simpl.
Admitted.

Lemma dist_bind_sum1 {A B : Type} (f : A -> Pmf B) (p : Pmf A) : list_fst_sum (dist_bind_outcomes f p.(outcomes)) = R1.
Proof.
  destruct p as [p Hp]. simpl.
  revert Hp.
  generalize R1 as t.
  induction p.
  simpl; intuition. 
  simpl in *. destruct a as [n a].
  rewrite list_sum_cat. intro t.
  rewrite (IHp (t-n)). 
  * intro Hat.
Admitted.
  
Definition Pmf_bind {A B : Type} (f : A -> Pmf B) (p : Pmf A) : Pmf B :={|
  outcomes := dist_bind_outcomes f p.(outcomes);
  sum1 := _
  |}.

  
