# Bing Daily — Cinnamon Applet

A Cinnamon panel applet that sets your desktop wallpaper to the **Bing Image of the Day** every morning. It keeps a local history of past images so you can browse backwards, runs completely in user-space (no root required), and works on both Linux Mint 21.x (Cinnamon 5.x) and Linux Mint 22.x (Cinnamon 6.x) without modification.

---

## Requirements

| Component | Provided by |
|-----------|-------------|
| Linux Mint 21.x or 22.x with Cinnamon | — |
| Python 3 (stdlib only — no pip) | Pre-installed on all Ubuntu/Mint |
| systemd (user session) | Pre-installed on all Ubuntu/Mint |
| `gsettings` | Pre-installed with Cinnamon |
| `xdg-open` | Pre-installed on all Ubuntu/Mint |

No additional packages need to be installed.

---

## Install

```bash
bash install.sh
```

That's it. The script:
- Copies the applet to `~/.local/share/cinnamon/applets/bing-daily@keithdriscoll.nyc/`
- Sets up the systemd timer for daily auto-update at 08:00
- Runs an initial refresh to download and set today's wallpaper

---

## Add the Applet to Your Panel

After running `install.sh`:

1. Right-click your Cinnamon panel
2. Select **Applets**
3. Find **Bing Daily** in the list and click the **+** button
4. Click **Done**

The applet icon will appear in your panel. Click it to open the menu.

---

## Applet Menu

| Item | Action |
|------|--------|
| Refresh Now | Fetch today's image immediately |
| ◀ Previous Image | Switch to an older image in history |
| ▶ Next Image | Switch to a newer image in history |
| Open Current Image | Open the image file in your default viewer |
| Image Info | Show title and copyright of the current image |
| Populate History | Download the last ~8 days of images in one shot |
| Clear All Images | Delete all cached images and reset history |
| Settings | Open the applet settings panel |
| About | Show version info |

---

## Engine Commands (Manual / Testing)

The Python engine works standalone — no Cinnamon required:

```bash
# Download today's wallpaper and set it
python3 ~/.local/share/cinnamon/applets/bing-daily@keithdriscoll.nyc/engine/bing_engine.py refresh

# Show info about the current image
python3 ~/.local/share/cinnamon/applets/bing-daily@keithdriscoll.nyc/engine/bing_engine.py info

# Navigate to a newer image
python3 ~/.local/share/cinnamon/applets/bing-daily@keithdriscoll.nyc/engine/bing_engine.py next

# Navigate to an older image
python3 ~/.local/share/cinnamon/applets/bing-daily@keithdriscoll.nyc/engine/bing_engine.py prev

# Bulk-download the last ~8 days of images
python3 ~/.local/share/cinnamon/applets/bing-daily@keithdriscoll.nyc/engine/bing_engine.py populate

# Clear all cached images
python3 ~/.local/share/cinnamon/applets/bing-daily@keithdriscoll.nyc/engine/bing_engine.py clear

# Open the current image in your viewer
python3 ~/.local/share/cinnamon/applets/bing-daily@keithdriscoll.nyc/engine/bing_engine.py open
```

---

## Settings

Open via the applet menu → **Settings**, or `cinnamon-settings applets bing-daily@keithdriscoll.nyc`.

| Setting | Default | Description |
|---------|---------|-------------|
| Auto-update | On | Enable/disable automatic refresh via systemd timer |
| Frequency | Daily | Update frequency: Daily, Weekly, or Monthly |
| Update time | 08:00 | Time of day for automatic refresh |
| Region | Global | Affects locally relevant imagery and holidays |
| History limit | 30 | Maximum number of wallpapers to keep on disk |

---

## File Locations

| Path | Contents |
|------|----------|
| `~/.local/share/cinnamon/applets/bing-daily@keithdriscoll.nyc/` | Applet code |
| `~/.cache/bing-daily/` | Downloaded images and history |
| `~/.cache/bing-daily/log.txt` | All events and errors |
| `~/.cache/bing-daily/history.json` | Image metadata history |
| `~/.config/systemd/user/bing-daily.{service,timer}` | systemd units |

---

## Troubleshooting

**Read the log:**
```bash
tail -f ~/.cache/bing-daily/log.txt
```

**Check the timer status:**
```bash
systemctl --user status bing-daily.timer
systemctl --user list-timers
```

**Manually trigger a refresh via systemd:**
```bash
systemctl --user start bing-daily.service
journalctl --user -u bing-daily.service -n 50
```

**Applet won't load / not showing in panel:**
Check for JavaScript errors:
```bash
cat ~/.xsession-errors | grep -i bing
```
Then reload Cinnamon: press `Alt+F2`, type `r`, press `Enter`.

**Wallpaper doesn't change after refresh:**
Confirm `gsettings` works for your user:
```bash
gsettings get org.cinnamon.desktop.background picture-uri
```

**Network errors:**
All images are fetched from Peapix. If the fetch fails, it is logged. Check your connection:
```bash
curl -s https://peapix.com/bing/feed?country=us | head -c 200
```

---

## Uninstall

```bash
# Disable and remove the timer
systemctl --user disable --now bing-daily.timer
rm ~/.config/systemd/user/bing-daily.service
rm ~/.config/systemd/user/bing-daily.timer
systemctl --user daemon-reload

# Remove the applet
rm -rf ~/.local/share/cinnamon/applets/bing-daily@keithdriscoll.nyc

# Optional: delete cached wallpapers and history
rm -rf ~/.cache/bing-daily
```

---

## How It Works

The applet itself contains no network code. All HTTP requests are made by the Python engine (`bing_engine.py`) which is called as a subprocess. This means:

- **No Soup2/Soup3 compatibility issues** — the applet works identically on Cinnamon 5.x and 6.x
- **Testable standalone** — the engine can be run from a terminal or cron without Cinnamon
- **Transparent logging** — every action and error is written to `log.txt`

Image source: **Peapix API** (`peapix.com/bing/feed`) — structured JSON, no Microsoft connection required.

The applet also automatically re-refreshes when your network becomes available after a reconnect (e.g. waking your laptop at a café), so you always get today's image even without the systemd timer firing.

---

## License

MIT License — see [LICENSE](../LICENSE).
