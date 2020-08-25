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
(** A poor person's acyclic directred graph and its topological sort
   
   @author Apoorv Ingle *)

module type OrderedType = sig
  type t
  val compare: t -> t -> int
end
        
module type S = sig 
  exception IllegalGraphOperation
  (** The exception raised when an illegal edge is added *)
  exception CyclicGraphException
  (** The exception raised when topological sort is tried on cyclic graph  *)
  
  type vertex
  (** The vertex type *)
    
  type edge
  (** The edge type to represent line between two vertices *)

  val mk_edge: vertex -> vertex -> edge   
  (** Make an [edge] from two vertices  *)

  val get_source_vertex: edge -> vertex
  (** Get the source [vertex] from an [edge] *)

  val is_vertex_source: edge -> vertex -> bool
  (** Checks if the [vertex] is the source [vertex] *)

  val get_target_vertex: edge -> vertex
  (** Get the target [vertex] from an [edge] *)

  val is_vertex_target: edge -> vertex -> bool
  (** Checks if the [vertex] is the target [vertex] *)
    
  type vertices
  (** Set of vertices *)

  type edges
  (** Set of edges *)

  type t
  (** The graph type  *)

  val empty: t
  (** The empty graph  *)

  val is_empty: t -> bool
  (** Check if the graph is empty *)

  val singleton: vertex -> t
  (** returns a singleton graph *)

  val add_vertex: t ->  vertex ->  t
  (** Add a [vertex] to a graph  *)

  val add_edge: t ->  edge ->  t
  (** Add an [edge] to a graph  *)

  val remove_vertex: t ->  vertex ->  t
  (** Remove a [vertex] from a graph *)                             

  val remove_edge: t ->  edge ->  t
  (** Remove an [edge] from a graph *)                             

  val connect: t -> vertex -> t
  (** Connect [vertex] to all the other vertices in the given graph *)
    
  val union: t -> t -> t
  (** Unions two graphs *)
    
  val topological_sort:  t ->  vertex list
  (** Computes a topological ordering of vertices 
   *  or throws an [CyclicGraphException] if the graph is cyclic.
   *  Implimentation is of this function is based on Kahn's algorithm *)
end
              
module Make (Ord: OrderedType): S with type vertex = Ord.t
