# Dockerfile
FROM ubuntu:22.04

# Build arguments
ARG DEVICE_TREE_URL
ARG DEVICE_CODE

# Environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    TZ=UTC \
    PATH="/root/bin:${PATH}"

# Install all dependencies in one RUN layer
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    bc bison build-essential ca-certificates curl flex g++-multilib \
    gcc-multilib git gnupg gperf imagemagick lib32ncurses-dev \
    libncurses-dev libsdl1.2-dev libssl-dev libxml2 libxml2-utils \
    lzop pngcrush rsync schedtool squashfs-tools xsltproc zip \
    zlib1g-dev python3 android-sdk-libsparse-utils android-sdk-ext4-utils \
    android-sdk-fsutils openjdk-11-jdk repo && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set up working directory
WORKDIR /build

# Copy build script
COPY .koyeb/build.sh /usr/local/bin/build.sh
RUN chmod +x /usr/local/bin/build.sh

# Set default command
CMD ["/usr/local/bin/build.sh"]