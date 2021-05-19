using Microsoft.AspNetCore.Components;
using Microsoft.AspNetCore.Components.WebAssembly.Authentication;
using Microsoft.Extensions.Configuration;

public class KeyvaultAPIAuthorizationMessageHandler : AuthorizationMessageHandler
{
    private readonly IConfiguration _Config;

    public KeyvaultAPIAuthorizationMessageHandler(IAccessTokenProvider provider,
        NavigationManager navigationManager, IConfiguration configuration)
        : base(provider, navigationManager)
    {
        this._Config = configuration;
        ConfigureHandler(
            authorizedUrls: new[] { _Config["Keyvault:APIBaseUrl"] },
            scopes: new[] { string.Format("api://{0}/{1}",_Config["Keyvault:APIApplicatonId"],_Config["Keyvault:ApiScope"]) });
    }
}