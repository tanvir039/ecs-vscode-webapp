# Build Stage
FROM debian:bookworm-slim AS build

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    tar \
    gzip \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*


RUN curl -fsSL \
    "https://github.com/coder/code-server/releases/download/v4.136.2/code-server-4.136.2-linux-amd64.tar.gz" \
    -o /tmp/app.tar.gz \
    && mkdir -p /app \
    && tar --strip-components=1 -xzf /tmp/app.tar.gz -C /app \
    && rm /tmp/app.tar.gz



# Runtime stage
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN useradd appuser -m -s /bin/bash

WORKDIR /app

COPY --from=build --chown=appuser:appuser /app/ ./

USER appuser

EXPOSE 8080

CMD ["./bin/code-server", "--bind-addr", "0.0.0.0:8080"]