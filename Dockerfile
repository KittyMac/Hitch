FROM swift:5.7.1-focal as builder

RUN export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true && apt-get -q update && \
    apt-get install -y \
    libpq-dev \
    libpng-dev \
    libjpeg-dev \
    libjavascriptcoregtk-4.0-dev \
    libatomic1

RUN rm -rf /var/lib/apt/lists/*


WORKDIR /root/Hitch
COPY ./Makefile ./Makefile
COPY ./Package.swift ./Package.swift
COPY ./Sources ./Sources
COPY ./Tests ./Tests

RUN swift package update
RUN swift build --configuration release
RUN swift test -v
