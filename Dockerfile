FROM eclipse-temurin:17-jdk-jammy

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl git fonts-liberation \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Cache Maven dependencies as a separate layer
COPY pom.xml .
RUN mvn dependency:go-offline -q || true

# Copy test sources
COPY src ./src
COPY serenity.properties .

ENV MAVEN_OPTS="-Xmx1024m -XX:MaxMetaspaceSize=512m"

ENTRYPOINT ["mvn", "verify", "-Pcucumber", "--no-transfer-progress"]