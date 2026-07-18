import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/vaccination.dart';
import '../../data/models/medication.dart';
import '../../data/models/vet_visit.dart';
import '../../data/models/surgery.dart';
import '../../data/models/allergy.dart';
import '../../viewmodels/pet_vm.dart';
import '../../viewmodels/health_vm.dart';

/// View: Health Records Screen
/// Only handles UI, delegates business logic to ViewModels
class HealthRecordsScreen extends StatefulWidget {
  final String? initialPetId;

  const HealthRecordsScreen({
    Key? key,
    this.initialPetId,
  }) : super(key: key);

  @override
  State<HealthRecordsScreen> createState() => _HealthRecordsScreenState();
}

class _HealthRecordsScreenState extends State<HealthRecordsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedPetId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _selectedPetId = widget.initialPetId;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Vaccination> _getFilteredVaccinations(HealthVM healthVM) {
    if (_selectedPetId == null) return healthVM.vaccinations;
    return healthVM.vaccinations.where((v) => v.petId == _selectedPetId).toList();
  }

  /// Helper method to recalculate and update pet health score
  Future<void> _updatePetHealthScore(BuildContext context, String petId, HealthVM healthVM) async {
    final petVM = context.read<PetVM>();
    final newHealthScore = healthVM.calculateHealthScore(petId);
    await petVM.updatePetHealthScore(petId, newHealthScore);
  }

  @override
  Widget build(BuildContext context) {
    final petVM = context.watch<PetVM>();
    final healthVM = context.watch<HealthVM>();
    
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Health Records'),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.vaccines), text: 'Vaccinations'),
            Tab(icon: Icon(Icons.medication), text: 'Medications'),
            Tab(icon: Icon(Icons.local_hospital), text: 'Vet Visits'),
            Tab(icon: Icon(Icons.healing), text: 'Surgeries'),
            Tab(icon: Icon(Icons.warning), text: 'Allergies'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Pet Filter
          if (petVM.pets.isNotEmpty)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.filter_list, color: Color(0xFF697282)),
                  const SizedBox(width: 12),
                  const Text(
                    'Filter by pet:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip(context, 'All Pets', null, petVM),
                          const SizedBox(width: 8),
                          ...petVM.pets.map((pet) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _buildFilterChip(context, pet.name, pet.id, petVM),
                          )).toList(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildVaccinationsTab(petVM, healthVM),
                _buildMedicationsTab(petVM, healthVM),
                _buildVetVisitsTab(petVM, healthVM),
                _buildSurgeriesTab(petVM, healthVM),
                _buildAllergiesTab(petVM, healthVM),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: petVM.pets.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () {
                final currentIndex = _tabController.index;
                if (currentIndex == 0) {
                  _showAddVaccinationDialog(context, petVM, healthVM);
                } else if (currentIndex == 1) {
                  _showAddMedicationDialog(context, petVM, healthVM);
                } else if (currentIndex == 2) {
                  _showAddVetVisitDialog(context, petVM, healthVM);
                } else if (currentIndex == 3) {
                  _showAddSurgeryDialog(context, petVM, healthVM);
                } else if (currentIndex == 4) {
                  _showAddAllergyDialog(context, petVM, healthVM);
                }
              },
              backgroundColor: _getFABColorForTab(_tabController.index),
              icon: const Icon(Icons.add),
              label: Text(_getFABLabelForTab(_tabController.index)),
            ),
    );
  }

  Widget _buildFilterChip(BuildContext context, String label, String? petId, PetVM petVM) {
    final isSelected = _selectedPetId == petId;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedPetId = selected ? petId : null);
      },
      selectedColor: const Color(0xFF4CAF50),
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFF333333),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildVaccinationsTab(PetVM petVM, HealthVM healthVM) {
    if (petVM.pets.isEmpty) {
        return _buildEmptyState(context, 
          icon: Icons.pets,
          title: 'No Pets Yet',
          message: 'Add a pet first to track their vaccinations',
        );
      }
  
      final vaccinations = _getFilteredVaccinations(healthVM);
  
      if (vaccinations.isEmpty) {
        return _buildEmptyState(context, 
          icon: Icons.vaccines,
          title: 'No Vaccinations Recorded',
          message: _selectedPetId == null
              ? 'Add vaccination records to keep track of your pets\' health'
              : 'No vaccination records for this pet yet',
        );
      }
  
      // Group by pet if showing all pets
      if (_selectedPetId == null) {
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: petVM.pets.length,
          itemBuilder: (context, index) {
            final pet = petVM.pets[index];
            final petVaccinations = vaccinations.where((v) => v.petId == pet.id).toList();
            
            if (petVaccinations.isEmpty) return const SizedBox.shrink();
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    pet.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                ),
                ...petVaccinations.map((vaccination) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildVaccinationCard(context, vaccination, healthVM),
                )).toList(),
                const SizedBox(height: 16),
              ],
            );
          },
        );
      }
  
      // Show for selected pet
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: vaccinations.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildVaccinationCard(context, vaccinations[index], healthVM),
          );
        },
      );
    }

  Widget _buildVaccinationCard(BuildContext context, Vaccination vaccination, HealthVM healthVM) {
    Color statusColor;
    if (vaccination.isOverdue) {
      statusColor = const Color(0xFFFF5722);
    } else if (vaccination.isDue) {
      statusColor = const Color(0xFFFFD148);
    } else {
      statusColor = const Color(0xFF4CAF50);
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: statusColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () => _showVaccinationDetails(context, vaccination, healthVM),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.vaccines, color: statusColor, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vaccination.vaccineName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.pets, size: 14, color: Color(0xFF697282)),
                            const SizedBox(width: 4),
                            Text(
                              vaccination.petName,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF697282),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      vaccination.getStatus(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoRow(context,
                      Icons.calendar_today,
                      'Given',
                      _formatDate(vaccination.dateGiven),
                    ),
                  ),
                  if (vaccination.dueDate != null)
                    Expanded(
                      child: _buildInfoRow(context,
                        Icons.event,
                        'Due',
                        _formatDate(vaccination.dueDate!),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              _buildInfoRow(context,
                Icons.local_hospital,
                'Veterinarian',
                vaccination.veterinarian,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF697282)),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF697282),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, {
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: const Color(0xFF697282)),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              message,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF697282),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  void _showAddVaccinationDialog(BuildContext context, PetVM petVM, HealthVM healthVM) {
    final titleController = TextEditingController();
    final batchController = TextEditingController();
    final notesController = TextEditingController();
    final vetController = TextEditingController();
    
    String selectedPetId = petVM.pets[0].id;
    DateTime dateGiven = DateTime.now();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Vaccination'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedPetId,
                  decoration: const InputDecoration(
                    labelText: 'Pet',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.pets),
                  ),
                  items: petVM.pets.map((pet) => DropdownMenuItem(
                    value: pet.id,
                    child: Text(pet.name),
                  )).toList(),
                  onChanged: (value) => setState(() => selectedPetId = value!),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Vaccine Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.vaccines),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: vetController,
                  decoration: const InputDecoration(
                    labelText: 'Veterinarian',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.local_hospital),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: batchController,
                  decoration: const InputDecoration(
                    labelText: 'Batch Number (Optional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.tag),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Notes (Optional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.note),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
              ),
              onPressed: () async {
                if (titleController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Please enter a vaccine name')),
                  );
                  return;
                }

                try {
                  final pet = petVM.pets.firstWhere((p) => p.id == selectedPetId);
                  final vaccination = Vaccination(
                    id: '', // Will be set by Firestore
                    petId: selectedPetId,
                    petName: pet.name,
                    vaccineName: titleController.text.trim(),
                    dateGiven: dateGiven,
                    dueDate: DateTime.now().add(const Duration(days: 365)), // 1 year default
                    veterinarian: vetController.text.trim().isEmpty 
                        ? 'Not specified' 
                        : vetController.text.trim(),
                    batchNumber: batchController.text.trim().isEmpty ? null : batchController.text.trim(),
                    notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                  );
                  
                  // Close dialog first
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  }
                  
                  // Then add the vaccination
                  final success = await healthVM.addVaccination(vaccination);
                  
                  // Recalculate health score
                  if (success && context.mounted) {
                    await _updatePetHealthScore(context, selectedPetId, healthVM);
                  }
                  
                  if (context.mounted) {
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Vaccination added!'),
                          backgroundColor: Color(0xFF4CAF50),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(healthVM.errorMessage ?? 'Failed to add vaccination'),
                          backgroundColor: const Color(0xFFFF5722),
                        ),
                      );
                    }
                  }
                } catch (e) {
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  }
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: ${e.toString()}'),
                        backgroundColor: const Color(0xFFFF5722),
                      ),
                    );
                  }
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showVaccinationDetails(BuildContext context, Vaccination vaccination, HealthVM healthVM) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(vaccination.vaccineName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(context, 'Pet', vaccination.petName),
            const SizedBox(height: 8),
            _buildDetailRow(context, 'Date Given', _formatDate(vaccination.dateGiven)),
            if (vaccination.dueDate != null) ...[
              const SizedBox(height: 8),
              _buildDetailRow(context, 'Due Date', _formatDate(vaccination.dueDate!)),
            ],
            const SizedBox(height: 8),
            _buildDetailRow(context, 'Veterinarian', vaccination.veterinarian),
            if (vaccination.batchNumber != null) ...[
              const SizedBox(height: 8),
              _buildDetailRow(context, 'Batch Number', vaccination.batchNumber!),
            ],
            if (vaccination.notes != null) ...[
              const SizedBox(height: 8),
              _buildDetailRow(context, 'Notes', vaccination.notes!),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Vaccination?'),
                  content: const Text('Are you sure you want to delete this vaccination record?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF5722),
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              
              if (confirm == true && context.mounted) {
                Navigator.pop(context); // Close details dialog
                
                final success = await healthVM.deleteVaccination(vaccination.id);
                
                // Recalculate health score
                if (success && context.mounted) {
                  await _updatePetHealthScore(context, vaccination.petId, healthVM);
                }
                
                if (context.mounted) {
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Vaccination deleted'),
                        backgroundColor: Color(0xFF4CAF50),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(healthVM.errorMessage ?? 'Failed to delete vaccination'),
                        backgroundColor: const Color(0xFFFF5722),
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF697282),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Color(0xFF333333)),
          ),
        ),
      ],
    );
  }

  // Helper methods for FAB
  Color _getFABColorForTab(int index) {
    switch (index) {
      case 0: return const Color(0xFF4CAF50); // Vaccinations - Green
      case 1: return const Color(0xFF2196F3); // Medications - Blue
      case 2: return const Color(0xFF9C27B0); // Vet Visits - Purple
      case 3: return const Color(0xFFFF5722); // Surgeries - Red
      case 4: return const Color(0xFFFFD148); // Allergies - Yellow
      default: return const Color(0xFF4CAF50);
    }
  }

  String _getFABLabelForTab(int index) {
    switch (index) {
      case 0: return 'Add Vaccination';
      case 1: return 'Add Medication';
      case 2: return 'Add Vet Visit';
      case 3: return 'Add Surgery';
      case 4: return 'Add Allergy';
      default: return 'Add';
    }
  }

  // ========== MEDICATIONS TAB ==========
  Widget _buildMedicationsTab(PetVM petVM, HealthVM healthVM) {
    if (petVM.pets.isEmpty) {
      return _buildEmptyState(context, 
        icon: Icons.pets,
        title: 'No Pets Yet',
        message: 'Add a pet first to track their medications',
      );
    }

    final medications = _selectedPetId == null 
        ? healthVM.medications 
        : healthVM.medications.where((m) => m.petId == _selectedPetId).toList();

    if (medications.isEmpty) {
      return _buildEmptyState(context, 
        icon: Icons.medication,
        title: 'No Medications Recorded',
        message: _selectedPetId == null
            ? 'Add medication records to keep track of your pets\' medications'
            : 'No medication records for this pet yet',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: medications.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildMedicationCard(context, medications[index], healthVM),
        );
      },
    );
  }

  Widget _buildMedicationCard(BuildContext context, Medication medication, HealthVM healthVM) {
    Color statusColor = const Color(0xFF2196F3);
    if (medication.isExpired) {
      statusColor = const Color(0xFFFF5722);
    } else if (medication.isDueForRefill) {
      statusColor = const Color(0xFFFFD148);
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: statusColor.withOpacity(0.3), width: 2),
      ),
      child: InkWell(
        onTap: () => _showMedicationDetails(context, medication, healthVM),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.medication, color: statusColor, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          medication.medicationName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${medication.dosage} - ${medication.frequency}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF697282),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (medication.isExpired)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5722),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Expired',
                        style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              _buildInfoRow(context, Icons.pets, 'Pet', medication.petName),
              const SizedBox(height: 8),
              _buildInfoRow(context, Icons.calendar_today, 'Start Date', _formatDate(medication.startDate)),
              if (medication.endDate != null)
                _buildInfoRow(context, Icons.event, 'End Date', _formatDate(medication.endDate!)),
            ],
          ),
        ),
      ),
    );
  }

  void _showMedicationDetails(BuildContext context, Medication medication, HealthVM healthVM) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(medication.medicationName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(context, 'Pet', medication.petName),
            const SizedBox(height: 8),
            _buildDetailRow(context, 'Dosage', medication.dosage),
            const SizedBox(height: 8),
            _buildDetailRow(context, 'Frequency', medication.frequency),
            const SizedBox(height: 8),
            _buildDetailRow(context, 'Start Date', _formatDate(medication.startDate)),
            if (medication.endDate != null) ...[
              const SizedBox(height: 8),
              _buildDetailRow(context, 'End Date', _formatDate(medication.endDate!)),
            ],
            const SizedBox(height: 8),
            _buildDetailRow(context, 'Veterinarian', medication.veterinarian),
            if (medication.notes != null) ...[
              const SizedBox(height: 8),
              _buildDetailRow(context, 'Notes', medication.notes!),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Medication?'),
                  content: const Text('Are you sure you want to delete this medication record?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5722)),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              if (confirm == true && context.mounted) {
                Navigator.pop(context);
                final success = await healthVM.deleteMedication(medication.id);
                
                // Recalculate health score
                if (success && context.mounted) {
                  await _updatePetHealthScore(context, medication.petId, healthVM);
                }
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'Medication deleted' : (healthVM.errorMessage ?? 'Failed to delete')),
                      backgroundColor: success ? const Color(0xFF4CAF50) : const Color(0xFFFF5722),
                    ),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showAddMedicationDialog(BuildContext context, PetVM petVM, HealthVM healthVM) {
    final nameController = TextEditingController();
    final dosageController = TextEditingController();
    final vetController = TextEditingController();
    final notesController = TextEditingController();
    
    String selectedPetId = petVM.pets[0].id;
    String selectedFrequency = 'Once daily';
    DateTime startDate = DateTime.now();
    DateTime? endDate;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Medication'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedPetId,
                  decoration: const InputDecoration(labelText: 'Pet', border: OutlineInputBorder(), prefixIcon: Icon(Icons.pets)),
                  items: petVM.pets.map((pet) => DropdownMenuItem(value: pet.id, child: Text(pet.name))).toList(),
                  onChanged: (value) => setState(() => selectedPetId = value!),
                ),
                const SizedBox(height: 16),
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Medication Name', border: OutlineInputBorder(), prefixIcon: Icon(Icons.medication))),
                const SizedBox(height: 16),
                TextField(controller: dosageController, decoration: const InputDecoration(labelText: 'Dosage', border: OutlineInputBorder(), prefixIcon: Icon(Icons.science))),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedFrequency,
                  decoration: const InputDecoration(labelText: 'Frequency', border: OutlineInputBorder(), prefixIcon: Icon(Icons.schedule)),
                  items: ['Once daily', 'Twice daily', 'Every 8 hours', 'Every 12 hours', 'As needed'].map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                  onChanged: (value) => setState(() => selectedFrequency = value!),
                ),
                const SizedBox(height: 16),
                TextField(controller: vetController, decoration: const InputDecoration(labelText: 'Veterinarian', border: OutlineInputBorder(), prefixIcon: Icon(Icons.local_hospital))),
                const SizedBox(height: 16),
                TextField(controller: notesController, maxLines: 2, decoration: const InputDecoration(labelText: 'Notes (Optional)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.note))),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2196F3)),
              onPressed: () async {
                if (nameController.text.trim().isEmpty || dosageController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(const SnackBar(content: Text('Please fill in all required fields')));
                  return;
                }
                final pet = petVM.pets.firstWhere((p) => p.id == selectedPetId);
                final medication = Medication(
                  id: '',
                  petId: selectedPetId,
                  petName: pet.name,
                  medicationName: nameController.text.trim(),
                  dosage: dosageController.text.trim(),
                  frequency: selectedFrequency,
                  startDate: startDate,
                  endDate: endDate,
                  veterinarian: vetController.text.trim().isEmpty ? 'Not specified' : vetController.text.trim(),
                  notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                );
                if (dialogContext.mounted) Navigator.pop(dialogContext);
                final success = await healthVM.addMedication(medication);
                
                // Recalculate health score
                if (success && context.mounted) {
                  await _updatePetHealthScore(context, selectedPetId, healthVM);
                }
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'Medication added!' : (healthVM.errorMessage ?? 'Failed to add medication')),
                      backgroundColor: success ? const Color(0xFF4CAF50) : const Color(0xFFFF5722),
                    ),
                  );
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  // ========== VET VISITS TAB ==========
  Widget _buildVetVisitsTab(PetVM petVM, HealthVM healthVM) {
    if (petVM.pets.isEmpty) {
      return _buildEmptyState(context, icon: Icons.pets, title: 'No Pets Yet', message: 'Add a pet first to track vet visits');
    }
    final visits = _selectedPetId == null ? healthVM.vetVisits : healthVM.vetVisits.where((v) => v.petId == _selectedPetId).toList();
    if (visits.isEmpty) {
      return _buildEmptyState(context, icon: Icons.local_hospital, title: 'No Vet Visits Recorded', message: _selectedPetId == null ? 'Add vet visit records' : 'No vet visits for this pet yet');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: visits.length,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _buildVetVisitCard(context, visits[index], healthVM),
      ),
    );
  }

  Widget _buildVetVisitCard(BuildContext context, VetVisit visit, HealthVM healthVM) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: const Color(0xFF9C27B0).withOpacity(0.3), width: 2)),
      child: InkWell(
        onTap: () => _showVetVisitDetails(context, visit, healthVM),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFF9C27B0).withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.local_hospital, color: Color(0xFF9C27B0), size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(visit.reason, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
                        const SizedBox(height: 4),
                        Text(visit.petName, style: const TextStyle(fontSize: 13, color: Color(0xFF697282))),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              _buildInfoRow(context, Icons.calendar_today, 'Date', _formatDate(visit.visitDate)),
              const SizedBox(height: 8),
              _buildInfoRow(context, Icons.local_hospital, 'Veterinarian', visit.veterinarian),
              if (visit.cost != null) ...[
                const SizedBox(height: 8),
                _buildInfoRow(context, Icons.attach_money, 'Cost', '\$${visit.cost!.toStringAsFixed(2)}'),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showVetVisitDetails(BuildContext context, VetVisit visit, HealthVM healthVM) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(visit.reason),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(context, 'Pet', visit.petName),
            const SizedBox(height: 8),
            _buildDetailRow(context, 'Date', _formatDate(visit.visitDate)),
            const SizedBox(height: 8),
            _buildDetailRow(context, 'Veterinarian', visit.veterinarian),
            if (visit.diagnosis != null) ...[
              const SizedBox(height: 8),
              _buildDetailRow(context, 'Diagnosis', visit.diagnosis!),
            ],
            if (visit.treatment != null) ...[
              const SizedBox(height: 8),
              _buildDetailRow(context, 'Treatment', visit.treatment!),
            ],
            if (visit.cost != null) ...[
              const SizedBox(height: 8),
              _buildDetailRow(context, 'Cost', '\$${visit.cost!.toStringAsFixed(2)}'),
            ],
            if (visit.notes != null) ...[
              const SizedBox(height: 8),
              _buildDetailRow(context, 'Notes', visit.notes!),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final confirm = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
                title: const Text('Delete Vet Visit?'),
                content: const Text('Are you sure you want to delete this vet visit record?'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                  ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5722)), onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                ],
              ));
              if (confirm == true && context.mounted) {
                Navigator.pop(context);
                final success = await healthVM.deleteVetVisit(visit.id);
                
                // Recalculate health score
                if (success && context.mounted) {
                  await _updatePetHealthScore(context, visit.petId, healthVM);
                }
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(success ? 'Vet visit deleted' : (healthVM.errorMessage ?? 'Failed to delete')),
                    backgroundColor: success ? const Color(0xFF4CAF50) : const Color(0xFFFF5722),
                  ));
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showAddVetVisitDialog(BuildContext context, PetVM petVM, HealthVM healthVM) {
    final reasonController = TextEditingController();
    final diagnosisController = TextEditingController();
    final treatmentController = TextEditingController();
    final vetController = TextEditingController();
    final costController = TextEditingController();
    final notesController = TextEditingController();
    
    String selectedPetId = petVM.pets[0].id;
    DateTime visitDate = DateTime.now();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Vet Visit'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedPetId,
                  decoration: const InputDecoration(labelText: 'Pet', border: OutlineInputBorder(), prefixIcon: Icon(Icons.pets)),
                  items: petVM.pets.map((pet) => DropdownMenuItem(value: pet.id, child: Text(pet.name))).toList(),
                  onChanged: (value) => setState(() => selectedPetId = value!),
                ),
                const SizedBox(height: 16),
                TextField(controller: reasonController, decoration: const InputDecoration(labelText: 'Reason for Visit', border: OutlineInputBorder(), prefixIcon: Icon(Icons.info))),
                const SizedBox(height: 16),
                TextField(controller: vetController, decoration: const InputDecoration(labelText: 'Veterinarian', border: OutlineInputBorder(), prefixIcon: Icon(Icons.local_hospital))),
                const SizedBox(height: 16),
                TextField(controller: diagnosisController, maxLines: 2, decoration: const InputDecoration(labelText: 'Diagnosis (Optional)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.medical_services))),
                const SizedBox(height: 16),
                TextField(controller: treatmentController, maxLines: 2, decoration: const InputDecoration(labelText: 'Treatment (Optional)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.healing))),
                const SizedBox(height: 16),
                TextField(controller: costController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Cost (Optional)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.attach_money))),
                const SizedBox(height: 16),
                TextField(controller: notesController, maxLines: 2, decoration: const InputDecoration(labelText: 'Notes (Optional)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.note))),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9C27B0)),
              onPressed: () async {
                if (reasonController.text.trim().isEmpty || vetController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(const SnackBar(content: Text('Please fill in all required fields')));
                  return;
                }
                final pet = petVM.pets.firstWhere((p) => p.id == selectedPetId);
                final visit = VetVisit(
                  id: '',
                  petId: selectedPetId,
                  petName: pet.name,
                  visitDate: visitDate,
                  reason: reasonController.text.trim(),
                  diagnosis: diagnosisController.text.trim().isEmpty ? null : diagnosisController.text.trim(),
                  treatment: treatmentController.text.trim().isEmpty ? null : treatmentController.text.trim(),
                  veterinarian: vetController.text.trim(),
                  cost: costController.text.trim().isEmpty ? null : double.tryParse(costController.text.trim()),
                  notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                );
                if (dialogContext.mounted) Navigator.pop(dialogContext);
                final success = await healthVM.addVetVisit(visit);
                
                // Recalculate health score
                if (success && context.mounted) {
                  await _updatePetHealthScore(context, selectedPetId, healthVM);
                }
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(success ? 'Vet visit added!' : (healthVM.errorMessage ?? 'Failed to add vet visit')),
                    backgroundColor: success ? const Color(0xFF4CAF50) : const Color(0xFFFF5722),
                  ));
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  // ========== SURGERIES TAB ==========
  Widget _buildSurgeriesTab(PetVM petVM, HealthVM healthVM) {
    if (petVM.pets.isEmpty) {
      return _buildEmptyState(context, icon: Icons.pets, title: 'No Pets Yet', message: 'Add a pet first to track surgeries');
    }
    final surgeries = _selectedPetId == null ? healthVM.surgeries : healthVM.surgeries.where((s) => s.petId == _selectedPetId).toList();
    if (surgeries.isEmpty) {
      return _buildEmptyState(context, icon: Icons.healing, title: 'No Surgeries Recorded', message: _selectedPetId == null ? 'Add surgery records' : 'No surgeries for this pet yet');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: surgeries.length,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _buildSurgeryCard(context, surgeries[index], healthVM),
      ),
    );
  }

  Widget _buildSurgeryCard(BuildContext context, Surgery surgery, HealthVM healthVM) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: const Color(0xFFFF5722).withOpacity(0.3), width: 2)),
      child: InkWell(
        onTap: () => _showSurgeryDetails(context, surgery, healthVM),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFFFF5722).withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.healing, color: Color(0xFFFF5722), size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(surgery.surgeryName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
                        const SizedBox(height: 4),
                        Text(surgery.petName, style: const TextStyle(fontSize: 13, color: Color(0xFF697282))),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              _buildInfoRow(context, Icons.calendar_today, 'Date', _formatDate(surgery.surgeryDate)),
              const SizedBox(height: 8),
              _buildInfoRow(context, Icons.local_hospital, 'Veterinarian', surgery.veterinarian),
            ],
          ),
        ),
      ),
    );
  }

  void _showSurgeryDetails(BuildContext context, Surgery surgery, HealthVM healthVM) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(surgery.surgeryName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(context, 'Pet', surgery.petName),
            const SizedBox(height: 8),
            _buildDetailRow(context, 'Date', _formatDate(surgery.surgeryDate)),
            const SizedBox(height: 8),
            _buildDetailRow(context, 'Veterinarian', surgery.veterinarian),
            if (surgery.reason != null) ...[
              const SizedBox(height: 8),
              _buildDetailRow(context, 'Reason', surgery.reason!),
            ],
            if (surgery.cost != null) ...[
              const SizedBox(height: 8),
              _buildDetailRow(context, 'Cost', '\$${surgery.cost!.toStringAsFixed(2)}'),
            ],
            if (surgery.recoveryNotes != null) ...[
              const SizedBox(height: 8),
              _buildDetailRow(context, 'Recovery Notes', surgery.recoveryNotes!),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final confirm = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
                title: const Text('Delete Surgery?'),
                content: const Text('Are you sure you want to delete this surgery record?'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                  ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5722)), onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                ],
              ));
              if (confirm == true && context.mounted) {
                Navigator.pop(context);
                final success = await healthVM.deleteSurgery(surgery.id);
                
                // Recalculate health score
                if (success && context.mounted) {
                  await _updatePetHealthScore(context, surgery.petId, healthVM);
                }
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(success ? 'Surgery deleted' : (healthVM.errorMessage ?? 'Failed to delete')),
                    backgroundColor: success ? const Color(0xFF4CAF50) : const Color(0xFFFF5722),
                  ));
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showAddSurgeryDialog(BuildContext context, PetVM petVM, HealthVM healthVM) {
    final nameController = TextEditingController();
    final vetController = TextEditingController();
    final clinicController = TextEditingController();
    final reasonController = TextEditingController();
    final recoveryController = TextEditingController();
    final costController = TextEditingController();
    
    String selectedPetId = petVM.pets[0].id;
    DateTime surgeryDate = DateTime.now();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Surgery'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedPetId,
                  decoration: const InputDecoration(labelText: 'Pet', border: OutlineInputBorder(), prefixIcon: Icon(Icons.pets)),
                  items: petVM.pets.map((pet) => DropdownMenuItem(value: pet.id, child: Text(pet.name))).toList(),
                  onChanged: (value) => setState(() => selectedPetId = value!),
                ),
                const SizedBox(height: 16),
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Surgery Name', border: OutlineInputBorder(), prefixIcon: Icon(Icons.healing))),
                const SizedBox(height: 16),
                TextField(controller: vetController, decoration: const InputDecoration(labelText: 'Veterinarian', border: OutlineInputBorder(), prefixIcon: Icon(Icons.local_hospital))),
                const SizedBox(height: 16),
                TextField(controller: clinicController, decoration: const InputDecoration(labelText: 'Clinic (Optional)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.business))),
                const SizedBox(height: 16),
                TextField(controller: reasonController, maxLines: 2, decoration: const InputDecoration(labelText: 'Reason (Optional)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.info))),
                const SizedBox(height: 16),
                TextField(controller: costController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Cost (Optional)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.attach_money))),
                const SizedBox(height: 16),
                TextField(controller: recoveryController, maxLines: 2, decoration: const InputDecoration(labelText: 'Recovery Notes (Optional)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.note))),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5722)),
              onPressed: () async {
                if (nameController.text.trim().isEmpty || vetController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(const SnackBar(content: Text('Please fill in all required fields')));
                  return;
                }
                final pet = petVM.pets.firstWhere((p) => p.id == selectedPetId);
                final surgery = Surgery(
                  id: '',
                  petId: selectedPetId,
                  petName: pet.name,
                  surgeryName: nameController.text.trim(),
                  surgeryDate: surgeryDate,
                  veterinarian: vetController.text.trim(),
                  clinic: clinicController.text.trim().isEmpty ? null : clinicController.text.trim(),
                  reason: reasonController.text.trim().isEmpty ? null : reasonController.text.trim(),
                  cost: costController.text.trim().isEmpty ? null : double.tryParse(costController.text.trim()),
                  recoveryNotes: recoveryController.text.trim().isEmpty ? null : recoveryController.text.trim(),
                );
                if (dialogContext.mounted) Navigator.pop(dialogContext);
                final success = await healthVM.addSurgery(surgery);
                
                // Recalculate health score
                if (success && context.mounted) {
                  await _updatePetHealthScore(context, selectedPetId, healthVM);
                }
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(success ? 'Surgery added!' : (healthVM.errorMessage ?? 'Failed to add surgery')),
                    backgroundColor: success ? const Color(0xFF4CAF50) : const Color(0xFFFF5722),
                  ));
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  // ========== ALLERGIES TAB ==========
  Widget _buildAllergiesTab(PetVM petVM, HealthVM healthVM) {
    if (petVM.pets.isEmpty) {
      return _buildEmptyState(context, icon: Icons.pets, title: 'No Pets Yet', message: 'Add a pet first to track allergies');
    }
    final allergies = _selectedPetId == null ? healthVM.allergies : healthVM.allergies.where((a) => a.petId == _selectedPetId).toList();
    if (allergies.isEmpty) {
      return _buildEmptyState(context, icon: Icons.warning, title: 'No Allergies Recorded', message: _selectedPetId == null ? 'Add allergy records' : 'No allergies for this pet yet');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: allergies.length,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _buildAllergyCard(context, allergies[index], healthVM),
      ),
    );
  }

  Widget _buildAllergyCard(BuildContext context, Allergy allergy, HealthVM healthVM) {
    final statusColor = allergy.severityColor;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: statusColor.withOpacity(0.3), width: 2)),
      child: InkWell(
        onTap: () => _showAllergyDetails(context, allergy, healthVM),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                    child: Icon(Icons.warning, color: statusColor, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(allergy.allergen, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
                        const SizedBox(height: 4),
                        Text(allergy.petName, style: const TextStyle(fontSize: 13, color: Color(0xFF697282))),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(20)),
                    child: Text(allergy.severity, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              _buildInfoRow(context, Icons.local_hospital, 'Veterinarian', allergy.veterinarian),
              if (allergy.diagnosedDate != null) ...[
                const SizedBox(height: 8),
                _buildInfoRow(context, Icons.calendar_today, 'Diagnosed', _formatDate(allergy.diagnosedDate!)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showAllergyDetails(BuildContext context, Allergy allergy, HealthVM healthVM) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(allergy.allergen),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(context, 'Pet', allergy.petName),
            const SizedBox(height: 8),
            _buildDetailRow(context, 'Severity', allergy.severity),
            const SizedBox(height: 8),
            _buildDetailRow(context, 'Veterinarian', allergy.veterinarian),
            if (allergy.symptoms != null) ...[
              const SizedBox(height: 8),
              _buildDetailRow(context, 'Symptoms', allergy.symptoms!),
            ],
            if (allergy.treatment != null) ...[
              const SizedBox(height: 8),
              _buildDetailRow(context, 'Treatment', allergy.treatment!),
            ],
            if (allergy.diagnosedDate != null) ...[
              const SizedBox(height: 8),
              _buildDetailRow(context, 'Diagnosed Date', _formatDate(allergy.diagnosedDate!)),
            ],
            if (allergy.notes != null) ...[
              const SizedBox(height: 8),
              _buildDetailRow(context, 'Notes', allergy.notes!),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final confirm = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
                title: const Text('Delete Allergy?'),
                content: const Text('Are you sure you want to delete this allergy record?'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                  ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5722)), onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                ],
              ));
              if (confirm == true && context.mounted) {
                Navigator.pop(context);
                final success = await healthVM.deleteAllergy(allergy.id);
                
                // Recalculate health score
                if (success && context.mounted) {
                  await _updatePetHealthScore(context, allergy.petId, healthVM);
                }
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(success ? 'Allergy deleted' : (healthVM.errorMessage ?? 'Failed to delete')),
                    backgroundColor: success ? const Color(0xFF4CAF50) : const Color(0xFFFF5722),
                  ));
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showAddAllergyDialog(BuildContext context, PetVM petVM, HealthVM healthVM) {
    final allergenController = TextEditingController();
    final symptomsController = TextEditingController();
    final treatmentController = TextEditingController();
    final vetController = TextEditingController();
    final notesController = TextEditingController();
    
    String selectedPetId = petVM.pets[0].id;
    String selectedSeverity = 'Mild';
    DateTime? diagnosedDate;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Allergy'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedPetId,
                  decoration: const InputDecoration(labelText: 'Pet', border: OutlineInputBorder(), prefixIcon: Icon(Icons.pets)),
                  items: petVM.pets.map((pet) => DropdownMenuItem(value: pet.id, child: Text(pet.name))).toList(),
                  onChanged: (value) => setState(() => selectedPetId = value!),
                ),
                const SizedBox(height: 16),
                TextField(controller: allergenController, decoration: const InputDecoration(labelText: 'Allergen', border: OutlineInputBorder(), prefixIcon: Icon(Icons.warning))),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedSeverity,
                  decoration: const InputDecoration(labelText: 'Severity', border: OutlineInputBorder(), prefixIcon: Icon(Icons.priority_high)),
                  items: ['Mild', 'Moderate', 'Severe'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (value) => setState(() => selectedSeverity = value!),
                ),
                const SizedBox(height: 16),
                TextField(controller: vetController, decoration: const InputDecoration(labelText: 'Veterinarian', border: OutlineInputBorder(), prefixIcon: Icon(Icons.local_hospital))),
                const SizedBox(height: 16),
                TextField(controller: symptomsController, maxLines: 2, decoration: const InputDecoration(labelText: 'Symptoms (Optional)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.info))),
                const SizedBox(height: 16),
                TextField(controller: treatmentController, maxLines: 2, decoration: const InputDecoration(labelText: 'Treatment (Optional)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.healing))),
                const SizedBox(height: 16),
                TextField(controller: notesController, maxLines: 2, decoration: const InputDecoration(labelText: 'Notes (Optional)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.note))),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFD148)),
              onPressed: () async {
                if (allergenController.text.trim().isEmpty || vetController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(const SnackBar(content: Text('Please fill in all required fields')));
                  return;
                }
                final pet = petVM.pets.firstWhere((p) => p.id == selectedPetId);
                final allergy = Allergy(
                  id: '',
                  petId: selectedPetId,
                  petName: pet.name,
                  allergen: allergenController.text.trim(),
                  severity: selectedSeverity,
                  symptoms: symptomsController.text.trim().isEmpty ? null : symptomsController.text.trim(),
                  treatment: treatmentController.text.trim().isEmpty ? null : treatmentController.text.trim(),
                  diagnosedDate: diagnosedDate,
                  veterinarian: vetController.text.trim(),
                  notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                );
                if (dialogContext.mounted) Navigator.pop(dialogContext);
                final success = await healthVM.addAllergy(allergy);
                
                // Recalculate health score
                if (success && context.mounted) {
                  await _updatePetHealthScore(context, selectedPetId, healthVM);
                }
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(success ? 'Allergy added!' : (healthVM.errorMessage ?? 'Failed to add allergy')),
                    backgroundColor: success ? const Color(0xFF4CAF50) : const Color(0xFFFF5722),
                  ));
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}

