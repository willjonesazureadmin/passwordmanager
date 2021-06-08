Param(   
    [Parameter(Mandatory = $false)]
    [string]
    $parametersFilePath = ".\deployment\arm\parameters\azuredeploy.parameters.json",

    [Parameter(Mandatory = $false)]
    [string]
    $frontEndAppSettingsPath = ".\frontend\wwwroot\appsettings.json",  

    [Parameter(Mandatory = $false)]
    [string]
    $frontEndAppSettingsSamplePath = "appsettings.json",  
  
    [Parameter(Mandatory = $false)]
    [string]
    $backendAppSettingsSecretSamplePath = "appsettingssecrets.json", 

    [Parameter(Mandatory = $false)]
    [string]
    $parametersFileSamplePath = "azuredeploy.parameters.json", 
   
    [Parameter(Mandatory = $false)]
    [string]
    $samplesPath = ".\deployment\samples\",

    [Parameter(Mandatory = $false)]
    [string]
    $repositoryUrl= "https://github.com/willjonesazureadmin/passwordmanager",

    [Parameter(Mandatory = $false)]
    [string]
    $keyvaultName = "aapasmannkv",

    [Parameter(Mandatory = $false)]
    [string]
    $backendApplicationName = "awa-weu-pmp-be-001",

    [Parameter(Mandatory = $false)]
    [string]
    $frontendApplicationName = "swa-pmp-fe-001",

    [Parameter(Mandatory = $false)]
    [string]
    $deploymentSubscriptionId = "9cd3389c-90fe-414d-b06e-ccd526ad00f0",

    [Parameter(Mandatory = $false)]
    [string]
    $deploymentResourceGroup = "lz2-passman-rg",

    [Parameter(Mandatory = $false)]
    [string]
    $dnsZoneSubscription = "484147e9-d24d-41b4-86a8-50819355deb7",

    [Parameter(Mandatory = $false)]
    [string]
    $dnsZoneResourceGroup = "ss-dns-rg",

    [Parameter(Mandatory = $false)]
    [string]
    $customDnsZone = "azureadmin.co.uk",

    [Parameter(Mandatory = $false)]
    [string]
    $frontendCustomDnsName = "passman",
  
    [Parameter(Mandatory = $false)]
    [string]
    $tenantDomainName = "azureadmin.co.uk",
  
    [Parameter(Mandatory = $false)]
    [string]
    $githubServicePrincpalName = "sp-github-passman",

    [Parameter(Mandatory = $false)]
    [bool]
    $resetExistingApplications = $false,
    
    [Parameter(Mandatory = $false)]
    [bool]
    $resetApplicationSecrets = $false,

    [Parameter(Mandatory = $false)]
    [bool]
    $resetGitHubSecrets = $false,

    [Parameter(Mandatory = $false)]
    [bool]
    $installAzModules = $false,

    [Parameter(Mandatory = $false)]
    [bool]
    $loginToPSandCLI = $false
)

function LoadFile() {
 [CmdletBinding()]
 Param
 (
     [Parameter(Mandatory = $true)]
     [string]
     $FilePath
 )
    ###Load file content from local repo
    Write-Host "Loading file from $FilePath" -ForegroundColor Yellow
    $content = Get-Content -Path $FilePath 
    Write-Host "Content loaded" -ForegroundColor Green
    return $content        
}

function ExportFile($FilePath, $content) {
    #Write file content to local repo
    Write-Host "Writing file to $FilePath" -ForegroundColor Yellow
    $content  | Set-Content -Path $FilePath -Force 
    Write-Host "Content written" -ForegroundColor Green    
}


function AmendManifestForBackEnd($object, $knownApp) {
    #Amend the backend manifest file ready to be sent to Azure AD
    Write-Host "Amending manifest for application" $object.AppId -ForegroundColor Yellow
    $object.api.knownClientApplications[0] = $knownApp.AppId
    Write-Host "Manifest Amended" -ForegroundColor green
    return $object
}

function AmendManifestForFrontEnd($object, $knownApp, $knownManifest, $frontendReplyUrl) {
    #Amend the frontend manifest file ready to be sent to Azure AD
    Write-Host "Amending manifest for application" $object.AppId -ForegroundColor Yellow
    $object.requiredResourceAccess[0].resourceAppId = $knownApp.AppId
    $object.requiredResourceAccess[0].resourceAccess[0].id = $knownManifest.api.oauth2PermissionScopes[0].id
    $object.spa.redirectUris[0] = $frontendReplyUrl
    Write-Host "Manifest Amended" -ForegroundColor green
    return $object
}




