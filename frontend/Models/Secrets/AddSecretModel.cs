using System.ComponentModel;
using System.ComponentModel.DataAnnotations;

namespace keyvault.web.models.secrets
{
    public class AddSecretModel
    {
        [Required]
        [Display(Name = "Secret Name")]
        public string name { get; set; }

        [Required]
        [Display(Name = "Secret Value")]
        public string  value { get; set; }       
    }
}