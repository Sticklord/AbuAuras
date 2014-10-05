local _, ns = ...
local cfg = ns.Config

local BUTTON_SIZE, BUTTON_PADDING = 28, 4
local PADDING_X, PADDING_Y = 7, 7
local FRAME_WIDTH = (2 * PADDING_X) + NUM_LE_RAID_BUFF_TYPES * (BUTTON_SIZE+BUTTON_PADDING) - BUTTON_PADDING


local ICONS = {
	[1] = "Interface\\Icons\\Spell_Magic_GreaterBlessingofKings", 	-- Stats
	[2] = "Interface\\Icons\\Spell_Holy_WordFortitude", 			-- Stamina
	[3] = "Interface\\Icons\\Ability_Warrior_BattleShout", 			-- Attack Power, fuck off dks
	[4] = "Interface\\Icons\\ability_rogue_disembowel", 			-- Attack Speed
	[5] = "Interface\\Icons\\Spell_Holy_MagicalSentry", 			-- Spell Power
	[6] = "Interface\\Icons\\Spell_Shadow_SpectralSight", 			-- Spell Haste
	[7] = "Interface\\Icons\\ability_warrior_rampage", 				-- Critical Strike
	[8] = "Interface\\Icons\\Spell_Holy_GreaterBlessingofKings" 	-- Mastery
}

local backdrop = {
	bgFile = "Interface\\Buttons\\WHITE8x8",
	tileSize = 16,
	insets = { left = -2, right = -2, top = -2, bottom = -2 },
}

local HOUR, MINUTE = 60*60, 60
local frame

-----------------------------------------------

local function GetTimes(seconds)
	if seconds < MINUTE then
		return floor(seconds), (seconds % 1) + 0.51
	elseif seconds < HOUR then
		local minutes = floor(seconds/MINUTE)
		if 2 > minutes then
			return floor(seconds), (seconds%MINUTE) + 0.51
		end
		local secondsLeftOfMinute = seconds % MINUTE
		if secondsLeftOfMinute > 30 then 
			return floor(seconds), secondsLeftOfMinute - 29
		end
		return floor(seconds), secondsLeftOfMinute + 31
	else
		return floor(seconds), (seconds % HOUR) + 2
	end
end

local function UpdateButtonTime(self, elapsed)
	self.timeleft = self.timeleft - elapsed	
	
	if self.nextupdate > 0 then
		self.nextupdate = self.nextupdate - elapsed
		return
	end

	if(self.timeleft <= 0) then
		self.duration:SetText("")
		self:SetScript("OnUpdate", nil)
		return
	end
	local seconds
	seconds, self.nextupdate = GetTimes(self.timeleft)
	AuraButton_UpdateDuration(self, seconds)
end

local lastState = {}
local function UpdateButtons()

	local buffmask, buffcount = GetRaidBuffInfo();
	if buffmask == nil then return; end
	local mask = 1;
	local hasAll = false, true;
	local status, text, warning = 0;

	for i = 1, NUM_LE_RAID_BUFF_TYPES do
		local spellName, rank, texture, duration, expirationTime, spellId, slot = GetRaidBuffTrayAuraInfo(i);
		local button = frame[i]
		warning = false
		
		if(spellName) then
			button.icon:SetTexture(texture)
			button.icon:SetDesaturated(false)
			button.spellName = spellName
			status = 2

			if (duration == 0 and expirationTime == 0) then
				button.duration:SetText(nil)
				button:SetScript('OnUpdate', nil)
			else
				button.timeleft = expirationTime - GetTime()
				if button.timeleft < 10 then warning = true; end
				text, button.nextupdate = GetTimes(button.timeleft)
				AuraButton_UpdateDuration(button, text)
				button:SetScript('OnUpdate', UpdateButtonTime)
			end
		else
			button.spellName = nil
			button:SetScript('OnUpdate', nil)
			button.duration:SetText(nil)
			if (bit.band(buffmask, mask ) > 0) then -- group can apply it
				button.icon:SetTexture(ICONS[i])
				button.icon:SetDesaturated(true)
				status = 0
				hasAll = false;
			else
				button.icon:SetTexture(cfg.IconTextures['Background'])
				button.icon:SetDesaturated(false)
				status = 1
            end
		end

		mask = bit.lshift(mask, 1); -- TODO fix this ghetto stuff
		-- Each button can only make it slide once each status change
		if lastState[i].status ~= status or (warning and lastState[i].handled == false) then 
			lastState[i].status = status;
			lastState[i].handled = false;

			if frame.slideInfo.stage == "Finished" and (status == 0 or warning) then
				frame:AnimationSlideStart()
				frame:AnimationSlideReturn(5)
				lastState[i].handled = true;
			elseif hasAll and frame.slideInfo.stage == "SlidedOut" and (not warning) then
				frame:AnimationSlideReturn()
				lastState[i].handled = true;
			end

		elseif frame.slideInfo.stage == "SlidedOut" and (not warning) then
			frame:AnimationSlideReturn(2)
		end
	end
