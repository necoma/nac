
open Printf

open Map_ext_instantiations

open Ipv4
open Tcp
open Udp
open Icmp

open Admd_functor_instantiation
open Mawilab_admd_functor_instantiation

open Key_occurrence_distribution_instantiations

open Five_tuple_flow_data_structures

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
    detailed_metrics_hashtable : (int, Detailed_metrics.t) Batteries.Hashtbl.t;
    anomaly_metric_hashtable : (int, Anomaly_metric.t) Batteries.Hashtbl.t;
  }

let new_t
    detailed_metrics_hashtable
    anomaly_metric_hashtable
    =
  {
    detailed_metrics_hashtable;
    anomaly_metric_hashtable;
  }

let to_string to_string_mode t =
  match to_string_mode with
  | To_string_mode.Command ->
    Utils_batteries.to_string_hashtbl
      ~sep_element: "\n\n"
      ~sep_key_value: ": "
      ~to_string_key: (fun key -> sprintf "%d" key)
      (fun detailed_metrics -> Detailed_metrics.to_string to_string_mode detailed_metrics)
      t.detailed_metrics_hashtable
  | To_string_mode.Simple ->
    Utils_batteries.to_string_hashtbl
      ~sep_element: "\n\n"
      ~sep_key_value: ": "
      ~to_string_key: (fun key -> sprintf "%d" key)
      (fun detailed_metrics -> Detailed_metrics.to_string to_string_mode detailed_metrics)
      t.detailed_metrics_hashtable
  | To_string_mode.Normal ->
    Utils_batteries.to_string_hashtbl
      ~sep_element: "\n\n"
      ~sep_key_value: ": "
      ~to_string_key: (fun key -> sprintf "%d" key)
      (fun detailed_metrics -> Detailed_metrics.to_string to_string_mode detailed_metrics)
      t.detailed_metrics_hashtable

let length t = Hashtbl.length t.detailed_metrics_hashtable

let find_detailed_metrics indice t = Hashtbl.find t.detailed_metrics_hashtable indice 
let find_anomaly_metric indice t = Hashtbl.find t.anomaly_metric_hashtable indice 

let fold_detailed_metrics f t acc = Hashtbl.fold f t.detailed_metrics_hashtable acc
let fold_anomaly_metric f t acc = Hashtbl.fold f t.anomaly_metric_hashtable acc

