Require Import String.
Require Import EquivDec.
Require Import RelationClasses.
Require Import List.
Require Import NPeano.
Require Import Lra Omega.
Require Reals.

Require Import Floatish.
Require Import Utils.

Set Bullet Behavior "Strict Subproofs".

Section DefinedFunctions.

  Context {floatish_impl:floatish}.
  Local Open Scope float.

(* Declare Scope df_scope. *)

(* in pytorch relu(f)' if f <=0 then 0 else f' *)
(* in pytorch abs(f)' = f'*sign(f) *)
(* max(a,b)' = if a<=b then b' else a' *)
(* min(a,b)' = if a>=b then b' else a' *)
(* x = Variable(torch.tensor(0.0), requires_grad=True) *)
(* z = torch.min(x*x, x); z.backward(); print(x.grad) = 1 *)
(* x.grad.data.zero_() between tests *)
(* relu behaves like max(x, 0), not max(0,x), i.e. relu(x)' at 0 = 0 *)


  Section Definitions.
    
    Definition var := string.
    
    Inductive SubVar : Set :=
    | Name (s : string)
    | Sub (v : SubVar) (i : nat).


    Definition var_dec : forall v1 v2 : SubVar, {v1 = v2} + {v1 <> v2}.
    Proof.
      decide equality.
      apply string_dec.
      apply Nat.eq_dec.
    Defined.
    
    Global Instance var_eqdec : EqDec SubVar eq.
    Proof.
      intros x y.
      apply var_dec.
    Defined.
    
    (* A subset of defined functions *)

    Definition Vector (T:Type) (n : nat) := {n':nat | n' < n}%nat -> T.
    Definition Matrix (T:Type) (n m : nat) := {n':nat | n' < n}%nat -> {m':nat | m' < m}%nat -> T.

    Inductive definition_function_types
     := DTfloat
      | DTVector (n:nat)
      | DTMatrix (m n:nat).
   
    Definition definition_function_types_interp (dft:definition_function_types) : Type
     := match dft with
        | DTfloat => float
        | DTVector n => Vector float n
        | DTMatrix m n => Matrix float m n
        end.

    Inductive DefinedFunction : definition_function_types -> Type :=
    | Number (x : float) : DefinedFunction DTfloat
    | DVector {n} (x : Vector (DefinedFunction DTfloat) n) : DefinedFunction (DTVector n)
    | DMatrix {n m} (x : Matrix (DefinedFunction DTfloat) n m) : DefinedFunction (DTMatrix n m)
    | Var (v : SubVar) : DefinedFunction DTfloat
    | Plus (l r : DefinedFunction DTfloat) : DefinedFunction DTfloat
    | Minus (l r : DefinedFunction DTfloat) : DefinedFunction DTfloat
    | Times (l r : DefinedFunction DTfloat) : DefinedFunction DTfloat
    | Divide (l r : DefinedFunction DTfloat) : DefinedFunction DTfloat
    | Exp (e : DefinedFunction DTfloat) : DefinedFunction DTfloat
    | Log (e : DefinedFunction DTfloat) : DefinedFunction DTfloat
    | Abs (e : DefinedFunction DTfloat) : DefinedFunction DTfloat
    | Sign (e : DefinedFunction DTfloat) : DefinedFunction DTfloat
    | PSign (e : DefinedFunction DTfloat) : DefinedFunction DTfloat
    | Max (l r : DefinedFunction DTfloat) : DefinedFunction DTfloat
    | VectorDot {n} (l r: DefinedFunction (DTVector n)) : DefinedFunction DTfloat
    | VectorSum {n} (v: DefinedFunction (DTVector n)) : DefinedFunction DTfloat
    | VectorElem {n} (l:DefinedFunction (DTVector n)) (i:{x:nat|x<n}%nat) : DefinedFunction DTfloat
    | MatrixElem {m n} (l:DefinedFunction (DTMatrix m n)) (i:{x:nat|x<m}%nat) (j:{x:nat|x<n}%nat) :
        DefinedFunction DTfloat
    | MatrixVectorMult {m n} (l : DefinedFunction (DTMatrix m n)) (r : DefinedFunction (DTVector n)) :
        DefinedFunction (DTVector m)
    | MatrixMult {m p n} (l : DefinedFunction (DTMatrix m p)) (r : DefinedFunction (DTMatrix p n)) :
        DefinedFunction (DTMatrix m n)
    | VectorPlus {n} (l r: DefinedFunction (DTVector n)) : DefinedFunction (DTVector n)
    | VectorMinus {n} (l r: DefinedFunction (DTVector n)) : DefinedFunction (DTVector n)                                                                                   
    | MatrixPlus {n m} (l r : DefinedFunction (DTMatrix n m)) : DefinedFunction (DTMatrix n m)
    | MatrixMinus {n m} (l r : DefinedFunction (DTMatrix n m)) : DefinedFunction (DTMatrix n m)
    | VectorScalMult {n} (x:DefinedFunction DTfloat) (l : DefinedFunction (DTVector n)) :
        DefinedFunction (DTVector n)
    | MatrixScalMult {n m} (x:DefinedFunction DTfloat) (l : DefinedFunction (DTMatrix n m)) :
        DefinedFunction (DTMatrix n m)
    | VectorApply {n} (v:SubVar) (s:DefinedFunction DTfloat) (l: DefinedFunction (DTVector n)) :
        DefinedFunction (DTVector n)
    .

  End Definitions.

    Tactic Notation "DefinedFunction_cases" tactic(first) ident(c) :=
      first;
      [ Case_aux c "Number"%string
      | Case_aux c "DVector"%string
      | Case_aux c "DMatrix"%string
      | Case_aux c "Var"%string
      | Case_aux c "Plus"%string
      | Case_aux c "Minus"%string
      | Case_aux c "Times"%string
      | Case_aux c "Divide"%string
      | Case_aux c "Exp"%string
      | Case_aux c "Log"%string
      | Case_aux c "Abs"%string
      | Case_aux c "Sign"%string
      | Case_aux c "PSign"%string
      | Case_aux c "Max"%string
      | Case_aux c "VectorDot"%string
      | Case_aux c "VectorSum"%string
      | Case_aux c "VectorElem"%string
      | Case_aux c "MatrixElem"%string
      | Case_aux c "MatrixVectorMult"%string
      | Case_aux c "MatrixMult"%string
      | Case_aux c "VectorPlus"%string
      | Case_aux c "VectorMinus"%string
      | Case_aux c "MatrixPlus"%string
      | Case_aux c "MatrixMinus"%string
      | Case_aux c "VectorScalMult"%string
      | Case_aux c "MatrixScalMult"%string
      | Case_aux c "VectorApply"%string].

  Definition df_plus (df1 df2 : DefinedFunction DTfloat) : DefinedFunction DTfloat :=
    Plus df1 df2.

  Definition df_times (df1 df2 : DefinedFunction DTfloat) : DefinedFunction DTfloat :=
    Times df1 df2.

  Section deriv.

    Definition vector_fold_right1_bounded_dep {A:nat->Type} {B} (f:forall n,B->A n->A (S n)) (init:A 0%nat) (singleton:B->A 1%nat) {m:nat} (v:Vector B m) (n:nat) (pf:(n<=m)%nat)
    : A n.
    Proof.
      induction n.
      - exact init.
      - destruct n.
        + assert (pf2:(0 < m)%nat) by omega.
          exact (singleton (v (exist _ 0 pf2)%nat)).
        + assert (pf2:(S n <= m)%nat) by omega.
          assert (pf3:(S n < m)%nat) by omega.
          apply f.
          * exact (v (exist _ (S n) pf3)).
          * apply IHn.
            apply pf2.
    Defined.

    Definition vector_fold_right_bounded_dep {A:nat->Type} {B} (f:forall n,B->A n->A (S n)) (init:A 0%nat) {m:nat} (v:Vector B m) (n:nat) (pf:(n<=m)%nat)
    : A n.
    Proof.
      induction n.
      - exact init.
      - apply f.
        + assert (pf2:(n < m)%nat) by omega.
          exact (v (exist _ n pf2)).
        + apply IHn.
          omega.
    Defined.

    Definition vnil {T} : Vector T 0.
    Proof.
      intros [i pf].
      omega.
    Defined.

    Definition vcons {T} {n} (x:T) (v:Vector T n) : (Vector T (S n)).
    Proof.
      intros [i pf].
      destruct (Nat.eq_dec i n).
      + exact x.
      + apply v.
        exists i.
        omega.
    Defined.

    Definition vector_fold_right1_dep {A:nat->Type} {B} (f:forall n, B->A n->A (S n)) (init:A 0%nat) (singleton:B->A 1%nat) {m:nat} (v:Vector B m) : A m
      := vector_fold_right1_bounded_dep f init singleton v m (le_refl _).

    Definition vector_fold_right_dep {A:nat->Type} {B} (f:forall n, B->A n->A (S n)) (init:A 0%nat) {m:nat} (v:Vector B m) : A m
      := vector_fold_right_bounded_dep f init v m (le_refl _).

    Definition vector_fold_right1 {A B:Type} (f:B->A->A) (init:A) (singleton:B->A) {m:nat} (v:Vector B m)
      := vector_fold_right1_dep (A:=fun _ => A) (fun _ => f) init singleton v.

    Definition vector_fold_right {A B:Type} (f:B->A->A) (init:A) {m:nat} (v:Vector B m)
      := vector_fold_right_dep (fun _ => f) init v.

    Definition defined_sum {m} (v:Vector (DefinedFunction DTfloat) m) : DefinedFunction DTfloat
      := vector_fold_right1 Plus (Number 0) id v.

    Definition vsum {m:nat} (v:Vector float m) : float
      := vector_fold_right1 Fplus 0 id v.

    Definition vectoro_to_ovector {T} {n} (v:Vector (option T) n) : option (Vector T n)
      := vector_fold_right_dep (fun n => lift2 (@vcons _ n)) (Some vnil) v.

    Definition matrixo_to_omatrix {T} {m n} (v:Matrix (option T) m n) : option (Matrix T m n)
      := vectoro_to_ovector (fun i => vectoro_to_ovector (v i)).

    Definition vmap {A B} {n} (f:A->B) (v:Vector A n) : Vector B n
      := vector_fold_right_dep (fun n x y => vcons (n:=n) (f x) y) vnil v.

    Definition list_fold_right1_bounded_dep {A:nat->Type} {B} (f:forall n,B->A n->A (S n)) (init:A 0%nat) (singleton:B->A 1%nat) (l:list B) (n:nat) (pf:(n<=length l)%nat)
    : A n.
    Proof.
      induction n.
      - exact init.
      - destruct n.
        + assert (pf2:(0 < length l)%nat) by omega.
          destruct l.
          * simpl in pf; omega.
          * exact (singleton b).
        + assert (pf2:(S n <= length l)%nat) by omega.
          apply f.
          * destruct l; simpl in *; try omega.
            apply b.
          * apply IHn.
            apply pf2.
    Defined.

    Definition list_fold_right1_dep {A:nat->Type} {B} (f:forall n, B->A n->A (S n)) (init:A 0%nat) (singleton:B->A 1%nat) (l:list B) : A (length l)
      := list_fold_right1_bounded_dep f init singleton l (length l) (le_refl _).

    Definition list_fold_right_dep {A:nat->Type} {B} (f:forall n, B->A n->A (S n)) (init:A 0%nat) (l:list B) : A (length l)
      := list_fold_right1_dep f init (fun a => f _ a init) l.

    Definition list_to_vector {A} (l:list A) : Vector A (length l)
      := list_fold_right_dep (@vcons _) vnil l.

    Definition vector_to_list {A} {n} (v:Vector A n) : list A
      := vector_fold_right cons nil v.
    
    Definition vseq start len : Vector nat len
      := eq_rect _ _ (list_to_vector (seq start len)) _ (seq_length _ _).

  Section subst.

    Fixpoint df_subst {T} (df: DefinedFunction T) (v:SubVar) (e':DefinedFunction DTfloat): DefinedFunction T :=
      match df with
      | Number x => Number x
      | DVector n df => DVector (fun x => df_subst (df x) v e')
      | DMatrix n m df => DMatrix (fun i j => df_subst (df i j) v e')
      | Var name =>
        if var_dec name v
        then e'
        else Var name
      | Plus l r => Plus (df_subst l v e') (df_subst r v e')
      | Times l r => Times (df_subst l v e') (df_subst r v e')
      | Minus l r => Minus (df_subst l v e') (df_subst r v e')
      | Divide l r => Divide (df_subst l v e') (df_subst r v e')
      | Exp e => Exp (df_subst e v e')
      | Log e => Log (df_subst e v e')
      | Abs e => Abs (df_subst e v e')
      | Sign e => Sign (df_subst e v e')
      | PSign e => PSign (df_subst e v e')
      | Max l r => Max (df_subst l v e') (df_subst r v e')
      | VectorElem n l i => VectorElem (df_subst l v e') i
      | MatrixElem m n l i j => MatrixElem (df_subst l v e') i j
      | VectorDot n l r =>
        VectorDot (df_subst l v e') (df_subst r v e')
      | VectorSum n e =>
        VectorSum (df_subst e v e')
      | VectorScalMult n x r =>
        VectorScalMult (df_subst x v e') (df_subst r v e')
      | MatrixScalMult n m x r =>
        MatrixScalMult (df_subst x v e') (df_subst r v e')
      | MatrixVectorMult n m l r =>
        MatrixVectorMult (df_subst l v e') (df_subst r v e')
      | MatrixMult n m p l r =>
        MatrixMult (df_subst l v e') (df_subst r v e')
      | VectorPlus n l r =>
        VectorPlus (df_subst l v e') (df_subst r v e')
      | VectorMinus n l r =>
        VectorMinus (df_subst l v e') (df_subst r v e')
      | MatrixPlus n m l r =>
        MatrixPlus (df_subst l v e') (df_subst r v e')
      | MatrixMinus n m l r =>
        MatrixMinus (df_subst l v e') (df_subst r v e')
      | VectorApply n x s l => 
        VectorApply x (df_subst s v e') (df_subst l v e')
      end.

    Definition df_substp {T} := fun e '(v,e') => @df_subst T e v  e'.

    Definition df_subst_list {T} (e:DefinedFunction T) (l:list (SubVar*DefinedFunction DTfloat)) : DefinedFunction T
      := fold_left (@df_substp T) l e.

  End subst.

    Fixpoint df_deriv {T} (df:DefinedFunction T) (v:SubVar) {struct df} : DefinedFunction T
      := (match df with
          | Number _ => Number 0
          | DVector n df => DVector (fun x => df_deriv (df x) v)
          | DMatrix n m df => DMatrix (fun i j => df_deriv (df i j) v)
          | Var x => if x == v then Number 1 else Number 0
          | Plus l r => Plus (df_deriv l v) (df_deriv r v)
          | Minus l r => Minus (df_deriv l v) (df_deriv r v)
          | Times l r => Plus (Times l (df_deriv r v))
                              (Times (df_deriv l v) r)
          | Divide l r => Divide 
                            (Minus
                               (Times (df_deriv l v) r)
                               (Times l (df_deriv r v)))
                            (Times r r)
          | Exp e => Times (df_deriv e v) (Exp e)
          | Log e => Divide (df_deriv e v) e
          | Abs e => Times (df_deriv e v) (Sign e) 
          | Sign e => Number 0
          | PSign e => Number 0
          | Max l r => Divide (Plus (Times (Minus (df_deriv r v) (df_deriv l v)) (PSign (Minus r l)))
                                    (Plus (df_deriv r v) (df_deriv l v)))
                              (Number 2)
          | VectorElem n l i => VectorElem (df_deriv l v) i
          | MatrixElem m n l i j => MatrixElem (df_deriv l v) i j
          | VectorDot n l r =>
            let ll := df_deriv l v in
            let rr := df_deriv r v in
                 defined_sum 
                           (fun (i:{x:nat|x<n}%nat) =>
                                    Plus (Times (VectorElem ll i) (VectorElem r i))
                                         (Times (VectorElem l i) (VectorElem rr i)))
          | VectorSum n l =>
            let ll := df_deriv l v in 
            defined_sum (fun (i:{x:nat|x<n}%nat) => VectorElem ll i)
          | VectorScalMult n x r => 
            let xx := df_deriv x v in 
            let rr := df_deriv r v in
            DVector (fun i =>
                         Plus (Times xx (VectorElem r i))
                              (Times x  (VectorElem rr i)))
          | MatrixScalMult n m x r => 
            let xx := df_deriv x v in 
            let rr := df_deriv r v in
            DMatrix (fun i j  =>
                         Plus (Times xx (MatrixElem r i j))
                              (Times x  (MatrixElem rr i j)))
          | MatrixVectorMult n m l r =>
            let ll := df_deriv l v in
            let rr := df_deriv r v in
            DVector (fun i =>
                         defined_sum 
                                 (fun (j:{x:nat|x<m}%nat) =>
                                    Plus (Times (MatrixElem ll i j) (VectorElem r j))

                                         (Times (MatrixElem l i j) (VectorElem rr j))))
          | MatrixMult n m p l r =>
            let ll := df_deriv l v in
            let rr := df_deriv r v in
            DMatrix (fun i k =>
                         defined_sum 
                                 (fun (j:{x:nat|x<m}%nat) =>
                                    Plus (Times (MatrixElem ll i j) (MatrixElem r j k))
                                         (Times (MatrixElem l i j) (MatrixElem rr j k))))
          | VectorPlus n l r =>
            let ll := df_deriv l v in
            let rr := df_deriv r v in
            DVector (fun i => Plus (VectorElem ll i) (VectorElem rr i))
          | VectorMinus n l r =>
            let ll := df_deriv l v in
            let rr := df_deriv r v in
            DVector (fun i => Minus (VectorElem ll i) (VectorElem rr i))
          | MatrixPlus n m l r =>
            let ll := df_deriv l v in
            let rr := df_deriv r v in
            DMatrix (fun i j => Plus (MatrixElem ll i j) (MatrixElem rr i j))
          | MatrixMinus n m l r =>
            let ll := df_deriv l v in
            let rr := df_deriv r v in
            DMatrix (fun i j => Minus (MatrixElem ll i j) (MatrixElem rr i j))
          | VectorApply n x s r => 
            let rr := df_deriv r v in
            let ss := df_deriv s v in
            DVector (fun i => Times (VectorElem rr i) (df_subst ss x (VectorElem r i)))
          end).

    Definition df_gradient {T} (df:DefinedFunction T) (lv:list SubVar) : list (DefinedFunction T)
      := map (df_deriv df) lv.

  End deriv.
  
  Section eval.
    
    Definition df_env := list (SubVar * float).

    Definition matrix_vector_mult {m n} (l : Matrix float n m)(r : Vector float m) : Vector float n :=
      fun i => vsum (fun j => (l i j) * (r j)).

    Definition matrix_mult {m n p} (l : Matrix float n m)(r : Matrix float m p) : Matrix float n p :=
      fun i k => vsum (fun j => (l i j) * (r j k)).

    Fixpoint df_eval {T} (σ:df_env) (df:DefinedFunction T) : option (definition_function_types_interp T)
      := match df with
         | Number r => Some r
         | DVector n dfs => vectoro_to_ovector (fun i => df_eval σ (dfs i))
         | DMatrix n m df => matrixo_to_omatrix (fun i j => df_eval σ (df i j))
         | Var x => lookup var_dec σ x
         | Plus l r =>
           match df_eval σ l, df_eval σ r with
           | Some l', Some r' => Some (l' + r')
           | _, _ => None
           end
         | Minus l r =>
           match df_eval σ l, df_eval σ r with
           | Some l', Some r' => Some (l' - r')
           | _, _ => None
           end
         | Times l r =>
           match df_eval σ l, df_eval σ r with
           | Some l', Some r' => Some (l' * r')
           | _, _ => None
           end
         | Divide l r =>
           match df_eval σ l, df_eval σ r with
           | Some l', Some r' => Some (l' / r')
           | _, _ => None
           end
         | Exp e => 
           match df_eval σ e with
           | Some v => Some (Fexp v)
           | _ => None
           end
         | Log e => 
           match df_eval σ e with
           | Some v => Some (Fln v) 
           | _ => None
           end
         | Abs e =>
           match df_eval σ e with
           | Some v => Some (Fabs v) 
           | _ => None
           end
         | Sign e =>
           match df_eval σ e with
           | Some v => Some (sign v)
           | _ => None
           end
         | PSign e =>
           match df_eval σ e with
           | Some v => Some (pos_sign v)
           | _ => None
           end
         | Max l r =>
           match df_eval σ l, df_eval σ r with
           | Some l', Some r' => Some (Fmax l' r')
           | _, _ => None
           end
         | VectorElem n l i => 
           match (df_eval σ l)  with
           | Some l' => Some (l' i)
           | _ => None
           end
         | MatrixElem m n l i j =>
           match (df_eval σ l)  with
           | Some l' => Some (l' i j)
           | _ => None
           end
         | VectorDot n l r =>
           match df_eval σ l, df_eval σ r with
           | Some l', Some r' => Some (vsum (fun i => (l' i) * (r' i)))
           | _, _ => None
           end
         | VectorSum n l =>
           match df_eval σ l with
           | Some l' => Some (vsum (fun i => l' i))
           | _ => None
           end
         | VectorScalMult n x r =>
           match df_eval σ x, df_eval σ r with
           | Some x', Some r' => Some (fun j => x' * (r' j))
           | _, _ => None
           end
         | MatrixScalMult n m x r =>            
           match df_eval σ x, df_eval σ r with
           | Some x', Some r' => Some (fun i j => x' * (r' i j))
           | _, _ => None
           end
         | MatrixVectorMult n m l r =>
           match df_eval σ l, df_eval σ r with
           | Some l', Some r' => Some (matrix_vector_mult l' r')
           | _, _ => None
           end
         | MatrixMult n m p l r =>
           match df_eval σ l, df_eval σ r with
           | Some l', Some r' => Some (matrix_mult l' r')
           | _, _ => None
           end
         | VectorPlus n l r =>
           match df_eval σ l, df_eval σ r with           
           | Some l', Some r' => Some (fun i => (l' i) + (r' i))
           | _, _ => None
           end
         | VectorMinus n l r =>
           match df_eval σ l, df_eval σ r with           
           | Some l', Some r' => Some (fun i => (l' i) - (r' i))
           | _, _ => None
           end
         | MatrixPlus n m l r =>
           match df_eval σ l, df_eval σ r with           
           | Some l', Some r' => Some (fun i j => (l' i j) + (r' i j))
           | _, _ => None
           end
         | MatrixMinus n m l r =>
           match df_eval σ l, df_eval σ r with           
           | Some l', Some r' => Some (fun i j => (l' i j) - (r' i j))
           | _, _ => None
           end
         | VectorApply n x s r => 
           match df_eval σ r with           
           | Some r' => vectoro_to_ovector (fun i => df_eval (cons (x, r' i) σ) s)
           | _ => None
           end
         end.

    Definition df_eval_symbolic_gradient {T} (σ:df_env) (df:DefinedFunction T) (lv:list SubVar) : option (list (definition_function_types_interp T))
      := listo_to_olist (map (df_eval σ) (df_gradient df lv)).
    
  End eval.

  Section isderiv.
    
  Context (σ:df_env).
  Context (v:SubVar).
(*
  Inductive is_deriv : DefinedFunction -> float -> Prop
    := 
    | is_deriv_Number (x : float) : is_deriv (Number x) 0
    | is_deriv_Var_eq : is_deriv (Var v) 1
    | is_deriv_Var_neq (sv : SubVar) : sv <> v -> is_deriv (Var sv) 0
    | is_deriv_Plus l l' r r' :
        is_deriv l l' ->
        is_deriv r r' ->
        is_deriv (Plus l r) (l' + r')
    | is_deriv_Minus l l' r r' :
        is_deriv l l' ->
        is_deriv r r' ->
        is_deriv (Minus l r) (l' - r')
    | is_deriv_Times l le l' r re r' :
        df_eval σ l = Some le ->
        is_deriv l l' ->
        df_eval σ r = Some re ->
        is_deriv r r' ->
        is_deriv (Times l r) ((le * r') + (l' * re))
    | is_deriv_Divide l le l' r re r' :
        df_eval σ l = Some le ->
        is_deriv l l' ->
        df_eval σ r = Some re ->
        is_deriv r r' ->
        is_deriv (Times l r)
                 (((l' * re ) - (le  * r'))
                    / (re * re))
    | is_deriv_Exp e ee e' :
        df_eval σ e = Some ee ->
        is_deriv e e' ->
        is_deriv (Exp e) (e' * (Fexp ee))
    | is_deriv_Log e ee e' :
        df_eval σ e = Some ee ->
        is_deriv e e' ->
        is_deriv (Exp e) (e' / ee)
    | is_deriv_Abs e ee e' :
        df_eval σ e = Some ee ->
        is_deriv e e' -> is_deriv (Abs e) (e' * (sign ee))
    | is_deriv_Sign (e : DefinedFunction) :
        is_deriv (Sign e) 0
    | is_deriv_PSign (e : DefinedFunction) :
        is_deriv (PSign e) 0
    | is_deriv_Max_l l le l' re r :
        df_eval σ l = Some le ->
        df_eval σ r = Some re ->
        (le > re) = true ->
        is_deriv l l' ->
        is_deriv (Max l r) l'
    | is_deriv_Max_r l le r re r' :
        df_eval σ l = Some le ->
        df_eval σ r = Some re ->
        (re >= le) = true ->
        is_deriv r r' ->
        is_deriv (Max l r) r'.
   (*
    | is_deriv_Max_eq l l' ee r r' :
        df_eval σ l = Some ee ->
        df_eval σ r = Some ee ->
        is_deriv l l' ->
        is_deriv r r' ->
        is_deriv (Max l r) ((l' + r')/2) *)

*)
  End isderiv.
  
  Section deriv2.

    Fixpoint df_eval_deriv {T} (σ:df_env) (df:DefinedFunction T) (v:SubVar) : option (definition_function_types_interp T)
      := (match df with
         | Number _ => Some 0
         | DVector n dfs => vectoro_to_ovector (fun i => df_eval_deriv σ (dfs i) v)
         | DMatrix n m df => matrixo_to_omatrix (fun i j => df_eval_deriv σ (df i j) v)
         | Var x => if x == v
                    then Some 1
                    else Some 0
         | Plus l r => 
           match df_eval_deriv σ l v, df_eval_deriv σ r v with
           | Some le, Some lr => Some (le + lr)
           | _, _ => None
           end
         | Minus l r =>
           match df_eval_deriv σ l v, df_eval_deriv σ r v with
           | Some le, Some lr => Some (le - lr)
           | _, _ => None
           end
         | Times l r =>
           match df_eval σ l, df_eval_deriv σ l v, df_eval σ r, df_eval_deriv σ r v with
           | Some le, Some ld, Some re, Some rd =>
             Some (le * rd + 
                   (ld * re))
           | _, _, _, _ => None
           end
         | Divide l r =>
           match df_eval σ l, df_eval_deriv σ l v, df_eval σ r, df_eval_deriv σ r v with
           | Some le, Some ld, Some re, Some rd =>
             Some (((ld * re) - (le * rd)) / (re * re))
           | _, _, _, _ => None
           end
         | Exp e =>
           match df_eval σ e, df_eval_deriv σ e v with
           | Some ee, Some ed => Some (ed * Fexp ee)
           | _, _  => None
           end
         | Log e =>
           match df_eval σ e, df_eval_deriv σ e v with
           | Some ee, Some ed => Some (ed / ee)
           | _, _ => None
           end
         | Abs e =>
           match df_eval σ e, df_eval_deriv σ e v with
           | Some ee, Some ed => Some (ed * (sign ee))
           | _, _ => None
           end
         | Sign e => Some 0
         | PSign e => Some 0
         | Max l r =>
           match df_eval σ l, df_eval_deriv σ l v, df_eval σ r, df_eval_deriv σ r v with
           | Some le, Some ld, Some re, Some rd =>
             if le <= re then Some rd else Some ld
           | _, _, _, _ => None
           end
         | VectorElem n l i => 
           match (df_eval_deriv σ l v)  with
           | Some l' => Some (l' i)
           | _ => None
           end
         | MatrixElem m n l i j =>
           match (df_eval_deriv σ l v)  with
           | Some l' => Some (l' i j)
           | _ => None
           end
         | VectorDot n l r =>
           match df_eval σ l, df_eval_deriv σ l v, df_eval σ r, df_eval_deriv σ r v with
           | Some le, Some ld, Some re, Some rd => 
               Some (vsum (fun j => (le j) * (rd j) + (ld j) * (re j)))
           | _, _, _, _ => None
           end
         | VectorSum n l =>
           match df_eval_deriv σ l v with
           | Some ld =>
               Some (vsum (fun j => ld j))
           | _ => None
           end
         | VectorScalMult n x r =>
           match df_eval σ x, df_eval_deriv σ x v, df_eval σ r, df_eval_deriv σ r v with
           | Some xe, Some xd, Some re, Some rd => Some (fun j => xe * (rd j) + xd * (re j))
           | _, _, _, _ => None
           end
         | MatrixScalMult n m x r =>            
           match df_eval σ x, df_eval_deriv σ x v, df_eval σ r, df_eval_deriv σ r v with
           | Some xe, Some xd, Some re, Some rd => Some (fun i j => xe * (rd i j) + xd * (re i j))
           | _, _, _, _ => None
           end
         | MatrixVectorMult n m l r =>
           match df_eval σ l, df_eval_deriv σ l v, df_eval σ r, df_eval_deriv σ r v with
           | Some le, Some ld, Some re, Some rd =>
             Some (fun i => vsum (fun j => (le i j)*(rd j) + (ld i j)*(re j)))
           | _, _, _, _ => None
           end
         | MatrixMult n m p l r =>
           match df_eval σ l, df_eval_deriv σ l v, df_eval σ r, df_eval_deriv σ r v with
           | Some le, Some ld, Some re, Some rd =>
             Some (fun i k => vsum (fun j => (le i j)*(rd j k) + (ld i j)*(re j k)))
           | _, _, _, _ => None
           end
         | VectorPlus n l r =>
           match df_eval_deriv σ l v, df_eval_deriv σ r v with           
           | Some l', Some r' => Some (fun i => (l' i) + (r' i))
           | _, _ => None
           end
         | VectorMinus n l r =>
           match df_eval_deriv σ l v, df_eval_deriv σ r v with           
           | Some l', Some r' => Some (fun i => (l' i) - (r' i))
           | _, _ => None
           end
         | MatrixPlus n m l r =>
           match df_eval_deriv σ l v, df_eval_deriv σ r v with           
           | Some l', Some r' => Some (fun i j => (l' i j) + (r' i j))
           | _, _ => None
           end
         | MatrixMinus n m l r =>
           match df_eval_deriv σ l v, df_eval_deriv σ r v with           
           | Some l', Some r' => Some (fun i j => (l' i j) - (r' i j))
           | _, _ => None
           end
         | VectorApply n x s r =>
           match df_eval σ r, df_eval_deriv σ r v with                      
           | Some re, Some rd => 
             vectoro_to_ovector 
               (fun i => match df_eval_deriv (cons (x, re i) σ) s v with
                         | Some sd => Some ((rd i) * sd)
                         | _ => None
                         end)
           | _, _ => None                                                    
           end

          end).

    Definition df_eval_gradient {T} σ (df:DefinedFunction T) (lv:list SubVar) : option (list (definition_function_types_interp T))
      := listo_to_olist (map (df_eval_deriv σ df) lv).
    
    Definition single_olist {T} (ol : option (list T)) : option (list (list T)) :=
      match ol with
      | Some l => Some (l::nil)
      | _      => None
      end.

   Definition combine_prod (l1 l2 : list (list float)) : list (list (float * float))
     := let l12 := list_prod l1 l2
        in map (fun '(x,y) => combine x y) l12.


   Definition definition_function_types_map_base (f:Type->Type) (dft:definition_function_types): Type
     := match dft with
        | DTfloat => f float
        | DTVector n => Vector (f float) n
        | DTMatrix m n => Matrix (f float) m n
        end.

   Definition definition_function_types_subgradient (dft:definition_function_types)
     := definition_function_types_map_base (fun t => list (list t)) dft.

   Fixpoint df_eval_subgradient {dft:definition_function_types} (σ:df_env) (df:DefinedFunction dft) (lv:list SubVar) : option (definition_function_types_subgradient dft)
    := (match df with
        | Number _ => Some ((map (fun v:SubVar => 0) lv) :: nil)
        | DVector n v => vectoro_to_ovector (vmap (fun x => df_eval_subgradient σ x lv) v)
        | DMatrix _ _ _ => None
         | Var x => single_olist (df_eval_gradient σ (Var x) lv)
         | Plus l r => 
           match df_eval_subgradient σ l lv, df_eval_subgradient σ r lv with
           | Some ld, Some rd => Some (map (map (fun '(x, y) => x+y)) (combine_prod ld rd))
           | _, _ => None
           end
         | Minus l r =>
           match df_eval_subgradient σ l lv, df_eval_subgradient σ r lv with
           | Some ld, Some rd => Some (map (map (fun '(x, y) => x-y)) (combine_prod ld rd))
           | _, _ => None
           end
         | Times l r =>
           match df_eval σ l, df_eval_subgradient σ l lv, df_eval σ r, df_eval_subgradient σ r lv with
           | Some le, Some ld, Some re, Some rd =>
             Some (map (map (fun '(lp,rp) => lp*re + le*rp)) (combine_prod ld rd))
           | _, _, _, _ => None
           end
         | Divide l r =>
           match df_eval σ l, df_eval_subgradient σ l lv, df_eval σ r, df_eval_subgradient σ r lv with
           | Some le, Some ld, Some re, Some rd =>
             Some (map (map (fun '(lp,rp) => (lp*re - le*rp)/(re * re))) (combine_prod ld rd))
           | _, _, _, _ => None
           end
         | Exp e =>
           match df_eval σ e, df_eval_subgradient σ e lv with
           | Some ee, Some ed => Some (map (map (fun pd => pd * Fexp ee)) ed)
           | _, _  => None
           end
         | Log e =>
           match df_eval σ e, df_eval_subgradient σ e lv with
           | Some ee, Some ed => Some (map (map (fun pd => (pd / ee))) ed)
           | _, _ => None
           end
         | Abs e =>
           match df_eval σ e, df_eval_subgradient σ e lv with
           | Some ee, Some ed => 
              if Feq ee 0 then Some (ed ++ (map (map (fun ep => -ep)) ed))
              else Some (map (map (fun ed => (ed * (sign ee)))) ed)
           | _, _ => None
           end
         | Sign e =>
           match df_eval σ e with
           | Some ee => Some ((map (fun v:SubVar => 0) lv) :: nil )
           | _ => None
           end
         | PSign e =>
           match df_eval σ e with
           | Some ee => Some ((map (fun v:SubVar => 0) lv) :: nil )
           | _ => None
           end
         | Max l r =>
           match df_eval σ l, df_eval_subgradient σ l lv, df_eval σ r, df_eval_subgradient σ r lv with
           | Some le, Some ld, Some re, Some rd =>
             if Feq le re then Some (ld ++ rd)
             else if le > re then Some ld
                  else Some rd
           | _, _, _, _ => None
           end
         | _ => None
          end).
*)
    End deriv2.

    Section deriv_deriv.

(*
      Theorem df_eval_deriv_same (σ:df_env) (df:DefinedFunction) (v:SubVar) :
        df_eval_deriv σ df v = df_eval σ (df_deriv df v).
      Proof.
        DefinedFunction_cases (induction df) Case; simpl; trivial
        ; try rewrite <- IHdf1, <- IHdf2; trivial
        ; try rewrite <- IHdf; trivial 
        ; try solve [ destruct (df_eval σ df1); trivial
                      ; destruct (df_eval_deriv σ df1 v); trivial
                      ; destruct (df_eval_deriv σ df2 v); trivial
                      ; destruct (df_eval σ df2); trivial
                    |  destruct (df_eval σ df); trivial
                       ; destruct (df_eval_deriv σ df v); trivial].
        - Case "Var"%string.
          destruct (equiv_dec v0 v); simpl; trivial.
        - case_eq (df_eval σ df1); trivial
          ; case_eq (df_eval_deriv σ df1 v); trivial
          ; case_eq (df_eval_deriv σ df2 v); trivial
          ; case_eq (df_eval σ df2); trivial.
          intros.
          destruct (Rle_dec r2 r); simpl.
          + f_equal.
            unfold sign.
            destruct (Rlt_dec (r2-r) 0); try lra.
            destruct (Rgt_dec (r2-r) 0); try lra.
            unfold pos_sign.
            destruct (Rge_dec (r-r2) 0); try lra.
            unfold pos_sign.
            destruct (Rge_dec (r-r2) 0); try lra.

          + unfold pos_sign.
            destruct (Rge_dec (r- r2) 0); try lra.
            destruct (Rgt_dec (r2-r) 0); try lra.
            f_equal.
            lra.
      Qed.
*)
      End deriv_deriv.
        
  Section max_derived.
    Definition MaxDerived (a b : DefinedFunction float) :=
      Divide (Plus (Plus (Abs (Minus b a)) b) a) (Number 2).

    Delimit Scope df_scope with df.
    
    Notation "x + y" := (Plus x y) (only printing) : df_scope.
    Notation "x - y" := (Minus x y) (only printing) : df_scope.
    Notation "x / y" := (Divide x y) (only printing) : df_scope.
    Notation "x * y" := (Times x y) (only printing) : df_scope.
    Notation "x" := (Number x) (only printing, at level 0) : df_scope.
    Notation "x" := (Var x) (only printing, at level 0) : df_scope.
    Notation "'|' x '|'" := (Abs x) (only printing, at level 0) : df_scope.
    
(*    Eval vm_compute in (df_deriv (MaxDerived (Var ("hi"%string)) (Var ("hello"%string))) "hi"%string)%df. *)
    
  End max_derived.

  Definition vlconcat {A n} (v:Vector (list A) n) : list A
    := concat (vector_to_list v).

  Definition vlconcat_map {A B n} (f:A->list B) (v:Vector A n) : list B
    := vlconcat (vmap f v).

  Definition vin {A n} (x:A) (v:Vector A n) : Prop
    := exists i, v i = x.

  Lemma vector_to_list_In {A} (x:A) {n} (v:Vector A n) :
    vin x v -> In x (vector_to_list v).
  Proof.
    induction n.
    - intros [[i pf] eqqi].
      omega.
    - intros [[i pf] eqqi].
  Admitted.

  Lemma vector_to_list_vin {A} (x:A) {n} (v:Vector A n) :
    In x (vector_to_list v) -> vin x v.
  Proof.
  Admitted.

  Section fv.

    Fixpoint df_free_variables {T} (f : DefinedFunction T) : list SubVar
      := match f with
         | Number x => nil
         | DVector n x => vlconcat_map df_free_variables x
           
         | DMatrix n m x => vlconcat_map (fun a => vlconcat_map df_free_variables a) x
         | Var name => name::nil
         | Plus l r => (df_free_variables l) ++ (df_free_variables r)
         | Minus l r => (df_free_variables l) ++ (df_free_variables r)
         | Times l r => (df_free_variables l) ++ (df_free_variables r)
         | Divide l r => (df_free_variables l) ++ (df_free_variables r)
         | Max l r => (df_free_variables l) ++ (df_free_variables r)
         | Abs e => df_free_variables e
         | Sign e => df_free_variables e
         | PSign e => df_free_variables e
         | Log e => df_free_variables e
         | Exp e => df_free_variables e
         | VectorElem n l i => df_free_variables l
         | MatrixElem m n l i j => df_free_variables l
         | VectorDot n l r => (df_free_variables l) ++ (df_free_variables r)
         | VectorSum n l => df_free_variables l
         | VectorScalMult n x r => (df_free_variables x) ++ (df_free_variables r)
         | MatrixScalMult n m x r => (df_free_variables x) ++ (df_free_variables r)
         | MatrixVectorMult n m l r => (df_free_variables l) ++ (df_free_variables r)
         | MatrixMult n m p l r => (df_free_variables l) ++ (df_free_variables r)
         | VectorPlus n l r => (df_free_variables l) ++ (df_free_variables r)
         | VectorMinus n l r => (df_free_variables l) ++ (df_free_variables r)
         | MatrixPlus n m l r => (df_free_variables l) ++ (df_free_variables r)
         | MatrixMinus n m l r => (df_free_variables l) ++ (df_free_variables r)
         | VectorApply n x s l => (df_free_variables s) ++ (df_free_variables l)
         end.

    Definition df_closed {T} (f: DefinedFunction T) : Prop
      := match df_free_variables f with
         | nil => True
         | _ => False
         end.

    Lemma df_closed_nil {T} (f: DefinedFunction T) : df_closed f -> df_free_variables f = nil.
    Proof.
      unfold df_closed.
      destruct (df_free_variables f); tauto.
    Qed.

    Lemma vmap_nth {A B : Type} (f : A -> B) {n} (v : Vector A n) i : 
      vmap f v i = f (v i).
    Proof.
      unfold vmap.
      unfold vector_fold_right_dep, vector_fold_right1_dep.
      induction n; simpl.
      - admit.
      - destruct n; simpl.
    Admitted.

    (*
    Lemma vin_vmap {A B : Type} (f : A -> B) {n} (v : Vector A n) (y : B) :
      vin y (vmap f v) -> (exists x : A, f x = y /\ vin x v).
    Proof.
      intros [i ieq].

      
      unfold vector_fold_right_dep.
      induction n; simpl; intros.
    Qed.
     *)
    Require Import FunctionalExtensionality.


    Lemma df_subst_nfree {T} (e: DefinedFunction T) (v:SubVar) (e':DefinedFunction float) :
      ~ In v (df_free_variables e) ->
      df_subst e v e' = e.
    Proof.
      DefinedFunction_cases (induction e) Case; simpl; trivial; intros nin
      ; try solve [try rewrite in_app_iff in nin
                   ; intuition congruence].
      - Case "DVector"%string.
        f_equal.
        apply functional_extensionality.
        intros x0.
        apply H.
        intros inn.
        apply nin.
        unfold vlconcat_map, vlconcat.
        apply concat_In.
        exists ((df_free_variables (x x0))).
        split; trivial.
        apply vector_to_list_In.
        
      - Case "DMatrix"%string.

      - Case "Var"%string.
        destruct (var_dec v0 v); intuition.
    Qed.

    Lemma df_eval_complete' {T} (σ:df_env) (f:DefinedFunction T) :
      incl (df_free_variables f) (domain σ) -> {v | df_eval σ f = Some v}.
    Proof.
      induction f; simpl; intros inc
      ;  try solve [rewrite <- incl_app_iff in inc
                    ; intuition
                    ; destruct X as [v1 ev1]
                    ; destruct X0 as [v2 ev2]
                    ; rewrite ev1; rewrite ev2
                    ; eauto
                   | intuition
                     ; destruct X as [v1 ev1]
                     ; rewrite ev1
                     ; eauto].
      - eauto.
      - apply in_dom_lookup_strong.
        specialize (inc v); simpl in *.
        intuition.
    Qed.

    (* This version has better computational properties *)
    Lemma df_eval_complete (σ:df_env) (f:DefinedFunction) :
      incl (df_free_variables f) (domain σ) -> {v | df_eval σ f = Some v}.
    Proof.
      case_eq (df_eval σ f); simpl.
      - intros r ?? ; exists r; eauto.
      - intros ? inc.
        destruct (df_eval_complete' _ _ inc); congruence.
    Defined.

    Lemma df_eval_none  (σ:df_env) (f:DefinedFunction) :
      df_eval σ f = None ->
      {v | In v (df_free_variables f) /\ ~ In v (domain σ)}.
    Proof.
      intros.
      destruct (incl_dec (df_free_variables f) (domain σ)).
      - destruct (df_eval_complete _ _ i); congruence.
      - apply (nincl_exists) in n; trivial.
    Qed.

    (* Either we can evaluate df or we are missing a variable definition.
       Note that this theorem may fail to hold if we change the definition of 
       division to make it partial.
     *)
    Lemma df_eval_compute (σ:df_env) (f:DefinedFunction) :
      {v | df_eval σ f = Some v} + {x | In x (df_free_variables f) /\ ~ In x (domain σ)}.
    Proof.
      case_eq (df_eval σ f); simpl.
      - eauto.
      - intros H; apply df_eval_none in H; eauto.
    Defined.

    Lemma df_eval_closed (f:DefinedFunction) :
      df_closed f -> {v | df_eval nil f = Some v}.
    Proof.
      intros c.
      apply (df_eval_complete nil f).
      rewrite df_closed_nil by trivial.
      simpl; reflexivity.
    Defined.        

    Lemma df_eval_lookup_on (σ₁ σ₂:df_env) (f:DefinedFunction) :
      lookup_equiv_on (df_free_variables f) σ₁ σ₂ ->
      df_eval σ₁ f = df_eval σ₂ f.
    Proof.
      intros lookeq.
      induction f; simpl in *; trivial
      ;  try solve [apply lookup_equiv_on_dom_app in lookeq; intuition
                    ; rewrite H1, H2; trivial
                   | rewrite IHf; trivial].
      - apply lookeq; simpl; tauto.
    Qed.
*)
  End fv.

  Section apply.

    Fixpoint df_apply {T} (e: DefinedFunction T) (args: SubVar -> DefinedFunction float) : DefinedFunction T :=
      match e with
      | Number x => Number x
      | DVector n df => DVector (fun x => df_apply (df x) args)
      | DMatrix n m df => DMatrix (fun i j => df_apply (df i j) args)
      | Var name => args name
      | Plus l r => Plus (df_apply l args) (df_apply r args)
      | Times l r => Times (df_apply l args) (df_apply r args)
      | Minus l r => Minus (df_apply l args) (df_apply r args)
      | Divide l r => Divide (df_apply l args) (df_apply r args)
      | Exp e => Exp (df_apply e args)
      | Log e => Log (df_apply e args)
      | Abs e => Abs (df_apply e args)
      | Sign e => Sign (df_apply e args)
      | PSign e => PSign (df_apply e args)
      | Max l r => Max (df_apply l args) (df_apply r args)
      | VectorElem n l i => VectorElem (df_apply l args) i
      | MatrixElem m n l i j => MatrixElem (df_apply l args) i j
      | VectorDot n l r =>
        let ll := df_apply l args in
        let rr := df_apply r args in
        defined_sum 
          (fun (i:{x:nat|x<n}%nat) =>
             (Times (VectorElem ll i) (VectorElem rr i)))
      | VectorSum n l =>
        let ll := df_apply l args in
        defined_sum 
          (fun (i:{x:nat|x<n}%nat) => VectorElem ll i)
      | VectorScalMult n x r => 
        let xx := df_apply x args in 
        let rr := df_apply r args in
        DVector (fun i => Times xx (VectorElem rr i))
      | MatrixScalMult n m x r => 
        let xx := df_apply x args in 
        let rr := df_apply r args in
        DMatrix (fun i j  => Times xx (MatrixElem rr i j))
      | MatrixVectorMult n m l r =>
        let ll := df_apply l args in
        let rr := df_apply r args in
        DVector (fun i =>
                   defined_sum 
                     (fun (j:{x:nat|x<m}%nat) =>
                        (Times (MatrixElem ll i j) (VectorElem rr j))))
                                      
      | MatrixMult n m p l r =>
        let ll := df_apply l args in
        let rr := df_apply r args in
        DMatrix (fun i k =>
                   defined_sum 
                     (fun (j:{x:nat|x<m}%nat) =>
                              (Times (MatrixElem ll i j) (MatrixElem rr j k))))
      | VectorPlus n l r =>
        let ll := df_apply l args in
        let rr := df_apply r args in
        DVector (fun i => Plus (VectorElem ll i) (VectorElem rr i))
      | VectorMinus n l r =>
        let ll := df_apply l args in
        let rr := df_apply r args in
        DVector (fun i => Minus (VectorElem ll i) (VectorElem rr i))
      | MatrixPlus n m l r =>
        let ll := df_apply l args in
        let rr := df_apply r args in
        DMatrix (fun i j => Plus (MatrixElem ll i j) (MatrixElem rr i j))
      | MatrixMinus n m l r =>
        let ll := df_apply l args in
        let rr := df_apply r args in
        DMatrix (fun i j => Minus (MatrixElem ll i j) (MatrixElem rr i j))
      | VectorApply n x s l => 
        VectorApply x (df_apply s args) (df_apply l args)

      end.

 End apply.

End DefinedFunctions.

Section real_pfs.

  Import Reals.
  Local Existing Instance floatish_R.
  
(*
  Lemma MaxDerivedMax_eq (a b : DefinedFunction float) :
    forall σ, df_eval σ (Max a b) = df_eval σ (MaxDerived a b).
  Proof.
    simpl; intros σ.
    destruct (df_eval σ a); destruct (df_eval σ b); trivial.
    f_equal.
    autorewrite with Rarith in *.
    destruct (Rle_dec f f0).
    - rewrite Rmax_right by trivial.
      rewrite Rabs_pos_eq by lra.
      lra.
    - rewrite Rmax_left by lra.
      rewrite Rabs_minus_sym.
      rewrite Rabs_pos_eq by lra.
      lra.
  Qed.
*)
End real_pfs.

(*
  Section FreeVariablesExample.
    (* We need ot open the string scope in order to use "a" as a string. *)
    Open Scope string_scope.
    Theorem ex1 : (df_free_variables (Plus (Var "a") (Var "b"))) = "a"::"b"::nil.
    Proof.
      (* Reflexivity doesn't need syntactically identical things on either side of =. 
       * It suffices that the left-hand side beta-reduced to the right-hand side. *)
      reflexivity.
    Qed.

    Close Scope string_scope.

  End FreeVariablesExample.
*)            


Tactic Notation "DefinedFunction_cases" tactic(first) ident(c) :=
  first;
  [ Case_aux c "Number"%string
  | Case_aux c "DVector"%string
  | Case_aux c "DMatrix"%string
  | Case_aux c "Var"%string
  | Case_aux c "Plus"%string
  | Case_aux c "Minus"%string
  | Case_aux c "Times"%string
  | Case_aux c "Divide"%string
  | Case_aux c "Exp"%string
  | Case_aux c "Log"%string
  | Case_aux c "Abs"%string
  | Case_aux c "Sign"%string
  | Case_aux c "PSign"%string
  | Case_aux c "Max"%string
  | Case_aux c "VectorDot"%string
  | Case_aux c "VectorSum"%string
  | Case_aux c "VectorElem"%string
  | Case_aux c "MatrixElem"%string
  | Case_aux c "MatrixVectorMult"%string
  | Case_aux c "MatrixMult"%string
  | Case_aux c "VectorPlus"%string
  | Case_aux c "VectorMinus"%string
  | Case_aux c "MatrixPlus"%string
  | Case_aux c "MatrixMinus"%string
  | Case_aux c "VectorScalMult"%string
  | Case_aux c "MatrixScalMult"%string
  | Case_aux c "VectorApply"%string].
