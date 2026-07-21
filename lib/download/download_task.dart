import 'download_status.dart';

/// Represents a single chapter download task unit.
class DownloadTask {
  final String taskId;
  final String novelId;
  final String chapterId;
  final String chapterTitle;
  final String downloadUrl;

  DownloadStatus status;
  double progress; // 0.0 to 1.0
  int retryCount;
  final int maxRetries;
  String? errorMessage;
  final DateTime createdAt;
  DateTime updatedAt;

  DownloadTask({
    required this.taskId,
    required this.novelId,
    required this.chapterId,
    required this.chapterTitle,
    required this.downloadUrl,
    this.status = DownloadStatus.idle,
    this.progress = 0.0,
    this.retryCount = 0,
    this.maxRetries = 3,
    this.errorMessage,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'taskId': taskId,
      'novelId': novelId,
      'chapterId': chapterId,
      'chapterTitle': chapterTitle,
      'downloadUrl': downloadUrl,
      'status': status.name,
      'progress': progress,
      'retryCount': retryCount,
      'maxRetries': maxRetries,
      'errorMessage': errorMessage,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory DownloadTask.fromJson(Map<String, dynamic> json) {
    return DownloadTask(
      taskId: json['taskId'] as String,
      novelId: json['novelId'] as String,
      chapterId: json['chapterId'] as String,
      chapterTitle: json['chapterTitle'] as String,
      downloadUrl: json['downloadUrl'] as String,
      status: DownloadStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => DownloadStatus.idle,
      ),
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      retryCount: json['retryCount'] as int? ?? 0,
      maxRetries: json['maxRetries'] as int? ?? 3,
      errorMessage: json['errorMessage'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }
}
