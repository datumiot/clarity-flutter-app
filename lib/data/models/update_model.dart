class FirmwareRelease {
  final int releaseId;
  final String version;
  final String? releaseNotes;
  final int? downloadSizeBytes;
  final bool isCritical;
  final bool requiresReboot;
  final DateTime? publishedAt;

  const FirmwareRelease({
    required this.releaseId,
    required this.version,
    this.releaseNotes,
    this.downloadSizeBytes,
    this.isCritical = false,
    this.requiresReboot = false,
    this.publishedAt,
  });

  factory FirmwareRelease.fromJson(Map<String, dynamic> json) => FirmwareRelease(
        releaseId: json['release_id'] as int,
        version: json['version'] as String,
        releaseNotes: json['release_notes'] as String?,
        downloadSizeBytes: json['download_size_bytes'] as int?,
        isCritical: json['is_critical'] as bool? ?? false,
        requiresReboot: json['requires_reboot'] as bool? ?? false,
        publishedAt: json['published_at'] != null
            ? DateTime.parse(json['published_at'] as String)
            : null,
      );

  String get formattedSize {
    if (downloadSizeBytes == null) return '-';
    if (downloadSizeBytes! < 1024) return '$downloadSizeBytes B';
    if (downloadSizeBytes! < 1048576) {
      return '${(downloadSizeBytes! / 1024).toStringAsFixed(1)} KB';
    }
    return '${(downloadSizeBytes! / 1048576).toStringAsFixed(1)} MB';
  }
}

class UpdateHistory {
  final int historyId;
  final String? fromVersion;
  final String toVersion;
  final String status;
  final String initiatedBy;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? errorMessage;

  const UpdateHistory({
    required this.historyId,
    this.fromVersion,
    required this.toVersion,
    required this.status,
    required this.initiatedBy,
    this.startedAt,
    this.completedAt,
    this.errorMessage,
  });

  factory UpdateHistory.fromJson(Map<String, dynamic> json) => UpdateHistory(
        historyId: json['history_id'] as int,
        fromVersion: json['from_version'] as String?,
        toVersion: json['to_version'] as String,
        status: json['status'] as String,
        initiatedBy: json['initiated_by'] as String,
        startedAt: json['started_at'] != null
            ? DateTime.parse(json['started_at'] as String)
            : null,
        completedAt: json['completed_at'] != null
            ? DateTime.parse(json['completed_at'] as String)
            : null,
        errorMessage: json['error_message'] as String?,
      );
}

class RestorePoint {
  final int restorePointId;
  final String version;
  final String? label;
  final int? snapshotSizeBytes;
  final bool isValid;
  final DateTime? createdAt;
  final String createdBy;

  const RestorePoint({
    required this.restorePointId,
    required this.version,
    this.label,
    this.snapshotSizeBytes,
    this.isValid = true,
    this.createdAt,
    this.createdBy = 'system',
  });

  factory RestorePoint.fromJson(Map<String, dynamic> json) => RestorePoint(
        restorePointId: json['restore_point_id'] as int,
        version: json['version'] as String,
        label: json['label'] as String?,
        snapshotSizeBytes: json['snapshot_size_bytes'] as int?,
        isValid: json['is_valid'] as bool? ?? true,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : null,
        createdBy: json['created_by'] as String? ?? 'system',
      );

  String get formattedSize {
    if (snapshotSizeBytes == null) return '-';
    if (snapshotSizeBytes! < 1024) return '$snapshotSizeBytes B';
    if (snapshotSizeBytes! < 1048576) {
      return '${(snapshotSizeBytes! / 1024).toStringAsFixed(1)} KB';
    }
    return '${(snapshotSizeBytes! / 1048576).toStringAsFixed(1)} MB';
  }
}
