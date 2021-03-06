
let transport_protocol_for_metrics_to_admd_transport_protocol
    transport_protocol_for_metrics
  =
  match transport_protocol_for_metrics with
  | Transport_protocol_for_metrics.ICMP -> Admd.Transport_protocol.ICMP
  | Transport_protocol_for_metrics.TCP -> Admd.Transport_protocol.TCP
  | Transport_protocol_for_metrics.UDP -> Admd.Transport_protocol.UDP
  | Transport_protocol_for_metrics.IPv6 -> Admd.Transport_protocol.IPv6
  | Transport_protocol_for_metrics.GRE -> Admd.Transport_protocol.GRE
  | Transport_protocol_for_metrics.ICMPv6 -> Admd.Transport_protocol.ICMPv6
  | Transport_protocol_for_metrics.Other code -> Admd.Transport_protocol.None
  
