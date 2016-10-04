local _, ns = ...
local cfg = ns.Config

--MWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWM--
--|\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\|--
--WMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMW--

local function CreateSkin(button, type)

	if (not button) or (button and button.Shadow) then return; end
	local isBuff = type == "HELPFUL"
	local isDebuff = type == "HARMFUL"
	local isTemp = type == "TEMPENCH"

	-- All
	local name = button:GetName()
	local icon = _G[name..'Icon']
	local count = button.count
	local duration = button.duration
	--Debuff & TempEnch
	local border = _G[name..'Border']
	--Debuff
	--local symbol = button.symbol --colorblind

	if (isDebuff) then
		button:SetSize(cfg.DebuffSize, cfg.DebuffSize)
	else
		button:SetSize(cfg.BuffSize, cfg.BuffSize)
	end

	icon:SetTexCoord(.05, .95, .05, .95)

	duration:ClearAllPoints()
	duration:SetPoint('BOTTOM', button, 'BOTTOM', 0, -2)
	duration:SetFont(cfg.Font, cfg.FontSize, 'OUTLINE')
	duration:SetShadowOffset(0, 0)
	duration:SetDrawLayer('OVERLAY')

	count:ClearAllPoints()
	count:SetPoint('TOPRIGHT', button)
	count:SetFont(cfg.Font, cfg.FontSize + 2, 'OUTLINE')
	count:SetShadowOffset(0, 0)
	count:SetDrawLayer('OVERLAY')

	if border then -- Debuffs/temps
		border:SetTexture(cfg.DebuffTexture)
		border:SetPoint('TOPRIGHT', button, 1, 1)
		border:SetPoint('BOTTOMLEFT', button, -1, -1)
		border:SetTexCoord(0, 1, 0, 1)
	else 			-- buffs
		button.texture = button:CreateTexture(nil, 'ARTWORK')
		button.texture:SetParent(button)
		button.texture:SetTexture(cfg.NormalTexture)
		button.texture:SetPoint('TOPRIGHT', button, 1, 1)
		button.texture:SetPoint('BOTTOMLEFT', button, -1, -1)
		button.texture:SetVertexColor(unpack(cfg.BorderColor))
	end

	button.Shadow = button:CreateTexture(nil, 'BACKGROUND')
	button.Shadow:SetTexture(cfg.ShadowTexture)
	button.Shadow:SetPoint('TOPRIGHT', button.texture or border, 3.35, 3.35)
	button.Shadow:SetPoint('BOTTOMLEFT', button.texture or border, -3.35, -3.35)
	button.Shadow:SetVertexColor(0, 0, 0, 1)
end

local function SkinAuraButton(name, index, type)
	local button = _G[name..index]
	CreateSkin(button, type)
end

local function SkinTempEnchant()
	for i = 1, NUM_TEMP_ENCHANT_FRAMES do
		local button = _G['TempEnchant'..i]
		SkinAuraButton('TempEnchant', i, "TEMPENCH")
	end
end

local function UpdateAllBuffAnchors()
	local aboveBuff, previousBuff, index;
	local numBuffs = 0;
	local numRows = 0;
	local slack = BuffFrame.numEnchants;

	TempEnchant1:ClearAllPoints()
	if slack > 0 then
		aboveBuff = TempEnchant1
	end
	TempEnchant1:SetPoint('TOPRIGHT', Minimap, 'TOPLEFT', -15, 0)

	if (BuffFrame.numEnchants > 0) and (not UnitHasVehicleUI("player")) then
		previousBuff = _G['TempEnchant'..BuffFrame.numEnchants]
	end

	for i = 1, BUFF_ACTUAL_DISPLAY do
		local buff = _G['BuffButton'..i]

		numBuffs = numBuffs + 1;
		index = numBuffs + slack;

		buff:ClearAllPoints()

		-- First buff, not temp enchants
		if index == 1 then
			buff:SetPoint("TOPRIGHT", TempEnchant1)
			aboveBuff = buff
		-- First buff on new row
		elseif (index % cfg.AurasPerRow == 1) then
			buff:SetPoint("TOPRIGHT", aboveBuff, "BOTTOMRIGHT", 0, -cfg.Padding_Y)
			aboveBuff = buff
		else
			buff:SetPoint('TOPRIGHT', previousBuff, 'TOPLEFT', -cfg.Padding_X, 0)
		end
		previousBuff = buff
	end
end

local function UpdateAllDebuffAnchors(buttonName, index)
	local numBuffs = BUFF_ACTUAL_DISPLAY + BuffFrame.numEnchants;
	
	local rows = ceil(numBuffs/cfg.AurasPerRow);

	local buff = _G[buttonName..index];
	buff:ClearAllPoints()

	-- Position debuffs
	if (index == 1) then
		-- First button
		local offsetY
		if ( rows < 2 ) then
			offsetY = (cfg.Padding_Y + cfg.DebuffSize);
		else
			offsetY = rows * (cfg.Padding_Y + cfg.BuffSize);
		end
		buff:SetPoint("TOPRIGHT", TempEnchant1, "BOTTOMRIGHT", 0, -offsetY);
	elseif ( (index > 1) and ((index % cfg.AurasPerRow) == 1) ) then
		-- New row
		buff:SetPoint("TOP", _G[buttonName..(index-cfg.AurasPerRow)], "BOTTOM", 0, -cfg.Padding_Y);
	else
		-- Else anchor to the one on the right
		buff:SetPoint("TOPRIGHT", _G[buttonName..(index-1)], "TOPLEFT", -cfg.Padding_X, 0);
	end
end

-- Temp Enchant frame
TempEnchant1:ClearAllPoints()
TempEnchant1:SetPoint('TOPRIGHT', Minimap, 'TOPLEFT', -15, 0)
TempEnchant2:ClearAllPoints()
TempEnchant2:SetPoint('TOPRIGHT', TempEnchant1, 'TOPLEFT', -cfg.Padding_X, 0)
TempEnchant3:ClearAllPoints()
TempEnchant3:SetPoint("TOPRIGHT", TempEnchant2, "TOPLEFT", -cfg.Padding_X, 0)

-- Sizing and acnhors
hooksecurefunc('BuffFrame_UpdateAllBuffAnchors', UpdateAllBuffAnchors)
hooksecurefunc("DebuffButton_UpdateAnchors", UpdateAllDebuffAnchors)

BuffFrame:SetScript("OnUpdate", nil)

-- Skinning
SkinTempEnchant()
hooksecurefunc('AuraButton_Update', SkinAuraButton)
