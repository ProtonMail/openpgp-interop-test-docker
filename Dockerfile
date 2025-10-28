FROM ubuntu AS build

# Set up essential build tools and libraries
RUN apt-get update -qq && apt-get install -y -qq --no-install-recommends \
    curl build-essential git wget ca-certificates\
    # Interoperability test suite
    clang-15 llvm pkg-config nettle-dev \
    # GnuPG dependencies
    gnupg libgpg-error-dev libgpgme-dev  \
    # RNP with Botan dependencies
    cmake libbz2-dev zlib1g-dev libjson-c-dev python3 python-is-python3 \
    # rSOP
    libpcsclite-dev libdbus-1-dev

# Install Rust
ENV RUST_VERSION=1.90.0
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y && \
    . "$HOME/.cargo/env" && \
    rustup install ${RUST_VERSION} && rustup default ${RUST_VERSION} && \
    rustc --version
ENV PATH="/root/.cargo/bin:${PATH}"

# Install Go
ENV GOLANG_VERSION=1.21.0 GOLANG_DIR=/go
WORKDIR /scratch
RUN wget https://go.dev/dl/go${GOLANG_VERSION}.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf go${GOLANG_VERSION}.linux-amd64.tar.gz && rm go${GOLANG_VERSION}.linux-amd64.tar.gz
ENV PATH="/usr/local/go/bin:${PATH}"

# Install Node.js (LTS)
ARG NODE_VERSION=22.21.0
RUN apt-get install -y -qq --no-install-recommends nodejs npm && \
    npm install -g n && n install ${NODE_VERSION}

# Test Suite
ARG TEST_SUITE_REPO=https://gitlab.com/sequoia-pgp/openpgp-interoperability-test-suite.git
ARG TEST_SUITE_REF=7034d684ab3aa407d5c48b4e92f0ff0befc83de0
WORKDIR /test-suite
RUN git clone ${TEST_SUITE_REPO} . && \
    git checkout ${TEST_SUITE_REF}
RUN cargo build

# All sops will be stored here
WORKDIR /sops

# Install sqop
ARG SQOP_VERSION="0.32.0"
RUN cargo install sequoia-sop --version ${SQOP_VERSION} --features=cli
RUN cp /root/.cargo/bin/sqop /sops

# GPGME Sop
ARG GPGME_SOP_REPO=https://gitlab.com/sequoia-pgp/gpgme-sop.git
ARG GPGME_SOP_REF=8663f6049953c660c4a417d25fd8fb740a6ea7b9
WORKDIR /scratch/gpgme-sop
RUN git clone ${GPGME_SOP_REPO} . && \
    git checkout ${GPGME_SOP_REF}
RUN cargo build --features=cli --release
RUN cp /scratch/gpgme-sop/target/release/gpgme-sop /sops

# GoSOP
ARG GOSOP_REPO=https://github.com/ProtonMail/gosop.git
ARG GOSOP_REF=30dd70b0383eb3d1c510ac6d2cfd6361ddb26f27
WORKDIR /scratch/gosop
RUN git clone ${GOSOP_REPO} . && \
    git checkout ${GOSOP_REF}
RUN go build
RUN cp /scratch/gosop/gosop /sops

# GoSOP V2
ARG GOSOP_REF_V2=488b4128fb242eb3e5806013e152e8313200e19f
WORKDIR /scratch/gosop-v2
RUN git clone ${GOSOP_REPO} . && \
    git checkout ${GOSOP_REF_V2}
RUN go build
RUN cp /scratch/gosop-v2/gosop /sops/gosop-v2

# OpenPGP.js Sop
ARG SOP_OPENPGPJS_REPO=https://github.com/openpgpjs/sop-openpgpjs.git
ARG SOP_OPENPGPJS_REF=d35fe10b1818da9047d9a335f93d96bc098a1635
WORKDIR /sops/sop-openpgpjs
RUN git clone ${SOP_OPENPGPJS_REPO} . && \
    git checkout ${SOP_OPENPGPJS_REF}
RUN npm install

# OpenPGP.js V6 Sop
ARG SOP_OPENPGPJS_V2_TAG=v2.2.0
WORKDIR /sops/sop-openpgpjs-v2
RUN git clone ${SOP_OPENPGPJS_REPO} . && \
    git checkout tags/${SOP_OPENPGPJS_V2_TAG} 
RUN npm install

# RNP and Botan
ARG BOTAN_VERSION="3.4.0"
ARG RNP_VERSION="v0.17.1"
WORKDIR /scratch/botan
RUN wget -qO- https://botan.randombit.net/releases/Botan-${BOTAN_VERSION}.tar.xz | tar xvJ && \
    cd Botan-${BOTAN_VERSION} && ./configure.py --prefix=/usr && make && make install
WORKDIR /scratch/rnp
RUN git clone https://github.com/rnpgp/rnp.git --recurse-submodules --shallow-submodules -b ${RNP_VERSION} .
WORKDIR /scratch/rnp/build
RUN cmake -DCMAKE_INSTALL_PREFIX=/opt/rnp -DBUILD_SHARED_LIBS=on -DBUILD_TESTING=off -DENABLE_CRYPTO_REFRESH=on .. && make -j$(nproc) install

# RNP Sop
RUN PKG_CONFIG_PATH=/opt/rnp/lib/pkgconfig cargo install --features=cli --git https://gitlab.com/sequoia-pgp/rnp-sop --branch sop-rs-0.7
RUN cp /root/.cargo/bin/rnp-sop /sops

# Install rsop
ARG RSOP_VERSION="0.8.0"
RUN cargo install rsop --version ${RSOP_VERSION}
RUN cp /root/.cargo/bin/rsop /sops

# Final cleaned up image
FROM ubuntu

# Install dependencies
RUN apt-get update -qq && apt install -y -qq --no-install-recommends \
libnettle8 libssl3 libpcsclite1 nodejs libgpgme11 gnupg gnupg1 libsqlite3-0 \ 
libdbus-1-3 libjson-c5 libbz2-1.0 zlib1g libjson-c5

# Copy relevant sop data
COPY --from=build /sops /sops
COPY --from=build /test-suite /test-suite
COPY --from=build /opt/rnp /opt/rnp
COPY --from=build /usr/lib/libbotan-3.so /opt/rnp/lib

# Add /opt/rnp to the ld library search path
RUN echo "/opt/rnp/lib" >> /etc/ld.so.conf.d/rnp.conf && ldconfig

# Copy relevant sop data
ENV SOP_OPENPGPJS=/sops/sop-openpgpjs/sop-openpgp
ENV SOP_OPENPGPJS_V2=/sops/sop-openpgpjs-v2/sopenpgpjs
ENV RNP_SOP=/sops/rnp-sop
ENV RSOP=/sops/rsop
ENV GPGME_SOP=/sops/gpgme-sop
ENV SQOP=/sops/sqop
ENV GOSOP=/sops/gosop
ENV GOSOP_V2=/sops/gosop-v2
ENV TEST_SUITE_DIR=/test-suite
ENV TEST_SUITE=${TEST_SUITE_DIR}/target/debug/openpgp-interoperability-test-suite
