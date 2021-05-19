## Password Manager Backend Architecture

Written in .NET 5 C# this is an ASP.NET Core API application. Hosted on Azure App Services the application "proxies" user requests and access tokens to an Azure based KeyVault to perform CRUD operations against secrets. 

![Passman Architecture](/docs/images/passman-backend-architecture.png)