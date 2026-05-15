import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'server_node.g.dart';

@HiveType(typeId: 1)
enum ServerProtocol {
  @HiveField(0)
  vmess,
  @HiveField(1)
  vless,
  @HiveField(2)
  trojan,
  @HiveField(3)
  shadowsocks,
  @HiveField(4)
  socks,
  @HiveField(5)
  http,
}

@HiveType(typeId: 0)
class ServerNode extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String host;

  @HiveField(3)
  int port;

  @HiveField(4)
  ServerProtocol protocol;

  @HiveField(5)
  String uuid; // vmess/vless uuid 或 ss password

  @HiveField(6)
  String alterId; // vmess alterId

  @HiveField(7)
  String security; // 加密方式

  @HiveField(8)
  String network; // tcp/ws/grpc/h2

  @HiveField(9)
  String path; // ws path / grpc serviceName

  @HiveField(10)
  String host2; // ws host header

  @HiveField(11)
  bool tls; // 是否启用TLS

  @HiveField(12)
  String sni; // TLS SNI

  @HiveField(13)
  String? fingerprint; // TLS fingerprint

  @HiveField(14)
  int? latency; // 延迟(ms), null=未测速

  @HiveField(15)
  bool selected; // 是否选中

  @HiveField(16)
  String rawConfig; // 原始配置字符串

  @HiveField(17)
  String? flow; // vless flow

  @HiveField(18)
  String? publicKey; // reality public key

  @HiveField(19)
  String? shortId; // reality short id

  @HiveField(20)
  String? spiderX; // reality spider x

  ServerNode({
    required this.id,
    required this.name,
    required this.host,
    required this.port,
    required this.protocol,
    this.uuid = '',
    this.alterId = '0',
    this.security = 'auto',
    this.network = 'tcp',
    this.path = '',
    this.host2 = '',
    this.tls = false,
    this.sni = '',
    this.fingerprint,
    this.latency,
    this.selected = false,
    this.rawConfig = '',
    this.flow,
    this.publicKey,
    this.shortId,
    this.spiderX,
  });

  String get protocolName {
    switch (protocol) {
      case ServerProtocol.vmess:
        return 'VMess';
      case ServerProtocol.vless:
        return 'VLESS';
      case ServerProtocol.trojan:
        return 'Trojan';
      case ServerProtocol.shadowsocks:
        return 'Shadowsocks';
      case ServerProtocol.socks:
        return 'SOCKS5';
      case ServerProtocol.http:
        return 'HTTP';
    }
  }

  String get latencyText {
    if (latency == null) return '--';
    if (latency! < 0) return '超时';
    return '${latency}ms';
  }

  Color get latencyColor {
    if (latency == null) return const Color(0xFF9E9E9E);
    if (latency! < 0) return const Color(0xFFF44336);
    if (latency! < 200) return const Color(0xFF4CAF50);
    if (latency! < 500) return const Color(0xFFFFC107);
    return const Color(0xFFF44336);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'host': host,
      'port': port,
      'protocol': protocol.name,
      'uuid': uuid,
      'alterId': alterId,
      'security': security,
      'network': network,
      'path': path,
      'host2': host2,
      'tls': tls,
      'sni': sni,
      'fingerprint': fingerprint,
      'latency': latency,
      'selected': selected,
      'rawConfig': rawConfig,
      'flow': flow,
      'publicKey': publicKey,
      'shortId': shortId,
      'spiderX': spiderX,
    };
  }

  factory ServerNode.fromJson(Map<String, dynamic> json) {
    return ServerNode(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      host: json['host'] ?? '',
      port: json['port'] ?? 0,
      protocol: ServerProtocol.values.firstWhere(
        (e) => e.name == json['protocol'],
        orElse: () => ServerProtocol.vmess,
      ),
      uuid: json['uuid'] ?? '',
      alterId: json['alterId'] ?? '0',
      security: json['security'] ?? 'auto',
      network: json['network'] ?? 'tcp',
      path: json['path'] ?? '',
      host2: json['host2'] ?? '',
      tls: json['tls'] ?? false,
      sni: json['sni'] ?? '',
      fingerprint: json['fingerprint'],
      latency: json['latency'],
      selected: json['selected'] ?? false,
      rawConfig: json['rawConfig'] ?? '',
      flow: json['flow'],
      publicKey: json['publicKey'],
      shortId: json['shortId'],
      spiderX: json['spiderX'],
    );
  }
}
