FROM condaforge/linux-anvil-comp7

# Start fresh with a busybox image
# Then copy over the pieces from the previous image that are needed
FROM busybox
COPY --from=0 /opt /opt
COPY --from=0 /home /home

# Ensure that all containers start with tini and the user selected process.
# Activate the `conda` environment `base` and the devtoolset compiler.
# Provide a default command (`sh`), which will start if the user doesn't specify one.
ENTRYPOINT [ "/opt/conda/bin/tini", "--", "/opt/docker/bin/entrypoint" ]
CMD [ "/bin/sh" ]
