---
name: desktop-app-interaction
description: Run, screenshot, and interact with desktop GUI applications (Bevy, Swing, GTK, etc.) using Xvfb, xdotool, and ImageMagick.
allowed-tools: Bash(Xvfb:*) Bash(xdotool:*) Bash(import:*) Bash(xwininfo:*) Bash(pkill:*) Bash(cargo:*) Bash(java:*)
---

# Desktop App Interaction

Run, screenshot, and interact with desktop GUI applications headlessly inside
the container. Uses Xvfb (virtual X11 display), Mesa lavapipe (software Vulkan),
xdotool (mouse/keyboard input), and ImageMagick (screenshots).

## Quick Start

```bash
# 1. Start the virtual display
Xvfb :99 -screen 0 1280x720x24 &

# 2. Launch the app in the background
cargo run &

# 3. Wait for the window to appear
sleep 3

# 4. Take a screenshot to see what rendered
import -window root /tmp/screenshot.png

# 5. View the screenshot (use the Read tool on the image file)

# 6. Interact with the app
xdotool mousemove 640 360 click 1

# 7. Take another screenshot to verify
import -window root /tmp/screenshot2.png

# 8. Clean up when done
pkill -f "cargo run" || true
pkill Xvfb || true
```

## Display Management

`DISPLAY=:99` is already set in the container environment.

```bash
# Start Xvfb with default 1280x720 resolution
Xvfb :99 -screen 0 1280x720x24 &

# Start with a larger resolution
Xvfb :99 -screen 0 1920x1080x24 &

# Start with a smaller resolution (faster rendering)
Xvfb :99 -screen 0 800x600x24 &

# Stop the virtual display
pkill Xvfb
```

Always start Xvfb **before** launching any GUI application.

## Screenshots

Screenshots are the primary way to see what the application is rendering.
Use ImageMagick's `import` command.

```bash
# Capture the entire virtual display
import -window root /tmp/screenshot.png

# Capture a specific window by name
xdotool search --name "My App" | head -1 | xargs -I{} import -window {} /tmp/window.png

# Capture a region (x, y, width, height)
import -window root -crop 400x300+100+50 /tmp/region.png

# Capture with a delay (useful if the app needs time to render)
sleep 2 && import -window root /tmp/screenshot.png
```

After taking a screenshot, use the **Read tool** to view the image file. This
lets you see what the application rendered and decide where to click or what
to type.

## Mouse Interaction

Use `xdotool` to send mouse events to the virtual display.

```bash
# Move mouse to coordinates and left-click
xdotool mousemove 640 360 click 1

# Right-click
xdotool mousemove 640 360 click 3

# Middle-click
xdotool mousemove 640 360 click 2

# Double-click
xdotool mousemove 640 360 click --repeat 2 1

# Click and hold (mousedown), then release (mouseup)
xdotool mousemove 100 200 mousedown 1
xdotool mousemove 300 400 mouseup 1

# Drag from one point to another
xdotool mousemove 100 200 mousedown 1 mousemove 300 400 mouseup 1

# Scroll up
xdotool mousemove 640 360 click 4

# Scroll down
xdotool mousemove 640 360 click 5
```

### Coordinate system

- Origin `(0, 0)` is the **top-left** corner of the screen.
- X increases to the right, Y increases downward.
- The maximum coordinates depend on the Xvfb screen resolution
  (e.g., 1280x720 means X: 0-1279, Y: 0-719).

## Keyboard Interaction

```bash
# Type a string of text
xdotool type "Hello, World!"

# Type with a delay between keystrokes (milliseconds)
xdotool type --delay 100 "slow typing"

# Press a single key
xdotool key Return
xdotool key Escape
xdotool key Tab
xdotool key BackSpace
xdotool key Delete
xdotool key space

# Arrow keys
xdotool key Up
xdotool key Down
xdotool key Left
xdotool key Right

# Key combinations
xdotool key ctrl+s          # Save
xdotool key ctrl+z          # Undo
xdotool key ctrl+shift+z    # Redo
xdotool key alt+F4          # Close window
xdotool key ctrl+c          # Copy
xdotool key ctrl+v          # Paste

# Function keys
xdotool key F1
xdotool key F11             # Fullscreen toggle

# Hold a key, perform action, release
xdotool keydown shift
xdotool mousemove 200 300 click 1
xdotool keyup shift
```

## Window Management

```bash
# List all windows
xdotool search --name "" getwindowname %@

# Find a window by name (partial match)
xdotool search --name "My App"

# Find a window by class
xdotool search --class "bevy"

# Focus/activate a window
xdotool search --name "My App" windowactivate

# Get the currently focused window
xdotool getactivewindow

# Get window geometry (position and size)
xdotool getactivewindow getwindowgeometry

# Move a window
xdotool search --name "My App" windowmove 0 0

# Resize a window
xdotool search --name "My App" windowsize 800 600

# Get detailed window info
xwininfo -root
xwininfo -id $(xdotool getactivewindow)
```

## Workflow: Iterative Development Loop

This is the recommended workflow for developing and testing GUI applications.

```bash
# 1. Start the virtual display (only once per session)
Xvfb :99 -screen 0 1280x720x24 &

# 2. Build and launch the app
cargo run &
APP_PID=$!
sleep 3

# 3. Take initial screenshot
import -window root /tmp/step1.png
# View with Read tool to see the initial state

# 4. Interact (e.g., click a button)
xdotool mousemove 400 300 click 1
sleep 1

# 5. Screenshot to verify the interaction
import -window root /tmp/step2.png
# View with Read tool to verify

# 6. More interactions as needed...
xdotool type "test input"
xdotool key Return
sleep 1
import -window root /tmp/step3.png

# 7. Stop the app when done
kill $APP_PID 2>/dev/null || true
wait $APP_PID 2>/dev/null || true

# 8. If code changes are needed, edit the code and repeat from step 2

# 9. Clean up when completely done
pkill Xvfb || true
```

## Workflow: Waiting for a Window

Some apps take time to create their window. Use this pattern to wait:

```bash
# Launch the app
cargo run &
APP_PID=$!

# Wait up to 10 seconds for a window to appear
for i in $(seq 1 20); do
  if xdotool search --name "." >/dev/null 2>&1; then
    break
  fi
  sleep 0.5
done

# Now interact with the app
import -window root /tmp/screenshot.png
```

## Troubleshooting

### Black or empty screenshot

The app may not have finished rendering. Add a longer `sleep` before
taking the screenshot, or wait for the window to appear using the
waiting pattern above.

### "cannot open display" error

Xvfb is not running. Start it first:

```bash
Xvfb :99 -screen 0 1280x720x24 &
```

### Vulkan/wgpu errors

The container uses Mesa lavapipe for software Vulkan rendering. If the app
reports Vulkan errors, ensure it is not trying to use a hardware GPU. For
Bevy apps, this should work automatically. If needed, force the Vulkan ICD:

```bash
export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/lvp_icd.x86_64.json
```

### App crashes immediately

- Check stderr output from the app for error messages.
- Ensure all required system libraries are installed.
- For Bevy apps, ensure the `bevy/x11` feature is enabled (not `bevy/wayland`).

### xdotool cannot find the window

- The window may not have been created yet. Use the waiting pattern.
- The window name may differ from expected. List all windows:
  ```bash
  xdotool search --name "" getwindowname %@
  ```

### Screenshot shows wrong resolution

Make sure the Xvfb resolution matches what you expect:

```bash
# Check current display info
xdpyinfo -display :99 | grep dimensions
```
