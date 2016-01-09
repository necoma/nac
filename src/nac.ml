
open Printf

let _ =
  print_endline "nac: call";

  let one_MB = 1024 * 1024 in
  Gc.set {
    (Gc.get())
    with
      Gc.minor_heap_size = (4 * one_MB);
      (* Gc.space_overhead = 150; *)
      Gc.major_heap_increment = (32 * one_MB);
  };

  Printexc.record_backtrace true;

  let nac_parameters =
    Nac_parameters.new_empty_t ()
  in

  let ppm_flag =
    Core.Std.Command.Spec.flag
      "-ppm"
      (Core.Std.Command.Spec.optional Core.Std.Command.Spec.string)
      ~doc: "string parse packet with the following IP versin [4|6|46]"
  in  
  let process_ppm_flag use_string =
    match use_string with
    | Some string ->
      nac_parameters.Nac_parameters.packet_parsing_mode <-
        Packet_parsing_mode.of_string string
    | None ->
      nac_parameters.Nac_parameters.packet_parsing_mode <-
        Packet_parsing_mode.IPV4
  in

  let das_flag =
    Core.Std.Command.Spec.flag
      "-das"
      Core.Std.Command.Spec.no_arg
      ~doc: " export values and attributes of anomalies"
  in
  let process_das_flag das =
    match das with
    | true ->
      nac_parameters.Nac_parameters.export_values_attributes <- true
    | false ->
      nac_parameters.Nac_parameters.export_values_attributes <- false
  in

  let p_flag =
    Core.Std.Command.Spec.flag
      "-p"
      (Core.Std.Command.Spec.optional Core.Std.Command.Spec.int)
      ~doc: "int Parallel processing with [int] processes"
  in  
  let process_p_flag use_int =
    match use_int with
    | Some int ->
      nac_parameters.Nac_parameters.parallelization_mode <-
        Parallelization_mode.Parmap (int, 10)
    | None ->
      nac_parameters.Nac_parameters.parallelization_mode <-
        Parallelization_mode.No_parallelization
  in

  let ct =
    Core.Std.Command.basic
      ~summary: "Classify anomaly directly from trace"
      Core.Std.Command.Spec.(
        empty
        +> ppm_flag
        +> das_flag
        +> p_flag
        +> anon ("taxonomy_path" %: string)
        +> anon ("trace_path" %: string)
      )
      (fun use_string das use_int taxonomy_path trace_path () ->
         process_ppm_flag use_string;
         process_das_flag das;
         process_p_flag use_int;

         nac_parameters.Nac_parameters.taxonomy_filepath <- taxonomy_path;

         nac_parameters.Nac_parameters.classification_mode <-
           Classification_mode.Trace trace_path;
      )
  in

  let ctx =
    Core.Std.Command.basic
      ~summary: "Classify anomaly annotated in [xml_path] located in [trace_path] using [taxonomy_path] from trace"
      Core.Std.Command.Spec.(
        empty
        +> ppm_flag
        +> das_flag
        +> p_flag
        +> anon ("taxonomy_path" %: string)
        +> anon ("trace_path" %: string)
        +> anon ("xml_path" %: string)
      )
      (fun use_string das use_int taxonomy_path trace_path xml_path () ->
         process_ppm_flag use_string;
         process_das_flag das;
         process_p_flag use_int;

         nac_parameters.Nac_parameters.taxonomy_filepath <- taxonomy_path;

         nac_parameters.Nac_parameters.classification_mode <-
           Classification_mode.Xml
             (Xml_attribute_building_mode.Trace_xml (trace_path, xml_path));
      )
  in

  let ctmx =
    Core.Std.Command.basic
      ~summary: "Classify anomaly annotated in [mawilab_xml_anomalous_suspicious_path,mawilab_xml_notice_path] located in [trace_path] using [taxonomy_path] from trace"
      Core.Std.Command.Spec.(
        empty
        +> ppm_flag
        +> das_flag
        +> p_flag
        +> anon ("taxonomy_path" %: string)
        +> anon ("trace_path" %: string)
        +> anon ("mawilab_xml_anomalous_suspicious_path" %: string)
        +> anon ("mawilab_xml_notice_path" %: string)
      )
      (fun use_string das use_int taxonomy_path trace_path mawilab_xml_anomalous_suspicious_path mawilab_xml_notice_path () ->
         process_ppm_flag use_string;
         process_das_flag das;
         process_p_flag use_int;

         nac_parameters.Nac_parameters.taxonomy_filepath <- taxonomy_path;

         nac_parameters.Nac_parameters.classification_mode <-  
           Classification_mode.Xml
             (Xml_attribute_building_mode.Trace_mawilab_xml
                (trace_path,
                 mawilab_xml_anomalous_suspicious_path,
                 mawilab_xml_notice_path
                )
             );
      )
  in

  let command =
    Core.Std.Command.group
      ~summary: "Network anomaly classification"
      [ "ct", ct; "ctx", ctx; "ctmx", ctmx]
  in

  Core.Std.Command.run command;

  if
    Nac_parameters.check
      nac_parameters
    =
    false
  then
    (
      print_endline "nac: Invalid parameters (cf above)";
      exit 1;
    );

  print_endline
    (sprintf
       "nac: parameters:\n%s"
       (Nac_parameters.to_string
          nac_parameters
       )
    );

  ignore(
    match nac_parameters.Nac_parameters.classification_mode with
    | Classification_mode.Not_defined ->
      failwith "Classification mode not defined"
    | Classification_mode.Xml xml_attribute_building_mode ->
      (
        Xml_classifier.process
          nac_parameters.Nac_parameters.parallelization_mode

          nac_parameters.Nac_parameters.taxonomy_filepath

          nac_parameters.Nac_parameters.packet_parsing_mode

          nac_parameters.Nac_parameters.export_values_attributes

          xml_attribute_building_mode
        ;
      )
    | Classification_mode.Trace trace_file_path ->
      Trace_classifier.process
        nac_parameters.Nac_parameters.parallelization_mode

        nac_parameters.Nac_parameters.taxonomy_filepath

        nac_parameters.Nac_parameters.packet_parsing_mode

        nac_parameters.Nac_parameters.export_values_attributes

        trace_file_path
  );

  print_endline "nac: end";

  exit 0





