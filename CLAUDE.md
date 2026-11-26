# DayMark: standing rules for Claude Code

These rules override the per-branch/PR workflow described in `work_items/README.md`.

## Git workflow
- Work directly on `main`: `git pull`, commit, `git push origin main`. No branches, no PRs, no asking for approval or for a plan.
- Never rewrite history or force-push.
- Never commit secrets: `.env`, passwords, tokens, keystores, `.claude/settings.local.json`.

## Work items
- Work items live in `work_items/`. Do them in the order given.
- One commit per work item, message starting with its ID (e.g. `SEC-03: ...`). Push after each.
- Tick each finished item in the `work_items/README.md` table in the same commit.
- Line numbers in work items may have drifted; search for the quoted code.
- If a step can't be done in code (rotating a password, testing on a physical device), do everything else and list that step for the owner at the end.

## Checks before every commit
Run the checks for what you touched. Never commit with failing checks; fix them first.
- Backend: `cd Backend && ./mvnw test`
- Frontend: `cd Frontend && flutter analyze && flutter test`
  - If Drift tables or json models changed, first run `dart run build_runner build --delete-conflicting-outputs`.

## Reporting
Finish with a short summary: commits, checks run, anything skipped and why, manual steps for the owner.
