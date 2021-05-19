using System.Net.Http;
using System.Net.Http.Json;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Components.WebAssembly.Authentication;


public class KeyVaultClient
{
    private readonly HttpClient http;
 
    public KeyVaultClient(HttpClient http)
    {
        this.http = http;
    }
 
    public async Task<object[]> GetSecretAsync()
    {
        var secrets = new object[0];

        try
        {
            secrets = await http.GetFromJsonAsync<object[]>(
                "keyvault");
        }
        catch (AccessTokenNotAvailableException exception)
        {
            exception.Redirect();
        }

        return secrets;
    }
}