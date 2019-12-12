param(
    [string]$edition,
    [string]$basePath = "",
    [switch]$noWeb = $false
)

$folder = Split-Path $PSCommandPath
$script = Join-Path $folder "vs.ps1"
& $script -edition:$edition -version:"Preview" -basePath:$basePath -noWeb:$noWeb
