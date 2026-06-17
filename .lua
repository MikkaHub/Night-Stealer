local TweenService     = game:GetService("TweenService")
local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local HttpService      = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService     = game:GetService("SoundService")
local Debris           = game:GetService("Debris")

local LocalPlayer = Players.LocalPlayer
local playerGui   = LocalPlayer:WaitForChild("PlayerGui")

local CONFIG_FILE  = "GAG_FakePrompt.json"

local Config = {
	Robux           = 456000,
	PanelKey        = "L",
	SuccessVerb     = "bought",
	GiftTargetName  = "",

	DefaultImage    = "",
	GiftSfxName       = "Purchase",
	PurchaseSfxName   = "Purchase",
	GiftSoundId       = "",
	PurchaseSoundId   = "",
	GiftNotifyDelay   = 0.4,
	GiftNotifySfxName = "Notification",
	GiftNotifySoundId = "",
	ShowGiftPopup     = false,
	GiftPopupDuration = 4,
	GiftSideNotifications = false,
	MainNotifications = true,
	ShowQuantity      = true,
	GiftNamePrefix    = "[GIFT] ",
	GiftTitle         = "Gift item",
	BuyTitle          = "Buy item",
	UseRealProductInfo = true,
	HookAllShops      = true,
	PanelPosX       = 1,
	PanelPosOffsetX = -16,
	PanelPosY       = 1,
	PanelPosOffsetY = -16,

	PromptAssetId   = "rbxassetid://81789757744504",
	OverlayAssetId  = "rbxassetid://112129551120409",
}

pcall(function()
	if isfile and readfile and writefile then
		if isfile(CONFIG_FILE) then
			local ok, decoded = pcall(function()
				return HttpService:JSONDecode(readfile(CONFIG_FILE))
			end)
			if ok and decoded then
				for k, v in pairs(decoded) do Config[k] = v end
			end
		else
			writefile(CONFIG_FILE, HttpService:JSONEncode(Config))
		end
	end
end)

local function saveConfig()
	pcall(function()
		if writefile then
			writefile(CONFIG_FILE, HttpService:JSONEncode(Config))
		end
	end)
end

local function create(cls, props, children)
	local inst = Instance.new(cls)
	for k, v in pairs(props or {}) do inst[k] = v end
	for _, c in pairs(children or {}) do c.Parent = inst end
	return inst
end

local function makeCorner(r)
	return create("UICorner", { CornerRadius = UDim.new(0, r or 6) })
end

local function makeStroke(col, thick)
	return create("UIStroke", {
		Color     = col   or Color3.fromRGB(255, 105, 180),
		Thickness = thick or 1,
	})
end

local function formatCommas(n)
	return tostring(n):reverse():gsub("%d%d%d", "%1,"):gsub(",$", ""):reverse()
end

local function priceFromText(txt)
	local digits = tostring(txt or ""):gsub("[^%d]", "")
	return tonumber(digits)
end

local function splitQty(str)
	local base, qty = tostring(str or ""):match("^(.-):(%d+)$")
	if base and base ~= "" then return base, tonumber(qty) end
	return str, nil
end

local function formatItemName(baseName, qty, isGift)
	local display = baseName or "Item"
	if Config.ShowQuantity and qty and qty > 1 then
		display = string.format("%s (x%d)", display, qty)
	end
	if isGift and Config.GiftNamePrefix and Config.GiftNamePrefix ~= "" then
		display = Config.GiftNamePrefix .. display
	end
	return display
end

local function notify(msg)
	if not Config.MainNotifications then return end
	local fired = pcall(function()
		local n = ReplicatedStorage:FindFirstChild("Notify")
		if n then n:Fire(msg) else error("no Notify") end
	end)
	if not fired then
		pcall(function()
			local Controllers = LocalPlayer:WaitForChild("PlayerScripts"):FindFirstChild("Controllers")
			local NC = Controllers and Controllers:FindFirstChild("NotificationController")
			if NC then require(NC):CreateNotification(msg) else error("no NC") end
		end)
	end
end

local BG_COLOR       = Color3.fromRGB(248, 248, 252)
local BTN_DARK       = Color3.fromRGB(200, 50, 100)
local BTN_LIGHT      = Color3.fromRGB(255, 105, 180)
local BTN_HOVER      = Color3.fromRGB(255, 150, 200)
local BORDER_COLOR   = Color3.fromRGB(255, 105, 180)
local TEXT_WHITE     = Color3.fromRGB(255, 255, 255)
local TEXT_DARK      = Color3.fromRGB(40, 40, 50)
local TEXT_PINK      = Color3.fromRGB(200, 50, 100)
local X_HOVER_BG     = Color3.fromRGB(255, 220, 230)
local ROBUX_ICON_ID  = "rbxasset://textures/ui/common/robux@3x.png"
local ROBUX_RICH     = '<font family="rbxasset://LuaPackages/Packages/_Index/BuilderIcons/BuilderIcons/BuilderIcons.json" weight="400">robux</font> %s'

do
	local objs = game:GetObjects(Config.PromptAssetId)
	if objs and objs[1] then
		objs[1].Name   = "PC"
		objs[1].Parent = playerGui
	end
	local fnd = game:GetObjects(Config.OverlayAssetId)
	if fnd and fnd[1] then
		fnd[1].Name   = "FoundationOverlay"
		fnd[1].Parent = playerGui
	end
end
task.wait(0.5)

local PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts")
local Controllers   = PlayerScripts:WaitForChild("Controllers")
local SharedModules  = ReplicatedStorage:WaitForChild("SharedModules")

local DevProductController = require(Controllers:WaitForChild("DevProductController"))
local GuiController        = require(Controllers:WaitForChild("GuiController"))
local SfxController
pcall(function() SfxController = require(Controllers:WaitForChild("SfxController")) end)

local DevProducts, RobuxShopContent, SeedPackData, GearShopData, NumberUtils, SeedData
pcall(function() DevProducts      = require(SharedModules:WaitForChild("DevProducts")) end)
pcall(function() RobuxShopContent = require(SharedModules:WaitForChild("RobuxShopContent")) end)
pcall(function() SeedPackData     = require(SharedModules:WaitForChild("SeedPackData")) end)
pcall(function() GearShopData     = require(SharedModules:WaitForChild("GearShopData")) end)
pcall(function() NumberUtils      = require(SharedModules:WaitForChild("NumberUtils")) end)
pcall(function() SeedData         = require(SharedModules:WaitForChild("SeedData")) end)

local gearByName = {}
if GearShopData and GearShopData.Data then
	for _, g in pairs(GearShopData.Data) do gearByName[g.ItemName] = g end
end

local gamepassByName = {}
if RobuxShopContent and RobuxShopContent.Gears then
	for _, g in pairs(RobuxShopContent.Gears) do
		if g.Name and g.GamepassKey then gamepassByName[g.Name] = g.GamepassKey end
	end
end

local seedByName = {}
if SeedData then
	for _, e in pairs(SeedData) do
		if type(e) == "table" and e.SeedName then seedByName[e.SeedName] = e end
	end
