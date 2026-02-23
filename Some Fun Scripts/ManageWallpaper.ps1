param(
    [string]$choice
)

if (-not $choice) {
    Write-Host "--- Windows Wallpaper Manager ---" -ForegroundColor Cyan
    Write-Host "1. Change Wallpaper"
    Write-Host "2. Reset to Default"
    Write-Host "3. Cancel"
    $choice = Read-Host "`nSelect an option"
}

$themePath = "$env:APPDATA\Microsoft\Windows\Themes"
$cachePath = "$themePath\CachedFiles"

switch ($choice) {
    "1" {
        $sourceFile = Get-ChildItem -Path "$PSScriptRoot\wallpaper.*" | Select-Object -First 1
        
        if (-not $sourceFile) {
            Write-Host "Error: Could not find wallpaper in $PSScriptRoot\Resources\" -ForegroundColor Red
            pause
            exit
        }

        Write-Host "Processing image..." -ForegroundColor Yellow
        
        if (!(Test-Path $cachePath)) { New-Item -ItemType Directory -Path $cachePath -Force | Out-Null }
        Remove-Item "$themePath\TranscodedWallpaper*" -Force -ErrorAction SilentlyContinue
        Remove-Item "$cachePath\*" -Force -ErrorAction SilentlyContinue

        Copy-Item $sourceFile.FullName "$themePath\TranscodedWallpaper" -Force
        Copy-Item $sourceFile.FullName "$themePath\TranscodedWallpaper.png" -Force

        Write-Host "Wallpaper injected successfully!" -ForegroundColor Green
        Stop-Process -Name Explorer -Force
    }

    "2" {
        Write-Host "Resetting to default..." -ForegroundColor Yellow
        Remove-Item "$themePath\TranscodedWallpaper*" -Force -ErrorAction SilentlyContinue
        Remove-Item "$cachePath\*" -Force -ErrorAction SilentlyContinue
        
        Write-Host "Reset complete. Restarting Explorer..." -ForegroundColor Green
        Stop-Process -Name Explorer -Force
    }

    "3" {
        Write-Host "Exiting..."
        exit
    }

    Default {
        Write-Host "Invalid selection: $choice" -ForegroundColor Red
    }
}
