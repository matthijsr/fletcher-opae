FROM fletcher_opae_env:latest

# Fletcher runtime
ARG FLETCHER_VERSION=0.0.22
ARG ARROW_VERSION=8.0.0
RUN mkdir -p /fletcher && \
    dnf install -y https://apache.jfrog.io/artifactory/arrow/centos/$(cut -d: -f5 /etc/system-release-cpe)-stream/apache-arrow-release-latest.rpm && \
    dnf install -y arrow-devel-${ARROW_VERSION}-1.el8 && \
    curl -L https://github.com/matthijsr/fletcher/archive/${FLETCHER_VERSION}.tar.gz | tar xz -C /fletcher --strip-components=1 && \
    cd /fletcher && \
    cmake3 -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr . && \
    make -j && \
    make install && \
    rm -rf /fletcher

# Fletcher hardware libs
RUN git clone --recursive --single-branch -b ${FLETCHER_VERSION} https://github.com/matthijsr/fletcher /fletcher
ENV FLETCHER_HARDWARE_DIR=/fletcher/hardware

# Install vhdmmio
RUN python3 -m pip install -U pip && \
    python3 -m pip install vhdmmio vhdeps pyarrow==${ARROW_VERSION} && \
    python3 -m pip install https://github.com/matthijsr/fletcher/releases/download/${FLETCHER_VERSION}/pyfletchgen-${FLETCHER_VERSION}-cp39-cp39-manylinux_2_17_x86_64.manylinux2014_x86_64.whl

# Fletcher plaform support for OPAE
# ARG FLETCHER_OPAE_VERSION=0.2.3
# RUN mkdir -p /fletcher-opae && \
#     curl -L https://github.com/matthijsr/fletcher-opae/archive/${FLETCHER_OPAE_VERSION}.tar.gz | tar xz -C /fletcher-opae --strip-components=1 && \
#     cd /fletcher-opae && \
#     cmake3 -DCMAKE_BUILD_TYPE=Release -DBUILD_FLETCHER_OPAE-ASE=ON -DCMAKE_INSTALL_PREFIX=/usr . && \
#     make -j && \
#     make install && \
#     rm -rf /fletcher-opae

# Fletcher plaform support for OPAE (local)
COPY . /fletcher-opae
RUN cd /fletcher-opae && \
    cmake3 -DCMAKE_BUILD_TYPE=Release -DBUILD_FLETCHER_OPAE-ASE=ON -DCMAKE_INSTALL_PREFIX=/usr . && \
    make -j && \
    make install && \
    rm -rf /fletcher-opae

# Fix Modelsim on Centos 8 Stream (not necessary for newer versions of Quartus):
# 1. Force it to use local GCC by removing the built-in GCCs
RUN rm -rf /opt/intelFPGA_pro/quartus_19.2.0b57/modelsim_ase/gcc-*.*.*-linux
# 2. Install libstdc++.i686 (dependency)
RUN dnf install libstdc++.i686

WORKDIR /src