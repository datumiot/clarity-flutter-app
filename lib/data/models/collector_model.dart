class Collector {
  final int id;
  final String name;
  final String serial;
  final String status; // online, offline, unknown
  final String? firmwareVersion;
  final String? connectionType;
  final int? signalStrength;
  final String? ipAddress;
  final double? storageTotal;
  final double? storageFree;
  final DateTime? lastSeen;
  final DateTime createdAt;

  const Collector({
    required this.id,
    required this.name,
    required this.serial,
    required this.status,
    this.firmwareVersion,
    this.connectionType,
    this.signalStrength,
    this.ipAddress,
    this.storageTotal,
    this.storageFree,
    this.lastSeen,
    required this.createdAt,
  });

  bool get isOnline => status == 'online';

  factory Collector.fromJson(Map<String, dynamic> json) => Collector(
        id: json['id'] as int,
        name: json['name'] as String? ?? 'Unnamed Device',
        serial: json['serial'] as String,
        status: json['status'] as String? ?? 'unknown',
        firmwareVersion: json['firmware_version'] as String?,
        connectionType: json['connection_type'] as String?,
        signalStrength: json['signal_strength'] as int?,
        ipAddress: json['ip_address'] as String?,
        storageTotal: (json['storage_total'] as num?)?.toDouble(),
        storageFree: (json['storage_free'] as num?)?.toDouble(),
        lastSeen: json['last_seen'] != null
            ? DateTime.parse(json['last_seen'] as String)
            : null,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