end

local function seedImage(name)
	local e = seedByName[name]
	if not e then return nil end
	local img
	pcall(function()
		local si = e.SeedImage
		if typeof(si) == "Instance" then img = si.Value
		elseif type(si) == "string" then img = si end
	end)
	if img and img ~= "" then return img end
	return nil
end

local function resolveImageByName(name)
	if not name or name == "" then return nil end
	local g = gearByName[name]
	if g and g.IMG and g.IMG ~= "" then return g.IMG end
	local si = seedImage(name)
	if si then return si end
	if SeedPackData and SeedPackData.GetData then
		local ok, d = pcall(SeedPackData.GetData, name)
		if ok and d then
			if d.IMG and d.IMG ~= "" then return d.IMG end
			if d.Seeds and d.Seeds[1] then return seedImage(d.Seeds[1].SeedName) end
		end
	end
	return nil
end

local function playSfx(sfxName, soundId)
	if sfxName and sfxName ~= "" and SfxController and SfxController.PlaySFX then
		pcall(function() SfxController:PlaySFX(sfxName) end)
	end
	if soundId and soundId ~= "" then
		pcall(function()
			local snd = Instance.new("Sound")
			snd.SoundId = soundId
			snd.Volume = 0.6
			snd.Parent = SoundService
			snd:Play()
			Debris:AddItem(snd, 6)
		end)
	end
end

local function showGiftPopup(itemName)
	if not Config.ShowGiftPopup then return end
	pcall(function()
		local gifting = playerGui:FindFirstChild("Gifting")
		local src = gifting and gifting:FindFirstChild("Notification")
		if not src then return end
		local holder = playerGui:FindFirstChild("GAGGiftFake")
		if holder then holder:Destroy() end
		holder = Instance.new("ScreenGui")
		holder.Name = "GAGGiftFake"
		holder.ResetOnSpawn = false
		holder.IgnoreGuiInset = true
		holder.DisplayOrder = 250
		holder.Parent = playerGui
		local clone = src:Clone()
		clone.Visible = true
		clone.Parent = holder
		local tl = clone:FindFirstChild("TextLabel")
		if tl then tl.Text = ("@%s gifted:"):format(LocalPlayer.Name) end
		local reward = clone:FindFirstChild("Reward")
		if reward then
			if reward:IsA("TextLabel") or reward:IsA("TextButton") then reward.Text = itemName end
			local rtl = reward:FindFirstChild("TextLabel")
			if rtl then rtl.Text = itemName end
		end
		local btns = clone:FindFirstChild("Buttons")
		if btns then btns.Visible = false end
		task.delay(Config.GiftPopupDuration or 4, function()
			if holder then holder:Destroy() end
		end)
	end)
end

local resolveGamepass

local function realProductInfo(productString)
	local ok, info = pcall(function()
		return DevProductController:WaitForPreloadedProductInfo(productString, 3)
	end)
	if ok and type(info) == "table" then return info end
	return nil
end

local function infoImage(info)
	if type(info) ~= "table" then return nil end
	if type(info.Image) == "string" and info.Image ~= "" then return info.Image end
	if type(info.IconImageAssetId) == "number" then
		return "rbxassetid://" .. tostring(info.IconImageAssetId)
	end
	return nil
end

local function realProductPrice(baseString)
	local info = realProductInfo(baseString)
	if info and type(info.PriceInRobux) == "number" then return info.PriceInRobux end
	return nil
end

local function resolveProduct(productString)
	local original = tostring(productString)
	local out = { name = "Item", price = Config.Robux, image = Config.DefaultImage, isGift = false, productString = original }

	if original:find(":Gift", 1, true) or original:match("^Gift:") then out.isGift = true end

	local infoImg, infoPrice
	local info = realProductInfo(original)
	if info then
		if type(info.PriceInRobux) == "number" then infoPrice = info.PriceInRobux end
		if Config.UseRealProductInfo then infoImg = infoImage(info) end
	end

	local s = original:gsub(":Gift$", "")
	local baseName, qty, img, price

	local gpGiftName = s:match("^Gift:(.+):1$")
	if gpGiftName then
		local key = gamepassByName[gpGiftName]
		if key then
			local gp = resolveGamepass(key)
			baseName, price, img = gp.name, gp.price, gp.image
		elseif gearByName[gpGiftName] then
			baseName = gpGiftName
			price = realProductPrice(("Gear:%s:1"):format(gpGiftName))
			img = gearByName[gpGiftName].IMG
		else
			baseName = gpGiftName
		end
	else
		local amount = s:match("^Currency:Sheckles:(%d+)")
		if amount then
			baseName = ("%s Sheckles"):format(formatCommas(tonumber(amount)))
			price = realProductPrice(("Currency:Sheckles:%s"):format(amount))
			if RobuxShopContent and RobuxShopContent.Sheckles then
				for _, e in pairs(RobuxShopContent.Sheckles) do
					if tostring(e.Amount) == amount and e.Image then img = e.Image break end
				end
			end
		else
			local packCapture = s:match("^SeedPack:(.+)$")
			if packCapture then
				local packName, packQty = splitQty(packCapture)
				baseName, qty = packName, packQty
				price = realProductPrice(s) or realProductPrice(("SeedPack:%s"):format(packName))
				if SeedPackData and SeedPackData.GetData then
					local d = SeedPackData.GetData(packName)
					if d then
						baseName = d.DisplayName or packName
						if d.IMG and d.IMG ~= "" then
							img = d.IMG
						elseif d.Seeds and d.Seeds[1] then
							img = seedImage(d.Seeds[1].SeedName)
						end
					end
				end
			else
				local seedName = s:match("^Seed:(.+)$")
				if seedName then
					local sb, sq = splitQty(seedName)
					baseName = ("%s Seed"):format(sb)
					qty = sq
					price = realProductPrice(s)
					img = seedImage(sb)
				elseif s:match("StarterPack") then
					baseName = "Starter Pack"
					price = realProductPrice("Standalone:StarterPack:1")
				else
					local prefix, rest = s:match("^([^:]+):(.+)$")
					if prefix and rest then
						local itemName, genQty = splitQty(rest)
						baseName, qty = itemName, genQty
						price = realProductPrice(s) or realProductPrice(("%s:%s:1"):format(prefix, itemName))
						img = resolveImageByName(itemName)
					else
						local fbBase, fbQty = splitQty((s:gsub("^%w+:", "")))
						baseName, qty = fbBase, fbQty
						price = realProductPrice(s)
						img = resolveImageByName(fbBase)
					end
				end
			end
		end
	end

	out.name      = formatItemName(baseName, qty, out.isGift)
	out.cleanName = formatItemName(baseName, qty, false)
	if infoImg and infoImg ~= "" then out.image = infoImg elseif img and img ~= "" then out.image = img end
	out.price = infoPrice or price or out.price
	return out
end

