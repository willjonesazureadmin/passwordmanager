using System;
using System.Collections.Generic;
using System.Net.Http;
using System.Net.Http.Json;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Components;
using Microsoft.AspNetCore.Components.WebAssembly.Authentication;
using Microsoft.Extensions.Configuration;
using keyvault.web.models.secrets;
using static keyvault.web.models.AppSettings;

namespace keyvault.web.services
{
    public class SecretService
    {

        private readonly HttpClient _http;

        private readonly LocalConfigurations _settings;

        public string KeyvaultUrl { get; private set; }

        private NavigationManager _navManager;

        public SecretService(IHttpClientFactory HttpClientFactory, NavigationManager navigationManager, LocalConfigurations settings)
        {
            this._navManager = navigationManager;
            this._settings = settings;
            this.KeyvaultUrl = _settings.Keyvault.KeyvaultUrl;
            this._http = HttpClientFactory.CreateClient(_settings.Keyvault.ApiClientName);
        }

        public void ChangeKeyvault(string newKeyvaultUrl)
        {
            this.KeyvaultUrl = newKeyvaultUrl;
        }

        public async Task<List<IndexViewSecretModel>> GetAll()
        {
            try
            {
                var dataRequest = await _http.GetAsync(String.Format("{0}/secret", _settings.Keyvault.APIBaseUrl));
                if (!dataRequest.IsSuccessStatusCode)
                {
                    throw new ApplicationException($"Reasong: {dataRequest.ReasonPhrase}"); //or add a custom logic here
                }
                return await dataRequest.Content.ReadFromJsonAsync<List<IndexViewSecretModel>>();

            }
            catch (AccessTokenNotAvailableException exception)
            {
                exception.Redirect();
                throw new ApplicationException($"Reasong: {exception.Message}"); //or add a custom logic here

            }
            catch (Exception exception)
            {
                throw new ApplicationException($"Reasong: {exception.Message}"); //or add a custom logic here

            }
        }

        public async Task<SecretModel> Reveal(string name)
        {
            try
            {
                var dataRequest = await _http.GetAsync(String.Format("{0}/secret/{1}", _settings.Keyvault.APIBaseUrl, name));
                if (!dataRequest.IsSuccessStatusCode)
                {
                    throw new ApplicationException($"Reasong: {dataRequest.ReasonPhrase}"); //or add a custom logic here
                }
                return await dataRequest.Content.ReadFromJsonAsync<SecretModel>();

            }
            catch (AccessTokenNotAvailableException exception)
            {
                exception.Redirect();
                throw new ApplicationException($"Reasong: {exception.Message}"); //or add a custom logic here

            }
            catch (Exception exception)
            {
                throw new ApplicationException($"Reasong: {exception.Message}"); //or add a custom logic here

            }
        }
        public async Task<DetailsViewSecretModel> Get(string name)
        {
            try
            {
                var dataRequest = await _http.GetAsync(String.Format("{0}/secret/{1}", _settings.Keyvault.APIBaseUrl, name));
                if (!dataRequest.IsSuccessStatusCode)
                {
                    throw new ApplicationException($"Reasong: {dataRequest.ReasonPhrase}"); //or add a custom logic here
                }
                return await dataRequest.Content.ReadFromJsonAsync<DetailsViewSecretModel>();

            }
            catch (AccessTokenNotAvailableException exception)
            {
                exception.Redirect();
                throw new ApplicationException($"Reasong: {exception.Message}"); //or add a custom logic here

            }
            catch (Exception exception)
            {
                throw new ApplicationException($"Reasong: {exception.Message}"); //or add a custom logic here

            }
        }


        public async Task Edit(string name, string password)
        {
            try
            {
                var dataRequest = await _http.PostAsJsonAsync(String.Format("{0}/secret/{1}/update", _settings.Keyvault.APIBaseUrl, name), password);
                if (!dataRequest.IsSuccessStatusCode)
                {
                    throw new ApplicationException($"Reasong: {dataRequest.ReasonPhrase}"); //or add a custom logic here
                }
                return;

            }
            catch (AccessTokenNotAvailableException exception)
            {
                exception.Redirect();
                throw new ApplicationException($"Reasong: {exception.Message}"); //or add a custom logic here

            }
            catch (Exception exception)
            {
                throw new ApplicationException($"Reasong: {exception.Message}"); //or add a custom logic here

            }

        }

        public async Task Add(AddSecretModel model)
        {
            try
            {
                var dataRequest = await _http.PostAsJsonAsync(String.Format("{0}/secret", _settings.Keyvault.APIBaseUrl), model);
                if (!dataRequest.IsSuccessStatusCode)
                {
                    throw new ApplicationException($"Reasong: {dataRequest.ReasonPhrase}"); //or add a custom logic here
                }
                return;

            }
            catch (AccessTokenNotAvailableException exception)
            {
                exception.Redirect();
                throw new ApplicationException($"Reasong: {exception.Message}"); //or add a custom logic here

            }
            catch (Exception exception)
            {
                throw new ApplicationException($"Reasong: {exception.Message}"); //or add a custom logic here

            }

        }
    }
}
