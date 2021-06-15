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

1) Amend the ARM deployment paramters file with your desired parameters. 
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

### Application Frontend
The frontend application is a static web applicaiton written in Blazor C# and hosted on an Azure Static Web App. This application is the user's interface to the password manager service. The frontend applicaiton is registered in the user's Azure AD tenant as a single-page application with the following OAuth permissions to sign the user in, and access the backend application as the signed in user.
The frontend application performs REST queries to the proxy backend application to perform CRUD operations to the keyvault within Azure. 

[Deep dive into the frontend here](/docs/architecture/frontend/readme.md)

### Application Backend (Proxy)
Written in .NET 5 C# this is an ASP.NET Core API application. Hosted on Azure App Services the application "proxies" user requests and access tokens to an Azure based KeyVault to perform CRUD operations against secrets. The backend application is registed in the user's Azure AD tenant as a web API and with OAuth permissions to access the configured keyvault on behalf of the signed in user. 

The backend application recieves queries from the frontend applicaiton and proxies these to the keyvault with an access token that is created using a combination the user's access token and the application's identity. 

[Deep dive into the backend here](/docs/architecture/backend/readme.md)

### KeyVault
An Azure Keyvault is configured with permissions to allow an application and a user to perform secret operations. The application can only perform secret operations using a compound identity of the application and the user.

[Deep dive into the keyvault here](/docs/architecture/backend/readme.md)

### Azure AD Applications
The Azure AD Applications are key to allow secure authenticated and proper authorised access to the secrets within the Azure keyvault. Two applications are registered, the frontend application and the backend application. 

This allows for "on-behalf-of flow" to work correctly. [Deep dive into the application configuration here](/docs/architecture/auth/readme.md)









