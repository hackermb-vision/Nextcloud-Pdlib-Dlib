FROM nextcloud:production-fpm


 # Set up environment variables or necessary settings
 ENV DEBIAN_FRONTEND=noninteractive
 
 # Install dependencies for building dlib and pdlib
 RUN apt-get update && apt-get install -y \
 # Install ffmpeg
     ffmpeg \
 # ffmpeg Libraries:    
     # libavcodec-extra \
     # libavdevice-dev \
     # libavformat-dev \
     # libavfilter-dev \
     # libswresample-dev \
     # libswscale-dev \
     # libavutil-dev \
 # Used to clone & build
     git \
     wget \   
     cmake \
 # Dependenies for pdlib    
     libx11-dev \
 # OpenBLAS Library - optional
     libopenblas-dev \
     liblapack-dev \
 # For Facerecognition app to unzip models
     bzip2 \
     libbz2-dev && \
     docker-php-ext-install bz2
 
 # May or may not need    
     # build-essential \
     # pkg-config \
     # libpostproc-dev \
 
 # Clone, build, and install Dlib as a shared library
 RUN git clone https://github.com/davisking/dlib.git \
     && mkdir dlib/dlib/build \
     && cd dlib/dlib/build \
     && cmake -DBUILD_SHARED_LIBS=ON .. \
     && make \
     && make install
 
 # Clone, build, and install pdlib
 RUN git clone https://github.com/goodspb/pdlib.git \
     && cd pdlib \
     && phpize \
     && ./configure --enable-debug \
     # If the above command doesn't find dlib, uncomment the line below:
     # && PKG_CONFIG_PATH=/usr/local/lib/pkgconfig ./configure --enable-debug \
     && make \
     && make install
 
 # Append the necessary extension configuration to php.ini (for Docker that means add file to php/conf.d/)
 RUN echo "[pdlib]" >> /usr/local/etc/php/conf.d/docker-php-ext-pblib.ini \
     && echo "extension=\"pdlib.so\"" >> /usr/local/etc/php/conf.d/docker-php-ext-pblib.ini
 
 # Clean up
 RUN apt-get autoremove -y \
     && apt-get clean \
     && rm -rf /var/lib/apt/lists/* \
     && rm -rf /tmp/* \
     && rm -rf /var/tmp/*
