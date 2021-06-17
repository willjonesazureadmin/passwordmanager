## Backend Application
The backend application is a .NET Core Web API service hosted on Azure Web Apps. The application receives requests to the contollers via REST calls and uses the user's authentication token to request a keyvault access token on behalf of the user.

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
Performs all secret actions against the specified keyvault as provided in the [appsettings.json](/backend/appsettings.json) file. To do this the application must request an access token to the Azure Keyvault service using the [token acquistion](/backend/helpers/OnBehalfOfCredential.cs) service. Once a token is acquired this is then used with the [Keyvault Client Helper](/backend/helpers/KeyVaultClient.cs) to query the keyvault and pass the responses back to the frontend. 

### Token Acquisition Service
The [token acquisition service](/backend/helpers/OnBehalfOfCredential.cs) is injected into the controller. To acquire a token the [application settings](/backend/appsettings.json) are read to identify the backend application to Azure AD. When combined with a users access token Azure AD will provide an access token to the Keyvault.

### Keyvault Client
The Keyvault client is a [static helper](/backend/helpers/KeyVaultClient.cs) class that when provided with Keyvault information and access token will perform requests against the keyvault.

### Health Service
The application will perform several basic health checks which can be checked by querying the /health URL.


<- [Back to Summary](/docs/architecture/readme.md) | [Now read about the Azure AD application details here](/docs/architecture/auth/readme.md) ->

