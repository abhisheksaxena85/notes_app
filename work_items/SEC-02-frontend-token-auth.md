# SEC-02 — Frontend: send and store the auth token, handle 401

**Type:** Security · **Priority:** P0 · **Area:** Frontend · **Depends on:** SEC-01

## Problem
The app identifies the user only by an integer `USER_ID` in SharedPreferences and sends it as a query parameter or in the body. `Frontend/lib/data/network/interceptors/auth_interceptor.dart` has the token code commented out, and `data/network/config/api_config.dart` is an empty class.

## Proposed fix
1. Add `flutter_secure_storage`. Save `accessToken` and `expiresAt` there (not in SharedPreferences) after login/signup. Update `LoginResponseDto` and `RegisterResponseDto` for the new fields, then run `build_runner`.
2. `AuthInterceptor.onRequest`: attach `Authorization: Bearer <token>` when a token exists.
3. `AuthInterceptor.onError`: on 401, clear the session (reuse the `SessionService.logout()` from FE-01), cancel scheduled notifications (REM-03), and send the user to `LoginScreen` via `navigatorKey`. Don't do this while offline: a missing network is not a 401.
4. Stop sending `userId` once SEC-01 makes the server derive it. Remove it from DTOs and `ApiClient` signatures only after the backend no longer needs it, and keep `userId` for the local Drift scoping.
5. **Background isolate (REM-04):** the notification action handler runs in a separate isolate. It must be able to read the token from secure storage and build its own `Dio` with the interceptor.
6. Delete `ApiConfig` or give it a purpose (base URL / flavor config).

## Acceptance criteria
- [ ] Every API call carries the bearer token. Login and register work end to end against SEC-01.
- [ ] An expired or invalid token logs the user out cleanly once, without a crash loop or repeated snackbars.
- [ ] The token is not in SharedPreferences and is never logged.
- [ ] `flutter analyze && flutter test` pass, with an interceptor test using a fake adapter.
