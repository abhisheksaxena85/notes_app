# SEC-04 — Passwords and request bodies written to logs (also in release builds)

**Type:** Security · **Priority:** P0 · **Area:** Frontend · **Depends on:** none

## Problem
- `Frontend/lib/viewmodel/auth/login/login_viewmodel.dart:74`: `log("Login Attempt: $email, $password");` logs the plaintext password.
- `Frontend/lib/viewmodel/auth/register/register_viewmodel.dart:120` logs name, email, mobile and gender.
- `Frontend/lib/data/network/interceptors/logging_interceptor.dart` uses `debugPrint` to print **every request body and response body**, including `/auth/login`, `/auth/create-user` and `/auth/change-password` payloads with passwords. `debugPrint` is **not** stripped in release builds, so on Android anyone with `adb logcat` access sees this.
- It also prints `err.stackTrace` for every failed request, which is noisy.

## Proposed fix
1. Delete the password from the login log line, and drop or minimise the register log line.
2. `LoggingInterceptor`:
   - Only add it when `kDebugMode` (in `DioClient.create`).
   - Redact sensitive keys before printing (`password`, `oldPassword`, `newPassword`, `accessToken`, `Authorization` header).
   - Truncate large bodies (for example 1 KB).
3. Search the codebase for other `log(` / `debugPrint(` calls that include user content (note text) and limit them to debug mode.

## Acceptance criteria
- [ ] `grep -rn "password" Frontend/lib | grep -i "log\|print"` returns nothing sensitive.
- [ ] A release build prints no request or response bodies.
- [ ] A unit test for the redaction helper: input map with `password` → output shows `***`.
