# ==========================================
#        Core Logic (Reads mount.conf)
# ==========================================
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$CurrentDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RcloneExe  = Join-Path $CurrentDir "rclone.exe"
$RcloneConf = Join-Path $CurrentDir "rclone.conf"
$MountConf  = Join-Path $CurrentDir "mount.conf"

# --- Step 1: Load Mount Configurations ---
$Mounts = @()

if (Test-Path $MountConf) {
    $Lines = Get-Content $MountConf
    foreach ($Line in $Lines) {
        # Skip empty lines or comments
        if ([string]::IsNullOrWhiteSpace($Line) -or $Line.Trim().StartsWith("#")) { continue }
        
        # Parse: Remote|Letter|Label|Port
        $Parts = $Line -split "\|"
        if ($Parts.Count -ge 4) {
            
            # --- Core Fix: Drive Letter Handling ---
            $CleanLetter = $Parts[1].Trim()
            # If drive letter doesn't end with ':', append it to prevent mounting as a folder
            if (-not $CleanLetter.EndsWith(":")) {
                $CleanLetter += ":"
            }

            $Mounts += @{
                Remote = $Parts[0].Trim()
                Letter = $CleanLetter     # Use the corrected drive letter
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
        # Double check if drive letter is available (e.g. Z:\)
        if (-not (Test-Path "$($m.Letter)\")) {
            $ArgList = @(
                "mount", "$($m.Remote):", "$($m.Letter)",
                "--config", "$RcloneConf",
                "--vfs-cache-mode", "full",
                "--volname", "$($m.Label)",
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
Stop-All-Rclone
Start-All-Rclone
[System.Windows.Forms.Application]::Run()