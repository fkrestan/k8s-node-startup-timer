rounds=10

.PHONY: all
all: run clean

.PHONY: run
run: ## run the test in the configured kubernetes cluster
	./node-startup-timer.sh $(rounds)

.PHONY: clean
clean: ## cleanup the resoources created in the cluster
	tk delete --tla-code replicas=0 kubernetes/environments/node-startup-timer

.PHONY: fmt
fmt: ## auto-format the jsonnet source code
	tk fmt --verbose kubernetes/

