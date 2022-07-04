#!/usr/bin/env bash

set -euo pipefail

screen_name=$1

# block the user first
output=$(twurl -X POST "/1.1/blocks/create.json?screen_name=$screen_name&include_entities=false&skip_status=true")

error=$(echo "$output" | jq -c ".errors")

if [[ "$error" != "null" ]] ; then
  echo "$error" >/dev/stderr
  exit 1
fi

sleep 0.1

# then unblock the user -- effectively kicks the follower out
output=$(twurl -X POST "/1.1/blocks/destroy.json?screen_name=$screen_name&include_entities=false&skip_status=true")

error=$(echo "$output" | jq -c ".errors")

if [[ "$error" != "null" ]] ; then
  echo "$error" >/dev/stderr
  exit 1
fi
