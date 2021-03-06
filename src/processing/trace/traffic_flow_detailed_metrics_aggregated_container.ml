
open Printf

open Traffic_flow_aggr_data_instantiations.Traffic_flow_detailed_metrics_aggr_data

let debug_enabled = ref false

let set_debug bool = debug_enabled := bool

let debug fmt =
  Printf.kprintf
    (
      if !debug_enabled then
        (fun s -> Format.printf "[Traffic_flow_detailed_metrics_aggregated_container]: %s@." s)
      else
        ignore
    )
    fmt

type t =
  {
    hashtable : (Traffic_flow_key_type.aggr_mode_t, Aggr_key_data_container.t) Hashtbl.t;
  }

let new_t
    hashtable
  =
  {
    hashtable = hashtable;
  }

let to_string t : string =
  Hashtbl_ext.to_string
    ~sep_element: "\n"
    ~sep_key_value: ":\n"
    ~to_string_key: Traffic_flow_key_type.to_string_aggr_mode
    (fun aggr_key_data_container ->
       Aggr_key_data_container.to_string_ordered
         aggr_key_data_container
    )
    t.hashtable
    
let length t = Hashtbl.length t.hashtable

let map_to_hashtbl
    f
    t
  =
  Batteries.Hashtbl.map
    f
    t.hashtable

let of_addr_mode_list_five_tuple_flow_detailed_metrics_container
    addr_mode_list
    five_tuple_flow_detailed_metrics_container
  =
  let addr_mode_five_tuple_flow_detailed_metrics_container_tuple_list =
    List.map
      (fun addr_mode ->
         addr_mode
         ,
         Aggr_key_data_container.of_simple_key_data_container
           addr_mode
           five_tuple_flow_detailed_metrics_container
      )
      addr_mode_list
  in

  let enum = Batteries.List.enum addr_mode_five_tuple_flow_detailed_metrics_container_tuple_list in

  let hashtable = Batteries.Hashtbl.of_enum enum in

  new_t
    hashtable
