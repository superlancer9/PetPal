import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/models/pet.dart';

/// ViewModel: Pet Management
/// Manages pet data and logic using Cloud Firestore
class PetVM extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  Pet? _selectedPet;
  final List<Pet> _pets = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<Pet> get pets => List.unmodifiable(_pets);
  Pet? get selectedPet => _selectedPet;
  bool get hasPets => _pets.isNotEmpty;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  StreamSubscription? _petsSubscription;
  StreamSubscription? _authSubscription;

  PetVM() {
    // Listen to auth state changes to load pets when user logs in
    _authSubscription = _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        debugPrint('👤 User logged in: ${user.uid}, loading pets...');
        _loadPets();
      } else {
        debugPrint('👤 User logged out, clearing pets...');
        _petsSubscription?.cancel();
        _pets.clear();
        _selectedPet = null;
        notifyListeners();
      }
    });
    
    // Also try to load immediately if user is already logged in
    if (_auth.currentUser != null) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _loadPets();
      });
    }
  }
  
  @override
  void dispose() {
    _petsSubscription?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }

  /// Load pets from Firestore
  void _loadPets() {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('⚠️ No user logged in, cannot load pets');
      // Try again after a delay in case user logs in
      Future.delayed(const Duration(seconds: 2), () {
        if (_auth.currentUser != null) {
          _loadPets();
        }
      });
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      // Cancel existing subscription if any
      _petsSubscription?.cancel();
      
      // Listen to real-time updates from Firestore
      debugPrint('🔍 Setting up listener for user: ${user.uid}');
      _petsSubscription = _firestore
          .collection('pets')
          .where('userId', isEqualTo: user.uid)
          .snapshots()
          .listen((snapshot) {
        try {
          debugPrint('📦 Received snapshot with ${snapshot.docs.length} pets');
          _pets.clear();
          for (var doc in snapshot.docs) {
            try {
              final data = doc.data();
              debugPrint('📄 Pet document ${doc.id}: $data');
              data['id'] = doc.id; // Use Firestore document ID
              
              // Remove Firestore-specific fields that aren't in Pet model
              data.remove('createdAt');
              data.remove('updatedAt');
              
              final pet = Pet.fromJson(data);
              _pets.add(pet);
              debugPrint('✅ Successfully parsed pet: ${pet.name} (${pet.id})');
            } catch (e, stackTrace) {
              debugPrint('❌ Error parsing pet ${doc.id}: $e');
              debugPrint('Stack trace: $stackTrace');
              debugPrint('Data: ${doc.data()}');
            }
          }
          
          debugPrint('📊 Total pets in list: ${_pets.length}');
        
        // Select first pet if none selected
        if (_selectedPet == null && _pets.isNotEmpty) {
          _selectedPet = _pets[0];
        } else if (_selectedPet != null && _pets.isNotEmpty) {
          // Update selected pet if it still exists - always update to get latest data from Firestore
          try {
            final updatedSelected = _pets.firstWhere(
              (p) => p.id == _selectedPet!.id,
            );
            // Always update to ensure we have the latest health score from Firestore
            if (updatedSelected.healthScore != _selectedPet!.healthScore) {
              debugPrint('🔄 Health score updated in listener: ${_selectedPet!.healthScore} -> ${updatedSelected.healthScore}');
            }
            _selectedPet = updatedSelected;
          } catch (e) {
            // Selected pet no longer exists, select first
            _selectedPet = _pets[0];
          }
        } else if (_pets.isEmpty) {
          _selectedPet = null;
        }
        
          _isLoading = false;
          _errorMessage = null;
          notifyListeners();
        } catch (e, stackTrace) {
          debugPrint('Error in pets listener: $e');
          debugPrint('Stack trace: $stackTrace');
          _isLoading = false;
          _errorMessage = 'Failed to load pets: $e';
          notifyListeners();
        }
      }, onError: (error, stackTrace) {
        debugPrint('Error loading pets: $error');
        debugPrint('Stack trace: $stackTrace');
        _isLoading = false;
        _errorMessage = 'Failed to load pets: $error';
        notifyListeners();
      });
    } catch (e) {
      debugPrint('Error setting up pets listener: $e');
      _isLoading = false;
      _errorMessage = 'Failed to load pets: $e';
      notifyListeners();
    }
  }

  void selectPet(Pet pet) {
    _selectedPet = pet;
    notifyListeners();
  }

  /// Add a new pet to Firestore
  Future<bool> addPet(Pet newPet) async {
    final user = _auth.currentUser;
    if (user == null) {
      _errorMessage = 'You must be logged in to add a pet.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final petData = newPet.toJson();
      petData['userId'] = user.uid; // Add user ID to pet data
      petData['createdAt'] = FieldValue.serverTimestamp();
      petData['updatedAt'] = FieldValue.serverTimestamp();

      // Add pet to Firestore
      debugPrint('📤 Adding pet to Firestore: ${petData}');
      final docRef = await _firestore.collection('pets').add(petData);
      
      debugPrint('✅ Pet added to Firestore with ID: ${docRef.id}');
      debugPrint('👤 User ID: ${user.uid}');
      
      // The listener will automatically update _pets
      // Wait a bit for the listener to update, then select the new pet
      await Future.delayed(const Duration(milliseconds: 500));
      try {
        final addedPet = _pets.firstWhere(
          (p) => p.id == docRef.id,
        );
        _selectedPet = addedPet;
      } catch (e) {
        // Pet not found yet, select first pet if available
        if (_pets.isNotEmpty) {
          _selectedPet = _pets[0];
        }
      }
      
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error adding pet: $e');
      _isLoading = false;
      
      // Provide user-friendly error messages
      if (e.toString().contains('permission-denied')) {
        _errorMessage = 'Permission denied. Please check Firestore security rules.';
      } else {
        _errorMessage = 'Failed to add pet: ${e.toString()}';
      }
      
      notifyListeners();
      return false;
    }
  }

  /// Update a pet in Firestore
  Future<bool> updatePet(Pet updatedPet) async {
    final user = _auth.currentUser;
    if (user == null) {
      _errorMessage = 'You must be logged in to update a pet.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final petData = updatedPet.toJson();
      petData['userId'] = user.uid; // Ensure userId is set
      petData['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore.collection('pets').doc(updatedPet.id).update(petData);
      
      debugPrint('✅ Pet updated in Firestore: ${updatedPet.id}');
      debugPrint('📊 Health score updated to: ${updatedPet.healthScore}');
      
      // Update selected pet if it's the one being updated
      // Note: The listener will also update this, but we update immediately for responsiveness
      if (_selectedPet?.id == updatedPet.id) {
        _selectedPet = updatedPet;
        debugPrint('🔄 Updated selected pet in memory: ${updatedPet.name} (health score: ${updatedPet.healthScore})');
      }
      
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating pet: $e');
      _isLoading = false;
      
      // Provide user-friendly error messages
      if (e.toString().contains('permission-denied')) {
        _errorMessage = 'Permission denied. Please check Firestore security rules.';
      } else {
        _errorMessage = 'Failed to update pet: ${e.toString()}';
      }
      
      notifyListeners();
      return false;
    }
  }

  /// Delete a pet from Firestore
  Future<bool> deletePet(String petId) async {
    final user = _auth.currentUser;
    if (user == null) {
      _errorMessage = 'You must be logged in to delete a pet.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      await _firestore.collection('pets').doc(petId).delete();
      
      debugPrint('✅ Pet deleted from Firestore: $petId');
      
      // Update selected pet if the deleted one was selected
      if (_selectedPet?.id == petId) {
        _selectedPet = _pets.isNotEmpty ? _pets[0] : null;
      }
      
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting pet: $e');
      _isLoading = false;
      
      // Provide user-friendly error messages
      if (e.toString().contains('permission-denied')) {
        _errorMessage = 'Permission denied. Please check Firestore security rules.';
      } else {
        _errorMessage = 'Failed to delete pet: ${e.toString()}';
      }
      
      notifyListeners();
      return false;
    }
  }

  Pet? getPetById(String id) {
    try {
      return _pets.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Update pet health score based on health records
  /// This should be called when health records are added/updated/deleted
  Future<bool> updatePetHealthScore(String petId, int newHealthScore) async {
    final pet = getPetById(petId);
    if (pet == null) return false;

    final updatedPet = pet.copyWith(healthScore: newHealthScore);
    return await updatePet(updatedPet);
  }
}

