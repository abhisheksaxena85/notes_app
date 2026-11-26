# REPO-01 — Commit the current work, fix `.gitignore`, remove tracked junk

**Type:** Hygiene · **Priority:** P1 (do first) · **Area:** Repo · **Depends on:** none

## Problem
- A lot of finished work isn't committed. `git status` at audit time showed modified backend auth and notes code, plus **untracked** `Backend/src/main/java/.../tasks/`, `.../reminders/`, the new calendar DTOs, `CrossOriginConfig`, `ChangePasswordRequestDto`, `NotesApiTests`, `SecurityAccessTests` and `Backend/.dockerignore`. The last commit (`98e7f36 "Stable Version"`) doesn't contain the tasks and reminders backend that the app already calls. If this machine is lost, that work is lost.
- There's **no root `.gitignore`**. Tracked files that shouldn't be: `.DS_Store` in about a dozen folders, `Backend/.idea/*`, `Frontend/android/.idea/*` (including `workspace.xml` and `caches/`), `Frontend/android/notes_app_android.iml`, `Frontend/.flutter-plugins-dependencies`, `Frontend/test_screen.png`.
- `.claude/settings.local.json` is untracked and **must stay out of git** (personal settings).
- `Frontend/.gitignore` lists `.gitignore` itself, which is confusing. Remove that line.

## Tasks
1. Root `.gitignore`:
   ```
   .DS_Store
   .idea/
   *.iml
   .vscode/
   .claude/settings.local.json
   .env
   ```
   Extend `Frontend/.gitignore` with the standard Flutter template entries (`.flutter-plugins-dependencies`, `android/.gradle/`, `android/local.properties`, `ios/Flutter/Generated.xcconfig`, `ios/Flutter/ephemeral/`, `macos/Flutter/ephemeral/`, `*.iml`, `.idea/`) and remove the `.gitignore` line.
2. Stop tracking without deleting local files: `git rm -r --cached` for each tracked junk path above.
3. Check the generated code policy: either commit `*.g.dart` (current practice, keep it) or generate it in CI (BE-06). Pick one and note it in `Frontend/README.md`.
4. Commit in logical chunks: (a) ignores and untracking, (b) backend tasks and reminders module plus tests, (c) frontend changes, (d) `work_items/`.
5. Two different `instruction_work.md` files exist (repo root and `Frontend/`). Keep one, or move both into `docs/` with clear names (`docs/spec-workspace-tasks-reminders.md`).

## Notes for the agent
- Don't commit `.claude/settings.local.json`, `.env`, or anything with secrets (see SEC-03).
- Don't force-push or rewrite history here.
- Committing is the owner's call. Prepare the changes and the commit plan, then commit only if asked.

## Acceptance criteria
- [ ] `git status` is clean after the commits. `git ls-files | grep -E "DS_Store|\.idea|\.iml"` returns nothing.
- [ ] The backend builds and tests pass from a fresh clone (`git clone … && cd Backend && ./mvnw test`).
