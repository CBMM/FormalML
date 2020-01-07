Require Import String.
Require Import RelationClasses.
Require Import EquivDec.
Require Import Streams.
Require Import List.
Require Import ListAdd.
Require Import Rbase Rtrigo Rpower Rbasic_fun.
Require Import DefinedFunctions.
Require Import Lra Omega.

Require Import Floatish Utils.

Section GenNN.

  Context {floatish_impl:floatish}.
  
  Local Open Scope float.

  Definition UnitDefinedFunction := @DefinedFunction floatish_impl UnitAnn.

  Record FullNN : Type := mkNN { ldims : list nat; param_var : SubVar; 
                                 f_activ : UnitDefinedFunction DTfloat; f_loss : UnitDefinedFunction DTfloat }.

  Definition mkSubVarVector (v : SubVar) (n : nat) : UnitDefinedFunction (DTVector n) :=
    DVector tt (fun i => Var (Sub v (proj1_sig i), DTfloat) tt).

  Definition mkVarVector (v : SubVar) (n : nat) : UnitDefinedFunction (DTVector n) :=
    Var (v, DTVector n) tt.

  Definition mkSubVarMatrix (v : SubVar) (n m : nat) : UnitDefinedFunction (DTMatrix n m) :=
    DMatrix tt (fun i j => Var (Sub (Sub v (proj1_sig i)) (proj1_sig j), DTfloat) tt).

  Definition mkVarMatrix (v : SubVar) (n m : nat) : UnitDefinedFunction (DTMatrix n m) :=
    Var (v, DTMatrix n m) tt.

  Definition unique_var (df : DefinedFunction DTfloat) : option SubVar :=
    let fv := nodup var_dec (df_free_variables df) in
    match fv with
    | nil => None
    | v :: nil => Some v
    | _ => None
    end.   

  Definition activation (df : DefinedFunction DTfloat) (vec : list (DefinedFunction DTfloat)) : option (list (DefinedFunction DTfloat)) :=
    match unique_var df with
    | Some v => Some (map (fun dfj => df_subst df (v, DTfloat) dfj) vec)
    | None => None
    end.

  Definition create_activation_fun (df : DefinedFunction DTfloat) : option (DefinedFunction DTfloat -> DefinedFunction DTfloat) :=
    match unique_var df with
    | Some v => Some (fun val => df_subst df (v, DTfloat) val)
    | None => None
    end.

  Definition mkNN2 (n1 n2 n3 : nat) (ivar wvar : SubVar) (f_activ : DefinedFunction DTfloat) (f_activ_var : SubVar) : (DefinedFunction (DTVector n3)) :=
    let mat1 := mkSubVarMatrix (Sub wvar 1) n2 n1 in
    let mat2 := mkSubVarMatrix (Sub wvar 2) n3 n2 in
    let ivec := mkVarVector ivar n1 in
    let N1 := VectorApply tt f_activ_var f_activ (MatrixVectorMult  tt mat1 ivec) in 
    VectorApply tt f_activ_var f_activ (MatrixVectorMult tt mat2 N1).

  Definition mkVarNN2 (n1 n2 n3 : nat) (ivar wvar : SubVar) (f_activ : DefinedFunction DTfloat) (f_activ_var : SubVar) : (DefinedFunction (DTVector n3)) :=
    let mat1 := mkVarMatrix (Sub wvar 1) n2 n1 in
    let mat2 := mkVarMatrix (Sub wvar 2) n3 n2 in
    let ivec := mkVarVector ivar n1 in
    let N1 := VectorApply tt f_activ_var f_activ (MatrixVectorMult tt mat1 ivec) in 
    VectorApply tt f_activ_var f_activ (MatrixVectorMult tt mat2 N1).

  Definition mkNN_bias_step (n1 n2 : nat) (ivec : DefinedFunction (DTVector n1)) 
             (mat : DefinedFunction (DTMatrix n2 n1)) 
             (bias : DefinedFunction (DTVector n2)) 
             (f_activ_var : SubVar) (f_activ : DefinedFunction DTfloat) 
              : UnitDefinedFunction (DTVector n2) :=
    VectorApply tt f_activ_var f_activ (VectorPlus tt (MatrixVectorMult tt mat ivec) bias).

 Definition mkNN2_bias (n1 n2 n3 : nat) (ivar wvar : SubVar) (f_activ : DefinedFunction DTfloat) (f_activ_var : SubVar) : DefinedFunction (DTVector n3) :=
    let mat1 := mkSubVarMatrix (Sub wvar 1) n2 n1 in
    let b1 := mkSubVarVector (Sub wvar 1) n2 in
    let mat2 := mkSubVarMatrix (Sub wvar 2) n3 n2 in
    let b2 := mkSubVarVector (Sub wvar 2) n3 in
    let ivec := mkVarVector ivar n1 in
    let N1 := mkNN_bias_step n1 n2 ivec mat1 b1 f_activ_var f_activ in
    mkNN_bias_step n2 n3 N1 mat2 b2 f_activ_var f_activ.

 Definition mkNN2_Var_bias (n1 n2 n3 : nat) (ivar wvar : SubVar) (f_activ : DefinedFunction DTfloat) (f_activ_var : SubVar) : DefinedFunction (DTVector n3) :=
    let mat1 := mkVarMatrix (Sub wvar 1) n2 n1 in
    let b1 := mkVarVector (Sub wvar 1) n2 in
    let mat2 := mkVarMatrix (Sub wvar 2) n3 n2 in
    let b2 := mkVarVector (Sub wvar 2) n3 in
    let ivec := mkVarVector ivar n1 in
    let N1 := mkNN_bias_step n1 n2 ivec mat1 b1 f_activ_var f_activ in
    mkNN_bias_step n2 n3 N1 mat2 b2 f_activ_var f_activ.

 Lemma vector_float_map_last_rewrite {B nvlist1 n2 v n1} :
   (DTVector (last ((@domain _ B) nvlist1) n2)) = 
   (DTVector (last (domain((n2, v) :: nvlist1)) n1)).
 Proof.
   rewrite domain_cons.
   rewrite last_cons.
   reflexivity.
 Qed.

  Fixpoint mkNN_gen_0 (n1:nat) (nvlist : list (nat * SubVar)) 
           (ivec : (DefinedFunction (DTVector n1)))
           (f_activ_var : SubVar ) (f_activ : DefinedFunction DTfloat) :
    DefinedFunction (DTVector (last (domain nvlist) n1))
