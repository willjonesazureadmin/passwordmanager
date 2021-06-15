using System;
using System.Threading;
using System.Threading.Tasks;
using Azure.Core;
using Microsoft.Identity.Client;
using Microsoft.Identity.Web;


namespace keyvault.obo
{
    public class OnBehalfOfCredential : TokenCredential
    {
        private readonly IConfidentialClientApplication _confidentialClient;
        private readonly UserAssertion _userAssertion;

        public OnBehalfOfCredential(string clientId, string clientSecret, string userAccessToken)
        {
            _confidentialClient = ConfidentialClientApplicationBuilder.Create(clientId).WithClientSecret(clientSecret).Build();

            _userAssertion = new UserAssertion(userAccessToken);
        }

        public override AccessToken GetToken(TokenRequestContext requestContext, CancellationToken cancellationToken)
        {
            return GetTokenAsync(requestContext, cancellationToken).GetAwaiter().GetResult();
        }

        public override async ValueTask<AccessToken> GetTokenAsync(TokenRequestContext requestContext, CancellationToken cancellationToken)
        {
            AuthenticationResult result = await _confidentialClient.AcquireTokenOnBehalfOf(requestContext.Scopes, _userAssertion).ExecuteAsync();

            return new AccessToken(result.AccessToken, result.ExpiresOn);
        }
    }
}