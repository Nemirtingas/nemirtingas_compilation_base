ARG UBUNTU_VER=24.04
FROM ubuntu:${UBUNTU_VER}

ARG CLANG_VER=22
ENV DEBIAN_FRONTEND=noninteractive

RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get install -y \
        ca-certificates \
        curl \
        file \
        git \
        git-lfs \
        gnupg \
        gpg \
        lsb-release \
        ninja-build \
        pkg-config \
        python3 \
        python3-pip \
        software-properties-common \
        unzip \
        wget \
        zip \
        build-essential && \
    rm -rf /var/lib/apt/lists/*

# -----------------------------------------------------------------------------
# Node.js (needed for forgejo actions)
# -----------------------------------------------------------------------------
RUN install -m 0755 -d /usr/share/keyrings && \
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
        | gpg --dearmor -o /usr/share/keyrings/nodesource.gpg && \
    chmod 644 /usr/share/keyrings/nodesource.gpg && \
    NODE_MAJOR=24 && \
    printf '%s\n' \
        'Types: deb' \
        "URIs: https://deb.nodesource.com/node_${NODE_MAJOR}.x" \
        'Suites: nodistro' \
        'Components: main' \
        "Architectures: $(dpkg --print-architecture)" \
        'Signed-By: /usr/share/keyrings/nodesource.gpg' \
        > /etc/apt/sources.list.d/nodesource.sources && \
    apt-get update && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

# -----------------------------------------------------------------------------
# LLVM / Clang
# -----------------------------------------------------------------------------
RUN wget -qO /etc/apt/trusted.gpg.d/apt.llvm.org.asc \
        https://apt.llvm.org/llvm-snapshot.gpg.key && \
    wget -q https://apt.llvm.org/llvm.sh && \
    chmod +x llvm.sh && \
    ./llvm.sh ${CLANG_VER} && \
    apt-get install -y \
        clang-${CLANG_VER} \
        clang-tools-${CLANG_VER} \
        lld-${CLANG_VER} \
        llvm-${CLANG_VER} && \
    rm -f llvm.sh && \
    rm -rf /var/lib/apt/lists/*

# Symlinks clang -> clang-X etc.
RUN set -eux; \
    cd /usr/bin; \
    for bin in *-"${CLANG_VER}"; do \
        [ -e "$bin" ] || continue; \
        target="$(readlink -f "$bin")"; \
        base="${bin%-${CLANG_VER}}"; \
        ln -sf "$target" "/usr/bin/$base"; \
    done

# -----------------------------------------------------------------------------
# vcpkg
# -----------------------------------------------------------------------------
RUN git clone --depth 1 -b my_crosscompile \
        https://github.com/Nemirtingas/vcpkg.git /vcpkg && \
    /vcpkg/bootstrap-vcpkg.sh -disableMetrics && \
    ln -sf /vcpkg/vcpkg /usr/local/bin/vcpkg && \
    /vcpkg/vcpkg install vcpkg-cmake

# -----------------------------------------------------------------------------
# CMake symlink from vcpkg bundled tools
# -----------------------------------------------------------------------------
RUN CMAKE_BIN=$(find /vcpkg/downloads/tools -type f -path "*/bin/cmake" | head -n 1) && \
    ln -sf "${CMAKE_BIN}" /usr/local/bin/cmake

WORKDIR /