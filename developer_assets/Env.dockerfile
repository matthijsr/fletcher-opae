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

RUN dnf install -y autoconf automake bison boost boost-devel libxml2 libxml2-devel ncurses grub2 bc csh flex glibc-locale-source libnsl ncurses-compat-libs 
RUN localedef -f UTF-8 -i en_US en_US.UTF-8

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

# Intel Acceleration Stack for Development for Intel Programmable Acceleration Card with Intel Arria 10 GX FPGA
RUN yum install -y curl sudo && \
    mkdir -p /installer && \
    curl -L http://download.altera.com/akdlm/software/ias/1.2.1/a10_gx_pac_ias_1_2_1_pv_dev.tar.gz | tar xz -C /installer --strip-components=1 && \
    sed -i 's/install_opae=1/install_opae=0/g' /installer/setup.sh && \
    /installer/setup.sh --installdir /opt --yes && \
    rm -rf /installer && \
    yum install -y libpng12 freetype fontconfig libX11 libSM libXrender libXext libXtst

ENV OPAE_PLATFORM_ROOT /opt/inteldevstack/a10_gx_pac_ias_1_2_1_pv/
ENV QUARTUS_HOME /opt/intelFPGA_pro/quartus_19.2.0b57/quartus/
ENV PATH "${QUARTUS_HOME}/bin:${PATH}"

# Modelsim
RUN mkdir -p /installer && \
    cd /installer && \
    curl -L -O http://download.altera.com/akdlm/software/acdsinst/19.2/57/ib_installers/ModelSimProSetup-19.2.0.57-linux.run && \
    curl -L -O http://download.altera.com/akdlm/software/acdsinst/19.2/57/ib_installers/modelsim-part2-19.2.0.57-linux.qdz && \
    chmod +x ModelSimProSetup-19.2.0.57-linux.run && \
    ./ModelSimProSetup-19.2.0.57-linux.run --mode unattended --installdir /opt/intelFPGA_pro/quartus_19.2.0b57/ --accept_eula 1 && \
    rm -rf /installer && \
    yum install -y glibc-devel.i686 libX11.i686 libXext.i686 libXft.i686 libgcc libgcc.i686 && \
    sed -ci 's/linux_rh60/linux/g' /opt/intelFPGA_pro/quartus_19.2.0b57/modelsim_ase/bin/vsim

ENV MTI_HOME /opt/intelFPGA_pro/quartus_19.2.0b57/modelsim_ase
ENV QUESTA_HOME "${MTI_HOME}"
ENV PATH "${MTI_HOME}/bin:${PATH}"

# Platform Interface Manager
ARG OFS_REF=2dde2f3f8ad3070694d7ca26e93056f72ca0bc41
RUN mkdir -p /ofs-platform-afu-bbb && \
    curl -L https://github.com/OPAE/ofs-platform-afu-bbb/archive/${OFS_REF}.tar.gz | tar xz -C /ofs-platform-afu-bbb --strip-components=1 && \
    cd /ofs-platform-afu-bbb/ && \
    ./plat_if_release/update_release.sh $OPAE_PLATFORM_ROOT

# Open Programmable Acceleration Engine
ARG OPAE_SDK=76db48ba3c702185a69663ffe831ee191672b003
RUN git clone https://github.com/OPAE/opae-sdk.git /opae-sdk && \
    cd /opae-sdk && \
    git checkout ${OPAE_SDK} &&\
    mkdir -p /opae-sdk/build && \
    cd /opae-sdk/build && \
    cmake3 \
    -DCMAKE_BUILD_TYPE=Release \
    -DOPAE_BUILD_LIBOPAE_PY=On \
    -DOPAE_BUILD_LIBOPAEVFIO=Off \
    -DOPAE_BUILD_PLUGIN_VFIO=Off \
    -DOPAE_BUILD_EXTRA_TOOLS=On \
	-DCMAKE_INSTALL_PREFIX=/usr /opae-sdk && \
    make -j && \
    make install && \
    cmake3 -P cmake_install.cmake

# OPAE Simulator
ARG OPAE_SIM=f8e7bd5e876a5b913fb53d6fc85653211eb7af3f
RUN git clone https://github.com/OPAE/opae-sim.git /opae-sim && \
    cd /opae-sim && \
    git checkout ${OPAE_SIM} && \
    mkdir -p /opae-sim/build && \
    cd /opae-sim/build && \
    cmake3 \
    -DCMAKE_BUILD_TYPE=Release \
	-DCMAKE_INSTALL_PREFIX=/usr /opae-sim && \
    make && \
    make install && \
    rm -rf /opae-sim && \
    rm -rf /opae-sdk

# Intel FPGA Basic Building Blocks
ARG BBB_REF=4456d1edb785f2373639671aa70ad2a6d00984a7
RUN mkdir -p /intel-fpga-bbb/build && \
    curl -L https://github.com/OPAE/intel-fpga-bbb/archive/${BBB_REF}.tar.gz | tar xz -C /intel-fpga-bbb --strip-components=1 && \
    cd /intel-fpga-bbb/build && \
    cmake3 -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/usr .. && \
    make -j && \
    make install

ENV FPGA_BBB_CCI_SRC /intel-fpga-bbb

WORKDIR /src
