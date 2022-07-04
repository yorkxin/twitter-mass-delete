#!/usr/bin/env bash

set -euo pipefail

function getPage() {
  local handle=$1
  local filename=$2
  local cursor=$3

  url="/1.1/friends/list.json?screen_name=$handle&include_user_entities=false&skip_status=true&count=200&cursor=$cursor"

  twurl "$url" | tee -a "$filename.response.json" | jq -c -M '.users[] | {id_str,screen_name}' > "$filename"
}

function run() {
  local handle=$1
  local i=0
  local cursor="-1"

  while true; do
    local filename="followings.$i.jsonl"

    if getPage "$handle" "$filename" "$cursor"; then
      count=$(wc -l < $filename | awk '{print $1}')
      cursor=$(jq --raw-output ".next_cursor_str" < "$filename.response.json")
      unlink "$filename.response.json"
      if [[ "$cursor" == "0" ]] ; then
        echo "reached end"
        exit 0
      fi
      echo "got $filename, count: $count, next cursor: $cursor"
    else
      exit 1
    fi

    sleep 0.2
    ((i++))
  done
}

run "$1"