resolveGamepass = function(key)
	local out = { name = tostring(key), price = Config.Robux, image = Config.DefaultImage, isGift = false }
	if DevProducts and DevProducts.GetGamepassByKey then
		pcall(function() DevProductController:WaitForGamepassesReady() end)
		local gp = DevProducts.GetGamepassByKey(key)
		if gp then
			out.name  = gp.DisplayName or gp.Name or out.name
			out.price = gp.PriceInRobux or out.price
			out.image = gp.Image or out.image
		end
	end
	return out
end

local lastGiftTarget

local function setGiftTarget(name)
	if type(name) == "string" and name:gsub("%s", "") ~= "" then
		lastGiftTarget = name
	end
end

local function setGiftTargetByUserId(userId)
	if type(userId) ~= "number" then return end
	local ok, plr = pcall(function() return Players:GetPlayerByUserId(userId) end)
	if ok and plr then
		setGiftTarget(plr.Name)
		return
	end
	task.spawn(function()
		local ok2, nm = pcall(function() return Players:GetNameFromUserIdAsync(userId) end)
		if ok2 and nm then setGiftTarget(nm) end
	end)
end

local function readSelectionInfo(info)
	if info == nil then return end
	if type(info) == "table" then
		setGiftTarget(info.Name or (info.Player and info.Player.Name))
		if type(info.UserId) == "number" then setGiftTargetByUserId(info.UserId) end
	elseif typeof(info) == "Instance" and info:IsA("Player") then
		setGiftTarget(info.Name)
	end
end

local function hookPlayerSelected(ev)
	if not (ev and typeof(ev) == "Instance" and ev:IsA("BindableEvent")) then return end
	if ev:GetAttribute("__gagHooked") then return end
	ev:SetAttribute("__gagHooked", true)
	ev.Event:Connect(readSelectionInfo)
end

task.spawn(function()
	local ps = playerGui:WaitForChild("PlayerSelector", 30)
	if ps then
		local sel = ps:WaitForChild("PlayerSelected", 10)
		if sel then hookPlayerSelected(sel) end
	end
end)
for _, d in ipairs(playerGui:GetDescendants()) do
	if d.Name == "PlayerSelected" then hookPlayerSelected(d) end
end
playerGui.DescendantAdded:Connect(function(d)
	if d.Name == "PlayerSelected" then hookPlayerSelected(d) end
end)

pcall(function()
	local Networking = require(SharedModules:WaitForChild("Networking"))
	local dp = Networking and Networking.DevProducts
	local sgt = dp and dp.SetGiftTarget
	if not sgt then return end
	if typeof(sgt) == "Instance" then
		if sgt:IsA("BindableEvent") then
			sgt.Event:Connect(setGiftTargetByUserId)
		elseif sgt:IsA("RemoteEvent") then
			sgt.OnClientEvent:Connect(setGiftTargetByUserId)
		end
	elseif type(sgt) == "table" then
		if type(sgt.Fire) == "function" then
			local realFire = sgt.Fire
			sgt.Fire = function(self, userId, ...)
				setGiftTargetByUserId(userId)
				return realFire(self, userId, ...)
			end
		end
		if type(sgt.Connect) == "function" then
			pcall(function() sgt:Connect(setGiftTargetByUserId) end)
		end
	end
end)

local function giftTargetName()
	if Config.GiftTargetName ~= "" then return Config.GiftTargetName end
	if lastGiftTarget and lastGiftTarget:gsub("%s", "") ~= "" then return lastGiftTarget end
	local name
	pcall(function()
		local sel = playerGui:FindFirstChild("PlayerSelector", true)
		if sel then
			local lbl = sel:FindFirstChild("PlayerName", true)
			if lbl and lbl.Text and lbl.Text:gsub("%s", "") ~= "" then name = lbl.Text end
		end
	end)
	return name or LocalPlayer.Name
end

local function setModalTitle(modal, text)
	if not text or text == "" then return end
	pcall(function()
		local mh = modal:FindFirstChild("ModalHeader", true)
		if not mh then return end
		local right = mh:FindFirstChild("RightSide")
		local function ok(t) return t:IsA("TextLabel") and not (right and t:IsDescendantOf(right)) end
		for _, t in ipairs(mh:GetDescendants()) do
			if ok(t) then
				local cur = t.Text or ""
				if cur:find("item") or cur:find("Item") or cur == "Buy" or cur == "Gift" or cur == "Purchase" then
					t.RichText = false
					t.Text = text
					return
				end
			end
		end
		for _, t in ipairs(mh:GetDescendants()) do
			if ok(t) then
				t.RichText = false
				t.Text = text
				return
			end
		end
	end)
end

