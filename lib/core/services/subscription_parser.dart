import 'dart:convert';
import 'dart:typed_data';
import '../../models/server_node.dart';

/// 订阅解析服务
/// 支持 Base64 编码的订阅内容
/// 解析 vmess:// vless:// trojan:// ss:// socks:// 协议链接
class SubscriptionParser {
  /// 解析订阅内容，返回服务器节点列表
  static List<ServerNode> parse(String content) {
    List<ServerNode> nodes = [];

    // 尝试Base64解码
    String decoded = _tryBase64Decode(content.trim());
    List<String> lines = decoded
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    for (String line in lines) {
      try {
        ServerNode? node = _parseLine(line);
        if (node != null) {
          nodes.add(node);
        }
      } catch (e) {
        // 忽略解析失败的行
      }
    }

    return nodes;
  }

  static String _tryBase64Decode(String input) {
    try {
      // 补全base64 padding
      String padded = input;
      while (padded.length % 4 != 0) {
        padded += '=';
      }
      Uint8List bytes = base64Decode(padded);
      return utf8.decode(bytes);
    } catch (_) {
      return input;
    }
  }

  static ServerNode? _parseLine(String line) {
    if (line.startsWith('vmess://')) {
      return _parseVmess(line);
    } else if (line.startsWith('vless://')) {
      return _parseVless(line);
    } else if (line.startsWith('trojan://')) {
      return _parseTrojan(line);
    } else if (line.startsWith('ss://')) {
      return _parseShadowsocks(line);
    } else if (line.startsWith('socks5://') || line.startsWith('socks://')) {
      return _parseSocks(line);
    }
    return null;
  }

  // ==================== VMess ====================
  static ServerNode? _parseVmess(String url) {
    try {
      String encoded = url.substring('vmess://'.length);
      String decoded = _tryBase64Decode(encoded);
      Map<String, dynamic> json = jsonDecode(decoded);

      String name = Uri.decodeComponent(json['ps']?.toString() ?? '未命名节点');
      String host = json['add']?.toString() ?? '';
      int port = int.tryParse(json['port']?.toString() ?? '0') ?? 0;
      String uuid = json['id']?.toString() ?? '';
      String alterId = json['aid']?.toString() ?? '0';
      String security = json['scy']?.toString() ?? json['type']?.toString() ?? 'auto';
      String network = json['net']?.toString() ?? 'tcp';
      String path = json['path']?.toString() ?? '';
      String host2 = json['host']?.toString() ?? '';
      bool tls = json['tls']?.toString() == 'tls';
      String sni = json['sni']?.toString() ?? host2;
      String? fingerprint = json['fp']?.toString();

      return ServerNode(
        id: _generateId(url),
        name: name,
        host: host,
        port: port,
        protocol: ServerProtocol.vmess,
        uuid: uuid,
        alterId: alterId,
        security: security,
        network: network,
        path: path,
        host2: host2,
        tls: tls,
        sni: sni,
        fingerprint: fingerprint,
        rawConfig: url,
      );
    } catch (e) {
      return null;
    }
  }

  // ==================== VLESS ====================
  static ServerNode? _parseVless(String url) {
    try {
      Uri uri = Uri.parse(url);
      String uuid = uri.userInfo;
      String host = uri.host;
      int port = uri.port;
      String name = Uri.decodeComponent(uri.fragment.isNotEmpty ? uri.fragment : '未命名节点');

      Map<String, String> params = uri.queryParameters;
      String network = params['type'] ?? 'tcp';
      String security = params['security'] ?? 'none';
      bool tls = security == 'tls' || security == 'reality';
      String sni = params['sni'] ?? params['peer'] ?? host;
      String path = params['path'] ?? params['serviceName'] ?? '';
      String host2 = params['host'] ?? '';
      String? fingerprint = params['fp'];
      String? flow = params['flow'];
      String? publicKey = params['pbk'];
      String? shortId = params['sid'];
      String? spiderX = params['spx'];

      return ServerNode(
        id: _generateId(url),
        name: name,
        host: host,
        port: port,
        protocol: ServerProtocol.vless,
        uuid: uuid,
        security: security,
        network: network,
        path: path,
        host2: host2,
        tls: tls,
        sni: sni,
        fingerprint: fingerprint,
        rawConfig: url,
        flow: flow,
        publicKey: publicKey,
        shortId: shortId,
        spiderX: spiderX,
      );
    } catch (e) {
      return null;
    }
  }

