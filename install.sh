#!/usr/bin/env bash
# install.sh — Bing Daily Cinnamon Applet installer
# Idempotent: safe to run multiple times without damage.
set -euo pipefail

APPLET_ID="bing-daily@keithdriscoll.nyc"
APPLET_DEST="$HOME/.local/share/cinnamon/applets/$APPLET_ID"
CACHE_DIR="$HOME/.cache/bing-daily"
SYSTEMD_USER_DIR="$HOME/.config/systemd/user"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colour helpers — degrade gracefully when not a TTY
if [ -t 1 ]; then
    GREEN='\033[0;32m'
    RED='\033[0;31m'
    YELLOW='\033[1;33m'
    NC='\033[0m'
else
    GREEN=''; RED=''; YELLOW=''; NC=''
fi

ok()   { printf "${GREEN}✓${NC} %s\n" "$*"; }
fail() { printf "${RED}✗${NC} %s\n"   "$*"; }
info() { printf "${YELLOW}→${NC} %s\n" "$*"; }

# ---------------------------------------------------------------------------
# Step 0: Detect OS version
# ---------------------------------------------------------------------------
info "Detecting OS version..."
if [ -f /etc/linuxmint/info ]; then
    MINT_VERSION=$(grep '^RELEASE=' /etc/linuxmint/info | cut -d= -f2 | tr -d '"')
    ok "Linux Mint $MINT_VERSION"
elif [ -f /etc/os-release ]; then
    . /etc/os-release
    ok "$PRETTY_NAME"
else
    ok "Unknown OS (proceeding anyway)"
fi

# Check Python3
if ! command -v python3 &>/dev/null; then
    fail "python3 not found — please install it first"
    exit 1
fi
PYTHON_VER=$(python3 --version 2>&1)
ok "$PYTHON_VER"

# ---------------------------------------------------------------------------
# Step 1: Create applet directory
# ---------------------------------------------------------------------------
info "Creating applet directory..."
mkdir -p "$APPLET_DEST"
ok "Applet directory: $APPLET_DEST"

# ---------------------------------------------------------------------------
# Step 2: Copy applet files
# ---------------------------------------------------------------------------
info "Copying applet files..."
if command -v rsync &>/dev/null; then
    rsync -a --delete \
        --exclude='.git' \
        --exclude='install.sh' \
        "$SCRIPT_DIR/$APPLET_ID/" \
        "$APPLET_DEST/"
else
    cp -r "$SCRIPT_DIR/$APPLET_ID/." "$APPLET_DEST/"
fi
ok "Applet files copied"

# ---------------------------------------------------------------------------
# Step 3: Make engine executable
# ---------------------------------------------------------------------------
info "Setting engine permissions..."
chmod +x "$APPLET_DEST/engine/bing_engine.py"
ok "Engine executable: $APPLET_DEST/engine/bing_engine.py"

# ---------------------------------------------------------------------------
# Step 4: Create cache directory
# ---------------------------------------------------------------------------
info "Creating cache directory..."
mkdir -p "$CACHE_DIR"
ok "Cache directory: $CACHE_DIR"

# ---------------------------------------------------------------------------
# Step 5: Create systemd user directory
# ---------------------------------------------------------------------------
info "Creating systemd user directory..."
mkdir -p "$SYSTEMD_USER_DIR"
ok "systemd user directory: $SYSTEMD_USER_DIR"

# ---------------------------------------------------------------------------
# Step 6: Install systemd units
# ---------------------------------------------------------------------------
info "Installing systemd units..."
cp "$APPLET_DEST/systemd/bing-daily.service" "$SYSTEMD_USER_DIR/"
cp "$APPLET_DEST/systemd/bing-daily.timer"   "$SYSTEMD_USER_DIR/"
ok "systemd units installed"

# ---------------------------------------------------------------------------
# Step 7: Reload systemd
# ---------------------------------------------------------------------------
info "Reloading systemd user daemon..."
if systemctl --user daemon-reload 2>/dev/null; then
    ok "systemd user daemon reloaded"
else
    fail "systemctl --user daemon-reload failed (non-fatal, continuing)"
fi

# ---------------------------------------------------------------------------
# Step 8: Enable and start timer
# ---------------------------------------------------------------------------
info "Enabling bing-daily.timer..."
if systemctl --user enable --now bing-daily.timer 2>/dev/null; then
    ok "bing-daily.timer enabled and started"
else
    fail "Could not enable timer (systemd may not be running — you can enable it manually)"
fi

# ---------------------------------------------------------------------------
# Step 9: Initial refresh
# ---------------------------------------------------------------------------
info "Running initial wallpaper refresh (may take a moment)..."
if python3 "$APPLET_DEST/engine/bing_engine.py" refresh; then
    ok "Initial refresh complete"
else
    fail "Initial refresh failed — check $CACHE_DIR/log.txt for details"
fi

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------
printf "\n${GREEN}✓ Installation complete!${NC}\n\n"
cat <<'INSTRUCTIONS'
To activate the applet:
  1. Right-click your Cinnamon panel
  2. Select "Applets"
  3. Find "Bing Daily" and click the + button
  4. Click "Done"

To test manually:
  python3 ~/.local/share/cinnamon/applets/bing-daily@keithdriscoll.nyc/engine/bing_engine.py refresh

Logs:  ~/.cache/bing-daily/log.txt
INSTRUCTIONS
