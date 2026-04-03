// GENERATED CODE - DO NOT MODIFY BY HAND
// Hive TypeAdapter for ServerNode and ServerProtocol

part of 'server_node.dart';

class ServerProtocolAdapter extends TypeAdapter<ServerProtocol> {
  @override
  final int typeId = 1;

  @override
  ServerProtocol read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ServerProtocol.vmess;
      case 1:
        return ServerProtocol.vless;
      case 2:
        return ServerProtocol.trojan;
      case 3:
        return ServerProtocol.shadowsocks;
      case 4:
        return ServerProtocol.socks;
      case 5:
        return ServerProtocol.http;
      default:
        return ServerProtocol.vmess;
    }
  }

  @override
  void write(BinaryWriter writer, ServerProtocol obj) {
    switch (obj) {
      case ServerProtocol.vmess:
        writer.writeByte(0);
        break;
      case ServerProtocol.vless:
        writer.writeByte(1);
        break;
      case ServerProtocol.trojan:
        writer.writeByte(2);
        break;
      case ServerProtocol.shadowsocks:
        writer.writeByte(3);
        break;
      case ServerProtocol.socks:
        writer.writeByte(4);
        break;
      case ServerProtocol.http:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServerProtocolAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ServerNodeAdapter extends TypeAdapter<ServerNode> {
  @override
  final int typeId = 0;

  @override
  ServerNode read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ServerNode(
      id: fields[0] as String,
      name: fields[1] as String,
      host: fields[2] as String,
      port: fields[3] as int,
      protocol: fields[4] as ServerProtocol,
      uuid: fields[5] as String,
      alterId: fields[6] as String,
      security: fields[7] as String,
      network: fields[8] as String,
      path: fields[9] as String,
      host2: fields[10] as String,
      tls: fields[11] as bool,
      sni: fields[12] as String,
      fingerprint: fields[13] as String?,
      latency: fields[14] as int?,
      selected: fields[15] as bool,
      rawConfig: fields[16] as String,
      flow: fields[17] as String?,
      publicKey: fields[18] as String?,
      shortId: fields[19] as String?,
      spiderX: fields[20] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ServerNode obj) {
    writer
      ..writeByte(21)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.host)
      ..writeByte(3)
      ..write(obj.port)
      ..writeByte(4)
      ..write(obj.protocol)
      ..writeByte(5)
      ..write(obj.uuid)
      ..writeByte(6)
      ..write(obj.alterId)
      ..writeByte(7)
      ..write(obj.security)
      ..writeByte(8)
      ..write(obj.network)
      ..writeByte(9)
      ..write(obj.path)
      ..writeByte(10)
      ..write(obj.host2)
      ..writeByte(11)
      ..write(obj.tls)
      ..writeByte(12)
      ..write(obj.sni)
      ..writeByte(13)
      ..write(obj.fingerprint)
      ..writeByte(14)
      ..write(obj.latency)
      ..writeByte(15)
      ..write(obj.selected)
      ..writeByte(16)
      ..write(obj.rawConfig)
      ..writeByte(17)
      ..write(obj.flow)
      ..writeByte(18)
      ..write(obj.publicKey)
      ..writeByte(19)
      ..write(obj.shortId)
      ..writeByte(20)
      ..write(obj.spiderX);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServerNodeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
