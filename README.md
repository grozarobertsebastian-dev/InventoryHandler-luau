# InventoryHandler-Luau

A simple Roblox server inventory system for handling character placement, storage, and selling logic.

This system manages how players interact with their owned characters in slots and storage, including movement, selling, and basic safety checks.

## Features

- move characters between slots and storage
- limit-based storage system per rebirth level
- sell system with confirmation protection
- rebirth protection (prevents accidental progression loss)
- locked / protected character system
- automatic UI name tags for characters
- safe server-side validation for all actions

## How it works

Players can

- place characters into available slots
- move characters into storage
- sell characters for coins
- receive warnings if selling affects rebirth requirements

## Usage

Place the module in `ServerScriptService` and require it:

```lua
local InvetoryHandler = require(game.ServerScriptService.src.InventoryHandler)