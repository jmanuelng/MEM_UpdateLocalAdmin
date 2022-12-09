<#
.SYNOPSIS
    Can be used to execute B64 encoded script.

.DESCRIPTION
    For use in "Proactive Remediation" in Microsoft Intune.
    Insert B64 encoded script to $Data and will execute that script, runs successfully in Proactive Remediations.
    Captures the output so it is available in PR console.
#>

$Error.Clear()
$outfile = [System.IO.Path]::GetTempFileName()
$errorfile = [System.IO.Path]::GetTempFileName()

$Data ="XXXXXXXINSERTENCODEDSCRIPTHEREXXXXXX"


$argumentList = @(
    "-NoLogo",
    "-NonInteractive",
    "-NoProfile",
    "-EncodedCommand",
    $Data
)

$psPath = "Powershell"

$startProcessParams = @{
    FilePath               = $psPath
    ArgumentList           = $argumentList
    RedirectStandardError  = $errorfile
    RedirectStandardOutput = $outfile
    Wait                   = $true;
    PassThru               = $true;
    NoNewWindow            = $true;
}

$psProcess = Start-Process @startProcessParams

$psProcessOutput = Get-Content -Path $outfile -Raw
$psProcessError = Get-Content -Path $errorfile -Raw

Remove-item -Path $outfile, $errorfile -Force -ErrorAction Ignore

if (($psProcess.ExitCode -ne 0)) {
    if ($psProcessOutput) {
       Write-Host $psProcessOutput
    }
    if ($psProcessError) {
        #Write-Host $psProcessError.Trim()
        #throw $psProcessError.Trim()
        Exit 1
    }
}
else {
    if ([string]::IsNullOrEmpty($psProcessOutput) -eq $false) {
        Write-Host "INFO: No Errors"
        Write-Output -InputObject $psProcessOutput
        Exit 0
    }
}

#Finished!
