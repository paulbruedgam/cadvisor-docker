# https://chemidy.medium.com/create-the-smallest-and-secured-golang-docker-image-based-on-scratch-4752223b7324
############################
# STEP 1 build executable binary
############################
FROM golang:1.17-alpine as builder
LABEL maintainer="Paul Brüdgam <paul@bruedgam.eu>"

# Create appuser.
ENV USER=gouser
ENV UID=10001

# Install git.
# Git is required for fetching the dependencies.
# hadolint ignore=DL3018
RUN apk update \
    && apk add --no-cache \
      bash \
      build-base \
      ca-certificates \
      device-mapper \
      git \
      tzdata \
    && update-ca-certificates

# See https://stackoverflow.com/a/55757473/12429735RUN
RUN addgroup \
      --gid "${UID}" \
      --system "${USER}" \
    && addgroup \
      --gid 995 \
      --system docker \
    && adduser \
      --disabled-password \
      --gecos "" \
      --ingroup "${USER}" docker \
      --no-create-home \
      --shell "/sbin/nologin" \
      --system \
      --uid "${UID}" \
      "${USER}"

WORKDIR $GOPATH/src/github.com/google/cadvisor

RUN git clone https://github.com/google/cadvisor.git . \
    && sed -i 's/^ldflags="/ldflags="-linkmode external -extldflags -static/g' build/build.sh \
    && make build

############################
# STEP 2 build a small image
############################
FROM scratch

WORKDIR /app

# Import the user and group files from the builder.
COPY --from=builder /usr/share/zoneinfo /usr/share/zoneinfo
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /etc/passwd /etc/passwd
COPY --from=builder /etc/group /etc/group

# Copy our static executable.
COPY --chown=gouser:gouser --from=builder /go/src/github.com/google/cadvisor/cadvisor /app/cadvisor

# Use an unprivileged user.
USER gouser:gouser

# Run the binary.
ENTRYPOINT [ "/app/cadvisor" ]
