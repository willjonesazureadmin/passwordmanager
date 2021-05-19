## Pipelines
There are three Github actions defined for the deployment of the password manager backend. 

| Pipeline Name | Description | File | Trigger |
| ----------- | ----------- |----------- |----------- |
| .NET Application Build | Perform .NET build tasks |./github/workflows/dotnet-build.yml | On PR to Main |
| ARM Template Checker | Perform ARM Template Best Practice Checks |./github/workflows/arm-ttk.yml | On PR to Main |
| Full Backend Deployment | Full end to end deployment |./github/workflows/dotnet-build.yml | On push to Main |


### .NET Application Build ![Badge](https://github.com/willjonesazureadmin/password-manager-backend/actions/workflows/dotnet-build.yml/badge.svg)

Performs standard .NET build and test to validate the application builds successfully via a single build job. Job must pass to allow a PR to be completed. 

![Job Summary](/docs/images/net-pipeline.png)


### ARM Template Checker ![Badge](https://github.com/willjonesazureadmin/password-manager-backend/actions/workflows/arm-ttk.yml/badge.svg)

Performs the ARM Template Test Toolkit task for best practices as a single job. Job must pass to allow a PR to be completed. 

![Job Summary](/docs/images/ttk-pipeline.png)


### Full Backend Deployment ![Badge](https://github.com/willjonesazureadmin/password-manager-backend/actions/workflows/deploy-production.yml/badge.svg)

Performs a full deployment of the backend infrastructure. Broken down to multiple jobs with dependencies and artifacts.

![Job Summary](/docs/images/deployment-pipeline.png)

