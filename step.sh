#!/bin/bash
# set -x

# Store the bash field seperator to be reset later. We use this to split strings.
OLDIFS=$IFS

# Get current branch name.
# If Bitrise env var (BITRISE_GIT_BRANCH) is not passed in, use git command.
if [[ -z "$BITRISE_GIT_BRANCH" ]]; then
    BRANCH=`git rev-parse --abbrev-ref HEAD`
    echo "BITRISE_GIT_BRANCH is undefined, using '$BRANCH'."
else
    BRANCH=$BITRISE_GIT_BRANCH
    echo "BITRISE_GIT_BRANCH is '$BRANCH'."
fi

# Get current tag.
# If Bitrise env var (BITRISE_GIT_TAG) is not passed in, use git command.
if [[ -z "$BITRISE_GIT_TAG" ]]; then
    # Make sure we have all tags. These aren't pulled down by default.
    git fetch --tags
    TAG=`git describe --exact-match`
    echo "BITRISE_GIT_TAG is undefined, using '$TAG'."
else
    TAG=$BITRISE_GIT_TAG
    echo "BITRISE_GIT_TAG is '$TAG'."
fi

GENERATED_VERSION_NAME=""
GENERATED_VERSION_NAME_DETAILED=""

if [ "$TAG" != "" ]; then
    echo "Tag is $TAG, using as version."
    GENERATED_VERSION_NAME=$TAG
    GENERATED_VERSION_NAME_DETAILED=$TAG
else
    echo "Commit is not tagged, generating a version number."

    PREVIOUS=`git tag -l '[0-9].*' --sort version:refname | tail -n1`
        if [ "$PREVIOUS" = "" ]; then
            # No tags!
            echo "No previous tags to base version on, version will be 0.0.0."
            VERSION_NAME="0.0.0"
        else
            # Split the version number into 3 parts, increment minor.
            IFS='.'
            read -a SPLIT <<< "$PREVIOUS"
            MAJOR="${SPLIT[0]}"
            MINOR="${SPLIT[1]}"
            PATCH="${SPLIT[2]}"
            VERSION_NAME="$MAJOR.$((MINOR + 1)).0"

            echo "Previous tag is $PREVIOUS, version will increment minor value."
        fi

    echo "Version name is $VERSION_NAME"

    # If the branch name matches the git flow standard for releases or hotfixes, we can use the 2nd part of the branch name as the version.
    if [[ $BRANCH == release* || $BRANCH == hotfix* || $BRANCH == feature* || $BRANCH == fix* ]]; then
        # Setting the field seperator to / allows us to split the branch name.
        IFS='/'
        read -a SPLIT <<< "$BRANCH"
        TYPE="${SPLIT[0]}"
        VERSION="${SPLIT[1]}"

        echo "Building a $TYPE branch, version will be $VERSION."

        IFS='-'
        read -a SPLIT_BRANCH_NAME <<< "$VERSION"

        for (( n=0; n < ${#SPLIT_BRANCH_NAME[*]}; n++))
        do
          echo "${SPLIT_BRANCH_NAME[n]}"
        done

        if [ "$VERSION_NAME" != "" ]; then
          GENERATED_VERSION_NAME="$VERSION_NAME-${SPLIT_BRANCH_NAME[0]}-${SPLIT_BRANCH_NAME[1]}-SNAPSHOT"
        else
          GENERATED_VERSION_NAME="0.0.0-${SPLIT_BRANCH_NAME[0]}-${SPLIT_BRANCH_NAME[1]}-SNAPSHOT"
        fi

        GENERATED_VERSION_NAME_DETAILED=$GENERATED_VERSION_NAME
    else 
        # If we're building any other branch, we compute a version number based on the previous one.
        echo "Branch is not a release or hotfix ($BRANCH)."

        GENERATED_VERSION_NAME=VERSION_NAME
        GENERATED_VERSION_NAME_DETAILED="$VERSION_NAME-SNAPSHOT"

    fi
fi

IFS=$OLDIFS

envman add --key GENERATED_VERSION_NAME --value "${GENERATED_VERSION_NAME}"
envman add --key GENERATED_VERSION_NAME_DETAILED --value "${GENERATED_VERSION_NAME_DETAILED}"

echo "GENERATED_VERSION_NAME = $GENERATED_VERSION_NAME"
echo "GENERATED_VERSION_NAME_DETAILED = $GENERATED_VERSION_NAME_DETAILED"

exit 0