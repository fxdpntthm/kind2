(* This file is part of the Kind 2 model checker.

   Copyright (c) 2020 by the Board of Trustees of the University of Iowa

   Licensed under the Apache License, Version 2.0 (the "License"); you
   may not use this file except in compliance with the License.  You
   may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0 

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
   implied. See the License for the specific language governing
   permissions and limitations under the License. 

 *)

(** Converts the graph 
   
   @author Apoorv Ingle *)

module R = Res
module LA = LustreAst
(* type payload = {k:LustreAst.ident; v:LA.declaration option}
 * let payload_compare p1 p2 = Stdlib.compare p1.k p2.k *)
                          
module G = Graph.Make(struct
               type t = LA.ident
               let compare = Stdlib.compare
               let pp_print_t = LA.pp_print_ident
             end)

module IMap = Map.Make(struct
                  type t = LA.ident
                  let compare i1 i2 = Stdlib.compare i1 i2
                end)

type 'a graph_result = ('a, Lib.position * string) result  
let graph_error pos err = Error (Lib.dummy_pos, err)
let (>>=) = R.(>>=)                     

let ty_suffix = "type "
let const_suffix = ""
let node_suffix = ""
let contract_suffix = ""
                 
          
let rec mk_graph_type: LA.lustre_type -> G.t = function
  | TVar (_, i) -> G.singleton (ty_suffix ^ i)
  | Bool _
  | Int _
  | UInt8 _
  | UInt16 _
  | UInt32 _ 
  | UInt64 _ 
  | Int8 _ 
  | Int16 _
  | Int32 _
  | Int64 _
  | Real _
  | EnumType _ -> G.empty
  | IntRange (_, e1, e2) -> G.union (mk_graph_expr e1) (mk_graph_expr e2)
  | UserType (_, i) -> G.singleton (ty_suffix ^ i)
  | AbstractType  (_, i) -> G.singleton (ty_suffix ^ i)
  | TupleType (_, tys) -> List.fold_left G.union G.empty (List.map (fun t -> mk_graph_type t) tys)
  | RecordType (_, ty_ids) -> List.fold_left G.union G.empty (List.map (fun (_, _, t) -> mk_graph_type t) ty_ids)
  | ArrayType (_, (ty, e)) -> G.union (mk_graph_type ty) (mk_graph_expr e)
  | TArr (_, aty, rty) -> G.union (mk_graph_type aty) (mk_graph_type rty)
      
and mk_graph_expr: LA.expr -> G.t
  = function
  | LA.Ident (_, i) -> G.singleton i
  | LA.Const _ -> G.empty
  | LA.RecordExpr (_, _, ty_ids) ->
     List.fold_left G.union G.empty (List.map (fun ty_id -> mk_graph_expr (snd ty_id)) ty_ids)
  | LA.UnaryOp (_, _, e) -> mk_graph_expr e
  | LA.BinaryOp (_, _, e1, e2) -> G.union (mk_graph_expr e1) (mk_graph_expr e2) 
  | LA.TernaryOp (_, _, e1, e2, e3) -> G.union (mk_graph_expr e1)
                                         (G.union (mk_graph_expr e2) (mk_graph_expr e3)) 
  | LA.RecordProject (_, e, _) -> mk_graph_expr e
  | LA.ArrayConstr (_, e1, e2) -> G.union (mk_graph_expr e1) (mk_graph_expr e2) 
  | LA.ArraySlice (_, e1, (e2, e3)) -> G.union (G.union (mk_graph_expr e1) (mk_graph_expr e2)) (mk_graph_expr e3) 
  | LA.ArrayIndex (_, e1, e2) -> G.union (mk_graph_expr e1) (mk_graph_expr e2)
  | LA.ArrayConcat  (_, e1, e2) -> G.union (mk_graph_expr e1) (mk_graph_expr e2)
  | LA.GroupExpr (_, _, es) -> List.fold_left G.union G.empty (List.map mk_graph_expr es)
  | LA.Pre (_, e) -> mk_graph_expr e
  | LA.Last (_, i) -> G.singleton i
  | LA.Fby (_, e1, _, e2) ->  G.union (mk_graph_expr e1) (mk_graph_expr e2) 
  | LA.Arrow (_, e1, e2) ->  G.union (mk_graph_expr e1) (mk_graph_expr e2) 
  | _ -> Lib.todo __LOC__
  
let mk_graph_const_decl: LA.const_decl -> G.t
  = function
  | LA.FreeConst (_, i, ty) -> G.connect (mk_graph_type ty) i
  | LA.UntypedConst (_, i, e) -> G.connect (mk_graph_expr e) i 
  | LA.TypedConst (_, i, e, ty) -> G.connect (G.union (mk_graph_expr e) (mk_graph_type ty)) i

                                  
