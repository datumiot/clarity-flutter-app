class Alert {
  final int id;
  final String type; // offline, reading_error, low_storage, update_available
  final String message;
  final String? collectorName;
  final int? collectorId;
  final bool isRead;
  final DateTime createdAt;

  const Alert({
    required this.id,
    required this.type,
    required this.message,
    this.collectorName,
    this.collectorId,
    required this.isRead,
    required this.createdAt,
  });

  factory Alert.fromJson(Map<String, dynamic> json) => Alert(
        id: json['id'] as int,
        type: json['type'] as String,
        message: json['message'] as String,
        collectorName: json['collector_name'] as String?,
        collectorId: json['collector_id'] as int?,
        isRead: json['is_read'] as bool? ?? false,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
