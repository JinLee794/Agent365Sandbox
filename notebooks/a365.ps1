<#
.SYNOPSIS
    Agent Identity Blueprint Setup Script for Azure Entra ID

.DESCRIPTION
    Interactive script to create and configure an Agent Identity Blueprint in Azure Entra ID.
    Supports step-by-step execution and automatically updates .env file with generated values.

.PARAMETER Step
    Specific step to run (1-4), or "all" to run all steps sequentially

.PARAMETER TenantId
    Azure AD Tenant ID (optional - will prompt if not provided)

.EXAMPLE
    .\a365.ps1 -Step all
    .\a365.ps1 -Step 1
    .\a365.ps1 -Step 2 -TenantId "your-tenant-id"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("menu", "1", "2", "3", "4", "all")]
    [string]$Step = "menu",
    
    [Parameter(Mandatory=$false)]
    [string]$TenantId
)

# Script variables
$script:envPath = Join-Path $PSScriptRoot ".env"
$script:tenantId = $TenantId
$script:blueprintAppId = $null
$script:blueprintObjectId = $null
$script:blueprintSecret = $null
$script:servicePrincipalId = $null

#region Helper Functions

function Write-Header {
    param([string]$Title)
    Write-Host "`n==========================================================`n" -ForegroundColor Magenta
    Write-Host $Title -ForegroundColor Yellow
    Write-Host "" -ForegroundColor Magenta
}

function Update-EnvFile {
    param(
        [string]$Key,
        [string]$Value
    )
    
    if (-not (Test-Path $script:envPath)) {
        $examplePath = Join-Path $PSScriptRoot ".env.example"
        if (Test-Path $examplePath) {
            Copy-Item $examplePath $script:envPath
            Write-Host "Created .env file from .env.example" -ForegroundColor Green
        } else {
            New-Item -Path $script:envPath -ItemType File | Out-Null
            Write-Host "Created new .env file" -ForegroundColor Green
        }
    }
    
    $envContent = Get-Content $script:envPath -Raw
    
    # Check if the key exists
    if ($envContent -match "(?m)^$Key=.*$") {
        # Update existing key
        $envContent = $envContent -replace "(?m)^$Key=.*$", "$Key=$Value"
        Write-Host "  Updated $Key in .env" -ForegroundColor Cyan
    } else {
        # Add new key
        $envContent += "`n$Key=$Value"
        Write-Host "  Added $Key to .env" -ForegroundColor Cyan
    }
    
    Set-Content -Path $script:envPath -Value $envContent.TrimEnd()
}

function Load-EnvFile {
    if (Test-Path $script:envPath) {
        Get-Content $script:envPath | ForEach-Object {
            if ($_ -match '^\s*([^#][^=]+)=(.*)$') {
                $key = $matches[1].Trim()
                $value = $matches[2].Trim()
                
                # Store all values as script variables for easy access
                if (-not [string]::IsNullOrWhiteSpace($value)) {
                    Set-Variable -Name $key -Value $value -Scope Script
                    
                    # Load specific values we need
                    if ($key -eq "AZURE_TENANT_ID" -and [string]::IsNullOrWhiteSpace($script:tenantId)) {
                        $script:tenantId = $value
                    }
                    if ($key -eq "AZURE_CLIENT_ID") {
                        $script:blueprintAppId = $value
                    }
                    if ($key -eq "AGENT_BLUEPRINT_ID") {
                        $script:blueprintObjectId = $value
                    }
                }
            }
        }
        Write-Host "Loaded existing .env file" -ForegroundColor Green
    }
}

function Get-TenantId {
    if ([string]::IsNullOrWhiteSpace($script:tenantId)) {
        $script:tenantId = $env:TENANT_ID
        if ([string]::IsNullOrWhiteSpace($script:tenantId)) {
            $script:tenantId = Read-Host "Enter your Azure AD Tenant ID"
        }
    }
    
    # Save tenant ID to .env
    Update-EnvFile -Key "AZURE_TENANT_ID" -Value $script:tenantId
    
    Write-Host "Using Tenant ID: $($script:tenantId)" -ForegroundColor Cyan
    return $script:tenantId
}

#endregion

#region Step Functions

