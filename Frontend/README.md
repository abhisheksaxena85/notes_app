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

Reminders fire as **local** OS notifications (`flutter_local_notifications`), even when the app is closed; the server stores reminders and answers but never pushes anything.
- `NotificationService`: plugin setup, channels, permissions. Android, iOS and macOS only; a no-op on web, Windows and Linux (the notification settings are hidden there).
- `ReminderScheduler`: keeps the scheduled notifications equal to the reminders in Drift (nearest 50, wall-clock times in the device zone).
- `ReminderActionHandler`: **Done / Not done / Snooze 10 min** from the notification. Saved locally first and synced later; with the app killed it runs in a background isolate (`notification_background.dart`).
- `DigestScheduler`: the Daily reminder and Weekly summary settings in Profile → Notifications.

### Known OEM limitations
Some Android brands (Samsung, Xiaomi, OnePlus, Huawei, Oppo/Vivo and others) stop apps in the background more aggressively than stock Android. If reminders arrive late or not at all on such a phone:
- turn off battery optimisation for Daymark (Settings → Apps → Daymark → Battery → Unrestricted / "Don't optimise");
- allow auto-start / background activity where the phone has that setting;
- on Android 12+, allow **Alarms & reminders** for Daymark (Profile → Notifications shows "On, but may be late" when it is off).

See https://dontkillmyapp.com for per-brand steps. Device test results: `work_items/REM-09-results.md`.
