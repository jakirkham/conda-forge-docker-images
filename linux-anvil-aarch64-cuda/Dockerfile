# Note that this image doesn't cache cudatoolkit as it is not packaged by defaults.
# This docker image is meant for packages using CUDA driver and not for packages
# using the CUDA runtime.

ARG CUDA_VER

FROM nvidia/cuda-arm64:${CUDA_VER}-devel-centos7

LABEL maintainer="conda-forge <conda-forge@googlegroups.com>"

# Set CUDA_VER during runtime.
ARG CUDA_VER
ENV CUDA_VER ${CUDA_VER}

# Add qemu in here so that we can use this image on regular linux hosts with qemu user installed
ADD qemu-aarch64-static /usr/bin/qemu-aarch64-static

# Set an encoding to make things work smoothly.
ENV LANG en_US.UTF-8
ENV LANGUAGE=en_US.UTF-8

# Set path to CUDA install.
ENV CUDA_HOME /usr/local/cuda

# Add a timestamp for the build. Also, bust the cache.
ADD http://worldclockapi.com/api/json/utc/now /opt/docker/etc/timestamp

# Resolves a nasty NOKEY warning that appears when using yum.
RUN rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7 && \
    rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-SIG-AltArch-7-aarch64

# Remove preinclude system compilers
RUN rpm -e --nodeps --verbose gcc gcc-c++

# Install basic requirements.
COPY scripts/yum_clean_all /opt/docker/bin/
RUN yum update -y && \
    yum install -y \
        bzip2 \
        sudo \
        tar \
        which && \
    /opt/docker/bin/yum_clean_all

# Run common commands
COPY scripts/run_commands /opt/docker/bin/run_commands
RUN /opt/docker/bin/run_commands

# Download and cache new compiler packages.
# Should speedup installation of them on CIs.
RUN source /opt/conda/etc/profile.d/conda.sh && \
    conda activate && \
    conda create -n test --yes --quiet --download-only \
        conda-forge::binutils_impl_linux-aarch64 \
        conda-forge::binutils_linux-aarch64 \
        conda-forge::gcc_impl_linux-aarch64 \
        conda-forge::gcc_linux-aarch64 \
        conda-forge::gfortran_impl_linux-aarch64 \
        conda-forge::gfortran_linux-aarch64 \
        conda-forge::gxx_impl_linux-aarch64 \
        conda-forge::gxx_linux-aarch64 \
        conda-forge::libgcc-ng \
        conda-forge::libgfortran-ng \
        conda-forge::libstdcxx-ng && \
    conda remove --yes --quiet -n test --all && \
    conda clean -tiy && \
    chgrp -R lucky /opt/conda && \
    chmod -R g=u /opt/conda

# Add a file for users to source to activate the `conda`
# environment `root`. Also add a file that wraps that for
# use with the `ENTRYPOINT`.
COPY linux-anvil-aarch64/entrypoint_source /opt/docker/bin/entrypoint_source
COPY scripts/entrypoint /opt/docker/bin/entrypoint

# Ensure that all containers start with tini and the user selected process.
# Activate the `conda` environment `root`.
# Provide a default command (`bash`), which will start if the user doesn't specify one.
ENTRYPOINT [ "/opt/conda/bin/tini", "--", "/opt/docker/bin/entrypoint" ]
CMD [ "/bin/bash" ]
