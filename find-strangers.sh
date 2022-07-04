#!/usr/bin/env bash

diff --new-line-format="" --unchanged-line-format="" <(cat followers.*.jsonl | sort -u) <(cat followings.*.jsonl | sort -u)
