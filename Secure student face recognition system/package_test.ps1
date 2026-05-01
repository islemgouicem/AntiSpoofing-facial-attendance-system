$ErrorActionPreference = "Stop"

$ProjectRoot = (Get-Item .).FullName
$AppDir = Join-Path $ProjectRoot "attendance_app"
$EngineDir = Join-Path $ProjectRoot "ai_engine"
$OutDir = Join-Path $ProjectRoot "AttendanceSystem_Test"

Write-Host "========================================="
Write-Host " BUILDING ATTENDANCE SYSTEM TEST RUNNER  "
Write-Host "========================================="

# 1. Clean output directory
if (Test-Path $OutDir) {
    Remove-Item -Recurse -Force $OutDir
}
New-Item -ItemType Directory -Path $OutDir | Out-Null
# The ai_engine will be its own sub-folder with models/ and db/ inside it
$EngineDest = Join-Path $OutDir "ai_engine"
New-Item -ItemType Directory -Path $EngineDest | Out-Null
New-Item -ItemType Directory -Path (Join-Path $EngineDest "models") | Out-Null
New-Item -ItemType Directory -Path (Join-Path $EngineDest "db") | Out-Null

# 2. Build Flutter App
Write-Host "`n[1/4] Building Flutter Desktop App..."
Set-Location $AppDir
flutter build windows

Write-Host "Copying Flutter App to output..."
$FlutterOut = Join-Path $AppDir "build\windows\x64\runner\Release\*"
Copy-Item -Path $FlutterOut -Destination $OutDir -Recurse -Force

# Rename the exe if it's called attendance_app.exe
$oldExe = Join-Path $OutDir "attendance_app.exe"
$newExe = Join-Path $OutDir "AttendanceSystem.exe"
if (Test-Path $oldExe) {
    Rename-Item -Path $oldExe -NewName "AttendanceSystem.exe"
}

# 3. Build Python Engine
Write-Host "`n[2/4] Building Python AI Engine..."
Set-Location $EngineDir

# Clean previous PyInstaller builds
if (Test-Path "build") { Remove-Item -Recurse -Force "build" }
if (Test-Path "dist") { Remove-Item -Recurse -Force "dist" }
if (Test-Path "ai_engine.spec") { Remove-Item -Force "ai_engine.spec" }

# Run PyInstaller with --onedir (much faster startup)
pyinstaller --noconfirm --onedir --windowed --paths "..\antispoffing" --hidden-import uvicorn --hidden-import pydantic --hidden-import fastapi --hidden-import psutil --name ai_engine server.py

Write-Host "Copying AI Engine to output..."
$EngineDistDir = Join-Path $EngineDir "dist\ai_engine\*"
Copy-Item -Path $EngineDistDir -Destination $EngineDest -Recurse -Force

# 4. Copy Models and external data
Write-Host "`n[3/4] Copying Anti-Spoof Models..."
$ModelsSrc = Join-Path $ProjectRoot "antispoffing\resources\anti_spoof_models\*"
Copy-Item -Path $ModelsSrc -Destination (Join-Path $EngineDest "models") -Recurse -Force

# Copy database defaults if needed (not strictly needed, the daemon creates it, but we can copy the db dir)
$DbSrc = Join-Path $ProjectRoot "antispoffing\db\*"
if (Test-Path $DbSrc) {
    Copy-Item -Path $DbSrc -Destination (Join-Path $EngineDest "db") -Recurse -Force
}

Write-Host "`n[4/4] Done! The test runnable is ready at:"
Write-Host $OutDir
Write-Host "You can double click AttendanceSystem_Test\AttendanceSystem.exe to test."