local function showPrompt(details, onPurchased)
	details = details or {}
	local itemName  = details.name  or "Item"
	local cleanName = details.cleanName or itemName
	local itemPrice = details.price or 0
	local itemImage = details.image or Config.DefaultImage
	local isGift    = details.isGift == true
	local isSilent  = details.silent == true

	local FoundationOverlay = playerGui:WaitForChild("FoundationOverlay")

	if not FoundationOverlay:FindFirstChild("FoundationStyleSheet") then
		pcall(function()
			playerGui.PC.FoundationStyleSheet:Clone().Parent = FoundationOverlay
			FoundationOverlay.FoundationStyleLink.StyleSheet =
				FoundationOverlay:WaitForChild("FoundationStyleSheet")
		end)
	end

	local ProductPurchaseModal  = playerGui.PC.ProductPurchaseModal:Clone()
	local SheetContainer        = playerGui.PC.SheetContainer

	SheetContainer.Position          = UDim2.new(0.5, 0, 0.5, 25)
	SheetContainer.GroupTransparency = 1
	SheetContainer.AnchorPoint       = Vector2.new(0.5, 0.5)

	local SheetContainer_0      = ProductPurchaseModal.SheetContainer
	local BuyButton             = ProductPurchaseModal.SheetContainer.Sheet.Content.Actions["1"].BuyButton
	local CloseAffordance       = ProductPurchaseModal.SheetContainer.Sheet.Content.Header.Content.CloseAffordance
	local RobuxPrice            = ProductPurchaseModal.SheetContainer.Sheet.Content.Header.Content.SubContent.ModalHeader.RightSide.RobuxPrice
	local ProductPurchasePrompt = playerGui.PC.ProductPurchasePrompt:Clone()
	local SheetContainer_1      = ProductPurchasePrompt.SheetContainer
	local ConfirmButton         = ProductPurchasePrompt.SheetContainer.Sheet.Content.Actions["1"]
	local CloseAffordance2      = ProductPurchasePrompt.SheetContainer.Sheet.Content.Header.Content.CloseAffordance

	local tweenOpen = TweenService:Create(SheetContainer,
		TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
		{ GroupTransparency = 0, Position = UDim2.new(0.5, 0, 0.5, 0) })

	local tweenClose = TweenService:Create(SheetContainer,
		TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ GroupTransparency = 1, Position = UDim2.new(0.5, 0, 0.5, 25) })

	local tweenGradient = TweenService:Create(BuyButton.Gradient,
		TweenInfo.new(2.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ Offset = Vector2.new(1, 0) })

	local canBuy = false
	local isAnim = false

	task.spawn(function()
		pcall(function()
			local d = ProductPurchaseModal.SheetContainer.Sheet.Content.Content
				.ScrollingFrame.ScrollingFrame.SheetContentContainer
				.ProductDetailsContainer.ProductDetails

			d.ItemIcon.Image = itemImage
			d.ItemDetailsFrame.ItemName.Text = itemName
			d.ItemDetailsFrame.ItemDetails.ItemCost.Text = string.format(ROBUX_RICH, formatCommas(itemPrice))
		end)

		pcall(function()
			setModalTitle(ProductPurchaseModal, details.title or (isGift and Config.GiftTitle or Config.BuyTitle))
		end)

		pcall(function()
			ProductPurchasePrompt.SheetContainer.Sheet.Content.Content
				.ScrollingFrame.ScrollingFrame.Body.Message.Text =
				isGift
					and string.format("You have successfully gifted %s.", cleanName, giftTargetName())
					or  string.format("You have successfully bought %s.", cleanName)
		end)

		pcall(function()
			RobuxPrice.RichText = true
			RobuxPrice.Text = string.format(ROBUX_RICH, formatCommas(Config.Robux))
			for _, child in ipairs(RobuxPrice.Parent:GetChildren()) do
				if child ~= RobuxPrice then child.Visible = true end
			end
		end)
	end)

	local function closeModal()
		if isAnim then
			if tweenOpen.PlaybackState    == Enum.PlaybackState.Playing then tweenOpen:Cancel() end
			if tweenGradient.PlaybackState == Enum.PlaybackState.Playing then tweenGradient:Cancel() end
		end
		isAnim = true
		CloseAffordance.Active               = false
		ProductPurchaseModal.Backdrop.Active = false

		for _, c in pairs(SheetContainer_0:GetChildren()) do c.Parent = SheetContainer end
		SheetContainer_0.Parent = playerGui.PC
		SheetContainer.Parent   = ProductPurchaseModal

		TweenService:Create(ProductPurchaseModal.Backdrop,
			TweenInfo.new(0.1, Enum.EasingStyle.Quad),
			{ BackgroundTransparency = 1 }):Play()

		tweenClose:Play()
		tweenClose.Completed:Once(function()
			isAnim = false
			ProductPurchaseModal.Parent = nil
			for _, c in pairs(SheetContainer:GetChildren()) do c.Parent = SheetContainer_0 end
			SheetContainer.Parent   = playerGui.PC
			SheetContainer_0.Parent = ProductPurchaseModal
			ProductPurchaseModal:Destroy()
		end)
	end

	local successFinalized = false
	local function finalizeSuccess()
		if successFinalized then return end
		successFinalized = true
		if isSilent then return end
		if isGift then
			local recipient = giftTargetName()
			task.spawn(function()
				playSfx(Config.PurchaseSfxName, Config.PurchaseSoundId)
				task.wait(Config.GiftNotifyDelay or 0.4)
				notify(("<font color=\"#ff4444\">@%s</font> received: %s"):format(recipient, cleanName))
				playSfx(Config.GiftNotifySfxName, Config.GiftNotifySoundId)
				if Config.GiftSideNotifications then showGiftPopup(itemName) end
			end)
		else
			playSfx(Config.PurchaseSfxName, Config.PurchaseSoundId)
			notify(("You %s %s!"):format(Config.SuccessVerb, cleanName))
		end
	end

	local function showSuccessPrompt()
		SheetContainer_1.Parent               = playerGui.PC
		CloseAffordance2.Active               = true
		ProductPurchasePrompt.Backdrop.Active = true
		ConfirmButton.BackgroundTransparency  = 0.5
		ConfirmButton.Text.TextTransparency   = 0.5
		ProductPurchasePrompt.Parent          = FoundationOverlay

		TweenService:Create(ProductPurchasePrompt.Backdrop,
			TweenInfo.new(0.1, Enum.EasingStyle.Quad),
			{ BackgroundTransparency = 0.25 }):Play()

		SheetContainer_1.Parent              = ProductPurchasePrompt
		ConfirmButton.BackgroundTransparency = 0
		ConfirmButton.Text.TextTransparency  = 0
	end

	if not isAnim then
		isAnim = true
		for _, c in pairs(SheetContainer_0:GetChildren()) do c.Parent = SheetContainer end
		SheetContainer_0.Parent = playerGui.PC
		SheetContainer.Parent   = ProductPurchaseModal

		CloseAffordance.Active               = true
		ProductPurchaseModal.Backdrop.Active = true
		SheetContainer.Position              = UDim2.new(0.5, 0, 0.5, 25)
		SheetContainer.GroupTransparency     = 1
		BuyButton.BackgroundTransparency     = 0.5
		BuyButton.Text.TextTransparency      = 0.5
		BuyButton.Gradient.Offset            = Vector2.new(0, 0)
		ProductPurchaseModal.Parent          = FoundationOverlay

		TweenService:Create(ProductPurchaseModal.Backdrop,
			TweenInfo.new(0.1, Enum.EasingStyle.Quad),
			{ BackgroundTransparency = 0.25 }):Play()

		tweenOpen:Play()
		tweenOpen.Completed:Once(function()
			isAnim = false
			for _, c in pairs(SheetContainer:GetChildren()) do c.Parent = SheetContainer_0 end
			SheetContainer.Parent   = playerGui.PC
			SheetContainer_0.Parent = ProductPurchaseModal

			BuyButton.BackgroundTransparency = 0
			BuyButton.Text.TextTransparency  = 0
			BuyButton.Gradient.Enabled       = true
			tweenGradient:Play()
			tweenGradient.Completed:Once(function()
				canBuy           = true
				BuyButton.Active = true
				pcall(function() BuyButton.Gradient:Destroy() end)
			end)
		end)
	end

	ProductPurchaseModal.Backdrop.Activated:Connect(closeModal)
	CloseAffordance.Activated:Connect(closeModal)

	local function affordanceHover(aff, entering)
		aff.BackgroundTransparency = entering and 0.92 or 0
		aff.BackgroundColor3       = entering
			and Color3.fromRGB(255, 100, 100)
			or  Color3.fromRGB(163, 162, 165)
	end

	CloseAffordance.MouseEnter:Connect(function() affordanceHover(CloseAffordance, true)  end)
	CloseAffordance.MouseLeave:Connect(function() affordanceHover(CloseAffordance, false) end)
	CloseAffordance.MouseButton1Down:Connect(function()
		CloseAffordance.BackgroundTransparency = 0.88
		CloseAffordance.BackgroundColor3       = Color3.fromRGB(255, 100, 100)
	end)

	BuyButton.MouseEnter:Connect(function()
		if canBuy then BuyButton.BackgroundColor3 = Color3.fromRGB(63, 104, 254) end
	end)
	BuyButton.MouseLeave:Connect(function()
		if canBuy then BuyButton.BackgroundColor3 = Color3.fromRGB(51, 95, 255) end
	end)
	BuyButton.MouseButton1Down:Connect(function()
		if canBuy then BuyButton.BackgroundColor3 = Color3.fromRGB(69, 109, 254) end
	end)
	BuyButton.MouseButton1Up:Connect(function()
		if canBuy then BuyButton.BackgroundColor3 = Color3.fromRGB(63, 104, 254) end
	end)
	BuyButton.Activated:Connect(function()
		if not canBuy then return end
		canBuy = false
		BuyButton.Active                     = false
		CloseAffordance.Active               = false
		ProductPurchaseModal.Backdrop.Active = false

		TweenService:Create(BuyButton,
			TweenInfo.new(0.25, Enum.EasingStyle.Quad),
			{ BackgroundColor3 = Color3.fromRGB(51, 95, 255), BackgroundTransparency = 0.5 }):Play()
		TweenService:Create(BuyButton.Text,
			TweenInfo.new(0.25, Enum.EasingStyle.Quad),
			{ TextTransparency = 0.5 }):Play()

		task.wait(0.65)

		Config.Robux = math.max(0, Config.Robux - (itemPrice or 0))
		saveConfig()
		if _G.__GAG_RobuxDisplay then
			_G.__GAG_RobuxDisplay.Text = formatCommas(Config.Robux)
		end

		ProductPurchaseModal.Parent = nil
		showSuccessPrompt()

		if type(onPurchased) == "function" then
			task.spawn(onPurchased)
		end
	end)

	local function destroySuccess()
		finalizeSuccess()
		ProductPurchasePrompt.Backdrop.Active = false
		ProductPurchasePrompt:Destroy()
		pcall(function() ProductPurchaseModal:Destroy() end)
	end

	ProductPurchasePrompt.Backdrop.Activated:Connect(destroySuccess)
	CloseAffordance2.Activated:Connect(function()
		CloseAffordance2.Active = false
		destroySuccess()
	end)

	CloseAffordance2.MouseEnter:Connect(function() affordanceHover(CloseAffordance2, true)  end)
	CloseAffordance2.MouseLeave:Connect(function() affordanceHover(CloseAffordance2, false) end)
	CloseAffordance2.MouseButton1Down:Connect(function()
		CloseAffordance2.BackgroundTransparency = 0.88
		CloseAffordance2.BackgroundColor3       = Color3.fromRGB(255, 100, 100)
	end)

	ConfirmButton.MouseEnter:Connect(function() ConfirmButton.BackgroundColor3 = Color3.fromRGB(63, 104, 254) end)
	ConfirmButton.MouseLeave:Connect(function() ConfirmButton.BackgroundColor3 = Color3.fromRGB(51, 95, 255) end)
	ConfirmButton.MouseButton1Down:Connect(function() ConfirmButton.BackgroundColor3 = Color3.fromRGB(69, 109, 254) end)
	ConfirmButton.MouseButton1Up:Connect(function() ConfirmButton.BackgroundColor3 = Color3.fromRGB(63, 104, 254) end)
	ConfirmButton.Activated:Connect(function()
		ConfirmButton.Active = false
		destroySuccess()
	end)
