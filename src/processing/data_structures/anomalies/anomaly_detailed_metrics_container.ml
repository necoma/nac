
open Printf

module A = BatArray
module L = BatList
module S = BatString
module HT = BatHashtbl

open Admd.Instantiation

module Five_tuple_flow_set = Set_ext.Make(Five_tuple_flow)
    
let debug_enabled = ref true

let set_debug bool = debug_enabled := bool

let debug fmt =
  Printf.kprintf
    (
      if !debug_enabled then
        (fun s -> Format.printf "[Anomaly_detailed_metrics_container]: %s@." s)
      else
        ignore
    )
    fmt

type t =
  {
    detailed_metrics_h : (int, Detailed_metrics.t) HT.t;
    anomaly_metric_h : (int, Anomaly_metric.t) HT.t;
  }

let new_t
    detailed_metrics_h
    anomaly_metric_h
    =
  {
    detailed_metrics_h;
    anomaly_metric_h;
  }

let to_string to_string_mode t =
  Hashtbl_ext.to_string
    ~sep_element: "\n\n"
    ~sep_key_value: ": "
    ~to_string_key: (fun key -> sprintf "%d" key)
    (fun detailed_metrics -> Detailed_metrics.to_string detailed_metrics)
    t.detailed_metrics_h

let length t = Hashtbl.length t.detailed_metrics_h

let filter_indice f t =
  new_t
    (HT.filteri
       (fun key _ ->
          f key
       )
       t.detailed_metrics_h
    )
    (HT.filteri
       (fun key _ ->
          f key
       )
       t.anomaly_metric_h
    )

let find_detailed_metrics indice t = Hashtbl.find t.detailed_metrics_h indice 
let find_anomaly_metric indice t = Hashtbl.find t.anomaly_metric_h indice 

let fold_detailed_metrics f t acc = Hashtbl.fold f t.detailed_metrics_h acc
let fold_anomaly_metric f t acc = Hashtbl.fold f t.anomaly_metric_h acc

