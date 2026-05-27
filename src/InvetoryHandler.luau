-- inventroy storage and selling handler
-- rebirth safety checks

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local GD = require(ReplicatedStorage.Shared.GameData)

-- game configuration
local formatNumber        = GD.formatNumber
local SLOTS_PER_REBIRTH   = GD.SLOTS_PER_REBIRTH
local STORAGE_PER_REBIRTH = GD.STORAGE_PER_REBIRTH
local REBIRTH_REQUIREMENTS = GD.REBIRTH_REQUIREMENTS

local function getStarMultiplier(stars)
	return GD.getStarMultiplier(stars)
end

-- player helpers

local function getRebirthLevel(player)
	local ls = player:FindFirstChild("leaderstats")
	if not ls then return 0 end
	local rebirths = ls:FindFirstChild("Rebirths")
	return rebirths and rebirths.Value or 0
end

local function getStorageLimit(player)
	return STORAGE_PER_REBIRTH[getRebirthLevel(player)] or 4
end

local function getUnlockedSlots(player)
	return SLOTS_PER_REBIRTH[getRebirthLevel(player)] or 5
end

local function getPlayerBasePlateau(player)
	local pn = player:GetAttribute("SpawnerNumber") or 1
	local folder = workspace:FindFirstChild("SpawnerPlayer" .. pn)
	if not folder then return nil end
	return folder:FindFirstChild("BasePlateau" .. pn)
end

local function isCharacterOwnedByPlayer(player, character)
	if not character or not character.Parent then return false end

	local parent = character.Parent
	local pn = player:GetAttribute("SpawnerNumber") or 1

	if parent.Name:match("^Slot%d+$") then
		local bp = parent.Parent
		if bp and bp.Name == "BasePlateau" .. pn then
			return true
		end
	end

	if parent.Name == "Storage" then
		local inv = parent.Parent
		if inv and inv.Name == "Inventory" and inv.Parent == player then
			return true
		end
	end

	return false
end

-- inventory storage

local function ensureStorage(player)
	local inv = player:FindFirstChild("Inventory")
	if not inv then
		inv = Instance.new("Folder")
		inv.Name = "Inventory"
		inv.Parent = player
	end

	local storage = inv:FindFirstChild("Storage")
	if not storage then
		storage = Instance.new("Folder")
		storage.Name = "Storage"
		storage.Parent = inv
	end

	return storage
end

-- character counting

local function countCharacterOwned(player, charName)
	local count = 0

	local bp = getPlayerBasePlateau(player)
	if bp then
		for _, slot in pairs(bp:GetChildren()) do
			if slot.Name:match("^Slot%d+$") then
				for _, child in pairs(slot:GetChildren()) do
					if child:IsA("BasePart") and child.Name == "PlacedCharacter" then
						if child:GetAttribute("CharacterName") == charName then
							count += 1
						end
					end
				end
			end
		end
	end

	local inv = player:FindFirstChild("Inventory")
	if inv then
		local storage = inv:FindFirstChild("Storage")
		if storage then
			for _, child in pairs(storage:GetChildren()) do
				if child:IsA("BasePart") and child:GetAttribute("CharacterName") == charName then
					count += 1
				end
			end
		end
	end

	return count
end

-- rebirth protection check

local function wouldSellBlockRebirth(player, charName)
	local nextRebirth = getRebirthLevel(player) + 1
	if nextRebirth > 9 then return false, 0 end

	local req = REBIRTH_REQUIREMENTS[nextRebirth]
	if not req then return false, 0 end

	local needed = req.Characters[charName]
	if not needed then return false, 0 end

	local owned = countCharacterOwned(player, charName)

	if owned <= needed then
		return true, nextRebirth
	end

	return false, 0
end

-- colors

local ANIME_COLORS = {
	["Solo Leveling"]=Color3.fromRGB(108,59,245),
	["Black Clover"]=Color3.fromRGB(26,188,156),
	["Hunter x Hunter"]=Color3.fromRGB(76,175,80),
	["Bleach"]=Color3.fromRGB(245,166,35),
	["My Hero Academia"]=Color3.fromRGB(46,204,113),
	["Attack on Titan"]=Color3.fromRGB(107,142,35),
	["Dragon Ball"]=Color3.fromRGB(255,140,0),
	["Naruto"]=Color3.fromRGB(255,107,53),
	["One Piece"]=Color3.fromRGB(231,76,60),
}

local RARITY_COLORS = GD.RARITY_COLORS
local RARITY_DISPLAY = GD.RARITY_DISPLAY

-- nametag system

