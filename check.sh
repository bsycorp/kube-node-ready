#!/bin/bash
set -e
error_trap() {
    echo "Error on line $1"
}
trap 'error_trap $LINENO' ERR
SCRIPT_PATH=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )

# looks up nodes with given node selectors, checks for healthy/ready pods of given daemonset and will then remove a taint if applicable
while getopts "ud:t:" option; do
  case $option in
    u) echo "usage: $(basename $0) [-d daemonset names (comma separated)] -t [node taint name]"; exit ;;
    d) DAEMONSETS=$OPTARG ;;
    t) NODE_TAINT=$OPTARG ;;
    ?) echo "error: option -$OPTARG is not implemented"; exit ;;
  esac
done

if [ -z "$NODE_TAINT" ]; then
    echo "No node taint configured"
    exit 1
fi

if [ -z "$DAEMONSETS" ]; then
    echo "No daemonsets configured"
    exit 1
else
    DAEMONSETS=$(echo $DAEMONSETS | tr ',' '\n')
fi

# will be a list of node names that have the applicable taint, one node per line with just the node name as the value
NODES_TEMPLATE=$(cat $SCRIPT_PATH/nodes.tmpl | sed "s|NODE_TAINT_NAME|$NODE_TAINT|g")
TAINTED_NODES=$(kubectl get nodes -o go-template="$NODES_TEMPLATE")
while read -r NODE; do
    # will be a list of pods, one pod per line, in format "namespace/podname,<N booleans representing container status>" for example 'kube-system/kube-dns,true,true,true', pods with unhealthy container statuses are removed so they don't match
    POD_STATUSES=$(kubectl get po --field-selector=spec.nodeName=$NODE --all-namespaces -o json | jq -r '.items[] | select(.metadata.ownerReferences[0] != null) | [(.metadata.namespace + "/" + .metadata.ownerReferences[0].name), .status.containerStatuses[].ready] | @csv'  | grep -v ",false" | sed 's|"||g')

    NODE_READY=true
    NODE_NOTREADY_REASON=""
    while read -r DAEMONSET; do
        DS_MATCH=false

        # check all pods, make sure we find at least one (should only be one since its a daemonset)
        while read -r POD_STATUS; do
            if [[ "$POD_STATUS" == "$DAEMONSET"* ]]; then
                DS_MATCH=true
                break
            fi
        done <<< "$POD_STATUSES"

        # if we dont find a match then fail the node and add to the reason
        if [ "$DS_MATCH" == "false" ]; then
            NODE_READY=false
            NODE_NOTREADY_REASON="$NODE_NOTREADY_REASON $DAEMONSET"
        fi
    done <<< "$DAEMONSETS"

    if [ "$NODE_READY" == "true" ]; then
        echo "Node: $NODE is ready and will be untainted!"
    else
        NODE_NOTREADY_REASON=$(echo $NODE_NOTREADY_REASON | xargs)
        echo "Node: $NODE is not ready yet ($NODE_NOTREADY_REASON are not ready)"
    fi

done <<< "$TAINTED_NODES"