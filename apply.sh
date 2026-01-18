#!/bin/bash
# input:
#  - path to module where to apply the template

set -e

# + + + + + input + + + + +
MODULE_PATH="$1"
TEMPLATE_RAW_DIR="$(dirname "$0")/template-raw"
TEMPLATE_DIR="$(dirname "$0")/template"

if [ -z "$MODULE_PATH" ]; then
  echo "Usage: $0 <module-path>"
  exit 1
fi
# - - - - - input - - - - -

# + + + + + git sanity checks + + + + +

if [ ! -d "$MODULE_PATH/.git" ]; then
  echo "Error: $MODULE_PATH is not a git repository"
  exit 10
fi

cd "$MODULE_PATH"

# Ensure we are on a branch (not detached HEAD)
if ! git symbolic-ref --quiet HEAD >/dev/null; then
  echo "Error: git repository is in detached HEAD state"
  exit 11
fi

# Ensure working tree is clean
if [ -n "$(git status --porcelain)" ]; then
  echo "Error: git working tree is not clean"
  git status --short
  exit 12
fi

# Ensure we have an upstream configured
if ! git rev-parse --abbrev-ref --symbolic-full-name @{u} >/dev/null 2>&1; then
  echo "Error: current branch has no upstream configured"
  exit 13
fi

# Fetch and check if branch is up to date
git fetch --quiet

LOCAL="$(git rev-parse @)"
REMOTE="$(git rev-parse @{u})"
BASE="$(git merge-base @ @{u})"

if [ "$LOCAL" != "$REMOTE" ]; then
  if [ "$LOCAL" = "$BASE" ]; then
    echo "Error: local branch is behind remote (pull first)"
    exit 14
  elif [ "$REMOTE" = "$BASE" ]; then
    echo "Error: local branch is ahead of remote (push first)"
    exit 15
  else
    echo "Error: local and remote branches have diverged"
    exit 16
  fi
fi

echo "Git repository is clean and up to date"

# go back to original directory for the rest of the script
cd - >/dev/null

# - - - - - git sanity checks - - - - -

# + + + + + raw files + + + + +

if [ ! -d "$TEMPLATE_RAW_DIR" ]; then
  echo "Error: template-raw directory not found at $TEMPLATE_RAW_DIR"
  exit 2
fi

# Copy all files and directories, including hidden ones, from template-raw to the module path
cp -rf "$TEMPLATE_RAW_DIR"/. "$MODULE_PATH"/

# - - - - - raw files - - - - -

# + + + + + template files + + + + +
POM_FILE="$MODULE_PATH/pom.xml"
if [ ! -f "$POM_FILE" ]; then
  echo "Error: pom.xml not found in $MODULE_PATH"
  exit 3
fi

# Extract <artifactId> from pom.xml
MODULE_NAME=$(grep -m1 '<artifactId>' "$POM_FILE" | sed 's/.*<artifactId>\(.*\)<\/artifactId>.*/\1/')
if [ -z "$MODULE_NAME" ]; then
  echo "Error: Could not extract <artifactId> from pom.xml"
  exit 4
fi

echo "Module name (artifactId) detected: $MODULE_NAME"

cp -rf "$TEMPLATE_DIR"/. "$MODULE_PATH"/

find "$MODULE_PATH" -type f -print0 | while IFS= read -r -d '' file; do
  # Skip binary files
  if grep -Iq . "$file"; then
    sed -i "s/TEMPLATE_NAME/$MODULE_NAME/g" "$file"
  fi
done
# - - - - - template files - - - - -

# + + + + + cleanup + + + + +
rm $MODULE_PATH/.github/workflows/maven.yml
# - - - - - cleanup - - - - -

# + + + + + commit + + + + +
cd "$MODULE_PATH"
git add .
git commit -m "build: apply maven-java-template"
# - - - - - commit - - - - -

echo "Template applied to $MODULE_PATH"
