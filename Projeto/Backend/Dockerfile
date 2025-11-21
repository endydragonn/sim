## Estágio de build: compila o jar com Java 21 e Maven 3.9
FROM maven:3.9.7-eclipse-temurin-21-jammy AS build
WORKDIR /build
COPY pom.xml .
COPY src ./src
RUN mvn -B -DskipTests clean package

# Estágio runtime: imagem pequena apenas para executar o jar (Java 25)
FROM eclipse-temurin:25-jre-jammy
WORKDIR /app
COPY --from=build /build/target/*.jar ./app.jar
EXPOSE 8081
ENTRYPOINT ["java", "-Dserver.port=8081", "-jar", "/app/app.jar"]