local function refreshNameTag(character)
	local charName = character:GetAttribute("CharacterName") or "Unknown"
	local rarity = character:GetAttribute("Rarity") or "Common"
	local anime = character:GetAttribute("Anime") or "Unknown"

	local baseIncome = character:GetAttribute("BasePassiveIncome") 
		or character:GetAttribute("PassiveIncome") or 0

	local stars = character:GetAttribute("Stars") or 1
	local rarityColor = RARITY_COLORS[rarity] or Color3.fromRGB(180,180,180)
	local rarityDisplay = RARITY_DISPLAY[rarity] or "Common"

	local starMult = getStarMultiplier(stars)
	local actualIncome = baseIncome * starMult

	local old = character:FindFirstChild("NameTag")
	if old then old:Destroy() end

	local bbg = Instance.new("BillboardGui")
	bbg.Name = "NameTag"
	bbg.Adornee = character
	bbg.Size = UDim2.new(0, 200, 0, 110)
	bbg.StudsOffset = Vector3.new(0, 5, 0)
	bbg.Parent = character

	local frame = Instance.new("Frame", bbg)
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundColor3 = Color3.fromRGB(10,10,14)
	frame.BackgroundTransparency = 0.1

	local stroke = Instance.new("UIStroke", frame)
	stroke.Color = rarityColor
	stroke.Thickness = 1.5

	local name = Instance.new("TextLabel", frame)
	name.Text = charName
	name.Size = UDim2.new(1,0,0,20)
	name.BackgroundTransparency = 1
	name.Font = Enum.Font.GothamBold
	name.TextSize = 16
	name.TextColor3 = Color3.fromRGB(255,255,255)

	local income = Instance.new("TextLabel", frame)
	income.Text = "+" .. formatNumber(actualIncome) .. "/s"
	income.Size = UDim2.new(1,0,0,18)
	income.Position = UDim2.new(0,0,0,40)
	income.BackgroundTransparency = 1
	income.Font = Enum.Font.GothamBold
	income.TextSize = 12
	income.TextColor3 = Color3.fromRGB(100,255,120)
end

-- remote events

local moveToSlotEvent = ReplicatedStorage:FindFirstChild("MoveToSlotEvent")
local moveToStorageEvent = ReplicatedStorage:FindFirstChild("MoveToStorageEvent")
local sellFromInventoryEvent = ReplicatedStorage:FindFirstChild("SellFromInventoryEvent")
local notifyEvent = ReplicatedStorage:FindFirstChild("NotifyEvent")

local sellConfirmEvent = Instance.new("RemoteEvent")
sellConfirmEvent.Name = "SellConfirmEvent"
sellConfirmEvent.Parent = ReplicatedStorage

local sellConfirmResponseEvent = Instance.new("RemoteEvent")
sellConfirmResponseEvent.Name = "SellConfirmResponseEvent"
sellConfirmResponseEvent.Parent = ReplicatedStorage

local pendingSells = {}

-- move to slot ( repaired )

moveToSlotEvent.OnServerEvent:Connect(function(player, character)
	if not character or not character.Parent then return end
	if not isCharacterOwnedByPlayer(player, character) then return end

	local base = getPlayerBasePlateau(player)
	if not base then return end

	local unlocked = getUnlockedSlots(player)
	local freeSlot = nil

	for i = 0, unlocked - 1 do
		local slot = base:FindFirstChild("Slot" .. i)
		if slot then
			local empty = true
			for _, c in pairs(slot:GetChildren()) do
				if c.Name == "PlacedCharacter" then
					empty = false
					break
				end
			end
			if empty then
				freeSlot = slot
				break
			end
		end
	end

	if not freeSlot then
		notifyEvent:FireClient(player, "No free slots!", "error")
		return
	end

	character.Parent = freeSlot
	character:SetAttribute("InInventory", false)
	refreshNameTag(character)

	notifyEvent:FireClient(player, "Character placed!", "success")
end)

-- move to storage

moveToStorageEvent.OnServerEvent:Connect(function(player, character)
	if not character or not character.Parent then return end
	if not isCharacterOwnedByPlayer(player, character) then return end

	local storage = ensureStorage(player)
	character.Parent = storage
	character.Position = Vector3.new(0,-200,0)
	character:SetAttribute("InInventory", true)

	notifyEvent:FireClient(player, "Moved to storage!", "info")
end)

-- sell system

local function executeSell(player, character)
	if not character or not character.Parent then return end
	if not isCharacterOwnedByPlayer(player, character) then return end

	local price = character:GetAttribute("Price") or 10
	local stars = character:GetAttribute("Stars") or 1
	local mult = getStarMultiplier(stars)

	local sellPrice = math.floor(price * 0.5 * mult)

	local ls = player:FindFirstChild("leaderstats")
	if ls then
		local coins = ls:FindFirstChild("Coins")
		if coins then
			coins.Value += sellPrice
		end
	end

	character:Destroy()

	notifyEvent:FireClient(player, "Sold for "..sellPrice, "success")
end

sellFromInventoryEvent.OnServerEvent:Connect(function(player, character)
	if not character then return end
	if not isCharacterOwnedByPlayer(player, character) then return end

	local name = character:GetAttribute("CharacterName") or "Character"
	local block, rebirth = wouldSellBlockRebirth(player, name)

	if block then
		pendingSells[player] = character
		sellConfirmEvent:FireClient(player, name, rebirth)
		return
	end

	executeSell(player, character)
end)

sellConfirmResponseEvent.OnServerEvent:Connect(function(player, confirmed)
	local character = pendingSells[player]
	pendingSells[player] = nil

	if confirmed and character then
		executeSell(player, character)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	pendingSells[player] = nil
end)

print("InventoryHandler loaded")
