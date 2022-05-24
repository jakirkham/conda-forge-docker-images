# Note that this image doesn't cache cudatoolkit as it is not packaged by defaults.
# This docker image is meant for packages using CUDA driver and not for packages
# using the CUDA runtime.

ARG CUDA_VER
ARG DISTRO_VER
FROM --platform=linux/ppc64le nvidia/cuda:${CUDA_VER}-devel-centos${DISTRO_VER}

LABEL maintainer="conda-forge <conda-forge@googlegroups.com>"

# Add qemu in here so that we can use this image on regular linux hosts with qemu user installed
ADD qemu-ppc64le-static /usr/bin/qemu-ppc64le-static

# Set CUDA_VER during runtime.
ARG CUDA_VER
ARG DISTRO_VER
ENV CUDA_VER=${CUDA_VER} \
    DISTRO_VER=${DISTRO_VER}

# Set an encoding to make things work smoothly.
ENV LANG en_US.UTF-8
ENV LANGUAGE=en_US.UTF-8

# Set path to CUDA install.
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

# Resolves a nasty NOKEY warning that appears when using yum.
# Naming convention changed with cos8 - see:
# * https://lists.centos.org/pipermail/centos-devel/2019-September/017847.html
# * https://www.centos.org/keys/#project-keys
RUN if [ "$DISTRO_VER" -le "7" ]; then \
        rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-${DISTRO_VER} && \
        rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-SIG-AltArch-${DISTRO_VER}-ppc64le; \
    else \
        rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial; \
    fi

# Remove preinclude system compilers
RUN rpm -e --nodeps --verbose gcc gcc-c++

# Add custom `yum_clean_all` script before using `yum`
COPY scripts/yum_clean_all /opt/docker/bin/

# Fallback to CentOS vault for CentOS 8 support.
RUN if [ "$DISTRO_VER" -eq "8" ]; then \
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
RUN if [ "$DISTRO_VER" -ge "8" ]; then \
        yum install -y glibc-langpack-en \
        && \
        /opt/docker/bin/yum_clean_all; \
    fi

# Run common commands
COPY scripts/run_commands /opt/docker/bin/run_commands
RUN /opt/docker/bin/run_commands

# Download and cache new compiler packages.
# Should speedup installation of them on CIs.
RUN source /opt/conda/etc/profile.d/conda.sh && \
    conda activate && \
    conda create -n test --yes --quiet --download-only \
        conda-forge::binutils_impl_linux-ppc64le \
        conda-forge::binutils_linux-ppc64le \
        conda-forge::gcc_impl_linux-ppc64le \
        conda-forge::gcc_linux-ppc64le \
        conda-forge::gfortran_impl_linux-ppc64le \
        conda-forge::gfortran_linux-ppc64le \
        conda-forge::gxx_impl_linux-ppc64le \
        conda-forge::gxx_linux-ppc64le \
        conda-forge::libgcc-ng \
        conda-forge::libgfortran-ng \
        conda-forge::libstdcxx-ng && \
    conda remove --yes --quiet -n test --all && \
    conda clean -tiy && \
    chgrp -R lucky /opt/conda && \
    chmod -R g=u /opt/conda

# Download and cache CUDA related packages.
RUN if [[ "$CUDA_VER" == "9.2" || "$CUDA_VER" == "10.0" || "$CUDA_VER" == "10.1" ]]; then \
        echo "`cudatoolkit` not available for CUDA_VER<10.2"; \
    else \
        source /opt/conda/etc/profile.d/conda.sh && \
        conda activate && \
        conda create -n test --yes --quiet --download-only \
            conda-forge::cudatoolkit=${CUDA_VER} \
            && \
        conda remove --yes --quiet -n test --all && \
        conda clean -tiy && \
        chgrp -R lucky /opt/conda && \
        chmod -R g=u /opt/conda; \
    fi

# Add a file for users to source to activate the `conda`
# environment `root`. Also add a file that wraps that for
# use with the `ENTRYPOINT`.
COPY linux-anvil-ppc64le-cuda/entrypoint_source /opt/docker/bin/entrypoint_source
COPY scripts/entrypoint /opt/docker/bin/entrypoint

# Ensure that all containers start with tini and the user selected process.
# Activate the `conda` environment `root`.
# Provide a default command (`bash`), which will start if the user doesn't specify one.
ENTRYPOINT [ "/opt/conda/bin/tini", "--", "/opt/docker/bin/entrypoint" ]
CMD [ "/bin/bash" ]
