FROM ubuntu:22.04

LABEL maintainer="devops@example.com"

# hadolint ignore=DL3008
RUN apt-get update \
    && apt-get install -y --no-install-recommends curl procps \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY scripts/ /app/scripts/

CMD ["bash", "scripts/health_check.sh"]
