# https://github.com/futurejones/swift-arm64-docker

# Ubuntu Impish 21.10
# Swift 5.5.2 Release
FROM ubuntu:21.10
LABEL maintainer="Swift on Arm <docker@swift-arm.com>"
LABEL description="Docker Container for the Swift programming language"

ARG TARGETPLATFORM
ARG TARGETOS
ARG TARGETARCH
ARG TARGETVARIANT

RUN echo "Target: $TARGETPLATFORM $TARGETOS $TARGETARCH $TARGETVARIANT"

RUN export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true && apt-get -q update && \
    apt-get -q install -y \
    wget \
    libgtk-4-dev \
    libglib2.0-dev \
    glib-networking \
    gobject-introspection \
    libgirepository1.0-dev \
    libgtksourceview-4-dev
    
ARG PACKAGE_NAME=swiftlang_5.5.2-01-ubuntu-hirsute_$TARGETARCH.deb
ARG RELEASE_TAG=v5.5.2-RELEASE
ARG SWIFT_WEBROOT=https://archive.swiftlang.xyz/repos/ubuntu/pool/main/s/swiftlang

RUN set -e; \
    SWIFT_BIN_URL="$SWIFT_WEBROOT/$PACKAGE_NAME" \
    # - download the swift toolchain
    && wget "$SWIFT_BIN_URL" \
    # - install swift
    && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -q install -y ./"$PACKAGE_NAME" \
    # - clean up.
    && rm -rf "$PACKAGE_NAME" \
    && apt-get purge --auto-remove -y wget \
    && rm -r /var/lib/apt/lists/*

# 2. build our swift program
WORKDIR /root/Hitch
COPY ./Makefile ./Makefile
COPY ./Package.swift ./Package.swift
COPY ./meta ./meta
COPY ./Sources ./Sources
COPY ./Tests ./Tests

RUN swift package update
RUN swift build --configuration release

