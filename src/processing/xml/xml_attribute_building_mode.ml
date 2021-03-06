
open Printf

type t =
| Trace_xml of (string * string)
| Trace_mawilab_xml of (string * string * string)
| Xml of string

let to_string t =
  match t with
  | Trace_xml (trace_name, xml_file_name) ->
     sprintf 
       "Trace_xml: %s - %s"
       trace_name
       xml_file_name
  | Trace_mawilab_xml (trace_name, anomalous_suspicious_xml_file_name, notice_xml_file_name) ->
     sprintf
       "Trace_mawilab_xml: %s - %s - %s"
       trace_name
       anomalous_suspicious_xml_file_name
       notice_xml_file_name
  | Xml xml_file_name -> 
     sprintf
       "Xml: %s" 
       xml_file_name

