#usr/bin/bash

FROM ubuntu:latest
RUN apt-get update && apt-get install -y \
    bash \
    curl \
    wget \
    build-essential \
    cmake \
    git \
    g++ \
    zlib1g-dev \
    libbz2-dev \
    liblzma-dev \
    libcurl4-openssl-dev \
    libboost-all-dev \
    && rm -rf /var/lib/apt/lists/*
RUN wget https://github.com/iqtree/iqtree2/releases/download/v2.2.0/iqtree2-2.2.0-linux.tar.gz \
    && tar -xvzf iqtree2-2.2.0-linux.tar.gz \
    && mv iqtree2-2.2.0-linux/iqtree2 /usr/local/bin/ \
    && rm -rf iqtree2-2.2.0-linux.tar.gz iqtree2-2.2.0-linux
COPY . /app
WORKDIR /app
RUN chmod +x script_linux.sh
CMD ["./script_linux.sh"] 