end

local function showBulkPrompts(details, count, onAllDone)
	count = math.max(1, math.floor(count or 1))
	local remaining = count

	local function doNext()
		if remaining <= 0 then
			if type(onAllDone) == "function" then onAllDone() end
			return
		end
		local current = remaining
		remaining = remaining - 1
		local d = {}
		for k, v in pairs(details) do d[k] = v end
		d.name      = string.format("%s [%d/%d]", details.name or "Item", count - current + 1, count)
		d.cleanName = details.cleanName or details.name or "Item"
		showPrompt(d, doNext)
	end

	doNext()
end

local realPromptPurchase         = DevProductController.PromptPurchase
local realPromptGamepass         = DevProductController.PromptGamepassPurchase
local realPromptPurchaseInternal = DevProductController.PromptPurchaseInternal

local lastPromptKey, lastPromptAt = nil, 0

local function firePrompt(productString)
	local key = tostring(productString)
	local now = os.clock()
	if key == lastPromptKey and (now - lastPromptAt) < 0.4 then return end
	lastPromptKey, lastPromptAt = key, now
	task.spawn(function()
		local ok, err = pcall(function()
			showPrompt(resolveProduct(key))
		end)
		if not ok then warn("[FakePrompt] showPrompt failed:", err) end
	end)
end

local function fireGamepassPrompt(key)
	local tag = "GP:" .. tostring(key)
	local now = os.clock()
	if tag == lastPromptKey and (now - lastPromptAt) < 0.4 then return end
	lastPromptKey, lastPromptAt = tag, now
	task.spawn(function()
		local ok, err = pcall(function()
			showPrompt(resolveGamepass(key))
		end)
		if not ok then warn("[FakePrompt] gamepass prompt failed:", err) end
	end)
end

DevProductController.PromptPurchase = function(_, productString, ...)
	firePrompt(productString)
end

if realPromptGamepass then
	DevProductController.PromptGamepassPurchase = function(_, key, ...)
		fireGamepassPrompt(key)
	end
end

if Config.HookAllShops and type(realPromptPurchaseInternal) == "function" then
	DevProductController.PromptPurchaseInternal = function(_, productString, ...)
		firePrompt(productString)
		return true, "Prompted Robux"
	end
end

local existing = playerGui:FindFirstChild("GAGFakePanel")
if existing then existing:Destroy() end

local screenGui = create("ScreenGui", {
	Name           = "GAGFakePanel",
	IgnoreGuiInset = true,
	ResetOnSpawn   = false,
	DisplayOrder   = 100,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent         = playerGui,
})

local PANEL_W, PANEL_H = 196, 144

local panel = create("Frame", {
	Size             = UDim2.new(0, PANEL_W, 0, PANEL_H),
	Position         = UDim2.new(Config.PanelPosX, Config.PanelPosOffsetX, Config.PanelPosY, Config.PanelPosOffsetY),
	AnchorPoint      = Vector2.new(1, 1),
	BackgroundColor3 = BG_COLOR,
	Active           = true,
	Parent           = screenGui,
}, {
	makeCorner(8),
	makeStroke(BORDER_COLOR, 1),
	create("UIPadding", {
		PaddingTop    = UDim.new(0, 8),
		PaddingBottom = UDim.new(0, 8),
		PaddingLeft   = UDim.new(0, 10),
		PaddingRight  = UDim.new(0, 10),
	}),
	create("UIListLayout", {
		FillDirection       = Enum.FillDirection.Vertical,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment   = Enum.VerticalAlignment.Top,
		SortOrder           = Enum.SortOrder.LayoutOrder,
		Padding             = UDim.new(0, 6),
	}),
})

-- Title: Mikka Hub (pink accent)
create("TextLabel", {
	Size                   = UDim2.new(1, 0, 0, 16),
	LayoutOrder            = 1,
	BackgroundTransparency = 1,
	Text                   = "Mikka Hub",
	TextColor3             = TEXT_PINK,
	Font                   = Enum.Font.GothamBold,
	TextSize               = 12,
	TextXAlignment         = Enum.TextXAlignment.Center,
	Parent                 = panel,
})

