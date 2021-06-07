Param(   
    [Parameter(Mandatory = $false)]
    [string]
    $parametersFilePath = ".\deployment\arm\parameters\azuredeploy.parameters.json",

    [Parameter(Mandatory = $false)]
    [string]
    $frontEndAppSettingsPath = ".\frontend\wwwroot\appsettings.json",  
  
    [Parameter(Mandatory = $false)]
    [string]
    $backendAppSettingsSecretSamplePath = ".\samples\appsettingssecrets.json", 
   
    [Parameter(Mandatory = $false)]
    [string]
    $sampleManifestPath = ".\samples\",

    [Parameter(Mandatory = $true)]
    [string]
    $deploymentResourceGroup,

    [Parameter(Mandatory = $true)]
    [string]
    $deploymentResourceGroup,

    [Parameter(Mandatory = $true)]
    [string]
    $deploymentResourceGroup,

    [Parameter(Mandatory = $true)]
    [string]
    $deploymentResourceGroup,

    [Parameter(Mandatory = $true)]
    [string]
    $deploymentSubscriptionId,

    [Parameter(Mandatory = $true)]
    [string]
    $tenantDomainName
)

function LoadFile($FilePath) {
    Write-Host "Loading file from $FilePath" -ForegroundColor Yellow
    $content = Get-Content -Path $FilePath 
    Write-Host "Content loaded" -ForegroundColor Green
    return $content        
}

function ExportFile($FilePath, $content) {
    
    $content  | Set-Content -Path $FilePath -Force 
      
}


function AmendManifestForBackEnd($object, $knownApp) {
    Write-Host "Amending manifest for application" $object.AppId -ForegroundColor Yellow
    $object.api.knownClientApplications[0] = $knownApp.AppId
    Write-Host "Manifest Amended" -ForegroundColor green

    return $object
}

function AmendManifestForFrontEnd($object, $knownApp, $knownManifest, $frontendReplyUrl) {
    Write-Host "Amending manifest for application" $object.AppId -ForegroundColor Yellow
    $object.requiredResourceAccess[0].resourceAppId = $knownApp.AppId
    $object.requiredResourceAccess[0].resourceAccess[0].id = $knownManifest.api.oauth2PermissionScopes[0].id
    $object.spa.redirectUris[0] = $frontendReplyUrl
    Write-Host "Manifest Amended" -ForegroundColor green
    return $object
}


