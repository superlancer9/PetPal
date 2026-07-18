import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/models/reminder.dart';

/// ViewModel for Reminder management
/// Contains all business logic and state for reminders using Cloud Firestore
class ReminderVM extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  final List<Reminder> _reminders = [];
  bool _isLoading = false;
  String? _errorMessage;
  
  StreamSubscription? _remindersSubscription;
  StreamSubscription? _authSubscription;

  // Getters
  List<Reminder> get reminders => List.unmodifiable(_reminders);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  ReminderVM() {
    // Listen to auth state changes to load reminders when user logs in
    _authSubscription = _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        debugPrint('👤 User logged in: ${user.uid}, loading reminders...');
        _loadReminders();
      } else {
        debugPrint('👤 User logged out, clearing reminders...');
        _remindersSubscription?.cancel();
        _reminders.clear();
        notifyListeners();
      }
    });
    
    // Also try to load immediately if user is already logged in
    if (_auth.currentUser != null) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _loadReminders();
      });
    }
  }
  
  @override
  void dispose() {
    _remindersSubscription?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }

  /// Load reminders from Firestore
  void _loadReminders() {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('⚠️ No user logged in, cannot load reminders');
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      // Cancel existing subscription if any
      _remindersSubscription?.cancel();
      
      // Listen to real-time updates from Firestore
      debugPrint('🔍 Setting up reminders listener for user: ${user.uid}');
      _remindersSubscription = _firestore
          .collection('reminders')
          .where('userId', isEqualTo: user.uid)
          .snapshots()
          .listen((snapshot) {
        try {
          debugPrint('📦 Received reminders snapshot with ${snapshot.docs.length} reminders');
          _reminders.clear();
          for (var doc in snapshot.docs) {
            try {
              final data = doc.data();
              data['id'] = doc.id; // Use Firestore document ID
              
              // Remove Firestore-specific fields that aren't in Reminder model
              data.remove('createdAt');
              data.remove('updatedAt');
              
              final reminder = Reminder.fromJson(data);
              _reminders.add(reminder);
              debugPrint('✅ Successfully parsed reminder: ${reminder.title} (${reminder.id})');
            } catch (e, stackTrace) {
              debugPrint('❌ Error parsing reminder ${doc.id}: $e');
              debugPrint('Stack trace: $stackTrace');
              debugPrint('Data: ${doc.data()}');
            }
          }
          
          debugPrint('📊 Total reminders in list: ${_reminders.length}');
          _isLoading = false;
          _errorMessage = null;
          notifyListeners();
        } catch (e, stackTrace) {
          debugPrint('Error in reminders listener: $e');
          debugPrint('Stack trace: $stackTrace');
          _isLoading = false;
          _errorMessage = 'Failed to load reminders: $e';
          notifyListeners();
        }
      }, onError: (error, stackTrace) {
        debugPrint('Error loading reminders: $error');
        debugPrint('Stack trace: $stackTrace');
        _isLoading = false;
        _errorMessage = 'Failed to load reminders: $error';
        notifyListeners();
      });
    } catch (e) {
      debugPrint('Error setting up reminders listener: $e');
      _isLoading = false;
      _errorMessage = 'Failed to load reminders: $e';
      notifyListeners();
    }
  }

  /// Add a new reminder to Firestore
  Future<bool> addReminder(Reminder reminder) async {
    final user = _auth.currentUser;
    if (user == null) {
      _errorMessage = 'You must be logged in to add a reminder.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final reminderData = reminder.toJson();
      reminderData['userId'] = user.uid; // Add user ID to reminder data
      reminderData['createdAt'] = FieldValue.serverTimestamp();
      reminderData['updatedAt'] = FieldValue.serverTimestamp();

      // Remove id from data (Firestore will generate it)
      reminderData.remove('id');

      debugPrint('📤 Adding reminder to Firestore: $reminderData');
      final docRef = await _firestore.collection('reminders').add(reminderData);
      
      debugPrint('✅ Reminder added to Firestore with ID: ${docRef.id}');
      debugPrint('👤 User ID: ${user.uid}');
      
      // The listener will automatically update _reminders
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error adding reminder: $e');
      _isLoading = false;
      
      // Provide user-friendly error messages
      if (e.toString().contains('permission-denied')) {
        _errorMessage = 'Permission denied. Please check Firestore security rules.';
      } else {
        _errorMessage = 'Failed to add reminder: ${e.toString()}';
      }
      
      notifyListeners();
      return false;
    }
  }

  /// Update a reminder in Firestore
  Future<bool> updateReminder(Reminder updatedReminder) async {
    final user = _auth.currentUser;
    if (user == null) {
      _errorMessage = 'You must be logged in to update a reminder.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final reminderData = updatedReminder.toJson();
      reminderData['userId'] = user.uid; // Ensure userId is set
      reminderData['updatedAt'] = FieldValue.serverTimestamp();
      
      // Remove id from data (it's the document ID)
      reminderData.remove('id');

      await _firestore.collection('reminders').doc(updatedReminder.id).update(reminderData);
      
      debugPrint('✅ Reminder updated in Firestore: ${updatedReminder.id}');
      
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating reminder: $e');
      _isLoading = false;
      
      // Provide user-friendly error messages
      if (e.toString().contains('permission-denied')) {
        _errorMessage = 'Permission denied. Please check Firestore security rules.';
      } else {
        _errorMessage = 'Failed to update reminder: ${e.toString()}';
      }
      
      notifyListeners();
      return false;
    }
  }

  /// Delete a reminder from Firestore
  Future<bool> deleteReminder(String reminderId) async {
    final user = _auth.currentUser;
    if (user == null) {
      _errorMessage = 'You must be logged in to delete a reminder.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      await _firestore.collection('reminders').doc(reminderId).delete();
      
      debugPrint('✅ Reminder deleted from Firestore: $reminderId');
      
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting reminder: $e');
      _isLoading = false;
      
      // Provide user-friendly error messages
      if (e.toString().contains('permission-denied')) {
        _errorMessage = 'Permission denied. Please check Firestore security rules.';
      } else {
        _errorMessage = 'Failed to delete reminder: ${e.toString()}';
      }
      
      notifyListeners();
      return false;
    }
  }

  List<Reminder> getRemindersByPetId(String petId) {
    return _reminders.where((r) => r.petId == petId).toList();
  }

  List<Reminder> getUrgentReminders() {
    return _reminders.where((r) => r.isUrgent && !r.isCompleted).toList();
  }

  List<Reminder> getUpcomingReminders({int limit = 2}) {
    final now = DateTime.now();
    return _reminders
        .where((r) => !r.isCompleted && r.dateTime.isAfter(now))
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  int getTodayCount() {
    final now = DateTime.now();
    return _reminders.where((r) =>
      !r.isCompleted &&
      r.dateTime.year == now.year &&
      r.dateTime.month == now.month &&
      r.dateTime.day == now.day
    ).length;
  }

  int getThisWeekCount() {
    final now = DateTime.now();
    return _reminders.where((r) =>
      !r.isCompleted &&
      r.dateTime.difference(now).inDays < 7 &&
      r.dateTime.isAfter(now)
    ).length;
  }

  int getOverdueCount() {
    final now = DateTime.now();
    return _reminders.where((r) =>
      !r.isCompleted && r.dateTime.isBefore(now)
    ).length;
  }
}

