# Stage 1: Build the Spring Boot application
FROM maven:3.9-eclipse-temurin-17 AS build

WORKDIR /workspace

# Copy Maven configuration first
COPY pom.xml .

# Download dependencies before copying application code
RUN mvn -B dependency:go-offline

# Copy application source code
COPY src ./src

# Package the application. Tests run in CI (.github/workflows/ci.yml), not here.
RUN mvn -B clean package -DskipTests


# Stage 2: Run the packaged application
FROM eclipse-temurin:17-jre

WORKDIR /app

# Run as an unprivileged user, not root
RUN groupadd --system app && useradd --system --gid app --no-create-home app

# Copy the JAR from the build stage
COPY --from=build /workspace/target/*.jar /app/app.jar

USER app

# Spring listens on $PORT (server.port=${PORT:8080}); 8080 when PORT is unset.
EXPOSE 8080

# Start the Spring Boot application
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