function Step1-CreateBlueprint {
    param([switch]$Force)
    
    Write-Header "Step 1: Create Agent Identity Blueprint"
    
    # Check if blueprint already exists
    if (-not $Force -and -not [string]::IsNullOrWhiteSpace($script:blueprintAppId) -and -not [string]::IsNullOrWhiteSpace($script:blueprintObjectId)) {
        Write-Host "⚠️  Blueprint already exists:" -ForegroundColor Yellow
        Write-Host "   Application ID: $($script:blueprintAppId)" -ForegroundColor Cyan
        Write-Host "   Object ID: $($script:blueprintObjectId)" -ForegroundColor Cyan
        
        $overwrite = Read-Host "`nDo you want to create a new blueprint anyway? (y/N)"
        if ($overwrite -ne 'y' -and $overwrite -ne 'Y') {
            Write-Host "✓ Skipping - using existing blueprint" -ForegroundColor Green
            return $true
        }
        Write-Host "Creating new blueprint..." -ForegroundColor Yellow
    }
    
    $tid = Get-TenantId
    
    Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Yellow
    Connect-MgGraph -Scopes "AgentIdentityBlueprint.Create","User.Read" -TenantId $tid
    
    # Get the current user's ID
    $currentUser = Get-MgContext | Select-Object -ExpandProperty Account
    $user = Get-MgUser -UserId $currentUser
    
    Write-Host "Current user: $($user.DisplayName) ($($user.Id))" -ForegroundColor Cyan
    
    # Construct the body for the POST request
    $body = @{
        "@odata.type" = "Microsoft.Graph.AgentIdentityBlueprint"
        "displayName" = "My Agent Identity Blueprint"
        "sponsors@odata.bind" = @("https://graph.microsoft.com/v1.0/users/$($user.Id)")
        "owners@odata.bind" = @("https://graph.microsoft.com/v1.0/users/$($user.Id)")
    } | ConvertTo-Json -Depth 5
    
    Write-Host "Creating Agent Identity Blueprint..." -ForegroundColor Yellow
    $response = Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/beta/applications/graph.agentIdentityBlueprint" -Body $body -ContentType "application/json"
    
    if ($response) {
        Write-Host "`n✅ Success! Agent Identity Blueprint created successfully." -ForegroundColor Green
        Write-Host "Application ID: $($response.appId)" -ForegroundColor Cyan
        Write-Host "Object ID: $($response.id)" -ForegroundColor Cyan
        Write-Host "Display Name: $($response.displayName)" -ForegroundColor Cyan
        
        # Store values
        $script:blueprintAppId = $response.appId
        $script:blueprintObjectId = $response.id
        
        # Update .env file
        Write-Host "`nUpdating .env file..." -ForegroundColor Yellow
        Update-EnvFile -Key "AZURE_CLIENT_ID" -Value $script:blueprintAppId
        Update-EnvFile -Key "AGENT_BLUEPRINT_ID" -Value $script:blueprintObjectId
        
        Write-Host "`n✅ Step 1 completed!" -ForegroundColor Green
        return $true
    } else {
        Write-Host "❌ Failed to create Agent Identity Blueprint" -ForegroundColor Red
        return $false
    }
}

function Grant-DirectoryReadPermission {
    param(
        [string]$ServicePrincipalId,
        [string]$TenantId,
        [string]$ApplicationId
    )
    
    Write-Host "Configuring Directory.Read.All permission..." -ForegroundColor Yellow
    
    try {
        # Agent Blueprint service principals don't support traditional AppRoleAssignments
        # Instead, we need to add the permission through the application's API permissions
        
        Connect-MgGraph -Scopes "Application.ReadWrite.All" -TenantId $TenantId -ErrorAction SilentlyContinue
        
        # Get the Microsoft Graph service principal
        $graphSp = Get-MgServicePrincipal -Filter "appId eq '00000003-0000-0000-c000-000000000000'" -ErrorAction SilentlyContinue
        
        if (-not $graphSp) {
            Write-Host "⚠️  Could not find Microsoft Graph service principal" -ForegroundColor Yellow
            return $false
        }
        
        # Find the Directory.Read.All role
        $directoryReadRole = $graphSp.AppRoles | Where-Object { $_.Value -eq "Directory.Read.All" }
        
        if (-not $directoryReadRole) {
            Write-Host "⚠️  Could not find Directory.Read.All role" -ForegroundColor Yellow
            return $false
        }
        
        # Get the application to check existing permissions
        $app = Get-MgApplication -ApplicationId $ApplicationId -ErrorAction SilentlyContinue
        
        if (-not $app) {
            Write-Host "⚠️  Could not find application" -ForegroundColor Yellow
            return $false
        }
        
        # Check if the permission is already configured
        $requiredResourceAccess = $app.RequiredResourceAccess | Where-Object { $_.ResourceAppId -eq "00000003-0000-0000-c000-000000000000" }
        $alreadyConfigured = $requiredResourceAccess.ResourceAccess | Where-Object { $_.Id -eq $directoryReadRole.Id }
        
        if ($alreadyConfigured) {
            Write-Host "✅ Directory.Read.All permission already configured" -ForegroundColor Green
            return $true
        }
        
        # Note: Agent Blueprint service principals don't support traditional role assignments
        # The permissions are configured through Azure Portal admin consent
        Write-Host "⚠️  Agent Blueprint service principals use admin-configured permissions" -ForegroundColor Yellow
        Write-Host "   To grant Directory.Read.All permission:" -ForegroundColor Cyan
        Write-Host "   1. Go to Azure Portal → Entra ID → App registrations" -ForegroundColor Cyan
        Write-Host "   2. Find your Agent Blueprint application" -ForegroundColor Cyan
        Write-Host "   3. Click 'API permissions' on the left" -ForegroundColor Cyan
        Write-Host "   4. Click 'Add a permission'" -ForegroundColor Cyan
        Write-Host "   5. Select 'Microsoft Graph' → 'Application permissions'" -ForegroundColor Cyan
        Write-Host "   6. Search for and select 'Directory.Read.All'" -ForegroundColor Cyan
        Write-Host "   7. Click 'Add permissions'" -ForegroundColor Cyan
        Write-Host "   8. Click 'Grant admin consent for [Tenant]'" -ForegroundColor Cyan
        
        return $true
        
    } catch {
        Write-Host "⚠️  Could not verify Directory.Read.All permission: $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Host "   Please configure the permission manually in Azure Portal (see steps above)" -ForegroundColor Yellow
        return $false
    }
}

