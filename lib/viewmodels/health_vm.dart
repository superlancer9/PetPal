import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/models/vaccination.dart';
import '../data/models/medication.dart';
import '../data/models/vet_visit.dart';
import '../data/models/surgery.dart';
import '../data/models/allergy.dart';

/// ViewModel for Health Records management
/// Contains all business logic and state for all health record types using Cloud Firestore
class HealthVM extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Health record lists
  final List<Vaccination> _vaccinations = [];
  final List<Medication> _medications = [];
  final List<VetVisit> _vetVisits = [];
  final List<Surgery> _surgeries = [];
  final List<Allergy> _allergies = [];
  
  bool _isLoading = false;
  String? _errorMessage;
  
  // Stream subscriptions
  StreamSubscription? _vaccinationsSubscription;
  StreamSubscription? _medicationsSubscription;
  StreamSubscription? _vetVisitsSubscription;
  StreamSubscription? _surgeriesSubscription;
  StreamSubscription? _allergiesSubscription;
  StreamSubscription? _authSubscription;

  // Getters
  List<Vaccination> get vaccinations => List.unmodifiable(_vaccinations);
  List<Medication> get medications => List.unmodifiable(_medications);
  List<VetVisit> get vetVisits => List.unmodifiable(_vetVisits);
  List<Surgery> get surgeries => List.unmodifiable(_surgeries);
  List<Allergy> get allergies => List.unmodifiable(_allergies);
  
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  HealthVM() {
    // Listen to auth state changes to load all health records when user logs in
    _authSubscription = _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        debugPrint('👤 User logged in: ${user.uid}, loading health records...');
        _loadAllHealthRecords();
      } else {
        debugPrint('👤 User logged out, clearing health records...');
        _cancelAllSubscriptions();
        _clearAllData();
        notifyListeners();
      }
    });
    
    // Also try to load immediately if user is already logged in
    if (_auth.currentUser != null) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _loadAllHealthRecords();
      });
    }
  }
  
  @override
  void dispose() {
    _cancelAllSubscriptions();
    super.dispose();
  }

  void _cancelAllSubscriptions() {
    _vaccinationsSubscription?.cancel();
    _medicationsSubscription?.cancel();
    _vetVisitsSubscription?.cancel();
    _surgeriesSubscription?.cancel();
    _allergiesSubscription?.cancel();
    _authSubscription?.cancel();
  }

  void _clearAllData() {
    _vaccinations.clear();
    _medications.clear();
    _vetVisits.clear();
    _surgeries.clear();
    _allergies.clear();
  }

  /// Load all health records from Firestore
  void _loadAllHealthRecords() {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('⚠️ No user logged in, cannot load health records');
        return;
      }

      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _loadVaccinations(user.uid);
      _loadMedications(user.uid);
      _loadVetVisits(user.uid);
      _loadSurgeries(user.uid);
      _loadAllergies(user.uid);
    } catch (e, stackTrace) {
      debugPrint('❌ Error loading all health records: $e');
      debugPrint('Stack trace: $stackTrace');
      _isLoading = false;
      _errorMessage = 'Failed to load health records: $e';
      notifyListeners();
    }
  }

  // ========== VACCINATIONS ==========
  void _loadVaccinations(String userId) {
    try {
      _vaccinationsSubscription?.cancel();
      _vaccinationsSubscription = _firestore
          .collection('vaccinations')
          .where('userId', isEqualTo: userId)
          .snapshots()
          .listen((snapshot) {
        try {
          _vaccinations.clear();
          for (var doc in snapshot.docs) {
            try {
              final data = doc.data();
              data['id'] = doc.id;
              data.remove('createdAt');
              data.remove('updatedAt');
              _vaccinations.add(Vaccination.fromJson(data));
            } catch (e, stackTrace) {
              debugPrint('❌ Error parsing vaccination ${doc.id}: $e');
              debugPrint('Stack trace: $stackTrace');
            }
          }
          _isLoading = false;
          _errorMessage = null;
          notifyListeners();
        } catch (e, stackTrace) {
          debugPrint('❌ Error processing vaccinations snapshot: $e');
          debugPrint('Stack trace: $stackTrace');
          _isLoading = false;
          _errorMessage = 'Failed to load vaccinations: $e';
          notifyListeners();
        }
      }, onError: (error, stackTrace) {
        debugPrint('❌ Error in vaccinations listener: $error');
        debugPrint('Stack trace: $stackTrace');
        _isLoading = false;
        _errorMessage = 'Failed to load vaccinations: $error';
        notifyListeners();
      });
    } catch (e, stackTrace) {
      debugPrint('❌ Error setting up vaccinations listener: $e');
      debugPrint('Stack trace: $stackTrace');
      _isLoading = false;
      _errorMessage = 'Failed to load vaccinations: $e';
      notifyListeners();
    }
  }

  Future<bool> addVaccination(Vaccination vaccination) async {
    return _addHealthRecord('vaccinations', vaccination.toJson(), vaccination.id);
  }

  Future<bool> updateVaccination(Vaccination vaccination) async {
    return _updateHealthRecord('vaccinations', vaccination.toJson(), vaccination.id);
  }

  Future<bool> deleteVaccination(String id) async {
    return _deleteHealthRecord('vaccinations', id);
  }

  // ========== MEDICATIONS ==========
  void _loadMedications(String userId) {
    try {
      _medicationsSubscription?.cancel();
      _medicationsSubscription = _firestore
          .collection('medications')
          .where('userId', isEqualTo: userId)
          .snapshots()
          .listen((snapshot) {
        try {
          _medications.clear();
          for (var doc in snapshot.docs) {
            try {
              final data = doc.data();
              data['id'] = doc.id;
              data.remove('createdAt');
              data.remove('updatedAt');
              _medications.add(Medication.fromJson(data));
            } catch (e, stackTrace) {
              debugPrint('❌ Error parsing medication ${doc.id}: $e');
              debugPrint('Stack trace: $stackTrace');
            }
          }
          _isLoading = false;
          _errorMessage = null;
          notifyListeners();
        } catch (e, stackTrace) {
          debugPrint('❌ Error processing medications snapshot: $e');
          debugPrint('Stack trace: $stackTrace');
          _isLoading = false;
          _errorMessage = 'Failed to load medications: $e';
          notifyListeners();
        }
      }, onError: (error, stackTrace) {
        debugPrint('❌ Error in medications listener: $error');
        debugPrint('Stack trace: $stackTrace');
        _isLoading = false;
        _errorMessage = 'Failed to load medications: $error';
        notifyListeners();
      });
    } catch (e, stackTrace) {
      debugPrint('❌ Error setting up medications listener: $e');
      debugPrint('Stack trace: $stackTrace');
      _isLoading = false;
      _errorMessage = 'Failed to load medications: $e';
      notifyListeners();
    }
  }

  Future<bool> addMedication(Medication medication) async {
    return _addHealthRecord('medications', medication.toJson(), medication.id);
  }

  Future<bool> updateMedication(Medication medication) async {
    return _updateHealthRecord('medications', medication.toJson(), medication.id);
  }

  Future<bool> deleteMedication(String id) async {
    return _deleteHealthRecord('medications', id);
  }

  // ========== VET VISITS ==========
  void _loadVetVisits(String userId) {
    try {
      _vetVisitsSubscription?.cancel();
      _vetVisitsSubscription = _firestore
          .collection('vet_visits')
          .where('userId', isEqualTo: userId)
          .snapshots()
          .listen((snapshot) {
        try {
          _vetVisits.clear();
          for (var doc in snapshot.docs) {
            try {
              final data = doc.data();
              data['id'] = doc.id;
              data.remove('createdAt');
              data.remove('updatedAt');
              _vetVisits.add(VetVisit.fromJson(data));
            } catch (e, stackTrace) {
              debugPrint('❌ Error parsing vet visit ${doc.id}: $e');
              debugPrint('Stack trace: $stackTrace');
            }
          }
          _isLoading = false;
          _errorMessage = null;
          notifyListeners();
        } catch (e, stackTrace) {
          debugPrint('❌ Error processing vet visits snapshot: $e');
          debugPrint('Stack trace: $stackTrace');
          _isLoading = false;
          _errorMessage = 'Failed to load vet visits: $e';
          notifyListeners();
        }
      }, onError: (error, stackTrace) {
        debugPrint('❌ Error in vet visits listener: $error');
        debugPrint('Stack trace: $stackTrace');
        _isLoading = false;
        _errorMessage = 'Failed to load vet visits: $error';
        notifyListeners();
      });
    } catch (e, stackTrace) {
      debugPrint('❌ Error setting up vet visits listener: $e');
      debugPrint('Stack trace: $stackTrace');
      _isLoading = false;
      _errorMessage = 'Failed to load vet visits: $e';
      notifyListeners();
    }
  }

  Future<bool> addVetVisit(VetVisit vetVisit) async {
    return _addHealthRecord('vet_visits', vetVisit.toJson(), vetVisit.id);
  }

  Future<bool> updateVetVisit(VetVisit vetVisit) async {
    return _updateHealthRecord('vet_visits', vetVisit.toJson(), vetVisit.id);
  }

  Future<bool> deleteVetVisit(String id) async {
    return _deleteHealthRecord('vet_visits', id);
  }

  // ========== SURGERIES ==========
  void _loadSurgeries(String userId) {
    try {
      _surgeriesSubscription?.cancel();
      _surgeriesSubscription = _firestore
          .collection('surgeries')
          .where('userId', isEqualTo: userId)
          .snapshots()
          .listen((snapshot) {
        try {
          _surgeries.clear();
          for (var doc in snapshot.docs) {
            try {
              final data = doc.data();
              data['id'] = doc.id;
              data.remove('createdAt');
              data.remove('updatedAt');
              _surgeries.add(Surgery.fromJson(data));
            } catch (e, stackTrace) {
              debugPrint('❌ Error parsing surgery ${doc.id}: $e');
              debugPrint('Stack trace: $stackTrace');
            }
          }
          _isLoading = false;
          _errorMessage = null;
          notifyListeners();
        } catch (e, stackTrace) {
          debugPrint('❌ Error processing surgeries snapshot: $e');
          debugPrint('Stack trace: $stackTrace');
          _isLoading = false;
          _errorMessage = 'Failed to load surgeries: $e';
          notifyListeners();
        }
      }, onError: (error, stackTrace) {
        debugPrint('❌ Error in surgeries listener: $error');
        debugPrint('Stack trace: $stackTrace');
        _isLoading = false;
        _errorMessage = 'Failed to load surgeries: $error';
        notifyListeners();
      });
    } catch (e, stackTrace) {
      debugPrint('❌ Error setting up surgeries listener: $e');
      debugPrint('Stack trace: $stackTrace');
      _isLoading = false;
      _errorMessage = 'Failed to load surgeries: $e';
      notifyListeners();
    }
  }

  Future<bool> addSurgery(Surgery surgery) async {
    return _addHealthRecord('surgeries', surgery.toJson(), surgery.id);
  }

  Future<bool> updateSurgery(Surgery surgery) async {
    return _updateHealthRecord('surgeries', surgery.toJson(), surgery.id);
  }

  Future<bool> deleteSurgery(String id) async {
    return _deleteHealthRecord('surgeries', id);
  }

  // ========== ALLERGIES ==========
  void _loadAllergies(String userId) {
    try {
      _allergiesSubscription?.cancel();
      _allergiesSubscription = _firestore
          .collection('allergies')
          .where('userId', isEqualTo: userId)
          .snapshots()
          .listen((snapshot) {
        try {
          _allergies.clear();
          for (var doc in snapshot.docs) {
            try {
              final data = doc.data();
              data['id'] = doc.id;
              data.remove('createdAt');
              data.remove('updatedAt');
              _allergies.add(Allergy.fromJson(data));
            } catch (e, stackTrace) {
              debugPrint('❌ Error parsing allergy ${doc.id}: $e');
              debugPrint('Stack trace: $stackTrace');
            }
          }
          _isLoading = false;
          _errorMessage = null;
          notifyListeners();
        } catch (e, stackTrace) {
          debugPrint('❌ Error processing allergies snapshot: $e');
          debugPrint('Stack trace: $stackTrace');
          _isLoading = false;
          _errorMessage = 'Failed to load allergies: $e';
          notifyListeners();
        }
      }, onError: (error, stackTrace) {
        debugPrint('❌ Error in allergies listener: $error');
        debugPrint('Stack trace: $stackTrace');
        _isLoading = false;
        _errorMessage = 'Failed to load allergies: $error';
        notifyListeners();
      });
    } catch (e, stackTrace) {
      debugPrint('❌ Error setting up allergies listener: $e');
      debugPrint('Stack trace: $stackTrace');
      _isLoading = false;
      _errorMessage = 'Failed to load allergies: $e';
      notifyListeners();
    }
  }

  Future<bool> addAllergy(Allergy allergy) async {
    return _addHealthRecord('allergies', allergy.toJson(), allergy.id);
  }

  Future<bool> updateAllergy(Allergy allergy) async {
    return _updateHealthRecord('allergies', allergy.toJson(), allergy.id);
  }

  Future<bool> deleteAllergy(String id) async {
    return _deleteHealthRecord('allergies', id);
  }

  // ========== GENERIC CRUD METHODS ==========
  Future<bool> _addHealthRecord(String collection, Map<String, dynamic> data, String? id) async {
    final user = _auth.currentUser;
    if (user == null) {
      _errorMessage = 'You must be logged in to add a health record.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      data['userId'] = user.uid;
      data['createdAt'] = FieldValue.serverTimestamp();
      data['updatedAt'] = FieldValue.serverTimestamp();
      data.remove('id');

      await _firestore.collection(collection).add(data);
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      debugPrint('❌ Error adding health record to $collection: $e');
      debugPrint('Stack trace: $stackTrace');
      _isLoading = false;
      _errorMessage = e.toString().contains('permission-denied')
          ? 'Permission denied. Please check Firestore security rules.'
          : 'Failed to add record: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<bool> _updateHealthRecord(String collection, Map<String, dynamic> data, String id) async {
    final user = _auth.currentUser;
    if (user == null) {
      _errorMessage = 'You must be logged in to update a health record.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      data['userId'] = user.uid;
      data['updatedAt'] = FieldValue.serverTimestamp();
      data.remove('id');

      await _firestore.collection(collection).doc(id).update(data);
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      debugPrint('❌ Error updating health record in $collection: $e');
      debugPrint('Stack trace: $stackTrace');
      _isLoading = false;
      _errorMessage = e.toString().contains('permission-denied')
          ? 'Permission denied. Please check Firestore security rules.'
          : 'Failed to update record: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<bool> _deleteHealthRecord(String collection, String id) async {
    final user = _auth.currentUser;
    if (user == null) {
      _errorMessage = 'You must be logged in to delete a health record.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      await _firestore.collection(collection).doc(id).delete();
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      debugPrint('❌ Error deleting health record from $collection: $e');
      debugPrint('Stack trace: $stackTrace');
      _isLoading = false;
      _errorMessage = e.toString().contains('permission-denied')
          ? 'Permission denied. Please check Firestore security rules.'
          : 'Failed to delete record: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // ========== HELPER METHODS ==========
  List<Vaccination> getVaccinationsByPetId(String petId) {
    return _vaccinations.where((v) => v.petId == petId).toList();
  }

  List<Medication> getMedicationsByPetId(String petId) {
    return _medications.where((m) => m.petId == petId).toList();
  }

  List<VetVisit> getVetVisitsByPetId(String petId) {
    return _vetVisits.where((v) => v.petId == petId).toList();
  }

  List<Surgery> getSurgeriesByPetId(String petId) {
    return _surgeries.where((s) => s.petId == petId).toList();
  }

  List<Allergy> getAllergiesByPetId(String petId) {
    return _allergies.where((a) => a.petId == petId).toList();
  }

  /// Calculate health score for a pet based on health records
  /// Returns a score from 0-100
  int calculateHealthScore(String petId) {
    int score = 100;
    
    // Check vaccinations - deduct for overdue
    final petVaccinations = getVaccinationsByPetId(petId);
    for (var vax in petVaccinations) {
      if (vax.isOverdue) score -= 10;
      else if (vax.isDue) score -= 5;
    }
    
    // Check medications - deduct for expired/expiring
    final petMedications = getMedicationsByPetId(petId);
    for (var med in petMedications) {
      if (med.isExpired) score -= 5;
      else if (med.isDueForRefill) score -= 2;
    }
    
    // Check allergies - deduct for severe allergies
    final petAllergies = getAllergiesByPetId(petId);
    for (var allergy in petAllergies) {
      if (allergy.severity.toLowerCase() == 'severe') score -= 10;
      else if (allergy.severity.toLowerCase() == 'moderate') score -= 5;
    }
    
    // Check recent vet visits - bonus for recent checkups
    final petVetVisits = getVetVisitsByPetId(petId);
    final recentCheckups = petVetVisits.where((visit) {
      final daysSince = DateTime.now().difference(visit.visitDate).inDays;
      return daysSince <= 365 && visit.reason.toLowerCase().contains('checkup');
    }).length;
    if (recentCheckups > 0) score += 5; // Bonus for recent checkups
    
    // Ensure score is between 0 and 100
    return score.clamp(0, 100);
  }

  /// Get all health records for a pet (for timeline view)
  List<Map<String, dynamic>> getAllHealthRecordsForPet(String petId) {
    final records = <Map<String, dynamic>>[];
    
    for (var vax in getVaccinationsByPetId(petId)) {
      records.add({
        'type': 'vaccination',
        'date': vax.dateGiven,
        'title': vax.vaccineName,
        'data': vax,
      });
    }
    
    for (var med in getMedicationsByPetId(petId)) {
      records.add({
        'type': 'medication',
        'date': med.startDate,
        'title': med.medicationName,
        'data': med,
      });
    }
    
    for (var visit in getVetVisitsByPetId(petId)) {
      records.add({
        'type': 'vet_visit',
        'date': visit.visitDate,
        'title': visit.reason,
        'data': visit,
      });
    }
    
    for (var surgery in getSurgeriesByPetId(petId)) {
      records.add({
        'type': 'surgery',
        'date': surgery.surgeryDate,
        'title': surgery.surgeryName,
        'data': surgery,
      });
    }
    
    for (var allergy in getAllergiesByPetId(petId)) {
      records.add({
        'type': 'allergy',
        'date': allergy.diagnosedDate ?? DateTime.now(),
        'title': allergy.allergen,
        'data': allergy,
      });
    }
    
    // Sort by date (most recent first)
    records.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));
    
    return records;
  }
}
