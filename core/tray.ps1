# ==========================================
#        Core Logic (Reads mount.conf)
# ==========================================
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- [CRITICAL FIX] Kill previous tray instances ---
# Get the ID of the current script process so we don't kill ourselves
$CurrentPID = $PID

# Find other PowerShell processes running 'tray.ps1' and kill them
try {
    Get-WmiObject Win32_Process | Where-Object { 
        $_.Name -match 'powershell' -and 
        $_.CommandLine -like '*tray.ps1*' -and 
        $_.ProcessId -ne $CurrentPID 
    } | ForEach-Object { 
        Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue 
    }
} catch {
    # Ignore errors if WMI is restricted, though rare.
}
# ---------------------------------------------------

$CurrentDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RcloneExe  = Join-Path $CurrentDir "rclone.exe"
$RcloneConf = Join-Path $CurrentDir "rclone.conf"
$MountConf  = Join-Path $CurrentDir "mount.conf"

# --- Step 1: Load Mount Configurations ---
$Mounts = @()

if (Test-Path $MountConf) {
    $Lines = Get-Content $MountConf
    foreach ($Line in $Lines) {
        if ([string]::IsNullOrWhiteSpace($Line) -or $Line.Trim().StartsWith("#")) { continue }
        
        $Parts = $Line -split "\|"
        if ($Parts.Count -ge 4) {
            $CleanLetter = $Parts[1].Trim()
            if (-not $CleanLetter.EndsWith(":")) { $CleanLetter += ":" }

            $Mounts += @{
                Remote = $Parts[0].Trim()
                Letter = $CleanLetter
                Label  = $Parts[2].Trim()
                Port   = $Parts[3].Trim()
            }
        }
    }
}

# --- Pre-flight Checks ---
if (-not (Test-Path $RcloneConf)) {
    [System.Windows.Forms.MessageBox]::Show("Error: 'rclone.conf' missing.`nRun RcloneTray.bat [1] first.", "Rclone Tray", "OK", "Error")
    exit
}

if ($Mounts.Count -eq 0) {
    [System.Windows.Forms.MessageBox]::Show("Error: No mounts configured in 'mount.conf'.`nRun RcloneTray.bat [2] to add mounts.", "Rclone Tray", "OK", "Warning")
    exit
}

# --- Function: Stop Rclone ---
function Stop-All-Rclone {
    Stop-Process -Name "rclone" -Force -ErrorAction SilentlyContinue
    Start-Sleep -Milliseconds 200
}

# --- Function: Start Mounts ---
function Start-All-Rclone {
    foreach ($m in $Mounts) {
        if (-not (Test-Path "$($m.Letter)\")) {
            $ArgList = @(
                "mount", "$($m.Remote):", "$($m.Letter)",
                "--config", "$RcloneConf",
                
                # --- 核心读写模式 ---
                "--vfs-cache-mode", "full",
                "--vfs-write-back", "5s",  # 稍微缩短一点延迟，提高响应
                "--volname", "$($m.Label)",
                "--dir-cache-time", "1m",  # 缩短目录缓存，加快新文件发现
                "--poll-interval", "15s",  # 加快轮询，从默认1分钟改为15秒
                
                # --- [修正] 修复 User-Agent 被截断的问题 ---
                # 注意：这里用了 '"..."' (单引号包双引号)，这是关键！
                "--user-agent", '"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"',
                
                # --- 兼容性参数 ---
                "--transfers", "1",
                "--checkers", "1",
                
                # --- 解决 500 错误和 corrupted 错误的关键 ---
                "--no-checksum",
                "--ignore-size",  # 必须加上这个，因为 Pydio 服务端显示的大小和本地不一致
                "--ignore-checksum",

                # --- 调试日志 (修好后记得删掉或改成 INFO) ---
                # "--log-file", "$CurrentDir\rclone.log",
                # "--log-level", "DEBUG",

                # --- 远程控制接口 ---
                "--rc", "--rc-addr", "localhost:$($m.Port)",
                "--rc-no-auth", 
                "--rc-web-gui", "--rc-web-gui-no-open-browser", "--rc-web-gui-update",
                "--no-console"
            )
            Start-Process -FilePath $RcloneExe -ArgumentList $ArgList -WindowStyle Hidden
        }
    }
}

# --- System Tray Icon ---
if (Test-Path $RcloneExe) {
    $Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($RcloneExe)
} else { exit }

$NotifyIcon = New-Object System.Windows.Forms.NotifyIcon
$NotifyIcon.Icon = $Icon
$NotifyIcon.Text = "Rclone Tray Manager"
$NotifyIcon.Visible = $true

# --- Context Menu ---
$ContextMenu = New-Object System.Windows.Forms.ContextMenuStrip

$SubMenu = $ContextMenu.Items.Add("Open Dashboard")
foreach ($m in $Mounts) {
    $ItemName = "$($m.Letter) - $($m.Label)"
    $SubItem = $SubMenu.DropDownItems.Add($ItemName)
    $SubItem.Tag = $m.Port 
    $SubItem.Add_Click({ Start-Process "http://localhost:$($this.Tag)/#/dashboard" })
}

$ContextMenu.Items.Add("-") | Out-Null
$MenuItemExit = $ContextMenu.Items.Add("Exit")
$MenuItemExit.Add_Click({
    Stop-All-Rclone
    $NotifyIcon.Visible = $false
    $NotifyIcon.Dispose()
    [System.Windows.Forms.Application]::Exit()
})

$NotifyIcon.ContextMenuStrip = $ContextMenu

# --- Double Click ---
$NotifyIcon.Add_DoubleClick({
    if ($Mounts.Count -gt 0) {
        Start-Process "http://localhost:$($Mounts[0].Port)/#/dashboard"
    }
})

# --- Main Execution ---
Stop-All-Rclone  # Kill rclone binaries
Start-All-Rclone # Start new rclone mounts
[System.Windows.Forms.Application]::Run()