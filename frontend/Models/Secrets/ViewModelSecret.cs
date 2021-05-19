
namespace keyvault.web.models.secrets
{
    public class ViewModelSecret
    {
        public string id { get; set; }
        public string name { get; set; }
        public string  value { get
        {
            if(Revealed == false)
            {
                return "*********";
            }
            else
            {
                return _value;
            }
        } 
        set
        {
            this._value = value;
        } }

        private string _value { get; set; }

        public bool Revealed { get; private set; }

        public ViewModelSecret()
        {
            this.Revealed = false;
        }

        public void Reveal()
        {
            if(Revealed == false)
            {
                Revealed = true;
            }
            else
            {
                Revealed = false;
            }
        }
        
    }
}