import 'async';
import 'download_status.dart';
import 'download_task.dart';

typedef DownloadFetcher = Future<String> Function(DownloadTask task);
typedef TaskCompletedCallback = Future<void> Function(DownloadTask task, String content);

/// Manages concurrent chapter downloads with throttling, retries, and state notifications.
class DownloadQueueManager {
  final int maxConcurrent;
  final DownloadFetcher fetcher;
  final TaskCompletedCallback onTaskCompleted;

  final Map<String, DownloadTask> _tasks = {};
  final List<String> _pendingQueue = [];
  final Set<String> _activeTasks = {};
  
  bool _isPaused = false;

  DownloadQueueManager({
    this.maxConcurrent = 3,
    required this.fetcher,
    required this.onTaskCompleted,
  });

  List<DownloadTask> get allTasks => _tasks.values.toList();
  bool get isPaused => _isPaused;

  void enqueue(DownloadTask task) {
    _tasks[task.taskId] = task;
    task.status = DownloadStatus.queued;
    task.updatedAt = DateTime.now();
    _pendingQueue.add(task.taskId);
    _processQueue();
  }

  void enqueueBatch(List<DownloadTask> tasks) {
    for (final task in tasks) {
      _tasks[task.taskId] = task;
      task.status = DownloadStatus.queued;
      task.updatedAt = DateTime.now();
      _pendingQueue.add(task.taskId);
    }
    _processQueue();
  }

  void pause() {
    _isPaused = true;
  }

  void resume() {
    _isPaused = false;
    _processQueue();
  }

  void cancelTask(String taskId) {
    _pendingQueue.remove(taskId);
    final task = _tasks[taskId];
    if (task != null) {
      task.status = DownloadStatus.idle;
      task.progress = 0.0;
      task.updatedAt = DateTime.now();
    }
    _activeTasks.remove(taskId);
    _processQueue();
  }

  void _processQueue() {
    if (_isPaused) return;

    while (_activeTasks.length < maxConcurrent && _pendingQueue.isNotEmpty) {
      final taskId = _pendingQueue.removeAt(0);
      final task = _tasks[taskId];
      if (task == null || task.status == DownloadStatus.paused) continue;

      _activeTasks.add(taskId);
      _executeTask(task);
    }
  }

  Future<void> _executeTask(DownloadTask task) async {
    task.status = DownloadStatus.downloading;
    task.progress = 0.1;
    task.updatedAt = DateTime.now();

    try {
      final content = await fetcher(task);
      task.progress = 1.0;
      task.status = DownloadStatus.completed;
      task.updatedAt = DateTime.now();

      await onTaskCompleted(task, content);
    } catch (e) {
      task.retryCount++;
      if (task.retryCount <= task.maxRetries) {
        task.status = DownloadStatus.queued;
        task.errorMessage = 'Retry ${task.retryCount}/${task.maxRetries}: $e';
        // Exponential backoff delay re-enqueueing
        final delayMs = 500 * (1 << (task.retryCount - 1));
        Future.delayed(Duration(milliseconds: delayMs), () {
          if (!_tasks.containsKey(task.taskId)) return;
          _pendingQueue.add(task.taskId);
          _processQueue();
        });
      } else {
        task.status = DownloadStatus.failed;
        task.errorMessage = e.toString();
        task.updatedAt = DateTime.now();
      }
    } finally {
      _activeTasks.remove(task.taskId);
      _processQueue();
    }
  }

  DownloadTask? getTask(String taskId) => _tasks[taskId];

  double getOverallProgress(String novelId) {
    final novelTasks = _tasks.values.where((t) => t.novelId == novelId).toList();
    if (novelTasks.isEmpty) return 0.0;
    final totalProgress = novelTasks.fold<double>(0.0, (sum, t) => sum + t.progress);
    return totalProgress / novelTasks.length;
  }
}
