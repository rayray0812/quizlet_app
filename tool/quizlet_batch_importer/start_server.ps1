param(
  [int]$Port = 47831
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
node (Join-Path $root "server.js") $Port
