import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../data/models/pet.dart';
import 'health_records.dart';
import '../../viewmodels/pet_vm.dart';
import '../../viewmodels/health_vm.dart';
import 'edit_pet.dart';

/// View: Pet Profile Screen
/// Only handles UI, delegates business logic to ViewModels
class PetProfileScreen extends StatefulWidget {
  const PetProfileScreen({Key? key}) : super(key: key);

  @override
  State<PetProfileScreen> createState() => _PetProfileScreenState();
}

class _PetProfileScreenState extends State<PetProfileScreen> {
  String? _lastCalculatedPetId;
  int? _lastCalculatedScore;
  
  @override
  void initState() {
    super.initState();
  }

  void _recalculateHealthScoreIfNeeded(Pet? currentPet, HealthVM healthVM, PetVM petVM) {
    if (currentPet == null) return;
    
    // Only recalculate if pet changed or we haven't calculated yet
    if (_lastCalculatedPetId != currentPet.id || _lastCalculatedScore == null) {
      _lastCalculatedPetId = currentPet.id;
      final newHealthScore = healthVM.calculateHealthScore(currentPet.id);
      _lastCalculatedScore = newHealthScore;
      
      // Only update if score changed from what's stored
      if (newHealthScore != currentPet.healthScore) {
        debugPrint('🔄 Updating health score for ${currentPet.name}: ${currentPet.healthScore} -> $newHealthScore');
        petVM.updatePetHealthScore(currentPet.id, newHealthScore);
      }
    } else {
      // Pet hasn't changed, but check if health records changed
      final newHealthScore = healthVM.calculateHealthScore(currentPet.id);
      if (newHealthScore != _lastCalculatedScore) {
        _lastCalculatedScore = newHealthScore;
        if (newHealthScore != currentPet.healthScore) {
          debugPrint('🔄 Health records changed, updating health score: ${currentPet.healthScore} -> $newHealthScore');
          petVM.updatePetHealthScore(currentPet.id, newHealthScore);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      final petVM = context.watch<PetVM>();
      final healthVM = context.watch<HealthVM>();
      final currentPet = petVM.selectedPet;
      
      // Recalculate health score when pet or health records change
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && currentPet != null) {
          _recalculateHealthScoreIfNeeded(currentPet, healthVM, petVM);
        }
      });

      if (currentPet == null || petVM.pets.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.pets, size: 80, color: Color(0xFF697282)),
                SizedBox(height: 20),
                Text(
                  'No Pet Selected',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Add a pet from the home screen!',
                  style: TextStyle(fontSize: 16, color: Color(0xFF697282)),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              _buildHeader(context),
              if (petVM.pets.length > 1) _buildPetSwitcher(context, petVM, currentPet),
              _buildPetCard(context, currentPet),
              _buildHealthScore(context, currentPet),
              _buildStatsSection(context, currentPet),
              _buildVitalStats(context, currentPet),
              _buildInfoSection(context, currentPet),
              _buildActionButtons(context, currentPet, petVM, healthVM),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditPetScreen(
                pet: currentPet,
              ),
            ),
          );
        },
        backgroundColor: const Color(0xFF0056B4),
        child: const Icon(Icons.edit, color: Colors.white),
        tooltip: 'Edit Pet Profile',
      ),
    );
    } catch (e, stackTrace) {
      debugPrint('❌ Error in PetProfileScreen: $e');
      debugPrint('Stack trace: $stackTrace');
      return Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Error Loading Pet Profile',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Error: $e',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.red,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      // Try to reload
                      Navigator.of(context).pop();
                    },
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: const Text(
        'Pet Profile',
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Color(0xFF333333),
        ),
      ),
    );
  }

  Widget _buildPetSwitcher(BuildContext context, PetVM petVM, Pet currentPet) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5E5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.swap_horiz, color: Color(0xFF0056B4), size: 20),
          const SizedBox(width: 12),
          const Text(
            'Switch Pet:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF697282),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Pet>(
                value: currentPet,
                isExpanded: true,
                icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF0056B4)),
                items: petVM.pets.map((pet) {
                  return DropdownMenuItem<Pet>(
                    value: pet,
                    child: Row(
                      children: [
                        Icon(
                          pet.type == 'Dog' ? Icons.pets : Icons.pets,
                          size: 18,
                          color: const Color(0xFF0056B4),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          pet.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF333333),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${pet.type})',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF697282),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (Pet? newPet) {
                  if (newPet != null) {
                    petVM.selectPet(newPet);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPetCard(BuildContext context, Pet currentPet) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF16A8E), Color(0xFFCF3F67)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF16A8E).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.pets,
              size: 50,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            currentPet.name,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              currentPet.breed,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthScore(BuildContext context, Pet currentPet) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF2F4F6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Health Score',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Excellent',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4CAF50),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: CircularProgressIndicator(
                      value: currentPet.healthScore / 100,
                      strokeWidth: 8,
                      backgroundColor: const Color(0xFFF2F4F6),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        currentPet.healthScore >= 80 ? const Color(0xFF4CAF50) : 
                        currentPet.healthScore >= 60 ? const Color(0xFFFFD148) : 
                        const Color(0xFFFF5722),
                      ),
                    ),
                  ),
                  Text(
                    '${currentPet.healthScore}',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: currentPet.healthScore >= 80 ? const Color(0xFF4CAF50) : 
                             currentPet.healthScore >= 60 ? const Color(0xFFFFD148) : 
                             const Color(0xFFFF5722),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Your pet is in excellent health',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Last checkup: 2 weeks ago',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF697282),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context, Pet currentPet) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Basic Info',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildStatCard('Age', '${currentPet.age} Year${currentPet.age != 1 ? 's' : ''}', Icons.cake, const Color(0xFF0056B4))),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('Weight', '${currentPet.weight} kg', Icons.monitor_weight, const Color(0xFFF16A8E))),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('Gender', currentPet.gender, Icons.pets, const Color(0xFF4CAF50))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF2F4F6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF697282),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVitalStats(BuildContext context, Pet currentPet) {
    return Container(
      margin: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Vital Stats',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildVitalCard(
                  'Temperature',
                  '${currentPet.temperature}°C',
                  Icons.thermostat,
                  const Color(0xFFFF5722),
                  'Normal',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildVitalCard(
                  'Heart Rate',
                  '${currentPet.heartRate} bpm',
                  Icons.favorite,
                  const Color(0xFFF16A8E),
                  'Normal',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVitalCard(String label, String value, IconData icon, Color color, String status) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF2F4F6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF697282),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context, Pet currentPet) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            'Date of Birth',
            currentPet.dateOfBirth,
            Icons.calendar_today,
            const Color(0xFF0056B4),
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            'Microchip ID',
            currentPet.microchipId,
            Icons.credit_card,
            const Color(0xFF4CAF50),
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            'Veterinarian',
            currentPet.veterinarian,
            Icons.local_hospital,
            const Color(0xFFFFD148),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF2F4F6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF697282),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, Pet currentPet, PetVM petVM, HealthVM healthVM) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          _buildActionButton(
            'Medical Records',
            Icons.medical_services,
            const Color(0xFFF16A8E),
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HealthRecordsScreen(
                    initialPetId: currentPet.id,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            'Vaccination History',
            Icons.vaccines,
            const Color(0xFF0056B4),
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HealthRecordsScreen(
                    initialPetId: currentPet.id,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            'Photo Gallery',
            Icons.photo_library,
            Color(0xFF4CAF50),
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Photo gallery coming soon!')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color, color.withOpacity(0.8)],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }
}