:= 
    match nvlist with
    | nil => ivec
    | cons (n2,v) nvlist1 => 
      let mat := mkSubVarMatrix v n2 n1 in
      let b := mkSubVarVector v n2 in
      let N := mkNN_bias_step n1 n2 ivec mat b f_activ_var f_activ in
      eq_rect _ DefinedFunction (mkNN_gen_0 n2 nvlist1 N f_activ_var f_activ) _ vector_float_map_last_rewrite
    end.

  Fixpoint mkNN_Var_gen_0 (n1:nat) (nvlist : list (nat * SubVar)) 
           (ivec : (DefinedFunction (DTVector n1)))
           (f_activ_var : SubVar ) (f_activ : DefinedFunction DTfloat) :
    DefinedFunction (DTVector (last (domain nvlist) n1))
:= 
    match nvlist with
    | nil => ivec
    | cons (n2,v) nvlist1 => 
      let mat := mkVarMatrix v n2 n1 in
      let b := mkVarVector v n2 in
      let N := mkNN_bias_step n1 n2 ivec mat b f_activ_var f_activ in
      eq_rect _ DefinedFunction (mkNN_Var_gen_0 n2 nvlist1 N f_activ_var f_activ) _ vector_float_map_last_rewrite
    end.


  Program Definition mkNN_gen (n1:nat) (nlist : list nat) (ivar wvar f_activ_var : SubVar) 
             (f_activ : DefinedFunction DTfloat) : 
    DefinedFunction (DTVector (last nlist n1)) :=
    let vlist := map (fun i => Sub wvar i) (seq 1 (length nlist)) in
    let ivec := mkVarVector ivar n1 in
    eq_rect _ DefinedFunction
            (mkNN_gen_0 n1 (combine nlist vlist) ivec f_activ_var f_activ) _ _.
  Next Obligation.
    f_equal.
    f_equal.
    rewrite combine_domain_eq; trivial.
    now rewrite map_length, seq_length.
  Qed.

  Program Definition mkNN_Var_gen (n1:nat) (nlist : list nat) (ivar wvar f_activ_var : SubVar) 
             (f_activ : DefinedFunction DTfloat) : 
    DefinedFunction (DTVector (last nlist n1)) :=
    let vlist := map (fun i => Sub wvar i) (seq 1 (length nlist)) in
    let ivec := mkVarVector ivar n1 in
    eq_rect _ DefinedFunction
            (mkNN_Var_gen_0 n1 (combine nlist vlist) ivec f_activ_var f_activ) _ _.
  Next Obligation.
    f_equal.
    f_equal.
    rewrite combine_domain_eq; trivial.
    now rewrite map_length, seq_length.
  Qed.

  Definition softmax {n:nat} (NN : DefinedFunction (DTVector n)) : UnitDefinedFunction (DTVector n) :=
    let expvar := Name "expvar" in
    let NNexp := VectorApply tt expvar (Exp tt (Var (expvar, DTfloat) tt)) NN in
    let NNexpscale := Divide tt (Number tt 1) (VectorSum tt NNexp) in
    VectorScalMult tt NNexpscale NNexp.

  Definition L2loss (nnvar ovar : SubVar) : UnitDefinedFunction DTfloat :=
    Square tt ( Minus tt (Var (nnvar, DTfloat) tt) (Var (ovar, DTfloat) tt) ).

  Definition L1loss (nnvar ovar : SubVar) : UnitDefinedFunction DTfloat :=
    Abs tt (Minus tt (Var (nnvar, DTfloat) tt) (Var (ovar, DTfloat) tt)).

  Record testcases : Type := mkTest {ninput: nat; noutput: nat; ntest: nat; 
                                     datavec : Vector ((Vector float ninput) * (Vector float noutput)) ntest}.

  Definition NNinstance {ninput noutput : nat} (ivar : SubVar) (f_loss : DefinedFunction DTfloat)
             (f_loss_NNvar f_loss_outvar : SubVar) 
             (NN : UnitDefinedFunction (DTVector noutput)) (σ:df_env) 
             (data: (Vector float ninput) * (Vector float noutput))
             : option float :=
    let ipair := mk_env_entry (ivar, DTVector ninput) (fst data) in
    df_eval (cons ipair σ) (Lossfun tt f_loss_NNvar f_loss_outvar f_loss NN (snd data)).

  (*
  Lemma NNinstance_unique_var (n1 n2 n3 : nat) (ivar : SubVar) (f_loss : DefinedFunction DTfloat) 
        (NN2 : DefinedFunction (DTVector n3)) (inputs : (list float)) 
        (outputs : Vector float n3) (v:SubVar) :
    unique_var f_loss = Some v ->
    NNinstance n1 n2 n3 ivar f_loss NN2 inputs outputs =
    Some (
        let ipairs := (list_prod (map (fun n => (Sub ivar n)) (seq 1 n1))
                                 (map Number inputs)) in
        let losses := VectorMinus (df_subst_list NN2 ipairs) 
                                  (DVector (vmap Number outputs)) in
        (VectorSum (VectorApply v f_loss losses))
      ).
  Proof.
    unfold NNinstance.
    intros.
    rewrite H.
    reflexivity.
  Qed.

  Lemma NNinstance_None (n1 n2 n3 : nat) (ivar : SubVar) (f_loss : DefinedFunction DTfloat) 
        (NN2 : DefinedFunction (DTVector n3)) (inputs : (list float)) 
        (outputs : Vector float n3) :
    unique_var f_loss = None ->
    NNinstance n1 n2 n3 ivar f_loss NN2 inputs outputs = None.
  Proof.
    unfold NNinstance.
    intros.
    now rewrite H.
  Qed.
   *)

