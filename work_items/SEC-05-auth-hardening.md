# SEC-05 — Auth hardening: account enumeration, email uniqueness, input validation

**Type:** Security / bug · **Priority:** P1 · **Area:** Backend (+ small frontend) · **Depends on:** none

## Problems
1. **Account enumeration.** `AuthService.login` returns `"User does not exists!"` for an unknown email and `"Password does not match!"` for a wrong password (`auth/service/AuthService.java:51,55`). That tells an attacker which emails are registered.
2. **Duplicate accounts.** `UserModel.email` is a `TEXT` column with no unique constraint (`auth/model/UserModel.java:25-26`). The check-then-insert in `createNewUser` is racy, and `findByEmail` is case-sensitive, so `A@x.com` and `a@x.com` become two accounts. If duplicates exist, `findByEmail` returning `Optional` will throw `IncorrectResultSizeDataAccessException`.
3. **No input validation.** DTOs have no `@Valid` / `@NotBlank` / `@Email` / `@Size`. A null password reaches `BCrypt.encode(null)`. There's no minimum password length on the server, and `changePassword` accepts an empty `newPassword`.
4. **No brute-force protection** on `/auth/login`.
5. The client trims passwords (`login_viewmodel.dart:73` `passwordController.text.trim()`). If registration and login disagree about trimming, users with leading or trailing spaces get locked out. Pick one rule. Recommended: don't trim passwords anywhere.

## Proposed fix
- Login failures return one generic message (`"Invalid email or password"`) with HTTP 401 (see BE-03).
- Normalise email (`trim().toLowerCase(Locale.ROOT)`) on signup, login and lookup. Change the column to `VARCHAR(320)` with a unique index. Migration: lowercase existing emails, report duplicates before adding the constraint, and catch `DataIntegrityViolationException` → 409.
- Add `spring-boot-starter-validation` and annotate the request DTOs. Return 400 with field errors (handled in `GlobalExceptionHandler`, see BE-03). Require passwords of at least 8 characters.
- Simple rate limit for login: an in-memory Bucket4j or a per-IP and per-email counter (for example 10 attempts per 15 minutes).
- Frontend: stop trimming passwords, and match the client-side min length to the server.

## Acceptance criteria
- [ ] Unknown email and wrong password return the same status and message.
- [ ] Signing up twice with different email casing is rejected (409).
- [ ] Invalid payloads return 400 with field errors and never reach the service.
- [ ] Tests cover all of the above.
