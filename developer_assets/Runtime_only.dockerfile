FROM quay.io/centos/centos:stream8

RUN dnf install -y dnf-plugins-core && \
    dnf config-manager --set-enabled powertools && \
    dnf install -y epel-release && \
    dnf config-manager --enable epel 

# Dev/Build requirements
RUN dnf install -y python39 python39-pip python39-devel cmake make libuuid-devel json-c-devel gcc clang gcc-c++ hwloc-devel tbb-devel rpm-build rpmdevtools git
RUN dnf install -y libedit-devel
RUN dnf install -y libudev-devel
RUN dnf install -y libcap-devel

# Python 3.9
RUN alternatives --set python3 /usr/bin/python3.9
RUN ln -s /usr/bin/python3 /usr/bin/python

# Python packages
RUN python3 -m pip install --user \
        jsonschema \
        virtualenv \
        pudb \
        pyyaml

RUN pip3 uninstall -y setuptools
RUN pip3 install Pybind11==2.10.0
RUN pip3 install setuptools==59.6.0 --prefix=/usr

# Open Programmable Acceleration Engine
ARG OPAE_SDK=2.0.11-1
RUN git clone https://github.com/OPAE/opae-sdk.git /opae-sdk && \
    cd /opae-sdk && \
    git checkout ${OPAE_SDK} &&\
    mkdir -p /opae-sdk/build && \
    cd /opae-sdk/build && \
    cmake3 \
    -DCMAKE_BUILD_TYPE=Release \
    -DOPAE_BUILD_FPGABIST=ON \
    -DOPAE_BUILD_PYTHON_DIST=ON \
	-DCMAKE_INSTALL_PREFIX=/usr /opae-sdk && \
    make -j `nproc` && \
    make install && \
    rm -rf /opae-sdk

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


# Fletcher plaform support for OPAE
# To fetch specific versions of OPAE: -DFETCH_OPAE=ON -DFETCH_OPAE_TAG=2.0.9-4 -DFETCH_OPAE_SIM_TAG=2.0.10-2 
ARG FLETCHER_OPAE_VERSION=0.2.3
RUN mkdir -p /fletcher-opae && \
    curl -L https://github.com/matthijsr/fletcher-opae/archive/${FLETCHER_OPAE_VERSION}.tar.gz | tar xz -C /fletcher-opae --strip-components=1 && \
    cd /fletcher-opae && \
    cmake3 -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_FLETCHER_OPAE-ASE=OFF \
    -DFETCH_OPAE=ON -DFETCH_OPAE_TAG=2.0.11-1 \
    -DCMAKE_INSTALL_PREFIX=/usr . && \
    make -j && \
    make install && \
    rm -rf /fletcher-opae

WORKDIR /src