function ProcessManifest($filePath, $application, $appType, $knownApp, $updatedManifest, $frontendReplyUrl) {
    #Process the manifest files for applications
    Write-Host "Getting manifest settings for application" $application.appId -ForegroundColor yellow
    $fullPath = $filePath + $apptype + "manifest.json"
    $content = LoadFile $fullPath | ConvertFrom-Json
    switch ($appType) {
        backend { $content = AmendManifestForBackEnd $content $knownApp }
        frontend { $content = AmendManifestForFrontEnd $content $knownApp $updatedManifest $frontendReplyUrl }
    }

    ConvertTo-Json -InputObject $content -Depth 50 | Out-File .\$appType.temp.json 
    Write-Host "Manifest temp file saved" -ForegroundColor Green
    return $content

}

function UploadManifest($application, $appType, $content) {
    #Upload the manifest files to Azure AD
    Write-Host "Applying manifest settings for application " $application.appId -ForegroundColor yellow
    $url = 'https://graph.microsoft.com/v1.0/applications/' + $application.ObjectId
    $body = Get-Content .\$appType.temp.json
    $body = $body -replace "`"", "\`""
    az rest --method PATCH --uri $url --headers 'Content-Type=application/json' --body "$body"
    $content = az rest --method GET --uri $url
    return $content | ConvertFrom-Json
}

function CreateApp() {
 [CmdletBinding()]
 Param
 (
     [Parameter(Mandatory = $true)]
     [string]
     $applicationName,

     [Parameter(Mandatory = $true)]
     [string]
     $tenantDomainName
 )

    #Create Azure AD Application registrations for frontend and backend apps if they do not exist
    Write-Host "Application does not exist" $applicationName -ForegroundColor Red
    write-host "Creating a new application" -ForegroundColor Yellow
    $identifier = "api://" + $applicationName.replace(" ", "-") + "." + $tenantDomainName
    $application = New-AzADApplication -DisplayName $applicationName -IdentifierUris $identifier -InformationAction SilentlyContinue -WarningAction SilentlyContinue 
    New-AzADServicePrincipal -ApplicationId $application.ApplicationId -SkipAssignment
    Start-Sleep -Seconds 5
    $app = (az ad app show --id $application.ApplicationId) | Convertfrom-Json
    Write-Host "Application Created" $applicationName "and ready for configuration Id" $app.appId -ForegroundColor Green
    return $app

}

function CheckAppExists() {
 [CmdletBinding()]
 Param
 (
     [Parameter(Mandatory = $true)]
     [string]
     $applicationName

 )
    ###Check applications are already registered in Azure AD
    write-host "Checking app exists" $applicationName -ForegroundColor Yellow
    $application = Get-AzADApplication -DisplayName $applicationName
    if ($application -ne $null) {
        Write-Host "Application already exists" -ForegroundColor Green
        $app = (az ad app show --id $application.ApplicationId) | ConvertFrom-Json
    }
 
    return $app
}

function AmendParameters() {
 [CmdletBinding()]
 Param
 (
     [Parameter(Mandatory = $true)]
     [object]
     $Parameters

 )
    ###Amend and return the paramters file
    write-host "Amending local ARM Parameters files" -ForegroundColor Yellow
    $Parameters.parameters.frontendName.value = $frontendApplicationName
    $Parameters.parameters.customDnsZone.value = $customDnsZone
    $Parameters.parameters.dnsZoneResourceGroup.value = $dnsZoneResourceGroup
    $Parameters.parameters.dnsZoneSubscription.value = $dnsZoneSubscription
    $Parameters.parameters.backendName.value = $backendApplicationName
    $Parameters.parameters.frontendCustomDnsName.value = $frontendCustomDnsName
    $Parameters.parameters.frontendRepositoryUrl.value = $repositoryUrl
    $Parameters.parameters.keyVaultName.value = $keyvaultName
 
    return $Parameters
}

function CreateAppSecret($application) {
    #Create secret for backend application
    Write-Host "Creating new secret for application" $application.ApplicationId -ForegroundColor Yellow
    $backendPwd = -join ((65..90) + (97..122) | Get-Random -Count 10 | ForEach-Object {[char]$_})
    $SecureStringPassword = ConvertTo-SecureString -String $backendPwd -AsPlainText -Force
    New-AzADAppCredential -ObjectId $application.ObjectId -Password $SecureStringPassword -EndDate (Get-Date).AddYears(99)
    Write-Host "Secret created" -ForegroundColor Green
    return $backendPwd
}

function CreateServicePrincipal($principalName, $subscriptionId1, $resourceGroup1, $subscriptionId2, $resourceGroup2)
{
    #Create service Principal for Github and set permissions, if DNS zones are in a different subscription then add additional scope
    $scope1 = "/subscriptions/$subscriptionId1/resourcegroups/$resourceGroup1"
    if($subscriptionId1 -ne $subscriptionId2)
    {

        $scope2 = "/subscriptions/$subscriptionId2/resourcegroups/$resourceGroup2"

    }
    $servicePrincipalSecretDetails = Invoke-Command -ScriptBlock {az ad sp create-for-rbac --name "http://$principalName" --role contributor --scopes $scope1 $scope2 --sdk-auth} -WarningAction SilentlyContinue
    return $servicePrincipalSecretDetails
}

### Error Action
$ErrorActionPreference = "Continue"
$WarningPreference = "Continue"

if($installAzModules -eq $true) { Install-Module az -Scope CurrentUser -Force }

### Load parameter file sample from repo, amend parameters and output to correct repo location for pipeline###
$configParameters = Loadfile -FilePath ($samplesPath + $parametersFileSamplePath ) -ErrorAction Stop| Convertfrom-Json
$configParameters = AmendParameters -Parameters $configParameters -ErrorAction Stop 
ExportFile $parametersFilePath ($configParameters | ConvertTo-Json)


###Log into Azure Powershell and CLI###
If($loginToPSandCLI -eq $true) {
write-host "Logging in to AZ CLI and AZ Powershell....we need both"
az login
Login-AzAccount
}


###Build additional variables from input parameters
$frontendHostName = ($frontendCustomDnsName + "." + $customDnsZone)
$backendHostName = ($backendApplicationName + ".azurewebsites.net")
$frontendReplyUrl = "https://" + $frontendHostName + "/authentication/login-callback"


###Create Azure ad app registrations and configure for both backend and frontend
$backendApplication = CheckAppExists -applicationName $backendApplicationName
if($backendApplication -eq $null) { CreateApp -applicationName $backendApplicationName -tenantDomainName $tenantDomainName; $manifestConfig = $true; $resetApplicationSecrets = $true }
$frontendApplication = CheckAppExists -applicationName $frontendApplicationName
if($frontendApplication -eq $null) { CreateApp -applicationName $frontendApplicationName -tenantDomainName $tenantDomainName; $manifestConfig = $true  }

if(($manifestConfig -eq $true) -or ($resetExistingApplications -eq $true))
{
    $backendManifest = UploadManifest $backendApplication "backend" (ProcessManifest $samplesPath $backendApplication "backend" $frontendApplication)
    UploadManifest $frontendApplication "frontend" (ProcessManifest $samplesPath $frontendApplication "frontend" $backendApplication $backendManifest $frontendReplyUrl)
}


###Update the frontend application settings file, this is not secret so write back to the repo
write-host "Preparing Public App Settings Values" -ForegroundColor yellow
$frontendAppSettings = LoadFile($samplesPath + $frontEndAppSettingsSamplePath) | ConvertFrom-Json
$frontendAppSettings.AzureAd.Authority = $frontendAppSettings.AzureAd.Authority + $tenantDomainName
$frontendAppSettings.AzureAd.ClientId = $frontendApplication.appId
$frontendAppSettings.keyvault.APIBaseUrl = ("https://" + $backendHostName )
$frontendAppSettings.keyvault.APIApplicatonId = $backendApplication.identifierUris[0]
$frontendAppSettings.keyvault.KeyvaultUrl = ("https://" + $configParameters.parameters.keyVaultName.value + ".vault.azure.net")
ExportFile $frontEndAppSettingsPath ($frontendAppSettings | ConvertTo-Json)

###Output to screen the secrets that need to be saved to GitHub
if($resetApplicationSecrets -eq $true)
{
    ###Generate Backend Secret Password
    $backendSecret = CreateAppSecret $backendApplication

    
    ###Create configuration items that you must save as secrets to github
    write-host "Preparing Secret Values" -ForegroundColor yellow
    write-host "Secret Values for Backend App being created" -ForegroundColor yellow
    $backendAppSettingsSecret = LoadFile($samplesPath + $backendAppSettingsSecretSamplePath) | ConvertFrom-Json
    $backendAppSettingsSecret[0].value = (Get-AzContext).Tenant.Id
    $backendAppSettingsSecret[2].value = $tenantDomainName  
    $backendAppSettingsSecret[3].value = $backendSecret[1]
    $backendAppSettingsSecret[4].value = $backendApplication.appId
    $backendAppSettingsSecret[6].value = ("https://" + $configParameters.parameters.keyVaultName.value + ".vault.azure.net")
    $backendAppSettingsSecret[8].value = $frontendHostName

    write-host "Store this secret as APP_SETTINGS:" -ForegroundColor red
    $backendAppSettingsSecret | ConvertTo-Json
}

if($resetGitHubSecrets -eq $true)
{
    ###Create Service Principal for deployment from github
    $servicePrincipalConfig = CreateServicePrincipal $githubServicePrincpalName $deploymentSubscriptionId $deploymentResourceGroup $dnsZoneSubscription $dnsZoneResourceGroup
    write-host "Store this secret as AZURE_CREDENTIALS:" -ForegroundColor red
    $servicePrincipalConfig 
}  

write-host "Store this secret as AZURE_RG:" -ForegroundColor red
$deploymentResourceGroup

write-host "Store this secret as AZURE_SUBSCRIPTION:" -ForegroundColor red
$deploymentSubscriptionId

##TO DO API WRITE TO GITHUB


