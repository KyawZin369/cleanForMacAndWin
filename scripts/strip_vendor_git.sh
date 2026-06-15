#!/bin/sh
# Remove nested git metadata from a vendored dependency directory.
set -e

TARGET="${1:?usage: strip_vendor_git.sh <directory>}"

if [ ! -d "$TARGET" ]; then
  echo "strip_vendor_git: not a directory: $TARGET" >&2
  exit 1
fi

if [ -d "$TARGET/.git" ]; then
  rm -rf "$TARGET/.git"
  echo "Removed nested .git from $TARGET"
fi

if [ -f "$TARGET/.git" ]; then
  rm -f "$TARGET/.git"
  echo "Removed nested .git file from $TARGET"
fi
