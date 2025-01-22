# this is bc my first one fucked up and now i have account with no license fuckkkk 

$users = Import-Csv -Path /home/emma/lice.csv

# first i had to add regions? idk why i had to do this seperatley im really tired 
foreach ($user in $users) {                                              
    try {
        # Get user details based on UserPrincipalName
        $userDetails = Get-MgUser -UserId $user.UserPrincipalName
        
        if ($userDetails) {
            Write-Host "Updating usage location for: $($user.UserPrincipalName)"
            
            # Set usage location
            Update-MgUser -UserId $userDetails.Id -UsageLocation 'US'
            
            Write-Host "Updated usage location for: $($user.UserPrincipalName)"
        } else {
            Write-Host "User not found: $($user.UserPrincipalName)"
        }
    }
    catch {
        Write-Host "Error updating user: $($user.UserPrincipalName) - $_"
    }
}


# then i added licenses 
foreach ($user in $users) {
    try {
        # Retrieve user details
        $userDetails = Get-MgUser -UserId $user.UserPrincipalName

        if ($userDetails) {
            Write-Host "Assigning license to: $($user.UserPrincipalName)"
            
            # Assign the license
            $license = @{SkuId = $user.LicenseSkuId }
            Set-MgUserLicense -UserId $userDetails.Id -AddLicenses @($license) -RemoveLicenses @()
            
            Write-Host "License assigned to: $($user.UserPrincipalName)"
        } else {
            Write-Host "User not found: $($user.UserPrincipalName)"
        }
    }
    catch {
        Write-Host "Error assigning license to: $($user.UserPrincipalName) - $_"
    }
}

