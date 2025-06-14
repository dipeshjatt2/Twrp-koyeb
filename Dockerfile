# Dockerfile
FROM ubuntu:22.04

# Install dependencies
RUN apt-get update && \
    apt-get install -y bc bison build-essential curl flex g++-multilib \
    gcc-multilib git gnupg gperf imagemagick lib32ncurses-dev libncurses-dev \
    libsdl1.2-dev libssl-dev libxml2 libxml2-utils lzop pngcrush rsync \
    schedtool squashfs-tools xsltproc zip zlib1g-dev python3 android-sdk-libsparse-utils \
    android-sdk-ext4-utils android-sdk-fsutils openjdk-11-jdk

# Set up repo tool
RUN mkdir -p ~/bin && \
    curl https://storage.googleapis.com/git-repo-downloads/repo > ~/bin/repo && \
    chmod a+x ~/bin/repo

# Set up build environment
WORKDIR /build
COPY .koyeb/build.sh /usr/local/bin/build.sh
RUN chmod +x /usr/local/bin/build.sh

CMD ["/usr/local/bin/build.sh"]