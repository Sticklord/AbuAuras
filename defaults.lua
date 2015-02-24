local _, ns = ...
local Gcfg = AbuGlobal.GlobalConfig

ns.Config = {
	BuffSize = 36,
	DebuffSize = 48,

	Padding_X = 7,
	Padding_Y = 7,

	AurasPerRow = 12,
	FontSize = 14,
	Font = Gcfg.Fonts.Normal,

	BorderColor = Gcfg.Colors.Border,
	DebuffTexture = Gcfg.IconTextures.Debuff,
	NormalTexture = Gcfg.IconTextures.Normal,
	ShadowTexture = Gcfg.IconTextures.Shadow,
}