local buttonsContainer = create("Frame", {
	Size                   = UDim2.new(1, 0, 0, 62),
	LayoutOrder            = 2,
	BackgroundTransparency = 1,
	Parent                 = panel,
}, {
	create("UIListLayout", {
		FillDirection       = Enum.FillDirection.Vertical,
		Padding             = UDim.new(0, 6),
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		SortOrder           = Enum.SortOrder.LayoutOrder,
	}),
})

local row1 = create("Frame", {
	Size                   = UDim2.new(1, 0, 0, 28),
	LayoutOrder            = 1,
	BackgroundTransparency = 1,
	Parent                 = buttonsContainer,
}, {
	create("UIListLayout", {
		FillDirection       = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment   = Enum.VerticalAlignment.Center,
		SortOrder           = Enum.SortOrder.LayoutOrder,
		Padding             = UDim.new(0, 6),
	}),
})

local row2 = create("Frame", {
	Size                   = UDim2.new(1, 0, 0, 28),
	LayoutOrder            = 2,
	BackgroundTransparency = 1,
	Parent                 = buttonsContainer,
}, {
	create("UIListLayout", {
		FillDirection       = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment   = Enum.VerticalAlignment.Center,
		SortOrder           = Enum.SortOrder.LayoutOrder,
		Padding             = UDim.new(0, 6),
	}),
})

local BTN_W = 85

local openBtn = create("TextButton", {
	Size             = UDim2.new(0, BTN_W, 0, 28),
	LayoutOrder      = 1,
	BackgroundColor3 = BTN_LIGHT,
	Text             = "Open Shop",
	TextColor3       = TEXT_WHITE,
	Font             = Enum.Font.GothamBold,
	TextSize         = 12,
	AutoButtonColor  = false,
	Parent           = row1,
}, { makeCorner(4) })

local shecklesBtn = create("TextButton", {
	Size             = UDim2.new(0, BTN_W, 0, 28),
	LayoutOrder      = 2,
	BackgroundColor3 = BTN_DARK,
	Text             = "Sheckles",
	TextColor3       = TEXT_WHITE,
	Font             = Enum.Font.GothamBold,
	TextSize         = 12,
	AutoButtonColor  = false,
	Parent           = row1,
}, { makeCorner(4) })

local cfgBtn = create("TextButton", {
	Size             = UDim2.new(0, BTN_W, 0, 28),
	LayoutOrder      = 1,
	BackgroundColor3 = BTN_DARK,
	Text             = "CFG",
	TextColor3       = TEXT_WHITE,
	Font             = Enum.Font.GothamBold,
	TextSize         = 12,
	AutoButtonColor  = false,
	Parent           = row2,
}, { makeCorner(4) })

local keybindBtn = create("TextButton", {
	Size             = UDim2.new(0, BTN_W, 0, 28),
	LayoutOrder      = 2,
	BackgroundColor3 = BTN_DARK,
	Text             = "Keybind",
	TextColor3       = TEXT_WHITE,
	Font             = Enum.Font.GothamBold,
	TextSize         = 12,
	AutoButtonColor  = false,
	Parent           = row2,
}, { makeCorner(4) })

-- Discord label removed

local robuxBalanceDisplay
do
	local balRow = create("Frame", {
		Size                   = UDim2.new(1, 0, 0, 16),
		LayoutOrder            = 4,
		BackgroundTransparency = 1,
		Parent                 = panel,
	}, {
		create("UIListLayout", {
			FillDirection       = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment   = Enum.VerticalAlignment.Center,
			SortOrder           = Enum.SortOrder.LayoutOrder,
			Padding             = UDim.new(0, 4),
		}),
		create("ImageLabel", {
			Size                   = UDim2.new(0, 12, 0, 12),
			LayoutOrder            = 1,
			BackgroundTransparency = 1,
			Image                  = ROBUX_ICON_ID,
			ImageColor3            = TEXT_PINK,
			ScaleType              = Enum.ScaleType.Fit,
		}),
	})
	robuxBalanceDisplay = create("TextLabel", {
		Size                   = UDim2.new(0, 0, 1, 0),
		LayoutOrder            = 2,
		AutomaticSize          = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Text                   = formatCommas(Config.Robux),
		TextColor3             = TEXT_PINK,
		Font                   = Enum.Font.GothamMedium,
		TextSize               = 11,
		Parent                 = balRow,
	})
	_G.__GAG_RobuxDisplay = robuxBalanceDisplay
end

openBtn.MouseButton1Click:Connect(function()
	local opened = pcall(function() GuiController:Open("RobuxShop", nil, { "HUD" }) end)
	if not opened then
		showPrompt({ name = "Sheckles", price = Config.Robux, image = Config.DefaultImage })
	end
end)

openBtn.MouseEnter:Connect(function() TweenService:Create(openBtn, TweenInfo.new(0.12), { BackgroundColor3 = BTN_HOVER }):Play() end)
openBtn.MouseLeave:Connect(function() TweenService:Create(openBtn, TweenInfo.new(0.12), { BackgroundColor3 = BTN_LIGHT }):Play() end)
openBtn.MouseButton1Down:Connect(function() TweenService:Create(openBtn, TweenInfo.new(0.06), { BackgroundColor3 = Color3.fromRGB(150, 30, 70) }):Play() end)
openBtn.MouseButton1Up:Connect(function()   TweenService:Create(openBtn, TweenInfo.new(0.10), { BackgroundColor3 = BTN_HOVER }):Play() end)

cfgBtn.MouseEnter:Connect(function() TweenService:Create(cfgBtn, TweenInfo.new(0.12), { BackgroundColor3 = BTN_HOVER }):Play() end)
cfgBtn.MouseLeave:Connect(function() TweenService:Create(cfgBtn, TweenInfo.new(0.12), { BackgroundColor3 = BTN_DARK  }):Play() end)

keybindBtn.MouseEnter:Connect(function() TweenService:Create(keybindBtn, TweenInfo.new(0.12), { BackgroundColor3 = BTN_HOVER }):Play() end)
keybindBtn.MouseLeave:Connect(function() TweenService:Create(keybindBtn, TweenInfo.new(0.12), { BackgroundColor3 = BTN_DARK  }):Play() end)

local cfgPopover = create("Frame", {
	Size             = UDim2.new(0, PANEL_W, 0, 0),
	AutomaticSize    = Enum.AutomaticSize.Y,
	BackgroundColor3 = BG_COLOR,
	BorderSizePixel  = 0,
	Visible          = false,
	ZIndex           = 200,
	Parent           = screenGui,
}, {
	makeCorner(8),
	makeStroke(BORDER_COLOR, 1),
	create("UIPadding", {
		PaddingTop    = UDim.new(0, 10),
		PaddingBottom = UDim.new(0, 10),
		PaddingLeft   = UDim.new(0, 12),
		PaddingRight  = UDim.new(0, 12),
	}),
	create("UIListLayout", {
		FillDirection       = Enum.FillDirection.Vertical,
		Padding             = UDim.new(0, 8),
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
	}),
})