function Step2-CreatePrincipal {
    param([switch]$Force)
    
    Write-Header "Step 2: Create Agent Identity Blueprint Principal"
    
    $tid = Get-TenantId
    
    # Load blueprint ID if not in memory
    if ([string]::IsNullOrWhiteSpace($script:blueprintAppId)) {
        Load-EnvFile
        if ([string]::IsNullOrWhiteSpace($script:blueprintAppId)) {
            Write-Host "❌ Blueprint App ID not found. Please run Step 1 first." -ForegroundColor Red
            return $false
        }
    }
    
    # Check if principal already exists by trying to get it
    if (-not $Force) {
        Write-Host "Checking for existing service principal..." -ForegroundColor Yellow
        Connect-MgGraph -Scopes "Application.Read.All","AppRoleAssignment.ReadWrite.All" -TenantId $tid
        
        try {
            $existing = Get-MgServicePrincipal -Filter "appId eq '$($script:blueprintAppId)'" -ErrorAction SilentlyContinue
            if ($existing) {
                Write-Host "⚠️  Service Principal already exists:" -ForegroundColor Yellow
                Write-Host "   Service Principal ID: $($existing.Id)" -ForegroundColor Cyan
                
                $overwrite = Read-Host "`nDo you want to recreate it anyway? (y/N)"
                if ($overwrite -ne 'y' -and $overwrite -ne 'Y') {
                    Write-Host "✓ Skipping - using existing service principal" -ForegroundColor Green
                    $script:servicePrincipalId = $existing.Id
                    # Update .env with existing principal ID
                    Update-EnvFile -Key "AGENT_BLUEPRINT_PRINCIPAL_ID" -Value $existing.Id
                    
                    # Grant permissions to existing principal
                    Grant-DirectoryReadPermission -ServicePrincipalId $existing.Id -ApplicationId $script:blueprintObjectId -TenantId $tid | Out-Null
                    
                    return $true
                }
                Write-Host "⚠️  Note: Service principal already exists. Will continue with existing one." -ForegroundColor Yellow
                $script:servicePrincipalId = $existing.Id
                Update-EnvFile -Key "AGENT_BLUEPRINT_PRINCIPAL_ID" -Value $existing.Id
                
                # Grant permissions
                Grant-DirectoryReadPermission -ServicePrincipalId $existing.Id -ApplicationId $script:blueprintObjectId -TenantId $tid | Out-Null
                
                Write-Host "`n✅ Step 2 completed (using existing principal)!" -ForegroundColor Green
                return $true
            }
        } catch {
            Write-Host "Could not check for existing principal, proceeding..." -ForegroundColor Yellow
        }
    }
    
    Write-Host "Using Blueprint App ID: $($script:blueprintAppId)" -ForegroundColor Cyan
    Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Yellow
    Connect-MgGraph -Scopes "AgentIdentityBlueprintPrincipal.Create","AppRoleAssignment.ReadWrite.All" -TenantId $tid
    
    $principalBody = @{
        appId = $script:blueprintAppId
    }
    
    Write-Host "Creating Service Principal..." -ForegroundColor Yellow
    try {
        $principalResponse = Invoke-MgGraphRequest -Method POST `
            -Uri "https://graph.microsoft.com/beta/serviceprincipals/graph.agentIdentityBlueprintPrincipal" `
            -Headers @{ "OData-Version" = "4.0" } `
            -Body ($principalBody | ConvertTo-Json) `
            -ContentType "application/json"
        
        if ($principalResponse) {
            Write-Host "✅ Agent Identity Blueprint Principal created successfully." -ForegroundColor Green
            Write-Host "Service Principal ID: $($principalResponse.id)" -ForegroundColor Cyan
            
            $script:servicePrincipalId = $principalResponse.id
            
            # Mark step as complete in .env
            Update-EnvFile -Key "AGENT_BLUEPRINT_PRINCIPAL_ID" -Value $principalResponse.id
            
            # Grant Directory.Read.All permission
            Grant-DirectoryReadPermission -ServicePrincipalId $principalResponse.id -ApplicationId $script:blueprintObjectId -TenantId $tid | Out-Null
            
            Write-Host "`n✅ Step 2 completed!" -ForegroundColor Green
            return $true
        }
    } catch {
        # Handle 409 Conflict - service principal already exists
        if ($_.Exception.Message -match "409 Conflict" -or $_.Exception.Message -match "already in use") {
            Write-Host "⚠️  Service principal already exists. Retrieving existing one..." -ForegroundColor Yellow
            
            try {
                $existing = Get-MgServicePrincipal -Filter "appId eq '$($script:blueprintAppId)'" -ErrorAction SilentlyContinue
                if ($existing) {
                    Write-Host "✅ Using existing service principal" -ForegroundColor Green
                    Write-Host "Service Principal ID: $($existing.Id)" -ForegroundColor Cyan
                    
                    $script:servicePrincipalId = $existing.Id
                    Update-EnvFile -Key "AGENT_BLUEPRINT_PRINCIPAL_ID" -Value $existing.Id
                    
                    # Grant Directory.Read.All permission
                    Grant-DirectoryReadPermission -ServicePrincipalId $existing.Id -ApplicationId $script:blueprintObjectId -TenantId $tid | Out-Null
                    
                    Write-Host "`n✅ Step 2 completed!" -ForegroundColor Green
                    return $true
                }
            } catch {
                Write-Host "❌ Could not retrieve existing service principal: $($_.Exception.Message)" -ForegroundColor Red
                return $false
            }
        }
        
        Write-Host "❌ Failed to create Agent Identity Blueprint Principal: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
    
    Write-Host "❌ Failed to create Agent Identity Blueprint Principal" -ForegroundColor Red
    return $false
}

function Step3-AddCredentials {
    param([switch]$Force)
    
    Write-Header "Step 3: Add Credential (Certificate or Client Secret)"
    
    $tid = Get-TenantId
    
    # Load blueprint ID if not in memory
    if ([string]::IsNullOrWhiteSpace($script:blueprintObjectId)) {
        Load-EnvFile
        if ([string]::IsNullOrWhiteSpace($script:blueprintObjectId)) {
            Write-Host "❌ Blueprint Object ID not found. Please run Step 1 first." -ForegroundColor Red
            return $false
        }
    }
    
    # Check if credentials already exist
    if (-not $Force) {
        Write-Host "Checking for existing credentials..." -ForegroundColor Yellow
        Connect-MgGraph -Scopes "Application.Read.All" -TenantId $tid
        
        try {
            $app = Get-MgApplication -ApplicationId $script:blueprintObjectId -ErrorAction SilentlyContinue
            $hasPassword = $app.PasswordCredentials.Count -gt 0
            $hasCert = $app.KeyCredentials.Count -gt 0
            
            if ($hasPassword -or $hasCert) {
                Write-Host "⚠️  Application already has credentials:" -ForegroundColor Yellow
                if ($hasPassword) {
                    Write-Host "   Secrets: $($app.PasswordCredentials.Count)" -ForegroundColor Cyan
                    foreach ($cred in $app.PasswordCredentials) {
                        Write-Host "     - $($cred.DisplayName) (expires: $($cred.EndDateTime))" -ForegroundColor Cyan
                    }
                }
                if ($hasCert) {
                    Write-Host "   Certificates: $($app.KeyCredentials.Count)" -ForegroundColor Cyan
                    foreach ($cert in $app.KeyCredentials) {
                        Write-Host "     - $($cert.DisplayName) (expires: $($cert.EndDateTime))" -ForegroundColor Cyan
                    }
                }
                
                $overwrite = Read-Host "`nDo you want to add another credential? (y/N)"
                if ($overwrite -ne 'y' -and $overwrite -ne 'Y') {
                    Write-Host "✓ Skipping - using existing credentials" -ForegroundColor Green
                    # Mark as complete if credentials exist
                    if ($hasPassword) {
                        Update-EnvFile -Key "AZURE_CLIENT_SECRET_KEY_ID" -Value $app.PasswordCredentials[0].KeyId
                    } elseif ($hasCert) {
                        Update-EnvFile -Key "AZURE_CLIENT_CERT_THUMBPRINT" -Value $app.KeyCredentials[0].KeyId
                    }
                    return $true
                }
                Write-Host "Adding new credential..." -ForegroundColor Yellow
            }
        } catch {
            Write-Host "Could not check for existing credentials, proceeding..." -ForegroundColor Yellow
        }
    }
    
    # Ask user which type of credential to create
    Write-Host "`nSelect credential type:" -ForegroundColor Yellow
    Write-Host "  1. Client Secret (password)" -ForegroundColor Cyan
    Write-Host "  2. Certificate (self-signed, for local development)" -ForegroundColor Cyan
    $credChoice = Read-Host "Enter choice (1 or 2)"
    
    Write-Host "Using Blueprint Object ID: $($script:blueprintObjectId)" -ForegroundColor Cyan
    Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Yellow
    Connect-MgGraph -Scopes "AgentIdentityBlueprint.AddRemoveCreds.All" -TenantId $tid
    
    if ($credChoice -eq "2") {
        # Certificate path - Cross-platform using OpenSSL
        Write-Host "`nGenerating self-signed certificate using OpenSSL..." -ForegroundColor Yellow
        
        # Check if openssl is available
        $opensslPath = Get-Command openssl -ErrorAction SilentlyContinue
        if (-not $opensslPath) {
            Write-Host "❌ OpenSSL not found. Please install OpenSSL:" -ForegroundColor Red
            Write-Host "   macOS: brew install openssl" -ForegroundColor Yellow
            Write-Host "   Linux: sudo apt-get install openssl" -ForegroundColor Yellow
            Write-Host "   Windows: Download from https://slproweb.com/products/Win32OpenSSL.html" -ForegroundColor Yellow
            return $false
        }
        
        $certPath = Join-Path $PSScriptRoot "certs"
        if (-not (Test-Path $certPath)) {
            New-Item -ItemType Directory -Path $certPath | Out-Null
            Write-Host "Created certs directory: $certPath" -ForegroundColor Green
        }
        
        $certName = "AgentBlueprintCert"
        $keyFile = Join-Path $certPath "$certName.key"
        $certFile = Join-Path $certPath "$certName.crt"
        $pemFile = Join-Path $certPath "$certName.pem"
        
        # Generate private key and self-signed certificate using OpenSSL
        $subject = "/CN=AgentBlueprintCertificate/O=Development/C=US"
        $days = 365
        
        try {
            # Generate private key
            & openssl genrsa -out $keyFile 2048 2>&1 | Out-Null
            
            # Generate self-signed certificate
            & openssl req -new -x509 -key $keyFile -out $certFile -days $days -subj $subject 2>&1 | Out-Null
            
            # Combine key and cert into PEM format (for Python SDK)
            $keyContent = Get-Content $keyFile -Raw
            $certContent = Get-Content $certFile -Raw
            Set-Content -Path $pemFile -Value ($keyContent + $certContent)
            
            Write-Host "✅ Certificate generated successfully" -ForegroundColor Green
            Write-Host "   Private Key: $keyFile" -ForegroundColor Cyan
            Write-Host "   Certificate: $certFile" -ForegroundColor Cyan
            Write-Host "   PEM (combined): $pemFile" -ForegroundColor Cyan
            
            # Calculate thumbprint using OpenSSL
            $thumbprintOutput = & openssl x509 -in $certFile -noout -fingerprint -sha1 2>&1
            if ($thumbprintOutput -match "SHA1 Fingerprint=([A-F0-9:]+)") {
                $thumbprint = $matches[1] -replace ":", ""
                Write-Host "   Thumbprint: $thumbprint" -ForegroundColor Cyan
            } else {
                Write-Host "⚠️  Could not calculate thumbprint" -ForegroundColor Yellow
                $thumbprint = ""
            }
            
            # Read certificate in Base64 for Azure upload (DER format without line breaks)
            $certDerBase64 = & openssl x509 -in $certFile -outform DER | & openssl base64 -A
            
            # Upload certificate to Azure AD using addKey method
            Write-Host "`nUploading certificate to Azure AD..." -ForegroundColor Yellow
            
            # Get existing credentials to preserve them
            $app = Get-MgApplication -ApplicationId $script:blueprintObjectId
            $existingKeyCreds = @()
            if ($app.KeyCredentials) {
                $existingKeyCreds = $app.KeyCredentials
            }
            
            # Read certificate start and end dates
            $startDate = & openssl x509 -in $certFile -noout -startdate | ForEach-Object { $_ -replace "notBefore=", "" }
            $endDate = & openssl x509 -in $certFile -noout -enddate | ForEach-Object { $_ -replace "notAfter=", "" }
            
            # Convert dates to ISO 8601 format
            $startDateTime = [DateTime]::ParseExact($startDate, "MMM dd HH:mm:ss yyyy 'GMT'", [System.Globalization.CultureInfo]::InvariantCulture)
            $endDateTime = [DateTime]::ParseExact($endDate, "MMM dd HH:mm:ss yyyy 'GMT'", [System.Globalization.CultureInfo]::InvariantCulture)
            
            # Create new key credential
            $newKeyCred = @{
                type = "AsymmetricX509Cert"
                usage = "Verify"
                key = [System.Convert]::FromBase64String($certDerBase64)
                displayName = $certName
                startDateTime = $startDateTime.ToString("o")
                endDateTime = $endDateTime.ToString("o")
            }
            
            # Combine with existing credentials
            $allKeyCreds = @($existingKeyCreds) + @($newKeyCred)
            
            # Update application with all credentials using beta endpoint (required for Agent Blueprints)
            $updateBody = @{
                keyCredentials = $allKeyCreds
            } | ConvertTo-Json -Depth 10
            
            try {
                Invoke-MgGraphRequest -Method PATCH `
                    -Uri "https://graph.microsoft.com/beta/applications/$($script:blueprintObjectId)" `
                    -Body $updateBody `
                    -ContentType "application/json"
                
                Write-Host "✅ Certificate uploaded to Azure AD" -ForegroundColor Green
            } catch {
                # Parse the error to provide better feedback
                $errorMessage = $_.Exception.Message
                
                if ($errorMessage -match "not supported" -or $errorMessage -match "BadRequest") {
                    Write-Host "❌ Certificate upload failed:" -ForegroundColor Red
                    Write-Host "   Agent Identity Blueprints may not support certificate credentials." -ForegroundColor Yellow
                    Write-Host "   Please use Client Secret (option 1) instead." -ForegroundColor Yellow
                    Write-Host "`nError details: $errorMessage" -ForegroundColor Gray
                } else {
                    Write-Host "❌ Failed to upload certificate: $errorMessage" -ForegroundColor Red
                }
                throw
            }
            
            # Update .env file
            Update-EnvFile -Key "AZURE_CLIENT_CERT_PATH" -Value "./certs/$certName.pem"
            if ($thumbprint) {
                Update-EnvFile -Key "AZURE_CLIENT_CERT_THUMBPRINT" -Value $thumbprint
            }
            # Mark credential as configured
            Update-EnvFile -Key "AZURE_CLIENT_CREDENTIAL_TYPE" -Value "certificate"
            
            Write-Host "`n✅ Certificate configured successfully!" -ForegroundColor Green
            Write-Host "⚠️  Keep the private key file secure and do not commit to source control!" -ForegroundColor Red
            
        } catch {
            Write-Host "❌ Failed to generate or upload certificate: $($_.Exception.Message)" -ForegroundColor Red
            return $false
        }
        
    } else {
        # Client Secret path (default)
        $displayName = "Agent Blueprint Secret"
        $endDate = (Get-Date).AddYears(1).ToString("o")
        
        $passwordCredential = @{
            displayName = $displayName
            endDateTime = $endDate
        }
        
        Write-Host "Adding client secret..." -ForegroundColor Yellow
        $secretResponse = Add-MgApplicationPassword -ApplicationId $script:blueprintObjectId -PasswordCredential $passwordCredential
        
        if ($secretResponse) {
            Write-Host "✅ Client secret created successfully." -ForegroundColor Green
            Write-Host "Secret ID: $($secretResponse.KeyId)" -ForegroundColor Cyan
            Write-Host "Secret Text: $($secretResponse.SecretText)" -ForegroundColor Red
            Write-Host "`n⚠️  IMPORTANT: Save the secret text above - it cannot be retrieved again!" -ForegroundColor Red
            
            $script:blueprintSecret = $secretResponse.SecretText
            
            # Save secret to .env
            Update-EnvFile -Key "AZURE_CLIENT_SECRET" -Value $script:blueprintSecret
            Update-EnvFile -Key "AZURE_CLIENT_SECRET_KEY_ID" -Value $secretResponse.KeyId
            # Mark credential type
            Update-EnvFile -Key "AZURE_CLIENT_CREDENTIAL_TYPE" -Value "secret"
            
            Write-Host "`n✅ Client secret saved to .env file" -ForegroundColor Green
        } else {
            Write-Host "❌ Failed to create client secret" -ForegroundColor Red
            return $false
        }
    }
    
    Write-Host "`n✅ Step 3 completed!" -ForegroundColor Green
    return $true
}

