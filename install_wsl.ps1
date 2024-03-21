# Automatic Windows Update
Write-Host "Checking for Windows updates..."
$updates = Get-WindowsUpdate
if ($updates.Count -gt 0) {
    Write-Host "Found $($updates.Count) updates. Installing updates..."
    Install-WindowsUpdate -AcceptAll -AutoReboot:$false
} else {
    Write-Host "No updates available."
}

# Check if Windows Subsystem for Linux (WSL) is already enabled
$wslEnabled = Get-WindowsOptionalFeature -Online | Where-Object { $_.FeatureName -eq "Microsoft-Windows-Subsystem-Linux" -and $_.State -eq "Enabled" }

if (-not $wslEnabled) {
    # Install Windows Subsystem for Linux (WSL)
    Write-Host "Enabling Windows Subsystem for Linux (WSL)..."
    dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
} else {
    Write-Host "Windows Subsystem for Linux (WSL) is already enabled."
}

# Check if Virtual Machine Platform feature is already enabled
$vmpEnabled = Get-WindowsOptionalFeature -Online | Where-Object { $_.FeatureName -eq "VirtualMachinePlatform" -and $_.State -eq "Enabled" }

if (-not $vmpEnabled) {
    # Enable Virtual Machine Platform feature
    Write-Host "Enabling Virtual Machine Platform feature..."
    dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
} else {
    Write-Host "Virtual Machine Platform feature is already enabled."
}

# Set default WSL version to 2
wsl --set-default-version 2

# Prompt the user to restart the computer
Write-Host "Completed. Please restart your computer to apply the changes."
