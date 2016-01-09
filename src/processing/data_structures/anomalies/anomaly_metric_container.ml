
open Printf

open Map_ext_instantiations

open Ipv4
open Tcp
open Udp
open Icmp

open Admd_functor_instantiation
open Mawilab_admd_functor_instantiation

let debug_enabled = ref false

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
    anomaly_metric_int_map : Anomaly_metric.t Int_map.t;
  }

let new_t
    anomaly_metric_int_map
    =
  {
    anomaly_metric_int_map;
  }

(* let to_string to_string_mode t = *)
(*   match to_string_mode with *)
(*   | To_string_mode.Command -> *)
(*     Map_ext_instantiations.Int_map.to_string *)
(*       ~sep: "\n\n" *)
(*       (fun indice detailed_metrics -> sprintf "%d: %s" indice (Network_attributes.to_string to_string_mode detailed_metrics)) *)
(*       t.network_attributes_int_map *)
(*   | To_string_mode.Simple -> *)
(*     Map_ext_instantiations.Int_map.to_string *)
(*       ~sep: "\n\n" *)
(*       (\* ~sep_key_value: ": " *\) *)
(*       (\* ~display_key: true *\) *)
(*       (\* (fun detailed_metrics -> Network_attributes.to_string to_string_mode detailed_metrics) *\) *)
(*       (fun indice detailed_metrics -> sprintf "%d: %s" indice (Network_attributes.to_string to_string_mode detailed_metrics)) *)
(*       t.network_attributes_int_map *)
(*   | To_string_mode.Normal -> *)
(*     Map_ext_instantiations.Int_map.to_string *)
(*       ~sep: "\n\n" *)
(*       (\* ~sep_key_value: ": " *\) *)
(*       (\* ~display_key: true *\) *)
(*       (\* (fun detailed_metrics -> Network_attributes.to_string to_string_mode detailed_metrics) *\) *)
(*       (fun indice detailed_metrics -> sprintf "%d: %s" indice (Network_attributes.to_string to_string_mode detailed_metrics)) *)
(*       t.network_attributes_int_map *)

let of_anomaly_detailed_metrics_container
    anomaly_detailed_metrics_container
    =
  let detailed_metrics_int_map =
    Hashtbl.fold
      (fun int detailed_metrics int_map ->
        Int_map.add
          int 
          detailed_metrics
          int_map
      )
      anomaly_detailed_metrics_container.Anomaly_detailed_metrics_container.detailed_metrics_int_map
      Int_map.empty
  in

  let int_map =
    Int_map.map
      Network_attributes.of_detailed_metrics
      detailed_metrics_int_map
  in
  
  new_t
    int_map

let to_int_map t = t.network_attributes_int_map
