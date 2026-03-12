# Restaurant Waste Management System

Frontend client application for the Restaurant Waste Management System thesis project.

## 1. Project Title

Restaurant Waste Management System

## 2. System Description

The Restaurant Waste Management System is a mobile and web-enabled platform that helps restaurants manage daily waste operations. It supports pickup scheduling, segregation tracking, analytics, and data-driven waste reduction practices. This repository contains the Flutter frontend used by restaurant users, connected to a Django REST backend.

## 3. Features

- Waste pickup request scheduling
- Waste type classification: Kitchen Waste, Customer Waste, and Food Waste
- Waste weight recording for each pickup request
- Photo proof upload for waste segregation verification
- Waste analytics dashboard for monitoring trends and performance
- Recommended pickup schedule based on historical waste data
- Segregation efficiency scoring system (Efficiency Score)
- Waste reduction recommendations
- Pickup status tracking and request history
- Rewards and subscription support

## 4. Technologies Used

- Flutter (Dart)
- Django REST Framework (backend API integration)
- SQLite (development database)
- Firebase (authentication and app services)
- HTTP/REST API communication
- Shared Preferences (local session/token storage)

## 5. System Modules

- Authentication and user profile management
- Dashboard and KPI overview
- Trash pickup management
- Waste analytics and reporting
- Segregation guide and verification support
- Donation drive management
- Food menu management
- Employee management
- Rewards and subscriptions

## 6. How to Run the Project

### Prerequisites

- Flutter SDK (stable)
- Dart SDK (included with Flutter)
- Android Studio or VS Code with Flutter extension
- Running backend server (default: port 8000)

### Steps

1. Clone the frontend and backend repositories.
2. Start the backend server.
3. In this frontend project, install dependencies:

```bash
flutter pub get
```

4. Confirm API base URL configuration in `lib/services/api_service.dart`.
5. Run the app:

```bash
flutter run
```

Optional (web):

```bash
flutter run -d chrome
```

## 7. Developers / Authors

- Harlyn Nichole T. Qiu
- Francis Lawrence A. De Jesus

Bachelor of Science in Information Systems  
Ateneo de Davao University

---

For backend services, refer to the companion repository: `../Restaurant-Waste-Backend`.
