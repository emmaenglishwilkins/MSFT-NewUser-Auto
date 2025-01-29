```powershell-scripts/take2.ps1
# this is bc my first one fucked up and now i have account with no license fuckkkk 

$users = Import-Csv -Path /home/emma/bulk_create.csv

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

# bulk assign license
foreach ($user in $users) {
    try {   
        Write-Host "Assigning license to: $($user.UserPrincipalName)"
        $license = @{SkuId = $user.LicenseSkuId}  
        Write-Host "License: $($license.LicenseSkuId)"
        Update-MgUser -UserId $user.UserPrincipalName -UsageLocation "US"            
        Set-MgUserLicense -UserId $user.UserPrincipalName -AddLicenses @($license) -RemoveLicenses @() 
    }
    catch {
        Write-Host "Error processing user: $($user.UserPrincipalName) - $_"
    }
}


# just assign single license
$user = Get-MgUser -UserId $user.UserPrincipalName    
$license = @{SkuId = $user}  
Update-MgUser -UserId $user.Id -UsageLocation "US"            
Set-MgUserLicense -UserId $user.Id -AddLicenses @($license) -RemoveLicenses @()

# check - yayyyayayayayayayayayaaayyayayayayaay
foreach ($user in $users) {
    Get-MgUserLicenseDetail -UserId $user.UserPrincipalName
}