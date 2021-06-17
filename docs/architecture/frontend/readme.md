## Frontend Application

The frontend application is a Blazor WebAssembly hosted on an Azure Static Web App. The frontend provides a user interface for signing in the user, viewing, adding, copying and amending secrets stored in an Azure Keyvault. 

### Pages

The application structure for pages is as follows:

- [Index (Home)](\frontend\Pages\Index.razor) - Default Document Homepage
- [About](\frontend\Pages\About.razor) - About the application
- [Settings](\frontend\Pages\Settings.razor) - Review the application Settings
- [Token](\frontend\Pages\Token.razor) - View the Azure AD Auth Token used by the application
- Secrets
  - [Add](\frontend\Pages\Secrets\Add.razor) - Add a new secret
  - [Details](\frontend\Pages\Secrets\Details.razor) - View details of a secret
  - [Edit](\frontend\Pages\Secrets\Edit.razor) - Edit an existing secret
  - [Index](\frontend\Pages\Secrets\Index.razor) - Lists all Secrets in Keyvault

### REST Operations
Requests to the proxy backend application are handled using a service injected into the relevant pages [SecretService](/frontend/Services/SecretService.cs) class to perform the CRUD style rest operations. The SecretService relies on a custom HTTP Client to authenticate calls with a JWT.

### Custom HTTP Client
By default Blazor will attach Azure AD Auth tokens to outbound HTTP calls as long as it is the same domain that the Blazor application is hosted on. As the backend application is hosted on a different domain a custom client with the relevant authentication tokens must be created. This is created as part of the SecretService constructor. However it must be configured at application [startup](/frontend/Program.cs) with the appropriate authorisation handler also. The name of the client is pulled from the [appsettings.json](/frontend/wwwroot/appsettings.json) file. 

### Authorisation Handler
At application [startup](/frontend/Program.cs) an authorisation handler is registered with the services, this [authorisation](/frontend/authorization/KeyvaultAPIAuthorizationMessageHandler.cs) handler is then used within the http client. 

The [authorisation](/frontend/authorization/KeyvaultAPIAuthorizationMessageHandler.cs) handler is configured with the application Id, scope url of the backend application pulled from [appsettings.json](/frontend/wwwroot/appsettings.json). 


### Application Settings
Application [settings](/frontend/wwwroot/appsettings.json) are imported when the application starts. These are the key settings that are required to use the app. 

```
{
    "AzureAd": {
        "Authority": "https://login.microsoftonline.com/azureadmin.co.uk", 
        "ClientId": "4ad01221-7b51-4159-894c-e02ac969fb11",
        "ValidateAuthority": true
    },
    "Keyvault": {
        "ApiClientName": "KeyvaultAPI",
        "ApiScope": "user_impersonation",
        "APIBaseUrl": "https://awa-weu-pmp-be-001.azurewebsites.net",
        "APIApplicationId": "api://awa-weu-pmp-be-001.azureadmin.co.uk",
        "KeyvaultUrl": "https://azureadminpassmankv.vault.azure.net"
    }
}
```

| Setting | Use |
|---|---|
| AzureAd: Authority | The Directory endpoint for user login and token issuance | 
| AzureAd: ClientId | The public client Id as registered in Azure Ad |
| AzureAd: ValidateAuthority | Validate that the authority is correct | 
| Keyvault: ApiClientName | This is the name of the HTTP Client that is registered at startup and then used by the SecretService |
| Keyvault: ApiScope | The name of the API Scope as reqistered by the backend application |
| Keyvault: ApiApplicationId | The backend application Id as registered in Azure Ad |
| Keyvault: KeyvaultUrl | The Keyvault where the secrets are stored |

<- [Back to Summary](/docs/architecture/readme.md) | [Next read about the backend application here](/docs/architecture/backend/readme.md) ->
