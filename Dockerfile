# Dockerfile
FROM ubuntu:20.04

# Build arguments
ARG DEVICE_TREE_URL
ARG DEVICE_CODE

# Environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    TZ=UTC \
    PATH="/root/bin:${PATH}"

# Install base dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    software-properties-common apt-utils && \
    add-apt-repository ppa:openjdk-r/ppa -y && \
    apt-get update

# Main package installation
RUN apt-get install -y --no-install-recommends \
    bc bison build-essential ca-certificates curl flex g++-multilib \
    gcc-multilib git gnupg gperf imagemagick lib32ncurses-dev \
    libncurses-dev libsdl1.2-dev libssl-dev libxml2 libxml2-utils \
    lzop pngcrush rsync schedtool squashfs-tools xsltproc zip \
    zlib1g-dev python3 openjdk-11-jdk repo && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Android tools (manual installation)
RUN mkdir -p /opt/android-sdk && \
    cd /opt/android-sdk && \
    curl -O https://dl.google.com/android/repository/platform-tools-latest-linux.zip && \
    unzip platform-tools-latest-linux.zip && \
    rm platform-tools-latest-linux.zip && \
    ln -s /opt/android-sdk/platform-tools/adb /usr/bin/adb && \
    ln -s /opt/android-sdk/platform-tools/fastboot /usr/bin/fastboot

WORKDIR /build
COPY .koyeb/build.sh /usr/local/bin/build.sh
RUN chmod +x /usr/local/bin/build.sh

CMD ["/usr/local/bin/build.sh"]
