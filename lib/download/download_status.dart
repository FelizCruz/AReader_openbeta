/// Represents the lifecycle status of a chapter download task.
enum DownloadStatus {
  idle,
  queued,
  downloading,
  completed,
  failed,
  paused,
}

extension DownloadStatusX on DownloadStatus {
  bool get isTerminal => this == DownloadStatus.completed || this == DownloadStatus.failed;
  bool get isActive => this == DownloadStatus.queued || this == DownloadStatus.downloading;
  
  String get label {
    switch (this) {
      case DownloadStatus.idle:
        return 'Idle';
      case DownloadStatus.queued:
        return 'Queued';
      case DownloadStatus.downloading:
        return 'Downloading';
      case DownloadStatus.completed:
        return 'Completed';
      case DownloadStatus.failed:
        return 'Failed';
      case DownloadStatus.paused:
        return 'Paused';
    }
  }
}