  // ==================== Trojan ====================
  static ServerNode? _parseTrojan(String url) {
    try {
      Uri uri = Uri.parse(url);
      String password = uri.userInfo;
      String host = uri.host;
      int port = uri.port;
      String name = Uri.decodeComponent(uri.fragment.isNotEmpty ? uri.fragment : '未命名节点');

      Map<String, String> params = uri.queryParameters;
      String network = params['type'] ?? 'tcp';
      String sni = params['sni'] ?? params['peer'] ?? host;
      String path = params['path'] ?? params['serviceName'] ?? '';
      String host2 = params['host'] ?? '';
      String? fingerprint = params['fp'];

      return ServerNode(
        id: _generateId(url),
        name: name,
        host: host,
        port: port,
        protocol: ServerProtocol.trojan,
        uuid: password,
        network: network,
        path: path,
        host2: host2,
        tls: true,
        sni: sni,
        fingerprint: fingerprint,
        rawConfig: url,
      );
    } catch (e) {
      return null;
    }
  }

  // ==================== Shadowsocks ====================
  static ServerNode? _parseShadowsocks(String url) {
    try {
      // ss://BASE64(method:password)@host:port#name
      // ss://BASE64(method:password@host:port)#name
      String raw = url.substring('ss://'.length);
      String name = '';
      if (raw.contains('#')) {
        int hashIdx = raw.lastIndexOf('#');
        name = Uri.decodeComponent(raw.substring(hashIdx + 1));
        raw = raw.substring(0, hashIdx);
      }
      name = name.isEmpty ? '未命名节点' : name;

      String method, password, host;
      int port;

      if (raw.contains('@')) {
        // SIP002格式: BASE64(method:password)@host:port
        int atIdx = raw.lastIndexOf('@');
        String userInfo = raw.substring(0, atIdx);
        String hostPort = raw.substring(atIdx + 1);

        // 解码userInfo
        String decoded = _tryBase64Decode(userInfo);
        if (decoded.contains(':')) {
          int colonIdx = decoded.indexOf(':');
          method = decoded.substring(0, colonIdx);
          password = decoded.substring(colonIdx + 1);
        } else {
          method = 'aes-256-gcm';
          password = decoded;
        }

        // 解析host:port
        if (hostPort.contains(']:')) {
          // IPv6
          int bracketEnd = hostPort.indexOf(']:');
          host = hostPort.substring(1, bracketEnd);
          port = int.parse(hostPort.substring(bracketEnd + 2));
        } else {
          List<String> parts = hostPort.split(':');
          host = parts[0];
          port = int.parse(parts[1]);
        }
      } else {
        // 旧格式: BASE64(method:password@host:port)
        String decoded = _tryBase64Decode(raw);
        // method:password@host:port
        int atIdx = decoded.lastIndexOf('@');
        String userInfo = decoded.substring(0, atIdx);
        String hostPort = decoded.substring(atIdx + 1);

        int colonIdx = userInfo.indexOf(':');
        method = userInfo.substring(0, colonIdx);
        password = userInfo.substring(colonIdx + 1);

        List<String> parts = hostPort.split(':');
        host = parts[0];
        port = int.parse(parts[1]);
      }

      return ServerNode(
        id: _generateId(url),
        name: name,
        host: host,
        port: port,
        protocol: ServerProtocol.shadowsocks,
        uuid: password,
        security: method,
        rawConfig: url,
      );
    } catch (e) {
      return null;
    }
  }

  // ==================== SOCKS5 ====================
  static ServerNode? _parseSocks(String url) {
    try {
      Uri uri = Uri.parse(url.replaceFirst('socks5://', 'socks://'));
      String name = Uri.decodeComponent(uri.fragment.isNotEmpty ? uri.fragment : '未命名节点');

      return ServerNode(
        id: _generateId(url),
        name: name,
        host: uri.host,
        port: uri.port,
        protocol: ServerProtocol.socks,
        uuid: uri.userInfo.contains(':') ? uri.userInfo.split(':')[1] : '',
        rawConfig: url,
      );
    } catch (e) {
      return null;
    }
  }

  static String _generateId(String url) {
    return url.hashCode.abs().toString();
  }
}
