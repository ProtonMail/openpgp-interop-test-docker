FROM ubuntu

# Build test suite

ARG TEST_SUITE_REPO=https://gitlab.com/sequoia-pgp/openpgp-interoperability-test-suite.git

ARG TEST_SUITE_REF=2273f28f86a7407d71cfac34e4fda0a444b4d42a

RUN apt update && apt install -y git rustc cargo clang-15 llvm pkg-config nettle-dev

ENV TEST_SUITE_DIR=/test-suite

RUN git clone  ${TEST_SUITE_REPO} ${TEST_SUITE_DIR}

WORKDIR ${TEST_SUITE_DIR}

RUN git checkout ${TEST_SUITE_REF}

RUN cargo build

ENV TEST_SUITE=${TEST_SUITE_DIR}/target/debug/openpgp-interoperability-test-suite

# Install sqop

ARG SQOP_VERSION="0.32.0"

RUN cargo install sequoia-sop --version ${SQOP_VERSION} --features=cli

ENV SQOP=/root/.cargo/bin/sqop

ENV PATH=/root/.cargo/bin:${PATH}

# Install gpg

RUN apt update && apt install -y gnupg libgpg-error-dev libgpgme-dev

# Install gpgme

ENV GPGME_SOP_DIR=/gpgme-sop

RUN mkdir ${GPGME_SOP_DIR}

ARG GPGME_SOP_REPO=https://gitlab.com/sequoia-pgp/gpgme-sop.git

ARG GPGME_SOP_REF=8663f6049953c660c4a417d25fd8fb740a6ea7b9

RUN git clone ${GPGME_SOP_REPO} ${GPGME_SOP_DIR}

WORKDIR ${GPGME_SOP_DIR}

RUN git checkout ${GPGME_SOP_REF}

RUN cargo build --features=cli --release

ENV GPGME_SOP=${GPGME_SOP_DIR}/target/release/gpgme-sop

# Install golang

RUN apt update && apt install -y wget

ENV GOLANG_DIR=/go

ARG GOLANG_VERSION="1.21.0"

ARG GOLANG_CHECK_SUM="d0398903a16ba2232b389fb31032ddf57cac34efda306a0eebac34f0965a0742"

RUN mkdir ${GOLANG_DIR}

WORKDIR ${GOLANG_DIR}

RUN wget https://go.dev/dl/go${GOLANG_VERSION}.linux-amd64.tar.gz

RUN echo "${GOLANG_CHECK_SUM} go${GOLANG_VERSION}.linux-amd64.tar.gz" | sha256sum --check --status

RUN tar -C / -xzf go${GOLANG_VERSION}.linux-amd64.tar.gz

RUN rm go${GOLANG_VERSION}.linux-amd64.tar.gz

ENV PATH=${GOLANG_DIR}/bin:${PATH}

# Install gosop (for gopenpgp v2)

ENV GOSOP_DIR=/gosop

RUN mkdir ${GOSOP_DIR}

ARG GOSOP_REPO=https://github.com/ProtonMail/gosop.git

ARG GOSOP_REF=30dd70b0383eb3d1c510ac6d2cfd6361ddb26f27

RUN git clone ${GOSOP_REPO} ${GOSOP_DIR}

WORKDIR ${GOSOP_DIR}

RUN git checkout ${GOSOP_REF}

RUN go build .

ENV PATH=${GOSOP_DIR}:${PATH}

ENV GOSOP=${GOSOP_DIR}/gosop

# Install gosop-v2 (for gopenpgp v3)

ENV GOSOP_DIR_V2=/gosop-v2

RUN mkdir ${GOSOP_DIR_V2}

ARG GOSOP_REPO=https://github.com/ProtonMail/gosop.git

ARG GOSOP_REF=488b4128fb242eb3e5806013e152e8313200e19f

RUN git clone ${GOSOP_REPO} ${GOSOP_DIR_V2}

WORKDIR ${GOSOP_DIR_V2}

RUN git checkout ${GOSOP_REF}

RUN go build .

ENV PATH=${GOSOP_DIR_V2}:${PATH}

ENV GOSOP_V2=${GOSOP_DIR_V2}/gosop

# Install sop-openpgpjs

# Default is LTS
ARG NODE_VERSION=18.15.0

