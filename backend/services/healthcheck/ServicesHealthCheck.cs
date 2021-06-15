using System;
using System.Net;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Diagnostics.HealthChecks;

public class KeyvayltHealthCheck : IHealthCheck
{
    private readonly IConfiguration _config;
    private bool healthCheckResultHealthy;


    public KeyvayltHealthCheck(IConfiguration appConfig)
    {
        this._config = appConfig;
    }


    public Task<HealthCheckResult> CheckHealthAsync(HealthCheckContext context, CancellationToken cancellationToken = default(CancellationToken))
    {
        DoGetHostAddresses(_config["AppConfiguration:KeyvaultUrl"]);

        if (healthCheckResultHealthy)
        {
            return Task.FromResult(
                HealthCheckResult.Healthy("Keyvault DNS Found"));
        }

        return Task.FromResult(
            new HealthCheckResult(context.Registration.FailureStatus,
            "Keyvault DNS not found"));
    }

    public void DoGetHostAddresses(string hostname)
    {
        try
        {
            var url = new Uri(hostname);
            
            IPAddress[] addresses = Dns.GetHostAddresses(hostname.Remove(0, 8));

            if (addresses.Length >= 1)
            {
                healthCheckResultHealthy = true;
            }
        }
        catch
        {
            healthCheckResultHealthy = false;

        }
    }
}

public class FrontEndHealthCheck : IHealthCheck
{
    private readonly IConfiguration _config;
    private bool healthCheckResultHealthy;


    public FrontEndHealthCheck(IConfiguration appConfig)
    {
        this._config = appConfig;
    }


    public Task<HealthCheckResult> CheckHealthAsync(HealthCheckContext context, CancellationToken cancellationToken = default(CancellationToken))
    {
        DoGetHostAddresses(_config["AppConfiguration:FrontEndUrl"]);

        if (healthCheckResultHealthy)
        {
            return Task.FromResult(
                HealthCheckResult.Healthy("FrontEnd DNS Found"));
        }

        return Task.FromResult(
            new HealthCheckResult(context.Registration.FailureStatus,
            "FrontEnd DNS not found"));
    }

    public void DoGetHostAddresses(string hostname)
    {
        try
        {
            IPAddress[] addresses = Dns.GetHostAddresses(hostname.Remove(0, 8));

            if (addresses.Length >= 1)
            {
                healthCheckResultHealthy = true;
            }
        }
        catch
        {
            healthCheckResultHealthy = false;
        }
    }

    
}

public class EnvironmentHealthCheck : IHealthCheck
{
    
    public Task<HealthCheckResult> CheckHealthAsync(HealthCheckContext context, CancellationToken cancellationToken = default(CancellationToken))
    {

            return Task.FromResult(
                HealthCheckResult.Healthy(Environment.GetEnvironmentVariable("WEBSITE_HOSTNAME")));

    }
   
}