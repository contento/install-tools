#requires -version 5

Set-StrictMode -Version 2

<#
.SYNOPSIS
  Copy various configurations
.DESCRIPTION
  Copy configurations from ./configurations folder
.INPUTS
  None
.OUTPUTS
  None
.NOTES

.EXAMPLE
  None
.EXAMPLE
  None
#>

$ErrorActionPreference = "Stop"

[string] $configurationsPath = "$PSScriptRoot/configurations"

# TODO: use tools.yaml
$configurations = @(
    , ("doublecmd.xml", "$env:APPDATA/DoubleCmd")
    , ("shortcuts.scf", "$env:APPDATA/DoubleCmd")
)

foreach ($configuration in $configurations) {
    $configurationFile = "$configurationsPath/$($configuration[0])"
    $configurationTargetPath = $configuration[1]

    if (!(Test-Path -Path $configurationTargetPath)) {
        New-Item -ItemType Directory -Path $configurationTargetPath
    }

    "Copying '$configurationFile' to '$configurationTargetPath' ..."
    Copy-Item $configurationFile $configurationTargetPath -Force
}
