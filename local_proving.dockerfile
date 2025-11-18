ARG CUDA_RUNTIME_IMG=nvidia/cuda:12.9.1-devel-ubuntu24.04
# ARG CUDA_RUNTIME_IMG=nvidia/cuda:13.0.1-runtime-ubuntu24.04
FROM ${CUDA_RUNTIME_IMG}

RUN apt-get update && \
    apt-get install -y ca-certificates libssl3 curl tar cmake build-essential xz-utils unzip librust-async-compression-dev git protobuf-compiler && \
    rm -rf /var/lib/apt/lists/*

# TODO following rzup commands should likely only be done in a builder image to minimize image size
# Install RISC0 and groth16 component early for better caching
ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:$PATH
ENV RISC0_HOME=/usr/local/risc0
ENV PATH="/root/.cargo/bin:${PATH}"

# Install rust and target version (should match rust-toolchain.toml for best speed)
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y \
    && chmod -R a+w $RUSTUP_HOME $CARGO_HOME \
    && rustup install 1.88

# Install RISC0 specifically for groth16 component - this layer will be cached unless RISC0_HOME changes
RUN curl -L https://risczero.com/install | bash && \
    /root/.risc0/bin/rzup install risc0-groth16 && \
    # Clean up any temporary files to reduce image size
    rm -rf /tmp/* /var/tmp/*


RUN git clone https://github.com/risc0/risc0.git && \
    cd risc0 && \
    cargo run --bin rzup install

# build:
#     ```
#     docker build -t test -f local_proving.dockerfile .
#     ```

# run:
#     ```
#     docker run -it --rm --runtime=nvidia --gpus all test /bin/bash
#     ```
# test in container:
#     ```
#     cd /risc0 && RUSTFLAGS="-C target-cpu=native" cargo run -F cuda -r --example datasheet
#     ```