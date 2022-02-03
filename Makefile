
helm-lint: helm
	helm lint -f global-values.yaml lustre-aws-fsx/

chart: helm-lint
	helm package lustre-aws-fsx/
	helm repo index .

configmap: chart
	rm -rf cm
	mkdir -p cm
	cp lustre-aws-fsx-0.0.1.tgz cm/lustre-aws-fsx-0.0.1.tgz
	helm repo index cm --url=cm://lustre-aws-fsx/lustre-aws-fsx-chart
	oc create namespace lustre-aws-fsx || true
	oc delete cm/lustre-aws-fsx-chart
	oc create cm lustre-aws-fsx-chart --from-file=cm/index.yaml --from-file=cm/lustre-aws-fsx-0.0.1.tgz -n lustre-aws-fsx
	echo "set url: cm://lustre-aws-fsx/lustre-aws-fsx-chart"

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
