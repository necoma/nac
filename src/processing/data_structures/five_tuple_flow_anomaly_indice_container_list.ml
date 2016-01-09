
open Printf

module L = List_ext
module HT = BatHashtbl

open Admd.Instantiation
open Set_ext_instantiations
    
let debug_enabled = ref true

let set_debug bool = debug_enabled := bool

let debug fmt =
  Printf.kprintf
    (
      if !debug_enabled then
        (fun s -> Format.printf "[Five_tuple_flow_anomaly_indice_container]: %s@." s)
      else
        ignore
    )
    fmt

type t =
  {
    (* five_tuple_flow_anomaly_indice_h : ; *)
    
    src_ipaddr_anomaly_h : (Ipaddr.t, int list) HT.t;
    dst_ipaddr_anomaly_h : (Ipaddr.t, int list) HT.t;
    transport_protocol_anomaly_h : (Admd_transport_protocol.t, int list) HT.t;
    src_port_anomaly_h : (int, int list) HT.t;
    dst_port_anomaly_h : (int, int list) HT.t;
    
    anomaly_h : (int, Base.Anomaly.t) HT.t;
  }

let new_t
    src_ipaddr_anomaly_h
    dst_ipaddr_anomaly_h
    transport_protocol_anomaly_h
    src_port_anomaly_h
    dst_port_anomaly_h

    anomaly_h
  =
  {
    src_ipaddr_anomaly_h;
    dst_ipaddr_anomaly_h;
    transport_protocol_anomaly_h;
    src_port_anomaly_h;
    dst_port_anomaly_h;

    anomaly_h;
  }

let to_string t =
  sprintf
    "Five_tuple_flow_anomaly_indice_container:\nsrc_ipaddr_anomaly_h:\n%s\n\ndst_ipaddr_anomaly_h:\n%s\nsrc_port_anomaly_h:\n%s\n\n%s\n\ndst_port_anomaly_h:\n%s"
    (L.to_string
       ~sep: "\n"
       (fun (ipaddr, anomaly_indice_l) ->
          sprintf
            "%s: %s"
            (Ipaddr.to_string ipaddr)
            (L.to_string string_of_int anomaly_indice_l)
       )
       (L.of_enum (HT.enum t.src_ipaddr_anomaly_h))
    )
    (L.to_string
       ~sep: "\n"
       (fun (ipaddr, anomaly_indice_l) ->
          sprintf
            "%s: %s"
            (Ipaddr.to_string ipaddr)
            (L.to_string string_of_int anomaly_indice_l)
       )
       (L.of_enum (HT.enum t.dst_ipaddr_anomaly_h))
    )

    (L.to_string
       ~sep: "\n"
       (fun (port, anomaly_indice_l) ->
          sprintf
            "%d: %s"
            port
            (L.to_string string_of_int anomaly_indice_l)
       )
       (L.of_enum (HT.enum t.src_port_anomaly_h))
    )
    (L.to_string
       ~sep: "\n"
       (fun (port, anomaly_indice_l) ->
          sprintf
            "%d: %s"
            port
            (L.to_string string_of_int anomaly_indice_l)
       )
       (L.of_enum (HT.enum t.dst_port_anomaly_h))
    )

    (L.to_string
       ~sep: "\n"
       (fun (indice, anomaly) ->
          sprintf
            "%d:\n%s"
            indice
            (Base.Anomaly.to_string
               anomaly
            )
       )
       (L.of_enum (HT.enum t.anomaly_h))
    )


(* let new_empty_t *)
(*     size *)
(*     = *)
(*   let container_empty = *)
(*     Simple_key_data_container.new_empty_t *)
(*       size *)
(*   in *)

(*   new_t *)
(*     container_empty *)

(* let to_string t = *)
(*   Simple_key_data_container.to_string *)
(*     t.container *)

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

(* let to_list t = Simple_key_data_container.to_list t.container *)

(* let filteri f t = *)
(*   let new_container = *)
(*     Simple_key_data_container.filteri *)
(*       f *)
(*       t.container *)
(*   in *)
(*   new_t *)
(*     new_container *)

