using System;

namespace keyvault.web.models.secrets
{
    public class IndexViewSecretModel : ViewModelSecret
    {
        public string vaultUri { get; set; }
        public DateTime updatedOn { get; set; }
        
    }
}