create("Frame", {
	Size                   = UDim2.new(1, 0, 0, 18),
	BackgroundTransparency = 1,
	ZIndex                 = 200,
	Parent                 = cfgPopover,
}, {
	create("UIListLayout", {
		FillDirection     = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding           = UDim.new(0, 4),
	}),
	create("ImageLabel", {
		Size                   = UDim2.new(0, 14, 0, 14),
		BackgroundTransparency = 1,
		Image                  = ROBUX_ICON_ID,
		ImageColor3            = TEXT_PINK,
		ScaleType              = Enum.ScaleType.Fit,
		ZIndex                 = 200,
	}),
	create("TextLabel", {
		Size                   = UDim2.new(0, 0, 0, 18),
		AutomaticSize          = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Text                   = "Set Robux Balance",
		TextColor3             = TEXT_DARK,
		Font                   = Enum.Font.GothamBold,
		TextSize               = 12,
		ZIndex                 = 200,
	}),
})

local robuxInput = create("TextBox", {
	Size              = UDim2.new(1, 0, 0, 32),
	BackgroundColor3  = X_HOVER_BG,
	PlaceholderText   = "Current: " .. formatCommas(Config.Robux),
	Text              = "",
	TextColor3        = TEXT_DARK,
	PlaceholderColor3 = Color3.fromRGB(180, 120, 140),
	Font              = Enum.Font.GothamMedium,
	TextSize          = 13,
	ClearTextOnFocus  = true,
	ZIndex            = 200,
	Parent            = cfgPopover,
}, { makeCorner(5), makeStroke(BORDER_COLOR, 1) })

local keybindPopover = create("Frame", {
	Size             = UDim2.new(0, PANEL_W, 0, 0),
	AutomaticSize    = Enum.AutomaticSize.Y,
	BackgroundColor3 = BG_COLOR,
	BorderSizePixel  = 0,
	Visible          = false,
	ZIndex           = 200,
	Parent           = screenGui,
}, {
	makeCorner(8),
	makeStroke(BORDER_COLOR, 1),
	create("UIPadding", {
		PaddingTop    = UDim.new(0, 10),
		PaddingBottom = UDim.new(0, 10),
		PaddingLeft   = UDim.new(0, 12),
		PaddingRight  = UDim.new(0, 12),
	}),
	create("UIListLayout", {
		FillDirection       = Enum.FillDirection.Vertical,
		Padding             = UDim.new(0, 8),
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
	}),
})

create("TextLabel", {
	Size                   = UDim2.new(1, 0, 0, 18),
	BackgroundTransparency = 1,
	Text                   = "Toggle Keybind",
	TextColor3             = TEXT_DARK,
	Font                   = Enum.Font.GothamBold,
	TextSize               = 12,
	TextXAlignment         = Enum.TextXAlignment.Center,
	ZIndex                 = 200,
	Parent                 = keybindPopover,
})

local keyHint = create("TextLabel", {
	Size                   = UDim2.new(1, 0, 0, 20),
	BackgroundTransparency = 1,
	Text                   = "Current: " .. Config.PanelKey,
	TextColor3             = TEXT_PINK,
	Font                   = Enum.Font.GothamMedium,
	TextSize               = 13,
	TextXAlignment         = Enum.TextXAlignment.Center,
	ZIndex                 = 200,
	Parent                 = keybindPopover,
})

local listening = false
local listenButton = create("TextButton", {
	Size             = UDim2.new(1, 0, 0, 30),
	BackgroundColor3 = BTN_LIGHT,
	Text             = "Press to set new key",
	TextColor3       = TEXT_WHITE,
	Font             = Enum.Font.GothamBold,
	TextSize         = 12,
	AutoButtonColor  = false,
	ZIndex           = 200,
	Parent           = keybindPopover,
}, { makeCorner(5) })

listenButton.MouseEnter:Connect(function() listenButton.BackgroundColor3 = BTN_HOVER end)
listenButton.MouseLeave:Connect(function() 
	if not listening then listenButton.BackgroundColor3 = BTN_LIGHT end
end)

listenButton.MouseButton1Click:Connect(function()
	listening = true
	listenButton.Text = "Press any key..."
	listenButton.BackgroundColor3 = Color3.fromRGB(150, 30, 70)
	
	local conn
	conn = UserInputService.InputBegan:Connect(function(input, gpe)
		if gpe then return end
		if input.UserInputType == Enum.UserInputType.Keyboard then
			local newKey = input.KeyCode.Name
			if newKey and newKey ~= "" then
				Config.PanelKey = newKey
				saveConfig()
				keyHint.Text = "Current: " .. newKey
				listening = false
				listenButton.Text = "Press to set new key"
				listenButton.BackgroundColor3 = BTN_LIGHT
				conn:Disconnect()
			end
		end
	end)
	
	task.delay(10, function()
		if listening then
			listening = false
			listenButton.Text = "Press to set new key"
			listenButton.BackgroundColor3 = BTN_LIGHT
			conn:Disconnect()
		end
	end)
end)

local sframe = create("Frame", {
	Name             = "GAGSheckles",
	Size             = UDim2.new(0, PANEL_W, 0, 0),
	AutomaticSize    = Enum.AutomaticSize.Y,
	BackgroundColor3 = BG_COLOR,
	BorderSizePixel  = 0,
	Visible          = false,
	ZIndex           = 200,
	Parent           = screenGui,
}, {
	makeCorner(8),
	makeStroke(BORDER_COLOR, 1),
	create("UIPadding", {
		PaddingTop    = UDim.new(0, 10),
		PaddingBottom = UDim.new(0, 10),
		PaddingLeft   = UDim.new(0, 12),
		PaddingRight  = UDim.new(0, 12),
	}),
	create("UIListLayout", {
		FillDirection       = Enum.FillDirection.Vertical,
		Padding             = UDim.new(0, 8),
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
	}),
})

create("Frame", {
	Size                   = UDim2.new(1, 0, 0, 18),
	BackgroundTransparency = 1,
	ZIndex                 = 200,
	Parent                 = sframe,
}, {
	create("UIListLayout", {
		FillDirection     = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding           = UDim.new(0, 4),
	}),
	create("ImageLabel", {
		Size                   = UDim2.new(0, 14, 0, 14),
		BackgroundTransparency = 1,
		Image                  = ROBUX_ICON_ID,
		ImageColor3            = TEXT_PINK,
		ScaleType              = Enum.ScaleType.Fit,
		ZIndex                 = 200,
	}),
	create("TextLabel", {
		Size                   = UDim2.new(0, 0, 0, 18),
		AutomaticSize          = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Text                   = "Set Sheckles Balance",
		TextColor3             = TEXT_DARK,
		Font                   = Enum.Font.GothamBold,
		TextSize               = 12,
		ZIndex                 = 200,
	}),
})

