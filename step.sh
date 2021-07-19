#!/bin/bash
# set -x

# Make sure we have all tags. These aren't pulled down by default.
git fetch --tags

# Get current branch name.
GITBRANCH=`git rev-parse --abbrev-ref HEAD`

# Store the bash field seperator to be reset later. We use this to split strings.
OLDIFS=$IFS

GENERATED_VERSION_NAME=""
GENERATED_VERSION_NAME_DETAILED=""

TAG=`git describe --exact-match`
if [ "$TAG" != "" ]; then
    echo "Tag is $TAG, using as version."
    GENERATED_VERSION_NAME=$TAG
    GENERATED_VERSION_NAME_DETAILED=$TAG
else
    echo "Commit is not tagged, generating a version number."
    # If the branch name matches the git flow standard for releases or hotfixes, we can use the 2nd part of the branch name as the version.
    if [[ $GITBRANCH == release* || $GITBRANCH == hotfix* ]]; then
        # Setting the field seperator to / allows us to split the branch name.
        IFS='/'
        read -a SPLIT <<< "$GITBRANCH"
        TYPE="${SPLIT[0]}"
        VERSION="${SPLIT[1]}"

        echo "Building a $TYPE branch, version will be $VERSION."

        GENERATED_VERSION_NAME=$VERSION
        GENERATED_VERSION_NAME_DETAILED=$GENERATED_VERSION_NAME
    else 
        # If we're building any other branch, we compute a version number based on the previous one.
        echo "Branch is not a release or hotfix ($GITBRANCH)."

        PREVIOUS=`git tag -l '[0-9].*' --sort version:refname | tail -n1`
        if [ "$PREVIOUS" = "" ]; then
            # No tags!
            echo "No previous tags to base version on, version will be 0.0.0."
            GENERATED_VERSION_NAME="0.0.0"
            GENERATED_VERSION_NAME_DETAILED="$GENERATED_VERSION_NAME-wip"
        else 
            # Split the version number into 3 parts, increment minor.
            IFS='.'
            read -a SPLIT <<< "$PREVIOUS"
            MAJOR="${SPLIT[0]}"
            MINOR="${SPLIT[1]}"
            PATCH="${SPLIT[2]}"
            GENERATED_VERSION_NAME="$MAJOR.$((MINOR + 1)).0"
            GENERATED_VERSION_NAME_DETAILED="$GENERATED_VERSION_NAME-wip"

            echo "Previous tag is $PREVIOUS, version will increment minor value."
        fi
    fi
fi

IFS=$OLDIFS

envman add --key GENERATED_VERSION_NAME --value "${GENERATED_VERSION_NAME}"
envman add --key GENERATED_VERSION_NAME_DETAILED --value "${GENERATED_VERSION_NAME_DETAILED}"

echo "GENERATED_VERSION_NAME = $GENERATED_VERSION_NAME"
echo "GENERATED_VERSION_NAME_DETAILED = $GENERATED_VERSION_NAME_DETAILED"

exit 0