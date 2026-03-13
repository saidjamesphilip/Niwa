#!/bin/bash
set -e

APP_NAME="Niwa"
REPO="saidjamesphilip/Niwa"
INSTALL_DIR="/Applications"

echo "Installing $APP_NAME..."

# Get latest release download URL
DOWNLOAD_URL=$(curl -sL "https://api.github.com/repos/$REPO/releases/latest" \
  | grep "browser_download_url.*\.zip" \
  | head -1 \
  | cut -d '"' -f 4)

if [ -z "$DOWNLOAD_URL" ]; then
  echo "Error: Could not find latest release."
  exit 1
fi

VERSION=$(echo "$DOWNLOAD_URL" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
echo "Found $APP_NAME v$VERSION"

# Download
TMPDIR=$(mktemp -d)
echo "Downloading..."
curl -sL "$DOWNLOAD_URL" -o "$TMPDIR/$APP_NAME.zip"

# Unzip
echo "Extracting..."
unzip -qo "$TMPDIR/$APP_NAME.zip" -d "$TMPDIR"

# Move to Applications
if [ -d "$INSTALL_DIR/$APP_NAME.app" ]; then
  echo "Removing previous version..."
  rm -rf "$INSTALL_DIR/$APP_NAME.app"
fi

mv "$TMPDIR/$APP_NAME.app" "$INSTALL_DIR/"

# Remove quarantine
xattr -cr "$INSTALL_DIR/$APP_NAME.app"

# Clean up
rm -rf "$TMPDIR"

echo ""
echo "$APP_NAME v$VERSION installed to $INSTALL_DIR"
echo "Look for the leaf icon in your menu bar."
echo ""
echo "To launch: open -a $APP_NAME"
