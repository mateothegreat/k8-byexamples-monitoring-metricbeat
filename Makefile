#                                 __                 __
#    __  ______  ____ ___  ____ _/ /____  ____  ____/ /
#   / / / / __ \/ __ `__ \/ __ `/ __/ _ \/ __ \/ __  /
#  / /_/ / /_/ / / / / / / /_/ / /_/  __/ /_/ / /_/ /
#  \__, /\____/_/ /_/ /_/\__,_/\__/\___/\____/\__,_/
# /____                     matthewdavis.io, holla!
#

NS                      ?= infra-monitoring
ELASTICSEARCH_HOST      ?= elasticsearch.es.svc.cluster.local
ELASTICSEARCH_PORT      ?= 9200
ELASTICSEARCH_USERNAME  ?= elasticsearch
ELASTICSEARCH_PASSWORD  ?= elasticsearch
export

install:    install-rbac install-configmap-metricbeat-daemonset-modules install-configmap-metricbeat-config install-configmap-metricbeat-deployment-modules install-daemonset install-deployment
delete:     delete-rbac delete-configmap-metricbeat-daemonset-modules delete-configmap-metricbeat-config delete-configmap-metricbeat-deployment-modules delete-daemonset delete-deployment

## Generate the default configuration file
conf:

	docker run --rm influxdb influxd config > influxdb.conf

####################################

install-%:

	@envsubst < manifests/$*.yaml | kubectl --namespace $(NS) apply -f -

delete-%:

	@envsubst < manifests/$*.yaml | kubectl --namespace $(NS) delete --ignore-not-found -f -

dump-%:

	envsubst < manifests/$*.yaml

#
# Help Outputs
GREEN  		:= $(shell tput -Txterm setaf 2)
YELLOW 		:= $(shell tput -Txterm setaf 3)
WHITE  		:= $(shell tput -Txterm setaf 7)
RESET  		:= $(shell tput -Txterm sgr0)
help:

	@echo "\nUsage:\n\n  ${YELLOW}make${RESET} ${GREEN}<target>${RESET}\n\nTargets:\n"
	@awk '/^[a-zA-Z\-\_0-9]+:/ { \
		helpMessage = match(lastLine, /^## (.*)/); \
		if (helpMessage) { \
			helpCommand = substr($$1, 0, index($$1, ":")-1); \
			helpMessage = substr(lastLine, RSTART + 3, RLENGTH); \
			printf "  ${YELLOW}%-20s${RESET} ${GREEN}%s${RESET}\n", helpCommand, helpMessage; \
		} \
	} \
	{ lastLine = $$0 }' $(MAKEFILE_LIST)

## Find first pod and follow log output
logs:

	@$(eval POD:=$(shell kubectl get pods --namespace $(NS) -lk8s-app=metricbeat -o jsonpath='{.items[0].metadata.name}'))
	echo $(POD)

	kubectl --namespace $(NS) logs -f $(POD)
