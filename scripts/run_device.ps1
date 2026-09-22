$ErrorActionPreference = "Stop"
$device = "adb-d611fb34-Or5Q1h._adb-tls-connect._tcp"
Write-Host "Target device: $device"
Write-Host "Starting release build and install..."

& "C:\flutter\bin\flutter.bat" run --release -d $device --dart-define-from-file=.env
