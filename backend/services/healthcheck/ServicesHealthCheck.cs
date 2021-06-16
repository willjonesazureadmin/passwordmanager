using System;
using System.Net;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Diagnostics.HealthChecks;
using keyvault.helpers;

public class KeyvaultHealthCheck : IHealthCheck
{
    private readonly IConfiguration _config;
    private bool healthCheckResultHealthy;


    public KeyvaultHealthCheck(IConfiguration appConfig)
    {
        this._config = appConfig;
    }


    public Task<HealthCheckResult> CheckHealthAsync(HealthCheckContext context, CancellationToken cancellationToken = default(CancellationToken))
    {
        healthCheckResultHealthy = Lookup.DoGetHostAddresses(_config["AppConfiguration:KeyvaultUrl"]);

        if (healthCheckResultHealthy)
        {
            return Task.FromResult(
                HealthCheckResult.Healthy("Keyvault DNS Found"));
        }

        return Task.FromResult(
            new HealthCheckResult(context.Registration.FailureStatus,
            "Keyvault DNS not found"));
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
        healthCheckResultHealthy = Lookup.DoGetHostAddresses(_config["AppConfiguration:FrontEndUrl"]);

        if (healthCheckResultHealthy)
        {
            return Task.FromResult(
                HealthCheckResult.Healthy("FrontEnd DNS Found"));
        }

        return Task.FromResult(
            new HealthCheckResult(context.Registration.FailureStatus,
            String.Format("FrontEnd DNS not found: {0}",_config["AppConfiguration:FrontEndUrl"])));
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




