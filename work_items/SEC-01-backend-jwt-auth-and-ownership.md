# SEC-01 — Backend: real authentication (JWT) and per-user ownership checks

**Type:** Security bug · **Priority:** P0 · **Area:** Backend · **Depends on:** none · **Pairs with:** SEC-02 (ship together)

## Problem
The backend has no authentication. Every data route is public, and the caller picks the user by passing a `userId` or a record id.

Evidence:
- `Backend/src/main/java/com/example/notes_app/common/AppSecurity.java:21-26`: `/auth/**`, `/notes/**`, `/tasks/**`, `/reminders/**` are all `permitAll()`. The code comment says so.
- `AuthService.login` (`auth/service/AuthService.java:45-65`) returns only `userId`. No token is issued.
- `config/JwtConfig.java` is an empty class. `spring-boot-starter-oauth2-resource-server` and `spring-security-oauth2-jose` are in `pom.xml` (lines ~78-84) but never used.
- Services never check ownership. For example `NotesService.getNoteDetails(noteId)`, `updateNote`, `deleteNote`, `togglePin`, `TaskService.updateTask/deleteTask/getTaskDetails`, `ReminderService.updateReminder/updateStatus/deleteReminder` and `AuthService.getUserDetails/deleteUser/updateUser/changePassword` all act on whatever id they're given.

## Impact
Anyone who can reach the Railway URL can read, change or delete any user's notes, tasks, reminders and profile, and can delete any account (`DELETE /auth/delete-user?id=N`). Ids are sequential, so they're easy to enumerate.

## Proposed fix
1. **Issue tokens.** On successful `POST /auth/login` and `POST /auth/create-user`, return `{ userId, accessToken, expiresAt }` with a signed JWT (HS256 is fine) carrying `sub=userId`. Read the secret from env `JWT_SECRET`, at least 32 bytes, never committed. 7 days is a reasonable lifetime for now. Optionally add a refresh token later.
2. **Validate tokens.** Use the Spring Security OAuth2 resource server already on the classpath: `http.oauth2ResourceServer(o -> o.jwt(...))` with a `JwtDecoder` built from the same secret (`NimbusJwtDecoder.withSecretKey`). Put the encoder/decoder beans in `config/JwtConfig.java`.
3. **Lock routes down.** `permitAll()` only for `/auth/login`, `/auth/create-user`, swagger/api-docs (and maybe only in non-prod). Everything else gets `.authenticated()`. Remove `httpBasic`. Keep CSRF disabled (stateless API) and set `SessionCreationPolicy.STATELESS`.
4. **Take the user from the token, not the request.** Add a helper such as `CurrentUser.id(Authentication)` or an `@AuthenticationPrincipal Jwt jwt` parameter.
   - For list/create endpoints, ignore or remove `userId` from query/body and use the token's subject. For backward compatibility during rollout, accept the param but return 403 if it doesn't match the token.
   - For by-id endpoints (`get-details-by-noteId`, `update-*`, `delete-*`, `toggle-*`, `update-status`), load the entity and return **404** if `entity.user.id != currentUserId`. Use 404 rather than 403 so ids can't be probed.
   - Add repository methods such as `findByNoteIdAndUser_Id`, `findByTaskIdAndUser_Id`, `findByReminderIdAndUser_Id`.
5. `auth/delete-user`, `update-user`, `change-password` and `user-details-by-userid` work only on the current user.
6. Update `SecurityAccessTests` (it currently asserts routes are reachable *without* credentials) to assert the opposite.

## Acceptance criteria
- [ ] Login and signup return a JWT. All data routes return 401 without a valid `Authorization: Bearer` token.
- [ ] User A's token cannot read, change or delete user B's notes, tasks, reminders or profile. These requests return 404.
- [ ] `JWT_SECRET` comes from the environment. The app fails fast at startup if it's missing in prod.
- [ ] Swagger documents the bearer scheme (`OpenApiConfig`).
- [ ] `./mvnw test` passes.

## Tests to add
- `SecurityAccessTests`: 401 without a token on each route group, 200 with a token.
- An ownership test per resource: create as A, then access as B and expect 404.
- A token-expiry test using a clock or a short-lived token.

## Notes
- Coordinate the rollout with SEC-02. The current app sends no token and will break as soon as this ships.
- BE-03 changes failure status codes. Don't mix both changes in one PR.
