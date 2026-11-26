# FE-05 — A new connectivity listener is created on every app rebuild

**Type:** Bug (leak, battery, duplicate snackbars) · **Priority:** P1 · **Area:** Frontend · **Depends on:** none

## Problem
`Frontend/lib/main.dart:62` calls `internetStatusListener(context)` **inside `MaterialApp.builder`**. That builder runs on every rebuild of the app root: theme mode changes, locale and `MediaQuery` changes (keyboard open/close, rotation, text scale), and so on.

Each call (`utils/services/internet_connection_service.dart:10-36`):
- creates a **new** `InternetConnectionChecker.createInstance()`, which polls the network periodically;
- adds a new `onStatusChange` listener that is **never cancelled**.

After a few minutes of normal use there are dozens of pollers. Each connectivity change shows the "Internet connected" / "Internet disconnected" snackbar many times. `OfflineSyncService` creates yet another checker (`data/di/dependency_injection.dart:55`).

The global `isInternetConnected` flag (`main.dart:18`) is written by all of them and has an odd 10-second delay before switching to "connected".

## Proposed fix
1. Create one `ConnectivityService` in get_it: one `InternetConnectionChecker`, a broadcast `Stream<bool> online`, a `bool isOnline` getter, started once in `initialize()`.
2. `OfflineSyncService` uses that stream instead of its own checker.
3. Show the snackbar from a single place: a small `ConsumerStatefulWidget` wrapper (or a listener set up once in `MyApp`'s `initState`) that subscribes once, cancels in `dispose`, and uses `navigatorKey.currentContext` / a `scaffoldMessengerKey` on `MaterialApp`. Debounce to about 2 s both ways, and only show "back online" after an "offline" was shown.
4. Remove the `isInternetConnected` global, or turn it into a getter on the service.
5. Optional: consider `connectivity_plus` together with the reachability check.

## Acceptance criteria
- [ ] Toggling theme or rotating 20 times leaves exactly one checker subscription (test by injecting a fake checker and counting `listen` calls).
- [ ] Airplane mode on then off shows one "offline" and one "back online" snackbar.
- [ ] Sync still starts when connectivity returns.
