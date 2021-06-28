using System;
using System.Threading.Tasks;
using Azure.Security.KeyVault.Secrets;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Microsoft.Identity.Web;

namespace keyvault.obo.Controllers
{
    [Authorize]
    [ApiController]
    [Route("[controller]")]
    public class SecretController : ControllerBase
    {


        private readonly ILogger<SecretController> _logger;
        private readonly IConfiguration _config;
        private readonly ITokenAcquisition _tokenAcquisition;
        private string KeyvaultUrl { get; set; }

        public SecretController(ILogger<SecretController> logger, ITokenAcquisition tokenAcquisition, IConfiguration appConfig)
        {
            this._tokenAcquisition = tokenAcquisition;
            this._logger = logger;
            this._config = appConfig;
            this.KeyvaultUrl = _config["AppConfiguration:KeyvaultUrl"];
        }

        [HttpGet]
        public async Task<IActionResult> GetAsync()
        {
            try
            {
                return Ok(await KeyVaultClient.ListSecrets((new OnBehalfOfCredential(_config["AzureAd:ClientId"],_config["AzureAd:ClientSecret"], await GetToken())), this.KeyvaultUrl));
            }
            catch(Azure.RequestFailedException e)
            {
                return BadRequest(e.Message);
            }
            catch (UnauthorizedAccessException e)
            {
                return Unauthorized(e.Message);
            }
            catch (System.Exception)
            {
                return BadRequest();
            }   
        }

        [HttpGet("{SecretId}")]
        public async Task<IActionResult> GetAsync(string SecretId)
        {
            try
            {      
                return Ok(KeyVaultClient.GetSecret((new OnBehalfOfCredential(_config["AzureAd:ClientId"],_config["AzureAd:ClientSecret"], await GetToken())), this.KeyvaultUrl, SecretId));
            }
            catch(Exception e)
            {
                return BadRequest("Something went wrong");
            }

        }

        [HttpPost("{SecretId}/update")]
        public async Task<IActionResult> PostAsync(string SecretId, [FromBody]string secret)
        {
            return Ok(KeyVaultClient.UpdateSecret((new OnBehalfOfCredential(_config["AzureAd:ClientId"],_config["AzureAd:ClientSecret"], await GetToken())), this.KeyvaultUrl, SecretId, secret));
        }

        [HttpPost]
        public async Task<IActionResult> PostAsync(KeyVaultSecret secret)
        {
            return Ok(KeyVaultClient.CreateSecret((new OnBehalfOfCredential(_config["AzureAd:ClientId"],_config["AzureAd:ClientSecret"], await GetToken())), this.KeyvaultUrl, secret));
        }

        private async Task<string> GetToken()
        {
            return await _tokenAcquisition.GetAccessTokenForUserAsync(new[] { String.Format("{0}/{1}",_config["AzureAd:Audience"],_config["AppConfiguration:ApiScope"]) });
        }
    }
}

