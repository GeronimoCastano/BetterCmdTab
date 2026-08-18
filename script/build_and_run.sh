#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
APP_NAME="BetterCmdTab Debug"
SCHEME="BetterCmdTab Debug"
CONFIGURATION="Debug"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DERIVED_DATA="$ROOT_DIR/build/codex-derived-data"
APP_BUNDLE="$DERIVED_DATA/Build/Products/$CONFIGURATION/$APP_NAME.app"
APP_BINARY="$APP_BUNDLE/Contents/MacOS/$APP_NAME"
INSTALL_APP_BUNDLE="/Applications/BetterCmdTab Personal.app"

pkill -x "$APP_NAME" >/dev/null 2>&1 || true

xcodebuild \
  -project "$ROOT_DIR/BetterCmdTab.xcodeproj" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -destination 'platform=macOS' \
  -derivedDataPath "$DERIVED_DATA" \
  CODE_SIGN_STYLE=Manual \
  CODE_SIGN_IDENTITY=- \
  DEVELOPMENT_TEAM= \
  build

open_app() {
  /usr/bin/open -n "$APP_BUNDLE"
}

case "$MODE" in
  run)
    open_app
    ;;
  --debug|debug)
    lldb -- "$APP_BINARY"
    ;;
  --logs|logs)
    open_app
    /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
    ;;
  --telemetry|telemetry)
    open_app
    /usr/bin/log stream --info --style compact --predicate 'subsystem == "pro.bettercmdtab.BetterCmdTab"'
    ;;
  --verify|verify)
    open_app
    sleep 1
    pgrep -x "$APP_NAME" >/dev/null
    ;;
  --install|install)
    if [[ -e "$INSTALL_APP_BUNDLE" && ! -d "$INSTALL_APP_BUNDLE" ]]; then
      echo "install target exists and is not an app bundle: $INSTALL_APP_BUNDLE" >&2
      exit 1
    fi
    /usr/bin/ditto "$APP_BUNDLE" "$INSTALL_APP_BUNDLE"
    /usr/bin/codesign --verify --deep --strict "$INSTALL_APP_BUNDLE"
    /usr/bin/open -n "$INSTALL_APP_BUNDLE"
    sleep 1
    pgrep -x "$APP_NAME" >/dev/null
    ;;
  *)
    echo "usage: $0 [run|--debug|--logs|--telemetry|--verify|--install]" >&2
    exit 2
    ;;
esac
