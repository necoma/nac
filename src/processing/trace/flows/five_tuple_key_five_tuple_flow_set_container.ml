
open Printf

module A = BatArray
module S = BatString
module HT = BatHashtbl
module L = BatList

open Map_ext_instantiations

open Ipv4
open Tcp
open Udp
open Icmp

open Traffic_flow_aggr_data_instantiations.Traffic_flow_five_tuple_flow_detailed_metrics_aggr_data

open Key_occurrence_distribution_instantiations

open Five_tuple_flow_data_structures

let debug_enabled = ref false

let set_debug bool = debug_enabled := bool

let debug fmt =
  Printf.kprintf
    (
      if !debug_enabled then
        (fun s -> Format.printf "[Five_tuple_key_five_tuple_flow_set_container]: %s@." s)
      else
        ignore
    )
    fmt

type t =
  {
    src_addr_hashtable : (Ipaddr.t, Five_tuple_flow_hashset.t) HT.t;
    dst_addr_hashtable : (Ipaddr.t, Five_tuple_flow_hashset.t) HT.t;
    admd_transport_protocol_hashtable : ( Admd.Transport_protocol.t , Five_tuple_flow_hashset.t) HT.t;
    src_port_hashtable : (int, Five_tuple_flow_hashset.t) HT.t;
    dst_port_hashtable : (int, Five_tuple_flow_hashset.t) HT.t;
  }

let new_t
    src_addr_hashtable
    dst_addr_hashtable
    admd_transport_protocol_hashtable
    src_port_hashtable
    dst_port_hashtable
    =
  {
    src_addr_hashtable;
    dst_addr_hashtable;
    admd_transport_protocol_hashtable;
    src_port_hashtable;
    dst_port_hashtable;
  }

let new_empty_t
    ()
    =
  new_t
    (Hashtbl.create 0)
    (Hashtbl.create 0)
    (Hashtbl.create 0)
    (Hashtbl.create 0)
    (Hashtbl.create 0)

let of_five_tuple_key_five_tuple_flow_list_container five_tuple_key_five_tuple_flow_list_container =
  (
    let src_addr_hashtable =
      HT.map
        (fun int32 five_tuple_flow_list -> 
           Five_tuple_flow_hashset.of_list
             (L.sort_unique Five_tuple_flow.compare five_tuple_flow_list)
        )
        five_tuple_key_five_tuple_flow_list_container.Five_tuple_key_five_tuple_flow_list_container.src_addr_hashtable
    in
    (* let src_addr_hashtable = *)
    (*   HT.of_enum *)
    (*   (L.enum *)
    (*      (L.map *)
    (*         (fun (int32, data) -> *)
    (*          let ipaddrv4 : Ipaddr.V4.t = Ipaddr.V4.of_int32 int32 in *)
    (*          let ipaddr : Ipaddr.t = Ipaddr.V4 ipaddrv4 in *)
    (*          (ipaddr, data) *)
    (*         ) *)
    (*         (L.of_enum (HT.enum src_addr_hashtable)) *)
    (*      ) *)
    (*   ) *)
    (* in *)

    let dst_addr_hashtable =
      Batteries.Hashtbl.map
        (fun _ five_tuple_flow_list -> 
           Five_tuple_flow_hashset.of_list
             (L.sort_unique Five_tuple_flow.compare five_tuple_flow_list)
        )
        five_tuple_key_five_tuple_flow_list_container.Five_tuple_key_five_tuple_flow_list_container.dst_addr_hashtable
    in

    let admd_transport_protocol_hashtable =
      Batteries.Hashtbl.map
        (fun _ five_tuple_flow_list -> 
           Five_tuple_flow_hashset.of_list
             (L.sort_unique Five_tuple_flow.compare five_tuple_flow_list)
        )
        five_tuple_key_five_tuple_flow_list_container.Five_tuple_key_five_tuple_flow_list_container.admd_transport_protocol_hashtable
    in

    let src_port_hashtable =
      Batteries.Hashtbl.map
        (fun _ five_tuple_flow_list ->
           Five_tuple_flow_hashset.of_list 
             (L.sort_unique Five_tuple_flow.compare five_tuple_flow_list)
        )
        five_tuple_key_five_tuple_flow_list_container.Five_tuple_key_five_tuple_flow_list_container.src_port_hashtable
    in

    let dst_port_hashtable =
      Batteries.Hashtbl.map
        (fun _ five_tuple_flow_list -> 
           Five_tuple_flow_hashset.of_list 
             (L.sort_unique Five_tuple_flow.compare five_tuple_flow_list)
        )
        five_tuple_key_five_tuple_flow_list_container.Five_tuple_key_five_tuple_flow_list_container.dst_port_hashtable
    in

    new_t
      src_addr_hashtable
      dst_addr_hashtable
      admd_transport_protocol_hashtable
      src_port_hashtable
      dst_port_hashtable
  )

