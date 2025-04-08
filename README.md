# Netobserv Catalog

This repository build the Netobserv OLM catalog used to release new version of Openshift Network Observability Operator.

To generate all catalogs from template:
```bash
make generate
```

To build the catalog with released version:
```bash
podman build -t catalog .
```

To use a different generated catalog:
```bash
podman build --build-arg CATALOG_PATH=./auto-generated/catalog/y-stream -t catalog .
```
