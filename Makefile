
helm-lint: helm
	cd chart; \
	helm lint -f global-values.yaml lustre-aws-fsx-0.0.1/

chart: helm-lint
	cd chart; \
	helm package lustre-aws-fsx-0.0.1/; \
	helm repo index .


helm:
ifeq (, $(shell which helm))
	@{ \
	set -e ;\
	HELM_GEN_TMP_DIR=$$(mktemp -d) ;\
	cd $$HELM_GEN_TMP_DIR ;\
	curl https://get.helm.sh/helm-v3.6.0-linux-amd64.tar.gz -o helm.tar.gz ;\
	tar xvfpz helm.tar.gz ;\
	mv linux-amd64/helm /usr/local/bin ;\
	chmod +x /usr/local/bin/helm ;\
	rm -rf $$HELM_GEN_TMP_DIR ;\
	}
HELM=/usr/local/bin/helm
else
HELM=$(shell which helm)
endif
