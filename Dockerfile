# Builds and runs the game on Linux.
#
# The build stage runs tools/tgs4_scripts/PreCompile.sh, the same script
# tgstation-server runs on Linux, so building this image also tests the
# TGS Linux deploy path (rust_g, tgui and DM compile).
#
# BYOND 516 needs glibc 2.34 or newer, so Ubuntu 22.04 is the oldest usable base.
# PreCompile.sh installs its own build packages (rust, git, i386 libssl and
# multilib), so the build stage adds nothing on top of the BYOND stage.
#
# Usage:
#   docker build -t tgmc .
#   docker run -p 1337:1337 -v tgmc-data:/tgmc/data tgmc
# Mount your own config with -v /path/to/config:/tgmc/config
# (on Docker Desktop for Windows a bind-mounted config is not read; copy it
# in with `docker cp` before starting the container instead)

FROM ubuntu:22.04 AS byond

ENV DEBIAN_FRONTEND=noninteractive

RUN dpkg --add-architecture i386 \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    unzip \
    make \
    libc6:i386 \
    libstdc++6:i386 \
    && rm -rf /var/lib/apt/lists/*

COPY dependencies.sh /tmp/dependencies.sh

RUN . /tmp/dependencies.sh \
    && cd /tmp \
    && curl -fsSL -H "User-Agent: tgstation/1.0 CI Script" \
    "https://www.byond.com/download/build/${BYOND_MAJOR}/${BYOND_MAJOR}.${BYOND_MINOR}_byond_linux.zip" \
    -o byond.zip \
    && unzip -q byond.zip \
    && cd byond \
    && make install \
    && cd / \
    && rm -rf /tmp/byond /tmp/byond.zip /tmp/dependencies.sh

FROM byond AS build

COPY . /tgmc_src

WORKDIR /precompile

RUN bash /tgmc_src/tools/tgs4_scripts/PreCompile.sh /tgmc_src

WORKDIR /tgmc_src

RUN DreamMaker -max_errors 0 tgmc.dme \
    && bash tools/deploy.sh /deploy \
    && cp -r config /deploy/config

FROM byond

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    libssl3:i386 \
    zlib1g:i386 \
    && rm -rf /var/lib/apt/lists/*

COPY --from=build /deploy /tgmc

WORKDIR /tgmc

EXPOSE 1337

VOLUME [ "/tgmc/data" ]

ENTRYPOINT [ "DreamDaemon", "tgmc.dmb", "-port", "1337", "-trusted", "-close", "-verbose" ]
