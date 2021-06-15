using Microsoft.AspNetCore.Components;
using Microsoft.AspNetCore.Components.WebAssembly.Authentication;
using Microsoft.Extensions.Configuration;
using static keyvault.web.models.AppSettings;

public class KeyvaultAPIAuthorizationMessageHandler : AuthorizationMessageHandler
{

    private readonly LocalConfigurations _settings;

    public KeyvaultAPIAuthorizationMessageHandler(IAccessTokenProvider provider, NavigationManager navigationManager, LocalConfigurations settings) : base(provider, navigationManager)
    {
        this._settings = settings;
        ConfigureHandler(
            authorizedUrls: new[] { _settings.Keyvault.APIBaseUrl  },
            scopes: new[] { string.Format("{0}/{1}",_settings.Keyvault.APIApplicationId, _settings.Keyvault.ApiScope) });
    }
}