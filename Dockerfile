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
RUN apk update \
    && apk add --no-cache \
      ca-certificates \
      dmsetup \
      git \
      tzdata \
    && update-ca-certificates

# See https://stackoverflow.com/a/55757473/12429735RUN 
RUN adduser \
    --disabled-password \
    --gecos "" \
    --no-create-home \
    --shell "/sbin/nologin" \
    --system \
    --uid "${UID}" \
    "${USER}"

WORKDIR $GOPATH/src/github.com/google/cadvisor

RUN git clone https://github.com/google/cadvisor.git . \
    && GOOS=linux GOARCH=amd64 go build -ldflags="-w -s" -o make build

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
COPY --from=builder /go/src/github.com/google/cadvisor/cadvisor /app/cadvisor

# Use an unprivileged user.
USER gouser:gouser

# Run the binary.
ENTRYPOINT ["/app/cadvisor"]
