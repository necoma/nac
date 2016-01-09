
open Printf

type t =
  {
    mutable classification_mode : Classification_mode.t;

    mutable taxonomy_filepath : string;

    mutable packet_parsing_mode : Packet_parsing_mode.t;

    (* mutable date_format_string : string; *)
    (* mutable time_format_string : string; *)
    (* mutable default_hour_minute_second : (int * int * int) option; *)

    mutable export_values_attributes : bool;

    mutable parallelization_mode : Parallelization_mode.t;
  }

let new_t
    classification_mode
    taxonomy_filepath
    packet_parsing_mode
    export_values_attributes
    parallelization_mode
  =
  {
    classification_mode;

    taxonomy_filepath;

    packet_parsing_mode;
    
    export_values_attributes;

    parallelization_mode;
  }
  
let new_empty_t () =
  new_t
    Classification_mode.Not_defined

    ""

    Packet_parsing_mode.IPV4

    false

    Parallelization_mode.No_parallelization

let to_string t =
  (* sprintf *)
  (*   "Anomaly classification parameters:\nClassification mode: %s\ntaxonomy_filepath: %s\npacket parsing mode: %s\ntime format string: %s\nExport_metrics_attributes: %b" *)
  (*   (Classification_mode.to_string t.classification_mode) *)
  (*   t.taxonomy_filepath *)
  (*   (Packet_parsing_mode.to_string t.packet_parsing_mode) *)
  (*   t.time_format_string *)
  (*   t.export_metrics_attributes *)
  sprintf
    "nac parameters:\nClassification mode: %s\ntaxonomy_filepath: %s\npacket parsing mode: %s\nExport_metrics_attributes: %b"
    (Classification_mode.to_string t.classification_mode)
    t.taxonomy_filepath
    (Packet_parsing_mode.to_string t.packet_parsing_mode)
    t.export_values_attributes

let check t =
  t.classification_mode <> Classification_mode.Not_defined
  &&
  t.taxonomy_filepath <> ""
