FROM ubuntu:24.04 AS builder

# Update & install essentials
RUN apt-get update \
    && apt-get install -y \
    autoconf \
    automake \
    autotools-dev \
    curl \
    python3 \
    python3-pip \
    python3-tomli \
    libmpc-dev \
    libmpfr-dev \
    libgmp-dev \
    gawk \
    build-essential \
    bison \
    flex \
    texinfo \
    gperf \
    libtool \
    patchutils \
    bc \
    zlib1g-dev \
    libexpat-dev \
    ninja-build \
    git \
    cmake \
    llvm \
    clang \
    libglib2.0-dev \
    libslirp-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY build.sh /tmp/build.sh
RUN chmod +x /tmp/build.sh \
    && /tmp/build.sh /opt/riscv-gcc /opt/riscv-llvm \
    && rm -rf /tmp/build.sh 

FROM ubuntu:24.04

RUN touch /var/mail/ubuntu \
    && chown ubuntu /var/mail/ubuntu \
    && userdel -r ubuntu

ARG USERNAME=ntl
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME

# Copy the built toolchains from the builder stage
COPY --chown=ntl --from=builder /opt/riscv-gcc /opt/riscv-gcc
COPY --chown=ntl --from=builder /opt/riscv-llvm /opt/riscv-llvm

RUN mkdir -p /opt/clang-wrapper/bin \
    && chown -R ntl:ntl /opt/clang-wrapper

COPY clang-wrapper.sh /opt/clang-wrapper/bin/clang
COPY riscv32-unknown-linux-gnu-clang.cfg /opt/clang-wrapper/riscv32-unknown-linux-gnu-clang.cfg
RUN chmod +x /opt/clang-wrapper/bin/clang

RUN apt-get update \
    && apt-get install -y \
    sudo \
    curl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

USER ntl
WORKDIR /home/ntl
ENV HOME=/home/ntl

# Add RISC-V toolchains to PATH
ENV PATH="/opt/riscv-gcc/bin:${PATH}"
ENV PATH="/opt/riscv-llvm/bin:${PATH}"
ENV PATH="/opt/clang-wrapper/bin:${PATH}"

ENTRYPOINT ["/bin/bash"]