# Daymark Notes App

A modern, offline-first notes and productivity application designed in Figma and powered by Flutter and a Java Spring Boot backend.

---

## 🏗 System Architecture

The application is structured into two main decoupled modules:
1. **Frontend (`/Frontend`)**:
   - **Framework**: Flutter (Dart 3.x) with Riverpod (`AsyncNotifier`) state management.
   - **Offline Persistence**: SQLite via [Drift](https://drift.simonbinder.eu/) with atomic pending-upload queues for offline writes and background synchronization.
   - **Design & Theme**: Pixel-accurate implementation matching Figma specifications (`412 x 892` baseline with `flutter_screenutil`), dual theme support (Warm Ivory Light / Night Charcoal Dark), SVG vector icons, and an animated splash sequence.
   - **Local Reminders**: Strict client-side notifications/reminders via `LocalReminderService` (SharedPreferences + scheduled alerts).
2. **Backend (`/Backend`)**:
   - **Framework**: Spring Boot 4.1.1 on Java 17 with Spring Data JPA.
   - **Database**: MySQL 8.x (`notes_application` database).
   - **Layering**: Classic enterprise pattern (`Controller` ➔ `Service` ➔ `Repository` ➔ `Model`/`DTO`).

---

## 🚀 Getting Started

### 1. Backend Setup & Run

Ensure MySQL is running on `localhost:3306` with database `notes_application`.

```bash
cd ../Backend

# Verify and execute tests
mvn test

# Start the Spring Boot application on port 8080
mvn spring-boot:run
```

The backend provides Swagger/OpenAPI documentation at `http://localhost:8080/swagger-ui.html`.

### 2. Frontend Configuration & Run

By default, the Flutter client connects to `http://localhost:8080` (or `http://10.0.2.2:8080` on Android emulator). You can override this using `--dart-define`:

```bash
cd Frontend

# Install dependencies
flutter pub get

# Generate Drift database and JSON serialization code
dart run build_runner build --delete-conflicting-outputs

# Run on macOS / Chrome / iOS Simulator
flutter run

# Run on Android Emulator (points to host machine localhost)
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080

# Run on Physical Device / Remote Server
flutter run --dart-define=API_BASE_URL=http://<YOUR_IP>:8080
```

### Generated code policy

Generated Dart files (`*.g.dart` from Drift and `json_serializable`) **are committed** to the repository, so a fresh clone builds without running codegen first. Whenever you change a Drift table or an annotated DTO, re-run `dart run build_runner build --delete-conflicting-outputs` and commit the regenerated `*.g.dart` files in the same commit as the source change.

---

## 🧪 Testing & Verification

Both frontend and backend are equipped with automated test suites:

### Backend Tests
```bash
cd Backend
mvn test
# Results: 8 tests run, 0 failures, 0 errors, 0 skipped
```

### Frontend Tests & Static Analysis
```bash
cd Frontend

# Run static analysis
flutter analyze --no-fatal-infos

# Run all test suites (unit, widget, drift database, synchronization)
flutter test
```

---

## 📑 Feature & API Documentation

Detailed specifications and implementation mapping can be found in the `docs/` folder:
- [API Mapping Matrix](docs/API_MAPPING.md): Endpoint URLs, HTTP methods, payload schemas, and query parameters.
- [Implementation Status Matrix](docs/IMPLEMENTATION_STATUS.md): Complete feature gap analysis, Figma screen matching, and test status.

---

## 🔔 Local Reminders & Notifications

As per architectural requirements, **no reminder or notification logic resides on the backend**:
- Handled entirely on the mobile client via `lib/utils/services/local_reminder_service.dart`.
- Supports configurable daily reminder times (TimePicker) and weekly summaries.
- Settings are persisted across app restarts using local preferences and do not sync to remote servers.
