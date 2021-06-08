using System;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Components.WebAssembly.Hosting;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using keyvault.web.services;
using keyvault.web.models;
using BlazorApplicationInsights;
using System.Collections.Generic;

namespace keyvault
{
    public class Program
    {
        public static async Task Main(string[] args)
        {
            var builder = WebAssemblyHostBuilder.CreateDefault(args);
            builder.RootComponents.Add<App>("#app");
            var localConfigurations = builder.Configuration.Get<AppSettings.LocalConfigurations>();
            builder.Services.AddSingleton(localConfigurations);
            builder.Services.AddSingleton<SecretService>();
            builder.Services.AddScoped<KeyvaultAPIAuthorizationMessageHandler>();
            builder.Services.AddHttpClient(builder.Configuration["Keyvault:ApiClientName"], 
                client => client.BaseAddress = new Uri(builder.Configuration["Keyvault:APIBaseUrl"]))
                    .AddHttpMessageHandler<KeyvaultAPIAuthorizationMessageHandler>();
            builder.Services.AddHttpClient(string.Format("{0}.NoAuthenticationClient",builder.Configuration["Keyvault:ApiClientName"]), 
                client => client.BaseAddress = new Uri(string.Format("{0)/health",builder.Configuration["Keyvault:APIBaseUrl"])));



            builder.Services.AddBlazorApplicationInsights(async applicationInsights =>
            {
                var telemetryItem = new TelemetryItem()
                {
                    Tags = new Dictionary<string, object>()
                    {
                        { "ai.cloud.role", "SPA" },
                        { "ai.cloud.roleInstance", "Blazor Wasm" },
                    }
                };

                await applicationInsights.SetInstrumentationKey("7b0dd1fd-40e6-491e-98e0-e59cf158b4d1");
                await applicationInsights.LoadAppInsights();

                await applicationInsights.AddTelemetryInitializer(telemetryItem);
            });

            builder.Services.AddMsalAuthentication(options =>
            {
                builder.Configuration.Bind("AzureAd", options.ProviderOptions.Authentication);
                options.ProviderOptions.DefaultAccessTokenScopes.Add(string.Format("{0}/.default",builder.Configuration["Keyvault:APIApplicatonId"]));
            });
            
            await builder.Build().RunAsync();
        }
    }
}
