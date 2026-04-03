import 'dart:convert';
import '../../models/server_node.dart';

/// V2Ray配置文件生成器
/// 根据ServerNode生成v2ray-core所需的JSON配置
class V2rayConfigBuilder {
  static Map<String, dynamic> build(ServerNode node, {
    int localSocksPort = 10808,
    int localHttpPort = 10809,
    String dnsServer1 = '8.8.8.8',
    String dnsServer2 = '1.1.1.1',
    bool bypassCN = true,
  }) {
    return {
      'log': {
        'loglevel': 'warning',
      },
      'dns': _buildDns(dnsServer1, dnsServer2),
      'inbounds': _buildInbounds(localSocksPort, localHttpPort),
      'outbounds': _buildOutbounds(node),
      'routing': _buildRouting(bypassCN),
    };
  }

  static Map<String, dynamic> _buildDns(String dns1, String dns2) {
    return {
      'servers': [dns1, dns2, 'localhost'],
    };
  }

  static List<Map<String, dynamic>> _buildInbounds(int socksPort, int httpPort) {
    return [
      {
        'tag': 'socks',
        'port': socksPort,
        'listen': '127.0.0.1',
        'protocol': 'socks',
        'sniffing': {
          'enabled': true,
          'destOverride': ['http', 'tls'],
        },
        'settings': {
          'auth': 'noauth',
          'udp': true,
          'ip': '127.0.0.1',
        },
      },
      {
        'tag': 'http',
        'port': httpPort,
        'listen': '127.0.0.1',
        'protocol': 'http',
        'sniffing': {
          'enabled': true,
          'destOverride': ['http', 'tls'],
        },
        'settings': {
          'auth': 'noauth',
        },
      },
    ];
  }

  static List<Map<String, dynamic>> _buildOutbounds(ServerNode node) {
    List<Map<String, dynamic>> outbounds = [
      _buildMainOutbound(node),
      {
        'tag': 'direct',
        'protocol': 'freedom',
        'settings': {},
      },
      {
        'tag': 'block',
        'protocol': 'blackhole',
        'settings': {'response': {'type': 'http'}},
      },
    ];
    return outbounds;
  }

  static Map<String, dynamic> _buildMainOutbound(ServerNode node) {
    switch (node.protocol) {
      case ServerProtocol.vmess:
        return _buildVmessOutbound(node);
      case ServerProtocol.vless:
        return _buildVlessOutbound(node);
      case ServerProtocol.trojan:
        return _buildTrojanOutbound(node);
      case ServerProtocol.shadowsocks:
        return _buildShadowsocksOutbound(node);
      case ServerProtocol.socks:
        return _buildSocksOutbound(node);
      case ServerProtocol.http:
        return _buildHttpOutbound(node);
    }
  }

  static Map<String, dynamic> _buildVmessOutbound(ServerNode node) {
    return {
      'tag': 'proxy',
      'protocol': 'vmess',
      'settings': {
        'vnext': [
          {
            'address': node.host,
            'port': node.port,
            'users': [
              {
                'id': node.uuid,
                'alterId': int.tryParse(node.alterId) ?? 0,
                'security': node.security.isEmpty ? 'auto' : node.security,
                'level': 0,
              }
            ],
          }
        ],
      },
      'streamSettings': _buildStreamSettings(node),
    };
  }

  static Map<String, dynamic> _buildVlessOutbound(ServerNode node) {
    Map<String, dynamic> userObj = {
      'id': node.uuid,
      'level': 0,
      'encryption': 'none',
    };
    if (node.flow != null && node.flow!.isNotEmpty) {
      userObj['flow'] = node.flow;
    }

    return {
      'tag': 'proxy',
      'protocol': 'vless',
      'settings': {
        'vnext': [
          {
            'address': node.host,
            'port': node.port,
            'users': [userObj],
          }
        ],
      },
      'streamSettings': _buildStreamSettings(node),
    };
  }

  static Map<String, dynamic> _buildTrojanOutbound(ServerNode node) {
    return {
      'tag': 'proxy',
      'protocol': 'trojan',
      'settings': {
        'servers': [
          {
            'address': node.host,
            'port': node.port,
            'password': node.uuid,
            'level': 0,
          }
        ],
      },
      'streamSettings': _buildStreamSettings(node),
    };
  }

