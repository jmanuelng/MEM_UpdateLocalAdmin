<#
.SYNOPSIS
    Detection script. Looks for a specific local user, verifies if exists, is enabled, has the correct password.

.DESCRIPTION
    For use as detection script in "Proactive Remediation" in Microsoft Intune.
    Looks for a specific local user, verifies if exists, is enabled, has the correct password.
    Gets status of the account and reports it back to Intune PR console.

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

$TestUser = "MYADMIN"
$TestUserPass = "MyP@ssw0rd"
$LocalAccount = Get-LocalUser -Name $TestUser -ErrorAction SilentlyContinue
$LocalADSI = [ADSI]"WinNT://$env:ComputerName/$TestUser,user"
$Result = 0
$ErrSummary = ""
Add-Type -AssemblyName System.DirectoryServices.AccountManagement 
$DS = New-Object System.DirectoryServices.AccountManagement.PrincipalContext([System.DirectoryServices.AccountManagement.ContextType]::Machine)

#Endregion

#Clean errors
$Error.Clear()
#New lines, easier to read Agentexecutor Log file.
Write-Host "`n`n"
Write-Host "Starting script execution"

#Verify if "Verify if users exists"
Write-Host "Verifying if user $TestUser exists."


if ($LocalAccount.Name -eq $TestUser) {

    Write-Host "`tUser $TestUser exists"
    $Result = $Result + 0

    #Verify if account is enabled.
    if ($LocalAccount.Enabled) {
        Write-Host "`tAccount is enabled"
        $Result = $Result + 0

        #Verify if "Change password at next logon is enabled"
        if ($LocalADSI.PasswordExpired -eq 1) {
            Write-Host "Password is set to change at next logon."
            $ErrSummary += """User must change password at next logon"""
            $Result = $Result + 1
        }
        else {
            """User must change password at next logon"" disabled"
            $Result = $Result + 0

            #Verify if Password is set correctly (No sense verifying password if set to be changed at next logon).
            Write-Host "Verifying password"

            if ($DS.ValidateCredentials($TestUser, $TestUserPass)) {

                Write-Host "`tPassword is set correctly"
                $Result = $Result + 0
            }
            else {
                Write-Host "`tPassword incorrect"
                if ( -not ($ErrSummary -eq "")) { $ErrSummary += ", "}
                $ErrSummary += "Incorrect Password"
                $Result = $Result + 1
            }

        }

        #Verify if "Password Neverd Expires is enabled"
        Write-Host "Verifying if ""Password Never Expires"" is enabled."

        if ($LocalADSI.UserFlags.Value -band 65536) {

            Write-Host "`t""Password Never Expires"" is enabled."
            $Result = $Result + 0
        }
        else {

            Write-Host "`t""Password Never Expires"" is disabled."
            if ( -not ($ErrSummary -eq "")) { $ErrSummary += ", "}
            $ErrSummary += """Password Never Expires"" disabled"
            $Result = $Result + 1
        }
        

    }
    else {
        Write-Host "Account $LocalAccount is disabled."
        $ErrSummary += "Account is disabled"
        $Result = $Result + 1
    }

}
else {

    Write-Host "INFO $([datetime]::Now) : User does not exist."
    $Result = Result + 0
    Exit 0
}


#Return result
if ($Result -eq 0) {

    Write-Host "INFO $([datetime]::Now) : User is correctly configured."
    Exit 0
}
else {
    Write-Host "ERROR $([datetime]::Now) : $ErrSummary"
    Exit 1
}


