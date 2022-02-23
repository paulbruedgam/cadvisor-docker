FROM golang:1.17
LABEL maintainer="Paul Brüdgam <paul@bruedgam.eu>"

# hadolint ignore=DL3008
RUN apt-get update \
    && apt-get install --no-install-recommends --yes git dmsetup \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /go/src/github.com/google/cadvisor

WORKDIR /go/src/github.com/google/cadvisor

RUN git clone https://github.com/google/cadvisor.git . \
    && make

ENTRYPOINT ["/go/src/github.com/google/cadvisor/cadvisor"]
