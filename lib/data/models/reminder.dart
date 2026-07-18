class Reminder {
  final String id;
  final String petId;
  final String petName;
  final String title;
  final String description;
  final DateTime dateTime;
  final String type; // vaccination, grooming, medication, checkup, etc.
  final bool isCompleted;
  final bool isUrgent;

  Reminder({
    required this.id,
    required this.petId,
    required this.petName,
    required this.title,
    required this.description,
    required this.dateTime,
    required this.type,
    this.isCompleted = false,
    this.isUrgent = false,
  });

  Reminder copyWith({
    String? id,
    String? petId,
    String? petName,
    String? title,
    String? description,
    DateTime? dateTime,
    String? type,
    bool? isCompleted,
    bool? isUrgent,
  }) {
    return Reminder(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      petName: petName ?? this.petName,
      title: title ?? this.title,
      description: description ?? this.description,
      dateTime: dateTime ?? this.dateTime,
      type: type ?? this.type,
      isCompleted: isCompleted ?? this.isCompleted,
      isUrgent: isUrgent ?? this.isUrgent,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'petId': petId,
      'petName': petName,
      'title': title,
      'description': description,
      'dateTime': dateTime.toIso8601String(),
      'type': type,
      'isCompleted': isCompleted,
      'isUrgent': isUrgent,
    };
  }

  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['id'],
      petId: json['petId'],
      petName: json['petName'],
      title: json['title'],
      description: json['description'],
      dateTime: DateTime.parse(json['dateTime']),
      type: json['type'],
      isCompleted: json['isCompleted'] ?? false,
      isUrgent: json['isUrgent'] ?? false,
    );
  }

  String getFormattedTime() {
    final now = DateTime.now();
    final difference = dateTime.difference(now);

    if (difference.inDays == 0) {
      return 'Today, ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Tomorrow, ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return '${_getWeekday(dateTime.weekday)}, ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.month}/${dateTime.day}, ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  String _getWeekday(int weekday) {
    switch (weekday) {
      case 1: return 'Monday';
      case 2: return 'Tuesday';
      case 3: return 'Wednesday';
      case 4: return 'Thursday';
      case 5: return 'Friday';
      case 6: return 'Saturday';
      case 7: return 'Sunday';
      default: return '';
    }
  }
}

