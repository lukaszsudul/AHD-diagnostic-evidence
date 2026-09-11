#!/bin/sh
set -eu
if [ "$#" -ne 2 ]; then
  echo "usage: $0 SOURCE OUTPUT" >&2
  exit 2
fi
source_path=$1
output_path=$2
case "$source_path:$output_path" in
  /*:/*) ;;
  *) echo "absolute paths required" >&2; exit 2 ;;
esac
test -f "$source_path"
test ! -e "$output_path"
umask 077
cc -O2 -Wall -Wextra -std=c11 -o "$output_path" "$source_path" -lrt
chmod 700 "$output_path"
file "$output_path"
sha256sum "$source_path" "$output_path"