let of_anomaly_container_five_tuple_flow_metrics_container_parallelized_list_fusion_map
    parallelization_mode
    five_tuple_flow_metrics_container
    anomaly_container
  =
  (
    debug "of_anomaly_container_five_tuple_flow_metrics_container_parallelized_list_fusion_map: call";

    let five_tuple_flow_metrics_tuple_list =
      Five_tuple_flow_metrics_container.to_list
        five_tuple_flow_metrics_container
    in

    let nb_five_tuple_flow = Five_tuple_flow_metrics_container.length five_tuple_flow_metrics_container in
    let nb_anomaly = Mawilab_admd.Anomaly_container.length anomaly_container in

    (* let fusion_map hashtable_1 hashtable_2 = *)
    (*   debug "of_anomaly_container_five_tuple_flow_metrics_container_parallelized_list_fusion_map: fusion_map: call"; *)

    (*   let detailed_metrics_int_map_1 = *)
    (*     Hashtbl.fold *)
    (*       (fun int (five_tuple_flow_list, detailed_metrics) int_map -> *)
    (*         Int_map.add *)
    (*           int *)
    (*           (five_tuple_flow_list, detailed_metrics) *)
    (*           int_map *)
    (*       ) *)
    (*       hashtable_1 *)
    (*       Int_map.empty *)
    (*   in *)

    (*   let detailed_metrics_int_map_2 = *)
    (*     Hashtbl.fold *)
    (*       (fun int (five_tuple_flow_list, detailed_metrics) int_map -> *)
    (*         Int_map.add *)
    (*           int *)
    (*           (five_tuple_flow_list, detailed_metrics) *)
    (*           int_map *)
    (*       ) *)
    (*       hashtable_2 *)
    (*       Int_map.empty *)
    (*   in *)

    (*   let int_map = *)
    (*     Int_map.merge *)
    (*       (fun int option_1 option_2 -> *)
    (*         match option_1 with *)
    (*         | None -> *)
    (*           ( *)
    (*             match option_2 with *)
    (*             | None -> failwith "Anomaly_detailed_metrics_container: apply_anomaly_container_five_tuple_flow_detailed_metrics_container: nothing a five_tuple_flow" *)
    (*             | Some (five_tuple_flow_list_2, detailed_metrics_2) -> Some (five_tuple_flow_list_2, detailed_metrics_2) *)
    (*           ) *)
    (*         | Some (five_tuple_flow_list_1, detailed_metrics_1) -> *)
    (*           ( *)
    (*             match option_2 with *)
    (*             | None -> Some (five_tuple_flow_list_1, detailed_metrics_1) *)
    (*             | Some (five_tuple_flow_list_2, detailed_metrics_2) -> *)
    (*       Some *)
    (*         ( *)
    (*           (Batteries.List.unique_cmp ~cmp: Five_tuple_flow.compare  *)
    (*        (List.append five_tuple_flow_list_1 five_tuple_flow_list_2) *)
    (*           ) *)
    (*       , *)
    (*           (Detailed_metrics.fusion detailed_metrics_1 detailed_metrics_2) *)
    (*         )  *)
    (*           ) *)
    (*       ) *)
    (*       detailed_metrics_int_map_1 *)
    (*       detailed_metrics_int_map_2 *)
    (*   in *)

    (*   let new_hashtable = Hashtbl.create (Int_map.cardinal int_map) in *)

    (*   Int_map.iter *)
    (*     (fun indice detailed_metrics -> *)
    (*       Hashtbl.add *)
    (*         new_hashtable *)
    (*         indice *)
    (*         detailed_metrics *)
    (*     ) *)
    (*     int_map; *)

    (*   debug "of_anomaly_container_five_tuple_flow_metrics_container_parallelized_list_fusion_map: fusion_map: end"; *)

    (*   new_hashtable *)
    (* in *)

    let fusion_five_tuple_list_detailed_metrics_hashtable hashtable_1 hashtable_2 =
      Fusion_hashtable.fusion_int_hashtable
        (* (fun (five_tuple_flow_list_1, detailed_metrics_1) (five_tuple_flow_list_2, detailed_metrics_2) -> *)
        (fun (five_tuple_flow_set_1, detailed_metrics_1) (five_tuple_flow_set_2, detailed_metrics_2) ->
           (
             (* (Batteries.List.unique_cmp ~cmp: Five_tuple_flow.compare  *)
             (*    (Batteries.List.append five_tuple_flow_list_1 five_tuple_flow_list_2) *)
             (* ) *)
             (
               (* let set1 = Five_tuple_flow_set.of_list five_tuple_flow_list_1 in *)
               (* let set2 = Five_tuple_flow_set.of_list five_tuple_flow_list_2 in *)
               (* let union = Five_tuple_flow_set.union set1 set2 in *)
               let union = Five_tuple_flow_set.union five_tuple_flow_set_1 five_tuple_flow_set_2 in
               (* Five_tuple_flow_set.to_list union *)
               union
             )
             ,
             (Detailed_metrics.fusion detailed_metrics_1 detailed_metrics_2))
        )
        hashtable_1 
        hashtable_2
    in

    let fusion_anomaly_count_hashtable hashtable_1 hashtable_2 =
      Fusion_hashtable.fusion
        (fun count_1 count_2 ->  count_1 + count_2)
        hashtable_1 
        hashtable_2
    in

    let fusion_map (count_hashtable_1, tuple_hashtable_1) (count_hashtable_2, tuple_hashtable_2) =
      let count_hashtable = fusion_anomaly_count_hashtable count_hashtable_1 count_hashtable_2 in
      let tuple_hashtable = fusion_five_tuple_list_detailed_metrics_hashtable tuple_hashtable_1 tuple_hashtable_2 in
      (count_hashtable, tuple_hashtable)
    in

    let parallelization_mode_to_use =
      if Five_tuple_flow_metrics_container.length five_tuple_flow_metrics_container < 5000000 then
        parallelization_mode
      else 
        Parallelization_mode.No_parallelization 2000
    in

    let five_tuple_flow_count_hashtable, five_tuple_flow_set_detailed_metrics_tuple_hashtable =
      Map_data.fold_list
        parallelization_mode_to_use
        (fun (count_hashtable_1, tuple_hashtable_1) (five_tuple_flow, five_tuple_flow_metrics) ->
           (
             let src_addr,
                 dst_addr,
                 proto,
                 src_port,
                 dst_port
               =
               Five_tuple_flow.to_five_tuple
                 five_tuple_flow
             in

             let (new_count_hashtable_1, new_tuple_hashtable_1)  =
               Mawilab_admd.Anomaly_container.fold_left
                 (fun (count_hashtable_2, tuple_hashtable_2) anomaly ->
                    (
                      (* debug "of_anomaly_container_five_tuple_flow_metrics_container_parallelized_list_fusion_map: comparing"; *)

                      let compare_result =
                        Mawilab_admd.Anomaly.match_flow
                          five_tuple_flow_metrics.Five_tuple_flow_metrics.timestamp_sec_start
                          five_tuple_flow_metrics.Five_tuple_flow_metrics.timestamp_usec_start
                          five_tuple_flow_metrics.Five_tuple_flow_metrics.timestamp_sec_end
                          five_tuple_flow_metrics.Five_tuple_flow_metrics.timestamp_usec_end
                          false
                          (* five_tuple_flow_metrics.Five_tuple_flow_metrics.nb_packets *)
                          src_addr
                          dst_addr
                          (Transport_protocol_translation.transport_protocol_for_metrics_to_admd_transport_protocol proto)
                          src_port
                          dst_port
                          anomaly
                      in

                      (* debug *)
                      (*   "of_anomaly_container_five_tuple_flow_metrics_container_parallelized_list_fusion_map:\n%s\n%s" *)
                      (*   (Five_tuple_flow.to_string five_tuple_flow) *)
                      (*   (Mawilab_admd.Anomaly.to_string To_string_mode.Simple anomaly); *)

                      (* debug *)
                      (*   "of_anomaly_container_five_tuple_flow_metrics_container_parallelized_list_fusion_map: %b\n\n" *)
                      (*   compare_result; *)

                      let count_hashtable, tuple_hashtable =
                        if compare_result then
                          (
                            let indice = anomaly.Mawilab_admd.Anomaly.indice in

                            (* debug *)
                            (*   "of_anomaly_container_five_tuple_flow_metrics_container_parallelized_list_fusion_map: %d" *)
                            (*   indice; *)

                            let new_count_hashtable =
                              try
                                (
                                  let anomaly_count =
                                    Batteries.Hashtbl.find
                                      count_hashtable_2
                                      five_tuple_flow
                                  in

                                  Batteries.Hashtbl.replace
                                    count_hashtable_2
                                    five_tuple_flow
                                    (anomaly_count + 1);

                                  count_hashtable_2
                                )
                              with
                              | Not_found ->
                                (
                                  Batteries.Hashtbl.add
                                    count_hashtable_2
                                    five_tuple_flow
                                    1;

                                  count_hashtable_2
                                )
                            in

                            let new_tuple_hashtable =
                              try
                                (
                                  let five_tuple_flow_set, found_detailed_metrics =
                                    Batteries.Hashtbl.find
                                      tuple_hashtable_2
                                      indice
                                  in

                                  let detailed_metrics =
                                    Detailed_metrics.of_five_tuple_flow_metrics
                                      five_tuple_flow
                                      five_tuple_flow_metrics
                                  in
                                  Detailed_metrics.append
                                    found_detailed_metrics
                                    detailed_metrics;

                                  Hashtbl.replace
                                    tuple_hashtable_2
                                    indice
                                    (* ((five_tuple_flow :: five_tuple_flow_list), found_detailed_metrics) *)
                                    ((Five_tuple_flow_set.add five_tuple_flow five_tuple_flow_set), found_detailed_metrics)
                                  ;


                                  tuple_hashtable_2
                                )
                              with
                              | Not_found ->
                                (
                                  let new_detailed_metrics =
                                    Detailed_metrics.of_five_tuple_flow_metrics
                                      five_tuple_flow
                                      five_tuple_flow_metrics
                                  in

                                  Batteries.Hashtbl.add
                                    tuple_hashtable_2
                                    indice
                                    (Five_tuple_flow_set.singleton five_tuple_flow, new_detailed_metrics);

                                  tuple_hashtable_2
                                )
                            in


                            (new_count_hashtable, new_tuple_hashtable)
                          )
                        else
                          (
                            (count_hashtable_2, tuple_hashtable_2)
                          )
                      in

                      (count_hashtable, tuple_hashtable)
                    )
                 )
                 (count_hashtable_1, tuple_hashtable_1)
                 anomaly_container
             in

             (new_count_hashtable_1, new_tuple_hashtable_1)
           )
        )
        fusion_map
        ((Batteries.Hashtbl.create nb_five_tuple_flow), (Batteries.Hashtbl.create nb_anomaly))
        five_tuple_flow_metrics_tuple_list
    in

    (* Completing metrics for anomalies with empty traffic *)
    Mawilab_admd.Anomaly_container.iter
      (fun anomaly ->
         try 
           (
             let _detailed_metrics_found =
               Hashtbl.find
                 five_tuple_flow_set_detailed_metrics_tuple_hashtable 
                 anomaly.Mawilab_admd.Anomaly.indice
             in

             ()
           )
         with
         | Not_found ->
           (
             Hashtbl.add
               five_tuple_flow_set_detailed_metrics_tuple_hashtable
               anomaly.Mawilab_admd.Anomaly.indice 
               (Five_tuple_flow_set.empty, Detailed_metrics.new_empty_t ())
           )
      )
      anomaly_container;

    (* t.detailed_metrics_int_map <- new_detailed_metrics_int_map; *)

    let detailed_metrics_hashtable =
      Batteries.Hashtbl.map
        (fun _ (_, detailed_metrics) -> detailed_metrics)
        five_tuple_flow_set_detailed_metrics_tuple_hashtable
    in

    let anomaly_metric_hashtable =
      Batteries.Hashtbl.map
        (fun indice (five_tuple_flow_set, _) ->
           let flow_number = Five_tuple_flow_set.cardinal five_tuple_flow_set in

           let packet_number, byte_number =
             Five_tuple_flow_set.fold
               (fun five_tuple_flow (packet_number_acc, byte_number_acc) ->
                  let five_tuple_flow_metrics =
                    Five_tuple_flow_metrics_container.find
                      five_tuple_flow_metrics_container
                      five_tuple_flow
                  in

                  let anomaly_number_for_five_tuple_flow =
                    Hashtbl.find
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

    debug "of_anomaly_container_five_tuple_flow_metrics_container_parallelized_list_fusion_map: end";

    new_t
      detailed_metrics_hashtable
      anomaly_metric_hashtable
  )

let of_anomaly_container_five_tuple_flow_metrics_container
    parallelization_mode
    five_tuple_flow_metrics_container
    anomaly_container
  =
  (
    debug "of_anomaly_container_five_tuple_flow_metrics_container: call";

    (* let five_tuple_flow_metrics_tuple_list = *)
    (*   Five_tuple_flow_metrics_container.to_list *)
    (*     five_tuple_flow_metrics_container *)
    (* in *)

    let nb_five_tuple_flow = Five_tuple_flow_metrics_container.length five_tuple_flow_metrics_container in
    let nb_anomaly = Mawilab_admd.Anomaly_container.length anomaly_container in

    debug "of_anomaly_container_five_tuple_flow_metrics_container: building five_tuple_key_five_tuple_flow_container";

    let five_tuple_key_five_tuple_flow_list_container =
      Five_tuple_key_five_tuple_flow_list_container.of_five_tuple_flow_metrics_container
        five_tuple_flow_metrics_container
    in
    let five_tuple_key_five_tuple_flow_set_container =
      Five_tuple_key_five_tuple_flow_set_container.of_five_tuple_key_five_tuple_flow_list_container
        five_tuple_key_five_tuple_flow_list_container
    in

    let anomaly_list = Mawilab_admd.Anomaly_container.to_list anomaly_container in

    let get_five_tuple_flow_set_of_filter_criteria filter_criteria =
      (* debug *)
      (*   "of_anomaly_container_five_tuple_flow_metrics_container: filter_criteria:\n%s" *)
      (*   (Filter_criteria.to_string filter_criteria); *)

      match filter_criteria with
      | Filter_criteria.Src_ip src_addr ->
        Five_tuple_key_five_tuple_flow_set_container.find_src_addr
          five_tuple_key_five_tuple_flow_set_container
          src_addr
      | Filter_criteria.Dst_ip dst_addr ->
        Five_tuple_key_five_tuple_flow_set_container.find_dst_addr
          five_tuple_key_five_tuple_flow_set_container
          dst_addr
      | Filter_criteria.Admd_transport_protocol admd_transport_protocol ->
        Five_tuple_key_five_tuple_flow_set_container.find_admd_transport_protocol
          five_tuple_key_five_tuple_flow_set_container
          admd_transport_protocol
      | Filter_criteria.Src_port src_port ->
        Five_tuple_key_five_tuple_flow_set_container.find_src_port
          five_tuple_key_five_tuple_flow_set_container
          src_port
      | Filter_criteria.Dst_port dst_port ->
        Five_tuple_key_five_tuple_flow_set_container.find_dst_port
          five_tuple_key_five_tuple_flow_set_container
          dst_port
    in

    debug "of_anomaly_container_five_tuple_flow_metrics_container: assigning five tuple flows to anomalies";

    let five_tuple_flow_count_hashtable, five_tuple_flow_set_detailed_metrics_tuple_hashtable =
      List.fold_left
        (fun (count_hashtable, tuple_hashtable) anomaly ->
           (
             (* debug "of_anomaly_container_five_tuple_flow_metrics_container: anomaly start"; *)

             let anomaly_indice = anomaly.Mawilab_admd.Anomaly.indice in

             (* debug "of_anomaly_container_five_tuple_flow_metrics_container: indice %d" anomaly_indice; *)

             let filter_criteria_list_list =
               Batteries.List.fold_left
                 (fun acc slice ->
                    Batteries.List.append
                      acc
                      (
                        Batteries.List.map
                          (fun filter ->
                             filter.Filter.filter_criteria_list 
                          )
                          slice.Slice.filter_list
                      )
                 )
                 []
                 anomaly.Mawilab_admd.Anomaly.slice_list
             in

             if List.length filter_criteria_list_list = 0 then
               (count_hashtable, tuple_hashtable)
             else    
               (* five_tuple_flow_set list for all slices and filters *)
               let five_tuple_flow_set_list =
                 Batteries.List.map
                   (fun filter_criteria_list ->
                      let five_tuple_flow_list_list =
                        Batteries.List.map
                          get_five_tuple_flow_set_of_filter_criteria
                          filter_criteria_list
                      in

                      assert(List.length five_tuple_flow_list_list > 0);

                      Batteries.List.fold_left
                        (fun acc five_tuple_flow_set ->
                           Five_tuple_flow_set.inter acc five_tuple_flow_set
                        )
                        (Batteries.List.hd five_tuple_flow_list_list)
                        (Batteries.List.tl five_tuple_flow_list_list)
                   )
                   filter_criteria_list_list
               in

               assert(List.length five_tuple_flow_set_list > 0);

               let five_tuple_flow_set =
                 Batteries.List.fold_left
                   (fun acc five_tuple_flow_set ->
                      Five_tuple_flow_set.union acc five_tuple_flow_set
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

               Five_tuple_flow_set.iter
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

               let detailed_metrics =
                 Five_tuple_flow_set.fold
                   (fun five_tuple_flow acc ->
                      let five_tuple_flow_metrics =
                        Five_tuple_flow_metrics_container.find
                          five_tuple_flow_metrics_container
                          five_tuple_flow
                      in

                      let detailed_metrics =
                        Detailed_metrics.of_five_tuple_flow_metrics
                          five_tuple_flow
                          five_tuple_flow_metrics
                      in

                      Detailed_metrics.append
                        acc
                        detailed_metrics;

                      acc
                   )
                   five_tuple_flow_set
                   (Detailed_metrics.new_empty_t ())      
               in

               Hashtbl.add
                 tuple_hashtable
                 anomaly_indice
                 (five_tuple_flow_set, detailed_metrics);

               (* debug "of_anomaly_container_five_tuple_flow_metrics_container: anomaly end"; *)

               (count_hashtable, tuple_hashtable)
           )
        )
        ((Batteries.Hashtbl.create nb_five_tuple_flow), (Batteries.Hashtbl.create nb_anomaly))
        anomaly_list
    in

    (* Completing metrics for anomalies with empty traffic *)
    Mawilab_admd.Anomaly_container.iter
      (fun anomaly ->
         try 
           (
             let _detailed_metrics_found =
               Hashtbl.find
                 five_tuple_flow_set_detailed_metrics_tuple_hashtable 
                 anomaly.Mawilab_admd.Anomaly.indice
             in

             ()
           )
         with
         | Not_found ->
           (
             Hashtbl.add
               five_tuple_flow_set_detailed_metrics_tuple_hashtable
               anomaly.Mawilab_admd.Anomaly.indice 
               (Five_tuple_flow_set.empty, Detailed_metrics.new_empty_t ())
           )
      )
      anomaly_container;

    (* t.detailed_metrics_int_map <- new_detailed_metrics_int_map; *)

    let detailed_metrics_hashtable =
      Batteries.Hashtbl.map
        (fun _ (_, detailed_metrics) -> detailed_metrics)
        five_tuple_flow_set_detailed_metrics_tuple_hashtable
    in

    let anomaly_metric_hashtable =
      Batteries.Hashtbl.map
        (fun indice (five_tuple_flow_set, _) ->
           let flow_number = Five_tuple_flow_set.cardinal five_tuple_flow_set in

           let packet_number, byte_number =
             Five_tuple_flow_set.fold
               (fun five_tuple_flow (packet_number_acc, byte_number_acc) ->
                  let five_tuple_flow_metrics =
                    Five_tuple_flow_metrics_container.find
                      five_tuple_flow_metrics_container
                      five_tuple_flow
                  in

                  let anomaly_number_for_five_tuple_flow =
                    Hashtbl.find
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

    debug "of_anomaly_container_five_tuple_flow_metrics_container: end";

    new_t
      detailed_metrics_hashtable
      anomaly_metric_hashtable
  )
