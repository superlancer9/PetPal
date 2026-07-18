import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/reminder.dart';
import '../../viewmodels/reminder_vm.dart';
import '../../viewmodels/pet_vm.dart';
import 'edit_reminder.dart';

/// View: Reminders Screen
/// Only handles UI, delegates business logic to ViewModels
class TasksContainer extends StatelessWidget {
  const TasksContainer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final reminderVM = context.watch<ReminderVM>();
    final petVM = context.watch<PetVM>();
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              _buildHeader(context),
              _buildQuickStats(context, reminderVM),
              _buildUpcomingReminders(context, reminderVM),
              _buildAllReminders(context, reminderVM, petVM),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const EditReminderScreen(
                reminder: null,
              ),
            ),
          );
        },
        backgroundColor: const Color(0xFFF16A8E),
        icon: const Icon(Icons.add),
        label: const Text('Add Reminder'),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Reminders',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list, color: Color(0xFF0056B4)),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context, ReminderVM reminderVM) {
    final now = DateTime.now();
    final today = reminderVM.reminders.where((r) => 
      !r.isCompleted && 
      r.dateTime.year == now.year && 
      r.dateTime.month == now.month && 
      r.dateTime.day == now.day
    ).length;
    
    final thisWeek = reminderVM.reminders.where((r) => 
      !r.isCompleted && 
      r.dateTime.difference(now).inDays < 7 &&
      r.dateTime.isAfter(now)
    ).length;
    
    final overdue = reminderVM.reminders.where((r) => 
      !r.isCompleted && r.dateTime.isBefore(now)
    ).length;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard('Today', '$today', const Color(0xFFF16A8E)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard('This Week', '$thisWeek', const Color(0xFF0056B4)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard('Overdue', '$overdue', const Color(0xFFFF5722)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String count, Color color) {
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
        children: [
          Text(
            count,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: color,
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

  Widget _buildUpcomingReminders(BuildContext context, ReminderVM reminderVM) {
    final urgentReminders = reminderVM.reminders.where((r) => r.isUrgent && !r.isCompleted).toList();
    
    return Container(
      margin: const EdgeInsets.only(top: 24, left: 20, right: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Urgent',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 16),
          if (urgentReminders.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFF2F4F6)),
              ),
              child: const Center(
                child: Text(
                  'No urgent reminders',
                  style: TextStyle(color: Color(0xFF697282)),
                ),
              ),
            )
          else
            ...urgentReminders.map((reminder) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildReminderCard(
                context,
                reminder,
                Icons.vaccines,
                const Color(0xFFFF5722),
                true,
              ),
            )).toList(),
        ],
      ),
    );
  }

  Widget _buildAllReminders(BuildContext context, ReminderVM reminderVM, PetVM petVM) {
    final allReminders = reminderVM.reminders.where((r) => !r.isUrgent && !r.isCompleted).toList();
    
    return Container(
      margin: const EdgeInsets.only(top: 24, left: 20, right: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'All Reminders',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 16),
          if (allReminders.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFF2F4F6)),
              ),
              child: const Center(
                child: Text(
                  'No reminders yet',
                  style: TextStyle(color: Color(0xFF697282)),
                ),
              ),
            )
          else
            ...allReminders.map((reminder) {
              final color = _getColorForType(reminder.type);
              final icon = _getIconForType(reminder.type);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildReminderCard(
                  context,
                  reminder,
                  icon,
                  color,
                  false,
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Color _getColorForType(String type) {
    switch (type.toLowerCase()) {
      case 'vaccination': return const Color(0xFF0056B4);
      case 'grooming': return const Color(0xFF9C27B0);
      case 'medication': return const Color(0xFF4CAF50);
      case 'checkup': return const Color(0xFFF16A8E);
      default: return const Color(0xFFFFD148);
    }
  }

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'vaccination': return Icons.vaccines;
      case 'grooming': return Icons.content_cut;
      case 'medication': return Icons.medication;
      case 'checkup': return Icons.local_hospital;
      default: return Icons.alarm;
    }
  }

  Widget _buildReminderCard(
    BuildContext context,
    Reminder reminder,
    IconData icon,
    Color color,
    bool isUrgent,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditReminderScreen(
              reminder: reminder,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isUrgent ? color.withOpacity(0.3) : const Color(0xFFF2F4F6),
          width: isUrgent ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isUrgent ? color.withOpacity(0.1) : Colors.black.withOpacity(0.05),
            blurRadius: isUrgent ? 15 : 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          reminder.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333),
                        ),
                      ),
                    ),
                    if (isUrgent)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'URGENT',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.pets, size: 14, color: color),
                    const SizedBox(width: 4),
                    Text(
                      reminder.petName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  reminder.description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF697282),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.access_time, color: color, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      reminder.getFormattedTime(),
                      style: TextStyle(
                        color: color,
                        fontSize: 13,
                        fontFamily: 'Arimo',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}
