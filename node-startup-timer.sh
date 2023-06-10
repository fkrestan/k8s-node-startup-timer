#!/usr/bin/env bash

set -euo pipefail

readonly ROUNDS="${1:-10}"
readonly NAME="node-startup-timer"
readonly TK_ENV="kubernetes/environments/${NAME}"
readonly CTX=$(jq -r '.spec.contextNames[0]' "${TK_ENV}/spec.json")
readonly OUT=$(mktemp  -p /tmp tmp.node-startup.timer.XXXXXXXXXX)

pinfo() {
  printf "[+] %s\n" "$*"
}

datediff() {
    d1=$(date -d "$1" +%s)
    d2=$(date -d "$2" +%s)
    printf "%d\n" "$(( d1 - d2 ))"
}

cleanup() {
    pinfo "Cleaning up created Kubernetes API resources"
    tk delete --auto-approve always --tla-code replicas="0" "$TK_ENV"
    pinfo "Done"
}


trap cleanup INT EXIT
pinfo "Raw measurements will be written to" "$OUT"
pinfo "Creating support API resources in the Kubernetes cluster context=" "$CTX"
tk apply --tla-code replicas="0" "$TK_ENV"
for i in $(seq "$ROUNDS"); do
	tk apply --auto-approve always --tla-code replicas="$i" "$TK_ENV"
    kubectl wait --context "$CTX" --for=condition=Ready --timeout 600s \
        --namespace "$NAME" "Pod/${NAME}-$((i - 1))"
    pod=$(kubectl get --context "$CTX" --namespace "$NAME" "Pod/${NAME}-$((i - 1))" -o json)
    pod_created=$(echo $pod | jq -r '.metadata.creationTimestamp')
    pod_running=$(echo $pod | jq -r '.status.conditions[] | select(.type=="Ready") | .lastTransitionTime')
    datediff "$pod_running" "$pod_created" >>"$OUT"
done

pinfo 'Testing done'
sta --min --max --p 50 --p 80 --p 99 --sd --transpose --delimiter '=' <"$OUT"
