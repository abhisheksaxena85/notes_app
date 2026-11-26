# SEC-03 — DB password committed to git: rotate it and move secrets to env

**Type:** Security · **Priority:** P0 · **Area:** Backend / repo · **Depends on:** none

## Problem
`Backend/src/main/resources/application.properties:10` contains, in a comment, a real-looking local MySQL root password:
```
# spring.datasource.password=<REDACTED — see the file itself>
```
It has been in history since the first commit (`git log --oneline -- Backend/src/main/resources/application.properties` → `85de3c9 Initial Setup`), and the repo is pushed to `github.com/abhisheksaxena85/notes_app`. Line 12 also sets `spring.jpa.show-sql=true` in the prod profile, which logs every SQL statement.

## Proposed fix
1. **Human step (not code):** treat the password as leaked. Change it on every MySQL instance where it is or was used, and anywhere else it was reused. Claude Code cannot do this; list it in the PR description as a manual step.
2. Remove the commented dev block. Create profiles instead:
   - `application.properties`: shared settings plus `${ENV}` placeholders only.
   - `application-dev.properties`: `spring.datasource.url=jdbc:mysql://localhost:3306/notes_application?createDatabaseIfNotExist=true`, `username=${DB_USER:root}`, `password=${DB_PASSWORD}`, `show-sql=true`.
   - Set prod `show-sql=false`.
3. Add `Backend/.env.example` (no real values) and make sure `.env` is gitignored (it already is in `Backend/.dockerignore`; add it to `.gitignore` too).
4. Optional: purge the secret from history with `git filter-repo`. This rewrites history and needs a force-push, so only do it with the owner's explicit OK. Rotating the password is what actually fixes the leak.

## Acceptance criteria
- [ ] No credentials in any tracked file (`git grep -i "password="` shows placeholders only).
- [ ] `./mvnw spring-boot:run -Dspring-boot.run.profiles=dev` works with `DB_PASSWORD` set.
- [ ] Prod doesn't log SQL.
- [ ] The PR description says the password must be rotated.
