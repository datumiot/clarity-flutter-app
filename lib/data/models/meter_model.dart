class Meter {
  final int id;
  final int collectorId;
  final String name;
  final String type; // SDM230, SDM630, etc.
  final int modbusAddress;
  final String? serial;
  final DateTime createdAt;

  const Meter({
    required this.id,
    required this.collectorId,
    required this.name,
    required this.type,
    required this.modbusAddress,
    this.serial,
    required this.createdAt,
  });

  factory Meter.fromJson(Map<String, dynamic> json) => Meter(
        id: json['id'] as int,
        collectorId: json['collector_id'] as int,
        name: json['name'] as String? ?? 'Unnamed Meter',
        type: json['type'] as String? ?? 'Unknown',
        modbusAddress: json['modbus_address'] as int? ?? 1,
        serial: json['serial'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

class MeterReading {
  final int id;
  final int meterId;
  final double? voltage;
  final double? current;
  final double? power;
  final double? energy;
  final double? frequency;
  final double? powerFactor;
  final DateTime timestamp;

  const MeterReading({
    required this.id,
    required this.meterId,
    this.voltage,
    this.current,
    this.power,
    this.energy,
    this.frequency,
    this.powerFactor,
    required this.timestamp,
  });

  factory MeterReading.fromJson(Map<String, dynamic> json) => MeterReading(
        id: json['id'] as int,
        meterId: json['meter_id'] as int,
        voltage: (json['voltage'] as num?)?.toDouble(),
        current: (json['current'] as num?)?.toDouble(),
        power: (json['power'] as num?)?.toDouble(),
        energy: (json['energy'] as num?)?.toDouble(),
        frequency: (json['frequency'] as num?)?.toDouble(),
        powerFactor: (json['power_factor'] as num?)?.toDouble(),
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}
