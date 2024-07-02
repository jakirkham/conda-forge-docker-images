# Set `ARG`s for use in `FROM`.
ARG DISTRO_ARCH
ARG DISTRO_NAME
ARG DISTRO_VER
FROM --platform=linux/${DISTRO_ARCH} ${DISTRO_NAME}:${DISTRO_VER}

LABEL maintainer="conda-forge <conda-forge@googlegroups.com>"

# Set `ARG`s during build.
ARG DISTRO_ARCH
ARG DISTRO_NAME
ARG DISTRO_VER
ENV DISTRO_ARCH=${DISTRO_ARCH} \
    DISTRO_NAME=${DISTRO_NAME} \
    DISTRO_VER=${DISTRO_VER}

# Set an encoding to make things work smoothly.
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8

# bust the docker cache so that we always rerun the installs below
ADD https://loripsum.net/api /opt/docker/etc/gibberish

# Add qemu in here so that we can use this image on regular linux hosts with qemu user installed
ADD qemu-ppc64le-static /usr/bin/qemu-ppc64le-static

# Add the archived repo URL and fix RPM imports
ADD centos7-repos /tmp/centos7-repos
ADD scripts/fix_rpm /opt/docker/bin/fix_rpm
RUN /opt/docker/bin/fix_rpm

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

# Add a file for users to source to activate the `conda`
# environment `root`. Also add a file that wraps that for
# use with the `ENTRYPOINT`.
COPY linux-anvil-ppc64le/entrypoint_source /opt/docker/bin/entrypoint_source
COPY scripts/entrypoint /opt/docker/bin/entrypoint

# Ensure that all containers start with tini and the user selected process.
# Activate the `conda` environment `root`.
# Provide a default command (`bash`), which will start if the user doesn't specify one.
ENTRYPOINT [ "/opt/conda/bin/tini", "--", "/opt/docker/bin/entrypoint" ]
CMD [ "/bin/bash" ]
