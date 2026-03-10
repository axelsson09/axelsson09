param(
    [string]$choice,
    [string]$subChoice,
    [string]$url
)

$themePath = "$env:APPDATA\Microsoft\Windows\Themes"
$cachePath = "$themePath\CachedFiles"
$tempDownload = "$PSScriptRoot\temp_wallpaper.png"

# --- Functions ---
function Apply-Wallpaper {
    param([string]$Path)
    
    Write-Host "Applying wallpaper..." -ForegroundColor Yellow
    
    # Prepare the Themes folder
    if (!(Test-Path $cachePath)) { New-Item -ItemType Directory -Path $cachePath -Force | Out-Null }
    Remove-Item "$themePath\TranscodedWallpaper*" -Force -ErrorAction SilentlyContinue
    Remove-Item "$cachePath\*" -Force -ErrorAction SilentlyContinue

    # Inject the file (Windows expects both an extensionless and a .png version)
    Copy-Item $Path "$themePath\TranscodedWallpaper" -Force
    Copy-Item $Path "$themePath\TranscodedWallpaper.png" -Force

    Write-Host "Wallpaper injected successfully!" -ForegroundColor Green
    Write-Host "Restarting Explorer to apply changes..." -ForegroundColor Gray
    
    Stop-Process -Name Explorer -Force
}

# --- Main Interface ---
if (-not $choice) {
    Clear-Host
    Write-Host "--- Windows Wallpaper Manager ---" -ForegroundColor Cyan
    Write-Host "1. Change Wallpaper (Local / URL / Library)"
    Write-Host "2. Reset to Default"
    Write-Host "3. Exit"
    $choice = Read-Host "`nSelect an option"
}

switch ($choice) {
    "1" {
        if (-not $subChoice) {
            Write-Host "`n--- Change Wallpaper ---" -ForegroundColor Magenta
            Write-Host "A. Use local file (wallpaper.* in script folder)"
            Write-Host "B. Enter Image URL"
            Write-Host "C. Browse GitHub Library"
            $subChoice = Read-Host "Select sub-option"
        }

        switch ($subChoice) {
            "A" {
                $sourceFile = Get-ChildItem -Path "$PSScriptRoot\wallpaper.*" | Select-Object -First 1
                if ($sourceFile) { 
                    Apply-Wallpaper -Path $sourceFile.FullName 
                } else { 
                    Write-Host "Error: Could not find any file named 'wallpaper' with an image extension in $PSScriptRoot" -ForegroundColor Red 
                }
            }

            "B" {
                if (-not $url) { $url = Read-Host "Enter the direct image URL" }
                Write-Host "Downloading image..." -ForegroundColor Cyan
                try {
                    Invoke-WebRequest -Uri $url -OutFile $tempDownload -ErrorAction Stop
                    Apply-Wallpaper -Path $tempDownload
                } catch {
                    Write-Host "Failed to download image. Ensure the URL is a direct link to an image file." -ForegroundColor Red
                }
            }

            "C" {
                Write-Host "Fetching library from GitHub..." -ForegroundColor Cyan
                $repoApi = "https://api.github.com/repos/axelsson09/axelsson09/contents/Some%20Fun%20Scripts/wallpaperManager/library"
                
                try {
                    # Force result into an array and provide User-Agent for GitHub API
                    $files = @(Invoke-RestMethod -Uri $repoApi -Headers @{"User-Agent"="PowerShell-Wallpaper-Manager"})
                    
                    # Filter for actual image extensions only
                    $images = $files | Where-Object { $_.name -match "\.(jpg|jpeg|png|bmp)$" }

                    if ($null -eq $images -or $images.Count -eq 0) {
                        Write-Host "No images found in the GitHub library folder." -ForegroundColor Yellow
                        return
                    }

                    Write-Host "`n--- Available Library Wallpapers ---" -ForegroundColor Green
                    for ($i = 0; $i -lt $images.Count; $i++) {
                        Write-Host "$($i + 1). $($images[$i].name)"
                    }

                    $selection = Read-Host "`nSelect an image number (or 'q' to go back)"
                    if ($selection -eq 'q') { return }

                    if ($selection -match '^\d+$') {
                        $imgIndex = [int]$selection - 1
                        if ($imgIndex -ge 0 -and $imgIndex -lt $images.Count) {
                            $selectedUrl = $images[$imgIndex].download_url
                            Write-Host "Downloading $($images[$imgIndex].name)..." -ForegroundColor Cyan
                            Invoke-WebRequest -Uri $selectedUrl -OutFile $tempDownload
                            Apply-Wallpaper -Path $tempDownload
                        } else {
                            Write-Host "Selection out of range." -ForegroundColor Red
                        }
                    } else {
                        Write-Host "Invalid input. Please enter a number." -ForegroundColor Red
                    }
                } catch {
                    Write-Host "Could not connect to GitHub. Error: $($_.Exception.Message)" -ForegroundColor Red
                }
            }
        }
    }

    "2" {
        Write-Host "Resetting to default Windows wallpaper..." -ForegroundColor Yellow
        Remove-Item "$themePath\TranscodedWallpaper*" -Force -ErrorAction SilentlyContinue
        Remove-Item "$cachePath\*" -Force -ErrorAction SilentlyContinue
        Stop-Process -Name Explorer -Force
        Write-Host "Reset complete." -ForegroundColor Green
    }

    "3" {
        Write-Host "Exiting..."
        exit
    }

    Default {
        Write-Host "Invalid selection: $choice" -ForegroundColor Red
    }
}

# Cleanup temporary download if it exists
if (Test-Path $tempDownload) { Remove-Item $tempDownload -Force }
