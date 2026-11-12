# Stage 1: Build the Spring Boot application
FROM maven:3.9-eclipse-temurin-17 AS build

WORKDIR /workspace

# Copy Maven configuration first
COPY pom.xml .

# Download dependencies before copying application code
RUN mvn -B dependency:go-offline

# Copy application source code
COPY src ./src

# Compile, test and package the application
RUN mvn clean package -DskipTests


# Stage 2: Run the packaged application
FROM eclipse-temurin:17-jre

WORKDIR /app

# Copy the JAR from the build stage
COPY --from=build /workspace/target/*.jar /app/app.jar

# Spring Boot will use port 80 inside this container
ENV PORT=80

# Document the port used by the application
EXPOSE 80

# Start the Spring Boot application
ENTRYPOINT ["java", "-jar", "/app/app.jar"]