function Step4-ConfigureScope {
    param([switch]$Force)
    
    Write-Header "Step 4: Configure Identifier URI and OAuth Scope"
    
    $tid = Get-TenantId
    
    # Load blueprint IDs if not in memory
    if ([string]::IsNullOrWhiteSpace($script:blueprintAppId) -or [string]::IsNullOrWhiteSpace($script:blueprintObjectId)) {
        Load-EnvFile
        if ([string]::IsNullOrWhiteSpace($script:blueprintAppId) -or [string]::IsNullOrWhiteSpace($script:blueprintObjectId)) {
            Write-Host "❌ Blueprint IDs not found. Please run Step 1 first." -ForegroundColor Red
            return $false
        }
    }
    
    # Check if identifier URI and scope already configured
    if (-not $Force) {
        Write-Host "Checking for existing configuration..." -ForegroundColor Yellow
        Connect-MgGraph -Scopes "Application.Read.All" -TenantId $tid
        
        try {
            $app = Get-MgApplication -ApplicationId $script:blueprintObjectId -ErrorAction SilentlyContinue
            if ($app -and $app.IdentifierUris.Count -gt 0 -and $app.Api.Oauth2PermissionScopes.Count -gt 0) {
                Write-Host "⚠️  Application already configured:" -ForegroundColor Yellow
                Write-Host "   Identifier URI: $($app.IdentifierUris[0])" -ForegroundColor Cyan
                Write-Host "   OAuth Scopes: $($app.Api.Oauth2PermissionScopes.Count)" -ForegroundColor Cyan
                foreach ($scope in $app.Api.Oauth2PermissionScopes) {
                    Write-Host "     - $($scope.Value): $($scope.AdminConsentDisplayName)" -ForegroundColor Cyan
                }
                
                $overwrite = Read-Host "`nDo you want to reconfigure? (y/N)"
                if ($overwrite -ne 'y' -and $overwrite -ne 'Y') {
                    Write-Host "✓ Skipping - using existing configuration" -ForegroundColor Green
                    return $true
                }
                Write-Host "Updating configuration..." -ForegroundColor Yellow
            }
        } catch {
            Write-Host "Could not check for existing configuration, proceeding..." -ForegroundColor Yellow
        }
    }
    
    Write-Host "Using Blueprint App ID: $($script:blueprintAppId)" -ForegroundColor Cyan
    Write-Host "Using Blueprint Object ID: $($script:blueprintObjectId)" -ForegroundColor Cyan
    Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Yellow
    Connect-MgGraph -Scopes "AgentIdentityBlueprint.ReadWrite.All" -TenantId $tid
    
    $IdentifierUri = "api://$($script:blueprintAppId)"
    $ScopeId = [guid]::NewGuid()
    
    # Construct the OAuth2 permission scope
    $scope = @{
        adminConsentDescription = "Allow the application to access the agent on behalf of the signed-in user."
        adminConsentDisplayName = "Access agent"
        id = $ScopeId
        isEnabled = $true
        type = "User"
        value = "access_agent"
    }
    
    # Construct the update body
    $updateBody = @{
        identifierUris = @($IdentifierUri)
        api = @{
            oauth2PermissionScopes = @($scope)
        }
    } | ConvertTo-Json -Depth 5
    
    Write-Host "Configuring identifier URI and scope..." -ForegroundColor Yellow
    try {
        Invoke-MgGraphRequest -Method PATCH `
            -Uri "https://graph.microsoft.com/beta/applications/$($script:blueprintObjectId)" `
            -Body $updateBody `
            -ContentType "application/json"
    } catch {
        Write-Host "❌ Failed to configure: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
    
    Write-Host "✅ Identifier URI and OAuth scope configured successfully." -ForegroundColor Green
    Write-Host "Identifier URI: $IdentifierUri" -ForegroundColor Cyan
    Write-Host "OAuth Scope: access_agent" -ForegroundColor Cyan
    
    # Mark step as complete
    Update-EnvFile -Key "AGENT_BLUEPRINT_IDENTIFIER_URI" -Value $IdentifierUri
    Update-EnvFile -Key "AGENT_BLUEPRINT_SCOPE" -Value "access_agent"
    
    Write-Host "`n✅ Step 4 completed!" -ForegroundColor Green
    return $true
}

#endregion

#region Menu

function Show-Menu {
    Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║      Agent Identity Blueprint Setup - Main Menu           ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    # Load .env first to ensure all variables are available
    if (Test-Path $script:envPath) {
        Get-Content $script:envPath | ForEach-Object {
            if ($_ -match '^\s*([^#][^=]+)=(.*)$') {
                $key = $matches[1].Trim()
                $value = $matches[2].Trim()
                
                # Store all values as script variables for easy access
                if (-not [string]::IsNullOrWhiteSpace($value)) {
                    Set-Variable -Name $key -Value $value -Scope Script -Force
                }
            }
        }
    }
    
    # Check completion status from .env markers (simple and fast)
    $step1Complete = -not [string]::IsNullOrWhiteSpace($script:blueprintAppId) -and 
                     -not [string]::IsNullOrWhiteSpace($script:blueprintObjectId)
    
    # Check for completion markers set by each step
    $step2Complete = -not [string]::IsNullOrWhiteSpace((Get-Variable -Name "AGENT_BLUEPRINT_PRINCIPAL_ID" -Scope Script -ValueOnly -ErrorAction SilentlyContinue))
    
    # Check credential type and completion
    $credType = Get-Variable -Name "AZURE_CLIENT_CREDENTIAL_TYPE" -Scope Script -ValueOnly -ErrorAction SilentlyContinue
    $hasSecret = -not [string]::IsNullOrWhiteSpace((Get-Variable -Name "AZURE_CLIENT_SECRET" -Scope Script -ValueOnly -ErrorAction SilentlyContinue))
    $hasCert = -not [string]::IsNullOrWhiteSpace((Get-Variable -Name "AZURE_CLIENT_CERT_THUMBPRINT" -Scope Script -ValueOnly -ErrorAction SilentlyContinue))
    $step3Complete = $hasSecret -or $hasCert
    
    $step4Complete = -not [string]::IsNullOrWhiteSpace((Get-Variable -Name "AGENT_BLUEPRINT_IDENTIFIER_URI" -Scope Script -ValueOnly -ErrorAction SilentlyContinue))
    
    Write-Host "  1. Create Agent Identity Blueprint" -ForegroundColor Yellow -NoNewline
    if ($step1Complete) { Write-Host " [COMPLETED]" -ForegroundColor Green } else { Write-Host "" }
    
    Write-Host "  2. Create Agent Identity Blueprint Principal" -ForegroundColor Yellow -NoNewline
    if ($step2Complete) { Write-Host " [COMPLETED]" -ForegroundColor Green } else { Write-Host "" }
    
    Write-Host "  3. Add Credential (Certificate or Client Secret)" -ForegroundColor Yellow -NoNewline
    if ($step3Complete) { 
        if ($credType -eq "certificate") {
            Write-Host " [COMPLETED - Certificate]" -ForegroundColor Green 
        } elseif ($credType -eq "secret") {
            Write-Host " [COMPLETED - Client Secret]" -ForegroundColor Green
        } elseif ($hasSecret -and $hasCert) {
            Write-Host " [COMPLETED - Both]" -ForegroundColor Green
        } else {
            Write-Host " [COMPLETED]" -ForegroundColor Green
        }
    } else { 
        Write-Host "" 
    }
    
    Write-Host "  4. Configure Identifier URI and OAuth Scope" -ForegroundColor Yellow -NoNewline
    if ($step4Complete) { Write-Host " [COMPLETED]" -ForegroundColor Green } else { Write-Host "" }
    
    Write-Host ""
    Write-Host "  all. Run All Steps Sequentially" -ForegroundColor Green
    Write-Host "  q. Quit" -ForegroundColor Red
    Write-Host ""
    
    if (Test-Path $script:envPath) {
        Write-Host "Current .env configuration:" -ForegroundColor Cyan
        Load-EnvFile
        if (-not [string]::IsNullOrWhiteSpace($script:tenantId)) {
            Write-Host "  ✓ Tenant ID: $($script:tenantId)" -ForegroundColor Green
        }
        if (-not [string]::IsNullOrWhiteSpace($script:blueprintAppId)) {
            Write-Host "  ✓ Blueprint App ID: $($script:blueprintAppId)" -ForegroundColor Green
        }
        if (-not [string]::IsNullOrWhiteSpace($script:blueprintObjectId)) {
            Write-Host "  ✓ Blueprint Object ID: $($script:blueprintObjectId)" -ForegroundColor Green
        }
        Write-Host ""
        Write-Host "  Note: Completed steps will be skipped unless you explicitly" -ForegroundColor Gray
        Write-Host "        choose to overwrite when prompted." -ForegroundColor Gray
        Write-Host ""
    }
}

function Start-Menu {
    while ($true) {
        Show-Menu
        $choice = Read-Host "Select an option"
        
        switch ($choice) {
            "1" { Step1-CreateBlueprint -Force:$false }
            "2" { Step2-CreatePrincipal -Force:$false }
            "3" { Step3-AddCredentials -Force:$false }
            "4" { Step4-ConfigureScope -Force:$false }
            "all" {
                if ((Step1-CreateBlueprint) -and 
                    (Step2-CreatePrincipal) -and 
                    (Step3-AddCredentials) -and 
                    (Step4-ConfigureScope)) {
                    
                    Write-Header "✅ All Steps Completed Successfully!"
                    Write-Host "Agent Identity Blueprint Summary:" -ForegroundColor Yellow
                    Write-Host "  Tenant ID: $($script:tenantId)" -ForegroundColor Cyan
                    Write-Host "  Application ID: $($script:blueprintAppId)" -ForegroundColor Cyan
                    Write-Host "  Object ID: $($script:blueprintObjectId)" -ForegroundColor Cyan
                    Write-Host "  Identifier URI: api://$($script:blueprintAppId)" -ForegroundColor Cyan
                    Write-Host "  OAuth Scope: access_agent" -ForegroundColor Cyan
                    Write-Host "`nConfiguration saved to: $($script:envPath)" -ForegroundColor Green
                }
            }
            "q" { 
                Write-Host "Exiting..." -ForegroundColor Yellow
                return 
            }
            default { 
                Write-Host "Invalid option. Please try again." -ForegroundColor Red 
            }
        }
        
        if ($choice -ne "q") {
            Write-Host "`nPress Enter to continue..." -ForegroundColor Gray
            Read-Host
        }
    }
}

#endregion

#region Main Execution

# Load existing .env if available
Load-EnvFile

# Execute based on parameter
switch ($Step) {
    "menu" { Start-Menu }
    "1" { Step1-CreateBlueprint }
    "2" { Step2-CreatePrincipal }
    "3" { Step3-AddCredentials }
    "4" { Step4-ConfigureScope }
    "all" {
        if ((Step1-CreateBlueprint) -and 
            (Step2-CreatePrincipal) -and 
            (Step3-AddCredentials) -and 
            (Step4-ConfigureScope)) {
            
            Write-Header "✅ All Steps Completed Successfully!"
            Write-Host "Agent Identity Blueprint Summary:" -ForegroundColor Yellow
            Write-Host "  Tenant ID: $($script:tenantId)" -ForegroundColor Cyan
            Write-Host "  Application ID: $($script:blueprintAppId)" -ForegroundColor Cyan
            Write-Host "  Object ID: $($script:blueprintObjectId)" -ForegroundColor Cyan
            Write-Host "  Identifier URI: api://$($script:blueprintAppId)" -ForegroundColor Cyan
            Write-Host "  OAuth Scope: access_agent" -ForegroundColor Cyan
            Write-Host "`nConfiguration saved to: $($script:envPath)" -ForegroundColor Green
        }
    }
}

#endregion