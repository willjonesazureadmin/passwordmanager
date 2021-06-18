## Authentication

Authetnication and authorisation is handled by Azure Active Directory and the OAuth 2.0 standard. Key to this is "on Behalf-of Flow," this provides the use case where an application invokes a service/web API, which in turn needs to call another service/web API. As detailed [here](https://docs.microsoft.com/en-us/azure/active-directory/develop/v2-oauth2-on-behalf-of-flow#:~:text=Azure%20Active%20Directory%20can%20provide%20a%20SAML%20assertion,web%20service%20API%20endpoints%20that%20consume%20SAML%20tokens) The idea is to propagate the user identity and permissions through the request chain. Allowing the middle tier service to make authenticated requests to the down stream service on behalf of the user.  
In essence, using the permission that the user has to the key vault but from within the password manager application.

The authentication flow is detailed below

![Auth flow](/docs/images/authflow.png)

### Application Registration

Applications are registered in Azure AD. A user must consent to both applications to perform the relevant authentication and authorisation flow to the key vault. The permissions required are:

|Application | Permission  | Perission Name |
--- | --- | ---
|Frontend|Sign in User| Graph - User.Read |
|Frontend|Access Backend App| Backend App - user_impersonation |
|Backend|Access Key vault| Azure key vault - user_impersonation |
|Backend| Sign In User | Graph - User.Read |

As the backend application does not sign in users interactively consent must be gained from the user when they sign into the frontend application. To do this the backend application is configured with a "knownClientId" which is the application Id of the front end application. This means that when a user signs in for the first time they are presented with a consent page for all the applications in the stack.

All of these settings are configured either through the Azure Portal or via scripting the upload of a manifest file that is a JSON representation of the application registrations.

The frontend application is a "public" application, as such, all information regarding the client is public and it does not use application secrets. The backend application is a confidential client and can contain secrets that are used to authenticate the application and to create confidential client tokens. The frontend and backend applications use the Microsoft Authentication Library (MSAL) more details can be found [here](https://docs.microsoft.com/en-us/azure/active-directory/develop/msal-client-applications).

<- [Back to Summary](/docs/architecture/readme.md) | [Now read the setup guide here](/docs/setup/readme.md) ->