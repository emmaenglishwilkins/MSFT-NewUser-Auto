# Define the License SKU ID (same for all users)
# $skuId = "94763226-9b3c-4e75-a931-5c89701abe66"

# DisplayName	UserPrincipalName	PasswordProfile_password	LicenseSkuId
Connect-AzureAD
$users = Import-Csv -Path /home/emma/bulk_create.csv

# Loop through each user in the CSV
foreach ($user in $users) {
    try {
        Write-Host "Creating user: $($user.UserPrincipalName)..."

        # Create a new Entra ID user
        $newUser = New-AzureADUser -DisplayName $user.DisplayName `
            -UserPrincipalName $user.UserPrincipalName `
            -MailNickName ($user.UserPrincipalName -split "@")[0] `
            -AccountEnabled $true `
            -PasswordProfile (New-Object -TypeName Microsoft.Open.AzureAD.Model.PasswordProfile -Property @{
                Password = $user.PasswordProfile_password
                ForceChangePasswordNextLogin = $false
            })

        if ($newUser) {
            Write-Host "User created: $($user.UserPrincipalName). Assigning license..."

            # Update Usage Location (required before assigning a license)
            Write-Host "Assigning license to: $($user.UserPrincipalName)"
            $license = @{SkuId = $user.LicenseSkuId}  
            Write-Host "License: $($license.LicenseSkuId)"
            Update-MgUser -UserId $newUser.Id -UsageLocation "US"            
            Set-MgUserLicense -UserId $user.Id -AddLicenses @($license) -RemoveLicenses @() 

        } else {
            Write-Host "Error: Failed to create user $($user.UserPrincipalName)"
        }
    }
    catch {
        Write-Host "Error processing user: $($user.UserPrincipalName) - $_"
    }
}

