# Initial setup after cloning

Run the following two commands (make sure to update the subscription ID first).

```pwsh
azd env new dpc --no-prompt
azd env set AZURE_SUBSCRIPTION_ID 00000000-0000-0000-0000-000000000000

```

# Provisining a new client environment

1. Determine a client ID for the new client. For example, the acronym or short name of a cooperative.
2. Copy the "_example" folder and underlying files to a new folder under "clients".
3. Update values in bicepparam accordingly for the client. Typically should just need to change "clientId" and "brandingClientName".
4. If you haven't already, login to Azure from the CLI:

```pwsh
azd auth login
```

> [!IMPORTANT]
> The user that runs this provision command will need to have access to both create resources for the subscription as well application registration permissions.


5. Run the azd command to provision the new environment:

```pwsh
azd deploy-client-complete --parameter clientId=<clientId>
```

