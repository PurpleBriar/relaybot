# relaybot

This repo contains a set of sample scripts used to set up an Azure Chat Bot and connect with it through a relay.

## Instructions
1. [Create a C# EchoBot in Visual Studio](https://docs.microsoft.com/en-us/azure/bot-service/bot-service-quickstart-create-bot?view=azure-bot-service-4.0&tabs=csharp%2Cvs), then run and test it with Bot Framework Emulator
1. Set up Azure Relay with [this script](https://github.com/PurpleBriar/relaybot/blob/main/scripts/createBotAndRelay.sh). It will also create the bot service in Azure
1. Set up NetPassage
1. Clone the [NetPassages repo](https://github.com/dannygar/netpassage) and open it in Visual Studio

    a. Go to the directory _**src/NetPassage**_, make a copy of the file _**NetPassage.json.template**_ and name it **_NetPassage.json_**

    b. Update the following fields as stated:

      * Mode (under Relay): "http"

      * Under Http and WebSocket:

        * Namespace: the name of your Azure Service Bus Relay.

        * ConnectionName: the name of the Hybrid Connection used for Http relay. Under the Websocket section, ConnectionName is the name of the Hybrid Connection used for Websocket relay (We won't be using websockets, but create a hybrid connection for websockets anyway).

        * PolicyName: value of the shared access policy for the hybrid connection

        * PolicyKey: value of the secret key for the shared access policy.

        * TargetServiceAddress: the port to be used for localhost. The address and port number should match the address and port used by your bot. For example, http://localhost:[PORT].

1. In Visual Studio, build and run Netpassage

1. In Echobot project (created in step 1), go to src directory and add MicrosoftAppId and MicrosoftAppPassword values to appsettings.json

1. Update and run [this script](https://github.com/PurpleBriar/relaybot/blob/main/scripts/zipAndDeploy.sh) to zip your bot and deploy it to Azure