RUN apt update && apt install -y nodejs npm wget

RUN npm install -g n && n install ${NODE_VERSION}

ENV SOP_OPENPGPJS_DIR=/sop-openpgpjs

ARG SOP_OPENPGPJS_REPO=https://github.com/openpgpjs/sop-openpgpjs.git

ARG SOP_OPENPGPJS_REF=d35fe10b1818da9047d9a335f93d96bc098a1635

RUN mkdir ${SOP_OPENPGPJS_DIR}

RUN git clone ${SOP_OPENPGPJS_REPO} ${SOP_OPENPGPJS_DIR}

WORKDIR ${SOP_OPENPGPJS_DIR}

RUN git checkout ${SOP_OPENPGPJS_REF}

RUN npm install

ENV PATH=${SOP_OPENPGPJS_DIR}:${PATH}

ENV SOP_OPENPGPJS=${SOP_OPENPGPJS_DIR}/sop-openpgp

# Install sop-openpgpjs with v6 support
ENV SOP_OPENPGPJS_V2_DIR=/sop-openpgpjs-v2

ARG SOP_OPENPGPJS_V2_REPO=https://github.com/openpgpjs/sop-openpgpjs.git

ARG SOP_OPENPGPJS_V2_TAG=v2.0.0-1

RUN mkdir ${SOP_OPENPGPJS_V2_DIR}

RUN git clone ${SOP_OPENPGPJS_V2_REPO} ${SOP_OPENPGPJS_V2_DIR}

WORKDIR ${SOP_OPENPGPJS_V2_DIR}

RUN git checkout tags/${SOP_OPENPGPJS_V2_TAG}

RUN npm install

ENV PATH=${SOP_OPENPGPJS_V2_DIR}:${PATH}

ENV SOP_OPENPGPJS_V2=${SOP_OPENPGPJS_V2_DIR}/sopenpgpjs

# Install RNP
RUN apt update && apt install -y cmake libbz2-dev zlib1g-dev libjson-c-dev build-essential python3 python-is-python3

ENV BOTAN_DIR=/botan

ARG BOTAN_VERSION="2.19.4"

RUN mkdir ${BOTAN_DIR}

WORKDIR ${BOTAN_DIR}

RUN wget -qO- https://botan.randombit.net/releases/Botan-${BOTAN_VERSION}.tar.xz | tar xvJ 

RUN cd Botan-${BOTAN_VERSION} && \
    ./configure.py --prefix=/usr && \
    make && \
    make install

ENV RNP_DIR=/rnp

RUN mkdir ${RNP_DIR}

ARG RNP_VESION="v0.17.1"

RUN git clone https://github.com/rnpgp/rnp.git --recurse-submodules --shallow-submodules -b ${RNP_VESION} ${RNP_DIR}

WORKDIR ${RNP_DIR}

RUN mkdir build

RUN cd build && \
    cmake -DCMAKE_INSTALL_PREFIX=/usr -DBUILD_SHARED_LIBS=on -DBUILD_TESTING=off .. && \
    make && \
    make install

# Install RNP-SOP

ENV RNP_SOP_DIR=/rnp-sop

ENV SOP_RS_DIR=/sop-rs

RUN mkdir ${RNP_SOP_DIR}

RUN mkdir ${SOP_RS_DIR}

RUN git clone https://gitlab.com/sequoia-pgp/sop-rs.git ${SOP_RS_DIR}

WORKDIR ${SOP_RS_DIR}

ARG SOP_RS_REF=v0.6.0

RUN git checkout ${SOP_RS_REF}

ARG RNP_SOP_REPO=https://gitlab.com/sequoia-pgp/rnp-sop.git

ARG RNP_SOP_REF=242491142047532c92cb1ea94abb5256d388665e

RUN git clone ${RNP_SOP_REPO} ${RNP_SOP_DIR}

WORKDIR ${RNP_SOP_DIR}

RUN git checkout ${RNP_SOP_REF}

RUN cargo build --release

ENV RNP_SOP=${RNP_SOP_DIR}/target/release/rnp-sop

WORKDIR /

# Install rsop

ARG RSOP_VERSION="0.3.7"

RUN apt install -y libpcsclite-dev

RUN cargo install rsop --version ${RSOP_VERSION}

ENV RSOP=/root/.cargo/bin/rsop