function CreateApp($applicationName, $tenantDomainName, $hostName, $urlSuffix) {
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
    Write-Host "Applying manifest settings for application " $application.appId -ForegroundColor yellow
    $url = 'https://graph.microsoft.com/v1.0/applications/' + $application.ObjectId
    $body = Get-Content .\$appType.temp.json
    $body = $body -replace "`"", "\`""
    az rest --method PATCH --uri $url --headers 'Content-Type=application/json' --body "$body"
    $content = az rest --method GET --uri $url
    return $content | ConvertFrom-Json
}

function CreateAppSecret($application) {
    Write-Host "Creating new secret for application" $application.ApplicationId -ForegroundColor Yellow
    $backendPwd = -join ((65..90) + (97..122) | Get-Random -Count 10 | % {[char]$_})
    $SecureStringPassword = ConvertTo-SecureString -String $backendPwd -AsPlainText -Force
    New-AzADAppCredential -ObjectId $application.ObjectId -Password $SecureStringPassword -EndDate (Get-Date).AddYears(99)
    Write-Host "Secret created" -ForegroundColor Green
    return $backendPwd[1]
}

function CheckAppExists($applicationName) {
    write-host "Checking app exists" $applicationName -ForegroundColor Yellow
    $application = Get-AzADApplication -DisplayName $applicationName
    if ($application -ne $null) {
        $app = (az ad app show --id $application.ApplicationId) | ConvertFrom-Json
    }
 
    return $app
}

function CreateServicePrincipal($subscriptionId1, $resourceGroup1, $subscriptionId2, $resourceGroup2)
{

    $scope1 = "/subscriptions/$subscriptionId1/resourcegroups/$resourceGroup1"
    if($subscriptionId1 -ne $subscriptionId2)
    {

        $scope2 = "/subscriptions/$subscriptionId2/resourcegroups/$resourceGroup2"

    }
    $servicePrincipalSecretDetails = az ad sp create-for-rbac --name "sp-github-passwordmanager-deployapp3" --role contributor --scopes $scope1 $scope2 --sdk-auth
    return $servicePrincipalSecretDetails
}

$configParameters = Loadfile($parametersFilePath) | Convertfrom-Json

write-host "Logging in to AZ CLI and AZ Powershell....we need both"
az login
Login-AzAccount

$servicePrincipalConfig = CreateServicePrincipal $deploymentSubscriptionId $deploymentResourceGroup $configParameters.parameters.dnsZoneSubscription.value $configParameters.parameters.dnsZoneResourceGroup.value
$frontendHostName = ($configParameters.parameters.frontendCustomDnsName.value + "." + $configParameters.parameters.customDnsZone.value) 
$backendHostName = ($configParameters.parameters.backendName.value + ".azurewebsites.net")
$backendApplicationName = $configParameters.parameters.backendName.value
$frontendApplicationName = $configParameters.parameters.frontendName.value
$frontendReplyUrl = "https://" + $frontendHostName + "/authenication/login-callback"


    $backendApplication = CreateApp $backendApplicationName $tenantDomainName $backendHostName
    $frontendApplication = CreateApp $frontendApplicationName $tenantDomainName $frontendHostName $frontEndReplySuffix
    $backendManifest = UploadManifest $backendApplication "backend" (ProcessManifest $sampleManifestPath $backendApplication "backend" $frontendApplication)
    $frontendManifest = UploadManifest $frontendApplication "frontend" (ProcessManifest $sampleManifestPath $frontendApplication "frontend" $backendApplication $backendManifest $frontendReplyUrl)


    $backendSecret = CreateAppSecret $backendApplication


    write-host "Preparing Secret Values" -ForegroundColor yellow

    write-host "Secret Values for Backend App being created" -ForegroundColor yellow
    $backendAppSettingsSecret = LoadFile($backendAppSettingsSecretSamplePath) | ConvertFrom-Json
    $backendAppSettingsSecret[0].value = (Get-AzContext).Tenant.Id
    $backendAppSettingsSecret[2].value = $tenantDomainName  
    $backendAppSettingsSecret[3].value = $backendSecret
    $backendAppSettingsSecret[4].value = $backendApplication.appId
    $backendAppSettingsSecret[5].value = ("https://" + $configParameters.parameters.keyVaultName.value + ".vault.azure.net")
    $backendAppSettingsSecret[7].value = $frontendHostName


    write-host "Preparing Public App Settings Values" -ForegroundColor yellow
    $frontendAppSettings = LoadFile($frontEndAppSettingsPath) | ConvertFrom-Json
    $frontendAppSettings.AzureAd.ClientId = $frontendApplication.appId
    $frontendAppSettings.keyvault.APIBaseUrl = $backendHostName
    $frontendAppSettings.keyvault.APIApplicatonId = $backendApplication.appId
    $frontendAppSettings.keyvault.KeyvaultUrl = ("https://" + $configParameters.parameters.keyVaultName.value + ".vault.azure.net")


    ExportFile $frontEndAppSettingsPath ($frontendAppSettings | ConvertTo-Json)

        write-host "Store this secret as APP_SETTINGS:" -ForegroundColor red
    $backendAppSettingsSecret | ConvertTo-Json

            write-host "Store this secret as AZURE_CREDENTIALS:" -ForegroundColor red
    $servicePrincipalConfig 

    
            write-host "Store this secret as AZURE_RG:" -ForegroundColor red
            $deploymentResourceGroup

                        write-host "Store this secret as AZURE_SUBSCRIPTION:" -ForegroundColor red
            $deploymentSubscriptionId


