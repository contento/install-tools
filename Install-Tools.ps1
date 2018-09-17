#requires -version 5
#Requires -RunAsAdministrator

<#
.SYNOPSIS
  Installs a bunch of tools for development purposes
.DESCRIPTION
  Installs:
  - Various PowerShell Modules
  - Chocolatey + Tools
.INPUTS
  None
.OUTPUTS
  log file. See $LogFilePath
.NOTES
 None
.EXAMPLE
  Install-Tools
.EXAMPLE
  Install-Tools -LogFilePath c:/logs
#>

param (
    [Parameter(Mandatory = $false, HelpMessage = "Path to log file")]
    [string]$LogFilePath
)

#---------------------------------------------------------[Initializations]--------------------------------------------------------

Set-StrictMode -Version 2

$ErrorActionPreference = "Stop"

. "$PSScriptRoot/Write-Log.ps1"

#----------------------------------------------------------[Declarations]----------------------------------------------------------

if (!$LogFilePath) {
    $LogFilePath = "$PSScriptRoot/logs/$([System.IO.Path]::GetFileNameWithoutExtension($PSCommandPath)).{yyyy-MM-dd}.log"
}

$moduleNames = @(
    # https://www.powershellgallery.com
    "posh-git",
    "PowerShellGet",
    "Powershell-yaml",
    "PSReadLine"
)

$chocoApps = @(
    # VS Chocolatey: BEGIN
    "chocolatey",
    # VS Chocolatey: END
    "cmder",
    "dependencywalker",
    "doublecmd",
    "git",
    "ilspy",
    "irfanview",
    "irfanviewplugins", # TODO: confirm!
    "jdk8", # Only for development !!!
    # "lightshot", # Broken!
    "lockhunter",
    "notepad3",
    "notepadplusplus",
    "rdtabs",
    "tortoisegit",
    "treesizefree",
    # VS Code: BEGIN
    #   https://chocolatey.org/packages?q=vscode
    "vscode",
    "vscode-autofilename",
    "vscode-csharp",
    "vscode-docker",
    "vscode-powershell",
    "vscode-editorconfig",
    "vscode-icons",
    "vscode-tslint",
    # VS Code: END
    "reshack",
    "sysinternals",
    "wintail",
    "7zip"
)

#-----------------------------------------------------------[Functions]------------------------------------------------------------

function Initialize-ToolsFolder {
    "Initializing Tools Folder" | Write-Log -UseHost -Path $LogFilePath

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
}

function Install-Chocolatey() {
    "Install/upgrading Chocolatey" | Write-Log -UseHost -Path $LogFilePath

    $savedErrorActionPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = "SilentlyContinue"
        $command = Get-Command choco
    }
    finally {
        $ErrorActionPreference = $savedErrorActionPreference
    }
    if ($command) {
        choco upgrade -y chocolatey 2>&1 | Write-Log -UseHost -Path $LogFilePath
    }
    else {
        Set-ExecutionPolicy Bypass -Scope Process -Force
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1')) 2>&1 | Write-Log -UseHost -Path $LogFilePath
    }
}

function Install-ChocoApps() {
    "Install/upgrading Choco-Apps" | Write-Log -UseHost -Path $LogFilePath
    ForEach ($appName in $chocoApps) {
        $exists = choco list -lo | Where-object { $_.ToLower().StartsWith("$appName ".ToLower()) }
        if (!$exists) {
          "Installing $appName ..." | Write-Log -UseHost -Path $LogFilePath
          choco install -y $appName 2>&1 | Write-Log -Path $LogFilePath
        }
        else {
          "Upgrading $appName ..." | Write-Log -UseHost -Path $LogFilePath
          choco upgrade -y $appName 2>&1 | Write-Log -Path $LogFilePath
        }
    }
}

function Install-PowerShellModules() {
    "Installing PowerShell Modules" | Write-Log -UseHost -Path $LogFilePath
    # You may want to move this policy to a system script
    Install-PackageProvider -Name NuGet -Force
    Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted

    ForEach ($moduleName in $moduleNames) {
        "Installing $moduleName ..." | Write-Log -UseHost -Path $LogFilePath

        $module = Get-Module -ListAvailable | Where-Object { $_.Name -eq $moduleName }
        if (!$module) {
            Install-Module -Name $moduleName 2>&1 | Write-Log -Path $LogFilePath
        }
        else {
            "Module $($module.Name) $($module.Version) was already installed" | Write-Log -UseHost -Level Warn -Path $LogFilePath
        }
    }
}

function Main {
    [CmdletBinding()]
    param (
    )

    begin {
        Initialize-ToolsFolder
    }

    process {
        Install-PowerShellModules
        Install-Chocolatey
        Install-ChocoApps
    }

    end {
    }
}

#-----------------------------------------------------------[Execution]------------------------------------------------------------

try {
    $savedDebugPreference = $DebugPreference
    #! Enable next line if you want to see the Debug Output
    # $DebugPreference = "Continue"

    $duration = Measure-Command { Main }
    "Done! $duration" | Write-Log -UseHost -Path $LogFilePath
}
finally {
    $DebugPreference = $savedDebugPreference
}
