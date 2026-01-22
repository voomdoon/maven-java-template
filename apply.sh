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

echo ⏩ $MODULE_PATH ...

# + + + + + git sanity checks + + + + +

if [ ! -d "$MODULE_PATH/.git" ]; then
  echo "❌ $MODULE_PATH : not a git repository"
  exit 1
fi

cd "$MODULE_PATH"

# Ensure we are on a branch (not detached HEAD)
if ! git symbolic-ref --quiet HEAD >/dev/null; then
  echo "❌ $MODULE_PATH : git repository is in detached HEAD state"
  exit 1
fi

# Ensure working tree is clean
if [ -n "$(git status --porcelain)" ]; then
  echo "❌ $MODULE_PATH : git working tree is not clean"
  git status --short
  exit 1
fi

# Ensure we have an upstream configured
if ! git rev-parse --abbrev-ref --symbolic-full-name @{u} >/dev/null 2>&1; then
  echo "❌ $MODULE_PATH : current branch has no upstream configured"
  exit 1
fi

# Fetch and check if branch is up to date
git fetch --quiet

LOCAL="$(git rev-parse @)"
REMOTE="$(git rev-parse @{u})"
BASE="$(git merge-base @ @{u})"

if [ "$LOCAL" != "$REMOTE" ]; then
  if [ "$LOCAL" = "$BASE" ]; then
    echo "❌ $MODULE_PATH : local branch is behind remote (pull first)"
    exit 1
  elif [ "$REMOTE" = "$BASE" ]; then
    echo "❌ $MODULE_PATH : local branch is ahead of remote (push first)"
    exit 1
  else
    echo "❌ $MODULE_PATH : local and remote branches have diverged"
    exit 1
  fi
fi

echo "Git repository is clean and up to date"

# go back to original directory for the rest of the script
cd - >/dev/null

# - - - - - git sanity checks - - - - -

# + + + + + raw files + + + + +

if [ ! -d "$TEMPLATE_RAW_DIR" ]; then
  echo "❌ $MODULE_PATH : template-raw directory not found at $TEMPLATE_RAW_DIR"
  exit 1
fi

# Copy all files and directories, including hidden ones, from template-raw to the module path
cp -rf "$TEMPLATE_RAW_DIR"/. "$MODULE_PATH"/

# - - - - - raw files - - - - -

# + + + + + template files + + + + +
POM_FILE="$MODULE_PATH/pom.xml"
if [ ! -f "$POM_FILE" ]; then
  echo "❌ $MODULE_PATH : pom.xml not found in $MODULE_PATH"
  exit 1
fi

MODULE_NAME="$(cd "$MODULE_PATH" && mvn -q -N -DforceStdout help:evaluate -Dexpression=project.artifactId 2>&1 | tr -d '\r' | awk 'NF{last=$0} END{print last}')"

# Check for Maven error output
if [[ -z "$MODULE_NAME" || "$MODULE_NAME" == *"[ERROR]"* ]]; then
  echo "❌ $MODULE_PATH : Could not extract <artifactId> from pom.xml (Maven error: $MODULE_NAME)"
  exit 1
fi

echo "Module name: $MODULE_NAME"

# Escape special characters for sed (|, &, \)
ESCAPED_MODULE_NAME=$(printf '%s' "$MODULE_NAME" | sed -e 's/[|&\\]/\\&/g')

cp -rf "$TEMPLATE_DIR"/. "$MODULE_PATH"/

find "$MODULE_PATH" -type f -print0 | while IFS= read -r -d '' file; do
  # Skip binary files
  if grep -Iq . "$file"; then
    sed -i "s|TEMPLATE_NAME|$ESCAPED_MODULE_NAME|g" "$file"
  fi
done
# - - - - - template files - - - - -

# + + + + + cleanup + + + + +
rm --force $MODULE_PATH/.github/workflows/maven.yml
# - - - - - cleanup - - - - -

# + + + + + commit + + + + +
cd "$MODULE_PATH"
git add .

if git diff --cached --quiet; then
  echo "✅ $MODULE_PATH"
else
  git commit -m "build: apply maven-java-template"
  echo "⚠️ $MODULE_PATH : changes committed => push required"
fi
# - - - - - commit - - - - -

echo
