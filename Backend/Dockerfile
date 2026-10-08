# Use a lightweight Alpine JRE runtime
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app

# Add a non-root user for security
RUN addgroup -S spring && adduser -S spring -G spring
USER spring:spring

# Copy your locally pre-built JAR file into the image
# For Maven:
COPY target/*.jar app.jar

# (Uncomment below and comment out Maven if using Gradle)
# COPY build/libs/*-SNAPSHOT.jar app.jar

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]
