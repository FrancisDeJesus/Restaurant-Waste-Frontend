# Restaurant Waste Frontend

Flutter client app for the Restaurant Waste Management System.

## Project Description

The Restaurant Waste Management System is a mobile and web-based platform designed
to help restaurants in Davao City manage food waste collection and segregation.
The system allows restaurant users to request waste pickup, estimate waste volume,
upload waste photos for segregation validation, and monitor analytics related to
waste generation and collection trends.

This frontend is the client application used by restaurant staff and related
users to interact with the system services provided by the backend API.

## Core Features

- Waste pickup request workflow
- Waste volume estimation and tracking
- Waste segregation validation via photo upload
- Driver pickup status tracking
- Analytics dashboard for waste monitoring
- Rewards and subscription support

## System Architecture

Restaurant Client App (Flutter)
-> REST API Services (Django REST Framework)
-> Database and business modules
-> Analytics and reporting outputs

## Overview

This app is used by restaurants and related users to manage:

- Account and authentication flows
- Employee records
- Food menu and donation drive workflows
- Trash pickup and driver map tracking
- Rewards and subscriptions
- Analytics dashboards

Backend API for this frontend lives in `../Restaurant-Waste-Backend`.

## Tech Stack

- Flutter (Dart)
- Firebase (Core/Auth + Google Sign-In)
- HTTP REST integration
- Shared Preferences for local token/session storage
- Flutter Map + OpenStreetMap

## Prerequisites

- Flutter SDK (stable)
- Dart SDK (comes with Flutter)
- Android Studio and/or VS Code with Flutter extension
- A running backend server on port `8000`

Check setup:

```bash
flutter doctor
```

## Getting Started

1. Install dependencies:

```bash
flutter pub get
```

2. Verify backend URL configuration in `lib/services/api_service.dart`:

- `_realDeviceBase` for physical devices on same Wi-Fi
- `_webBase` for Flutter web
- `_emulatorBase` for Android emulator

3. Run the app:

```bash
flutter run
```

Optional web run:

```bash
flutter run -d chrome
```

## API Base URL Notes

Current API base settings are in `lib/services/api_service.dart`:

- Android emulator: `http://10.0.2.2:8000/api/`
- Real device: `http://192.168.254.191:8000/api/`
- Web: `http://127.0.0.1:8000/api/`

If your machine IP changes, update `_realDeviceBase`.

## Firebase Notes

- Firebase config is present via `lib/firebase_options.dart` and platform files.
- Ensure Android `google-services.json` is valid for your Firebase project.
- Do not commit private Firebase service account keys for backend use.

## Useful Commands

```bash
flutter analyze
flutter test
flutter clean
flutter pub get
```

## Project Structure

```text
lib/
	main.dart
	firebase_options.dart
	models/
	screens/
	services/
assets/
android/
ios/
web/
windows/
linux/
macos/
```

## Troubleshooting

- Backend not reachable:
	- Confirm backend is running at `http://<host>:8000`.
	- For physical devices, phone and PC must be on same network.
- Login/token issues:
	- Clear app data or call logout to remove stale tokens.
- Build issues:
	- Run `flutter clean` then `flutter pub get`.

## Team Notes

- Keep API endpoint changes centralized in `lib/services/api_service.dart`.
- Prefer updating this README when setup steps or architecture change.
