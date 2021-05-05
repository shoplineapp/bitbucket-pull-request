#!/bin/sh

set -e

if [ -z "$BITBUCKET_CLIENT_ID" ] || [ -z "$BITBUCKET_SECRET" ]; then
    echo "lack of Bitbucket access key or secret"
    exit 1
fi

set -x

origin_branch=$(git rev-parse --abbrev-ref HEAD)
repo=$(basename -s .git `git config --get remote.origin.url`)

# get access token
token=$(curl -X POST -u "${BITBUCKET_CLIENT_ID}:${BITBUCKET_SECRET}" \
  https://bitbucket.org/site/oauth2/access_token \
  -d grant_type=client_credentials | jq .access_token -M -r)

response=$(curl --location --request POST "https://api.bitbucket.org/2.0/repositories/starlinglabs/${repo}/pullrequests" \
--header "Authorization: Bearer ${token}" \
--header "Content-Type: application/json" \
--data-raw "{
    \"title\": \"version update\",
    \"state\": \"OPEN\",
    \"open\": true,
    \"closed\": false,
    \"source\": {
        \"branch\": {
            \"name\": \"${TARGET_BRANCH}\"
        }
    },
    \"destination\": {
        \"branch\": {
            \"name\": \"${origin_branch}\"
        }
    }
}")

type=$(echo "$response" | jq .type -M -r)
if [ "$type" = "error" ]; then
  echo "$response" | jq .error.message
  exit 1
elif [ "$type" = "pullrequest" ]; then
  echo "PR link: $response" | jq .links.html.href -r -M
fi