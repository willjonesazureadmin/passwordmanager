## Frontend Application

The frontend application is a Blazor WebAssembly hosted on an Azure Static Web App. The frontend provides a user interface for signing in the user, viewing, adding, copying and amending secrets stored in an Azure Keyvault. 

### Pages

The application structure for pages is as follows:

- [Index (Home)](frontend\Pages\Index.razor) - Default Document Homepage
- [About](frontend\Pages\About.razor) - About the application
- [Settings](frontend\Pages\Settings.razor) - Review the application Settings
- [Token](frontend\Pages\Token.razor) - View the Azure AD Auth Token used by the application
- Secrets
  - [Add](frontend\Pages\Secrets\Add.razor) - Add a new secret
  - [Details](frontend\Pages\Secrets\Details.razor) - View details of a secret
  - [Edit](frontend\Pages\Secrets\Edit.razor) - Edit an existing secret
  - [Index](frontend\Pages\Secrets\Index.razor) - Lists all Secrets in Keyvault

### REST Operations
Requests to the proxy backend application are handled using a helper [KeyVaultClient](/frontend/helpers/KeyVaultClient.cs) class to perform the CRUD style rest operations. 





[Next read about the backend application here](/docs/architecture/backend/readme.md)

[Back to Summary](/docs/architecture/readme.md)