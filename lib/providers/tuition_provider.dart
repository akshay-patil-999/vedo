import 'package:flutter/foundation.dart';
import '../models/tuition_model.dart';
import '../services/firestore_service.dart';
import '../services/offline_cache_service.dart';
import '../core/utils/helpers.dart';

class TuitionProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final OfflineCacheService _offlineCacheService = OfflineCacheService();

  bool _isLoading = false;
  TuitionModel? _currentTuition;
  List<TuitionModel> _tuitions = [];
  String? _error;

  bool get isLoading => _isLoading;
  TuitionModel? get currentTuition => _currentTuition;
  List<TuitionModel> get tuitions => _tuitions;
  String? get error => _error;

  /// Create a new tuition with full details
  Future<TuitionModel?> createTuition({
    required String tuitionName,
    required String subject,
    required String timing,
    required String teacherId,
    required String teacherName,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Generate unique 6-character tuition code
      final tuitionCode = Helpers.generateTuitionCode();
      
      debugPrint('TuitionProvider: Creating tuition with code: $tuitionCode');

      final tuition = TuitionModel(
        id: '', // Will be set by Firestore
        name: tuitionName,
        subject: subject,
        timing: timing,
        tuitionCode: tuitionCode,
        teacherId: teacherId,
        teacherName: teacherName,
        students: [],
        createdAt: DateTime.now(),
      );

      // Save to Firestore and get the document ID
      final docId = await _firestoreService.createTuition(tuition.toMap());
      
      // Create tuition with the actual Firestore document ID
      final createdTuition = tuition.copyWith(id: docId);
      _currentTuition = createdTuition;
      await _offlineCacheService.saveJson('cached_tuition', createdTuition.toMap());

      _isLoading = false;
      notifyListeners();
      
      debugPrint('TuitionProvider: Tuition created successfully - $tuitionName');
      return createdTuition;
    } catch (e) {
      _error = 'Failed to create tuition: $e';
      _isLoading = false;
      notifyListeners();
      debugPrint('TuitionProvider: Error - $_error');
      return null;
    }
  }

  /// Join a tuition using the unique code
  Future<TuitionModel?> joinTuition({
    required String code,
    required String studentId,
    required String studentName,
    required String studentEmail,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('TuitionProvider: Attempting to join tuition with code: $code');
      
      // Search for tuition by code
      final tuitionMap = await _firestoreService.getTuitionByCode(code);
      
      if (tuitionMap == null) {
        _error = 'Invalid tuition code. Please check and try again.';
        _isLoading = false;
        notifyListeners();
        debugPrint('TuitionProvider: Tuition not found');
        return null;
      }

      final tuition = TuitionModel.fromMap(tuitionMap);
      
      // Check if student is already enrolled
      final students = tuition.students;
      final alreadyEnrolled = students.any((student) => student['uid'] == studentId);
      
      if (alreadyEnrolled) {
        _error = 'You are already enrolled in this tuition.';
        _isLoading = false;
        notifyListeners();
        debugPrint('TuitionProvider: Student already enrolled');
        return null;
      }

      // Add student to tuition's students array with full data
      await _firestoreService.addStudentToTuition(
        tuitionId: tuition.id,
        studentId: studentId,
        studentName: studentName,
        studentEmail: studentEmail,
      );
      
      // Update local tuition object
      final newStudent = {
        'uid': studentId,
        'name': studentName,
        'email': studentEmail,
        'joinedAt': DateTime.now().toIso8601String(),
      };
      
      _currentTuition = tuition.copyWith(
        students: [...students, newStudent],
      );
      await _offlineCacheService.saveJson('cached_tuition', _currentTuition!.toMap());

      _isLoading = false;
      notifyListeners();
      
      debugPrint('TuitionProvider: Successfully joined tuition - ${tuition.name}');
      return _currentTuition;
    } catch (e) {
      _error = 'Failed to join tuition: $e';
      _isLoading = false;
      notifyListeners();
      debugPrint('TuitionProvider: Error - $_error');
      return null;
    }
  }

  /// Get all tuitions created by a teacher
  Future<List<TuitionModel>> getTeacherTuitions(String teacherId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('TuitionProvider: Fetching teacher tuitions');
      
      final tuitionsMap = await _firestoreService.getTuitionsByTeacher(teacherId);
      
      _tuitions = tuitionsMap.map((map) => TuitionModel.fromMap(map)).toList();
      await _offlineCacheService.saveJsonList('cached_tuitions', _tuitions.map((item) => item.toMap()).toList());
      
      _isLoading = false;
      notifyListeners();
      
      debugPrint('TuitionProvider: Found ${_tuitions.length} tuitions');
      return _tuitions;
    } catch (e) {
      _error = 'Failed to load tuitions: $e';
      _isLoading = false;
      notifyListeners();
      debugPrint('TuitionProvider: Error - $_error');
      return [];
    }
  }

  /// Get all tuitions where student is enrolled
  Future<List<TuitionModel>> getStudentTuitions(String studentId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('TuitionProvider: Fetching student tuitions');
      
      final tuitionsMap = await _firestoreService.getTuitionsByStudent(studentId);
      
      _tuitions = tuitionsMap.map((map) => TuitionModel.fromMap(map)).toList();
      await _offlineCacheService.saveJsonList('cached_tuitions', _tuitions.map((item) => item.toMap()).toList());
      
      _isLoading = false;
      notifyListeners();
      
      debugPrint('TuitionProvider: Found ${_tuitions.length} tuitions');
      return _tuitions;
    } catch (e) {
      _error = 'Failed to load tuitions: $e';
      _isLoading = false;
      notifyListeners();
      debugPrint('TuitionProvider: Error - $_error');
      return [];
    }
  }

  /// Get a single tuition by ID
  Future<TuitionModel?> getTuitionById(String tuitionId) async {
    try {
      final tuitionMap = await _firestoreService.getTuitionById(tuitionId);
      
      if (tuitionMap == null) return null;
      
      return TuitionModel.fromMap(tuitionMap);
    } catch (e) {
      debugPrint('TuitionProvider: Error fetching tuition - $e');
      return null;
    }
  }

  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Clear current tuition
  void clearCurrentTuition() {
    _currentTuition = null;
    notifyListeners();
  }
}
