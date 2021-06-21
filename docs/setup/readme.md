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
* Deploy Azure Resources
* Frontend Application Code Deployment
* Backend Application Code Deployment

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

---

>The majority of the following steps have been automated as much as possible to simplify them. The ConfigureDeployment.ps1 script located [here](/deployment/scripts/) when run against your repo with the correct settings will perform the following tasks:
>
>1) Amend the ARM deployment parameters file with your desired parameters
>2) Register the appropriate Azure AD Applications in your tenant
>3) Update the Azure AD Application manifest files with the appropriate configuration
>4) Update the frontend appsettings.json file and save it in your repo
>5) Generate a service principal with permissions to the correct scopes and output to screen
>6) Generate Secret values for the backend application and output to screen
>7) Generate Subscription value and output to screen
>8) Generate Resource group values and output to screen
>
>The script will automate some the steps below, if you choose to run the script, jump straight to the [run configuration script](#configure-with-script)

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

### Amend Frontend Application Settings

Configure the frontend application settings to match the settings you have configured. The file [appsettings.json](/frontend/wwwroot/appsettings.json) should be changed as per the below table, leave all other settings as is in the file:

| Setting | Use |
|---|---|
| AzureAd: Authority | Your tenant Id |
| AzureAd: ClientId | The application Id for the frontend app registration |
| key vault: ApiScope | The name of the API Scope as registered by the backend application |
| key vault: ApiApplicationId | The backend application Id as registered in Azure Ad |
| key vault: key vaultUrl | The key vault name you have chosen |

### Amend Deployment Parameters

To deploy the application stack, the [azuredeploy.parameters.json](/deployment/arm/parameters/azuredeploy.parameters.json) file needs to be configured with the appropriate settings. As per the steps completed previously.

| Parameter | Use |
|---|---|


and then save it as a secret within your repo as "AZURE_GITHUB_TOKEN"