let of_anomaly_container
    anomaly_container
  =
  (
    let anomaly_list = Base.Anomaly_container.to_list anomaly_container in

    (* let h_1 = *)
    (*   HT.of_enum *)
    (*     (L.enum *)
    (*        (L.map *)
    (*           (fun anomaly -> *)
    (*              let anomaly_indice = anomaly.Base.Anomaly.indice in *)

    (*              let filter_criteria_list_list = *)
    (*                Batteries.List.fold_left *)
    (*                  (fun acc slice -> *)
    (*                     Batteries.List.append *)
    (*                       acc *)
    (*                       ( *)
    (*                         Batteries.List.map *)
    (*                           (fun filter -> *)
    (*                              filter.Admd_filter.filter_criteria_list *)
    (*                           ) *)
    (*                           slice.Admd_slice.filter_list *)
    (*                       ) *)
    (*                  ) *)
    (*                  [] *)
    (*                  anomaly.Base.Anomaly.slice_list *)
    (*              in *)

    (*              anomaly_indice, filter_criteria_list_list *)
    (*           ) *)
    (*           anomaly_list *)
    (*        ) *)
    (*     ) *)
    (* in *)

    let anomaly_h =
      HT.of_enum
        (L.enum
           (L.map
              (fun anomaly ->
                 let anomaly_indice = anomaly.Base.Anomaly.indice in

                 anomaly_indice, anomaly
              )
              anomaly_list
           )
        )
    in

    let src_ipaddr_anomaly_h,
        dst_ipaddr_anomaly_h,
        transport_protocol_anomaly_h,
        src_port_anomaly_h,
        dst_port_anomaly_h
      =
      L.fold_left
        (fun 
          (
            src_ipaddr_anomaly_h_acc,
            dst_ipaddr_anomaly_h_acc,
            transport_protocol_anomaly_h_acc,
            src_port_anomaly_h_acc,
            dst_port_anomaly_h_acc
          )
          anomaly
          ->
            let anomaly_indice = anomaly.Base.Anomaly.indice in

            let filter_criteria_list_list =
              Batteries.List.fold_left
                (fun acc slice ->
                   Batteries.List.append
                     acc
                     (
                       Batteries.List.map
                         (fun filter ->
                            filter.Admd_filter.filter_criteria_list 
                         )
                         slice.Admd_slice.filter_list
                     )
                )
                []
                anomaly.Base.Anomaly.slice_list
            in

            let filter_criteria_list = L.flatten filter_criteria_list_list in

            L.iter
              (fun filter_criteria ->
                 match filter_criteria with
                 |  Admd.Filter.criteria.Src_ip src_addr ->
                   (
                     let ipaddr = Admd_ipaddr.to_ipaddr src_addr in
                     try
                       (
                         let l = HT.find src_ipaddr_anomaly_h_acc ipaddr in
                         let new_l = L.append l [ anomaly_indice ] in
                         HT.replace
                           src_ipaddr_anomaly_h_acc
                           ipaddr
                           new_l;
                       )
                     with
                     | Not_found ->
                       (
                         HT.add
                           src_ipaddr_anomaly_h_acc
                           ipaddr
                           [ anomaly_indice ]
                         ;
                       )
                   )
                 |  Admd.Filter.criteria.Dst_ip dst_addr ->
                   (
                     let ipaddr = Admd_ipaddr.to_ipaddr dst_addr in
                     try
                       (
                         let l = HT.find dst_ipaddr_anomaly_h_acc ipaddr in
                         let new_l = L.append l [ anomaly_indice ] in
                         HT.replace
                           dst_ipaddr_anomaly_h_acc
                           ipaddr
                           new_l;
                       )
                     with
                     | Not_found ->
                       (
                         HT.add
                           dst_ipaddr_anomaly_h_acc
                           ipaddr
                           [ anomaly_indice ]
                         ;
                       )
                   )
                 |  Admd.Filter.criteria.Admd_transport_protocol admd_transport_protocol ->
                   (
                     try
                       (
                         let l = HT.find transport_protocol_anomaly_h_acc admd_transport_protocol in
                         let new_l = L.append l [ anomaly_indice ] in
                         HT.replace
                           transport_protocol_anomaly_h_acc
                           admd_transport_protocol
                           new_l;
                       )
                     with
                     | Not_found ->
                       (
                         HT.add
                           transport_protocol_anomaly_h_acc
                           admd_transport_protocol
                           [ anomaly_indice ]
                         ;
                       )
                   )
                 |  Admd.Filter.criteria.Src_port src_port ->
                   (
                     try
                       (
                         let l = HT.find src_port_anomaly_h_acc src_port in
                         let new_l = L.append l [ anomaly_indice ] in
                         HT.replace
                           src_port_anomaly_h_acc
                           src_port
                           new_l;
                       )
                     with
                     | Not_found ->
                       (
                         HT.add
                           src_port_anomaly_h_acc
                           src_port
                           [ anomaly_indice ]
                         ;
                       )
                   )
                 |  Admd.Filter.criteria.Dst_port dst_port ->
                   (
                     try
                       (
                         let l = HT.find dst_port_anomaly_h_acc dst_port in
                         let new_l = L.append l [ anomaly_indice ] in
                         HT.replace
                           dst_port_anomaly_h_acc
                           dst_port
                           new_l;
                       )
                     with
                     | Not_found ->
                       (
                         HT.add
                           dst_port_anomaly_h_acc
                           dst_port
                           [ anomaly_indice ]
                         ;
                       )
                   )
              )
              filter_criteria_list
            ;

            src_ipaddr_anomaly_h_acc,
            dst_ipaddr_anomaly_h_acc,
            transport_protocol_anomaly_h_acc,
            src_port_anomaly_h_acc,
            dst_port_anomaly_h_acc
        )
        (
          (HT.create 0),
          (HT.create 0),
          (HT.create 0),
          (HT.create 0),
          (HT.create 0)
        )
        anomaly_list
    in

    new_t
      src_ipaddr_anomaly_h
      dst_ipaddr_anomaly_h
      transport_protocol_anomaly_h
      src_port_anomaly_h
      dst_port_anomaly_h

      anomaly_h
  )

