# 🐾 PetPal – Smart Pet Care Companion

PetPal is a cross-platform mobile application developed with Flutter to help pet owners manage their pets' health, daily care, and veterinary needs in one place. The application provides health record management, medication and vaccination reminders, nearby veterinarian search, educational pet care articles, and secure user authentication through Firebase.

The project follows the MVVM (Model–View–ViewModel) architecture to maintain a clean separation between the user interface, business logic, and data layer.

---

## Features

- User authentication using Firebase Authentication
- Secure pet profile management
- Health record tracking
- Vaccination and medication management
- Feeding reminders
- Reminder scheduling and notifications
- Nearby veterinarian search using OpenStreetMap
- Educational pet care articles
- Admin panel for article management
- Responsive Material Design interface
- Unit-tested core functionality

---

## Technologies Used

### Mobile Development
- Flutter
- Dart

### Architecture
- MVVM (Model–View–ViewModel)
- Provider State Management

### Backend & Database
- Firebase Authentication
- Cloud Firestore

### Maps & Location
- OpenStreetMap
- flutter_map
- Overpass API
- OSRM Routing API
- Geolocator

### Development Tools
- Android Studio
- Visual Studio Code
- Git & GitHub

---

## Project Structure

```
lib/
├── data/
│   ├── models/
│   ├── repositories/
│   └── services/
├── ui/
│   ├── screens/
│   └── widgets/
├── viewmodels/
└── main.dart
```

---

## Installation

Clone the repository

```bash
git clone https://github.com/yourusername/PetPal.git
```

Navigate to the project

```bash
cd PetPal
```

Install dependencies

```bash
flutter pub get
```

Run the application

```bash
flutter run
```

---

## Testing

Run static analysis

```bash
flutter analyze
```

Run unit tests

```bash
flutter test
```

---

## Project Highlights

- Cross-platform Flutter application
- MVVM architecture for maintainable code
- Firebase Authentication and Cloud Firestore integration
- OpenStreetMap-based veterinarian locator with routing support
- Health record and reminder management
- Educational content management for pet owners
- Modular and scalable project structure

---

## Future Improvements

- Push notifications using Firebase Cloud Messaging
- AI-powered pet health recommendations
- Veterinary appointment booking
- Offline data synchronization
- Pet growth analytics and reporting
- Multi-language support

---

## License

This project was developed for educational purposes as part of the Mobile Development course at the British University in Egypt.