## Setup Guide

To build your own password manager service you will require the perform the following high level steps

* Clone of this Github Repo
* Generate PAT token for your user account
* Make some major life decisions
* Create an Azure AD Service Principal to be used by Github
* Register Azure AD Applications
* Amend frontend public appsettings.json
* Amend Azure Deployment Parameters
* Configure Github Secrets
* Deploy Azure Resources, Frontend Code and Backend Code

---

### Clone Repo

Clone this Github repo to your own repository. From now on you will be working in your own github repo.

### Generate PAT Token

Azure Static Web Apps when deployed will utilise a PAT token to create a pipeline in your repo to deploy the application. This PAT token must be saved as a secret in your repo to be consumed by the [deploy-production.yml](/.github/workflows/deploy-production.yml) pipeline.
Create a PAT token within GitHub with the following permissions.

![PAT Token](/docs/images/pat.png)

Ensure you copy the PAT we will save it as a Github secret later.

### Make some major life decisions

Only kidding, but you will need to decide some parameters that have to be globally unique that you will have to refer to whilst configuring parameter files or appsettings. Make the following decisions and keep note of them:

1) Key Vault Name
2) Backend Web App Name
3) Frontend Application Name
4) Your DNS hosting option, ideally use Azure DNS as this is fully integrated into the ARM template deployment
5) The custom DNS frontend name
6) The Azure Subscription to use
7) The name of the resource group to deploy to

---

### Configuration Script

The majority of the following steps have been automated as much as possible to simplify them. The ConfigureDeployment.ps1 script located [here](/deployment/scripts/) when run against your repo with the correct settings will perform the following tasks:

1) Amend the ARM deployment parameters file with your desired parameters
2) Register the appropriate Azure AD Applications in your tenant
3) Update the Azure AD Application manifest files with the appropriate configuration
4) Update the frontend appsettings.json file and save it in your repo
5) Generate a service principal with permissions to the correct scopes and output to screen
6) Generate Secret values for the backend application and output to screen
7) Generate Subscription value and output to screen
8) Generate Resource group values and output to screen

The script will automate some the steps below, if you choose to run the script, jump straight to the [run configuration script](#configure-with-script)

---

### Create Azure AD Service Principal

To Authenticate to Azure Github requires credentials to be created and stored as a secret, to be consumed by the deployments. Create an appropriate service principal and assign permissions following this [guide](https://docs.microsoft.com/en-us/azure/developer/github/connect-from-azure#:~:text=Create%20a%20service%20principal%20and%20add%20it%20to%20GitHub%20secret,-To%20use%20Azure&text=Open%20Azure%20Cloud%20Shell%20in%20the%20Azure%20portal%20or%20Azure%20CLI%20locally.&text=Create%20a%20new%20service%20principal,be%20assigned%20the%20Contributor%20role.&text=Copy%20the%20JSON%20object%20for%20your%20service%20principal.).
Make note of the output as you need to save these as a Github secret.

#### Register Azure AD Applications

From within the Azure Portal you will need to register two Azure AD Applications. You can choose any names you wish for the frontend and backend applications.

#### Backend Application Registration

1) Authentication - ID Tokens, Accounts in any organizational directory (Any Azure AD directory - Multitenant)
![auth](/docs/images/setup-appreg-backend-auth.png)
2) Certificates & Secrets - Create a secret with a lifetime of your choosing and make note for later
![secrets](/docs/images/setup-appreg-backend-secrets.png)
3) API Permissions - Add Azure Key Vault - user_impersonation & Microsoft Graph User.Read
![permissions](/docs/images/setup-appreg-backend-permission.png)
4) Expose an API - Register a new API for your app call it something easy to remember such as "User_impersonation," make note of the scope and url e.g. API://xxx/user_impersonation
![scopes](/docs/images/setup-appreg-backend-scopeconfig.png)
![scopes](/docs/images/setup-appreg-backend-scope.png)

* Ensure you have the Client Id, Secret and API Scope, and Tenant Id noted, you will need these later

#### Frontend Application Registration

1) Authentication - ID Tokens, Accounts in this Organizaional directory only, Add a platform configuration with a redirect URL of what the frontend app domain will be with "/authentication/login-callback" as the suffix.
![auth](/docs/images/setup-appreg-frontend-auth.png)
2) API Permissions - The the backend app scope you created in the previous steps & Microsoft Graph User.Read
![permissions](/docs/images/setup-appreg-frontend-permission.png)

