#!/bin/bash
set -ex

git fetch --tags

GITBRANCH=`git rev-parse --abbrev-ref HEAD`

OLDIFS=$IFS

if [[ "$GITBRANCH" = "main" || "$GITBRANCH" = "master" ]]; then
    GENERATED_VERSION_NAME=`git describe`
else
    if [[ $GITBRANCH == release* || $GITBRANCH == hotfix* ]]; then
        IFS='/'
        read -a SPLIT <<< "$GITBRANCH"
        TYPE="${SPLIT[0]}"
        VERSION="${SPLIT[1]}"
        GENERATED_VERSION_NAME=$VERSION
    else 
        PREVIOUS=`git tag -l '[0-9].*' --sort version:refname | tail -n1`
        if [ "$PREVIOUS" = "" ]; then
            GENERATED_VERSION_NAME="0.0.0"
        else 
            IFS='.'
            read -a SPLIT <<< "$PREVIOUS"
            MAJOR="${SPLIT[0]}"
            MINOR="${SPLIT[1]}"
            PATCH="${SPLIT[2]}"
            GENERATED_VERSION_NAME="$MAJOR.$((MINOR + 1)).0"
        fi
    fi
fi

IFS=$OLDIFS

envman add --key GENERATED_VERSION_NAME --value "${GENERATED_VERSION_NAME}"

exit 0