FROM condaforge/linux-anvil-comp7

# Start fresh with a scratch image
# Then copy over the pieces from the previous image that are needed
FROM scratch
COPY --from=0 /lib64 /lib64
COPY --from=0 /bin/bash /bin/bash
COPY --from=0 /opt /opt
COPY --from=0 /home /home

# Ensure that all containers start with tini and the user selected process.
# Activate the `conda` environment `base` and the devtoolset compiler.
# Provide a default command (`bash`), which will start if the user doesn't specify one.
ENTRYPOINT [ "/opt/conda/bin/tini", "--", "/opt/docker/bin/entrypoint" ]
CMD [ "/bin/bash" ]