(*  Local Existing Instance floatish_interval. *)
  
  Definition lookup_list (σ:df_env) (lvar : list SubVar) : option (list float) :=
    listo_to_olist (map (fun v => (vartlookup σ (v, DTfloat)):option float) lvar).

  Definition combine_with {A:Type} {B:Type} {C:Type} (f: A -> B -> C ) (lA : list A) (lB : list B) : list C :=
    map (fun '(a, b) => f a b) (combine lA lB).

  Definition combine3_with {A:Type} {B:Type} {C:Type} {D:Type} (f: A -> B -> C -> D) (lA : list A) (lB : list B) (lC : list C) : list D :=
    map (fun '(a, bc) => f a (fst bc) (snd bc)) (combine lA (combine lB lC)).

  Fixpoint streamtake (n : nat) {A : Type} (st : Stream A) : (list A) * (Stream A) :=
    match n with
    | 0 => (nil, st)
    | S n' => let rst := streamtake n' (Streams.tl st) in
              ((Streams.hd st)::(fst rst), snd rst)
    end.

  Lemma streamtake_n (n : nat) (A : Type) (st : Stream A) :
    length (fst (streamtake n st)) = n.
  Proof.
    generalize st.
    induction n.
    reflexivity.
    intros.
    simpl.
    f_equal.
    specialize IHn with (st := Streams.tl st0).
    apply IHn.
  Qed.

  Fixpoint env_update_first (l:df_env) (an:env_entry_type) : df_env
    := match l with 
       | nil => nil
       | fv::os => if (projT1 an) == (projT1 fv) then an::os 
                   else fv::(env_update_first os an)
       end.

  Definition env_update_list (l up:df_env) : df_env
    := fold_left (env_update_first) up l.

  Definition optimize_step 
             (step : nat) (df : DefinedFunction DTfloat) (σ:df_env) (lvar : list SubVar)
             (noise_st : Stream float) : (option df_env)*(Stream float) :=
    let lvart:list var_type := (map (fun v => (v, DTfloat)) lvar) in
    let ogradvec := df_eval_gradient σ df lvart in
    let alpha := 1 / (FfromZ (Z.of_nat (S step))) in
    let '(lnoise, nst) := streamtake (length lvar) noise_st in
    let olvals := lookup_list σ lvar in
    (match (ogradvec, olvals) with
     | (Some gradvec, Some lvals) => 
       Some (env_update_list 
               σ 
               (map (fun '(v,e) => mk_env_entry (v, DTfloat) (e:float))
                    (combine lvar (combine3_with 
                                     (fun val grad noise => val - alpha*(grad + noise))
                                     lvals gradvec lnoise))))
     | (_, _) => None
     end, nst).

  Fixpoint get_noise_vector (n: nat) (noise_st: Stream float) : 
    (Vector float n) * (Stream float) :=
    match n with
    | 0 => (vnil, noise_st)
    | S n' => 
      let noise := Streams.hd noise_st in
      let nst := Streams.tl noise_st in
      let '(vec, nst') := get_noise_vector n' nst in
      (vcons noise vec, nst')
    end.

  Fixpoint get_noise_matrix (n m: nat) (noise_st: Stream float) :
    (Matrix float n m) * (Stream float) :=
    let '(vec, nst) := get_noise_vector m noise_st in
    match n with
    | 0 => (fun i => vec, nst)
    | S n' => 
      let '(mat, nst') := get_noise_matrix n' m nst in
      (vcons vec mat, nst')
    end.

  Definition get_noise (t:definition_function_types) (noise_st:Stream float) : 
    (definition_function_types_interp t) * (Stream float) :=
    match t with
    | DTfloat => (Streams.hd noise_st, Streams.tl noise_st)
    | DTVector n => get_noise_vector n noise_st
    | DTMatrix m n => get_noise_matrix m n noise_st
    end.

    Program Definition update_val_gradenv (grad_env:df_env) (x:var_type) (alpha:float) :=
      (match snd x as y return definition_function_types_interp y ->
                               definition_function_types_interp y ->
                               definition_function_types_interp y with
       | DTfloat =>  fun val noise => 
                       match vartlookup grad_env x with
                       | Some grad => val - alpha * ((_ grad) + noise)
                       | _ => val
                       end
       | DTVector n => fun val noise =>
                         match vartlookup grad_env x with
                         | Some grad => 
                           fun i => 
                             (val i) - alpha * (((_ grad) i) + (noise i))
                         | _ => val
                         end
       | DTMatrix m n => fun val noise =>
                           match vartlookup grad_env x with
                           | Some grad =>
                             fun i j =>
                               (val i j) - alpha * (((_ grad) i j) + (noise i j))
                         | _ => val
                         end
       end).

  Definition update_entry (entry: env_entry_type) (grad_env:df_env) (alpha:float) (noise_st : Stream float) : (env_entry_type*Stream float) :=
    let x := projT1 entry in
    let val := projT2 entry in
    let '(noise, nst) := get_noise (snd x) noise_st in
    (mk_env_entry x (update_val_gradenv grad_env x alpha val noise), nst).

  Fixpoint list_arg_iter {A B} (f: A -> B -> A * B)
             (l:list A) (b: B) : (list A)*B :=
      match l with
      | nil => (l, b)
      | a :: l' => 
        let '(na, b') := f a b in
        let '(nl, nb) := list_arg_iter f l' b' in
        (na::nl, nb)
      end.         

  Definition optimize_step_backprop
             (step : nat) (df : UnitDefinedFunction DTfloat) (σ:df_env)
             (noise_st : Stream float) : (option df_env)*(Stream float) :=
    match df_eval_backprop_deriv σ df nil 1 with
    | Some gradenv => 
      let alpha := 1 / (FfromZ (Z.of_nat (S step))) in
      let '(env, nst) := list_arg_iter (fun a b => update_entry a gradenv alpha b) σ noise_st in
      (Some env, nst)
    | _ => (None, noise_st)
    end.

  Definition optimize_step_tree_backprop
             (step : nat) (df : UnitDefinedFunction DTfloat) (σ:df_env)
             (noise_st : Stream float) : (option df_env)*(Stream float) :=
    match df_eval_tree σ df with
    | Some df_tree =>
      match df_eval_tree_backprop_deriv (* σ not-needed *) nil df_tree nil 1 with
      | Some gradenv => 
        let alpha := 1 / (FfromZ (Z.of_nat (S step))) in
        let '(env, nst) := list_arg_iter (fun a b => update_entry a gradenv alpha b) σ noise_st in
        (Some env, nst)
      | _ => (None, noise_st)
      end
    | _ => (None, noise_st)
    end.

  Fixpoint optimize_steps 
           (start count:nat) (df : DefinedFunction DTfloat) (σ:df_env) (lvar : list SubVar)
           (noise_st : Stream float) : (option df_env)*(Stream float) :=
    match count with
    | 0 => (Some σ, noise_st)
    | S n =>
      match optimize_step start df σ lvar noise_st with
      | (Some σ', noise_st') => optimize_steps (S start) n df σ' lvar noise_st'
      | (None, noise_st') => (None, noise_st')
      end
    end.

  Fixpoint optimize_steps_backprop
           (start count:nat) (df : DefinedFunction DTfloat) (σ:df_env) 
           (noise_st : Stream float) : (option df_env)*(Stream float) :=
    match count with
    | 0 => (Some σ, noise_st)
    | S n =>
      match optimize_step_backprop start df σ noise_st with
      | (Some σ', noise_st') => optimize_steps_backprop (S start) n df σ' noise_st'
      | (None, noise_st') => (None, noise_st')
      end
    end.

  Fixpoint optimize_steps_tree_backprop
           (start count:nat) (df : DefinedFunction DTfloat) (σ:df_env) 
           (noise_st : Stream float) : (option df_env)*(Stream float) :=
    match count with
    | 0 => (Some σ, noise_st)
    | S n =>
      match optimize_step_tree_backprop start df σ noise_st with
      | (Some σ', noise_st') => optimize_steps_backprop (S start) n df σ' noise_st'
      | (None, noise_st') => (None, noise_st')
      end
    end.

Example xvar:var_type := (Name "x", DTfloat).
Example xfun:UnitDefinedFunction DTfloat := Var xvar tt.
Example quad:UnitDefinedFunction DTfloat := Minus tt (Times tt xfun xfun) (Number tt 1).
Example squad:UnitDefinedFunction DTfloat := Minus tt (Square tt xfun) (Number tt 1).
Example env : df_env := (mk_env_entry xvar (FfromZ 5))::nil.
Example gradenv := df_eval_backprop_deriv env quad nil 1.
(* Compute gradenv. *)
CoFixpoint noise : Stream float := Cons 0 noise.
Example opt := fst (optimize_steps 0 2 quad env ((fst xvar) :: nil) noise).
End GenNN.

