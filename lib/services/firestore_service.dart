import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'offline_cache_service.dart';

/// Firestore Service - Real Firebase Firestore integration
class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final OfflineCacheService _offlineCacheService = OfflineCacheService();

  // ====== TUITION OPERATIONS ======
  
  /// Create a new tuition in Firestore
  Future<String> createTuition(Map<String, dynamic> tuitionData) async {
    try {
      debugPrint('FirestoreService: Creating tuition - ${tuitionData['name']}');
      
      final docRef = await _firestore.collection('tuitions').add(tuitionData);
      
      // Update the document with its own ID
      await docRef.update({'id': docRef.id});
      
      debugPrint('FirestoreService: Tuition created with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('FirestoreService: Error creating tuition - $e');
      rethrow;
    }
  }

  /// Get tuition by unique code
  Future<Map<String, dynamic>?> getTuitionByCode(String code) async {
    try {
      debugPrint('FirestoreService: Searching for tuition code: $code');
      
      final querySnapshot = await _firestore
          .collection('tuitions')
          .where('tuitionCode', isEqualTo: code)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isEmpty) {
        debugPrint('FirestoreService: No tuition found with code: $code');
        return null;
      }
      
      final doc = querySnapshot.docs.first;
      final tuitionData = doc.data();
      tuitionData['id'] = doc.id;
      debugPrint('FirestoreService: Found tuition - ${tuitionData['name']} with ID: ${doc.id}');
      return tuitionData;
    } catch (e) {
      debugPrint('FirestoreService: Error fetching tuition by code - $e');
      rethrow;
    }
  }

  /// Add student to tuition with full student data
  Future<void> addStudentToTuition({
    required String tuitionId,
    required String studentId,
    required String studentName,
    required String studentEmail,
  }) async {
    try {
      debugPrint('FirestoreService: Adding student $studentName ($studentId) to tuition $tuitionId');
      
      final studentData = {
        'uid': studentId,
        'name': studentName,
        'email': studentEmail,
        'joinedAt': DateTime.now().toIso8601String(),
      };

      await _firestore.collection('tuitions').doc(tuitionId).update({
        'students': FieldValue.arrayUnion([studentData]),
        'studentIds': FieldValue.arrayUnion([studentId]),
      });
      
      debugPrint('FirestoreService: Student added successfully');
    } catch (e) {
      debugPrint('FirestoreService: Error adding student - $e');
      rethrow;
    }
  }

  /// Get tuition by ID
  Future<Map<String, dynamic>?> getTuitionById(String tuitionId) async {
    try {
      debugPrint('FirestoreService: Fetching tuition $tuitionId');
      
      final doc = await _firestore.collection('tuitions').doc(tuitionId).get();
      
      if (!doc.exists) {
        debugPrint('FirestoreService: Tuition not found');
        return null;
      }
      
      final data = doc.data();
      if (data != null) {
        data['id'] = doc.id;
      }
      return data;
    } catch (e) {
      debugPrint('FirestoreService: Error fetching tuition - $e');
      rethrow;
    }
  }

  /// Get all tuitions created by a teacher
  Future<List<Map<String, dynamic>>> getTuitionsByTeacher(String teacherId) async {
    try {
      debugPrint('FirestoreService: Fetching tuitions for teacher $teacherId');
      
      final querySnapshot = await _firestore
          .collection('tuitions')
          .where('teacherId', isEqualTo: teacherId)
          .get();
      
      final tuitions = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      
      // Sort in memory to avoid composite index requirements
      tuitions.sort((a, b) {
        final aTime = a['createdAt'];
        final bTime = b['createdAt'];
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.toString().compareTo(aTime.toString());
      });

      await _offlineCacheService.saveJsonList('cached_tuitions', tuitions);
      
      debugPrint('FirestoreService: Found ${tuitions.length} tuitions');
      return tuitions;
    } catch (e) {
      debugPrint('FirestoreService: Error fetching teacher tuitions - $e');
      return await _offlineCacheService.loadJsonList('cached_tuitions');
    }
  }

  /// Get all tuitions where student is enrolled
  Future<List<Map<String, dynamic>>> getTuitionsByStudent(String studentId) async {
    try {
      debugPrint('FirestoreService: Fetching tuitions for student $studentId');
      
      final querySnapshot = await _firestore
          .collection('tuitions')
          .where('studentIds', arrayContains: studentId)
          .get();
      
      final tuitions = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      
      // Sort in memory to avoid composite index requirements
      tuitions.sort((a, b) {
        final aTime = a['createdAt'];
        final bTime = b['createdAt'];
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.toString().compareTo(aTime.toString());
      });

      await _offlineCacheService.saveJsonList('cached_tuitions', tuitions);
      
      debugPrint('FirestoreService: Found ${tuitions.length} tuitions');
      return tuitions;
    } catch (e) {
      debugPrint('FirestoreService: Error fetching student tuitions - $e');
      return await _offlineCacheService.loadJsonList('cached_tuitions');
    }
  }

  // ====== USER OPERATIONS ======
  
  /// Save user data to Firestore (called during signup)
  /// Creates user document with uid, name, email, role, and timestamp
  /// Uses .set() which will overwrite if user already exists (prevents duplicates)
  Future<void> saveUserData({
    required String uid,
    required String name,
    required String email,
    required String role,
    String? linkedStudentId,
  }) async {
    try {
      debugPrint('FirestoreService: Saving user data for $uid with role $role');
      
      // Check if user already exists to prevent duplicates
      final userDoc = await _firestore.collection('users').doc(uid).get();
      
      if (userDoc.exists) {
        debugPrint('FirestoreService: User $uid already exists, updating instead of creating');
        // Update existing user data
        final updateData = {
          'name': name,
          'email': email,
          'role': role,
          'updatedAt': FieldValue.serverTimestamp(),
        };
        if (linkedStudentId != null) updateData['linkedStudentId'] = linkedStudentId;
        await _firestore.collection('users').doc(uid).update(updateData);
        debugPrint('FirestoreService: User data updated successfully');
      } else {
        // Create new user document
        final createData = {
          'uid': uid,
          'name': name,
          'email': email,
          'role': role,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };
        if (linkedStudentId != null) createData['linkedStudentId'] = linkedStudentId;
        await _firestore.collection('users').doc(uid).set(createData);
        debugPrint('FirestoreService: User data created successfully');
      }
    } catch (e) {
      debugPrint('FirestoreService: Error saving user data - $e');
      rethrow;
    }
  }

  /// Get user role from Firestore
  Future<String?> getUserRole(String userId) async {
    try {
      debugPrint('FirestoreService: Fetching role for user $userId');
      
      final doc = await _firestore.collection('users').doc(userId).get();
      
      if (!doc.exists) {
        debugPrint('FirestoreService: User document not found');
        return null;
      }
      
      final data = doc.data();
      final role = data?['role'] as String?;
      if (role != null) {
        await _offlineCacheService.saveJson('cached_user', data ?? {});
      }
      
      debugPrint('FirestoreService: User role is $role');
      return role;
    } catch (e) {
      debugPrint('FirestoreService: Error fetching user role - $e');
      final cachedUser = await _offlineCacheService.loadJson('cached_user');
      return cachedUser?['role'] as String?;
    }
  }

  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(userId).set(data, SetOptions(merge: true));
    } catch (e) {
      debugPrint('FirestoreService: Error updating user - $e');
      rethrow;
    }
  }

  /// Find a user document by email, returns UID or null
  Future<String?> findUserByEmail(String email) async {
    try {
      final q = await _firestore.collection('users').where('email', isEqualTo: email).limit(1).get();
      if (q.docs.isEmpty) return null;
      return q.docs.first.id;
    } catch (e) {
      debugPrint('FirestoreService: Error finding user by email - $e');
      return null;
    }
  }

  /// Add parent UID to student's `parentIds` array
  Future<void> addParentToStudent(String studentUid, String parentUid) async {
    try {
      await _firestore.collection('users').doc(studentUid).set({
        'parentIds': FieldValue.arrayUnion([parentUid]),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('FirestoreService: Error adding parent to student - $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getUser(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          await _offlineCacheService.saveJson('cached_user', data);
        }
        return data;
      }
      return null;
    } catch (e) {
      debugPrint('FirestoreService: Error fetching user - $e');
      return await _offlineCacheService.loadJson('cached_user');
    }
  }

  Future<void> setUserRole(String userId, String role) async {
    try {
      await _firestore.collection('users').doc(userId).update({'role': role});
    } catch (e) {
      debugPrint('FirestoreService: Error setting user role - $e');
      rethrow;
    }
  }

  Future<void> setUserTuitionId(String userId, String tuitionId) async {
    try {
      await _firestore.collection('users').doc(userId).set(
        {'tuitionId': tuitionId},
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('FirestoreService: Error setting user tuitionId - $e');
      rethrow;
    }
  }

  // ====== STUDENT OPERATIONS ======
  
  Stream<List<Map<String, dynamic>>> getStudents(String tuitionId) {
    return _firestore
        .collection('tuitions')
        .doc(tuitionId)
        .snapshots()
        .map((snapshot) {
      final data = snapshot.data();
      if (data == null) return [];
      
      final studentIds = List<String>.from(data['students'] ?? []);
      // Return student IDs (can be enhanced to fetch full user data)
      return studentIds.map((id) => {'id': id}).toList();
    });
  }

  Future<List<Map<String, dynamic>>> getStudentsInTuition(String tuitionId) async {
    try {
      final doc = await _firestore.collection('tuitions').doc(tuitionId).get();
      final data = doc.data();
      
      if (data == null) return [];
      
      final studentIds = List<String>.from(data['students'] ?? []);
      return studentIds.map((id) => {'id': id}).toList();
    } catch (e) {
      debugPrint('FirestoreService: Error fetching students - $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getStudentsForFeedback(String tuitionId) async {
    return getStudentsInTuition(tuitionId);
  }

  // ====== TASK OPERATIONS ======
  
  Future<List<Map<String, dynamic>>> getTasks(String tuitionId) async {
    try {
      final querySnapshot = await _firestore
          .collection('tasks')
          .where('tuitionId', isEqualTo: tuitionId)
          .orderBy('createdAt', descending: true)
          .get();
      
      final tasks = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      await _offlineCacheService.saveJsonList('cached_tasks', tasks);
      return tasks;
    } catch (e) {
      debugPrint('FirestoreService: Error fetching tasks - $e');
      return await _offlineCacheService.loadJsonList('cached_tasks');
    }
  }

  Future<List<Map<String, dynamic>>> getTasksForTuition(String tuitionId) async {
    return getTasks(tuitionId);
  }

  Future<void> addTask(Map<String, dynamic> taskData) async {
    try {
      taskData['createdAt'] = FieldValue.serverTimestamp();
      final docRef = await _firestore.collection('tasks').add(taskData);
      await docRef.update({'id': docRef.id});
    } catch (e) {
      debugPrint('FirestoreService: Error adding task - $e');
      rethrow;
    }
  }

  Future<void> createTask(Map<String, dynamic> taskData) async {
    return addTask(taskData);
  }

  Future<void> updateTask(String taskId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('tasks').doc(taskId).update(data);
    } catch (e) {
      debugPrint('FirestoreService: Error updating task - $e');
      rethrow;
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      await _firestore.collection('tasks').doc(taskId).delete();
    } catch (e) {
      debugPrint('FirestoreService: Error deleting task - $e');
      rethrow;
    }
  }

  // ====== FEEDBACK OPERATIONS ======
  
  Future<List<Map<String, dynamic>>> getFeedbacks(String studentId) async {
    try {
      final querySnapshot = await _firestore
          .collection('feedbacks')
          .where('studentId', isEqualTo: studentId)
          .get();
      
      final list = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      // Sort in memory to avoid composite index requirements
      list.sort((a, b) {
        final aTime = a['createdAt'];
        final bTime = b['createdAt'];
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.toString().compareTo(aTime.toString());
      });
      await _offlineCacheService.saveJsonList('cached_feedbacks', list);
      return list;
    } catch (e) {
      debugPrint('FirestoreService: Error fetching feedbacks - $e');
      return await _offlineCacheService.loadJsonList('cached_feedbacks');
    }
  }

  Future<List<Map<String, dynamic>>> getFeedbackForStudent(String studentId) async {
    return getFeedbacks(studentId);
  }

  Future<void> addFeedback(Map<String, dynamic> feedbackData) async {
    try {
      await _firestore.collection('feedbacks').add(feedbackData);
    } catch (e) {
      debugPrint('FirestoreService: Error adding feedback - $e');
      rethrow;
    }
  }

  Future<void> createFeedback(Map<String, dynamic> feedbackData) async {
    return addFeedback(feedbackData);
  }

  // ====== STUDY SESSION OPERATIONS ======
  
  Future<void> saveStudySession(Map<String, dynamic> sessionData) async {
    try {
      await _firestore.collection('study_sessions').add(sessionData);
    } catch (e) {
      debugPrint('FirestoreService: Error saving study session - $e');
      rethrow;
    }
  }

  // ====== EDIT / DELETE CLASS ======

  Future<void> updateTuition(String tuitionId, Map<String, dynamic> updateData) async {
    try {
      await _firestore.collection('tuitions').doc(tuitionId).update(updateData);
    } catch (e) {
      debugPrint('FirestoreService: Error updating tuition - $e');
      rethrow;
    }
  }

  Future<void> deleteTuition(String tuitionId) async {
    try {
      await _firestore.collection('tuitions').doc(tuitionId).delete();
    } catch (e) {
      debugPrint('FirestoreService: Error deleting tuition - $e');
      rethrow;
    }
  }

  // ====== ANNOUNCEMENT OPERATIONS ======

  Future<void> createAnnouncement(String tuitionId, String content, String teacherId, String teacherName) async {
    try {
      await _firestore.collection('announcements').add({
        'tuitionId': tuitionId,
        'content': content,
        'teacherId': teacherId,
        'teacherName': teacherName,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('FirestoreService: Error creating announcement - $e');
      rethrow;
    }
  }

  Stream<List<Map<String, dynamic>>> getAnnouncements(String tuitionId) {
    return _firestore
        .collection('announcements')
        .where('tuitionId', isEqualTo: tuitionId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  // ====== ATTENDANCE OPERATIONS ======

  Future<void> saveAttendance(String tuitionId, String date, List<String> presentStudentIds) async {
    try {
      final docId = '${tuitionId}_$date';
      await _firestore.collection('attendance').doc(docId).set({
        'tuitionId': tuitionId,
        'date': date,
        'presentStudentIds': presentStudentIds,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('FirestoreService: Error saving attendance - $e');
      rethrow;
    }
  }

  Stream<List<Map<String, dynamic>>> getAttendanceHistory(String tuitionId) async* {
    final cacheKey = 'cached_attendance_history_$tuitionId';
    final cached = await _offlineCacheService.loadJsonList(cacheKey);
    if (cached.isNotEmpty) {
      yield cached;
    }

    try {
      await for (final snapshot in _firestore
          .collection('attendance')
          .where('tuitionId', isEqualTo: tuitionId)
          .orderBy('date', descending: true)
          .snapshots()) {
        final list = snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();
        await _offlineCacheService.saveJsonList(cacheKey, list);
        yield list;
      }
    } catch (e) {
      debugPrint('FirestoreService: Error fetching attendance history - $e');
      if (cached.isEmpty) {
        yield [];
      }
    }
  }

  // ====== SUBMISSIONS operations ======

  Future<void> submitHomework(Map<String, dynamic> submissionData) async {
    try {
      final taskId = submissionData['taskId'];
      final studentId = submissionData['studentId'];
      
      // Save submission - overwrite if same student and task
      final docId = '${taskId}_$studentId';
      await _firestore.collection('submissions').doc(docId).set({
        ...submissionData,
        'submittedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      debugPrint('FirestoreService: Submission saved');
    } catch (e) {
      debugPrint('FirestoreService: Error submitting homework - $e');
      rethrow;
    }
  }

  Stream<List<Map<String, dynamic>>> getSubmissionsForTask(String taskId) async* {
    final cacheKey = 'cached_submissions_$taskId';
    final cached = await _offlineCacheService.loadJsonList(cacheKey);
    if (cached.isNotEmpty) {
      yield cached;
    }

    try {
      await for (final snapshot in _firestore
          .collection('submissions')
          .where('taskId', isEqualTo: taskId)
          .snapshots()) {
        final list = snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();

        // Sort in memory to avoid composite index requirements
        list.sort((a, b) {
          final aTime = a['submittedAt'];
          final bTime = b['submittedAt'];
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          if (aTime is Timestamp && bTime is Timestamp) {
            return bTime.compareTo(aTime);
          }
          return bTime.toString().compareTo(aTime.toString());
        });
        await _offlineCacheService.saveJsonList(cacheKey, list);
        yield list;
      }
    } catch (e) {
      debugPrint('FirestoreService: Error fetching submissions - $e');
      if (cached.isEmpty) {
        yield [];
      }
    }
  }

  Future<void> gradeSubmission(String submissionId, String grade, String feedback) async {
    try {
      await _firestore.collection('submissions').doc(submissionId).update({
        'grade': grade,
        'feedback': feedback,
        'isGraded': true,
        'gradedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('FirestoreService: Error grading submission - $e');
      rethrow;
    }
  }

  Stream<Map<String, dynamic>?> getStudentSubmissionForTask(String studentId, String taskId) async* {
    final docId = '${taskId}_$studentId';
    final cacheKey = 'cached_submission_$docId';
    final cached = await _offlineCacheService.loadJson(cacheKey);
    if (cached != null) {
      yield cached;
    }

    try {
      await for (final doc in _firestore.collection('submissions').doc(docId).snapshots()) {
        if (doc.exists) {
          final data = doc.data();
          data?['id'] = doc.id;
          await _offlineCacheService.saveJson(cacheKey, data ?? {});
          yield data;
        } else {
          await _offlineCacheService.remove(cacheKey);
          yield null;
        }
      }
    } catch (e) {
      debugPrint('FirestoreService: Error fetching student submission - $e');
      if (cached == null) {
        yield null;
      }
    }
  }

  // ====== STREAK OPERATIONS ======

  Future<void> updateStudentStreak(String studentId, int currentStreak, String lastStudyDate) async {
    try {
      await _firestore.collection('users').doc(studentId).update({
        'currentStreak': currentStreak,
        'lastStudyDate': lastStudyDate,
      });
    } catch (e) {
      debugPrint('FirestoreService: Error updating student streak - $e');
      rethrow;
    }
  }

  Stream<Map<String, dynamic>?> getStudentStreakInfo(String studentId) {
    return _firestore.collection('users').doc(studentId).snapshots().map((doc) {
      if (doc.exists) {
        final data = doc.data();
        return {
          'currentStreak': data?['currentStreak'] ?? 0,
          'lastStudyDate': data?['lastStudyDate'] ?? '',
        };
      }
      return null;
    });
  }

  Future<List<Map<String, dynamic>>> getStudySessions(String studentId) async {
    try {
      final querySnapshot = await _firestore
          .collection('study_sessions')
          .where('studentId', isEqualTo: studentId)
          .get();
      
      final list = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      // Sort in memory to avoid composite index requirements
      list.sort((a, b) {
        final aTime = a['createdAt'];
        final bTime = b['createdAt'];
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        if (aTime is Timestamp && bTime is Timestamp) {
          return bTime.compareTo(aTime);
        }
        return bTime.toString().compareTo(aTime.toString());
      });
      return list;
    } catch (e) {
      debugPrint('FirestoreService: Error fetching study sessions - $e');
      return [];
    }
  }

  Stream<List<Map<String, dynamic>>> getStudentSubmissions(String studentId) {
    return _firestore
        .collection('submissions')
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
  }
}
