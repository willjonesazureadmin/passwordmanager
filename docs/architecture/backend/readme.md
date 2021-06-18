## Backend Application
The backend application is a .NET Core Web API service hosted on Azure Web Apps. The application receives requests to the contollers via REST calls and uses the user's authentication token to request a key vault access token on behalf of the user.

### Controllers
The application structure for pages is as follows:

- [health](/backend/services/healthcheck/ServicesHealthCheck.cs) - Provides a health state for the application
- api
  - [secrets](/backend/Controllers/SecretController.cs)
    - Get - Get all Secrets
    - Get {Secret Id} - Get Secret By Id
    - Post - Create Secret
    - Post {Secret Id}/update - Update existing secret

### Secret Controller
Performs all secret actions against the specified key vault as provided in the [appsettings.json](/backend/appsettings.json) file. To do this the application must request an access token to the Azure key vault service using the [token acquistion](/backend/helpers/OnBehalfOfCredential.cs) service. Once a token is acquired this is then used with the [Keyvault Client Helper](/backend/helpers/KeyVaultClient.cs) to query the key vault and pass the responses back to the frontend.

### Token Acquisition Service
The [token acquisition service](/backend/helpers/OnBehalfOfCredential.cs) is injected into the controller. To acquire a token the [application settings](/backend/appsettings.json) are read to identify the backend application to Azure AD. When combined with a users access token Azure AD will provide an access token to the key vault.

### key vault Client
The key vault client is a [static helper](/backend/helpers/KeyVaultClient.cs) class that when provided with key vault information and access token will perform requests against the key vault.

### Health Service
The application will perform several basic health checks which can be checked by querying the /health URL.

### Application Settings
Application [settings](/backend/appsettings.json) are imported when the application starts. These are the key settings that are required to use the app.

```
{
  "AppConfiguration" : {
    "ApiScope" : "user_impersonation",
    "KeyvaultUrl" : "#{KeyvaultUrl}#",
    "FrontEndUrl" : "#{FrontEndUrl}#"
  },
  "AzureAd": {
    "Instance": "https://login.microsoftonline.com/",
    "Domain": "#{Domain}#",
    "TenantId": "#{TenantId}#",
    "ClientId": "#{ClientId}#",
    "ClientSecret" :"#{ClientSecret}#",
    "Audience" : "#{Audience}#",
    "CallbackPath": "/signin-oidc"
  },
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft": "Warning",
      "Microsoft.Hosting.Lifetime": "Information"
    }
  },
  "AllowedHosts": "*"
}

```

| Setting | Use |
|---|---|
| AppConfiguration: ApiScope | The scope that the frontend application should present to access the backend app |
| AppConfiguration: keyvaultUrl | The URL of the key vault to access |
| AppConfiguration: FrontEndUrl | The frontend app url for CORS policy |
| AzureAd: Instance | The Azure AD endpoint |
| AzureAd: Domain | The Azure AD Domain |
| AzureAd: TenantId | The Azure AD Tenant Id |
| AzureAd: ClientId | The backend application identifier |
| AzureAd: ClientSecret | The backend application secret |
| AzureAd: Audience | The expected audience that the app should validate |

<- [Back to Summary](/docs/architecture/readme.md) | [Now read about the Azure AD application details here](/docs/architecture/auth/readme.md) ->

