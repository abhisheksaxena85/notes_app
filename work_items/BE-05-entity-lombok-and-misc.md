# BE-05 — `@Data` on JPA entities plus small service bugs

**Type:** Bug / robustness · **Priority:** P2 · **Area:** Backend · **Depends on:** none

## Problems
1. **`@Data` on entities with two-way relations.** `UserModel` (`@Data`, `List<NotesModel> articles`, `tasks`, `reminders`) and `NotesModel`/`TaskModel`/`ReminderModel` (`@Data`, `UserModel user`). Lombok's generated `toString()`, `equals()` and `hashCode()` follow these references, so `user.toString()` → note → user → … → `StackOverflowError`. It's also a lazy-loading trap. Today it's only avoided because nobody calls `toString` (logging an entity would crash). `equals`/`hashCode` on a generated id also breaks `Set` semantics.
2. **`getNotes` ignores ordering.** `NotesService.getNotes` returns `user.getArticles()` (unordered), even though `NotesRepository.findByUser_IdOrderByIsPinnedDescCreatedAtDesc` exists and isn't used.
3. **`deleteUser` reports success when the user doesn't exist** (`AuthService.java:100-110`, `setDeleted(true)` in both branches).
4. **`updateUser` echoes the request** (`AuthService.java:132-136`) instead of the saved values, so it returns `null` for fields that weren't sent.
5. `UserModel` uses `cascade = REMOVE` and `orphanRemoval` on three collections. Deleting a user loads every child row into memory first. That's fine at this scale; add an `ON DELETE CASCADE` FK if it ever matters.
6. `jakarta.transaction.Transactional` is used instead of Spring's `org.springframework.transaction.annotation.Transactional`. Prefer Spring's for `readOnly` and rollback rules. Reads in `TaskService`/`ReminderService` have no transaction while notes reads do. Make this consistent.
7. Unused imports (`jakarta.persistence.Id`, `Query` in `AuthRepository`).

## Proposed fix
- Replace `@Data` on entities with `@Getter @Setter @NoArgsConstructor` plus `@ToString(exclude = {"user"})` / `exclude = {"articles","tasks","reminders","password"}`. Write `equals`/`hashCode` by id only when non-zero, or leave them out.
- Use the ordered repository method in `getNotes` (and in `exportNotes`).
- `deleteUser` → 404 when missing (BE-03). `updateUser` → return the saved entity's values.
- Switch to Spring `@Transactional`; add `@Transactional(readOnly = true)` on reads.

## Acceptance criteria
- [ ] A test calls `toString()` on a user with notes, tasks and reminders without a stack overflow.
- [ ] `get-all-notes` returns pinned first, then newest first.
- [ ] Tests for `deleteUser` (missing) and `updateUser` (partial update returns the stored values).
