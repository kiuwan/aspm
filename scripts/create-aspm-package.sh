#!/bin/bash
set -e

# Version must be provided by the Jenkins pipeline.
# Example:
#   ./create-aspm-package.sh 0.74.0

version="$1"

if [[ -z "$version" ]]; then
    echo "ERROR: ASPM version is required."
    echo "Usage: $0 <version>"
    exit 1
fi

if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "ERROR: Invalid version: $version"
    echo "Expected format: X.Y.Z"
    exit 1
fi

echo "========================================="
echo "Creating ASPM package"
echo "========================================="

echo "ASPM version: $version"

# Verify we are on the expected candidate branch.
expectedBranch="trivy/v${version}"
currentBranch=$(git branch --show-current)

echo ""
echo "Current branch:  $currentBranch"
echo "Expected branch: $expectedBranch"

if [[ "$currentBranch" != "$expectedBranch" ]]; then
    echo "ERROR: Workspace is not on the expected ASPM candidate branch."
    echo "Expected: $expectedBranch"
    echo "Actual:   $currentBranch"
    exit 1
fi

# Verify working tree is clean.
if [[ -n "$(git status --porcelain)" ]]; then
    echo ""
    echo "ERROR: Git working tree is not clean."
    git status
    exit 1
fi

# Create aspm.version
versionFile="dist/aspm.version"

echo ""
echo "Creating version file:"
echo "$versionFile"

echo -n "$version" > "$versionFile"

echo "Created $versionFile:"
cat "$versionFile"

# Verify required artifacts
requiredFiles=(
    "dist/aspm_${version}_windows.zip"
    "dist/aspm_${version}_linux.zip"
    "dist/aspm_${version}_mac.zip"
)

echo ""
echo "Verifying required artifacts..."

for file in "${requiredFiles[@]}"; do
    if [[ ! -f "$file" ]]; then
        echo "ERROR: Required artifact not found: $file"
        exit 1
    fi

    echo "Found: $file"
done

# Create final package
finalPackage="dist/aspm_${version}.zip"

rm -f "$finalPackage"

echo ""
echo "Creating final package:"
echo "$finalPackage"

zip -j "$finalPackage" \
    "$versionFile" \
    "dist/aspm_${version}_windows.zip" \
    "dist/aspm_${version}_linux.zip" \
    "dist/aspm_${version}_mac.zip"

echo ""
echo "========================================="
echo "Final ASPM package created successfully"
echo "========================================="

echo ""
echo "Package:"
echo "$finalPackage"

echo ""
echo "Contents:"
unzip -l "$finalPackage"