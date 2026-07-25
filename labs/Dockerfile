# vibage-skills lab image — script continuum only. Not Tier-0.
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    bash ca-certificates curl git python3 python3-pip ripgrep rsync \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /pkg
# Package is bind-mounted at runtime as /pkg:ro
CMD ["sleep", "infinity"]
