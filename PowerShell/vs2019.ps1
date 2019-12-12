param(
    [string]$edition,
    [string]$basePath = "",
    [switch]$noWeb = $false
)

$folder = Split-Path $PSCommandPath
$script = Join-Path $folder "vs.ps1"
& $script -edition:$edition -version:"2019" -basePath:$basePath -noWeb:$noWeb
