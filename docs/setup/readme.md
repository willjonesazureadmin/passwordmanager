## Setup Guide
To build your own password manager service you will require the perform the following high level steps

* Clone of this Github Repo
* Generate PAT token for your user account
* Create an Azure AD Service Principal to be used by Github
* Register Azure AD Applications
* Amend frontend public appsettings
* Amend Azure Deployment Parameters
* Configure Github Secrets
* Deploy Azure Resources
* Frontend Application Code Deployment
* Backend Application Code Deployment


The majority of these steps have been automated as much as possible to simplify them. The ConfigureDeployment.ps1 script located [here](/deployment/scripts/) when run against your repo with the correct settings will perform the following tasks:

1) Amend the ARM deployment paramters file with your desired parameters
2) Register the appropriate Azure AD Applications in your tenant
3) Update the Azure AD Application manifest files with the appropriate configuration
4) Update the frontend appsettings.json file and save it in your repo
5) Generate a service principal with permissions to the correct scopes and output to screen
6) Generate Secret values for the backend application and output to screen
7) Generate Subscription value and output to screen
8) Generate Resource group values and output to screen

The script will automate some the steps below, if you choose to run the script, jump straight to the [run configuration script](#configure-with-script)


### Clone Repo
Clone this Github repo to your own repository. From now on you will be working in your own github repo.

### Generate PAT Token
Azure Static Web Apps when deployed will utilise a PAT token to create a pipeline in your repo

### Create Azure AD Service Principal








