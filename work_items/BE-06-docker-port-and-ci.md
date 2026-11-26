# BE-06 — CI workflow can't find the Dockerfile; container port mismatch; no tests in CI

**Type:** Bug / DevOps · **Priority:** P1 · **Area:** CI, Backend · **Depends on:** none

## Problems
1. `.github/workflows/docker-image.yml:18` runs `docker build . --file Dockerfile` from the **repo root**, but the only Dockerfile is `Backend/Dockerfile`. The workflow fails on every push and PR to `main`.
2. `Backend/Dockerfile` sets `ENV PORT=80` and `EXPOSE 80`, but `application.properties` has no `server.port`, so Spring listens on **8080**. On Railway (which injects `PORT`) the app ignores it. It probably only works because of manual port settings.
3. The Docker build uses `-DskipTests`, and no workflow runs `mvn test` or `flutter test`. Tests exist (`Backend/src/test`, `Frontend/test`) but nothing enforces them.
4. The image tag is `my-image-name:<timestamp>` and nothing is pushed, so the job has no output.

## Proposed fix
1. `application.properties`: `server.port=${PORT:8080}`. Dockerfile: remove `ENV PORT=80`, use `EXPOSE 8080`, and run as a non-root user (`USER 1000`).
2. Replace the workflow with `ci.yml`:
   - `backend` job: `actions/setup-java@v4` (temurin 17, maven cache) → `cd Backend && ./mvnw -B test`.
   - `frontend` job: `subosito/flutter-action@v2` (channel stable, version pinned to what `pubspec.lock` was produced with; the `sdk: ^3.13.2` constraint needs a recent Flutter) → `flutter pub get`, `dart run build_runner build --delete-conflicting-outputs` (only if generated files aren't committed), `flutter analyze`, `flutter test`.
   - `docker` job (needs backend): `docker build Backend --file Backend/Dockerfile --tag daymark-backend:${{ github.sha }}`. Push to GHCR only if the owner wants that (leave a commented step).
3. Optional: `paths` filters so frontend-only changes skip the backend job and vice versa.

## Acceptance criteria
- [ ] CI is green on a PR. A failing unit test makes CI red.
- [ ] `docker run -e PORT=9000 -p 9000:9000 …` serves on 9000; with no `PORT` it serves on 8080.
