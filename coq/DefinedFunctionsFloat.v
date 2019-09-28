Require Import String.
Require Import EquivDec.
Require Import RelationClasses.
Require Import List.
Require Import Lra.
Require Import Omega.
Require Import Flocq.IEEE754.Binary.
Require Import Flocq.IEEE754.Bits.

Require Import Utils.

(* Declare Scope df_scope. *)

(* in pytorch relu(f)' if f <=0 then 0 else f' *)
(* in pytorch abs(f)' = f'*sign(f) *)
(* max(a,b)' = if a<=b then b' else a' *)
(* min(a,b)' = if a>=b then b' else a' *)
(* x = Variable(torch.tensor(0.0), requires_grad=True) *)
(* z = torch.min(x*x, x); z.backward(); print(x.grad) = 1 *)
(* x.grad.data.zero_() between tests *)
(* relu behaves like max(x, 0), not max(0,x), i.e. relu(x)' at 0 = 0 *)


(* float ops:
  Definition b64_opp : binary64 → binary64 := Bopp 53 1024 unop_nan_pl64.
  Definition b64_abs : binary64 → binary64 := Babs 53 1024 unop_nan_pl64.
  Definition b64_sqrt : mode → binary64 → binary64 := Bsqrt _ _ Hprec Hprec_emax unop_nan_pl64.
  Definition b64_plus : mode → binary64 → binary64 → binary64 := Bplus _ _ Hprec Hprec_emax binop_nan_pl64.
  Definition b64_minus : mode → binary64 → binary64 → binary64 := Bminus _ _ Hprec Hprec_emax binop_nan_pl64.
  Definition b64_mult : mode → binary64 → binary64 → binary64 := Bmult _ _ Hprec Hprec_emax binop_nan_pl64.
  Definition b64_div : mode → binary64 → binary64 → binary64 := Bdiv _ _ Hprec Hprec_emax binop_nan_pl64.
  Definition b64_compare : binary64 → binary64 → option comparison := Bcompare 53 1024.
*)

  Definition float : Set := binary64.

  Definition Fzero := B754_zero 53 1024 false.
  Definition Fopp (x : float) := b64_opp x.
  Definition Fplus (x y : float) := b64_plus mode_NE x y.
  Definition Fminus (x y : float) := b64_minus mode_NE x y.
  Definition Fmult (x y : float) := b64_mult mode_NE x y.
  Definition Fdiv (x y : float) := b64_div mode_NE x y.  
  Definition Fsqrt (x : float) := b64_sqrt mode_NE x.
  
  (* following function will be defined only in OCaml *)
  Axiom FPI : float.
  Axiom exp : float -> float.
  Axiom ln : float -> float.
  Axiom sin : float -> float.
  Axiom cos : float -> float.  

  Lemma prec_gt_0_ : FLX.Prec_gt_0 53.
  Proof.
    red.
    omega.
  Qed.

  Lemma lt53_1024 : (53 < 1024)%Z.
  Proof.
    omega.
  Qed.
  
  Definition Z2F (i:Z) := binary_normalize 53 1024 prec_gt_0_ lt53_1024 mode_NE i 0 false.

  Notation "0" := (Fzero) : float.
  Notation "1" := (Bone 53 1024 prec_gt_0_ lt53_1024) : float.
  Notation "2" := (Z2F 2) : float.
  Notation "- x" := (Fopp x) (at level 35, right associativity) : float.
  Notation "x + y" := (Fplus x y) (at level 50, left associativity) : float.
  Notation "x - y" := (Fminus x y) (at level 50, left associativity) : float.
  Notation "x * y" := (Fmult x y) (at level 40, left associativity) : float.
  Notation "x / y" := (Fdiv x y) (at level 40, left associativity) : float.

  Open Scope float.
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

    Inductive DefinedFunction : Set :=
    | Number (x : float)
    | Var (v : SubVar)
    | Plus (l r : DefinedFunction)
    | Minus (l r : DefinedFunction)
    | Times (l r : DefinedFunction)
    | Divide (l r : DefinedFunction)
    | Exp (e : DefinedFunction)
    | Log (e : DefinedFunction)
    | Abs (e : DefinedFunction)
    | Sign (e : DefinedFunction)
    | PSign (e : DefinedFunction)
    | Max (l r : DefinedFunction).

  End Definitions.


  Tactic Notation "DefinedFunction_cases" tactic(first) ident(c) :=
  first;
  [ Case_aux c "Number"%string
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
  | Case_aux c "Max"%string].

(*
  Definition pos_sign (e:R)
    := (if Rge_dec e 0 then 1 else -1)%R.

  Definition neg_sign (e:R)
    := (if Rle_dec e 0 then -1 else 1)%R.

  Definition sign (e:R)
    := (if Rlt_dec e 0 then -1 else 
        if Rgt_dec e 0 then 1 else 0)%R.

  Inductive comparison : Set :=  Eq : comparison | Lt : comparison | Gt : comparison

 *)

  Definition pos_sign (e:float)
    := (match b64_compare e 0 with
          | Some Lt =>  0 - 1
          | _  => 1
        end).

  Definition neg_sign (e:float)
    := (match b64_compare e 0 with
          | Some Gt => b64_opp 1
          | _ => 1
       end).

  Definition sign (e:float)
    := (match b64_compare e 0 with
          | Some Lt => b64_opp 1
          | Some Gt => 1
          | _ => 0
       end).                               

  Definition Fmax (x y:float)
    := (match b64_compare x y with
          | Some Lt => y
          | _ => x
       end).                               

  Definition Fgt (x y:float)
    := (match b64_compare x y with
          | Some Gt => true
          | _ => false
       end).                               

  Definition Flt (x y:float)
    := (match b64_compare x y with
          | Some Lt => true
          | _ => false
       end).                               

  Definition Fge (x y:float)
    := (match b64_compare x y with
          | Some Gt => true
          | Some Eq => true                         
          | _ => false
       end).                               

  Definition Fle (x y:float)
    := (match b64_compare x y with
          | Some Lt => true
          | Some Eq => true                         
          | _ => false
       end).                               

  Definition Feq (x y:float)
    := (match b64_compare x y with
          | Some Eq => true
          | _ => false
       end).                               

  Notation "x < y" := (Flt x y)  : float.
  Notation "x > y" := (Fgt x y)  : float.
  Notation "x <= y" := (Fle x y) : float.
  Notation "x >= y" := (Fge x y) : float.

  Definition df_plus (df1 df2 : DefinedFunction) : DefinedFunction :=
    Plus df1 df2.

  Definition df_times (df1 df2 : DefinedFunction) : DefinedFunction :=
    Times df1 df2.
  
  Section deriv.
    Fixpoint df_deriv (df:DefinedFunction) (v:SubVar) : DefinedFunction
      := (match df with
         | Number _ => Number 0
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
          end).

    Definition df_gradient (df:DefinedFunction) (lv:list SubVar) : list DefinedFunction
      := map (df_deriv df) lv.
    
  End deriv.
  
  Section eval.
    
    Definition df_env := list (SubVar * float).

    Fixpoint df_eval (σ:df_env) (df:DefinedFunction) : option float
      := match df with
         | Number r => Some r
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
           | Some v => Some (exp v)
           | _ => None
           end
         | Log e => 
           match df_eval σ e with
           | Some v => Some (ln v) 
           | _ => None
           end
         | Abs e =>
           match df_eval σ e with
           | Some v => Some (b64_abs v) 
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
         end.

    Definition df_eval_symbolic_gradient (σ:df_env) (df:DefinedFunction) (lv:list SubVar) : option (list float)
      := listo_to_olist (map (df_eval σ) (df_gradient df lv)).
    
  End eval.

  Section isderiv.
    
  Context (σ:df_env).
  Context (v:SubVar).

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
        is_deriv (Exp e) (e' * (exp ee))
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


  End isderiv.
  
  Section deriv2.

    Fixpoint df_eval_deriv (σ:df_env) (df:DefinedFunction) (v:SubVar) : option float
      := (match df with
         | Number _ => Some 0
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
           | Some ee, Some ed => Some (ed * exp ee)
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
          end).

    Definition df_eval_gradient σ (df:DefinedFunction) (lv:list SubVar) : option (list float)
      := listo_to_olist (map (df_eval_deriv σ df) lv).
    
    Definition single_olist (ol : option (list float)) : option (list (list float)) :=
      match ol with
      | Some l => Some (l::nil)
      | _      => None
      end.

   Definition combine_prod (l1 l2 : list (list float)) : list (list (float * float))
     := let l12 := list_prod l1 l2
        in map (fun '(x,y) => combine x y) l12.

    Fixpoint df_eval_subgradient (σ:df_env) (df:DefinedFunction) (lv:list SubVar) : option (list (list float))
      := (match df with
         | Number _ => Some ( (map (fun v:SubVar => 0) lv) :: nil )
         | Var x => single_olist (df_eval_gradient σ df lv)
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
           | Some ee, Some ed => Some (map (map (fun pd => pd * exp ee)) ed)
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
          end).

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
    Definition MaxDerived (a b : DefinedFunction) :=
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
    
(*
    Lemma MaxDerivedMax_eq (a b : DefinedFunction) :
      forall σ, df_eval σ (Max a b) = df_eval σ (MaxDerived a b).
    Proof.
      simpl; intros σ.
      destruct (df_eval σ a); destruct (df_eval σ b); trivial.
      f_equal.
      destruct (Rle_dec r r0).
      - rewrite Rmax_right by trivial.
        rewrite Rabs_pos_eq by lra.
        lra.
      - rewrite Rmax_left by lra.
        rewrite Rabs_minus_sym.
        rewrite Rabs_pos_eq by lra.
        lra.
    Qed.
*)
  End max_derived.

  Section fv.

    Fixpoint df_free_variables (f : DefinedFunction) : list SubVar
      := match f with
         | Number x => nil
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

         end.

    Definition df_closed (f: DefinedFunction) : Prop
      := match df_free_variables f with
         | nil => True
         | _ => False
         end.

    Lemma df_closed_nil (f: DefinedFunction) : df_closed f -> df_free_variables f = nil.
    Proof.
      unfold df_closed.
      destruct (df_free_variables f); tauto.
    Qed.

    Lemma df_eval_complete' (σ:df_env) (f:DefinedFunction) :
      incl (df_free_variables f) (domain σ) -> {v | df_eval σ f = Some v}.
    Proof.
      induction f; simpl; intros inc
      ;  try solve [rewrite <- incl_app_iff in inc
                    ; intuition
                    ; destruct H1 as [v1 ev1]
                    ; destruct H2 as [v2 ev2]
                    ; rewrite ev1; rewrite ev2
                    ; eauto
                   | intuition
                     ; destruct H as [v1 ev1]
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

  End fv.

  Section apply.
    
    Fixpoint df_apply (e: DefinedFunction) (args: SubVar -> DefinedFunction) :=
      match e with
      | Number x => Number x
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
      end.
    
 End apply.

    
  Section subst.
    Fixpoint df_subst (e: DefinedFunction) (v:SubVar) (e':DefinedFunction) :=
      match e with
      | Number x => Number x
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
      end.


   Definition df_substp := fun e '(v,e') => df_subst e v  e'.

   Definition df_subst_list (e:DefinedFunction) (l:list (SubVar*DefinedFunction)) : DefinedFunction
      := fold_left df_substp l e.


    Lemma df_subst_nfree (e: DefinedFunction) (v:SubVar) (e':DefinedFunction) :
      ~ In v (df_free_variables e) ->
      df_subst e v e' = e.
    Proof.
      induction e; simpl; trivial; intros nin
      ; try solve [try rewrite in_app_iff in nin
                   ; intuition congruence].
      - destruct (var_dec v0 v); intuition.
    Qed.

    End subst.


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
  | Case_aux c "Max"%string].
