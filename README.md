# PickyWatcher

A fast, native macOS app for filtering and exporting M3U/M3U8 IPTV playlists.

![macOS](https://img.shields.io/badge/macOS-14.0%2B-blue) ![Swift](https://img.shields.io/badge/Swift-5.9-orange)

## Features

- **Open any M3U/M3U8 file** — loads playlists of any size with a live progress bar
- **Parallel search** — splits entries across all available CPU cores via Swift's `TaskGroup`; search index is pre-built at load time so queries return in milliseconds
- **Streams tab** — browse, search, and multi-select individual streams (click to select, ⌘-click to add to selection)
- **Groups tab** — browse all `group-title` groups, expand any group to preview its streams, select one group and export it as a standalone playlist
- **Export** — save filtered/selected streams or a whole group to a new `.m3u8` file, preserving the original `#EXTM3U` header

## Usage

1. Click **Open…** (or press ⌘O) and pick an `.m3u` or `.m3u8` file
2. Wait for indexing to complete (progress bar shown for large files)
3. **Streams tab**: type a query and press Enter or click **Search** — results filter by name and group title; click **×** to clear and restore the full list
4. **Groups tab**: search by group title, click a group row to select it for export, click the chevron to expand and preview its streams
5. Click **Export…** to save the selected streams or group

## Performance notes

| Technique | Why |
|---|---|
| Pre-computed `searchIndex` per entry | Avoids repeated regex + string splits during search |
| `withTaskGroup` across all CPU cores | Parallelises the `.contains` scan across large playlists |
| `groupedEntries` built once at load time | Eliminates main-thread recomputation when switching groups |
| `LazyVStack` in `ScrollView` | Only renders rows visible in the viewport |

## Requirements

- macOS 14.0 or later
- Xcode 15 or later

## Building

```
open PickyWatcher.xcodeproj
```

Then press ⌘R.