* Ensure you have noted the Client Id for the frontend app registration, you will need this later.

#### Known app settings

1) Now return to the backend application and configure the manifest setting "knownClientApplications" and add the frontend app Client Id
![known app id](/docs/images/setup-appreg-backend-known.png)

**You should now have the following items noted that you will need later:**

* Backend Client Id
* Backend Client Secret
* Backend API Scope and Name
* Frontend Client Id
* Your Tenant Id

---

### Amend Frontend Application Settings

Configure the frontend application settings to match the settings you have configured. The file [appsettings.json](/frontend/wwwroot/appsettings.json) should be changed as per the below table, leave all other settings as is in the file:

| Setting | Use |
|---|---|
| AzureAd: Authority | Your tenant Id |
| AzureAd: ClientId | The application Id for the frontend app registration |
| keyvault: ApiScope | The name of the API Scope as registered by the backend application |
| keyvault: ApiApplicationId | The backend application Id as registered in Azure Ad |
| keyvault: key vaultUrl | The key vault name you have chosen |

---

### Amend Deployment Parameters

To deploy the application stack, the [azuredeploy.parameters.json](/deployment/arm/parameters/azuredeploy.parameters.json) file needs to be configured with the appropriate settings. As per the steps completed previously.

| Parameter | Use |
|---|---|
|backendName| The backend globally unique Azure web app name |
|backendHostingPlanName| The App service plan naming that is hosting your backend app|
|frontendName| The resource name for your frontend app|
|frontendRepositoryUrl| This is the repo that is hosting the frontend app code|
|frontendBranch| The name of the branch that should be deployed as code to your frontend app|
|frontendRepositoryToken| Leave blank we will override this secret at deployment time|
|deployDns| Choose whether to deploy Azure DNS to host the DNS zone for your app (highly recommended)|
|configureCustomDns| Whether to configure a custom dns name for your frontend app, if set to false, you will get a randomly generated app name which you will then need to put into you Azure AD app registration|
|customDnsZone| The zone name for your DNS hosting e.g. azureadmin.co.uk |
|frontendCustomDnsName| The name of your frontend app dns e.g. passman|
|dnsZoneSubscription| You may wish to host DNS in another subscription, enter the subscription that is hosting your DNS zone|
|dnsZoneResourceGroup| The resource group hosting your DNS zone|
|keyVaultName| The name of the key vault to use for the passman service|
|userObjectId| The user object Id that will be set as an access policy to the key vault|
|backendApplicationId| The backend application id that is configured with the access policy to the key vault|

---

### Run the Configuration Script (only do this if you jumped to this step)

The above steps have been automated by running [the ConfigureDeployment.ps1 script](/deployment/scripts/ConfigureDeployment.ps1)

If you choose to run the script, run it at the root of your repo and provide the required parameters (review the parameters by viewing the script to the script.)
You will be prompted to login to Azure CLI and Azure Powershell, ensure you use an account with permissions to register apps and configure permissions e.g. a global admin account. 

The script will read from [the sample files](/deployment/samples/) amend them and output them to the correct locations. Overall the script will perform the following tasks:

1) Amend the azuredeploy.parameters.json file
2) Register the backend application in Azure AD and configure the appropriate settings
3) Register the frontend application in Azure AD and configure the appropriate settings
4) Output to screen the settings you will need to save as github secrets

---

### Configure Github secrets
You now need to save github secret values that you have noted during setup, these secrets are used by the deployment pipelines.
Start by creating a new environment in your github repo at github.com. If you chose to run the ConfigureDeployment.ps1 script these would have been output to screen. Create an environment named "Production"
![github environment](/docs/images/github-environment.png)

From within the production environment add the following secrets:
| Secret Name | Value |
|---|---|
|APP_SETTINGS| These are the appsettings that are deployed to the backend application, these should remain secret and a sample of the value can be found [here](/deployment/samples/appsettingssecrets.json)|
|AZURE_CREDENTIALS| The credentials output when registering a new service principal|
|AZURE_GITHUB_TOKEN | The token you generated at the start of the setup guide |
|AZURE_RG| The name of the resource group for deployment|
|AZURE_SUBSCRIPTION| The subscription id you are deploying the service to |

---

### Deploy

You are now ready to deploy the application. This is done via [the pipeline deploy-production.yml](/.github/workflows/deploy-production.yml). Push your changes to main and this will trigger the pipeline. If all settings are configured correctly the deployment will succeed and this will also generate a new workflow action that is generated automatically by the deployment of an Azure Static web app.
