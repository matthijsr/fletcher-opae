FROM fletcher_opae_runtime:latest

# Intel FPGA Basic Building Blocks
ARG BBB_REF=981ea22da82599ed05a330106e0ec35bbabae865
RUN mkdir -p /intel-fpga-bbb/build && \
    curl -L https://github.com/OPAE/intel-fpga-bbb/archive/${BBB_REF}.tar.gz | tar xz -C /intel-fpga-bbb --strip-components=1 && \
    cd /intel-fpga-bbb/build && \
    cmake3 -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/usr .. && \
    make -j && \
    make install

ENV FPGA_BBB_CCI_SRC /intel-fpga-bbb

# Fletcher hardware libs
ARG FLETCHER_VERSION=0.0.22
RUN git clone --recursive --single-branch -b ${FLETCHER_VERSION} https://github.com/matthijsr/fletcher /fletcher
ENV FLETCHER_HARDWARE_DIR=/fletcher/hardware

# Install vhdmmio
ARG ARROW_VERSION=8.0.0
RUN python3 -m pip install -U pip && \
    python3 -m pip install vhdmmio vhdeps pyarrow==${ARROW_VERSION} && \
    python3 -m pip install https://github.com/matthijsr/fletcher/releases/download/${FLETCHER_VERSION}/pyfletchgen-${FLETCHER_VERSION}-cp39-cp39-manylinux_2_17_x86_64.manylinux2014_x86_64.whl

WORKDIR /src