let get_anomaly_indice_list
    match_timestamps
    t

    timestamp_sec_start
    timestamp_sec_end
    five_tuple_flow
  =
  (* debug "get_anomaly_indice_list: call"; *)

  let src_ipaddr_indice_set =
    Int_set.of_list
      (try
         HT.find
           t.src_ipaddr_anomaly_h
           five_tuple_flow.Five_tuple_flow.src_addr
       with
       | Not_found -> []
      )
  in
  let dst_ipaddr_indice_set =
    Int_set.of_list
      (try
         HT.find
           t.dst_ipaddr_anomaly_h
           five_tuple_flow.Five_tuple_flow.dst_addr
       with
       | Not_found -> []
      )
  in
  let transport_protocol_indice_set =
    Int_set.of_list
      (try
         HT.find t.transport_protocol_anomaly_h
           (Transport_protocol_for_metrics.to_admd_transport_protocol
              five_tuple_flow.Five_tuple_flow.protocol
           )
       with
       | Not_found -> []
      )
  in
  let src_port_indice_set =
    Int_set.of_list
      (try
         HT.find
           t.src_port_anomaly_h
           five_tuple_flow.Five_tuple_flow.src_port
       with
       | Not_found -> []
      )
  in
  let dst_port_indice_set =
    Int_set.of_list
      (try
         HT.find
           t.dst_port_anomaly_h
           five_tuple_flow.Five_tuple_flow.dst_port
       with
       | Not_found -> []
      )
  in

  (* debug "get_anomaly_indice_list: building indice_set"; *)

  let indice_set =
    L.fold_left
      (fun int_set_acc int_set -> Int_set.union int_set_acc int_set)
      Int_set.empty
      [
        src_ipaddr_indice_set;
        dst_ipaddr_indice_set;
        transport_protocol_indice_set;
        src_port_indice_set;
        dst_port_indice_set;
      ]
  in

  (* debug "get_anomaly_indice_list: building anomaly_h_filtered"; *)

  let anomaly_h_filtered =
    HT.filter
      (fun anomaly->
         let anomaly_indice = anomaly.Base.Anomaly.indice in

         Int_set.mem
           anomaly_indice
           indice_set
      )
      t.anomaly_h
  in

  (* debug "get_anomaly_indice_list: building anomaly_h_filtered_2"; *)

  let anomaly_h_filtered_2 =
    HT.filter
      (fun anomaly->
         Base.Anomaly.match_flow
           timestamp_sec_start
           0
           timestamp_sec_end
           0
           match_timestamps
           (* nb_packets *)
           five_tuple_flow.Five_tuple_flow.src_addr
           five_tuple_flow.Five_tuple_flow.dst_addr
           (Transport_protocol_for_metrics.to_admd_transport_protocol
              five_tuple_flow.Five_tuple_flow.protocol
           )
           five_tuple_flow.Five_tuple_flow.src_port
           five_tuple_flow.Five_tuple_flow.dst_port

           anomaly
      )
      anomaly_h_filtered
  in

  (* debug "get_anomaly_indice_list: end"; *)

  L.map
    snd
    (L.of_enum
       (HT.enum
          anomaly_h_filtered_2
       )
    )

(* let map_to_hashtbl *)
(*     f *)
(*     t *)
(*   = *)
(*   Simple_key_data_container.map_to_hashtbl *)
(*     f *)
(*     t.container *)

(* let find *)
(*     t *)
(*     five_tuple_flow *)
(*   = *)
(*   Simple_key_data_container.find *)
(*     t.container *)
(*     five_tuple_flow *)
