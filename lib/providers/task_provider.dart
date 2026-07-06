import 'package:flutter/foundation.dart';
import '../models/task_model.dart';
import '../services/firestore_service.dart';
import '../services/offline_cache_service.dart';
import '../services/storage_service.dart';

class TaskProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();

  bool _isLoading = false;
  String? _error;
  final OfflineCacheService _offlineCacheService = OfflineCacheService();

  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> createTask(TaskModel task) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _firestoreService.createTask(task.toMap());
      await _offlineCacheService.saveJson('last_task_created', task.toMap());
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to create task: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> editTask(String taskId, Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _firestoreService.updateTask(taskId, data);
      await _offlineCacheService.saveJson('last_task_updated', {'taskId': taskId, 'data': data});
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to edit task: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteTask(String taskId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _firestoreService.deleteTask(taskId);
      await _offlineCacheService.saveJson('last_task_deleted', {'taskId': taskId});
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete task: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleTaskCompletion(String taskId) async {
    if (_storageService.isTaskCompleted(taskId)) {
      await _storageService.markTaskIncomplete(taskId);
    } else {
      await _storageService.markTaskComplete(taskId);
    }
    notifyListeners();
  }

  bool isTaskCompleted(String taskId) {
    return _storageService.isTaskCompleted(taskId);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
