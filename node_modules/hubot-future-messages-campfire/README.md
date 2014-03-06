# hubot-future-messages-campfire

Send messages to people currently not in the room.

## Usage

This module both listens for messages and sends them.

It listens for messages containing (case insensitive) "future NAME" and prints
that when NAME enters the room. So this:

    Hey future Joe, tell me a joke

would be relayed to Joe when he enters the room.

## Installation

Add the package `hubot-future-messages-campfire` as a dependency in your Hubot `package.json` file:

    "dependencies": {
      // ....
      "hubot-future-messages-campfire": ">= 0"
    }

To enable the script, add the `hubot-future-messages-campfire` entry to the
`external-scripts.json` file:

    ["hubot-future-messages-campfire"]

## Bugs

The package finds the first match that contains the target name. So if a message
is intended for "Chris", and "Christian" enters the room, it would see that
"Christian" starts with "Chris" and deliver the message to Christian.
