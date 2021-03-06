
open Printf

module L = List_ext
module HT = Hashtbl_ext

open Admd.Instantiation
open Set_ext_instantiations
    
let debug_enabled = ref false

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
    
    src_ipaddr_anomaly_h : (Ipaddr.t, Int_set.t) HT.t;
    dst_ipaddr_anomaly_h : (Ipaddr.t, Int_set.t) HT.t;
    transport_protocol_anomaly_h : ( Admd.Transport_protocol.t, Int_set.t) HT.t;
    src_port_anomaly_h : (int, Int_set.t) HT.t;
    dst_port_anomaly_h : (int, Int_set.t) HT.t;
    
    (* anomaly_h : (int, Base.Anomaly.t) HT.t; *)
    anomaly_data_h : (int, (Admd.Slice.t list * int * int * int * int)) HT.t;
  }

let new_t
    src_ipaddr_anomaly_h
    dst_ipaddr_anomaly_h
    transport_protocol_anomaly_h
    src_port_anomaly_h
    dst_port_anomaly_h

    anomaly_data_h
  =
  {
    src_ipaddr_anomaly_h;
    dst_ipaddr_anomaly_h;
    transport_protocol_anomaly_h;
    src_port_anomaly_h;
    dst_port_anomaly_h;

    anomaly_data_h;
  }

let to_string t =
  sprintf
    "Five_tuple_flow_anomaly_indice_container:\nsrc_ipaddr_anomaly_h:\n%s\n\ndst_ipaddr_anomaly_h:\n%s\n\ntransport_protocol_anomaly_h:\n%s\n\nsrc_port_anomaly_h:\n%s\n\ndst_port_anomaly_h\n%s\n\n"
    (L.to_string
       ~sep: "\n"
       (fun (ipaddr, anomaly_indice_l) ->
          sprintf
            "%s: %s"
            (Ipaddr.to_string ipaddr)
            (* (L.to_string string_of_int anomaly_indice_l) *)
            (Int_set.to_string anomaly_indice_l)
       )
       (L.sort
          (fun (ipaddr1, _) (ipaddr2, _) ->
             Ipaddr.compare ipaddr1 ipaddr2
          )
          (L.of_enum (HT.enum t.src_ipaddr_anomaly_h))
       )
    )
    (L.to_string
       ~sep: "\n"
       (fun (ipaddr, anomaly_indice_l) ->
          sprintf
            "%s: %s"
            (Ipaddr.to_string ipaddr)
            (* (L.to_string string_of_int anomaly_indice_l) *)
            (Int_set.to_string anomaly_indice_l)
       )
       (L.sort
          (fun (ipaddr1, _) (ipaddr2, _) ->
             Ipaddr.compare ipaddr1 ipaddr2
          )
          (L.of_enum (HT.enum t.dst_ipaddr_anomaly_h))
       )
    )

    (L.to_string
       ~sep: "\n"
       (fun (ipaddr, anomaly_indice_l) ->
          sprintf
            "%s: %s"
            ( Admd.Transport_protocol.to_string ipaddr)
            (* (L.to_string string_of_int anomaly_indice_l) *)
            (Int_set.to_string anomaly_indice_l)
       )
       (L.sort
          (fun (ipaddr1, _) (ipaddr2, _) ->
              Admd.Transport_protocol.compare ipaddr1 ipaddr2
          )
          (L.of_enum (HT.enum t.transport_protocol_anomaly_h))
       )
    )

    (L.to_string
       ~sep: "\n"
       (fun (port, anomaly_indice_l) ->
          sprintf
            "%d: %s"
            port
            (* (L.to_string string_of_int anomaly_indice_l) *)
            (Int_set.to_string anomaly_indice_l)
       )
       (L.sort
          (fun (port1, _) (port2, _) ->
             compare port1 port2
          )
          (L.of_enum (HT.enum t.src_port_anomaly_h))
       )
    )
    (L.to_string
       ~sep: "\n"
       (fun (port, anomaly_indice_l) ->
          sprintf
            "%d: %s"
            port
            (* (L.to_string string_of_int anomaly_indice_l) *)
            (Int_set.to_string anomaly_indice_l)
       )
       (L.sort
          (fun (port1, _) (port2, _) ->
             compare port1 port2
          )
          (L.of_enum (HT.enum t.dst_port_anomaly_h))
       )
    )

