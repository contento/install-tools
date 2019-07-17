#requires -version 5
#requires -RunAsAdministrator

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
    [Parameter(Mandatory = $false, HelpMessage = "Path to YAML configuration file")]
    [string]$ConfigurationFilePath,
    [Parameter(Mandatory = $false, HelpMessage = "Path to log file")]
    [string]$LogFilePath
)

#---------------------------------------------------------[Initializations]--------------------------------------------------------

Set-StrictMode -Version 2

$ErrorActionPreference = "Stop"

# Let us install the egg before the chicken ;-)
@("PowerShellGet", "powershell-yaml") | ForEach-Object {
    $superModule = $_
    Write-Warning "Forcing installation of '$superModule' ..."

    Remove-Module -Name $superModule -Force -ErrorAction SilentlyContinue
    Install-Module -Name $superModule -Force -AllowClobber -ErrorAction SilentlyContinue
}

Import-Module -Name "powershell-yaml"

. "$PSScriptRoot/Write-Log.ps1"

#----------------------------------------------------------[Declarations]----------------------------------------------------------

if (!$LogFilePath) {
    $LogFilePath = "$PSScriptRoot/logs/$([System.IO.Path]::GetFileNameWithoutExtension($PSCommandPath)).{yyyy-MM-dd}.log"
}

#-----------------------------------------------------------[Functions]------------------------------------------------------------

function Initialize-ToolsFolder(
    $Configuration) {
    "Initializing Tools Folder" | Write-Log -UseHost -Path $LogFilePath

    $toolsPath = $Configuration.toolPath
    if (!(Test-Path -Path $toolsPath)) {
        New-Item -ItemType Directory -Path $toolsPath
    }

    $utilPath = $Configuration.utilPath
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

    $command = Get-Command choco -ErrorAction SilentlyContinue
    if ($command) {
        choco upgrade -y chocolatey 2>&1 | Write-Log -UseHost -Path $LogFilePath
    }
    else {
        Set-ExecutionPolicy Bypass -Scope Process -Force
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1')) 2>&1 | Write-Log -UseHost -Path $LogFilePath
    }
}

function Install-ChocoApps($ChocoApps) {
    "Install/upgrading Choco-Apps" | Write-Log -UseHost -Path $LogFilePath
    ForEach ($appName in $ChocoApps) {
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

function Install-PowerShellModules {
    [CmdletBinding()]
    param (
        $Modules,
        [switch] $Force
    )

    begin {
    }

    process {
        "Installing PowerShell Modules" | Write-Log -UseHost -Path $LogFilePath
        # You may want to move this policy to a system script
        Install-PackageProvider -Name NuGet -Force
        Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted

        ForEach ($module in $Modules) {
            "Installing $module ..." | Write-Log -UseHost -Path $LogFilePath
            Install-Module -Name $module -Force:$Force -AllowClobber 2>&1 | Write-Log -Path $LogFilePath
        }
    }

    end {
    }
}

function Initialize-Command {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string] $Command
    )

    begin {
    }

    process {
        $Command | Write-Log -UseHost -Path $LogFilePath
    }

    end {
    }
}


function Main {
    [CmdletBinding()]
    param (
    )

    begin {
        if (!$ConfigurationFilePath) {
            $ConfigurationFilePath = "$($PSScriptRoot)/tools.yaml"
        }
        $content = (Get-Content -Path $ConfigurationFilePath | Out-String)
        $Configuration = ConvertFrom-Yaml -Yaml $content
    }

    process {
        Initialize-ToolsFolder $Configuration

        Install-PowerShellModules -Modules $Configuration.powershell.modules -Force
        
        Install-Chocolatey
        Install-ChocoApps -ChocoApps $Configuration.choco.apps
        Install-ChocoApps -ChocoApps $Configuration.choco.vscode

        $Configuration.commands | Initialize-Command
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
catch {
    $Exception = $_.Exception

    if (!$LogFilePath) {
        $LogFilePath = Get-DefaultLogFilePath
    }

    $Exception | Write-Log -UseHost -Path $LogFilePath -Level Error
    if (!(Test-Path Variable:\LASTEXITCODE) -or $LASTEXITCODE -eq 0) {
        # Force Error Code 1: Incorrect function. [ERROR_INVALID_FUNCTION (0x1)]
        $LASTEXITCODE = 1
        "Function-Generated Exit Code: $LASTEXITCODE" | Write-Log -UseHost -Path $LogFilePath -Level Error
    }
}
finally {
    $DebugPreference = $savedDebugPreference
}
