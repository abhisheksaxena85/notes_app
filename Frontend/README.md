# Daymark Notes App

A modern, offline-first notes and productivity application designed in Figma and powered by Flutter and a Java Spring Boot backend.

---

## 🏗 System Architecture

The application is structured into two main decoupled modules:
1. **Frontend (`/Frontend`)**:
   - **Framework**: Flutter (Dart 3.x) with Riverpod (`AsyncNotifier`) state management.
   - **Offline Persistence**: SQLite via [Drift](https://drift.simonbinder.eu/) with atomic pending-upload queues for offline writes and background synchronization.
   - **Design & Theme**: Pixel-accurate implementation matching Figma specifications (`412 x 892` baseline with `flutter_screenutil`), dual theme support (Warm Ivory Light / Night Charcoal Dark), SVG vector icons, and an animated splash sequence.
   - **Auth**: JWT access token from login/signup, kept in the platform keystore and sent as `Authorization: Bearer` on every request.
   - **Reminders**: local OS notifications (`flutter_local_notifications`), see below.
2. **Backend (`/Backend`)**:
   - **Framework**: Spring Boot 4.1.1 on Java 17 with Spring Data JPA.
   - **Database**: MySQL 8.x, schema changes through Flyway.
   - **Layering**: Classic enterprise pattern (`Controller` ➔ `Service` ➔ `Repository` ➔ `Model`/`DTO`).

---

## 🚀 Getting Started

### 1. Backend Setup & Run

Tests run on an in-memory H2 database. Running the app locally needs MySQL on `localhost:3306` and the `dev` profile; set `DB_PASSWORD` (and optionally `DB_USER`, `JWT_SECRET`) in the environment or in `Backend/.env` (gitignored). See `Backend/src/main/resources/application-dev.properties`.

```bash
cd ../Backend

# Run the tests
./mvnw test

# Start the API on port 8080 with the dev profile
./mvnw spring-boot:run -Dspring-boot.run.profiles=dev
```

The backend provides Swagger/OpenAPI documentation at `http://localhost:8080/swagger-ui.html`.

### 2. Frontend Configuration & Run

By default the app talks to the production backend (`ApiConfig` in `lib/data/network/config/api_config.dart`). Point it at a local backend with `--dart-define=API_BASE_URL=...`:

```bash
cd Frontend

# Install dependencies
flutter pub get

# Generate Drift database and JSON serialization code
dart run build_runner build --delete-conflicting-outputs

# Run against production
flutter run

# Run on macOS / iOS Simulator against a local backend
flutter run --dart-define=API_BASE_URL=http://localhost:8080

# Run on Android Emulator (points to host machine localhost)
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080

# Run on Physical Device / Remote Server
flutter run --dart-define=API_BASE_URL=http://<YOUR_IP>:8080
```

### Generated code policy

Generated Dart files (`*.g.dart` from Drift and `json_serializable`) **are committed** to the repository, so a fresh clone builds without running codegen first. Whenever you change a Drift table or an annotated DTO, re-run `dart run build_runner build --delete-conflicting-outputs` and commit the regenerated `*.g.dart` files in the same commit as the source change.

### Release signing (Android)

Release builds are signed with the upload key described in `android/key.properties`. That file and the keystore are gitignored and must never be committed.

1. Create an upload keystore once (keep it and its passwords safe; losing it means you can't update the app on Play):
   ```bash
   keytool -genkey -v -keystore ~/daymark-upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
2. Copy `android/key.properties.example` to `android/key.properties` and fill in `storeFile` (absolute, or relative to `android/app`), `storePassword`, `keyAlias` and `keyPassword`.
3. `flutter build appbundle --release`

Without `android/key.properties`, release builds fall back to the debug key (Gradle prints a warning), so `flutter run --release` works locally, but those builds can't be uploaded to Play. If the file exists but a value is missing, the build stops and names it.

---

## 🧪 Testing & Verification

Both frontend and backend are equipped with automated test suites:

### Backend Tests
```bash
cd Backend
./mvnw test
```

### Frontend Tests & Static Analysis
```bash
cd Frontend

# Run static analysis
flutter analyze

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

## 🧩 Home-screen widgets

Two widgets, on Android (Jetpack Glance) and iOS (WidgetKit). Both follow light/dark mode and read a snapshot the app keeps up to date; changes made on a widget are saved like any other change (local first, then synced).

| Widget | Android | iOS | What it does |
|---|---|---|---|
| **Daymark Tasks** | 2x2 to 4x4 (default 4x2) | Medium, Large | Today's pending tasks (overdue and due today, then undated). Tick the circle to complete a task; **+** adds one; a row opens the task; "+N more" opens the Workspace. |
| **Next reminder** | 2x2, 4x1 | Small, Medium, lock screen (rectangular, inline) | The next reminder with a countdown, rolling over by itself when it passes. **Done** (wide sizes) completes it; repeating ones move to the next occurrence. |

**Adding them:** Android: long-press the home screen → Widgets → Daymark. iOS: long-press the home screen → Edit → Add Widget → Daymark; for the lock screen, long-press the lock screen → Customize → Lock Screen → add "Next reminder".

**Quick add:** the Tasks widget's **+** opens a small pop-up over the home screen on Android, and the quick-add sheet in the app on iOS.

**Siri and Shortcuts (iOS 16+):** say "Add task in Daymark" (or "New Daymark task"), or use the **Add task in Daymark** action in Shortcuts or on the Action button. It runs without opening the app: the task shows on the widget at once and is saved into Daymark the next time the app runs (right away if it is already running in the background).

**Platform limits:** widgets can't take typing, so adding a task always opens the pop-up or the app; on iOS 15 and 16, widget buttons open the app (which then completes the task or reminder) instead of acting in place; Android widgets use the system font. iOS widgets need the App Group `group.com.devquorix.daymark` on both the Runner and DaymarkWidgets targets: see `ios/DaymarkWidgets/README.md` for the one-time Xcode setup. Code: `lib/utils/services/home_widgets/`, `android/app/src/main/kotlin/com/devquorix/daymark/widgets/`, `ios/DaymarkWidgets/`. Device checklist: `work_items/WIDGETS-QA.md`.

### Known OEM limitations
Some Android brands (Samsung, Xiaomi, OnePlus, Huawei, Oppo/Vivo and others) stop apps in the background more aggressively than stock Android. If reminders arrive late or not at all on such a phone:
- turn off battery optimisation for Daymark (Settings → Apps → Daymark → Battery → Unrestricted / "Don't optimise");
- allow auto-start / background activity where the phone has that setting;
- on Android 12+, allow **Alarms & reminders** for Daymark (Profile → Notifications shows "On, but may be late" when it is off).

See https://dontkillmyapp.com for per-brand steps. Device test results: `work_items/REM-09-results.md`.
