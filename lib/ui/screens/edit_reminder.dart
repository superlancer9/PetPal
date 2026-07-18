import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/reminder.dart';
import '../../viewmodels/reminder_vm.dart';
import '../../viewmodels/pet_vm.dart';

class EditReminderScreen extends StatefulWidget {
  final Reminder? reminder; // null for new reminder

  const EditReminderScreen({
    Key? key,
    this.reminder,
  }) : super(key: key);

  @override
  State<EditReminderScreen> createState() => _EditReminderScreenState();
}

class _EditReminderScreenState extends State<EditReminderScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  
  late String _selectedPetId;
  late String _selectedType;
  late DateTime _selectedDateTime;
  late TimeOfDay _selectedTime;
  bool _isUrgent = false;
  
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final List<Map<String, dynamic>> _reminderTypes = [
    {'value': 'vaccination', 'label': 'Vaccination', 'icon': Icons.vaccines},
    {'value': 'grooming', 'label': 'Grooming', 'icon': Icons.content_cut},
    {'value': 'medication', 'label': 'Medication', 'icon': Icons.medication},
    {'value': 'checkup', 'label': 'Vet Checkup', 'icon': Icons.local_hospital},
    {'value': 'training', 'label': 'Training', 'icon': Icons.school},
    {'value': 'other', 'label': 'Other', 'icon': Icons.event},
  ];

  @override
  void initState() {
    super.initState();
    final petVM = context.read<PetVM>();
    
    if (widget.reminder != null) {
      // Editing existing reminder
      _titleController = TextEditingController(text: widget.reminder!.title);
      _descriptionController = TextEditingController(text: widget.reminder!.description);
      _selectedPetId = widget.reminder!.petId;
      _selectedType = widget.reminder!.type;
      _selectedDateTime = widget.reminder!.dateTime;
      _selectedTime = TimeOfDay.fromDateTime(widget.reminder!.dateTime);
      _isUrgent = widget.reminder!.isUrgent;
    } else {
      // New reminder
      _titleController = TextEditingController();
      _descriptionController = TextEditingController();
      _selectedPetId = petVM.pets.isNotEmpty ? petVM.pets[0].id : '';
      _selectedType = 'vaccination';
      _selectedDateTime = DateTime.now().add(const Duration(days: 1));
      _selectedTime = TimeOfDay(hour: 10, minute: 0);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveReminder() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final reminderVM = context.read<ReminderVM>();
      final petVM = context.read<PetVM>();
      
      final selectedPet = petVM.pets.firstWhere((pet) => pet.id == _selectedPetId);
      
      // Combine date and time
      final dateTime = DateTime(
        _selectedDateTime.year,
        _selectedDateTime.month,
        _selectedDateTime.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final reminder = Reminder(
        id: widget.reminder?.id ?? '', // Will be set by Firestore for new reminders
        petId: _selectedPetId,
        petName: selectedPet.name,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        dateTime: dateTime,
        type: _selectedType,
        isUrgent: _isUrgent,
        isCompleted: widget.reminder?.isCompleted ?? false,
      );

      final success = widget.reminder == null
          ? await reminderVM.addReminder(reminder)
          : await reminderVM.updateReminder(reminder);
      
      setState(() => _isLoading = false);
      
      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.reminder == null 
                ? 'Reminder created!' 
                : 'Reminder updated!'),
              backgroundColor: const Color(0xFF4CAF50),
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(reminderVM.errorMessage ?? 'Failed to save reminder'),
              backgroundColor: const Color(0xFFFF5722),
            ),
          );
        }
      }
    }
  }

  Future<void> _confirmDelete() async {
    if (widget.reminder == null) return;
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Reminder?'),
        content: const Text('Are you sure you want to delete this reminder?'),
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
      setState(() => _isLoading = true);
      
      final reminderVM = context.read<ReminderVM>();
      final success = await reminderVM.deleteReminder(widget.reminder!.id);
      
      setState(() => _isLoading = false);
      
      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reminder deleted'),
              backgroundColor: Color(0xFF4CAF50),
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(reminderVM.errorMessage ?? 'Failed to delete reminder'),
              backgroundColor: const Color(0xFFFF5722),
            ),
          );
        }
      }
    }
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (date != null) {
      setState(() => _selectedDateTime = date);
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (time != null) {
      setState(() => _selectedTime = time);
    }
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isNewReminder = widget.reminder == null;
    final petVM = context.watch<PetVM>();
    
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: Text(isNewReminder ? 'New Reminder' : 'Edit Reminder'),
        backgroundColor: const Color(0xFF0056B4),
        foregroundColor: Colors.white,
        actions: [
          if (!isNewReminder)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _confirmDelete,
              tooltip: 'Delete Reminder',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Pet Selection
              if (petVM.pets.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFF5722)),
                  ),
                  child: const Text(
                    'Please add a pet first before creating reminders.',
                    style: TextStyle(color: Color(0xFFFF5722)),
                    textAlign: TextAlign.center,
                  ),
                )
              else ...[
                const Text(
                  'Pet',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E5E5)),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _selectedPetId,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.pets, color: Color(0xFF0056B4)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    items: petVM.pets.map((pet) {
                      return DropdownMenuItem(
                        value: pet.id,
                        child: Text('${pet.name} (${pet.type})'),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _selectedPetId = value!),
                  ),
                ),
                const SizedBox(height: 24),

                // Reminder Type
                const Text(
                  'Reminder Type',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _reminderTypes.map((type) {
                    final isSelected = _selectedType == type['value'];
                    return ChoiceChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            type['icon'] as IconData,
                            size: 18,
                            color: isSelected ? Colors.white : const Color(0xFF0056B4),
                          ),
                          const SizedBox(width: 6),
                          Text(type['label'] as String),
                        ],
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedType = type['value'] as String);
                        }
                      },
                      selectedColor: const Color(0xFF0056B4),
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : const Color(0xFF333333),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      side: BorderSide(
                        color: isSelected ? const Color(0xFF0056B4) : const Color(0xFFE5E5E5),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Title
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    prefixIcon: const Icon(Icons.title, color: Color(0xFF0056B4)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF0056B4), width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    prefixIcon: const Icon(Icons.description, color: Color(0xFF0056B4)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF0056B4), width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 24),

                // Date and Time
                const Text(
                  'Date & Time',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: InkWell(
                        onTap: _selectDate,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE5E5E5)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, color: Color(0xFF0056B4)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _formatDate(_selectedDateTime),
                                  style: const TextStyle(fontSize: 15),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: _selectTime,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE5E5E5)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.access_time, color: Color(0xFF0056B4)),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  _selectedTime.format(context),
                                  style: const TextStyle(fontSize: 15),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Urgent Toggle
                Container(
                  decoration: BoxDecoration(
                    color: _isUrgent ? const Color(0xFFFFEBEE) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isUrgent ? const Color(0xFFFF5722) : const Color(0xFFE5E5E5),
                    ),
                  ),
                  child: SwitchListTile(
                    title: const Text(
                      'Mark as Urgent',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text('High priority reminder'),
                    value: _isUrgent,
                    onChanged: (value) => setState(() => _isUrgent = value),
                    activeColor: const Color(0xFFFF5722),
                    secondary: Icon(
                      _isUrgent ? Icons.priority_high : Icons.notifications_outlined,
                      color: _isUrgent ? const Color(0xFFFF5722) : const Color(0xFF697282),
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Save Button
                ElevatedButton(
                  onPressed: (_isLoading || petVM.pets.isEmpty) ? null : _saveReminder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 3,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          isNewReminder ? 'Create Reminder' : 'Save Changes',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