let length t = HT.length t.anomaly_data_h

let of_anomaly_data_list
    l
  =
  (
    let anomaly_data_h =
      HT.of_enum
        (L.enum
           (L.map
              (fun (anomaly_indice, (admd_indice, slice_list, start_sec, start_usec, stop_sec, stop_usec)) ->
                 anomaly_indice, (slice_list, start_sec, start_usec, stop_sec, stop_usec)
              )
              l
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
          (anomaly_indice, (_, slice_list, _, _, _, _))
          ->
            (* let anomaly_indice = anomaly.Base.Anomaly.indice in *)

            let filter_criteria_list_list =
              Batteries.List.fold_left
                (fun acc slice ->
                   Batteries.List.append
                     acc
                     (
                       Batteries.List.map
                         (fun filter ->
                            filter.Admd.Filter.filter_criteria_list 
                         )
                         slice. Admd.Slice.filter_list
                     )
                )
                []
                slice_list
            in

            let filter_criteria_list = L.flatten filter_criteria_list_list in

            L.iter
              (fun filter_criteria ->
                 match filter_criteria with
                 | Admd.Filter_criteria.Src_ip src_addr ->
                   (
                     let ipaddr =  Admd.Ipaddr_sb.to_ipaddr src_addr in
                     try
                       (
                         let s = HT.find src_ipaddr_anomaly_h_acc ipaddr in
                         let new_s = Int_set.add anomaly_indice s in
                         HT.replace
                           src_ipaddr_anomaly_h_acc
                           ipaddr
                           new_s;
                       )
                     with
                     | Not_found ->
                       (
                         HT.add
                           src_ipaddr_anomaly_h_acc
                           ipaddr
                           (Int_set.singleton anomaly_indice)
                         ;
                       )
                   )
                 | Admd.Filter_criteria.Dst_ip dst_addr ->
                   (
                     let ipaddr =  Admd.Ipaddr_sb.to_ipaddr dst_addr in
                     try
                       (
                         let s = HT.find dst_ipaddr_anomaly_h_acc ipaddr in
                         let new_s = Int_set.add anomaly_indice s in
                         HT.replace
                           dst_ipaddr_anomaly_h_acc
                           ipaddr
                           new_s;
                       )
                     with
                     | Not_found ->
                       (
                         HT.add
                           dst_ipaddr_anomaly_h_acc
                           ipaddr
                           (Int_set.singleton anomaly_indice)
                         ;
                       )
                   )
                 | Admd.Filter_criteria.Transport_protocol transport_protocol ->
                   (
                     try
                       (
                         let s = HT.find transport_protocol_anomaly_h_acc transport_protocol in
                         let new_s = Int_set.add anomaly_indice s in
                         HT.replace
                           transport_protocol_anomaly_h_acc
                           transport_protocol
                           new_s;
                       )
                     with
                     | Not_found ->
                       (
                         HT.add
                           transport_protocol_anomaly_h_acc
                           transport_protocol
                           (Int_set.singleton anomaly_indice)
                         ;
                       )
                   )
                 | Admd.Filter_criteria.Src_port src_port ->
                   (
                     try
                       (
                         let s = HT.find src_port_anomaly_h_acc src_port in
                         let new_s = Int_set.add anomaly_indice s in
                         HT.replace
                           src_port_anomaly_h_acc
                           src_port
                           new_s;
                       )
                     with
                     | Not_found ->
                       (
                         HT.add
                           src_port_anomaly_h_acc
                           src_port
                           (Int_set.singleton anomaly_indice)
                         ;
                       )
                   )
                 | Admd.Filter_criteria.Dst_port dst_port ->
                   (
                     try
                       (
                         let s = HT.find dst_port_anomaly_h_acc dst_port in
                         let new_s = Int_set.add anomaly_indice s in
                         HT.replace
                           dst_port_anomaly_h_acc
                           dst_port
                           new_s;
                       )
                     with
                     | Not_found ->
                       (
                         HT.add
                           dst_port_anomaly_h_acc
                           dst_port
                           (Int_set.singleton anomaly_indice)
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
        l
    in

    let t : t =
      new_t
        src_ipaddr_anomaly_h
        dst_ipaddr_anomaly_h
        transport_protocol_anomaly_h
        src_port_anomaly_h
        dst_port_anomaly_h

        anomaly_data_h
    in

    t
    (* anomaly_h *)
  )

let get_anomaly_data_list_for_timestamp_five_tuple_flow
    t

    match_timestamp

    timestamp_start_sec
    timestamp_start_usec
    timestamp_stop_sec
    timestamp_stop_usec

    five_tuple_flow
  =
  (* debug "get_anomaly_indice_list: call"; *)

  let src_ipaddr_indice_set =
    try
      HT.find
        t.src_ipaddr_anomaly_h
        five_tuple_flow.Five_tuple_flow.src_addr
    with
    | Not_found -> Int_set.empty
  in
  let dst_ipaddr_indice_set =
    try
      HT.find
        t.dst_ipaddr_anomaly_h
        five_tuple_flow.Five_tuple_flow.dst_addr
    with
    | Not_found -> Int_set.empty
  in
  let transport_protocol_indice_set =
    try
      HT.find t.transport_protocol_anomaly_h
        (Transport_protocol_for_metrics.to_admd_transport_protocol
           five_tuple_flow.Five_tuple_flow.protocol
        )
    with
    | Not_found -> Int_set.empty
  in
  let src_port_indice_set =
    try
      HT.find
        t.src_port_anomaly_h
        five_tuple_flow.Five_tuple_flow.src_port
    with
    | Not_found -> Int_set.empty
  in
  let dst_port_indice_set =
    try
      HT.find
        t.dst_port_anomaly_h
        five_tuple_flow.Five_tuple_flow.dst_port
    with
    | Not_found -> Int_set.empty
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

  (* debug "get_anomaly_indice_list: indice_set: %s" (Int_set.to_string indice_set); *)

  (* debug "get_anomaly_indice_list: building anomaly_h_filtered"; *)

  let anomaly_h_filtered =
    HT.filteri
      (fun anomaly_indice _ ->
         (* let anomaly_indice = anomaly.Base.Anomaly.indice in *)

         Int_set.mem
           anomaly_indice
           indice_set
      )
      t.anomaly_data_h
  in

  (* debug "get_anomaly_indice_list: building anomaly_h_filtered_2"; *)

  let anomaly_h_filtered_2 =
    HT.filter
      (fun (slice_l, start_sec, start_usec, stop_sec, stop_usec) ->
         Base.Anomaly.match_flow_data
           timestamp_start_sec
           timestamp_start_usec           
           timestamp_stop_sec          
           timestamp_stop_usec

           match_timestamp

           (* nb_packets *)
           five_tuple_flow.Five_tuple_flow.src_addr
           five_tuple_flow.Five_tuple_flow.dst_addr
           (Transport_protocol_for_metrics.to_admd_transport_protocol
              five_tuple_flow.Five_tuple_flow.protocol
           )
           five_tuple_flow.Five_tuple_flow.src_port
           five_tuple_flow.Five_tuple_flow.dst_port

           (* anomaly *)
           slice_l

           start_sec
           start_usec
           stop_sec
           stop_usec
      )
      anomaly_h_filtered
  in

  (* debug "get_anomaly_indice_list: end"; *)

  (* L.map *)
  (* snd *)
  L.map
    (fun (i, (slice_l, start_sec, start_usec, stop_sec, stop_usec)) ->
       i, slice_l, start_sec, start_usec, stop_sec, stop_usec
    )
    (L.of_enum
       (HT.enum
          anomaly_h_filtered_2
       )
    )

let get_anomaly_data_list_for_five_tuple_flow
    t

    five_tuple_flow
  =
  (* debug "get_anomaly_indice_list: call"; *)

  (* debug "get_anomaly_indice_list: five_tuple_flow: %s" (Five_tuple_flow.to_string five_tuple_flow); *)

  let src_ipaddr_indice_set =
    try
      HT.find
        t.src_ipaddr_anomaly_h
        five_tuple_flow.Five_tuple_flow.src_addr
    with
    | Not_found -> Int_set.empty
  in
  let dst_ipaddr_indice_set =
    try
      HT.find
        t.dst_ipaddr_anomaly_h
        five_tuple_flow.Five_tuple_flow.dst_addr
    with
    | Not_found -> Int_set.empty
  in
  let transport_protocol_indice_set =
    try
      HT.find t.transport_protocol_anomaly_h
        (Transport_protocol_for_metrics.to_admd_transport_protocol
           five_tuple_flow.Five_tuple_flow.protocol
        )
    with
    | Not_found -> Int_set.empty
  in
  let src_port_indice_set =
    try
      HT.find
        t.src_port_anomaly_h
        five_tuple_flow.Five_tuple_flow.src_port
    with
    | Not_found -> Int_set.empty
  in
  let dst_port_indice_set =
    try
      HT.find
        t.dst_port_anomaly_h
        five_tuple_flow.Five_tuple_flow.dst_port
    with
    | Not_found -> Int_set.empty
  in

  (* This set contain all the anomaly indice that match at least one
     of the components of the 5-tuple flow. *)
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

  (* debug *)
  (*   "get_anomaly_indice_list: indice_set: %s" *)
  (*   (Int_set.to_string indice_set); *)

  (* debug "get_anomaly_indice_list: filtering anomaly_data_h"; *)

  (* Filter anomaly data whose indice matches at least one of the
     components of 5-tuple flow. *)
  (* let anomaly_h_filtered = *)
  (*   HT.filteri *)
  (*     (fun anomaly_indice _ -> *)
  (*        Int_set.mem *)
  (*          anomaly_indice *)
  (*          indice_set *)
  (*     ) *)
  (*     t.anomaly_data_h *)
  (* in *)
  let anomaly_h_filtered =
    Int_set.fold
      (fun anomaly_indice h ->
         let data =
           HT.find
             t.anomaly_data_h
             anomaly_indice
         in

         HT.add
           h
           anomaly_indice
           data;

         h
      )
      indice_set
      (HT.create 0)
  in

  (* Filter anomaly data whose indice matches all components of
     5-tuple flow. *)
  let anomaly_h_filtered_2 =
    HT.filter
      (fun (slice_l, start_sec, start_usec, stop_sec, stop_usec) ->
         Base.Anomaly.match_flow_data
           0
           0
           0
           0
           false

           five_tuple_flow.Five_tuple_flow.src_addr
           five_tuple_flow.Five_tuple_flow.dst_addr
           (Transport_protocol_for_metrics.to_admd_transport_protocol
              five_tuple_flow.Five_tuple_flow.protocol
           )
           five_tuple_flow.Five_tuple_flow.src_port
           five_tuple_flow.Five_tuple_flow.dst_port

           (* anomaly *)
           slice_l
           start_sec
           start_usec
           stop_sec
           stop_usec
      )
      anomaly_h_filtered
  in

  (* if HT.length anomaly_h_filtered <> HT.length anomaly_h_filtered_2 then *)
  (*   ( *)
  (*     print_endline *)
  (*       (sprintf *)
  (*          "[Five_tuple_flow_anomaly_indice_container]: get_anomaly_indice_list: anomaly_h_filtered length (%d) <> anomaly_h_filtered_2 length (%d):\n%s\n\n%s" *)
  (*          (HT.length anomaly_h_filtered) *)
  (*          (HT.length anomaly_h_filtered_2) *)
  (*          (HT.to_string *)
  (*             (fun (slice_l, start_time, end_time) -> *)
  (*                sprintf *)
  (*                  "%s: %d %d" *)
  (*                  (L.to_string *)
  (*                     ~sep: "-" *)
  (*                     Admd.Slice.to_string *)
  (*                     slice_l *)
  (*                  ) *)
  (*                  start_time *)
  (*                  end_time *)
  (*             ) *)
  (*             anomaly_h_filtered *)
  (*          ) *)
  (*          (HT.to_string *)
  (*             (fun (slice_l, start_time, end_time) -> *)
  (*                sprintf *)
  (*                  "%s: %d %d" *)
  (*                  (L.to_string *)
  (*                     Admd.Slice.to_string *)
  (*                     slice_l *)
  (*                  ) *)
  (*                  start_time *)
  (*                  end_time *)
  (*             ) *)
  (*             anomaly_h_filtered_2 *)
  (*          ) *)
  (*       ); *)

  (*     assert(false) *)
  (*   ); *)

  let l =
    L.map
      (fun (i, (slice_l, start_sec, start_usec, stop_sec, stop_usec)) ->
         i, slice_l, start_sec, start_usec, stop_sec, stop_usec
      )
      (L.of_enum
         (HT.enum
            anomaly_h_filtered_2
         )
      )
  in

  (* debug "get_anomaly_indice_list: end"; *)

  l
    
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
