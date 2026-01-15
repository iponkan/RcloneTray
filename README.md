# Rclone Tray Manager (Portable Edition)

[🇨🇳 中文说明 (Read in Chinese)](./README_CN.md)

A lightweight, fully portable Windows system tray tool designed to manage [Rclone](https://rclone.org/) mounts. 
Built with PowerShell and Batch. No installation required—just unzip and run.

## 📂 Directory Structure

```text
RcloneTray/
│
├── RcloneTray.bat        <-- Startup Script (Double-click to initialize)
│
└── core/                 <-- [Core Folder] 
    ├── rclone.exe        <-- [NOTE] You MUST place the downloaded rclone.exe here!
    ├── tray.ps1
    ├── start.vbs
    └── ... (Config files will be generated here automatically)
```

## ✨ Key Features

- **System Tray Icon**: Minimizes to the system tray (using the native Rclone icon) for a clean workspace.
- **Web Dashboard**: Integrated Rclone Web UI. Double-click the tray icon to monitor transfer speeds and logs in real-time.
- **Smart Config Wizard**:
  - **Auto-list**: Automatically lists configured remotes (no need to type names manually).
  - **Auto-detect**: Detects free drive letters (e.g., Z:, X:) to prevent conflicts.
  - **Auto-assign**: Assigns free ports (5572, 5573...) allowing multiple instances to run simultaneously.
- **Silent Operation**: Completely hides the CMD window; runs quietly in the background.
- **True Portability**: All configurations are stored locally within the folder. You can put it on a USB drive and use it on different computers.
- **Smart Instance Control**: If the program is already running, clicking the shortcut again will intelligently open the Web Dashboard instead of launching a new instance.

## 🚀 Quick Start

### 1. Prerequisites

- **WinFsp**: `rclone mount` on Windows requires [WinFsp](https://github.com/winfsp/winfsp) to be installed. Please download and install it first.
- Windows 10 / 11.
- Download the **Windows version (zip)** from the [official Rclone website](https://rclone.org/downloads/).
- Unzip the download and **move `rclone.exe` into the `core/` folder of this project.**

### 2. Setup Steps

1. Double-click **`RcloneTray.bat`** in the root directory.
2. **Type [1]**: Enter the official Rclone configuration wizard to log in to your cloud storage (e.g., OneDrive, Google Drive, etc.).
3. **Type [2]**: Configure the mount.
   - The script will list your configured remotes and available drive letters.
   - Enter the remote name (e.g., `onedrive`) and drive letter (e.g., `Z`) as prompted.
4. **Type [3]**: Generate a **Desktop Shortcut**.
5. **Type [4]**: Enable **Start on Boot** (Recommended for daily use).

**Done!** You can now start the mount by double-clicking the desktop icon.

## 🕹️ Operations

Once started, a **Blue Cloud Icon** will appear in the system tray (bottom right taskbar).

- **Double Left-click**: Open the Web Dashboard.
- **Right-click**: Exit the program (This automatically unmounts the drive and cleans up processes).

## ❓ FAQ

- **Q: Why does nothing happen when I double-click?**
  - A: Please check if `rclone.exe` is strictly located inside the `core` folder.
- **Q: How do I modify the configuration?**
  - A: Run `RcloneTray.bat` again and select the corresponding option to re-configure.
- **Q: Antivirus warning?**
  - A: The script uses PowerShell to access system APIs (for creating shortcuts and mounting drives), which may trigger false positives in some antivirus software. Please add the folder to the exclusion list.

## 📄 License

MIT License