(* let to_string to_string_mode t = *)
(*   Simple_key_data_container.to_string *)
(*     to_string_mode *)
(*     t.container *)

(* let find five_tuple_flow t = Int_map.find indice t.detailed_metrics_int_map *)

(* let length t = Simple_key_data_container.length t.container *)

(* let iter f t = *)
(*   Simple_key_data_container.iter *)
(*     f *)
(*     t.container *)

(* let fold f t acc_init  = *)
(*   let new_acc = *)
(*     Simple_key_data_container.fold *)
(*       f *)
(*       t.container *)
(*       acc_init *)
(*   in *)

(*   new_acc *)

(* let map_to_hashtbl *)
(*   f *)
  (*   t *)
  (*   = *)
  (* Simple_key_data_container.map_to_hashtbl *)
  (*   f *)
  (*   t.container *)

let find_src_addr
    t
    src_addr
    =
  try
    Hashtbl.find
      t.src_addr_hashtable
      src_addr
  with
  | Not_found ->
    Five_tuple_flow_hashset.empty
    
let find_dst_addr
    t
    dst_addr
    =
  try
    Hashtbl.find
      t.dst_addr_hashtable
      dst_addr
  with
  | Not_found ->
    Five_tuple_flow_hashset.empty

let find_admd_transport_protocol
    t
    admd_transport_protocol
    =
  try
    Hashtbl.find
      t.admd_transport_protocol_hashtable
      admd_transport_protocol
  with
  | Not_found ->
        Five_tuple_flow_hashset.empty

let find_src_port
    t
    src_port
    =
  try
    Hashtbl.find
      t.src_port_hashtable
      src_port
  with
  | Not_found ->
        Five_tuple_flow_hashset.empty

let find_dst_port
    t
    dst_port
    =
  try
    Hashtbl.find
      t.dst_port_hashtable
      dst_port
  with
  | Not_found ->
    Five_tuple_flow_hashset.empty

