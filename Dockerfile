# Stage 1: Build stage
FROM nextcloud:latest as build

# Set up environment variables
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies for building dlib and pdlib
RUN apt-get update && apt-get install -y \
    git \
    wget \
    cmake \
    ffmpeg \
    libx11-dev \
    libopenblas-dev \
    liblapack-dev \
    bzip2 \
    libbz2-dev \

# Build dlib
RUN git clone https://github.com/davisking/dlib.git \
    && mkdir dlib/dlib/build \
    && cd dlib/dlib/build \
    && cmake -DBUILD_SHARED_LIBS=ON .. \
    && make -j$(nproc) \
    && make install

# Build pdlib
RUN git clone https://github.com/goodspb/pdlib.git \
    && cd pdlib \
    && phpize \
    && ./configure --enable-debug \
    && make -j$(nproc) \
    && make install

# Stage 2: Final runtime container
FROM nextcloud:latest

# Copy the built pdlib extension from the build stage
COPY --from=build /usr/local/lib/php/extensions/ /usr/local/lib/php/extensions/
COPY --from=build /usr/local/lib/libdlib.so /usr/local/lib/libdlib.so

# Configure PHP to load pdlib
RUN echo "[pdlib]" > /usr/local/etc/php/conf.d/docker-php-ext-pdlib.ini \
    && echo "extension=pdlib.so" >> /usr/local/etc/php/conf.d/docker-php-ext-pdlib.ini
