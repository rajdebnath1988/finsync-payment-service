# Use Amazon Corretto 17
FROM amazoncorretto:17

# Set the working directory
WORKDIR /app

# Copy the built Jar file
COPY target/payment-service-1.0-SNAPSHOT.jar app.jar

# Document that the container listens on port 8080
EXPOSE 8080

# Run the application
ENTRYPOINT ["java", "-jar", "app.jar"]
