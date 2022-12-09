<#
.SYNOPSIS
    Mega basic Base64 file encoder.

.DESCRIPTION
    Converts a file to Base 64, outputs a new file with .b64 extension in working folder. I use it to convert powershell scripts to Base64.
    To use encoded script just copy the .b64 content to a PS script and call "Powershell.exe -EncodedCommand".

.EXAMPLE
    Encode-B64.ps1 MyPowershellScript.ps1
    
    Encodes "MyPowershellScript.ps1" to Base64. MyPowershell.ps1 file should be in same folder / directory as this script.

#>

[CmdletBinding()]
param (
    [Parameter(Position=0,mandatory=$true)]
    [string]$FileName
)

$FilePath = $PSScriptRoot + "\" + $FileName
Write-Host "`n`n"

if (Test-Path -LiteralPath $FilePath) {

    [string]$Content = Get-Content -LiteralPath $FilePath -Raw
    $Bytes = [System.Text.Encoding]::Unicode.GetBytes($Content)
    $Encoded = [convert]::ToBase64String($Bytes)
    Write-Host "Encoded File $FilePath"

    $EncodedFilePath = $FilePath + ".b64"

    if ( -not (Test-Path -LiteralPath $EncodedFilePath)) {
        #If log file does not exist, create an empty Log File
        New-Item -Path $EncodedFilePath -Force -ItemType File
    }

    $Encoded | Out-File -LiteralPath $EncodedFilePath -Append -Force;
    #Write-Host $Encoded
}
else {
    Write-Host "File $FilePath not found."
}


