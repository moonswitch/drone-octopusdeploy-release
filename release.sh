#!/bin/bash

set -euo pipefail

PROGNAME=$(basename $0)

err_report () {
    echo "${PROGNAME}: ${2:-"Unknown Error"} at line $1" 1>&2
	exit 1
}

trap 'err_report $LINENO' ERR

send_req () {
    local calling_func=$(caller)
    local url="${1}"
    local data="${2:-nothing}"
    local headers="content-type:application/json accept:application/json X-Octopus-ApiKey:${API_KEY}"

    trap 'err_report $LINENO "Error requesting url $url with data $data"' ERR

    if [[ "${data}" != "nothing" ]]; then
        echo "${data}" | http --check-status --body POST ${url} ${headers}
    else 
        http --check-status --body --ignore-stdin ${url} ${headers}
    fi
}

PROJECT_SLUG="${PLUGIN_PROJECT_SLUG}"
VERSION="${PLUGIN_VERSION}"
SERVER_URL="${PLUGIN_SERVER_URL}"
API_KEY="${PLUGIN_API_KEY}"
STEP_NAME="${PLUGIN_STEP_NAME}"
ENVIRONMENT_NAME="${PLUGIN_ENVIRONMENT_NAME}"
CHANNEL_ID="${PLUGIN_CHANNEL_ID:-Channels-1}"
SPACE_ID="${PLUGIN_SPACE_ID:-Spaces-1}"

ENVIRONMENT_ID=$(send_req "${SERVER_URL}/api/${SPACE_ID}/environments/all" | jq --arg env_name "${ENVIRONMENT_NAME}" -r '.[] | select(.Name == $env_name) | .Id')

echo "${ENVIRONMENT_ID}"

PROJECT_ID=$(send_req "${SERVER_URL}/api/${SPACE_ID}/projects/${PROJECT_SLUG}" \
    | jq -r '.Id')

echo "${PROJECT_ID}"


RELEASE_REQUEST_BODY="{\"ProjectId\":\"${PROJECT_ID}\",\"ChannelId\":\"${CHANNEL_ID}\",\"Version\":\"${VERSION}\",\"SelectedPackages\":[{\"StepName\":\"${STEP_NAME}\", \"Version\":\"${VERSION}\"}]}"
echo $RELEASE_REQUEST_BODY

RELEASE_ID=$(send_req "${SERVER_URL}/api/${SPACE_ID}/releases?ignoreChannelRules=false" "${RELEASE_REQUEST_BODY}" \
    | jq -r '.Id')

echo "${RELEASE_ID}"

DEPLOYMENT_REQUEST_BODY="{\"ReleaseId\":\"${RELEASE_ID}\",\"EnvironmentId\":\"${ENVIRONMENT_ID}\"}"
echo $DEPLOYMENT_REQUEST_BODY

DEPLOYMENT_ID=$(send_req "${SERVER_URL}/api/${SPACE_ID}/deployments" "${DEPLOYMENT_REQUEST_BODY}" \
    | jq -r '.Id')

echo "${DEPLOYMENT_ID}"
