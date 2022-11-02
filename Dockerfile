FROM elixir:1.13-alpine as build

# Install deps
RUN set -xe; \
    apk add --update  --no-cache --virtual .build-deps \
        ca-certificates \
        g++ \
        gcc \
        git \
        make \
        musl-dev \
        nodejs \
        npm \
        python3 \
        tzdata;

# Use the standard /usr/local/src destination
RUN mkdir -p /usr/local/src/recognizer

COPY . /usr/local/src/recognizer/

# ARG is available during the build and not in the final container
# https://vsupalov.com/docker-arg-vs-env/
ARG MIX_ENV=prod
ARG APP_NAME=recognizer

# Use `set -xe;` to enable debugging and exit on error
# More verbose but that is often beneficial for builds
RUN set -xe; \
    cd /usr/local/src/recognizer/; \
    mix local.hex --force; \
    mix local.rebar --force; \
    mix deps.get; \
    mix deps.compile --all; \
    cd /usr/local/src/recognizer/assets/; \
    npm ci; \
    npm run build; \
    cd /usr/local/src/recognizer/; \
    mix phx.digest; \
    mix release

FROM alpine:3.16 as release

RUN set -xe; \
    apk add --update  --no-cache --virtual .runtime-deps \
        ca-certificates \
        libmcrypt \
        libmcrypt-dev \
        openssl \
        libstdc++ \
        ncurses-libs \
        tzdata;

# Create a `recognizer` group & user
# I've been told before it's generally a good practice to reserve ids < 1000 for the system
RUN set -xe; \
    addgroup -g 1000 -S recognizer; \
    adduser -u 1000 -S -h /recognizer -s /bin/sh -G recognizer recognizer;

ARG APP_NAME=recognizer

# Copy the release artifact and set `recognizer` ownership
COPY --chown=recognizer:recognizer --from=build /usr/local/src/recognizer/_build/prod/rel/${APP_NAME} /recognizer

# These are fed in from the build script
ARG VCS_REF
ARG BUILD_DATE
ARG VERSION

# `Maintainer` has been deprecated in favor of Labels / Metadata
# https://docs.docker.com/engine/reference/builder/#maintainer-deprecated
LABEL \
    org.opencontainers.image.created="${BUILD_DATE}" \
    org.opencontainers.image.description="recognizer" \
    org.opencontainers.image.revision="${VCS_REF}" \
    org.opencontainers.image.source="https://github.com/system76/recognizer" \
    org.opencontainers.image.title="recognizer" \
    org.opencontainers.image.vendor="system76" \
    org.opencontainers.image.version="${VERSION}"

ENV \
    PATH="/usr/local/bin:$PATH" \
    VERSION="${VERSION}" \
    APP_REVISION="${VERSION}" \
    MIX_APP="recognizer" \
    MIX_ENV="prod" \
    SHELL="/bin/bash"

# Drop down to our unprivileged `recognizer` user
USER recognizer

WORKDIR /recognizer

EXPOSE 8080
EXPOSE 50051

ENTRYPOINT ["/recognizer/bin/recognizer"]

CMD ["start"]
