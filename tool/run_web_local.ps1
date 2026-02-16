$ErrorActionPreference = "Stop"

$definesFile = "dart_defines.local.json"
if (-not (Test-Path $definesFile)) {
  Write-Error "Missing $definesFile. Copy dart_defines.example.json and fill your values first."
}

flutter run -d chrome --web-port 3000 --dart-define-from-file=$definesFile
