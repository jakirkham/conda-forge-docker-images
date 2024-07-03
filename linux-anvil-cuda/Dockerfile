# Set environment variables during runtime.
ARG CUDA_VER
ARG DISTRO_NAME
ARG DISTRO_VER
FROM --platform=linux/amd64 nvidia/cuda:${CUDA_VER}-devel-${DISTRO_NAME}${DISTRO_VER}

LABEL maintainer="conda-forge <conda-forge@googlegroups.com>"

ARG CUDA_VER
ARG DISTRO_NAME
ARG DISTRO_VER
ENV CUDA_VER=${CUDA_VER} \
    DISTRO_NAME=${DISTRO_NAME} \
    DISTRO_VER=${DISTRO_VER}

# Set an encoding to make things work smoothly.
ENV LANG en_US.UTF-8

# Set path to CUDA install (this is a symlink to /usr/local/cuda-${CUDA_VER})
ENV CUDA_HOME /usr/local/cuda

# we want to persist a path in ldconfig (to avoid having to always set LD_LIBRARY_PATH), but *after* the existing entries;
# since entries in ld.so.conf.d have precedence before the preconfigured directories, we first add the latter to the former
RUN ldconfig -v 2>/dev/null | grep -v ^$'\t' | cut -f1 -d":" >> /etc/ld.so.conf.d/cuda-$CUDA_VER.conf \
    && if [ ${CUDA_VER} != "9.2" ]; then \
        # the upstream images for 10.x all have libcuda.so under $CUDA_HOME/compat;
        # add this to the ldconfig so it will be found correctly.
        echo "$CUDA_HOME/compat" >> /etc/ld.so.conf.d/cuda-$CUDA_VER.conf ; \
    else \
        # For 9.2, the image nvidia/cuda:9.2-devel-centos6 contains neither
        # $CUDA_HOME/compat, nor any (non-stub) libcuda.so. We fix this by
        # adding cuda-compat-10.0 (which is not used for building, but to
        # test if loading the respective library/package works). However,
        # due to licensing reasons, these cannot be part of the conda-forge
        # docker images, but are instead added for CI purposes in:
        # github.com/conda-forge/conda-forge-ci-setup-feedstock/blob/master/recipe/run_conda_forge_build_setup_linux
        # Here we only set the ldconfig accordingly.
        echo "/usr/local/cuda-10.0/compat" >> /etc/ld.so.conf.d/cuda-$CUDA_VER.conf ; \
    fi \
    # don't forget to update settings by running ldconfig
    && ldconfig

# bust the docker cache so that we always rerun the installs below
ADD https://loripsum.net/api /opt/docker/etc/gibberish

# Add the archived repo URL and fix RPM imports
ADD centos7-repos /tmp/centos7-repos
ADD scripts/fix_rpm /opt/docker/bin/fix_rpm
RUN /opt/docker/bin/fix_rpm

# Install basic requirements.
COPY scripts/yum_clean_all /opt/docker/bin/
RUN yum update -y --disablerepo=cuda && \
    yum install -y \
        bzip2 \
        sudo \
        tar \
        which && \
    /opt/docker/bin/yum_clean_all

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

# Symlink CUDA headers that were moved from $CUDA_HOME/include to /usr/include
# in CUDA 10.1.
RUN for HEADER_FILE in cublas_api.h cublas.h cublasLt.h cublas_v2.h cublasXt.h nvblas.h; do \
    if [[ ! -f "${CUDA_HOME}/include/${HEADER_FILE}" ]]; \
      then ln -s "/usr/include/${HEADER_FILE}" "${CUDA_HOME}/include/${HEADER_FILE}"; \
    fi; \
    done

# Add qemu in here so that we can use this image on regular linux hosts with qemu user installed
ADD qemu-aarch64-static /usr/bin/qemu-aarch64-static
ADD qemu-ppc64le-static /usr/bin/qemu-ppc64le-static

# Add a file for users to source to activate the `conda`
# environment `base`. Also add a file that wraps that for
# use with the `ENTRYPOINT`.
COPY linux-anvil-cuda/entrypoint_source /opt/docker/bin/entrypoint_source
COPY scripts/entrypoint /opt/docker/bin/entrypoint

# Ensure that all containers start with tini and the user selected process.
# Activate the `conda` environment `base` and the devtoolset compiler.
# Provide a default command (`bash`), which will start if the user doesn't specify one.
ENTRYPOINT [ "/opt/conda/bin/tini", "--", "/opt/docker/bin/entrypoint" ]
CMD [ "/bin/bash" ]
