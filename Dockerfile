ARG UBUNTU_VER
FROM ubuntu:${UBUNTU_VER}
ARG CLANG_VER
RUN export DEBIAN_FRONTEND=noninteractive &&\
    dpkg --add-architecture i386 &&\
    apt-get update &&\
    apt-get -y install lsb-release python3 python3-pip git git-lfs wget zip unzip pkg-config curl ninja-build software-properties-common gnupg file &&\
    wget -qO- https://apt.llvm.org/llvm-snapshot.gpg.key |  tee /etc/apt/trusted.gpg.d/apt.llvm.org.asc &&\
    wget https://apt.llvm.org/llvm.sh &&\
    chmod +x llvm.sh &&\
    ./llvm.sh 22 &&\
    apt-get -y install ninja-build build-essential pkg-config clang clang-tools llvm lld &&\
    apt-get purge llvm-dev llvm-18* clang-18* -y &&\
    apt-get autoremove -y &&\
    apt-get clean &&\
    cd /usr/bin && for tool in clang*-${CLANG_VER} ll*-${CLANG_VER} dsymutil-${CLANG_VER}; do ln -s /usr/bin/${tool} /usr/bin/${tool%-${CLANG_VER}}; done && cd / &&\
    rm -f llvm.sh
RUN cd / &&\
    git clone --depth 1 -b my_crosscompile https://github.com/Nemirtingas/vcpkg.git vcpkg &&\
    cd /vcpkg &&\
    ./bootstrap-vcpkg.sh -disableMetrics &&\
    ln -s /vcpkg/vcpkg /usr/bin/ &&\
    vcpkg install vcpkg-cmake &&\
    ln -s /vcpkg/downloads/tools/cmake-*/cmake-*/bin/cmake /usr/bin/