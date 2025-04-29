########################
# Build stage (same as Nextcloud base)
########################
FROM nextcloud:production AS builder

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential cmake pkg-config autoconf libtool \
    libopenblas-dev libx11-dev php-dev php-pear git unzip wget

# Build dlib
ARG DLIB_VERSION=19.24
RUN git clone --branch v${DLIB_VERSION} --depth 1 https://github.com/davisking/dlib.git && \
    mkdir -p dlib/dlib/build && cd dlib/dlib/build && \
    cmake -DBUILD_SHARED_LIBS=ON -DCMAKE_BUILD_TYPE=Release .. && \
    make -j$(nproc) && make install

# Build pdlib
RUN git clone https://github.com/matiasdelellis/pdlib.git && \
    cd pdlib && phpize && ./configure && make -j$(nproc) && make install

########################
# Final stage (same as builder, but minimal)
########################
FROM nextcloud:production

RUN apt-get update && apt-get install -y --no-install-recommends \
    libx11-6 libxext6 libopenblas0 && \
    rm -rf /var/lib/apt/lists/*

# Copy libraries and extension
COPY --from=builder /usr/local/lib/libdlib.so* /usr/local/lib/
COPY --from=builder /usr/local/lib/php/extensions/ /usr/local/lib/php/extensions/

# Enable pdlib extension
RUN echo "extension=pdlib.so" > /usr/local/etc/php/conf.d/pdlib.ini
