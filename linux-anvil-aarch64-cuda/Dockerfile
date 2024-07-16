ARG CUDA_VER
ARG DISTRO_NAME
ARG DISTRO_VER
FROM --platform=linux/arm64 nvidia/cuda:${CUDA_VER}-devel-${DISTRO_NAME}${DISTRO_VER}

LABEL maintainer="conda-forge <conda-forge@googlegroups.com>"

ADD qemu-aarch64-static /usr/bin/qemu-aarch64-static

# Set CUDA_VER during runtime.
ARG CUDA_VER
ARG DISTRO_NAME
ARG DISTRO_VER
ENV CUDA_VER=${CUDA_VER} \
    DISTRO_NAME=${DISTRO_NAME} \
    DISTRO_VER=${DISTRO_VER}

# Set an encoding to make things work smoothly.
ENV LANG en_US.UTF-8
ENV LANGUAGE=en_US.UTF-8

# Set path to CUDA install.
ENV CUDA_HOME /usr/local/cuda

# we want to persist a path in ldconfig (to avoid having to always set LD_LIBRARY_PATH), but *after* the existing entries;
# since entries in ld.so.conf.d have precedence before the preconfigured directories, we first add the latter to the former
# the upstream images for 10.x all have libcuda.so under $CUDA_HOME/compat;
# add this to the ldconfig so it will be found correctly.
# don't forget to update settings by running ldconfig
RUN ldconfig -v 2>/dev/null | grep -v ^$'\t' | cut -f1 -d":" >> /etc/ld.so.conf.d/cuda-$CUDA_VER.conf && \
    echo "$CUDA_HOME/compat" >> /etc/ld.so.conf.d/cuda-$CUDA_VER.conf && \
    ldconfig

# bust the docker cache so that we always rerun the installs below
ADD https://loripsum.net/api /opt/docker/etc/gibberish

# Resolves a nasty NOKEY warning that appears when using yum.
# Naming convention changed with cos8 - see:
# * https://lists.centos.org/pipermail/centos-devel/2019-September/017847.html
# * https://www.centos.org/keys/#project-keys
RUN if [ "${DISTRO_NAME}${DISTRO_VER}" = "centos7" ]; then \
        rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7 && \
        rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-SIG-7-aarch64; \
    elif [ "${DISTRO_NAME}${DISTRO_VER}" = "centos8" ]; then \
        rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial; \
    elif [ "${DISTRO_NAME}${DISTRO_VER}" = "ubi8" ]; then \
        rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release; \
    fi

# Add custom `yum_clean_all` script before using `yum`
COPY scripts/yum_clean_all /opt/docker/bin/

# Fallback to CentOS vault for CentOS 8 support.
RUN if [ "${DISTRO_NAME}${DISTRO_VER}" = "centos8" ]; then \
        find /etc/yum.repos.d/ -name "CentOS-*.repo" -exec \
             sed -i 's/mirrorlist/#mirrorlist/g;s|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' {} \; && \
        yum update -y --disablerepo=cuda && \
        /opt/docker/bin/yum_clean_all; \
    fi

# Install basic requirements.
RUN yum update -y --disablerepo=cuda && \
    yum install -y \
        bzip2 \
        sudo \
        tar \
        which \
        && \
    /opt/docker/bin/yum_clean_all

# Fix locale in CentOS8 images
# See https://github.com/CentOS/sig-cloud-instance-images/issues/154
RUN if [ "${DISTRO_NAME}${DISTRO_VER}" = "centos8" ] || [ "${DISTRO_NAME}${DISTRO_VER}" = "ubi8" ]; then \
        yum install -y glibc-langpack-en \
        && \
        /opt/docker/bin/yum_clean_all; \
    fi

# Remove preinclude system compilers
RUN rpm -e --nodeps --verbose gcc gcc-c++

# Run common commands
COPY scripts/run_commands /opt/docker/bin/run_commands
RUN /opt/docker/bin/run_commands

# Download and cache CUDA related packages.
RUN source /opt/conda/etc/profile.d/conda.sh && \
    conda activate && \
    conda create -n test --yes --quiet --download-only \
        conda-forge::cudatoolkit=${CUDA_VER} \
        && \
    conda remove --yes --quiet -n test --all && \
    conda clean -tiy && \
    chgrp -R lucky /opt/conda && \
    chmod -R g=u /opt/conda

# Add a file for users to source to activate the `conda`
# environment `root`. Also add a file that wraps that for
# use with the `ENTRYPOINT`.
COPY linux-anvil-aarch64-cuda/entrypoint_source /opt/docker/bin/entrypoint_source
COPY scripts/entrypoint /opt/docker/bin/entrypoint

# Ensure that all containers start with tini and the user selected process.
# Activate the `conda` environment `root`.
# Provide a default command (`bash`), which will start if the user doesn't specify one.
ENTRYPOINT [ "/opt/conda/bin/tini", "--", "/opt/docker/bin/entrypoint" ]
CMD [ "/bin/bash" ]
