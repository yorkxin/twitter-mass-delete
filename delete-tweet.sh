#!/usr/bin/env bash

set -euo pipefail

id=$1

output=$(twurl -X POST /1.1/statuses/destroy/"$id".json)

error=$(echo "$output" | jq -c ".errors")

if [[ "$error" != "null" ]] ; then
  echo "$error" >/dev/stderr
  exit 1
fi
