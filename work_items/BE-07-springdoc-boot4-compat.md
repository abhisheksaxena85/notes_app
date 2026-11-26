# BE-07 — Check springdoc 2.x works with Spring Boot 4

**Type:** Dependency risk · **Priority:** P2 · **Area:** Backend · **Depends on:** none

## Problem
`Backend/pom.xml` uses `spring-boot-starter-parent` **4.1.1** with `springdoc-openapi-starter-webmvc-ui` **2.8.13**. The springdoc 2.x line was built for Spring Boot 3 / Spring Framework 6. Spring Boot 4 uses Spring Framework 7, which springdoc 3.x targets. The app may start, but `/swagger-ui.html` and `/v3/api-docs` can fail at runtime.

## Task
1. Run the app (`dev` profile, or the test profile with H2) and open `/v3/api-docs` and `/swagger-ui/index.html`.
2. If either errors, upgrade to the springdoc release line that supports Boot 4 (check Maven Central for `org.springdoc:springdoc-openapi-starter-webmvc-ui`) and fix any API changes in `config/OpenApiConfig.java`.
3. Add a smoke test: `MockMvc GET /v3/api-docs` → 200 with JSON containing `"/notes/get-all-notes"`.
4. While in `pom.xml`, check Lombok 1.18.48 against JDK 17 and the annotation processor config, and remove unused dependencies (keep the oauth2 resource server; SEC-01 uses it).

## Acceptance criteria
- [ ] The api-docs smoke test passes in `./mvnw test`.
- [ ] Swagger UI loads locally.