let mk_graph_type_decl: LA.type_decl -> G.t
  = function
  | FreeType (_, i) -> G.singleton (ty_suffix ^ i) 
  | AliasType (_, i, ty) -> G.connect (mk_graph_type ty) (ty_suffix ^ i)

let rec mk_graph_contract_node_eqn: LA.contract_node_equation -> G.t
  = function
  | LA.ContractCall (_, i, _, _) -> G.singleton i
  | LA.Assume (_, _, _, e) -> List.fold_left G.union G.empty (List.map G.singleton (get_node_call_from_expr e))
  | LA.Guarantee (_, _, _, e) -> List.fold_left G.union G.empty (List.map G.singleton (get_node_call_from_expr e))
  | _ -> G.empty

and get_node_call_from_expr: LA.expr -> LA.ident list
  = function
  | Ident _ 
  | ModeRef _ 
  | RecordProject _ -> [] 
  | TupleProject (_, e, _) -> get_node_call_from_expr e
  (* Values *)
  | LA.Const _ -> []
  (* Operators *)
  | LA.UnaryOp (_, _, e) -> get_node_call_from_expr e
  | LA.BinaryOp (_, _, e1, e2) -> (get_node_call_from_expr e1)
                                  @ (get_node_call_from_expr e2)
  | LA.TernaryOp (_, _, e1, e2, e3) -> (get_node_call_from_expr e1)
                                       @ (get_node_call_from_expr e2)
                                       @ (get_node_call_from_expr e3)
  | LA.NArityOp (_, _, es) -> List.flatten (List.map get_node_call_from_expr es)
  | LA.ConvOp (_, _, e) -> get_node_call_from_expr e
  | LA.CompOp (_, _, e1, e2) -> (get_node_call_from_expr e1) @ (get_node_call_from_expr e2)
  (* Structured expressions *)
  | LA.RecordExpr (_, _, id_exprs) -> List.flatten (List.map (fun (_, e) -> get_node_call_from_expr e) id_exprs)
  | LA.GroupExpr (_, _, es) -> List.flatten (List.map get_node_call_from_expr es) 
  (* Update of structured expressions *)
  | LA.StructUpdate (_, _, _, e) -> get_node_call_from_expr e
  | LA.ArrayConstr (_, e1, e2) -> (get_node_call_from_expr e1) @ (get_node_call_from_expr e2)
  | LA.ArraySlice (_, e1, (e2, e3)) -> (get_node_call_from_expr e1)
                                       @ (get_node_call_from_expr e2)
                                       @ (get_node_call_from_expr e3)
  | LA.ArrayIndex (_, e1, e2) -> (get_node_call_from_expr e1) @ (get_node_call_from_expr e2)
  | LA.ArrayConcat (_, e1, e2) -> (get_node_call_from_expr e1) @ (get_node_call_from_expr e2)
  (* Quantified expressions *)
  | LA.Quantifier (_, _, _, e) -> get_node_call_from_expr e 
  (* Clock operators *)
  | LA.When (_, e, _) -> get_node_call_from_expr e
  | LA.Current (_, e) -> get_node_call_from_expr e
  | LA.Condact (_, _,_, i, _, _) -> [i]
  | LA.Activate (_, i, _, _, _) -> [i]
  | LA.Merge (_, _, id_exprs) -> List.flatten (List.map (fun (_, e) -> get_node_call_from_expr e) id_exprs)
  | LA.RestartEvery (_, i, es, e1) -> i :: (List.flatten (List.map get_node_call_from_expr es)) @ get_node_call_from_expr e1
  (* Temporal operators *)
  | LA.Pre (_, e) -> get_node_call_from_expr e
  | LA.Last _ -> []
  | LA.Fby (_, e1, _, e2) -> (get_node_call_from_expr e1) @ (get_node_call_from_expr e2)
  | LA.Arrow (_, e1, e2) -> (get_node_call_from_expr e1) @ (get_node_call_from_expr e2)
  (* Node calls *)
  | LA.Call (_, i, es) -> i :: List.flatten (List.map get_node_call_from_expr es)
  | LA.CallParam _ -> []

let mk_graph_contract_decl: LA.contract_node_decl -> G.t
  = fun (_, _, _, _, c) ->
  List.fold_left G.union G.empty (List.map mk_graph_contract_node_eqn c)
       
let extract_node_calls: LA.node_item list -> LA.ident list
  = List.fold_left
      (fun acc eqn -> (match eqn with
                       | LA.Body bneq ->
                          (match bneq with
                           | LA.Assert (_, e) -> get_node_call_from_expr e
                           | LA.Equation (_, _, e) -> get_node_call_from_expr e
                           | LA.Automaton _ -> [])
                       | _ -> []) @ acc) [] 
       
