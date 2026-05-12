# Building PickyWatcher Locally

## Requirements

| Tool | Minimum version |
|------|----------------|
| macOS | 14.0 (Sonoma) |
| Xcode | 15.4 |

No third-party dependencies or package managers are needed.

## Steps

**1. Open the project**

```
open PickyWatcher.xcodeproj
```

Or double-click `PickyWatcher.xcodeproj` in Finder.

**2. Select a run destination**

In the Xcode toolbar, set the scheme to **PickyWatcher** and the destination to **My Mac**.

**3. Build and run**

Press **⌘R**, or go to **Product → Run**.

The project is configured with ad-hoc local signing (`-`) so no Apple Developer account or Team ID is required.

## Command-line build

```bash
xcodebuild -scheme PickyWatcher -configuration Debug build
```

The built app lands in `~/Library/Developer/Xcode/DerivedData/PickyWatcher-*/Build/Products/Debug/PickyWatcher.app`.

## Install to /Applications

### Via Xcode (Archive → Copy App)

This is the recommended flow for producing a production build.

**Before archiving — set up signing**

The project ships with no Development Team configured. Xcode requires one to archive.

1. Click the blue **PickyWatcher** icon at the top of the file navigator to open project settings.
2. Select the **PickyWatcher** target → **Signing & Capabilities** tab.
3. Tick **Automatically manage signing** and pick your Apple ID from the **Team** dropdown. A free Apple ID is sufficient for local use.

**Archive and export**

1. In the menu bar: **Product → Archive**. Xcode builds a Release binary and the **Organizer** window opens automatically.
2. Select the archive in the list and click **Distribute App**.
3. Choose **Copy App** (may be labelled **Direct Distribution** depending on your Xcode version) and click **Next**.
4. Pick a destination folder (e.g. the Desktop) and click **Export**.
5. Drag the exported `PickyWatcher.app` to `/Applications`.

### Via Terminal

```bash
# Build Release
xcodebuild -scheme PickyWatcher -configuration Release build

# Locate and copy the .app
APP=$(find ~/Library/Developer/Xcode/DerivedData/PickyWatcher-* \
      -name "PickyWatcher.app" -path "*/Release/*" | head -1)
cp -R "$APP" /Applications/
```

### First launch — Gatekeeper

Because the app is not notarized, macOS will block the first launch. To open it:

1. Right-click `PickyWatcher.app` in `/Applications` → **Open**.
2. Click **Open** in the dialog.

This only needs to be done once. Subsequent launches work normally.

## Sandboxing note

The app runs in the macOS App Sandbox with two entitlements:

- **Outbound network** — needed to download M3U8 playlists from URLs
- **App-scoped security bookmarks** — needed to remember recently opened files across launches

Both are already declared in `PickyWatcher/PickyWatcher.entitlements` and require no extra setup.
