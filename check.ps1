param(
    [string]$GodotPath = ""
)

$ErrorActionPreference = "Stop"
$projectPath = Split-Path -Parent $MyInvocation.MyCommand.Path

function Resolve-GodotExe {
    param([string]$UserPath)

    if ($UserPath -and (Test-Path $UserPath)) {
        return $UserPath
    }

    if ($env:GODOT_EXE -and (Test-Path $env:GODOT_EXE)) {
        return $env:GODOT_EXE
    }

    $cmd = Get-Command godot4 -ErrorAction SilentlyContinue
    if ($cmd) {
        return $cmd.Source
    }

    $cmd = Get-Command godot -ErrorAction SilentlyContinue
    if ($cmd) {
        return $cmd.Source
    }

    $commonPaths = @(
        "C:\Program Files\Godot\Godot_v4.6.1-stable_win64.exe",
        "C:\Program Files\Godot\Godot_v4.6.1-stable_mono_win64.exe",
        "C:\Program Files\Godot\Godot_v4.6.1-stable_win64_console.exe",
        "C:\Program Files\Godot\Godot_v4.6.1-stable_mono_win64_console.exe",
        "C:\Program Files\Godot\Godot_v4.3-stable_win64.exe",
        "C:\Program Files\Godot\Godot_v4.3-stable_mono_win64.exe",
        "C:\Program Files\Godot\Godot.exe",
        "C:\Users\1\Downloads\Godot_v4.6.1-stable_win64.exe",
        "C:\Users\1\Desktop\Godot_v4.6.1-stable_win64.exe"
    )

    foreach ($path in $commonPaths) {
        if (Test-Path $path) {
            return $path
        }
    }

    $searchRoots = @(
        "C:\Users\1\Downloads",
        "C:\Users\1\Desktop",
        "C:\Users\1\Documents",
        "D:\"
    )
    $patterns = @("Godot_v4.6.1*.exe", "Godot*.exe", "*godot*.exe")
    foreach ($root in $searchRoots) {
        if (-not (Test-Path $root)) {
            continue
        }
        foreach ($pattern in $patterns) {
            $found = Get-ChildItem -Path $root -Filter $pattern -File -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($found) {
                return $found.FullName
            }
        }
    }

    throw "Godot executable not found. Pass -GodotPath or set GODOT_EXE."
}

try {
    $godotExe = Resolve-GodotExe -UserPath $GodotPath
    Write-Host "Using Godot: $godotExe"

    $gdFiles = Get-ChildItem -Path $projectPath -Filter "*.gd" -File -Recurse | Where-Object { $_.FullName -notmatch "\\.godot\\" }
    if (-not $gdFiles -or $gdFiles.Count -eq 0) {
        throw "No .gd files found in project."
    }

    foreach ($file in $gdFiles) {
        $relativePath = $file.FullName.Substring($projectPath.Length + 1).Replace("\", "/")
        Write-Host "Checking: $relativePath"
        & $godotExe --headless --path $projectPath --script $relativePath --check-only --quit --no-header
        if ((-not $?) -or ($LASTEXITCODE -ne $null -and $LASTEXITCODE -ne 0)) {
            $code = if ($LASTEXITCODE -eq $null) { "unknown" } else { "$LASTEXITCODE" }
            throw "Script check failed: $relativePath (exit code $code)"
        }
    }

    Write-Host "Check passed."
    exit 0
}
catch {
    Write-Error $_
    exit 1
}
