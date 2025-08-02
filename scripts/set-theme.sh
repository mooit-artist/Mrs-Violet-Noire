#!/bin/bash
# set-theme.sh: Change the active theme for Mrs. Violet Noire website
# Usage: ./scripts/set-theme.sh [default|dark-academia|light-academia]

THEME_NAME="$1"
THEME_FILE=""

case "$THEME_NAME" in
  default)
    THEME_FILE="theme-default.css"
    ;;
  dark-academia)
    THEME_FILE="theme-dark-academia.css"
    ;;
  light-academia)
    THEME_FILE="theme-light-academia.css"
    ;;
  *)
    echo "Usage: $0 [default|dark-academia|light-academia]"
    exit 1
    ;;
esac

HTML_FILE="$(dirname "$0")/../index.html"
HTML_FILE=$(cd "$(dirname "$HTML_FILE")" && pwd)/$(basename "$HTML_FILE")

# Replace the theme stylesheet link in index.html
sed -i '' -E \
  "s|<link rel=\"stylesheet\" href=\"css/(style|theme-[a-z-]+)\.css\">|<link rel=\"stylesheet\" href=\"css/$THEME_FILE\">|g" \
  "$HTML_FILE"

echo "Theme set to $THEME_NAME ($THEME_FILE) in $HTML_FILE"

# Auto-commit the theme change
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git add "$HTML_FILE"
  git commit -m "chore(theme): set theme to $THEME_NAME ($THEME_FILE) via set-theme.sh"
  echo "Committed theme change to git."
else
  echo "Not a git repository. Skipping commit."
fi