let to_list t =
  (
    let h =
      Core_kernel.Core_int.Map.merge
        (Core_kernel.Core_int.Map.of_alist_exn
           (L.of_enum
              (HT.enum
                 t.detailed_metrics_h
              )
           )
        )
        (Core_kernel.Core_int.Map.of_alist_exn
           (L.of_enum
              (HT.enum
                 t.anomaly_metric_h
              )
           )
        )
        (fun ~key: indice data ->
           match data with
           | `Left _ ->
             failwith
               (sprintf
                  "[Anomaly_detailed_metrics_container]: to_list: only detailed_metrics for %d"
                  indice
               )
           | `Right _ ->
             failwith
               (sprintf
                  "[Anomaly_detailed_metrics_container]: to_list: only detailed_metrics for %d"
                  indice
               )
           | `Both (detailed_metrics, anomaly_metric) ->
             Some (detailed_metrics, anomaly_metric)
        )
    in

    Core_kernel.Core_int.Map.to_alist
      h
  )
    
let of_list l =
  new_t
    (HT.of_enum
       (L.enum
          (L.map (fun (i, tuple) -> i, fst tuple) l)
       )
    )
    (HT.of_enum
       (L.enum
          (L.map (fun (i, tuple) -> i, snd tuple) l)
       )
    )
  
let to_list_detailed_metrics t =
  L.of_enum
    (HT.enum
       t.detailed_metrics_h
    )
     
let to_list_anomaly_metric t =
  L.of_enum
    (HT.enum
       t.anomaly_metric_h
    )
     
let of_hashtables
    get_five_tuple_flow_metric_f
    
    anomaly_slice_time_data_container

    five_tuple_flow_set_detailed_metrics_tuple_hashtable
  =
  debug "of_hashtables: call";

  (* Completing metrics for anomalies with empty traffic *)
  (* Base.Anomaly_container.iter *)
  (*   (fun anomaly -> *)
  (*      try *)
  (*        ( *)
  (*          let _detailed_metrics_found = *)
  (*            Hashtbl.find *)
  (*              five_tuple_flow_set_detailed_metrics_tuple_hashtable  *)
  (*              anomaly.Base.Anomaly.indice *)
  (*          in *)

  (*          () *)
  (*        ) *)
  (*      with *)
  (*      | Not_found -> *)
  (*        ( *)
  (*          Hashtbl.add *)
  (*            five_tuple_flow_set_detailed_metrics_tuple_hashtable *)
  (*            anomaly.Base.Anomaly.indice  *)
  (*            (Five_tuple_flow_data_structures.Five_tuple_flow_hashset.empty, Detailed_metrics.new_empty_t ()) *)
  (*        ) *)
  (*   ) *)
  (*   anomaly_container; *)
  Anomaly_slice_time_data_container.iter
    (fun indice _ ->
       try
         (
           let _detailed_metrics_found =
             Hashtbl.find
               five_tuple_flow_set_detailed_metrics_tuple_hashtable 
               indice
           in

           ()
         )
       with
       | Not_found ->
         (
           Hashtbl.add
             five_tuple_flow_set_detailed_metrics_tuple_hashtable
             indice 
             (Five_tuple_flow_data_structures.Five_tuple_flow_hashset.empty, Detailed_metrics.new_empty_t ())
         )
    )
    anomaly_slice_time_data_container;
  

  assert(
    (* Base.Anomaly_container.length anomaly_container *)
     Anomaly_slice_time_data_container.length anomaly_slice_time_data_container
    =
    HT.length five_tuple_flow_set_detailed_metrics_tuple_hashtable
  );

  let five_tuple_flow_count_hashtable =
    HT.fold
      (fun indice (five_tuple_flow_set, _) count_hashtable ->
         Five_tuple_flow_data_structures.Five_tuple_flow_hashset.iter
           (fun five_tuple_flow ->
              try
                (
                  let anomaly_count =
                    Batteries.Hashtbl.find
                      count_hashtable
                      five_tuple_flow
                  in

                  Batteries.Hashtbl.replace
                    count_hashtable
                    five_tuple_flow
                    (anomaly_count + 1);
                )
              with
              | Not_found ->
                (
                  Batteries.Hashtbl.add
                    count_hashtable
                    five_tuple_flow
                    1;
                )
           )
           five_tuple_flow_set;

         count_hashtable
      )
      five_tuple_flow_set_detailed_metrics_tuple_hashtable
      (HT.create 0)
  in

  let detailed_metrics_hashtable =
    Batteries.Hashtbl.map
      (fun _ (_, detailed_metrics) -> detailed_metrics)
      five_tuple_flow_set_detailed_metrics_tuple_hashtable
  in

  let anomaly_metric_hashtable =
    Batteries.Hashtbl.map
      (fun indice (five_tuple_flow_set, _) ->
         let flow_number = Five_tuple_flow_data_structures.Five_tuple_flow_hashset.cardinal five_tuple_flow_set in

         let packet_number, byte_number =
           Five_tuple_flow_data_structures.Five_tuple_flow_hashset.fold
             (fun five_tuple_flow (packet_number_acc, byte_number_acc) ->
                let five_tuple_flow_metrics =
                  get_five_tuple_flow_metric_f
                    indice
                    five_tuple_flow
                in

                let anomaly_number_for_five_tuple_flow =
                  HT.find
                    five_tuple_flow_count_hashtable
                    five_tuple_flow
                in

                let packet_number = 
                  float_of_int five_tuple_flow_metrics.Five_tuple_flow_metrics.nb_packets 
                  /.
                  float_of_int anomaly_number_for_five_tuple_flow
                in
                let byte_number =
                  float_of_int five_tuple_flow_metrics.Five_tuple_flow_metrics.nb_bytes
                  /.
                  float_of_int anomaly_number_for_five_tuple_flow
                in

                (packet_number_acc +. packet_number, byte_number_acc +. byte_number)
             )
             five_tuple_flow_set
             (0., 0.)
         in

         Anomaly_metric.new_t
           (float_of_int flow_number)
           packet_number
           byte_number
      )
      five_tuple_flow_set_detailed_metrics_tuple_hashtable
  in

  debug "of_hashtables: end";

  new_t
    detailed_metrics_hashtable
    anomaly_metric_hashtable

let of_anomaly_container_five_tuple_flow_metrics_container______old
    parallelization_mode

    check_five_tuple_flow_metrics_timestamp
    
    five_tuple_flow_metrics_container
    five_tuple_key_five_tuple_flow_set_container

    anomaly_container
    anomaly_slice_time_data_container
  =
  (
    debug "of_anomaly_container_five_tuple_flow_metrics_container: call";

    let nb_five_tuple_flow =
      Five_tuple_flow_metrics_container.length
        five_tuple_flow_metrics_container
    in
    let nb_anomaly = Base.Anomaly_container.length anomaly_container in

    let anomaly_list = Base.Anomaly_container.to_list anomaly_container in

    let get_five_tuple_flow_set_of_filter_criteria filter_criteria =
      match filter_criteria with
      | Admd.Filter_criteria.Src_ip src_addr ->
        Five_tuple_key_five_tuple_flow_set_container.find_src_addr
          five_tuple_key_five_tuple_flow_set_container
          ( Admd.Ipaddr_sb.to_ipaddr src_addr)
      | Admd.Filter_criteria.Dst_ip dst_addr ->
        Five_tuple_key_five_tuple_flow_set_container.find_dst_addr
          five_tuple_key_five_tuple_flow_set_container
          ( Admd.Ipaddr_sb.to_ipaddr dst_addr)
      | Admd.Filter_criteria.Transport_protocol transport_protocol ->
        Five_tuple_key_five_tuple_flow_set_container.find_admd_transport_protocol
          five_tuple_key_five_tuple_flow_set_container
          transport_protocol
      | Admd.Filter_criteria.Src_port src_port ->
        Five_tuple_key_five_tuple_flow_set_container.find_src_port
          five_tuple_key_five_tuple_flow_set_container
          src_port
      | Admd.Filter_criteria.Dst_port dst_port ->
        Five_tuple_key_five_tuple_flow_set_container.find_dst_port
          five_tuple_key_five_tuple_flow_set_container
          dst_port
    in

    let five_tuple_flow_count_hashtable, five_tuple_flow_set_detailed_metrics_tuple_hashtable =
      Execution_time_measure.execute
        "[Anomaly_detailed_metrics_container]: of_anomaly_container_five_tuple_flow_metrics_container: assigning five tuple flows to anomalies"
        (fun _ ->
           List.fold_left
             (fun (count_hashtable, tuple_hashtable) anomaly ->
                (
                  let anomaly_indice = anomaly.Base.Anomaly.indice in

                  let filter_criteria_list_list =
                    Batteries.List.fold_left
                      (fun acc slice ->
                         Batteries.List.append
                           acc
                           (
                             Batteries.List.map
                               (fun filter ->
                                  filter. Admd.Filter.filter_criteria_list 
                               )
                               slice. Admd.Slice.filter_list
                           )
                      )
                      []
                      anomaly.Base.Anomaly.slice_list
                  in

                  if List.length filter_criteria_list_list = 0 then
                    (count_hashtable, tuple_hashtable)
                  else    
                    (* five_tuple_flow_set list for all slices and filters *)
                    let five_tuple_flow_set_list =
                      Batteries.List.map
                        (fun filter_criteria_list ->
                           (* We get all five_tuple_flow that match each filter_criteria separately. *)
                           let five_tuple_flow_set_list =
                             Batteries.List.map
                               get_five_tuple_flow_set_of_filter_criteria
                               filter_criteria_list
                           in

                           assert(List.length five_tuple_flow_set_list > 0);

                           (* We only keep five_tuple_flow that match all filter_criteria. *)
                           Batteries.List.fold_left
                             (fun acc five_tuple_flow_set ->
                                Five_tuple_flow_data_structures.Five_tuple_flow_hashset.inter acc five_tuple_flow_set
                             )
                             (Batteries.List.hd five_tuple_flow_set_list)
                             (Batteries.List.tl five_tuple_flow_set_list)
                        )
                        filter_criteria_list_list
                    in

                    assert(List.length five_tuple_flow_set_list > 0);

                    let five_tuple_flow_set =
                      Batteries.List.fold_left
                        (fun acc five_tuple_flow_set ->
                           Five_tuple_flow_data_structures.Five_tuple_flow_hashset.union acc five_tuple_flow_set
                        )
                        (Batteries.List.hd five_tuple_flow_set_list)
                        (Batteries.List.tl five_tuple_flow_set_list)
                    in

                    (* (\* Verify flow membership *\) *)
                    (* Five_tuple_flow_set.iter *)
                    (*   (fun five_tuple_flow -> *)
                    (*     let src_addr, *)
                    (*       dst_addr, *)
                    (*       proto, *)
                    (*       src_port, *)
                    (*       dst_port *)
                    (*       = *)
                    (*       Five_tuple_flow.to_five_tuple *)
                    (*   five_tuple_flow *)
                    (*     in *)

                    (*     let five_tuple_flow_metrics = *)
                    (*       Five_tuple_flow_metrics_container.find *)
                    (*   five_tuple_flow_metrics_container *)
                    (*   five_tuple_flow *)
                    (*     in *)

                    (*     let compare_result = *)
                    (*       Mawilab_admd.Anomaly.match_flow *)
                    (*   five_tuple_flow_metrics.Five_tuple_flow_metrics.timestamp_sec_start *)
                    (*   five_tuple_flow_metrics.Five_tuple_flow_metrics.timestamp_usec_start *)
                    (*   five_tuple_flow_metrics.Five_tuple_flow_metrics.timestamp_sec_end *)
                    (*   five_tuple_flow_metrics.Five_tuple_flow_metrics.timestamp_usec_end *)
                    (*   false *)
                    (*   (\* five_tuple_flow_metrics.Five_tuple_flow_metrics.nb_packets *\) *)
                    (*   src_addr *)
                    (*   dst_addr *)
                    (*   (Transport_protocol_translation.transport_protocol_for_metrics_to_admd_transport_protocol proto) *)
                    (*   src_port *)
                    (*   dst_port *)
                    (*   anomaly *)
                    (*     in *)

                    (*     if compare_result = false then *)
                    (*       ( *)
                    (*   print_endline *)
                    (*     (sprintf *)
                    (*        "Anomaly_detailed_metrics_container: of_anomaly_container_five_tuple_flow_metrics_container: problem with:\n%s\n%s" *)
                    (*        (Five_tuple_flow.to_string five_tuple_flow) *)
                    (*        (Mawilab_admd.Anomaly.to_string To_string_mode.Normal anomaly) *)
                    (*     ); *)
                    (*   assert(false); *)
                    (*       ); *)
                    (*   ) *)
                    (*   five_tuple_flow_set; *)

                    Five_tuple_flow_data_structures.Five_tuple_flow_hashset.iter
                      (fun five_tuple_flow ->
                         try
                           (
                             let anomaly_count =
                               Batteries.Hashtbl.find
                                 count_hashtable
                                 five_tuple_flow
                             in

                             Batteries.Hashtbl.replace
                               count_hashtable
                               five_tuple_flow
                               (anomaly_count + 1);
                           )
                         with
                         | Not_found ->
                           (
                             Batteries.Hashtbl.add
                               count_hashtable
                               five_tuple_flow
                               1;
                           )
                      )
                      five_tuple_flow_set;

                    (* let detailed_metrics = *)
                    (*   Five_tuple_flow_set.fold *)
                    (*     (fun five_tuple_flow acc -> *)
                    (*       let five_tuple_flow_metrics = *)
                    (*         Five_tuple_flow_metrics_container.find *)
                    (*     five_tuple_flow_metrics_container *)
                    (*     five_tuple_flow *)
                    (*       in *)

                    (*       let detailed_metrics = *)
                    (*         Detailed_metrics.of_five_tuple_flow_metrics *)
                    (*     five_tuple_flow *)
                    (*     five_tuple_flow_metrics *)
                    (*       in *)

                    (*       Detailed_metrics.append *)
                    (*         acc *)
                    (*         detailed_metrics; *)

                    (*       acc *)
                    (*     ) *)
                    (*     five_tuple_flow_set *)
                    (*     (Detailed_metrics.new_empty_t ())       *)
                    (* in *)

                    (* We avoid Detailed_metrics.new_empty_t because it causes problem
                       with updating of the start timestamp *)

                    (* If there are no five_tuple_flow for this anomaly, it
                       is empty => we use an empty detailed_metrics *)
                    let detailed_metrics =
                      if
                        Five_tuple_flow_data_structures.Five_tuple_flow_hashset.cardinal
                          five_tuple_flow_set = 0
                      then
                        Detailed_metrics.new_empty_t ()
                      else
                        let five_tuple_flow_list =
                          Five_tuple_flow_data_structures.Five_tuple_flow_hashset.elements
                            five_tuple_flow_set
                        in
                        let first_five_tuple_flow = List.hd five_tuple_flow_list in
                        let first_five_tuple_flow_metrics =
                          Five_tuple_flow_metrics_container.find
                            five_tuple_flow_metrics_container
                            first_five_tuple_flow
                        in
                        let first_detailed_metrics : Detailed_metrics.t =
                          Detailed_metrics.of_five_tuple_flow_metrics
                            ~check_five_tuple_flow_metrics_timestamp: check_five_tuple_flow_metrics_timestamp
                            first_five_tuple_flow 
                            first_five_tuple_flow_metrics
                        in

                        Batteries.List.fold_right
                          (fun five_tuple_flow (acc : Detailed_metrics.t) ->
                             let five_tuple_flow_metrics =
                               Five_tuple_flow_metrics_container.find
                                 five_tuple_flow_metrics_container
                                 five_tuple_flow
                             in

                             let detailed_metrics =
                               Detailed_metrics.of_five_tuple_flow_metrics
                                 ~check_five_tuple_flow_metrics_timestamp: check_five_tuple_flow_metrics_timestamp
                                 five_tuple_flow
                                 five_tuple_flow_metrics
                             in

                             (* print_endline *)
                             (*    (sprintf *)
                             (*       "Anomaly_detailed_metrics_container: of_anomaly_container_five_tuple_flow_metrics_container: acc before:\n%s\n\nnew detailed_metrics for %s:\n%s" *)
                             (*       (Detailed_metrics.to_string *)
                             (*          (\* To_string_mode.Simple *\) *)
                             (*          To_string_mode.Normal *)
                             (*          acc *)
                             (*       ) *)
                             (*       (Five_tuple_flow.to_string five_tuple_flow) *)
                             (*       (Detailed_metrics.to_string *)
                             (*          To_string_mode.Normal *)
                             (*          detailed_metrics *)
                             (*       ) *)
                             (*    ); *)

                             Detailed_metrics.append
                               acc
                               detailed_metrics;

                             acc
                          )
                          (List.tl five_tuple_flow_list)
                          first_detailed_metrics
                    in

                    Hashtbl.add
                      tuple_hashtable
                      anomaly_indice
                      (five_tuple_flow_set, detailed_metrics);

                    (count_hashtable, tuple_hashtable)
                )
             )
             ((Batteries.Hashtbl.create nb_five_tuple_flow), (Batteries.Hashtbl.create nb_anomaly))
             anomaly_list
        )
    in

    (* let detailed_metrics_hashtable = *)
    (*   Batteries.Hashtbl.map *)
    (*     (fun _ (_, detailed_metrics) -> detailed_metrics) *)
    (*     five_tuple_flow_set_detailed_metrics_tuple_hashtable *)
    (* in *)

    (* let anomaly_metric_hashtable = *)
    (*   Batteries.Hashtbl.map *)
    (*     (fun indice (five_tuple_flow_set, _) -> *)
    (*        let flow_number = Five_tuple_flow_data_structures.Five_tuple_flow_hashset.cardinal five_tuple_flow_set in *)

    (*        let packet_number, byte_number = *)
    (*          Five_tuple_flow_data_structures.Five_tuple_flow_hashset.fold *)
    (*            (fun five_tuple_flow (packet_number_acc, byte_number_acc) -> *)
    (*               let five_tuple_flow_metrics = *)
    (*                 Five_tuple_flow_metrics_container.find *)
    (*                   five_tuple_flow_metrics_container *)
    (*                   five_tuple_flow *)
    (*               in *)

    (*               let anomaly_number_for_five_tuple_flow = *)
    (*                 Hashtbl.find *)
    (*                   five_tuple_flow_count_hashtable *)
    (*                   five_tuple_flow *)
    (*               in *)

    (*               let packet_number =  *)
    (*                 float_of_int five_tuple_flow_metrics.Five_tuple_flow_metrics.nb_packets  *)
    (*                 /. *)
    (*                 float_of_int anomaly_number_for_five_tuple_flow *)
    (*               in *)
    (*               let byte_number = *)
    (*                 float_of_int five_tuple_flow_metrics.Five_tuple_flow_metrics.nb_bytes *)
    (*                 /. *)
    (*                 float_of_int anomaly_number_for_five_tuple_flow *)
    (*               in *)

    (*               (packet_number_acc +. packet_number, byte_number_acc +. byte_number) *)
    (*            ) *)
    (*            five_tuple_flow_set *)
    (*            (0., 0.) *)
    (*        in *)

    (*        Anomaly_metric.new_t *)
    (*          (float_of_int flow_number) *)
    (*          packet_number *)
    (*          byte_number *)
    (*     ) *)
    (*     five_tuple_flow_set_detailed_metrics_tuple_hashtable *)
    (* in *)

    let t =
      of_hashtables
        (fun _ five_tuple_flow ->
           Five_tuple_flow_metrics_container.find
             five_tuple_flow_metrics_container
             five_tuple_flow
        )
        (* five_tuple_flow_count_hashtable *)

        (* anomaly_container *)
        anomaly_slice_time_data_container
        
        five_tuple_flow_set_detailed_metrics_tuple_hashtable
    in 
    debug "of_anomaly_container_five_tuple_flow_metrics_container: end";

    (* new_t *)
    (*   detailed_metrics_hashtable *)
    (*   anomaly_metric_hashtable *)

    t
  )

let of_anomaly_container_five_tuple_flow_metrics_container
    parallelization_mode

    check_five_tuple_flow_metrics_timestamp
    
    five_tuple_flow_metrics_container
    five_tuple_key_five_tuple_flow_set_container

    (* anomaly_container *)
    (* anomaly_slice_time_data_container *)
    anomaly_slice_time_data_container
  =
  (
    debug "of_anomaly_container_five_tuple_flow_metrics_container: call";

    let nb_five_tuple_flow =
      Five_tuple_flow_metrics_container.length
        five_tuple_flow_metrics_container
    in
    (* let nb_anomaly = Base.Anomaly_container.length anomaly_container in *)

    (* let anomaly_list = Base.Anomaly_container.to_list anomaly_container in *)

    let nb_anomaly =
      Anomaly_slice_time_data_container.length
        anomaly_slice_time_data_container
    in

    let get_five_tuple_flow_set_of_filter_criteria filter_criteria =
      match filter_criteria with
      | Admd.Filter_criteria.Src_ip src_addr ->
        Five_tuple_key_five_tuple_flow_set_container.find_src_addr
          five_tuple_key_five_tuple_flow_set_container
          (Admd.Ipaddr_sb.to_ipaddr src_addr)
      | Admd.Filter_criteria.Dst_ip dst_addr ->
        Five_tuple_key_five_tuple_flow_set_container.find_dst_addr
          five_tuple_key_five_tuple_flow_set_container
          (Admd.Ipaddr_sb.to_ipaddr dst_addr)
      | Admd.Filter_criteria.Transport_protocol transport_protocol ->
        Five_tuple_key_five_tuple_flow_set_container.find_admd_transport_protocol
          five_tuple_key_five_tuple_flow_set_container
          transport_protocol
      | Admd.Filter_criteria.Src_port src_port ->
        Five_tuple_key_five_tuple_flow_set_container.find_src_port
          five_tuple_key_five_tuple_flow_set_container
          src_port
      | Admd.Filter_criteria.Dst_port dst_port ->
        Five_tuple_key_five_tuple_flow_set_container.find_dst_port
          five_tuple_key_five_tuple_flow_set_container
          dst_port
    in

    let five_tuple_flow_count_hashtable, five_tuple_flow_set_detailed_metrics_tuple_hashtable =
      Execution_time_measure.execute
        "[Anomaly_detailed_metrics_container]: of_anomaly_container_five_tuple_flow_metrics_container: assigning five tuple flows to anomalies"
        (fun _ ->
           List.fold_left
             (fun (count_hashtable, tuple_hashtable) (anomaly_indice, (_, slice_list, _, _, _, _)) ->
                (
                  (* let anomaly_indice = anomaly.Base.Anomaly.indice in *)

                  let filter_criteria_list_list =
                    Batteries.List.fold_left
                      (fun acc slice ->
                         Batteries.List.append
                           acc
                           (
                             Batteries.List.map
                               (fun filter ->
                                  filter. Admd.Filter.filter_criteria_list 
                               )
                               slice. Admd.Slice.filter_list
                           )
                      )
                      []
                      slice_list
                  in

                  if List.length filter_criteria_list_list = 0 then
                    (count_hashtable, tuple_hashtable)
                  else    
                    (* five_tuple_flow_set list for all slices and filters *)
                    let five_tuple_flow_set_list =
                      Batteries.List.map
                        (fun filter_criteria_list ->
                           (* We get all five_tuple_flow that match each filter_criteria separately. *)
                           let five_tuple_flow_set_list =
                             Batteries.List.map
                               get_five_tuple_flow_set_of_filter_criteria
                               filter_criteria_list
                           in

                           assert(List.length five_tuple_flow_set_list > 0);

                           (* We only keep five_tuple_flow that match all filter_criteria. *)
                           Batteries.List.fold_left
                             (fun acc five_tuple_flow_set ->
                                Five_tuple_flow_data_structures.Five_tuple_flow_hashset.inter acc five_tuple_flow_set
                             )
                             (Batteries.List.hd five_tuple_flow_set_list)
                             (Batteries.List.tl five_tuple_flow_set_list)
                        )
                        filter_criteria_list_list
                    in

                    assert(List.length five_tuple_flow_set_list > 0);

                    let five_tuple_flow_set =
                      Batteries.List.fold_left
                        (fun acc five_tuple_flow_set ->
                           Five_tuple_flow_data_structures.Five_tuple_flow_hashset.union acc five_tuple_flow_set
                        )
                        (Batteries.List.hd five_tuple_flow_set_list)
                        (Batteries.List.tl five_tuple_flow_set_list)
                    in

                    (* (\* Verify flow membership *\) *)
                    (* Five_tuple_flow_set.iter *)
                    (*   (fun five_tuple_flow -> *)
                    (*     let src_addr, *)
                    (*       dst_addr, *)
                    (*       proto, *)
                    (*       src_port, *)
                    (*       dst_port *)
                    (*       = *)
                    (*       Five_tuple_flow.to_five_tuple *)
                    (*   five_tuple_flow *)
                    (*     in *)

                    (*     let five_tuple_flow_metrics = *)
                    (*       Five_tuple_flow_metrics_container.find *)
                    (*   five_tuple_flow_metrics_container *)
                    (*   five_tuple_flow *)
                    (*     in *)

                    (*     let compare_result = *)
                    (*       Mawilab_admd.Anomaly.match_flow *)
                    (*   five_tuple_flow_metrics.Five_tuple_flow_metrics.timestamp_sec_start *)
                    (*   five_tuple_flow_metrics.Five_tuple_flow_metrics.timestamp_usec_start *)
                    (*   five_tuple_flow_metrics.Five_tuple_flow_metrics.timestamp_sec_end *)
                    (*   five_tuple_flow_metrics.Five_tuple_flow_metrics.timestamp_usec_end *)
                    (*   false *)
                    (*   (\* five_tuple_flow_metrics.Five_tuple_flow_metrics.nb_packets *\) *)
                    (*   src_addr *)
                    (*   dst_addr *)
                    (*   (Transport_protocol_translation.transport_protocol_for_metrics_to_admd_transport_protocol proto) *)
                    (*   src_port *)
                    (*   dst_port *)
                    (*   anomaly *)
                    (*     in *)

                    (*     if compare_result = false then *)
                    (*       ( *)
                    (*   print_endline *)
                    (*     (sprintf *)
                    (*        "Anomaly_detailed_metrics_container: of_anomaly_container_five_tuple_flow_metrics_container: problem with:\n%s\n%s" *)
                    (*        (Five_tuple_flow.to_string five_tuple_flow) *)
                    (*        (Mawilab_admd.Anomaly.to_string To_string_mode.Normal anomaly) *)
                    (*     ); *)
                    (*   assert(false); *)
                    (*       ); *)
                    (*   ) *)
                    (*   five_tuple_flow_set; *)

                    Five_tuple_flow_data_structures.Five_tuple_flow_hashset.iter
                      (fun five_tuple_flow ->
                         try
                           (
                             let anomaly_count =
                               Batteries.Hashtbl.find
                                 count_hashtable
                                 five_tuple_flow
                             in

                             Batteries.Hashtbl.replace
                               count_hashtable
                               five_tuple_flow
                               (anomaly_count + 1);
                           )
                         with
                         | Not_found ->
                           (
                             Batteries.Hashtbl.add
                               count_hashtable
                               five_tuple_flow
                               1;
                           )
                      )
                      five_tuple_flow_set;

                    (* let detailed_metrics = *)
                    (*   Five_tuple_flow_set.fold *)
                    (*     (fun five_tuple_flow acc -> *)
                    (*       let five_tuple_flow_metrics = *)
                    (*         Five_tuple_flow_metrics_container.find *)
                    (*     five_tuple_flow_metrics_container *)
                    (*     five_tuple_flow *)
                    (*       in *)

                    (*       let detailed_metrics = *)
                    (*         Detailed_metrics.of_five_tuple_flow_metrics *)
                    (*     five_tuple_flow *)
                    (*     five_tuple_flow_metrics *)
                    (*       in *)

                    (*       Detailed_metrics.append *)
                    (*         acc *)
                    (*         detailed_metrics; *)

                    (*       acc *)
                    (*     ) *)
                    (*     five_tuple_flow_set *)
                    (*     (Detailed_metrics.new_empty_t ())       *)
                    (* in *)

                    (* We avoid Detailed_metrics.new_empty_t because it causes problem
                       with updating of the start timestamp *)

                    (* If there are no five_tuple_flow for this anomaly, it
                       is empty => we use an empty detailed_metrics *)
                    let detailed_metrics =
                      if
                        Five_tuple_flow_data_structures.Five_tuple_flow_hashset.cardinal
                          five_tuple_flow_set = 0
                      then
                        Detailed_metrics.new_empty_t ()
                      else
                        let five_tuple_flow_list =
                          Five_tuple_flow_data_structures.Five_tuple_flow_hashset.elements
                            five_tuple_flow_set
                        in
                        let first_five_tuple_flow = List.hd five_tuple_flow_list in
                        let first_five_tuple_flow_metrics =
                          Five_tuple_flow_metrics_container.find
                            five_tuple_flow_metrics_container
                            first_five_tuple_flow
                        in
                        let first_detailed_metrics : Detailed_metrics.t =
                          Detailed_metrics.of_five_tuple_flow_metrics
                            ~check_five_tuple_flow_metrics_timestamp: check_five_tuple_flow_metrics_timestamp
                            first_five_tuple_flow 
                            first_five_tuple_flow_metrics
                        in

                        Batteries.List.fold_right
                          (fun five_tuple_flow (acc : Detailed_metrics.t) ->
                             let five_tuple_flow_metrics =
                               Five_tuple_flow_metrics_container.find
                                 five_tuple_flow_metrics_container
                                 five_tuple_flow
                             in

                             let detailed_metrics =
                               Detailed_metrics.of_five_tuple_flow_metrics
                                 ~check_five_tuple_flow_metrics_timestamp: check_five_tuple_flow_metrics_timestamp
                                 five_tuple_flow
                                 five_tuple_flow_metrics
                             in

                             (* print_endline *)
                             (*    (sprintf *)
                             (*       "Anomaly_detailed_metrics_container: of_anomaly_container_five_tuple_flow_metrics_container: acc before:\n%s\n\nnew detailed_metrics for %s:\n%s" *)
                             (*       (Detailed_metrics.to_string *)
                             (*          (\* To_string_mode.Simple *\) *)
                             (*          To_string_mode.Normal *)
                             (*          acc *)
                             (*       ) *)
                             (*       (Five_tuple_flow.to_string five_tuple_flow) *)
                             (*       (Detailed_metrics.to_string *)
                             (*          To_string_mode.Normal *)
                             (*          detailed_metrics *)
                             (*       ) *)
                             (*    ); *)

                             Detailed_metrics.append
                               acc
                               detailed_metrics;

                             acc
                          )
                          (List.tl five_tuple_flow_list)
                          first_detailed_metrics
                    in

                    Hashtbl.add
                      tuple_hashtable
                      anomaly_indice
                      (five_tuple_flow_set, detailed_metrics);

                    (count_hashtable, tuple_hashtable)
                )
             )
             ((Batteries.Hashtbl.create nb_five_tuple_flow), (Batteries.Hashtbl.create nb_anomaly))
             (Anomaly_slice_time_data_container.to_list
                anomaly_slice_time_data_container
             )
        )
    in

    (* let detailed_metrics_hashtable = *)
    (*   Batteries.Hashtbl.map *)
    (*     (fun _ (_, detailed_metrics) -> detailed_metrics) *)
    (*     five_tuple_flow_set_detailed_metrics_tuple_hashtable *)
    (* in *)

    (* let anomaly_metric_hashtable = *)
    (*   Batteries.Hashtbl.map *)
    (*     (fun indice (five_tuple_flow_set, _) -> *)
    (*        let flow_number = Five_tuple_flow_data_structures.Five_tuple_flow_hashset.cardinal five_tuple_flow_set in *)

    (*        let packet_number, byte_number = *)
    (*          Five_tuple_flow_data_structures.Five_tuple_flow_hashset.fold *)
    (*            (fun five_tuple_flow (packet_number_acc, byte_number_acc) -> *)
    (*               let five_tuple_flow_metrics = *)
    (*                 Five_tuple_flow_metrics_container.find *)
    (*                   five_tuple_flow_metrics_container *)
    (*                   five_tuple_flow *)
    (*               in *)

    (*               let anomaly_number_for_five_tuple_flow = *)
    (*                 Hashtbl.find *)
    (*                   five_tuple_flow_count_hashtable *)
    (*                   five_tuple_flow *)
    (*               in *)

    (*               let packet_number =  *)
    (*                 float_of_int five_tuple_flow_metrics.Five_tuple_flow_metrics.nb_packets  *)
    (*                 /. *)
    (*                 float_of_int anomaly_number_for_five_tuple_flow *)
    (*               in *)
    (*               let byte_number = *)
    (*                 float_of_int five_tuple_flow_metrics.Five_tuple_flow_metrics.nb_bytes *)
    (*                 /. *)
    (*                 float_of_int anomaly_number_for_five_tuple_flow *)
    (*               in *)

    (*               (packet_number_acc +. packet_number, byte_number_acc +. byte_number) *)
    (*            ) *)
    (*            five_tuple_flow_set *)
    (*            (0., 0.) *)
    (*        in *)

    (*        Anomaly_metric.new_t *)
    (*          (float_of_int flow_number) *)
    (*          packet_number *)
    (*          byte_number *)
    (*     ) *)
    (*     five_tuple_flow_set_detailed_metrics_tuple_hashtable *)
    (* in *)

    let t =
      of_hashtables
        (fun _ five_tuple_flow ->
           Five_tuple_flow_metrics_container.find
             five_tuple_flow_metrics_container
             five_tuple_flow
        )
        (* five_tuple_flow_count_hashtable *)

        (* anomaly_container *)
        anomaly_slice_time_data_container

        five_tuple_flow_set_detailed_metrics_tuple_hashtable
    in 
    debug "of_anomaly_container_five_tuple_flow_metrics_container: end";

    (* new_t *)
    (*   detailed_metrics_hashtable *)
    (*   anomaly_metric_hashtable *)

    t
  )

let of_anomaly_five_tuple_flow_metrics_container
    check_five_tuple_flow_metrics_timestamp
    
    anomaly_slice_time_data_container
    
    anomaly_five_tuple_flow_metrics_container
  =
  (
    debug "of_anomaly_five_tuple_flow_metrics_container: call";

    let h =
      Anomaly_five_tuple_flow_metrics_container.map_to_hashtbl
        (fun _ five_tuple_flow_metrics_container ->
           let l = Five_tuple_flow_metrics_container.to_list five_tuple_flow_metrics_container in

           let five_tuple_flow_l = L.map fst l in
           (* let five_tuple_flow_metrics_list = L.map snd l in *)

           let five_tuple_flow_set =
             Five_tuple_flow_set.of_list
               five_tuple_flow_l
           in
           let five_tuple_flow_hashset =
             Five_tuple_flow_data_structures.Five_tuple_flow_hashset.of_list
               five_tuple_flow_l
           in
           let five_tuple_flow_set_length =
             Five_tuple_flow_set.cardinal
               five_tuple_flow_set
           in

           assert(
             five_tuple_flow_set_length
             =
             L.length five_tuple_flow_l
           );

           let five_tuple_flow, five_tuple_flow_metrics = L.hd l in
           (* let first_five_tuple_flow_metrics = L.hd five_tuple_flow_metrics_list in *)
           let first_detailed_metrics : Detailed_metrics.t =
             Detailed_metrics.of_five_tuple_flow_metrics
               ~check_five_tuple_flow_metrics_timestamp: check_five_tuple_flow_metrics_timestamp
               five_tuple_flow
               five_tuple_flow_metrics
           in

           let detailed_metrics =
             Batteries.List.fold_right
               (fun (five_tuple_flow, five_tuple_flow_metrics) (acc : Detailed_metrics.t) ->
                  (* let five_tuple_flow_metrics = *)
                  (*   Five_tuple_flow_metrics_container.find *)
                  (*     five_tuple_flow_metrics_container *)
                  (*     five_tuple_flow *)
                  (* in *)

                  let detailed_metrics =
                    Detailed_metrics.of_five_tuple_flow_metrics
                      ~check_five_tuple_flow_metrics_timestamp: check_five_tuple_flow_metrics_timestamp
                      five_tuple_flow
                      five_tuple_flow_metrics
                  in

                  (* print_endline *)
                  (*    (sprintf *)
                  (*       "Anomaly_detailed_metrics_container: of_anomaly_container_five_tuple_flow_metrics_container: acc before:\n%s\n\nnew detailed_metrics for %s:\n%s" *)
                  (*       (Detailed_metrics.to_string *)
                  (*          (\* To_string_mode.Simple *\) *)
                  (*          To_string_mode.Normal *)
                  (*          acc *)
                  (*       ) *)
                  (*       (Five_tuple_flow.to_string five_tuple_flow) *)
                  (*       (Detailed_metrics.to_string *)
                  (*          To_string_mode.Normal *)
                  (*          detailed_metrics *)
                  (*       ) *)
                  (*    ); *)

                  Detailed_metrics.append
                    acc
                    detailed_metrics;

                  acc
               )
               (List.tl l)
               first_detailed_metrics
           in

           five_tuple_flow_set_length, (five_tuple_flow_hashset, detailed_metrics)
        )
        anomaly_five_tuple_flow_metrics_container
    in

    let _five_tuple_flow_count_hashtable =
      HT.map
        (fun _ tuple -> fst tuple)
        h
    in
    let five_tuple_flow_set_detailed_metrics_tuple_hashtable =
      HT.map
        (fun _ tuple -> snd tuple)
        h
    in

    let t =
      of_hashtables
        (fun anomaly_indice five_tuple_flow ->
           let five_tuple_flow_metrics_container =
             Anomaly_five_tuple_flow_metrics_container.find
               anomaly_five_tuple_flow_metrics_container
               anomaly_indice
           in
           let five_tuple_flow_metrics =
             Five_tuple_flow_metrics_container.find
               five_tuple_flow_metrics_container
               five_tuple_flow
           in
           five_tuple_flow_metrics
        )
        (* five_tuple_flow_count_hashtable *)
        (* () *)
        (* anomaly_container *)
        
        anomaly_slice_time_data_container
        
        five_tuple_flow_set_detailed_metrics_tuple_hashtable
    in

    debug "of_anomaly_five_tuple_flow_metrics_container: end";

    t

    (* failwith("BUG"); *)
  )
  
