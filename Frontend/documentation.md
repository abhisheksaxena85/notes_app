# Notes App - Architecture & Feature Documentation

> **Project Root**: [`Frontend`](file:///Volumes/Crucial_X6/Documents/Projects/Full%20Stack%20Projects/Notes%20App/Frontend)  
> **Tech Stack**: Flutter (Dart `^3.13.2`), Riverpod (`AsyncNotifier`), Drift (SQLite), Dio, GetIt, ScreenUtil  
> **Design Pattern**: MVVM with Repository Pattern, Reactive Local-First Data Flow, and Offline-First Sync Queue  

---

## Table of Contents

1. [Executive Summary & High-Level Architecture](#1-executive-summary--high-level-architecture)
2. [Project Directory Layout](#2-project-directory-layout)
3. [Core Architectural Patterns & Design Principles](#3-core-architectural-patterns--design-principles)
4. [Dependency Injection & Service Locator (`GetIt`)](#4-dependency-injection--service-locator-getit)
5. [Local Persistence Layer (Drift & SQLite Engine)](#5-local-persistence-layer-drift--sqlite-engine)
6. [Network Layer & Remote API Integration (`Dio`)](#6-network-layer--remote-api-integration-dio)
7. [Offline-First Synchronization Engine](#7-offline-first-synchronization-engine)
8. [Feature-by-Feature Implementation Details](#8-feature-by-feature-implementation-details)
   - [8.1 Application Bootstrapping & Lifecycle](#81-application-bootstrapping--lifecycle)
   - [8.2 Authentication: User Registration](#82-authentication-user-registration)
   - [8.3 Authentication: User Login & Session Persistence](#83-authentication-user-login--session-persistence)
   - [8.4 Main Dashboard & Navigation Dock](#84-main-dashboard--navigation-dock)
   - [8.5 Home Screen & Notes Feed](#85-home-screen--notes-feed)
   - [8.6 Note Creation & Offline Queuing](#86-note-creation--offline-queuing)
   - [8.7 Note Details, Editing, Pinned State & Categorization](#87-note-details-editing-pinned-state--categorization)
   - [8.8 Note Deletion](#88-note-deletion)
   - [8.9 User Profile Management & Cache Hydration](#89-user-profile-management--cache-hydration)
   - [8.10 Network Connectivity Monitoring & Feedback](#810-network-connectivity-monitoring--feedback)
9. [Design System, Theming & Responsiveness](#9-design-system-theming--responsiveness)
10. [Automated Testing Suite & Data Invariants](#10-automated-testing-suite--data-invariants)
11. [Developer Onboarding & Runbook](#11-developer-onboarding--runbook)

---

## 1. Executive Summary & High-Level Architecture

The **Notes App** is a production-grade Flutter application engineered with a **local-first, offline-first** philosophy. The core requirement of this application is seamless note authoring and management regardless of network state. 

Instead of waiting for remote REST calls to complete before updating the user interface, the application uses **Drift (an SQLite abstraction for Dart)** as the primary source of truth on the client. 

### Data Flow Architecture

```
[ User Interaction ] 
        │
        ▼
[ View Layer (ConsumerWidget / Screen / Modular Widgets) ]
        │ Ref.watch() / Ref.read()
        ▼
[ ViewModel Layer (Riverpod AsyncNotifier) ]
        │ Invokes Repository
        ▼
[ Repository Layer (HomeRepo, NoteRepo, ProfileRepo, AuthRepos) ]
       ╱                                                     ╲
      ▼                                                       ▼
[ Local Drift DB (AppDatabase) ]                      [ Remote REST API (ApiClient / Dio) ]
      │                                                       ▲
      │ (Atomic Enqueue / Cached Reads)                       │ (Background Sync)
      └─────────────────► [ OfflineSyncService ] ─────────────┘
```

### Key Architectural Characteristics
- **Zero-Latency UI Updates**: Notes and profiles are rendered directly from the local SQLite database. A remote sync never blocks or hides the screen behind a full-page loading spinner when cached data exists.
- **Atomic Offline Queuing**: Newly created notes are written within an SQLite transaction to both the `CachedNotes` table and the `PendingNotes` table. They appear immediately in the UI. When connectivity is restored, the `OfflineSyncService` reconciles local notes with the server.
- **Negative Identifier Mapping**: Pending offline notes are assigned negative IDs (`-localId`) in the presentation layer to prevent key collisions with server-assigned primary keys before synchronization.
- **Reactive UI Streams**: Database queries use Drift's reactive `.watch()` queries combined with Riverpod's `AsyncNotifier`, instantly re-rendering components when local rows are modified.

---

## 2. Project Directory Layout

The codebase follows a modular clean-architecture layout under [`lib/`](file:///Volumes/Crucial_X6/Documents/Projects/Full%20Stack%20Projects/Notes%20App/Frontend/lib):

```
lib/
├── data/                                 # Data Access, Persistence, & Network
│   ├── di/
│   │   └── dependency_injection.dart     # Service locator configuration using GetIt
│   ├── local/
│   │   ├── database/
│   │   │   ├── app_database.dart         # Drift database definition, tables, & queries
│   │   │   ├── app_database.g.dart       # Drift generated code
│   │   │   └── note_database_mapper.dart # Mappers translating between DB entities & DTOs
│   │   └── shared_preference/
│   │       ├── preference.dart           # SharedPreferences wrapper
│   │       └── preference_keys.dart      # Storage key constants
│   ├── network/
│   │   ├── api/
│   │   │   ├── api_client.dart           # High-level HTTP endpoint methods
│   │   │   └── api_endpoints.dart        # URL path constants
│   │   ├── config/
│   │   │   └── api_config.dart           # Base configuration
│   │   ├── dio_client/
│   │   │   └── dio_client.dart           # Dio instance builder with timeouts & interceptors
│   │   ├── dto/                          # Strongly typed JSON Data Transfer Objects
│   │   │   ├── request/                  # Request payloads (login, register, note, profile)
│   │   │   └── response/                 # Server response schemas with json_serializable
│   │   └── interceptors/
│   │       ├── auth_interceptor.dart     # Bearer token injection (ready for auth header)
│   │       ├── logging_interceptor.dart  # Formatted console request/response logger
│   │       └── retry_interceptor.dart    # Request retry hooks
│   ├── repository/                       # Data abstraction layer
│   │   ├── auth/
│   │   │   ├── login/login_repo.dart
│   │   │   └── register/register_repo.dart
│   │   ├── home/home_repo.dart           # Note listing & local caching logic
│   │   ├── note/note_repo.dart           # Note CRUD, atomic queuing, & sync
│   │   └── profile/profile_repo.dart     # User profile retrieval & caching
│   └── sync/
│       └── offline_sync_service.dart     # Background synchronization daemon
├── main.dart                             # Application bootstrap & entry point
├── utils/                                # Cross-cutting utilities & helpers
│   ├── constants/
│   │   ├── app_colors.dart               # Complete design system color tokens
│   │   ├── app_images.dart               # Asset path definitions
│   │   └── constants.dart                # Global constants
│   ├── res/
│   │   └── snackbar.dart                 # Custom animated Snackbars (Success, Error, Waiting)
│   ├── services/
│   │   └── internet_connection_service.dart # Real-time network status stream & toasts
│   └── themes/
│       └── app_theme.dart                # Material 3 global theme definition
├── viewmodel/                            # State management layer (Riverpod)
│   ├── auth/
│   │   ├── login/
│   │   │   ├── login_state.dart
│   │   │   └── login_viewmodel.dart
│   │   └── register/
│   │       ├── register_state.dart
│   │       └── register_viewmodel.dart
│   ├── controllers.dart                  # Riverpod provider definitions
│   ├── home/
│   │   ├── home_state.dart
│   │   └── home_viewmodel.dart
│   ├── note_details/
│   │   ├── note_details_state.dart
│   │   └── note_details_viewmodel.dart
│   └── profile/
│       ├── profile_state.dart
│       └── profile_viewmodel.dart
└── views/                                # Presentation Layer
    ├── screens/
    │   ├── auth/
    │   │   ├── login/login_screen.dart
    │   │   └── register/
    │   │       ├── register_screen.dart
    │   │       └── widgets/              # Atomic inputs, selectors, and buttons
    │   ├── dashboard/
    │   │   └── dashboard_screen.dart     # Tab navigation with floating dock
    │   ├── home/
    │   │   ├── home_screen.dart          # Main notes list screen
    │   │   └── widgets/                  # Note card, header, empty/error/loading widgets
    │   ├── note_details/
    │   │   ├── note_details_screen.dart  # Create/Edit note screen
    │   │   └── widgets/                  # Title/content fields, category picker, meta widget
    │   ├── profile/
    │   │   ├── profile_screen.dart       # User profile screen
    │   │   └── widgets/                  # Avatar, info tiles, loading/error states
    │   └── splash/
    │       └── splash_screen.dart        # Splash transition screen
    └── widgets/
        └── custom_text_field.dart        # Reusable enterprise text field with borders & states
```

---

## 3. Core Architectural Patterns & Design Principles

### 3.1 Model-View-ViewModel (MVVM)
- **Views**: Consume state using `WidgetRef.watch()` and trigger actions using `WidgetRef.read()`. Views contain zero business logic and zero direct database/API calls.
- **ViewModels**: Built as Riverpod `AsyncNotifier<T>`. They manage immutable states (`copyWith`), handle input validation, and coordinate repository invocations.
- **States**: Immutable state classes representing UI state (`notesData`, `isLoading`, `error`, form errors, toggles).

### 3.2 Repository Pattern
Repositories act as the single mediator between local SQLite caching and remote REST APIs:
- Repositories expose high-level Dart objects (`GetAllNotesResponseDto`, `ProfileResponseDto`).
- They encapsulate caching strategies: reading local Drift data first, dispatching remote network calls, updating the database in transactions, and returning clean DTOs.

### 3.3 Reactive Local-First Data Flow
Rather than waiting for the API to confirm note updates, views observe the Drift database via Dart Streams (`watchNotesForUser`). When local tables mutate (whether through an enqueue, update, or remote sync replacement), the streams automatically emit new lists, and Riverpod updates the UI instantaneously.

---

## 4. Dependency Injection & Service Locator (`GetIt`)

All foundational infrastructure singletons are configured in [`lib/data/di/dependency_injection.dart`](file:///Volumes/Crucial_X6/Documents/Projects/Full%20Stack%20Projects/Notes%20App/Frontend/lib/data/di/dependency_injection.dart#L14-L48) using `get_it`:

```dart
var getIt = GetIt.instance;

Future<void> configureDependencies() async {
  // 1. HTTP Network Client
  getIt.registerLazySingleton<DioClient>(() => DioClient.create());
  getIt.registerLazySingleton<ApiClient>(() => ApiClient(dioClient: getIt<DioClient>()));

  // 2. Local Storage
  getIt.registerLazySingleton<Preference>(() => Preference());
  getIt.registerLazySingleton<AppDatabase>(() => AppDatabase());

  // 3. Repositories
  getIt.registerLazySingleton<HomeRepo>(
    () => HomeRepo(client: getIt<ApiClient>(), database: getIt<AppDatabase>()),
  );
  getIt.registerLazySingleton<NoteRepo>(
    () => NoteRepo(client: getIt<ApiClient>(), database: getIt<AppDatabase>()),
  );
  getIt.registerLazySingleton<ProfileRepo>(
    () => ProfileRepo(client: getIt<ApiClient>(), database: getIt<AppDatabase>()),
  );

  // 4. Background Synchronization Service
  getIt.registerLazySingleton<OfflineSyncService>(
    () => OfflineSyncService(
      noteRepo: getIt<NoteRepo>(),
      connectionChecker: InternetConnectionChecker.createInstance(),
    ),
  );
}
```

### Component Roles
- **`DioClient`**: Configures base timeouts, base URLs, and interceptors.
- **`ApiClient`**: Maps REST methods to typed HTTP calls.
- **`Preference`**: Provides typed access to device `SharedPreferences`.
- **`AppDatabase`**: SQLite database instance managed by Drift.
- **`OfflineSyncService`**: Listens to connectivity changes and flushes pending writes.

---

## 5. Local Persistence Layer (Drift & SQLite Engine)

The database implementation is defined in [`lib/data/local/database/app_database.dart`](file:///Volumes/Crucial_X6/Documents/Projects/Full%20Stack%20Projects/Notes%20App/Frontend/lib/data/local/database/app_database.dart).

### 5.1 Drift Tables Schema

#### 1. `CachedNotes` Table
Caches notes on-device for instantaneous offline retrieval.
- `id` (`IntColumn`): Local auto-incrementing SQLite primary key.
- `userId` (`IntColumn`): Scopes notes per authenticated user.
- `serverId` (`IntColumn`, nullable): Server-assigned ID from the backend.
- `title` (`TextColumn`): Note headline.
- `content` (`TextColumn`): Note body content.
- `category` (`TextColumn`, nullable): Note classification (e.g. Work, Personal, Tasks).
- `createdAt` (`TextColumn`, nullable): ISO timestamp string.
- `updatedAt` (`TextColumn`, nullable): ISO timestamp string.
- `pinned` (`BoolColumn`): Flag for pinned notes (default: `false`).
- `isPending` (`BoolColumn`): Flag indicating the note is queued for remote creation (default: `false`).
- **Unique Constraint**: `{userId, serverId}` ensures duplicate server notes are updated rather than duplicated.

#### 2. `PendingNotes` Table
Persistent FIFO queue for notes written offline.
- `id` (`IntColumn`): Auto-incrementing queue ID.
- `userId` (`IntColumn`): Scopes queued notes per user.
- `localNoteId` (`IntColumn`): Foreign pointer referencing `CachedNotes.id`.
- `payload` (`TextColumn`): Raw JSON string of the `CreateNoteRequestDto`.
- `queuedAt` (`DateTimeColumn`): Timestamp when the note was queued.
- **Unique Constraint**: `{localNoteId}` ensures a single queue entry per local note.

#### 3. `CachedProfiles` Table
Stores user profile information locally.
- `userId` (`IntColumn`): Primary Key.
- `profileId` (`IntColumn`, nullable): Remote profile ID.
- `name` (`TextColumn`, nullable): User's full name.
- `email` (`TextColumn`, nullable): User's email.
- `mobile` (`TextColumn`, nullable): User's phone number.
- `gender` (`TextColumn`, nullable): User's gender.

### 5.2 Key Database Operations

- **Reactive Queries (`watchNotesForUser`)**:
  ```dart
  Stream<List<CachedNote>> watchNotesForUser(int userId) {
    return (select(cachedNotes)
          ..where((note) => note.userId.equals(userId))
          ..orderBy([
            (note) => OrderingTerm(expression: note.pinned, mode: OrderingMode.desc),
            (note) => OrderingTerm(expression: note.updatedAt, mode: OrderingMode.desc),
            (note) => OrderingTerm(expression: note.createdAt, mode: OrderingMode.desc),
          ]))
        .watch();
  }
  ```
- **Atomic Note Enqueueing (`enqueueNote`)**:
  Executed within a transaction. Inserts the note into `CachedNotes` with `isPending: true`, then writes the serialized payload to `PendingNotes`.
- **Atomic Queue Completion (`completePendingNote`)**:
  Executed upon successful server response. Updates `CachedNotes` by assigning the returned `serverId`, sets `isPending = false`, and deletes the row from `PendingNotes`.
- **Atomic Remote Synchronization (`replaceServerNotes`)**:
  Deletes only non-pending (`isPending == false`) rows for the current user, leaving local pending notes intact, and inserts fresh notes from the server on conflict update.

### 5.3 Database Mapper (`NoteDatabaseMapper`)
Located in [`lib/data/local/database/note_database_mapper.dart`](file:///Volumes/Crucial_X6/Documents/Projects/Full%20Stack%20Projects/Notes%20App/Frontend/lib/data/local/database/note_database_mapper.dart):
- Maps `CachedNote` entities to presentation `NoteItem` and `NoteDetailsData` DTOs.
- **Negative ID convention**: If `note.serverId` is null (i.e. note is pending upload), it assigns `noteId: -note.id`. This provides an unambiguous identifier that works across UI routing without colliding with positive server IDs.

---

## 6. Network Layer & Remote API Integration (`Dio`)

### 6.1 HTTP Client Configuration
Configured in [`lib/data/network/dio_client/dio_client.dart`](file:///Volumes/Crucial_X6/Documents/Projects/Full%20Stack%20Projects/Notes%20App/Frontend/lib/data/network/dio_client/dio_client.dart):
- **Base URL**: `https://notesapp-production-d43adec7.up.railway.app`
- **Timeouts**: Connect timeout: 10s, Send timeout: 10s, Receive timeout: 10s.
- **Interceptors Chain**:
  1. [`AuthInterceptor`](file:///Volumes/Crucial_X6/Documents/Projects/Full%20Stack%20Projects/Notes%20App/Frontend/lib/data/network/interceptors/auth_interceptor.dart): Injects Authorization headers.
  2. [`LoggingInterceptor`](file:///Volumes/Crucial_X6/Documents/Projects/Full%20Stack%20Projects/Notes%20App/Frontend/lib/data/network/interceptors/logging_interceptor.dart): Formats outgoing requests (`⇨`), incoming responses (`⇦`), and network errors (`✖`) in the debug console.
  3. [`RetryInterceptor`](file:///Volumes/Crucial_X6/Documents/Projects/Full%20Stack%20Projects/Notes%20App/Frontend/lib/data/network/interceptors/retry_interceptor.dart): Error interception for network retries.

### 6.2 REST Endpoints Reference
Defined in [`lib/data/network/api/api_endpoints.dart`](file:///Volumes/Crucial_X6/Documents/Projects/Full%20Stack%20Projects/Notes%20App/Frontend/lib/data/network/api/api_endpoints.dart) and implemented in [`lib/data/network/api/api_client.dart`](file:///Volumes/Crucial_X6/Documents/Projects/Full%20Stack%20Projects/Notes%20App/Frontend/lib/data/network/api/api_client.dart):

| Endpoint Route | HTTP Method | Request Payload / Params | Response DTO | Purpose |
| :--- | :--- | :--- | :--- | :--- |
| `/auth/login` | `POST` | `LoginRequestDto` (`email`, `password`) | `LoginResponseDto` | Authenticate user & retrieve `userId` |
| `/auth/create-user` | `POST` | `RegisterRequestDto` (`name`, `email`, `mobile`, `gender`, `password`) | `RegisterResponseDto` | Create a new user account |
| `/notes/get-all-notes` | `GET` | Query param: `id` (User ID) | `GetAllNotesResponseDto` | Fetch all server notes for a user |
| `/auth/user-details-by-userid` | `GET` | Query param: `id` (User ID) | `ProfileResponseDto` | Fetch user profile data |
| `/notes/create-note` | `POST` | `CreateNoteRequestDto` (`userId`, `title`, `content`, `category`, `pinned`) | `CreateNoteResponseDto` | Create a note on the remote server |
| `/notes/update-note` | `PUT` | `UpdateNoteRequestDto` (`noteId`, `title`, `content`, `category`, `pinned`) | `UpdateNoteResponseDto` | Update existing note attributes |
| `/notes/get-details-by-noteId` | `GET` | Query param: `id` (Note ID) | `NoteDetailsResponseDto` | Fetch details of a specific note |
| `/notes/delete-note` | `DELETE` | Request body: `int` (Note ID) | `DeleteNoteResponseDto` | Delete a note permanently |

---

## 7. Offline-First Synchronization Engine

The sync logic is governed by [`lib/data/sync/offline_sync_service.dart`](file:///Volumes/Crucial_X6/Documents/Projects/Full%20Stack%20Projects/Notes%20App/Frontend/lib/data/sync/offline_sync_service.dart).

```mermaid
sequenceDiagram
    autonumber
    participant UI as NoteDetails Screen
    participant DB as AppDatabase (Drift)
    participant Sync as OfflineSyncService
    participant Net as InternetConnectionChecker
    participant API as Remote REST API

    Note over UI, DB: Offline Note Creation
    UI->>DB: enqueueNote(userId, title, content, payload)
    DB->>DB: INSERT into CachedNotes (isPending = true)
    DB->>DB: INSERT into PendingNotes (queue payload)
    UI-->>UI: Instantly displays note in Home feed (-localId)
    UI->>Sync: syncPendingNotes()
    
    alt Device is Offline
        Sync->>API: Attempt sync
        API-->>Sync: Connection error
        Note over Sync: Queue preserved in DB; Sync stops gracefully
    else Device is Online / Reconnected
        Net-->>Sync: onStatusChange (Connected)
        Sync->>DB: getPendingNotes(userId)
        DB-->>Sync: [PendingNote 1, PendingNote 2...]
        loop For each pending note
            Sync->>API: POST /notes/create-note (payload)
            API-->>Sync: 200 OK (data: { noteId: 101 })
            Sync->>DB: completePendingNote(queueId, localNoteId, serverId: 101)
            DB->>DB: UPDATE CachedNotes (serverId = 101, isPending = false)
            DB->>DB: DELETE FROM PendingNotes WHERE id = queueId
        end
    end
```

### Race-Condition Protection
The sync service features a re-entrant lock pattern:
- `_isSyncing`: Guards against duplicate simultaneous runs.
- `_syncAgain`: If a new note is queued while an active sync loop is already executing, `_syncAgain` is flagged `true`, causing the `do ... while (_syncAgain)` loop to evaluate another cycle before releasing the lock.

---

## 8. Feature-by-Feature Implementation Details

### 8.1 Application Bootstrapping & Lifecycle
- **Files**: [`lib/main.dart`](file:///Volumes/Crucial_X6/Documents/Projects/Full%20Stack%20Projects/Notes%20App/Frontend/lib/main.dart), [`lib/data/di/dependency_injection.dart`](file:///Volumes/Crucial_X6/Documents/Projects/Full%20Stack%20Projects/Notes%20App/Frontend/lib/data/di/dependency_injection.dart)
- **Lifecycle Flow**:
  1. `WidgetsFlutterBinding.ensureInitialized()` guarantees engine communication.
  2. `configureDependencies()` initializes GetIt singletons.
  3. `Preference.init()` bootstraps shared preferences.
  4. Reads cached `USER_ID`. If non-zero (logged in), initializes `OfflineSyncService.start(USER_ID)` and immediately dispatches a non-blocking background `ProfileRepo.refreshProfile(USER_ID)`.
  5. Wraps the app in `ProviderScope` (Riverpod) and `ScreenUtilInit` (responsive design size `412 x 892`).
  6. Configures global gestures to dismiss keyboards on tap (`FocusScope.of(context).unfocus()`).
  7. Directs to `DashboardScreen` if `USER_ID != 0`, otherwise `LoginScreen`.

---

### 8.2 Authentication: User Registration
- **Files**:
  - Screen: [`lib/views/screens/auth/register/register_screen.dart`](file:///Volumes/Crucial_X6/Documents/Projects/Full%20Stack%20Projects/Notes%20App/Frontend/lib/views/screens/auth/register/register_screen.dart)
  - ViewModel: [`lib/viewmodel/auth/register/register_viewmodel.dart`](file:///Volumes/Crucial_X6/Documents/Projects/Full%20Stack%20Projects/Notes%20App/Frontend/lib/viewmodel/auth/register/register_viewmodel.dart)
  - State: [`lib/viewmodel/auth/register/register_state.dart`](file:///Volumes/Crucial_X6/Documents/Projects/Full%20Stack%20Projects/Notes%20App/Frontend/lib/viewmodel/auth/register/register_state.dart)
  - Repository: [`lib/data/repository/auth/register/register_repo.dart`](file:///Volumes/Crucial_X6/Documents/Projects/Full%20Stack%20Projects/Notes%20App/Frontend/lib/data/repository/auth/register/register_repo.dart)
  - Modular Widgets: [`register_name_field.dart`](file:///Volumes/Crucial_X6/Documents/Projects/Full%20Stack%20Projects/Notes%20App/Frontend/lib/views/screens/auth/register/widgets/register_name_field.dart), [`register_email_field.dart`](file:///Volumes/Crucial_X6/Documents/Projects/Full%20Stack%20Projects/Notes%20App/Frontend/lib/views/screens/auth/register/widgets/register_email_field.dart), [`register_mobile_field.dart`](file:///Volumes/Crucial_X6/Documents/Projects/Full%20Stack%20Projects/Notes%20App/Frontend/lib/views/screens/auth/register/widgets/register_mobile_field.dart), [`register_password_field.dart`](file:///Volumes/Crucial_X6/Documents/Projects/Full%20Stack%20Projects/Notes%20App/Frontend/lib/views/screens/auth/register/widgets/register_password_field.dart), [`register_gender_selector.dart`](file:///Volumes/Crucial_X6/Documents/Projects/Full%20Stack%20Projects/Notes%20App/Frontend/lib/views/screens/auth/register/widgets/register_gender_selector.dart), [`register_button.dart`](file:///Volumes/Crucial_X6/Documents/Projects/Full%20Stack%20Projects/Notes%20App/Frontend/lib/views/screens/auth/register/widgets/register_button.dart), [`register_login_link.dart`](file:///Volumes/Crucial_X6/Documents/Projects/Full%20Stack%20Projects/Notes%20App/Frontend/lib/views/screens/auth/register/widgets/register_login_link.dart).
- **Implementation**:
  - Validates fields reactively on input:
    - **Name**: Cannot be empty.
    - **Email**: Must match `r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'`.
    - **Mobile**: Must match exact 10 digits (`r'^[0-9]{10}$'`).
    - **Password**: Cannot be empty.
    - **Gender**: Custom radio button selector supporting `male`, `female`, and `other`.
  - When user submits via `registerButton`:
    - ViewModel sets state to `AsyncLoading()`.
    - `RegisterRepo.register()` posts `RegisterRequestDto` to `/auth/create-user`.
    - On success: displays `successSnackBar("User created successfully!")` and navigates back (`Navigator.pop(context)`).
    - On error: displays `failedSnackBar(response.message)` and transitions state to `AsyncData(state)` or `AsyncError`.

---

### 8.3 Authentication: User Login & Session Persistence
- **Files**:
  - Screen: [`lib/views/screens/auth/login/login_screen.dart`](file:///Volumes/Crucial_X6/Documents/Projects/Full%20Stack%20Projects/Notes%20App/Frontend/lib/views/screens/auth/login/login_screen.dart)
  - ViewModel: [`lib/viewmodel/auth/login/login_viewmodel.dart`](file:///Volumes/Crucial_X6/Documents/Projects/Full%20Stack%20Projects/Notes%20App/Frontend/lib/viewmodel/auth/login/login_viewmodel.dart)
  - State: [`lib/viewmodel/auth/login/login_state.dart`](file:///Volumes/Crucial_X6/Documents/Projects/Full%20Stack%20Projects/Notes%20App/Frontend/lib/viewmodel/auth/login/login_state.dart)
  - Repository: [`lib/data/repository/auth/login/login_repo.dart`](file:///Volumes/Crucial_X6/Documents/Projects/Full%20Stack%20Projects/Notes%20App/Frontend/lib/data/repository/auth/login/login_repo.dart)
- **Implementation**:
  - Handles email validation regex and password empty checks.
  - Submits `LoginRequestDto` to `/auth/login`.
  - On authentication success:
    - Extracts `userId` from `LoginResponseDto.data`.
    - Persists `userId` in `SharedPreferences` via `Preference.setInt(PreferenceKeys.USER_ID, userId)`.
    - Configures active user in `OfflineSyncService.setUserId(userId)`.
    - Asynchronously kicks off `ProfileRepo.refreshProfile(userId)` in the background.
    - Pushes [`DashboardScreen`](file:///Volumes/Crucial_X6/Documents/Projects/Full%20Stack%20Projects/Notes%20App/Frontend/lib/views/screens/dashboard/dashboard_screen.dart).

---

### 8.4 Main Dashboard & Navigation Dock
- **Files**: [`lib/views/screens/dashboard/dashboard_screen.dart`](file:///Volumes/Crucial_X6/Documents/Projects/Full%20Stack%20Projects/Notes%20App/Frontend/lib/views/screens/dashboard/dashboard_screen.dart)
- **Implementation**:
  - Houses a `TabBarView` containing [`HomeScreen`](file:///Volumes/Crucial_X6/Documents/Projects/Full%20Stack%20Projects/Notes%20App/Frontend/lib/views/screens/home/home_screen.dart) and [`ProfileScreen`](file:///Volumes/Crucial_X6/Documents/Projects/Full%20Stack%20Projects/Notes%20App/Frontend/lib/views/screens/profile/profile_screen.dart).
  - Controlled by a `TabController` with vsync (`SingleTickerProviderStateMixin`).
  - Implements a custom floating pill dock anchored at `FloatingActionButtonLocation.centerDocked`.
  - Uses `ListenableBuilder` tied to the `TabController` for tab indicator styling and icon state changes (`Icons.dashboard_rounded` vs `Icons.dashboard_outlined`).

---

### 8.5 Home Screen & Notes Feed
- **Files**:
  - Screen: [`lib/views/screens/home/home_screen.dart`](file:///Volumes/Crucial_X6/Documents/Projects/Full%20Stack%20Projects/Notes%20App/Frontend/lib/views/screens/home/home_screen.dart)
  - ViewModel: [`lib/viewmodel/home/home_viewmodel.dart`](file:///Volumes/Crucial_X6/Documents/Projects/Full%20Stack%20Projects/Notes%20App/Frontend/lib/viewmodel/home/home_viewmodel.dart)
  - State: [`lib/viewmodel/home/home_state.dart`](file:///Volumes/Crucial_X6/Documents/Projects/Full%20Stack%20Projects/Notes%20App/Frontend/lib/viewmodel/home/home_state.dart)
  - Repository: [`lib/data/repository/home/home_repo.dart`](file:///Volumes/Crucial_X6/Documents/Projects/Full%20Stack%20Projects/Notes%20App/Frontend/lib/data/repository/home/home_repo.dart)
  - Widgets: [`note_item_card.dart`](file:///Volumes/Crucial_X6/Documents/Projects/Full%20Stack%20Projects/Notes%20App/Frontend/lib/views/screens/home/widgets/note_item_card.dart), [`notes_list_view.dart`](file:///Volumes/Crucial_X6/Documents/Projects/Full%20Stack%20Projects/Notes%20App/Frontend/lib/views/screens/home/widgets/notes_list_view.dart), [`notes_header_widget.dart`](file:///Volumes/Crucial_X6/Documents/Projects/Full%20Stack%20Projects/Notes%20App/Frontend/lib/views/screens/home/widgets/notes_header_widget.dart), [`notes_empty_widget.dart`](file:///Volumes/Crucial_X6/Documents/Projects/Full%20Stack%20Projects/Notes%20App/Frontend/lib/views/screens/home/widgets/notes_empty_widget.dart), [`notes_error_widget.dart`](file:///Volumes/Crucial_X6/Documents/Projects/Full%20Stack%20Projects/Notes%20App/Frontend/lib/views/screens/home/widgets/notes_error_widget.dart), [`notes_loading_widget.dart`](file:///Volumes/Crucial_X6/Documents/Projects/Full%20Stack%20Projects/Notes%20App/Frontend/lib/views/screens/home/widgets/notes_loading_widget.dart), [`notes_floating_action_button.dart`](file:///Volumes/Crucial_X6/Documents/Projects/Full%20Stack%20Projects/Notes%20App/Frontend/lib/views/screens/home/widgets/notes_floating_action_button.dart).
- **Implementation**:
  - **Local-First Initial Load**: In `HomeViewmodel.build()`, it fetches cached notes synchronously from Drift using `_homeRepo.getCachedNotes(userId)` and returns `HomeState(notesData: cachedNotes)`.
  - **Reactive Database Subscription**: Immediately listens to `_homeRepo.watchNotes(userId)` stream. When notes change in the DB, Riverpod emits a new `AsyncData(HomeState)`.
  - **Silent Background Network Refresh**: Triggers `_refreshNotes(userId)` in the background without clearing current notes or showing a blocking spinner.
  - **Sorting Order**: Notes are sorted with pinned items at the top (`pinned == true`), followed by descending update/creation time or note ID.
  - **Empty & Error Handling**:
    - If notes list is empty: renders `notesEmptyWidget` with an illustration and pull-to-refresh.
    - If fetch fails: renders `notesErrorWidget` with a retry button.
  - **Note Card Presentation**:
    - Displays category tag pill.
    - Displays pin icon with warning color if pinned.
    - Single-line title and max 3 lines of content preview.
    - Formatted timestamp with calendar icon.

---

### 8.6 Note Creation & Offline Queuing
- **Files**:
  - Screen: [`lib/views/screens/note_details/note_details_screen.dart`](file:///Volumes/Crucial_X6/Documents/Projects/Full%20Stack%20Projects/Notes%20App/Frontend/lib/views/screens/note_details/note_details_screen.dart)
  - ViewModel: [`lib/viewmodel/note_details/note_details_viewmodel.dart`](file:///Volumes/Crucial_X6/Documents/Projects/Full%20Stack%20Projects/Notes%20App/Frontend/lib/viewmodel/note_details/note_details_viewmodel.dart)
  - Repository: [`lib/data/repository/note/note_repo.dart`](file:///Volumes/Crucial_X6/Documents/Projects/Full%20Stack%20Projects/Notes%20App/Frontend/lib/data/repository/note/note_repo.dart)
- **Implementation**:
  - When opened with `noteId == null`, enters **Create Mode**.
  - User can enter a title, body, select a category, and toggle the pinned status.
  - On save (`saveOrUpdateNote`):
    - Validates that title is not empty.
    - Sets `isSaving = true`.
    - Calls `NoteRepo.enqueueNote()`, which executes an SQLite transaction writing to both `CachedNotes` (`isPending: true`) and `PendingNotes`.
    - Triggers `OfflineSyncService.syncPendingNotes()` in the background.
    - Shows snackbar: `"Note saved. Syncing in the background."`.
    - Closes screen (`Navigator.pop(context, true)`).
    - The note is immediately visible on the `HomeScreen` feed with a negative ID mapping.

---

### 8.7 Note Details, Editing, Pinned State & Categorization
- **Files**:
  - Screen: [`lib/views/screens/note_details/note_details_screen.dart`](file:///Volumes/Crucial_X6/Documents/Projects/Full%20Stack%20Projects/Notes%20App/Frontend/lib/views/screens/note_details/note_details_screen.dart)
  - Form Builder: [`build_note_form_widget.dart`](file:///Volumes/Crucial_X6/Documents/Projects/Full%20Stack%20Projects/Notes%20App/Frontend/lib/views/screens/note_details/widgets/build_note_form_widget.dart)
  - Widgets: [`note_category_selector.dart`](file:///Volumes/Crucial_X6/Documents/Projects/Full%20Stack%20Projects/Notes%20App/Frontend/lib/views/screens/note_details/widgets/note_category_selector.dart), [`note_title_field.dart`](file:///Volumes/Crucial_X6/Documents/Projects/Full%20Stack%20Projects/Notes%20App/Frontend/lib/views/screens/note_details/widgets/note_title_field.dart), [`note_content_field.dart`](file:///Volumes/Crucial_X6/Documents/Projects/Full%20Stack%20Projects/Notes%20App/Frontend/lib/views/screens/note_details/widgets/note_content_field.dart), [`note_meta_info_widget.dart`](file:///Volumes/Crucial_X6/Documents/Projects/Full%20Stack%20Projects/Notes%20App/Frontend/lib/views/screens/note_details/widgets/note_meta_info_widget.dart), [`note_action_button.dart`](file:///Volumes/Crucial_X6/Documents/Projects/Full%20Stack%20Projects/Notes%20App/Frontend/lib/views/screens/note_details/widgets/note_action_button.dart), [`note_details_app_bar.dart`](file:///Volumes/Crucial_X6/Documents/Projects/Full%20Stack%20Projects/Notes%20App/Frontend/lib/views/screens/note_details/widgets/note_details_app_bar.dart).
- **Implementation**:
  - When opened with a valid `noteId`, enters **Edit Mode**.
  - `loadNote(noteId)` reads note details from local Drift database first. If not found and ID is positive, it queries `/notes/get-details-by-noteId` and caches the result locally.
  - Category selector provides predefined categories: `["General", "Personal", "Work", "Study", "Ideas", "Tasks"]`.
  - Pinned toggle allows immediate pinning/unpinning reflected in the app bar icon.
  - In Edit Mode, `noteMetaInfoWidget` renders formatted `Created` and `Updated` timestamps.
  - Submitting changes sends `UpdateNoteRequestDto` to `/notes/update-note` and updates the local row in `CachedNotes`.

---

### 8.8 Note Deletion
- **Files**:
  - Screen: [`lib/views/screens/note_details/note_details_screen.dart`](file:///Volumes/Crucial_X6/Documents/Projects/Full%20Stack%20Projects/Notes%20App/Frontend/lib/views/screens/note_details/note_details_screen.dart#L31-L92)
  - ViewModel: [`lib/viewmodel/note_details/note_details_viewmodel.dart`](file:///Volumes/Crucial_X6/Documents/Projects/Full%20Stack%20Projects/Notes%20App/Frontend/lib/viewmodel/note_details/note_details_viewmodel.dart#L184-L218)
  - Repository: [`lib/data/repository/note/note_repo.dart`](file:///Volumes/Crucial_X6/Documents/Projects/Full%20Stack%20Projects/Notes%20App/Frontend/lib/data/repository/note/note_repo.dart#L129-L135)
- **Implementation**:
  - In Edit Mode, the app bar features a delete icon button.
  - Tapping it triggers `_showDeleteConfirmationDialog()` requiring user confirmation.
  - On confirmation, `NoteDetailsViewmodel.deleteNote()` sends `DELETE /notes/delete-note` with the target `noteId`.
  - On successful deletion, displays a success snackbar and pops back to the notes list.

---

### 8.9 User Profile Management & Cache Hydration
- **Files**:
  - Screen: [`lib/views/screens/profile/profile_screen.dart`](file:///Volumes/Crucial_X6/Documents/Projects/Full%20Stack%20Projects/Notes%20App/Frontend/lib/views/screens/profile/profile_screen.dart)
  - ViewModel: [`lib/viewmodel/profile/profile_viewmodel.dart`](file:///Volumes/Crucial_X6/Documents/Projects/Full%20Stack%20Projects/Notes%20App/Frontend/lib/viewmodel/profile/profile_viewmodel.dart)
  - State: [`lib/viewmodel/profile/profile_state.dart`](file:///Volumes/Crucial_X6/Documents/Projects/Full%20Stack%20Projects/Notes%20App/Frontend/lib/viewmodel/profile/profile_state.dart)
  - Repository: [`lib/data/repository/profile/profile_repo.dart`](file:///Volumes/Crucial_X6/Documents/Projects/Full%20Stack%20Projects/Notes%20App/Frontend/lib/data/repository/profile/profile_repo.dart)
  - Widgets: [`build_profile_widget.dart`](file:///Volumes/Crucial_X6/Documents/Projects/Full%20Stack%20Projects/Notes%20App/Frontend/lib/views/screens/profile/widgets/build_profile_widget.dart), [`profile_avatar_widget.dart`](file:///Volumes/Crucial_X6/Documents/Projects/Full%20Stack%20Projects/Notes%20App/Frontend/lib/views/screens/profile/widgets/profile_avatar_widget.dart), [`profile_info_tile.dart`](file:///Volumes/Crucial_X6/Documents/Projects/Full%20Stack%20Projects/Notes%20App/Frontend/lib/views/screens/profile/widgets/profile_info_tile.dart), [`profile_loading_widget.dart`](file:///Volumes/Crucial_X6/Documents/Projects/Full%20Stack%20Projects/Notes%20App/Frontend/lib/views/screens/profile/widgets/profile_loading_widget.dart), [`profile_error_widget.dart`](file:///Volumes/Crucial_X6/Documents/Projects/Full%20Stack%20Projects/Notes%20App/Frontend/lib/views/screens/profile/widgets/profile_error_widget.dart).
- **Implementation**:
  - Profile is cached locally in `CachedProfiles`.
  - On app launch, `ProfileRepo.refreshProfile(USER_ID)` hydrates local SQLite profile data.
  - `ProfileViewmodel.build()` reads cached profile first, then streams updates from `watchProfile(userId)`.
  - `profileAvatarWidget` dynamically computes initials (e.g. "John Doe" -> "JD") and renders gender-specific icons (`Icons.male_rounded`, `Icons.female_rounded`, or `Icons.person_rounded`).
  - Displays user Email, Mobile number, and User ID in clean cards with pull-to-refresh support.

---

### 8.10 Network Connectivity Monitoring & Feedback
- **Files**: [`lib/utils/services/internet_connection_service.dart`](file:///Volumes/Crucial_X6/Documents/Projects/Full%20Stack%20Projects/Notes%20App/Frontend/lib/utils/services/internet_connection_service.dart), [`lib/utils/res/snackbar.dart`](file:///Volumes/Crucial_X6/Documents/Projects/Full%20Stack%20Projects/Notes%20App/Frontend/lib/utils/res/snackbar.dart)
- **Implementation**:
  - Root widget listener invokes `internetStatusListener(context)`.
  - Monitors `InternetConnectionChecker.createInstance().onStatusChange`.
  - Includes debouncing timers to avoid spamming toasts during intermittent flakiness.
  - Displays green `successSnackBar("Internet connected")` or red `failedSnackBar("Internet disconnected")`.

---

## 9. Design System, Theming & Responsiveness

### 9.1 Responsive Design via `ScreenUtil`
- Base design size: `412` width by `892` height.
- Scalable extensions applied across the entire UI:
  - `.w`: Proportional width.
  - `.h`: Proportional height.
  - `.r`: Proportional border radius and padding.
  - `.sp`: Scalable font sizes.

### 9.2 Color System ([`AppColors`](file:///Volumes/Crucial_X6/Documents/Projects/Full%20Stack%20Projects/Notes%20App/Frontend/lib/utils/constants/app_colors.dart))
- **Brand Palette**: Brand Color `Color.fromRGBO(74, 94, 139, 1)`, Background `Color.fromRGBO(235, 235, 244, 1)`.
- **Primary Blues**: `priBlue00` (`#E6EDF5`) to `priBlue40` (`#033666`).
- **Neutrals**: Full scale from `neutral100` (`#000000`) down to `neutral05` (`#FBFBFB`).
- **State Colors**: Error (`#8C1D18`, `#FFCECE`), Success (`#0A5B2F`, `#E0F3E9`), Warning/Pinned (`#EAA300`, `#FFF7E4`).

### 9.3 Typography
Powered by `google_fonts`:
- **Headlines & Actions**: `GoogleFonts.googleSans()` for titles, buttons, tabs, and category badges.
- **Body & Captions**: `GoogleFonts.sourceSans3()` for input fields, note descriptions, and dates.

### 9.4 Reusable Input Component ([`customTextInputField`](file:///Volumes/Crucial_X6/Documents/Projects/Full%20Stack%20Projects/Notes%20App/Frontend/lib/views/widgets/custom_text_field.dart))
Encapsulates text field styling with:
- Configurable height, maxLength, input formatters, and keyboard types.
- Dedicated focused, enabled, and error borders.
- Suffix error indicators and automatic error label layout.

---

## 10. Automated Testing Suite & Data Invariants

The test suite in [`test/`](file:///Volumes/Crucial_X6/Documents/Projects/Full%20Stack%20Projects/Notes%20App/Frontend/test) validates the critical invariants of the offline-first architecture:

### 10.1 In-Memory Database Tests ([`test/local_database_test.dart`](file:///Volumes/Crucial_X6/Documents/Projects/Full%20Stack%20Projects/Notes%20App/Frontend/test/local_database_test.dart))
- **Invariant Tested**: Remote notes refresh must never wipe out queued offline notes.
- **Verification**:
  - Enqueues an offline note for `userId: 42`.
  - Simulates remote sync with `replaceServerNotes(42, ...)`.
  - Confirms the local pending note remains intact with its negative ID.
  - Simulates sync completion via `completePendingNote()`, confirming the queue is emptied and the note transitions to its server ID.
  - Confirms per-user isolation of `CachedProfiles`.

### 10.2 Note Synchronization Tests ([`test/note_sync_test.dart`](file:///Volumes/Crucial_X6/Documents/Projects/Full%20Stack%20Projects/Notes%20App/Frontend/test/note_sync_test.dart))
- **Invariant Tested**: A failed HTTP response during sync leaves the queued note in `PendingNotes`, while a successful response removes it and updates `CachedNotes.isPending = false`.
- **Verification**: Uses a mock `FakeApiClient`. Verifies that thrown exceptions keep the pending queue length at `1`, and subsequent success drops the queue length to `0`.

---

## 11. Developer Onboarding & Runbook

### Prerequisites
- Flutter SDK `^3.13.2`
- Dart SDK `^3.13.2`
- SQLite native libraries (standard on macOS, iOS, Android, and Linux)

### Setup & Code Generation
Run the following commands in the `Frontend` directory:

```bash
# 1. Install dependencies
flutter pub get

# 2. Run build_runner to generate Drift database code & json_serializable DTOs
dart run build_runner build --delete-conflicting-outputs

# 3. Static analysis & linting
flutter analyze

# 4. Execute unit & integration tests
flutter test test/local_database_test.dart
flutter test test/note_sync_test.dart
```

### Running the App
```bash
# Debug mode on connected device or simulator
flutter run
```

---
*Documentation maintained for Notes App (Frontend).*
