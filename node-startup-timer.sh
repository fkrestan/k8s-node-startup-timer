#!/usr/bin/env bash

set -euo pipefail

readonly ROUNDS="${1:-10}"
readonly NAME="node-startup-timer"
readonly TK_ENV="kubernetes/environments/${NAME}"
readonly CTX=$(jq -r '.spec.contextNames[0]' "${TK_ENV}/spec.json")
readonly OUT_DIR=$(mktemp -d -p /tmp node-startup-timer.XXXXXXXXXX)
readonly OUT_TTS="${OUT_DIR}/time-to-schedule.csv"
readonly OUT_TTR="${OUT_DIR}/time-to-run.csv"

pinfo() {
  printf "[+] %s\n" "$*"
}

datediff() {
    local d1=$(date -d "$1" +%s)
    local d2=$(date -d "$2" +%s)
    printf "%d\n" "$(( d1 - d2 ))"
}

pstat() {
    sta --transpose --delimiter '=' \
        --min --max --p 50 --p 80 --p 99 --sd  <"$1"
}


pinfo "Raw measurements will be written to \"$OUT_DIR/\""

pinfo "Creating support API resources in the Kubernetes cluster context \"$CTX\""
tk apply --tla-code replicas="0" "$TK_ENV"

for i in $(seq "$ROUNDS"); do
	tk apply --auto-approve always --tla-code replicas="$i" "$TK_ENV"
    kubectl wait --context "$CTX" --for=condition=Ready --timeout 600s \
        --namespace "$NAME" "Pod/${NAME}-$((i - 1))"
    pod=$(kubectl get --context "$CTX" --namespace "$NAME" "Pod/${NAME}-$((i - 1))" -o json)
    pod_created=$(echo $pod | jq -r '.metadata.creationTimestamp')
    pod_scheduled=$(echo $pod | jq -r '.status.conditions[] | select(.type=="PodScheduled") | .lastTransitionTime')
    pod_running=$(echo $pod | jq -r '.status.conditions[] | select(.type=="Ready") | .lastTransitionTime')
    datediff "$pod_scheduled" "$pod_created" >>"$OUT_TTS"
    datediff "$pod_running" "$pod_created" >>"$OUT_TTR"
done
pinfo 'Testing done'

pinfo 'Time-to-scheduled statistics:'
pstat "$OUT_TTS"
pinfo 'Time-to-running statistics:'
pstat "$OUT_TTR"