let of_five_tuple_flow_metrics_container
    five_tuple_flow_metrics_container
  =
  (
    let new_t = new_empty_t () in

    Five_tuple_flow_metrics_container.iter
      (fun five_tuple_flow _ ->
         (
           (* let src_addr = Ipaddr.V4.to_int32 five_tuple_flow.Five_tuple_flow.src_addr in *)
           (* let dst_addr = Ipaddr.V4.to_int32 five_tuple_flow.Five_tuple_flow.dst_addr in *)
           (* let src_addr = Ipaddr.V4 five_tuple_flow.Five_tuple_flow.src_addr in *)
           (* let dst_addr = Ipaddr.V4 five_tuple_flow.Five_tuple_flow.dst_addr in *)
           let src_addr = five_tuple_flow.Five_tuple_flow.src_addr in
           let dst_addr = five_tuple_flow.Five_tuple_flow.dst_addr in
           let admd_transport_protocol = 
             Transport_protocol_translation.transport_protocol_for_metrics_to_admd_transport_protocol
               five_tuple_flow.Five_tuple_flow.protocol
           in
           let src_port = five_tuple_flow.Five_tuple_flow.src_port in
           let dst_port = five_tuple_flow.Five_tuple_flow.dst_port in

           (* Source address *)
           ignore(
             try
               (
                 let five_tuple_flow_hashset_found =
                   Hashtbl.find
                     new_t.src_addr_hashtable
                     src_addr
                 in

                 Five_tuple_flow_hashset.add
                   five_tuple_flow_hashset_found
                   five_tuple_flow;

                 (* Hashtbl.replace *)
                 (*   new_t.src_addr_hashtable *)
                 (*   src_addr *)
                 (*   (Batteries.List.append [ five_tuple_flow ] five_tuple_flow_list_found) *)
               )
             with
             | Not_found ->
               (
                 Hashtbl.add
                   new_t.src_addr_hashtable
                   src_addr
                   (Five_tuple_flow_hashset.singleton five_tuple_flow)
               )
           );
           (* Destination address *)
           ignore(
             try
               (
                 let five_tuple_flow_hashset_found =
                   Hashtbl.find
                     new_t.dst_addr_hashtable
                     dst_addr
                 in

                 Five_tuple_flow_hashset.add
                   five_tuple_flow_hashset_found
                   five_tuple_flow;

                 (* Hashtbl.replace *)
                 (*   new_t.dst_addr_hashtable *)
                 (*   dst_addr *)
                 (*   (Batteries.List.append [ five_tuple_flow ] five_tuple_flow_list_found) *)
               )
             with
             | Not_found ->
               (
                 Hashtbl.add
                   new_t.dst_addr_hashtable
                   dst_addr
                   (Five_tuple_flow_hashset.singleton five_tuple_flow)
               )
           );

           (* Admd transport protocol *)
           ignore(
             try
               (
                 let five_tuple_flow_hashset_found =
                   Hashtbl.find
                     new_t.admd_transport_protocol_hashtable
                     admd_transport_protocol
                 in

                 Five_tuple_flow_hashset.add
                   five_tuple_flow_hashset_found
                   five_tuple_flow;

                 (* Hashtbl.replace *)
                 (*   new_t.admd_transport_protocol_hashtable *)
                 (*   admd_transport_protocol *)
                 (*   (Batteries.List.append [ five_tuple_flow ] five_tuple_flow_list_found) *)
               )
             with
             | Not_found ->
               (
                 Hashtbl.add
                   new_t.admd_transport_protocol_hashtable
                   admd_transport_protocol
                   (Five_tuple_flow_hashset.singleton five_tuple_flow)
               )
           );

           (* Source port *)
           ignore(
             try
               (
                 let five_tuple_flow_hashset_found =
                   Hashtbl.find
                     new_t.src_port_hashtable
                     src_port
                 in

                 Five_tuple_flow_hashset.add
                   five_tuple_flow_hashset_found
                   five_tuple_flow;

                 (* Hashtbl.replace *)
                 (*   new_t.src_port_hashtable *)
                 (*   src_port *)
                 (*   (Batteries.List.append [ five_tuple_flow ] five_tuple_flow_list_found) *)
               )
             with
             | Not_found ->
               (
                 Hashtbl.add
                   new_t.src_port_hashtable
                   src_port
                   (Five_tuple_flow_hashset.singleton five_tuple_flow)
               )
           );
           (* Destination port *)
           ignore(
             try
               (
                 let five_tuple_flow_hashset_found =
                   Hashtbl.find
                     new_t.dst_port_hashtable
                     dst_port
                 in

                 Five_tuple_flow_hashset.add
                   five_tuple_flow_hashset_found
                   five_tuple_flow;

                 (* Hashtbl.replace *)
                 (*   new_t.dst_port_hashtable *)
                 (*   dst_port *)
                 (*   (Batteries.List.append [ five_tuple_flow ] five_tuple_flow_list_found) *)
               )
             with
             | Not_found ->
               (
                 Hashtbl.add
                   new_t.dst_port_hashtable
                   dst_port
                   (Five_tuple_flow_hashset.singleton five_tuple_flow)
               )
           );
         )
      )
      five_tuple_flow_metrics_container;

    new_t
  )
