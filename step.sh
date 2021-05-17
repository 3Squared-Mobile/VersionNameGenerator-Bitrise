#!/bin/bash
set -ex

GITBRANCH=`git rev-parse --abbrev-ref HEAD`
echo "Branch: $GITBRANCH"
