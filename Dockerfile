FROM php:8.2-cli-bullseye AS builder

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential cmake pkg-config autoconf libtool libopenblas-dev libx11-dev wget unzip

# Build dlib
ARG DLIB_VERSION=19.19
RUN wget -q -O dlib.tar.gz https://github.com/davisking/dlib/archive/refs/tags/v${DLIB_VERSION}.tar.gz && \
    tar -xzf dlib.tar.gz && mv dlib-* dlib && \
    cd dlib && mkdir build && cd build && \
    cmake -DBUILD_SHARED_LIBS=ON -DCMAKE_BUILD_TYPE=Release .. && \
    make -j$(nproc) && make install

# Build pdlib (PHP extension for dlib)
ARG PDLIB_VERSION=master
RUN wget -q -O pdlib.zip https://github.com/matiasdelellis/pdlib/archive/${PDLIB_VERSION}.zip && \
    unzip pdlib.zip && mv pdlib-* pdlib && \
    cd pdlib && phpize && ./configure && \
    make -j$(nproc) && make install

FROM nextcloud:latest

# Install runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends libopenblas-base libx11-6 libxext6 && rm -rf /var/lib/apt/lists/*

# Copy dlib and pdlib from builder
COPY --from=builder /usr/local/lib/libdlib.so* /usr/local/lib/
COPY --from=builder /usr/local/lib/php/extensions/ /usr/local/lib/php/extensions/

# Enable pdlib extension in PHP
RUN echo "extension=pdlib.so" > /usr/local/etc/php/conf.d/pdlib.ini
