```powershell-scripts/take2.ps1
# this is bc my first one fucked up and now i have account with no license fuckkkk 

$users = Import-Csv -Path /home/emma/lice.csv

# Combined loop to update usage location and assign license
foreach ($user in $users) {                                              
    try {
        # Get user details based on UserPrincipalName
        $userDetails = Get-MgUser -UserId $user.UserPrincipalName
        
        if ($userDetails) {
            # Update usage location
            Write-Host "Updating usage location for: $($user.UserPrincipalName)"
            Update-MgUser -UserId $userDetails.Id -UsageLocation 'US'
            Write-Host "Updated usage location for: $($user.UserPrincipalName)"
            
            # Assign the license
            Write-Host "Assigning license to: $($user.UserPrincipalName)"
            $license = @{SkuId = $user.LicenseSkuId }
            Set-MgUserLicense -UserId $userDetails.Id -AddLicenses @($license) -RemoveLicenses @()
            Write-Host "License assigned to: $($user.UserPrincipalName)"
        } else {
            Write-Host "User not found: $($user.UserPrincipalName)"
        }
    }
    catch {
        Write-Host "Error processing user: $($user.UserPrincipalName) - $_"
    }
}