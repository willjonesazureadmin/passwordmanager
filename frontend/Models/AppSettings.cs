
namespace keyvault.web.models
{
    public class AppSettings
    {
        public class LocalConfigurations
        {

            public AzureAdSettings AzureAd { get; set; }
            public KeyvaultSettings Keyvault { get; set; }

            public class KeyvaultSettings
            {
                public string ApiClientName { get; set; }
                public string ApiScope { get; set; }
                public string APIBaseUrl { get; set; }
                public string APIApplicationId { get; set; }
                public string KeyvaultUrl { get; set; }
            }

            public class AzureAdSettings
            {
                public string Authority { get; set; }
                public string ClientId { get; set; }
                public bool ValidateAuthority { get; set; }
            }
        }
    }
}