FROM ubuntu

# Build test suite

ARG TEST_SUITE_REPO=https://gitlab.com/sequoia-pgp/openpgp-interoperability-test-suite.git

ARG TEST_SUITE_REF=6303cbbbdc6156480662e2982307aa004b83c090

RUN apt update && apt install -y git rustc cargo clang llvm pkg-config nettle-dev

ENV TEST_SUITE_DIR=/test-suite

RUN git clone  ${TEST_SUITE_REPO} ${TEST_SUITE_DIR}

WORKDIR ${TEST_SUITE_DIR}

RUN git checkout ${TEST_SUITE_REF}

RUN cargo build

ENV TEST_SUITE=${TEST_SUITE_DIR}/target/debug/openpgp-interoperability-test-suite

# Install sqop

ARG SQOP_VERSION="0.27.3"

RUN cargo install sequoia-sop --version ${SQOP_VERSION} --features=cli

ENV SQOP=/root/.cargo/bin/sqop

ENV PATH=/root/.cargo/bin:${PATH}

# Install gpg

RUN apt update && apt install -y gnupg libgpg-error-dev libgpgme-dev

# Install gpgme

ENV GPGME_SOP_DIR=/gpgme-sop

RUN mkdir ${GPGME_SOP_DIR}

ARG GPGME_SOP_REPO=https://gitlab.com/sequoia-pgp/gpgme-sop.git

ARG GPGME_SOP_REF=40f1e0372747e0f0d15713c13510394e5ef32108

RUN git clone ${GPGME_SOP_REPO} ${GPGME_SOP_DIR}

WORKDIR ${GPGME_SOP_DIR}

RUN git checkout ${GPGME_SOP_REF}

RUN cargo build --features=cli --release

ENV GPGME_SOP=${GPGME_SOP_DIR}/target/release/gpgme-sop

# Install golang

RUN apt update && apt install -y wget

ENV GOLANG_DIR=/go

ARG GOLANG_VERSION="1.20.1"

ARG GOLANG_CHECK_SUM="000a5b1fca4f75895f78befeb2eecf10bfff3c428597f3f1e69133b63b911b02"

RUN mkdir ${GOLANG_DIR}

WORKDIR ${GOLANG_DIR}

RUN wget https://go.dev/dl/go${GOLANG_VERSION}.linux-amd64.tar.gz

RUN echo "${GOLANG_CHECK_SUM} go${GOLANG_VERSION}.linux-amd64.tar.gz" | sha256sum --check --status

RUN tar -C / -xzf go${GOLANG_VERSION}.linux-amd64.tar.gz

RUN rm go${GOLANG_VERSION}.linux-amd64.tar.gz

ENV PATH=${GOLANG_DIR}/bin:${PATH}

# Install gosop

ENV GOSOP_DIR=/gosop

RUN mkdir ${GOSOP_DIR}

ARG GOSOP_REPO=https://github.com/ProtonMail/gosop.git

ARG GOSOP_REF=92fc880b0f3bc7f5c7f64c7e5894f1ff347ea619

RUN git clone ${GOSOP_REPO} ${GOSOP_DIR}

WORKDIR ${GOSOP_DIR}

RUN git checkout ${GOSOP_REF}

RUN go build .

ENV PATH=${GOSOP_DIR}:${PATH}

ENV GOSOP=${GOSOP_DIR}/gosop

# Install sop-openpgpjs

RUN apt update && apt install -y nodejs npm

ENV SOP_OPENPGPJS_DIR=/sop-openpgpjs

ARG SOP_OPENPGPJS_REPO=https://github.com/openpgpjs/sop-openpgpjs.git

ARG SOP_OPENPGPJS_REF=e650d7ebc728d8851938a9b4be1f2dd847ba93c7

RUN mkdir ${SOP_OPENPGPJS_DIR}

RUN git clone ${SOP_OPENPGPJS_REPO} ${SOP_OPENPGPJS_DIR}

WORKDIR ${SOP_OPENPGPJS_DIR}

RUN git checkout ${SOP_OPENPGPJS_REF}

RUN npm install

ENV PATH=${SOP_OPENPGPJS_DIR}:${PATH}

ENV SOP_OPENPGPJS=${SOP_OPENPGPJS_DIR}/sop-openpgp

# Install RNP

RUN apt update && apt install -y cmake libbz2-dev zlib1g-dev libjson-c-dev build-essential python3 python-is-python3

ENV BOTAN_DIR=/botan

ARG BOTAN_VERSION="2.18.2"

RUN mkdir ${BOTAN_DIR}

WORKDIR ${BOTAN_DIR}

RUN wget -qO- https://botan.randombit.net/releases/Botan-${BOTAN_VERSION}.tar.xz | tar xvJ 

RUN cd Botan-${BOTAN_VERSION} && \
    ./configure.py --prefix=/usr && \
    make && \
    make install

ENV RNP_DIR=/rnp

RUN mkdir ${RNP_DIR}

ARG RNP_VESION="v0.16.2"

RUN git clone https://github.com/rnpgp/rnp.git -b ${RNP_VESION} ${RNP_DIR}

WORKDIR ${RNP_DIR}

RUN mkdir build

RUN cd build && \
    cmake -DCMAKE_INSTALL_PREFIX=/usr -DBUILD_SHARED_LIBS=on -DBUILD_TESTING=off ../ && \
    make && \
    make install

# Install RNP-SOP

ENV RNP_SOP_DIR=/rnp-sop

RUN mkdir ${RNP_SOP_DIR}

ARG RNP_SOP_REPO=https://gitlab.com/sequoia-pgp/rnp-sop.git

ARG RNP_SOP_REF=242491142047532c92cb1ea94abb5256d388665e

RUN git clone ${RNP_SOP_REPO} ${RNP_SOP_DIR}

WORKDIR ${RNP_SOP_DIR}

RUN git checkout ${RNP_SOP_REF}

RUN cargo build --release

ENV RNP_SOP=${RNP_SOP_DIR}/target/release/rnp-sop

WORKDIR /