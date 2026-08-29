# Compilacion
FROM gradle:8.5-jdk21 AS builder
WORKDIR /app

# copuiamos los archivos de configuracion gradle
COPY build.gradle settings.gradle gradlew ./
COPY gradle ./gradle

# ---> AGREGA ESTA LÍNEA <---
RUN chmod +x gradlew

# descargamos las dependencias para cachear
RUN ./gradlew dependencies --no-daemon

# Copiar el codigo fuente y compilar el jar
COPY src ./src
RUN ./gradlew bootJar --no-daemon -x test

# imagen ligera
FROM eclipse-temurin:21-jre-jammy
WORKDIR /app

# Crear un usuario sin privilegios por seguridad
RUN groupadd -g 1001 appgroup && useradd -u 1001 -g appgroup -m appuser
USER appuser

# Copiar el JAR ejecutable generado desde la etapa de compilacion
COPY --from=builder /app/build/libs/*.jar app.jar

# Exponer el puerto por defecto de Spring Boot
EXPOSE 8080

# Comando para ejecutar la aplicacion
ENTRYPOINT ["java", "-jar", "app.jar"]