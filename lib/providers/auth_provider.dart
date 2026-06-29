import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isDarkMode = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;
  String? get errorMessage => _errorMessage;
  String get userRole => _currentUser?.role ?? 'student';
  String? get tuitionId => _currentUser?.tuitionId;
  bool get isDarkMode => _isDarkMode;

  /// Initialize user from Firebase Auth state
  Future<void> initializeUser() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Load dark mode preference
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode = prefs.getBool('is_dark_mode') ?? false;

      final firebaseUser = _authService.currentUser;
      
      if (firebaseUser != null) {
        try {
          final firestoreUser = await _firestoreService.getUser(firebaseUser.uid);
          if (firestoreUser != null) {
            _currentUser = UserModel.fromMap(firestoreUser);
            debugPrint('AuthProvider: Loaded user profile from Firestore');
          } else {
            final fetchedRole = await _firestoreService.getUserRole(firebaseUser.uid);
            _currentUser = UserModel(
              uid: firebaseUser.uid,
              name: firebaseUser.email?.split('@')[0] ?? 'User',
              email: firebaseUser.email ?? '',
              role: fetchedRole ?? 'student',
            );
            debugPrint('AuthProvider: No Firestore profile found, using defaults');
          }
        } catch (e) {
          debugPrint('AuthProvider: Failed to initialize user from Firestore: $e');
          _currentUser = UserModel(
            uid: firebaseUser.uid,
            name: firebaseUser.email?.split('@')[0] ?? 'User',
            email: firebaseUser.email ?? '',
            role: 'student',
          );
        }
      } else {
        debugPrint('AuthProvider: No Firebase user found');
      }
    } catch (e) {
      debugPrint('AuthProvider: Error initializing user: $e');
      // Don't crash - just set loading to false
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sign in with email and password
  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final credential = await _authService.signInWithEmail(email, password);
      final user = credential.user;
      
      if (user != null) {
        try {
          final firestoreUser = await _firestoreService.getUser(user.uid);
          if (firestoreUser != null) {
            _currentUser = UserModel.fromMap(firestoreUser);
            debugPrint('AuthProvider: User logged in and loaded from Firestore');
          } else {
            final fetchedRole = await _firestoreService.getUserRole(user.uid);
            _currentUser = UserModel(
              uid: user.uid,
              name: user.email?.split('@')[0] ?? 'User',
              email: user.email ?? '',
              role: fetchedRole ?? 'student',
            );
            debugPrint('AuthProvider: User logged in without Firestore profile');
          }
        } catch (e) {
          debugPrint('AuthProvider: Failed to load user profile after login: $e');
          _currentUser = UserModel(
            uid: user.uid,
            name: user.email?.split('@')[0] ?? 'User',
            email: user.email ?? '',
            role: 'student',
          );
        }

        _isLoading = false;
        notifyListeners();
        return true;
      }
      
      _errorMessage = 'Sign in failed';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Sign up with email, password, and role
  Future<bool> signUp(String email, String password, String name, String role, {String? linkedStudentId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final credential = await _authService.signUpWithEmail(email, password);
      final user = credential.user;
      
      if (user != null) {
        // Save user data to Firestore (include parent link if provided)
        await _firestoreService.saveUserData(
          uid: user.uid,
          name: name,
          email: user.email ?? '',
          role: role,
          linkedStudentId: linkedStudentId,
        );

        // If parent signed up with a child identifier, try to link both ways
        if (role == 'parent' && linkedStudentId != null && linkedStudentId.isNotEmpty) {
          try {
            String? studentUid;
            if (linkedStudentId.contains('@')) {
              studentUid = await _firestoreService.findUserByEmail(linkedStudentId);
            } else {
              // assume it's UID
              final doc = await _firestoreService.getUser(linkedStudentId);
              if (doc != null) studentUid = linkedStudentId;
            }

            if (studentUid != null) {
              await _firestoreService.addParentToStudent(studentUid, user.uid);
            }
          } catch (e) {
            debugPrint('AuthProvider: Failed to link parent to student: $e');
          }
        }
        
        _currentUser = UserModel(
          uid: user.uid,
          name: name,
          email: user.email ?? '',
          role: role,
        );
        _isLoading = false;
        notifyListeners();
        return true;
      }
      
      _errorMessage = 'Sign up failed';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _authService.signOut();
      _currentUser = null;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Error signing out: $e');
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Send password reset email
  Future<bool> sendPasswordReset(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.sendPasswordResetEmail(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Send email verification link
  Future<bool> sendEmailVerification() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.sendEmailVerification();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Set user role (local only, no Firestore)
  Future<void> setUserRole(String role) async {
    if (_currentUser == null) return;

    final uid = _currentUser!.uid;
    _currentUser = _currentUser!.copyWith(role: role);
    notifyListeners();

    // Persist to Firestore
    try {
      await _firestoreService.setUserRole(uid, role);
    } catch (e) {
      debugPrint('AuthProvider: Failed to persist role change - $e');
    }
  }

  /// Set tuition ID locally and persist it to Firestore
  Future<void> setTuitionId(String tuitionId) async {
    if (_currentUser == null) return;

    final uid = _currentUser!.uid;
    _currentUser = _currentUser!.copyWith(tuitionId: tuitionId);
    notifyListeners();

    try {
      await _firestoreService.setUserTuitionId(uid, tuitionId);
      debugPrint('AuthProvider: Tuition ID persisted for user $uid');
    } catch (e) {
      debugPrint('AuthProvider: Failed to persist tuition ID: $e');
    }
  }

  /// Toggle and persist Dark Mode
  Future<void> toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', _isDarkMode);
    notifyListeners();
  }
}
