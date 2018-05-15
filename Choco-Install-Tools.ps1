#requires -version 5

Set-StrictMode -Version 2

<#
.SYNOPSIS
  Installs a bunch of tools using Chocolatey
.DESCRIPTION
  Installs a bunch of tools using Chocolatey
.INPUTS
  None
.OUTPUTS
  log file (./logs/yyyy-mm-dd.log)
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
    "rdtabs",
    "cmder",
    "dependencywalker",
    "doublecmd",
    "ilspy",
    "irfanview",
    "irfanviewplugins", # TODO: confirm!
    # "lightshot", # Broken!
    "lockhunter",
    "notepad3",
    "notepadplusplus",
    "rdtabs",
    "treesizefree",
    # VS Code: BEGIN
    "vscode",
    "vscode-autofilename",
    "vscode-powershell",
    "vscode-editorconfig",
    "vscode-icons",
    # VS Code: END
    "reshack",
    "sysinternals",
    "wintail",
    "7zip"
)

#---------------------------------------------------------[Initializations]--------------------------------------------------------
$ErrorActionPreference = "Stop"

$logsPath = "$PSScriptRoot\logs"
$logFilename = "$logsPath\Choco-Install-Tools.$(Get-Date -f yyyy-MM-dd).log"

#----------------------------------------------------------[Declarations]----------------------------------------------------------

#-----------------------------------------------------------[Functions]------------------------------------------------------------
function InstallOrUpgradeChocolatey() {
    Write-Output "About to install/upgrade Chocolatey"

    $savedErrorActionPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = "SilentlyContinue"
        $command = Get-Command choco
    } finally {
        $ErrorActionPreference = $savedErrorActionPreference  
    }
    if ($command) {
        choco upgrade -y chocolatey
    }
    else {
        Set-ExecutionPolicy Bypass -Scope Process -Force
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
    }
}

#-----------------------------------------------------------[Execution]------------------------------------------------------------

if (!(Test-Path -Path $logsPath)) {
    New-Item -ItemType Directory -Path $logsPath
}

$toolsPath = 'c:/tools'
if (!(Test-Path -Path $toolsPath)) {
    New-Item -ItemType Directory -Path $toolsPath
}

$utilPath = 'c:/util'
if (!(Test-Path -Path $utilPath)) {
    New-Item -ItemType SymbolicLink -Path $utilPath -Value $toolsPath
}

# In case something fails and we miss the environment variables
[Environment]::SetEnvironmentVariable("TOOLS_PATH", "$toolsPath", "Machine")
[Environment]::SetEnvironmentVariable("COMMANDER_PATH", "$toolsPath\totalcmd", "Machine")
[Environment]::SetEnvironmentVariable("CMDER_ROOT", "$toolsPath\cmder", "Machine")

InstallOrUpgradeChocolatey

ForEach ($i in $apps) {
    Write-Output "Installing $i ..."
    choco install -y $i 2>&1 | Tee-Object -FilePath $logFilename -Append
}