local sBox = create("TextBox", {
	Size              = UDim2.new(1, 0, 0, 32),
	BackgroundColor3  = X_HOVER_BG,
	PlaceholderText   = "e.g. 1000000000",
	Text              = "",
	TextColor3        = TEXT_DARK,
	PlaceholderColor3 = Color3.fromRGB(180, 120, 140),
	Font              = Enum.Font.GothamMedium,
	TextSize          = 13,
	ClearTextOnFocus  = false,
	ZIndex            = 200,
	Parent            = sframe,
}, { makeCorner(5), makeStroke(BORDER_COLOR, 1) })

local sBtn = create("TextButton", {
	Size             = UDim2.new(1, 0, 0, 30),
	BackgroundColor3 = BTN_LIGHT,
	Text             = "Generate",
	TextColor3       = TEXT_WHITE,
	Font             = Enum.Font.GothamBold,
	TextSize         = 13,
	AutoButtonColor  = false,
	ZIndex           = 200,
	Parent           = sframe,
}, { makeCorner(5) })
sBtn.MouseEnter:Connect(function() sBtn.BackgroundColor3 = BTN_HOVER end)
sBtn.MouseLeave:Connect(function() sBtn.BackgroundColor3 = BTN_LIGHT  end)

local sStatus = create("TextLabel", {
	Size                   = UDim2.new(1, 0, 0, 14),
	BackgroundTransparency = 1,
	Text                   = "",
	TextColor3             = TEXT_PINK,
	Font                   = Enum.Font.GothamMedium,
	TextSize               = 11,
	TextXAlignment         = Enum.TextXAlignment.Center,
	ZIndex                 = 200,
	Parent                 = sframe,
})

local function setStatus(msg, ok)
	sStatus.Text = msg
	sStatus.TextColor3 = ok and Color3.fromRGB(80, 220, 120) or Color3.fromRGB(255, 80, 80)
	task.delay(3, function() if sStatus.Text == msg then sStatus.Text = "" end end)
end

local function setSheckles(amount)
	local success = false
	local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
	if leaderstats then
		local s = leaderstats:FindFirstChild("Sheckles")
			or leaderstats:FindFirstChild("Money")
			or leaderstats:FindFirstChild("Cash")
		if s then
			s.Value = tonumber(amount) or 0
			success = true
		end
	end
	if not success then
		for _, v in ipairs(LocalPlayer:GetDescendants()) do
			if (v:IsA("IntValue") or v:IsA("NumberValue")) and
				(string.find(v.Name:lower(), "sheckle") or string.find(v.Name:lower(), "money")) then
				v.Value = tonumber(amount) or 0
				success = true
				break
			end
		end
	end
	if success then
		setStatus("Set to " .. tostring(amount), true)
	else
		setStatus("Could not find Sheckles value", false)
	end
end

sBtn.MouseButton1Click:Connect(function()
	local amount = sBox.Text
	if amount and tonumber(amount) then
		setSheckles(amount)
	else
		setStatus("Enter a valid number", false)
	end
end)

local function repositionAllPopovers()
	task.defer(function()
		local ap = panel.AbsolutePosition
		local as = panel.AbsoluteSize
		if not ap or not as then return end

		local popups = {}
		if cfgPopover.Visible then popups[#popups+1] = cfgPopover end
		if sframe.Visible then popups[#popups+1] = sframe end
		if keybindPopover.Visible then popups[#popups+1] = keybindPopover end

		local currentY = ap.Y
		local panelRightX = ap.X + as.X

		for i, popup in ipairs(popups) do
			local size = popup.AbsoluteSize
			if size and size.Y > 0 then
				local popupHeight = size.Y
				local popupWidth = size.X
				local x = panelRightX - popupWidth
				local y = currentY - popupHeight
				popup.Position = UDim2.new(0, x, 0, y)
				currentY = y
			end
		end
	end)
end

cfgPopover:GetPropertyChangedSignal("Visible"):Connect(repositionAllPopovers)
sframe:GetPropertyChangedSignal("Visible"):Connect(repositionAllPopovers)
keybindPopover:GetPropertyChangedSignal("Visible"):Connect(repositionAllPopovers)
panel:GetPropertyChangedSignal("Position"):Connect(repositionAllPopovers)
panel:GetPropertyChangedSignal("AbsoluteSize"):Connect(repositionAllPopovers)

local isCfgOpen = false
cfgBtn.MouseButton1Click:Connect(function()
	isCfgOpen = not isCfgOpen
	cfgPopover.Visible = isCfgOpen
	if isCfgOpen then
		robuxInput.PlaceholderText = "Current: " .. formatCommas(Config.Robux)
		repositionAllPopovers()
	end
end)

robuxInput.FocusLost:Connect(function()
	local num = tonumber(robuxInput.Text)
	if num then
		Config.Robux = math.max(0, math.floor(num))
		saveConfig()
		robuxInput.PlaceholderText = "Current: " .. formatCommas(Config.Robux)
		if robuxBalanceDisplay then robuxBalanceDisplay.Text = formatCommas(Config.Robux) end
	end
	robuxInput.Text = ""
end)

local isKeybindOpen = false
keybindBtn.MouseButton1Click:Connect(function()
	isKeybindOpen = not isKeybindOpen
	keybindPopover.Visible = isKeybindOpen
	if isKeybindOpen then
		listening = false
		listenButton.Text = "Press to set new key"
		listenButton.BackgroundColor3 = BTN_LIGHT
		keyHint.Text = "Current: " .. Config.PanelKey
		repositionAllPopovers()
	end
end)

shecklesBtn.MouseButton1Click:Connect(function()
	sframe.Visible = not sframe.Visible
	if sframe.Visible then
		repositionAllPopovers()
	end
end)

local cfgDragging, cfgDragInput, cfgDragStart, cfgStartPos
cfgPopover.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
		cfgDragging  = true
		cfgDragStart = input.Position
		cfgStartPos  = cfgPopover.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then cfgDragging = false end
		end)
	end
end)
cfgPopover.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch then
		cfgDragInput = input
	end
end)

local dragging, dragInput, dragStart, startPos
panel.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
		dragging  = true
		dragStart = input.Position
		startPos  = panel.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
				Config.PanelPosX       = panel.Position.X.Scale
				Config.PanelPosOffsetX = panel.Position.X.Offset
				Config.PanelPosY       = panel.Position.Y.Scale
				Config.PanelPosOffsetY = panel.Position.Y.Offset
				saveConfig()
				repositionAllPopovers()
			end
		end)
	end
end)
panel.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if input == cfgDragInput and cfgDragging then
		local d = input.Position - cfgDragStart
		cfgPopover.Position = UDim2.new(
			cfgStartPos.X.Scale, cfgStartPos.X.Offset + d.X,
			cfgStartPos.Y.Scale, cfgStartPos.Y.Offset + d.Y)
		repositionAllPopovers()
	end
	if input == dragInput and dragging then
		local d = input.Position - dragStart
		panel.Position = UDim2.new(
			startPos.X.Scale, startPos.X.Offset + d.X,
			startPos.Y.Scale, startPos.Y.Offset + d.Y)
		repositionAllPopovers()
	end
end)

UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
	if input.KeyCode.Name == Config.PanelKey then
		panel.Visible = not panel.Visible
	end
end)
