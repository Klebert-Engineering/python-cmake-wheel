FROM quay.io/pypa/manylinux2014_x86_64

RUN yum update -y && yum install -y \
    ant \
    zlib-devel \
    perl-core \
    ninja-build \
    libsecret-devel \
    bzip2-devel \
    libffi-devel \
    openssl-devel

# Install OpenSSL 1.1
ADD https://www.openssl.org/source/openssl-1.1.1d.tar.gz /usr/local/src
RUN cd /usr/local/src && \
    tar -xzvf openssl-1.1.1d.tar.gz && \
    cd openssl-1.1.1d && \
    ./config --prefix=/usr/local/ssl --openssldir=/usr/local/ssl shared zlib && \
    make install
ENV OPENSSL_ROOT_DIR=/usr/local/ssl

# Install Python 3.8
ADD https://www.python.org/ftp/python/3.8.3/Python-3.8.3.tgz /usr/local/src
RUN cd /usr/local/src && \
    tar -xzvf Python-3.8.3.tgz && \
    cd Python-3.8.3 && \
    ./configure --enable-optimizations --enable-shared && \
    make install
RUN ln -s /usr/local/src/Python-3.8.3/libpython3.8.so.1.0 /lib64/libpython3.8.so.1.0
RUN pip3.8 install wheel
# ENV LD_LIBRARY_PATH=/usr/local/src/Python-3.8.3
