using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using Azure;
using Azure.Security.KeyVault.Secrets;

namespace keyvault.obo
{
    public static class KeyVaultClient
    {
    

        public static async Task<List<SecretProperties>> ListSecrets(OnBehalfOfCredential userToken, string KeyvaultName)
        {

            var client = new SecretClient(new Uri(KeyvaultName), userToken);
            
            AsyncPageable<SecretProperties> allSecrets = client.GetPropertiesOfSecretsAsync();

            var l = new List<SecretProperties>();
            await foreach (SecretProperties secretProperties in allSecrets)
            {
                l.Add(secretProperties);
            }
            return l;
        }  

        public static KeyVaultSecret GetSecret(OnBehalfOfCredential userToken, string KeyvaultName, string secretName)
        {
            var client = new SecretClient(new Uri(KeyvaultName), userToken);           
            return client.GetSecret(secretName);
        }

        public static SecretProperties GetSecretProperties(OnBehalfOfCredential userToken, string KeyvaultName, string secretName)
        {
            var client = new SecretClient(new Uri(KeyvaultName), userToken);           
            return client.GetSecret(secretName).Value.Properties;
        }

        public static KeyVaultSecret UpdateSecret(OnBehalfOfCredential userToken, string KeyvaultName, string secretName, string newSecretValue)
        {
            var client = new SecretClient(new Uri(KeyvaultName), userToken);
            var newSecret = new KeyVaultSecret(secretName, newSecretValue);
            return client.SetSecret(newSecret);
        }       
        public static KeyVaultSecret CreateSecret(OnBehalfOfCredential userToken, string KeyvaultName, KeyVaultSecret secret)
        {
            var client = new SecretClient(new Uri(KeyvaultName), userToken);          
            return client.SetSecret(secret);
        }            
    }
}