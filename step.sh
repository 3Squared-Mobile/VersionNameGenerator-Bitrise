#!/bin/bash
set -ex

GITBRANCH=`git rev-parse --abbrev-ref HEAD`

echo "Branch: $GITBRANCH"

if [[ "$GITBRANCH" = "main" || "$GITBRANCH" = "master" ]]; then
    echo `git describe --always`
else
    if [[ $GITBRANCH == release* || $GITBRANCH == hotfix* ]]; then
        IFS='/'
        read -a SPLIT <<< "$GITBRANCH"
        TYPE="${SPLIT[0]}"
        VERSION="${SPLIT[1]}"
        echo $VERSION
    else 
        PREVIOUS=`git tag -l '[0-9].*' --sort version:refname | tail -n1`
        if [ "$PREVIOUS" = "" ]; then
            echo "0.0.0"
        else 
            IFS='.'
            read -a SPLIT <<< "$GITBRANCH"
            TYPE="${SPLIT[0]}"
            VERSION="${SPLIT[1]}"
        fi
    fi
fi

