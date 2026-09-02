$ErrorActionPreference = 'Stop'

$bundledPython = Join-Path $env:USERPROFILE '.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'
$pythonCommand = Get-Command python.exe -ErrorAction SilentlyContinue

if ($pythonCommand -and -not ($pythonCommand.Source -like '*WindowsApps*')) {
    $pythonExe = $pythonCommand.Source
} elseif (Test-Path -LiteralPath $bundledPython) {
    $pythonExe = $bundledPython
} else {
    throw 'Python 3.11 ou superior nao foi encontrado. Instale o Python ou execute pelo ambiente do Codex.'
}

if (-not $env:ERP_IA_API_URL) {
    $env:ERP_IA_API_URL = 'http://127.0.0.1:8080'
}

Write-Host "Iniciando ERP IA com: $pythonExe"
Write-Host 'Use Ctrl+C para encerrar.'

& $pythonExe (Join-Path $PSScriptRoot 'main.py')
