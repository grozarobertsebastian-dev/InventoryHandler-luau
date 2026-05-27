# InventoryHandler-Luau

A server-side inventory and character management system for Roblox multiplayer games.

It handles secure player interactions with owned characters, including placement, storage, selling, and progression-based restrictions.

## Features

- slot-based character placement system
- storage system with rebirth-based limits
- secure server-side action validation
- character selling system with economy scaling
- rebirth protection to prevent progression loss
- locked / protected character handling
- dynamic character UI (name tags)
- remote event validation for all player actions

## How it works

Players can

- place characters into unlocked slots
- move characters into storage
- sell characters for in-game currency
- receive warnings when selling affects progression requirements

## Usage

Place the module in `ServerScriptService` and require it:

```lua
local InventoryHandler = require(game.ServerScriptService.src.InventoryHandler)
