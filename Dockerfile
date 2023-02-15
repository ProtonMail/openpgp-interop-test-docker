FROM ubuntu

# Build test suite

RUN apt update && apt install -y git rustc cargo clang llvm pkg-config nettle-dev

ENV TEST_SUITE_DIR=/test-suite

RUN git clone https://gitlab.com/sequoia-pgp/openpgp-interoperability-test-suite.git ${TEST_SUITE_DIR}

WORKDIR ${TEST_SUITE_DIR}

RUN cargo build

ENV TEST_SUITE=${TEST_SUITE_DIR}/target/debug/openpgp-interoperability-test-suite

# Install sqop

ENV SQOP_VERSION="0.27.3"

RUN cargo install sequoia-sop --version ${SQOP_VERSION} --features=cli

ENV SQOP=/root/.cargo/bin/sqop

ENV PATH=/root/.cargo/bin:${PATH}

# Install gpg

RUN apt update && apt install -y gnupg libgpg-error-dev libgpgme-dev

# Install gpgme

ENV GPGME_SOP_DIR=/gpgme-sop

RUN mkdir ${GPGME_SOP_DIR}

RUN git clone https://gitlab.com/sequoia-pgp/gpgme-sop.git ${GPGME_SOP_DIR}

WORKDIR ${GPGME_SOP_DIR}

RUN cargo build --features=cli --release

ENV GPGME_SOP=${GPGME_SOP_DIR}/target/debug/gpgme-sop

# Install golang

RUN apt update && apt install -y wget

ENV GOLANG_DIR=/go

ENV GOLANG_VERSION="1.20.1"

ENV GOLANG_CHECK_SUM="000a5b1fca4f75895f78befeb2eecf10bfff3c428597f3f1e69133b63b911b02"

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

RUN git clone https://github.com/ProtonMail/gosop.git ${GOSOP_DIR}

WORKDIR ${GOSOP_DIR}

RUN go build .

ENV PATH=${GOSOP_DIR}:${PATH}

ENV GOSOP=${GOSOP_DIR}/gosop

# Install sop-openpgpjs

RUN apt update && apt install -y nodejs npm

ENV SOP_OPENPGPJS_DIR=/sop-openpgpjs

RUN mkdir ${SOP_OPENPGPJS_DIR}

RUN git clone https://github.com/openpgpjs/sop-openpgpjs.git ${SOP_OPENPGPJS_DIR}

WORKDIR ${SOP_OPENPGPJS_DIR}

RUN npm install

ENV PATH=${SOP_OPENPGPJS_DIR}:${PATH}

ENV SOP_OPENPGPJS=${SOP_OPENPGPJS_DIR}/sop-openpgp

# Install RNP

RUN apt update && apt install -y cmake libbz2-dev zlib1g-dev libjson-c-dev build-essential python3 python-is-python3

ENV BOTAN_DIR=/botan

ENV BOTAN_VERSION="2.18.2"

RUN mkdir ${BOTAN_DIR}

WORKDIR ${BOTAN_DIR}

RUN wget -qO- https://botan.randombit.net/releases/Botan-${BOTAN_VERSION}.tar.xz | tar xvJ 

RUN cd Botan-${BOTAN_VERSION} && \
    ./configure.py --prefix=/usr && \
    make && \
    make install

ENV RNP_DIR=/rnp

RUN mkdir ${RNP_DIR}

ENV RNP_VESION="v0.16.2"

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

RUN git clone https://gitlab.com/sequoia-pgp/rnp-sop.git ${RNP_SOP_DIR}

WORKDIR ${RNP_SOP_DIR}

RUN cargo build --release

ENV RNG_SOP=${RNP_SOP_DIR}/target/debug/rnp-sop

WORKDIR /