#!/usr/bin/env bash

set -euo pipefail

function getPage() {
  local handle=$1
  local filename=$2
  local max_id=$3

  url="/1.1/statuses/user_timeline.json?screen_name=$handle&trim_user=1&include_rts=1&count=200"

  if [[ "$max_id" != "0" ]]; then
    url="$url&max_id=$max_id"
  fi

  twurl "$url" | jq -c -M '.[] | {id_str,created_at,text}' > "$filename"
}

function run() {
  local handle=$1
  local i=0
  local max_id="0"

  while true; do
    local filename="tweets.$i.jsonl"

    if getPage "$handle" "$filename" "$max_id"; then
      count=$(wc -l < $filename | awk '{print $1}')
      max_id=$(tail -n 1 $filename | jq --raw-output ".id_str")
      if [[ "$max_id" == "" || "$count" == "1" ]] ; then
        echo "reached end"
        exit 0
      fi
      echo "got $filename, count: $count, last id: $max_id"
    else
      exit 1
    fi

    sleep 0.2
    ((i++))
  done
}

run "$1"
