### Key Vault
The key vault is the persistence layer for the application. To be able to access the secrets within the Key vault both the user and the application must be configured with appropriate access policies.

This application is specifically designed so it is the user who has access to the key vault and it is their access token that is used to gain access. However as the application is performing this on behalf of the user it must use a "compound" identity to do so. The is part of "on behalf-of flow" that the application relies on to work.
