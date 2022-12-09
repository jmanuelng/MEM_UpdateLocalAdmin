<#
.SYNOPSIS
    Looks for a specific local user, verifies and/or sets "Password Never Expires"

.DESCRIPTION
    For use as remediation script in "Proactive Remediation" in Microsoft Intune.
    Verifies that a local user account exists, is enabled and has "Password Never Expires" enabled. 

.NOTES
    WAINING: Writing a username and/or password in script is completely not recommended under any circumstances. 
    Script encryption done via this repository is extremely basic. Microsoft's Intune Proactive Remediations leave copy of script in local computer. 
    If you do consider the use of this script please review how to create a scheduled task to remove script from computer. 

    Sources:
    https://social.technet.microsoft.com/Forums/azure/en-US/b6c7c9fc-8d34-4efd-b75d-03f6048ccbd5/accounts-csp-password-change-required?forum=microsoftintuneprod
    https://learn.microsoft.com/en-us/answers/questions/608549/change-local-admin-password-from-intune.html
    https://lazyadmin.nl/powershell/create-local-user/

#>

#Region Settings

$ErrorActionPreference = "Stop"
$TestUser = "MYADMIN"
$TestUserPass = "MyP@ssw0rd"
$TestUserPassS = $TestUserPass | ConvertTo-SecureString -AsPlainText -Force
$LocalAccount = Get-LocalUser -Name $TestUser -ErrorAction SilentlyContinue
$LocalADSI = [ADSI]"WinNT://$env:ComputerName/$TestUser,user"
Add-Type -AssemblyName System.DirectoryServices.AccountManagement 
$DS = New-Object System.DirectoryServices.AccountManagement.PrincipalContext([System.DirectoryServices.AccountManagement.ContextType]::Machine)
$FixSummary = ""

#Endregion

#Region Main 

#Clean errors
$Error.Clear()
#New lines, easier to read Agentexecutor Log file.
Write-Host "`n`n"
Write-Host "Starting script execution"

Write-Host "Verify if user $TestUser exists."

if ($LocalAccount.Name -eq $TestUser) {
    Write-Host "User $TestUser does exist."

    #Verify if account is enabled. If not, enable it.
    if ( -not ($LocalAccount.Enabled)) {
        Write-Host "Account is disabled, need to enable it"
        $LocalAccount | Enable-LocalUser
        $FixSummary += "Enabled account"
    }
    else {
        Write-Host "Account $LocalAccount is enabled."
    }

    #Verify if Password is set correctly
    Write-Host "Verifying password"
    try {

        if ($DS.ValidateCredentials($TestUser, $TestUserPass)) {

            Write-Host "`tPassword is set correctly"
        }
        else {
    
            Write-Host "Password incorrect. Trying to update password."
            try {
                Set-LocalUser -Name $TestUser -Password $TestUserPassS -ErrorAction Stop
                if ( -not ($FixSummary -eq "")) { $FixSummary += ", "}
                $FixSummary += "Password updated"
            }
            catch {
                if ($null -ne $_.Exception.ErrorName) {
                    if ( -not ($FixSummary -eq "")) { $FixSummary += ", "}
                    $FixSummary += "ERROR updating password"
                    Write-Host $_.Exception.Message
                }
            }
        }
        
    }
    catch {
        Write-Host "`tError verifying credentials, password incorrect or not set. Trying to force update"

        try {
            $null = net user $TestUser $TestUserPass 2>&1
            if ( -not ($FixSummary -eq "")) { $FixSummary += ", "}
            $FixSummary += "Password force updated"
        }
        catch {

            if ($null -ne $_.Exception.Message) {
                if ( -not ($FixSummary -eq "")) { $FixSummary += ", "}
                $FixSummary += "ERROR updating password"
                Write-Host "`tError: $($_.Exception.Message)"
            }
        }
    }
       
    #Verify if "User must change password at next logon is enabled". This is just in case.
    if ($LocalADSI.PasswordExpired -eq 1) {
        Write-Host "Password set to change at next logon."
        try {
            Write-Host "Disabling ""Change Password at Next Logon""."
            $LocalADSI.Put("PasswordExpired", 0)
            $LocalADSI.SetInfo()
            if ( -not ($FixSummary -eq "")) { $FixSummary += ", "}
            $FixSummary += "Disabled ""Change Password at Next Logon"""
        }
        catch {
            Write-Warning "Failed to disable ""User must change password at next logon"" Error: $($_.Exception.Message)"
        }
        
    }
    else {
        Write-Host """User must change password at next logon"" disabled"
    }

    #Verify "Ppassword never expires" enabled.
    if ( -not ($LocalADSI.UserFlags.Value -band 65536)) {

        try {

            Write-Host "Need to change property on ""Password Never Expires""."
            $LocalAccount | Set-LocalUser -PasswordNeverExpires $true -ErrorAction Stop
            Write-Host "Enabled ""Password Never Expires""."
            if ( -not ($FixSummary -eq "")) { $FixSummary += ", "}
            $FixSummary += "Enabled ""Password Never Expires"""

        }
        catch {

            if ($null -ne $_.Exception.ErrorName) {
                if ( -not ($FixSummary -eq "")) { $FixSummary += ", "}
                $FixSummary += "ERROR enabling ""Password never expires"""
                Write-Host $_.Exception.Message
            }

        }


    }
    else {

        Write-Host "User password is correctly set to never expire."

    }

}

else {

    Write-Host "INFO $([datetime]::Now) :User $TestUser does not exist."
    Exit 0

}

if ($FixSummary -eq "") {
    Write-Host "INFO $([datetime]::Now) : Did nothing. User correctly configured."
}
else {
    Write-Host "FIX $([datetime]::Now) :  $FixSummary."
}

#Finished!
Exit 0

#Endregion

