
FROM node:24.15.0-bookworm-slim

ARG NPM_VERSION

RUN apt-get update \
    && apt-get install -y --no-install-recommends time \
    && rm -rf /var/lib/apt/lists/* \
    && test -n "$NPM_VERSION" \
    && npm install --global "npm@${NPM_VERSION}" \
    && test "$(npm --version)" = "$NPM_VERSION"

WORKDIR /experiment

CMD ["sleep", "infinity"]
