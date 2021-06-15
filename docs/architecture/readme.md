## Password Manager Architecture

The fundamental goal of the password manager project is to quickly store, update and retrieve secrets from a keyvault that is secured using the user's identity. As if they were looking at the keyvault through the Azure portal. To achieve this goal the password manager application is made of 4 core components.

* [Application Frontend](#application-frontend)
* [Application Backend (Proxy)](#Application-Backend-proxy)
* [Keyvault](#keyvault)
* [Azure AD Applications](#Azure-ad-applications)


![Passman Architecture](/docs/images/passman-architecture.png)

The frontend application is designed to allow a user(s) to save and retrieve secrets stored in an Azure Keyvault utilsing their Azure AD identity. An application frontend cannot make calls directly to the keyvault due to CORS policies that cannot be changed on the keyvault. Therefore a middle-tier application must "proxy" the connection/identity/authorisation to the keyvault, in this case the applicaiton backend. 

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









