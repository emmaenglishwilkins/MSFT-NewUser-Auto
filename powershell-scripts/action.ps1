
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
                Password = $user.Password # had to change this in the other one bc my column was named differently
                ForceChangePasswordNextLogin = $false
            })

        # this part didnt work lol revised scripts in powershell-scripts folder (add location and then license)
        if ($newUser) {
            Write-Host "User created: $($user.UserPrincipalName). Assigning license..."

            # Get the license SKU ID from the friendly name
            $skuId = (Get-AzureADSubscribedSku | Where-Object { $_.SkuPartNumber -eq $user.LicenseSkuId }).SkuId

            if ($skuId) {
                # Assign license to the user
                Set-AzureADUserLicense -ObjectId $newUser.ObjectId -AddLicenses @(@{SkuId = $skuId }) -RemoveLicenses @()
                Write-Host "License assigned to: $($user.UserPrincipalName)"
            } else {
                Write-Host "Error: License SKU ID not found for $($user.UserPrincipalName)"
            }
        }
    }
    catch {
        Write-Host "Error processing user: $($user.UserPrincipalName) - $_"
    }
}
