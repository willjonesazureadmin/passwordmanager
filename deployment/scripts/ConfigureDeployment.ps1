﻿Param(   
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
    $frontendCustomDnsName = "passman-test",
  
    [Parameter(Mandatory = $false)]
    [string]
    $tenantDomainName = "azureadmin.co.uk",
  
    [Parameter(Mandatory = $false)]
    [string]
    $githubServicePrincpalName = "sp-github-passman"
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


function CreateApp($applicationName, $tenantDomainName) {
    #Create Azure AD Application registrations for frontend and backend apps

    Write-Host "Application does not exist" $applicationName -ForegroundColor Red
    write-host "Creating a new application" -ForegroundColor Yellow
    $identifier = "api://" + $applicationName.replace(" ", "-") + "." + $tenantDomainName
    $application = New-AzADApplication -DisplayName $applicationName -IdentifierUris $identifier -InformationAction SilentlyContinue -WarningAction SilentlyContinue 
    $servicePrincipal = New-AzADServicePrincipal -ApplicationId $application.ApplicationId -SkipAssignment
    Start-Sleep -Seconds 5
    $app = (az ad app show --id $application.ApplicationId) | Convertfrom-Json
    Write-Host "Application Created" $applicationName "and ready for configuration Id" $app.appId -ForegroundColor Green
    return $app

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

function CreateAppSecret($application) {
    #Create secret for backend application
    Write-Host "Creating new secret for application" $application.ApplicationId -ForegroundColor Yellow
    $backendPwd = -join ((65..90) + (97..122) | Get-Random -Count 10 | % {[char]$_})
    $SecureStringPassword = ConvertTo-SecureString -String $backendPwd -AsPlainText -Force
    New-AzADAppCredential -ObjectId $application.ObjectId -Password $SecureStringPassword -EndDate (Get-Date).AddYears(99)
    Write-Host "Secret created" -ForegroundColor Green
    return $backendPwd
}

function CheckAppExists($applicationName) {
    ###Check applications are already registered in Azure AD
    write-host "Checking app exists" $applicationName -ForegroundColor Yellow
    $application = Get-AzADApplication -DisplayName $applicationName
    if ($application -ne $null) {
        $app = (az ad app show --id $application.ApplicationId) | ConvertFrom-Json
    }
 
    return $app
}

function CreateServicePrincipal($principalName, $subscriptionId1, $resourceGroup1, $subscriptionId2, $resourceGroup2)
{
    #Create service Principal for Github and set permissions, if DNS zones are in a different subscription then add additional scope
    $scope1 = "/subscriptions/$subscriptionId1/resourcegroups/$resourceGroup1"
    if($subscriptionId1 -ne $subscriptionId2)
    {

        $scope2 = "/subscriptions/$subscriptionId2/resourcegroups/$resourceGroup2"

    }
    $servicePrincipalSecretDetails = az ad sp create-for-rbac --name "http://$principalName" --role contributor --scopes $scope1 $scope2 --sdk-auth
    return $servicePrincipalSecretDetails
}

### Error Action
$ErrorActionPreference = "Continue"
$WarningPreference = "Continue"
Install-Module az -Scope CurrentUser -Force

### Load parameter file sample from repo, amend parameters and output to correct repo location for pipeline###
$configParameters = Loadfile -FilePath ($parametersFilePath ) -ErrorAction Stop| Convertfrom-Json
$configParameters.parameters.frontendName.value = $frontendApplicationName
$configParameters.parameters.customDnsZone.value = $customDnsZone
$configParameters.parameters.dnsZoneResourceGroup.value = $dnsZoneResourceGroup
$configParameters.parameters.dnsZoneSubscription.value = $dnsZoneSubscription
$configParameters.parameters.backendName.value = $backendApplicationName
$configParameters.parameters.frontendCustomDnsName.value = $frontendCustomDnsName
$configParameters.parameters.frontendRepositoryUrl.value = $repositoryUrl
$configParameters.parameters.keyVaultName.value = $keyvaultName
ExportFile $parametersFilePath ($configParameters | ConvertTo-Json)


###Log into Azure Powershell and CLI###
write-host "Logging in to AZ CLI and AZ Powershell....we need both"
az login
Login-AzAccount


###Create Service Principal for deployment from github
$servicePrincipalConfig = CreateServicePrincipal $githubServicePrincpalName $deploymentSubscriptionId $deploymentResourceGroup $dnsZoneSubscription $dnsZoneResourceGroup


###Build additional variables from input parameters
$frontendHostName = ($frontendCustomDnsName + "." + $customDnsZone)
$backendHostName = ($backendHostName + ".azurewebsites.net")
$frontendReplyUrl = "https://" + $frontendHostName + "/authenication/login-callback"


###Create Azure ad app registrations and configure for both backend and frontend
$backendApplication = CreateApp $backendApplicationName $tenantDomainName $backendHostName 
$frontendApplication = CreateApp $frontendApplicationName $tenantDomainName $frontendHostName $frontEndReplySuffix
$backendManifest = UploadManifest $backendApplication "backend" (ProcessManifest $samplesPath $backendApplication "backend" $frontendApplication)
$frontendManifest = UploadManifest $frontendApplication "frontend" (ProcessManifest $samplesPath $frontendApplication "frontend" $backendApplication $backendManifest $frontendReplyUrl)

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

###Update the frontend application settings file, this is not secret so write back to the repo
write-host "Preparing Public App Settings Values" -ForegroundColor yellow
$frontendAppSettings = LoadFile($samplesPath + $frontEndAppSettingsSamplePath) | ConvertFrom-Json
$frontendAppSettings.AzureAd.ClientId = $frontendApplication.appId
$frontendAppSettings.keyvault.APIBaseUrl = $backendHostName
$frontendAppSettings.keyvault.APIApplicatonId = $backendApplication.appId
$frontendAppSettings.keyvault.KeyvaultUrl = ("https://" + $configParameters.parameters.keyVaultName.value + ".vault.azure.net")
ExportFile $frontEndAppSettingsPath ($frontendAppSettings | ConvertTo-Json)



###Output to screen the secrets that need to be saved to GitHub
write-host "Store this secret as APP_SETTINGS:" -ForegroundColor red
$backendAppSettingsSecret | ConvertTo-Json

write-host "Store this secret as AZURE_CREDENTIALS:" -ForegroundColor red
$servicePrincipalConfig 

    
write-host "Store this secret as AZURE_RG:" -ForegroundColor red
$deploymentResourceGroup

write-host "Store this secret as AZURE_SUBSCRIPTION:" -ForegroundColor red
$deploymentSubscriptionId

##TO DO API WRITE TO GITHUB