  static Map<String, dynamic> _buildShadowsocksOutbound(ServerNode node) {
    return {
      'tag': 'proxy',
      'protocol': 'shadowsocks',
      'settings': {
        'servers': [
          {
            'address': node.host,
            'port': node.port,
            'method': node.security,
            'password': node.uuid,
            'level': 0,
          }
        ],
      },
    };
  }

  static Map<String, dynamic> _buildSocksOutbound(ServerNode node) {
    return {
      'tag': 'proxy',
      'protocol': 'socks',
      'settings': {
        'servers': [
          {
            'address': node.host,
            'port': node.port,
            'level': 0,
          }
        ],
      },
    };
  }

  static Map<String, dynamic> _buildHttpOutbound(ServerNode node) {
    return {
      'tag': 'proxy',
      'protocol': 'http',
      'settings': {
        'servers': [
          {
            'address': node.host,
            'port': node.port,
            'level': 0,
          }
        ],
      },
    };
  }

  static Map<String, dynamic> _buildStreamSettings(ServerNode node) {
    Map<String, dynamic> stream = {
      'network': node.network,
    };

    // 传输层配置
    switch (node.network) {
      case 'ws':
        stream['wsSettings'] = {
          'path': node.path.isNotEmpty ? node.path : '/',
          'headers': node.host2.isNotEmpty ? {'Host': node.host2} : {},
        };
        break;
      case 'grpc':
        stream['grpcSettings'] = {
          'serviceName': node.path,
          'multiMode': false,
        };
        break;
      case 'h2':
      case 'http':
        stream['httpSettings'] = {
          'path': node.path.isNotEmpty ? node.path : '/',
          'host': node.host2.isNotEmpty ? [node.host2] : [node.host],
        };
        break;
      case 'quic':
        stream['quicSettings'] = {
          'security': 'none',
          'key': '',
          'header': {'type': 'none'},
        };
        break;
      case 'kcp':
        stream['kcpSettings'] = {
          'mtu': 1350,
          'tti': 50,
          'uplinkCapacity': 12,
          'downlinkCapacity': 100,
          'congestion': false,
          'readBufferSize': 2,
          'writeBufferSize': 2,
          'header': {'type': 'none'},
          'seed': node.path,
        };
        break;
    }

    // TLS / Reality 配置
    String security = node.security.toLowerCase();
    if (node.tls || security == 'tls') {
      stream['security'] = 'tls';
      Map<String, dynamic> tlsSettings = {
        'serverName': node.sni.isNotEmpty ? node.sni : node.host,
        'allowInsecure': false,
      };
      if (node.fingerprint != null && node.fingerprint!.isNotEmpty) {
        tlsSettings['fingerprint'] = node.fingerprint;
      }
      stream['tlsSettings'] = tlsSettings;
    } else if (security == 'reality') {
      stream['security'] = 'reality';
      stream['realitySettings'] = {
        'serverName': node.sni.isNotEmpty ? node.sni : node.host,
        'fingerprint': node.fingerprint ?? 'chrome',
        'show': false,
        'publicKey': node.publicKey ?? '',
        'shortId': node.shortId ?? '',
        'spiderX': node.spiderX ?? '/',
      };
    }

    return stream;
  }

  static Map<String, dynamic> _buildRouting(bool bypassCN) {
    List<Map<String, dynamic>> rules = [
      // 屏蔽广告
      {
        'type': 'field',
        'outboundTag': 'block',
        'domain': ['geosite:category-ads-all'],
      },
    ];

    if (bypassCN) {
      // 国内直连
      rules.addAll([
        {
          'type': 'field',
          'outboundTag': 'direct',
          'ip': ['geoip:private', 'geoip:cn'],
        },
        {
          'type': 'field',
          'outboundTag': 'direct',
          'domain': ['geosite:cn', 'geosite:private'],
        },
      ]);
    }

    // 其余走代理
    rules.add({
      'type': 'field',
      'outboundTag': 'proxy',
      'network': 'tcp,udp',
    });

    return {
      'domainStrategy': 'IPIfNonMatch',
      'rules': rules,
    };
  }

  /// 转为JSON字符串
  static String toJsonString(ServerNode node) {
    return const JsonEncoder.withIndent('  ').convert(build(node));
  }
}
