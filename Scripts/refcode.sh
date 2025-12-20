#!/usr/bin/env bash

CHARS='ABCDEFGHJKMNPQRSTUVWXY23456789'
CHAR_COUNT=${#CHARS}

id=$(openssl rand 4 \
  | xxd -p \
  | fold -w2 \
  | while read -r byte; do
      idx=$((16#$byte % CHAR_COUNT))
      printf '%s' "${CHARS:idx:1}"
    done \
  | head -c 4)

# Copy to clipboard (no newline)
printf '%s' "\"$id\"" | pbcopy

echo "$id"
