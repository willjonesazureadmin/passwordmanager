using System;
using System.Net;

namespace keyvault.helpers

{
    public static class Lookup
    {
        public static bool DoGetHostAddresses(string hostname)
        {
            try
            {

                var url = new Uri(hostname);

                IPAddress[] addresses = Dns.GetHostAddresses(url.Host.ToString());

                if (addresses.Length >= 1)
                {
                    return true;
                }
                else{
                    return false;
                }
            }
            catch
            {
                return false;

            }
        }
    }
}