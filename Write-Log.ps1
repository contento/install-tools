<#
.SYNOPSIS
Write Log Entry

.DESCRIPTION
Write message to Log Entry

.PARAMETER Path
Log Path

.PARAMETER LogFormat
Format for each entry

.PARAMETER Message
The string to be loggeg. It could come from the pipeline

.PARAMETER Level
Log level: Default is Info

.PARAMETER NoClobber
Do not create a new file if one doesn't exist yet. Default is false

.PARAMETER UseTee
Use Tee-Object instead of Out-File. Default is false

.EXAMPLE
"Foo1", "Foo2" | Write-Log

.EXAMPLE
""Foo1", "Foo2" | Write-Log -UseTee -Level Warn -Path "./logs/Log.{yyyy-MM-dd}.log"

.NOTES
Some ideas taken from:
  https://gallery.technet.microsoft.com/scriptcenter/Write-Log-PowerShell-999c32d0
  https://learn-powershell.net/2013/05/07/tips-on-implementing-pipeline-support/
#>
function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)] 
        [string]$Path = "C:\logs\Log.{yyyy-MM-dd}.log",
        [Parameter(Mandatory = $false)] 
        [string]$LogFormat = "{0:yyyy-MM-dd HH:mm:ss}|{1,-5}|{2}",
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)] 
        [string]$Message, 
        [Parameter(Mandatory = $false)] 
        [ValidateSet("Error", "Warn", "Info", "Debug")] 
        [string]$Level = "Info", 
        [Parameter(Mandatory = $false)] 
        [switch]$NoClobber,
        [Parameter(Mandatory = $false, HelpMessage = "Use Tee-Object")] 
        [switch]$UseTee = $false,
        [Parameter(Mandatory = $false, HelpMessage = "Use Write-Host as well")] 
        [switch]$UseHost = $false
    )
    begin {
        if ((Test-Path $Path) -AND $NoClobber) {
            Write-Error "File '$Path' already exists and you specified -NoClobber"
            return
        }

        $Path = GetLogFilePath $Path 
        $logsPath = Split-Path -Path $Path 
        if (!(Test-Path -Path $logsPath)) {
            $item = New-Item -ItemType Directory -Path $logsPath
        }
    
        if (!(Test-Path $Path)) {
            $item = New-Item $Path -Force -ItemType File
        }

        if (!(Split-Path -IsAbsolute -Path $logsPath)) {
            $Path = Join-Path (Convert-Path $logsPath) (Split-Path -Path $Path -Leaf)  
        }
    }
    
    process {
        $line = $LogFormat -f (Get-Date), $Level.ToUpper(), $Message 

        if ($UseHost) {
            $foreColor = switch ($level.ToUpper())
            {
                "ERROR" { "Red" }
                "INFO" { "Green" }
                "WARN" { "Yellow" }
                "DEBUG" { "DarkGray" }
            }
            Write-Host $line -ForegroundColor $foreColor        
		}
        
        if ($UseTee) {
            $line | Tee-Object -FilePath $Path -Append
        }
        else {
            $line | Out-File -FilePath $Path -Append
        } 
    }
    
    end {
    }
}

function GetLogFilePath([string] $originalLogFilePath) {
    $matching = $originalLogFilePath -match ".*{(.*)}.*"
    if (!$matching) {
        return $originalLogFilePath
    } 

    $format = $Matches[1]
    $path = $originalLogFilePath -replace "{.*}", "$(Get-Date -f $format)"
    return $path
}
