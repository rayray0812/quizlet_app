$ErrorActionPreference = "Stop"

$versions = @(
  '202602070001',
  '202602130002',
  '202602130003',
  '202602130004',
  '202602130005',
  '202602130006',
  '202602130007',
  '202602130008',
  '202602210009',
  '202602210010',
  '202602210011',
  '202602210012',
  '202602210013',
  '202602220014',
  '202602220015',
  '202602220016',
  '202602220017',
  '202603070001',
  '202603110001',
  '202603110002'
)

$exe = Join-Path $HOME 'bin\supabase.exe'

Write-Host "Marking $($versions.Count) migrations as applied..."
& $exe migration repair --status applied $versions
if ($LASTEXITCODE -ne 0) {
  Write-Host "repair failed (exit $LASTEXITCODE)" -ForegroundColor Red
  exit $LASTEXITCODE
}

Write-Host ""
Write-Host "Verifying with db push..."
& $exe db push
exit $LASTEXITCODE