let mk_graph_node_decl: LA.node_decl -> G.t
  = fun (i, _, _, _, _, _, nitems, contract_opt) ->
  let cg = G.connect (match contract_opt with
                      | None -> G.empty
                      | Some c -> List.fold_left G.union G.empty (List.map mk_graph_contract_node_eqn c)) i in
  let node_refs = extract_node_calls nitems in
  List.fold_left (fun g nr -> G.union g (G.connect (G.singleton nr) i)) cg node_refs
                          
let mk_graph: LA.declaration ->  G.t = function
  | TypeDecl (pos, tydecl) -> mk_graph_type_decl tydecl 
  | ConstDecl (pos, cdecl) -> mk_graph_const_decl cdecl
  | NodeDecl (pos, ndecl) -> mk_graph_node_decl ndecl
  | FuncDecl (pos, ndecl) -> mk_graph_node_decl ndecl
  | ContractNodeDecl  (pos, cdecl) -> mk_graph_contract_decl cdecl
  | NodeParamInst  _ -> Lib.todo __LOC__


let add_decl: LA.declaration IMap.t -> LA.ident -> LA.declaration -> LA.declaration IMap.t
  = fun m i ty -> IMap.add i ty m
                      
let rec check_and_add: LA.declaration IMap.t -> Lib.position
                       -> string -> LA.ident -> LA.declaration -> LA.t -> (LA.declaration IMap.t) graph_result
  = fun m pos suffix i tyd decls ->
  if IMap.mem (suffix ^ i) m 
  then graph_error pos ("Identifier " ^ i ^ " is already declared")
  else let m' = add_decl m (suffix ^ i) tyd in  
       mk_decl_map m' decls
(** reject program if identifier is already declared  *)
       
and  mk_decl_map: LA.declaration IMap.t -> LA.t -> (LA.declaration IMap.t) graph_result =
  fun m ->
  function  
  | [] -> R.ok m 

  | (LA.TypeDecl (pos, FreeType (_, i)) as tydecl) :: decls
    | (LA.TypeDecl (pos, AliasType (_, i, _)) as tydecl) :: decls ->
     check_and_add m pos ty_suffix i tydecl decls

  | (LA.ConstDecl (pos, FreeConst (_, i, _)) as cnstd) :: decls
    | (LA.ConstDecl (pos, UntypedConst (_, i, _)) as cnstd) :: decls
    | (LA.ConstDecl (pos, TypedConst (_, i, _, _)) as cnstd) :: decls -> 
     check_and_add m pos const_suffix i cnstd decls

  | (LA.NodeDecl (pos, (i, _, _, _, _, _, _, _)) as ndecl) :: decls
    | (LA.FuncDecl (pos, (i, _, _, _, _, _, _, _)) as ndecl) :: decls ->
     check_and_add m pos node_suffix i ndecl decls

  | LA.ContractNodeDecl (pos, (i, _, _, _, _)) as cndecl :: decls ->
     check_and_add m pos contract_suffix i cndecl decls

  | LA.NodeParamInst _ :: _-> Lib.todo __LOC__
(** builds an id :-> decl map  *)
                      
let dependency_graph_decls: LA.t -> G.t
  = fun decls ->
  List.fold_left G.union G.empty (List.map mk_graph decls)

let rec extract_decls: LA.declaration IMap.t -> LA.ident list -> LA.t graph_result
  = fun decl_map ->
  function
  | [] -> R.ok []
  | i :: is -> (try (R.ok (IMap.find i decl_map)) with
                | Not_found -> graph_error Lib.dummy_pos ("Identifier " ^ i ^ " is not defined."))
               >>= (fun d -> (extract_decls decl_map is)
                             >>= (fun ds -> R.ok (d :: ds)))
    
and sort_decls: LA.t -> LA.t graph_result = fun decls ->
  (* 1. make an id :-> decl map  *)
  mk_decl_map IMap.empty decls >>= fun decl_map ->
  (* 2. build a dependency graph *)
  let dg = dependency_graph_decls decls in
  (* 3. try to sort it, raise an error if it is cyclic, or extract sorted decls from the decl_map *)
  (try (R.ok (G.topological_sort dg)) with
   | Graph.CyclicGraphException ids ->
      graph_error Lib.dummy_pos
        ("Cyclic dependency detected in definition of identifiers: "
  ^ Lib.string_of_t (Lib.pp_print_list LA.pp_print_ident ", ") ids))
  >>= fun sorted_ids -> Log.log L_trace "sorted ids: %a" (Lib.pp_print_list LA.pp_print_ident ",")  sorted_ids;
                          extract_decls decl_map sorted_ids                          

