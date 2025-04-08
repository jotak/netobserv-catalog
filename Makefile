TARGETS ?= y-stream z-stream

IMAGE ?= quay.io/$(USER)/network-observability-operator-catalog:latest
BUILD_STREAM ?= y-stream
OCI_BIN_PATH := $(shell which docker 2>/dev/null || which podman)
OCI_BIN ?= $(shell basename ${OCI_BIN_PATH})

define generate-delta-target
	echo 'generating bundle delta for $(1)'; \
	mkdir -p "auto-generated/catalog/$(1)"; \
	mkdir -p "auto-generated/legacy-catalog/$(1)"; \
	cp "templates/$(1)/index.yaml" "auto-generated/catalog/$(1)"; \
	cp "templates/$(1)/index.yaml" "auto-generated/legacy-catalog/$(1)"; \
	yq 'del(select(.schema == "olm.channel"))' auto-generated/catalog/released.yaml > "auto-generated/catalog/$(1)/released.yaml"; \
	yq 'del(select(.schema == "olm.channel"))' auto-generated/legacy-catalog/released.yaml > "auto-generated/legacy-catalog/$(1)/released.yaml"; \
	opm render \
		$(shell cat "templates/$(1)/bundle-image") \
		--output=yaml \
		--migrate-level=bundle-object-to-csv-metadata \
		> "auto-generated/catalog/$(1)/delta.yaml"; \
	opm render \
		$(shell cat "templates/$(1)/bundle-image") \
		--output=yaml \
		> "auto-generated/legacy-catalog/$(1)/delta.yaml";
endef

.PHONY: prereqs
prereqs:
	go install github.com/operator-framework/operator-registry/cmd/opm@v1.51.0
	go install github.com/mikefarah/yq/v4@v4.35.2

.PHONY: generate-delta
generate-delta: prereqs
	$(foreach target,$(TARGETS),$(call generate-delta-target,$(target)))

.PHONY: generate-released
generate-released: prereqs
	rm -f ./auto-generated/catalog/*
	rm -f ./auto-generated/legacy-catalog/*
	for i in $(shell ls ./templates/); do \
		opm alpha render-template basic --migrate-level=bundle-object-to-csv-metadata  -o yaml ./templates/$$i > ./auto-generated/catalog/$$i; \
		opm alpha render-template basic -o yaml ./templates/$$i > ./auto-generated/legacy-catalog/$$i; \
	done

.PHONY: generate
generate: generate-released generate-delta

.PHONY: build-image
build-image:
	$(OCI_BIN) build --build-arg CATALOG_PATH="./auto-generated/catalog/$(BUILD_STREAM)" -t $(IMAGE) -f upstream.Dockerfile .

.PHONY: push-image
push-image:
	$(OCI_BIN) push ${IMAGE}

.PHONY: deploy
deploy:
	yq '.spec.image="$(IMAGE)"' ./catalog-source.yaml | kubectl apply -f -

.PHONY: undeploy
undeploy:
	kubectl delete -f ./catalog-source.yaml
