local _, ns = ...
setmetatable(ns, { __index = ABUADDONS })
local _G = _G

--MWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWM--
--|\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\|--
--WMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMW--

local cfg = ns.Config.Auras
local cfg = ns.Config
local Textures = cfg.IconTextures
local Font = cfg.Fonts.Normal

local DEBUFF_SIZE = cfg.Auras.debuffSize
local BUFF_SIZE = cfg.Auras.buffSize
local PADDING_X, PADDING_Y = 7, 7
local AURAS_PER_ROW = 12

local function SkinAuraIcon(name, index, filter)
	local button = _G[name..index]
	local isDebuff = (filter == "HARMFUL");

	if not button or (button and button.Shadow) then return; end
	-- All
	local icon = _G[name..index..'Icon']
	local count = button.count
	local duration = button.duration
	--Debuff & TempEnch
	local border = _G[name..index..'Border']
	--Debuff
	--local symbol = button.symbol --colorblind

	if isDebuff then
		button:SetSize(DEBUFF_SIZE, DEBUFF_SIZE)
	else
		button:SetSize(BUFF_SIZE, BUFF_SIZE)
	end

	icon:SetTexCoord(.05, .95, .05, .95)

	duration:ClearAllPoints()
	duration:SetPoint('BOTTOM', button, 'BOTTOM', 0, -2)
	duration:SetFont(Font, cfg.Auras.fontSize, 'OUTLINE')
	duration:SetShadowOffset(0, 0)
	duration:SetDrawLayer('OVERLAY')

	count:ClearAllPoints()
	count:SetPoint('TOPRIGHT', button)
	count:SetFont(Font, cfg.Auras.fontSize + 2, 'OUTLINE')
	count:SetShadowOffset(0, 0)
	count:SetDrawLayer('OVERLAY')

	if border then -- Debuffs/temps
		border:SetTexture(Textures['Debuff'])
		border:SetPoint('TOPRIGHT', button, 1, 1)
		border:SetPoint('BOTTOMLEFT', button, -1, -1)
		border:SetTexCoord(0, 1, 0, 1)
	else 			-- buffs
		button.texture = button:CreateTexture(nil, 'ARTWORK')
		button.texture:SetParent(button)
		button.texture:SetTexture(Textures['Normal'])
		button.texture:SetPoint('TOPRIGHT', button, 1, 1)
		button.texture:SetPoint('BOTTOMLEFT', button, -1, -1)
		button.texture:SetVertexColor(unpack(cfg.Colors.Border))
	end

	button.Shadow = button:CreateTexture(nil, 'BACKGROUND')
	button.Shadow:SetTexture(Textures['Shadow'])
	button.Shadow:SetPoint('TOPRIGHT', button.texture or border, 3.35, 3.35)
	button.Shadow:SetPoint('BOTTOMLEFT', button.texture or border, -3.35, -3.35)
	button.Shadow:SetVertexColor(0, 0, 0, 1)
end

local function BuffButton1_UpdateAnchor()
	if BuffButton1 and BuffButton1:IsShown() then
		BuffButton1:ClearAllPoints()
		if (BuffFrame.numEnchants > 0) and (not UnitHasVehicleUI("player")) then
			BuffButton1:SetPoint('TOPRIGHT', _G['TempEnchant'..BuffFrame.numEnchants], 'TOPLEFT', -PADDING_X, 0)
			return;
		else
			BuffButton1:SetPoint("TOPRIGHT", TempEnchant1)
			return;
		end
	end
end

local function SkinTempEnchant()
	for i = 1, NUM_TEMP_ENCHANT_FRAMES do
		local button = _G['TempEnchant'..i]
		SkinAuraIcon('TempEnchant', i)

		button:SetScript('OnShow', BuffButton1_UpdateAnchor)
		button:SetScript('OnHide', BuffButton1_UpdateAnchor)
	end
end

