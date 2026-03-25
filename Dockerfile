FROM nvidia/cuda:12.4.1-devel-ubuntu22.04

RUN apt-get update -qq && \
    apt-get install -y -qq git make python3 ocl-icd-opencl-dev && \
    mkdir -p /etc/OpenCL/vendors && \
    echo "libnvidia-opencl.so.1" > /etc/OpenCL/vendors/nvidia.icd && \
    ldconfig && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Build Profanity2 (ETH)
RUN cd /root && \
    git clone https://github.com/1inch/profanity2.git && \
    cd profanity2 && make -j$(nproc)

# Build Solanity with runtime prefix patch (SOL)
RUN cd /root && \
    git clone -b runtime-prefix https://github.com/jarvishubai/solanity.git && \
    cd solanity && \
    sed -i "s/sm_37,sm_50,sm_61,sm_70/sm_80,sm_86/g" src/gpu-common.mk && \
    sed -i "s/compute_35/compute_80/g" src/gpu-common.mk && \
    export PATH=/usr/local/cuda/bin:\$PATH && \
    bash mk

WORKDIR /root

# Test both tools work
RUN cd /root/profanity2 && ./profanity2.x64 --help | head -3
RUN cd /root/solanity && export LD_LIBRARY_PATH=./src/release && ./src/release/cuda_ed25519_vanity 2>&1 | head -5 || echo "SOL needs runtime args"

# Usage examples:
# ETH: cd /root/profanity2 && ./profanity2.x64 --matching abcXXXXXXXX...
# SOL: cd /root/solanity && export LD_LIBRARY_PATH=./src/release && ./src/release/cuda_ed25519_vanity Dav Moon
