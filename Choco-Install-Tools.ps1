#requires -version 5

Set-StrictMode -Version 2

<#
.SYNOPSIS
  Installs a bunch of tools using Chocolatey
.DESCRIPTION
  Installs a bunch of tools using Chocolatey
.PARAMETER SourceFilename
  None
.PARAMETER LogFilename
  file containing the list of files to be installed/upgraded
.INPUTS
  None
.OUTPUTS
  log file
.NOTES
  Version:        1.0
  Author:         Gonzalo Contento
  Creation Date:  2018-01-26
  Purpose/Change: Initial script development

.EXAMPLE
  None
.EXAMPLE
  None
#>
$apps = @(
    # VS Chocolatey: BEGIN
    "chocolatey",
    # VS Chocolatey: END
    "cmder",
    "doublecmd",
    "notepad3",
    "notepadplusplus",
    "treesizefree",
    # VS Code: BEGIN
    "vscode",
    "vscode-autofilename",
    "vscode-powershell",
    "vscode-editorconfig",
    "vscode-icons",
    # VS Code: END
    "sysinternals",
    "wintail"
)

#---------------------------------------------------------[Initializations]--------------------------------------------------------
$ErrorActionPreference = "Stop"

$logFilename = "$PSScriptRoot\Choco-Tools.$(Get-Date -f yyyy-MM-dd).log"

#----------------------------------------------------------[Declarations]----------------------------------------------------------

#-----------------------------------------------------------[Functions]------------------------------------------------------------
function InstallOrUpgradeChocolatey() {
    Write-Output "About to install/upgrade Chocolatey"

    $command = Get-Command choco
    if ($command) {
        choco upgrade chocolatey
    }
    else {
        Set-ExecutionPolicy Bypass -Scope Process -Force
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
    }
}

#-----------------------------------------------------------[Execution]------------------------------------------------------------

$newDir = 'c:/util'
if (!(Test-Path -Path $newDir)) {
    New-Item -ItemType Directory -Path $newDir
}

$newDir = 'c:/tools'
if (!(Test-Path -Path $newDir)) {
    New-Item -ItemType SymbolicLink -Path $newDir -Value c:\util 
}

# In case something fails and we miss the environment variables
[Environment]::SetEnvironmentVariable("COMMANDER_PATH", "c:\tools\cmder", "Machine")
[Environment]::SetEnvironmentVariable("CMDER_ROOT", "c:\tools\totalcmd", "Machine")

InstallOrUpgradeChocolatey

ForEach ($i in $apps) {
    Write-Output "Installing $i ..."
    choco install -y $i 2>&1 | Add-Content -Path $logFilename
}
