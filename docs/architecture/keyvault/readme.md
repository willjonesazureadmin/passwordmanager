### Key Vault
The key vault is the persistence layer for the application. To be able to access the 

### Custom HTTP Client
By default Blazor will attach Azure AD Auth tokens to outbound HTTP calls as long as it is the same domain that the Blazor application is hosted on. As the backend application is hosted on a different domain a custom client with the relevant authentication tokens must be created. This is created as part of the SecretService constructor. However it must be configured at application [startup](/frontend/Program.cs) with the appropriate authorisation handler also. The name of the client is pulled from the [appsettings.json](/frontend/wwwroot/appsettings.json) file. 