local function UpdateAllBuffAnchors()
	local buff, aboveBuff, previousBuff, index
	local numBuffs = 0;
	local slack = BuffFrame.numEnchants 

	for i = 1, BUFF_ACTUAL_DISPLAY do
		local buff = _G['BuffButton'..i]

		if not buff.consolidated then
			numBuffs = numBuffs + 1;
			index = numBuffs + slack;

			buff:ClearAllPoints()

			-- First buff
			if numBuffs == 1 then
				BuffButton1_UpdateAnchor()
			-- New Row
			elseif (numBuffs > 1) and mod(index, AURAS_PER_ROW) == 1 then
				-- First buff on new row
				if (index == AURAS_PER_ROW + 1) then
					buff:SetPoint("TOP", TempEnchant1, "BOTTOM", 0, -PADDING_Y)
				else
					buff:SetPoint("TOP", aboveBuff, "BOTTOM", 0, -PADDING_Y)
				end
				aboveBuff = buff
			else
				buff:SetPoint('TOPRIGHT', previousBuff, 'TOPLEFT', -PADDING_X, 0)
			end

			previousBuff = buff
		end
	end
end

local function UpdateAllDebuffAnchors(buttonName, index)
	local numBuffs = BUFF_ACTUAL_DISPLAY + BuffFrame.numEnchants;
	if (ShouldShowConsolidatedBuffFrame()) then
		numBuffs = numBuffs + 1; -- consolidated buffs
	end
	
	local rows = ceil(numBuffs/AURAS_PER_ROW);

	local buff = _G[buttonName..index];
	buff:ClearAllPoints()

	-- Position debuffs
	if (index == 1) then
		-- First button
		local offsetY
		if ( rows < 2 ) then
			offsetY = (PADDING_Y + DEBUFF_SIZE);
		else
			offsetY = rows * (PADDING_Y + BUFF_SIZE);
		end
		buff:SetPoint("TOPRIGHT", TempEnchant1, "BOTTOMRIGHT", 0, -offsetY);
	elseif ( (index > 1) and ((index % AURAS_PER_ROW) == 1) ) then
		-- New row
		buff:SetPoint("TOP", _G[buttonName..(index-AURAS_PER_ROW)], "BOTTOM", 0, -PADDING_Y);
	else
		-- Else anchor to the one on the right
		buff:SetPoint("TOPRIGHT", _G[buttonName..(index-1)], "TOPLEFT", -PADDING_X, 0);
	end
end

-- Replace Blizzards duration display
do	local minute, hour, day = 60, 60*60, 60*60*24
	local hourish, dayish = minute*59, hour*23 
	function _G.SecondsToTimeAbbrev(sec)
		if ( sec >= dayish  ) then
			return '|cffffffff%dd|r', floor(sec/day + .5);
		elseif ( sec >= hourish  ) then
			return '|cffffffff%dh|r', floor(sec/hour + .5);
		elseif ( sec >= minute  ) then
			return '|cffffffff%dm|r', floor(sec/minute + .5);
		end
		return '|cffffffff%d|r', sec;
end	end

local function LoadAuras()
	-- Temp Enchant frame
	TempEnchant1:ClearAllPoints()
	TempEnchant1:SetPoint('TOPRIGHT', Minimap, 'TOPLEFT', -15, 0)
	TempEnchant2:ClearAllPoints()
	TempEnchant2:SetPoint('TOPRIGHT', TempEnchant1, 'TOPLEFT', PADDING_X, 0)

	-- Sizing and acnhors
	hooksecurefunc('BuffFrame_UpdateAllBuffAnchors', UpdateAllBuffAnchors)
	hooksecurefunc("DebuffButton_UpdateAnchors", UpdateAllDebuffAnchors)

	BuffFrame:SetScript("OnUpdate", nil)

	-- Skinning
	SkinTempEnchant()
	hooksecurefunc('AuraButton_Update', SkinAuraIcon)

	-- Load Consolidated
	ns.LoadConsolidatedAuras()
end

ns.RegisterEvent("PLAYER_LOGIN", LoadAuras)