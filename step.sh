#!/bin/bash
set -x

# Make sure we have all tags. These aren't pulled down by default.
git fetch --tags

# Get current branch name.
GITBRANCH=`git rev-parse --abbrev-ref HEAD`

# Store the bash field seperator to be reset later. We use this to split strings.
OLDIFS=$IFS

# If we're on main, the commit should be tagged, so a simple git describe will do.
if [[ "$GITBRANCH" = "main" || "$GITBRANCH" = "master" ]]; then
    DESCRIBE=`git describe`
    # describe can fail if there are no tags.
    if [ "$DESCRIBE" == "" ]; then
        GENERATED_VERSION_NAME="0.0.0"
    else
        GENERATED_VERSION_NAME=$DESCRIBE
    fi
else
    # If the branch name matches the git flow standard for releases or hotfixes, we can use the 2nd part of the branch name as the version.
    if [[ $GITBRANCH == release* || $GITBRANCH == hotfix* ]]; then
        # Setting the field seperator to / allows us to split the branch name.
        IFS='/'
        read -a SPLIT <<< "$GITBRANCH"
        TYPE="${SPLIT[0]}"
        VERSION="${SPLIT[1]}"
        GENERATED_VERSION_NAME=$VERSION
    else 
        # If we're building any other branch, we compute a version number based on the previous one.
        PREVIOUS=`git tag -l '[0-9].*' --sort version:refname | tail -n1`
        if [ "$PREVIOUS" = "" ]; then
            # No tags!
            GENERATED_VERSION_NAME="0.0.0"
        else 
            # Split the version number into 3 parts, increment minor.
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