end

local function Frame_OnEnter(self, motion)
	frame:AnimationSlideStart()
end

local function Frame_OnLeave(self, motion)
	if frame:IsMouseOver(0, 5, 5, -5) then return; end
	frame:AnimationSlideReturn(2)
end

local function Button_OnEnter(self, motion)
	GameTooltip:Hide()
	GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT", -3, self:GetHeight() + 2)
	GameTooltip:ClearLines()
	
	local id = self:GetID()
	if(self.spellName) then
		GameTooltip:SetUnitConsolidatedBuff("player", id)
	else
		GameTooltip:AddLine(_G[("RAID_BUFF_%d"):format(id)])
	end
	GameTooltip:Show()
	Frame_OnLeave(self, motion)
end

local function Button_OnLeave(self, motion)
	GameTooltip:Hide()
	Frame_OnEnter(self, motion)
end

local function CreateAuraButton(parent, name)
	local b = CreateFrame('Button', name, parent)

	b:SetSize(BUTTON_SIZE, BUTTON_SIZE)
	b:SetScript("OnEnter", Button_OnEnter)
	b:SetScript("OnLeave", Button_OnLeave)

	b.icon = b:CreateTexture(nil, "BACKGROUND")
	b.icon:SetTexCoord(.05, .95, .05, .95)
	b.icon:SetPoint('TOPLEFT', b, 'TOPLEFT', 0, 0)
	b.icon:SetPoint('BOTTOMRIGHT', b, 'BOTTOMRIGHT', 0, 0)
	b.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")

	b.border = b:CreateTexture(nil, 'BORDER')
	b.border:SetParent(b)
	b.border:SetPoint('TOPRIGHT', b, 1, 1)
	b.border:SetPoint('BOTTOMLEFT', b, -1, -1)
	b.border:SetTexture(cfg.IconTextures['Normal'])
	b.border:SetVertexColor(unpack(cfg.Colors['Border']))

	b.duration = b:CreateFontString(nil, 'OVERLAY')
	b.duration:SetPoint('BOTTOMRIGHT', 1, 1)
    b.duration:SetFont(cfg.Fonts.Normal, cfg.Auras.fontSize - 1, "THINOUTLINE")

	return b
end

local function SetupButtons(parent)
	for i = 1, NUM_LE_RAID_BUFF_TYPES do
		parent[i] = CreateAuraButton(parent, 'ConsolidatedButton'..i)
		local b = parent[i]
		b:SetID(i)
		lastState[i] = {status = 0, handled = false}

		if i == 1 then
			b:SetPoint('BOTTOMLEFT', parent, 'BOTTOMLEFT', PADDING_X, PADDING_Y)
		else
			b:SetPoint('BOTTOMLEFT', parent[i-1], 'BOTTOMRIGHT', BUTTON_PADDING, 0)
		end
	end
end

function ns.LoadConsolidatedAuras()
	if frame then return; end

	-- Move the button off screen and anchor to it
	ConsolidatedBuffs:SetPoint('TOPRIGHT', UIParent, -178, 98)

	-- Create The frame
	frame = CreateFrame("Frame", "Abu_ConsolidatedAuras", ConsolidatedBuffs)
	frame:SetPoint('TOPRIGHT', ConsolidatedBuffs)
	frame:SetSize(FRAME_WIDTH, 100)
	frame:SetBackdrop(backdrop)
	frame:EnableMouse(true)
	frame:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
	frame:SetAlpha(1)

	-- For sliding:
	ns.SetupFrameForSliding(frame, .5, 'Y', -40)

	ns.CreateBorder(frame, 13, 4)
	frame:SetBorderColor(unpack(cfg.Colors.Border))
	frame:SetScript("OnEnter", Frame_OnEnter)
	frame:SetScript("OnLeave", Frame_OnLeave)

	-- Create the aura buttons
	SetupButtons(frame)

	frame:RegisterUnitEvent("UNIT_AURA", "player")
	frame:SetScript("OnEvent", function(self, event,...)
		UpdateButtons()
	end)
	UpdateButtons()
end
