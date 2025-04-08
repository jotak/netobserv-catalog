ARG OPM_IMAGE=quay.io/operator-framework/opm:v1.51.0
FROM $OPM_IMAGE

ARG COMMIT
ARG CATALOG_PATH

COPY $CATALOG_PATH /configs/netobserv-operator

# Configure the entrypoint and command
ENTRYPOINT ["/bin/opm"]
CMD ["serve", "/configs", "--cache-dir=/tmp/cache"]

RUN ["/bin/opm", "serve", "/configs", "--cache-dir=/tmp/cache", "--cache-only"]

# Set DC-specific label for the location of the DC root directory
# in the image
LABEL operators.operatorframework.io.index.configs.v1=/configs

LABEL com.redhat.component="network-observability-operator-catalog-container"
LABEL name="network-observability-operator-catalog"
LABEL io.k8s.display-name="Network Observability Operator Catalog"
LABEL io.k8s.description="Network Observability Operator Catalog"
LABEL summary="Network Observability Operator Catalog"
LABEL maintainer="support@redhat.com"
LABEL io.openshift.tags="network-observability-operator-catalog"
LABEL upstream-vcs-ref="$COMMIT"
LABEL upstream-vcs-type="git"
LABEL description="Network Observability operator for OpenShift."
LABEL version="1.9.0"
