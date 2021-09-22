--- @type AddOn
local _, AddOn = ...
local L, C = AddOn.Locale, AddOn.Constants
--- @type LibLogging
local Logging = AddOn:GetLibrary("Logging")
--- @type LibUtil
local Util = AddOn:GetLibrary("Util")
--- @type UI.Native
local UI = AddOn.Require('UI.Native')
---@type UI.Util
local UIUtil = AddOn.Require('UI.Util')
--- @type UI.Native.Widget
local BaseWidget = AddOn.ImportPackage('UI.Native').Widget

local TestChangeLog = [=[
2021.1.0-dev
* A change
* Another change
* More changes

2020.2.123
* Fix regression
* Last cut of this version

2020.2.111
* Fix regression
* Last cut of this version

2020.1.1245
* Fix regression
* Last cut of this version

2020.1.444
* Fix regression
* Last cut of this version

2020.1.0-beta
* Fix regression
* Last cut of this version
]=]

local ParsedChangeLog = Util.Memoize.Memoize(
	function()
		--- @type Models.SemanticVersion
		local SemanticVersion  = AddOn.Package('Models').SemanticVersion
		local VersionDecorator = UIUtil.ColoredDecorator(C.Colors.ItemHeirloom)
		local LineDecorator    = UIUtil.ColoredDecorator(C.Colors.ItemArtifact)

		local parsed = Util.Tables.Map(
				Util.Strings.Split(TestChangeLog, "\n"),
				function(line, ...)
					if SemanticVersion.Is(line) then
						local _, version = SemanticVersion.Create(line)

						return VersionDecorator:decorate(tostring(version))
					end

					return Util.Strings.IsEmpty(line) and " " or LineDecorator:decorate(line)
				end
		)

		return parsed
	end
)

function AddOn:AddAbout()
	if not self.about then
		local lpad = self:Launchpad()
		local index, about = lpad:AddModule(AddOn.name, UIUtil.ColoredDecorator(C.Colors.Cyan):decorate(AddOn.name))
		about.image = UI:New('Texture', about, BaseWidget.ResolveTexture("cleopatra")):Point("TOPLEFT",15,5):Size(512, 320)
		about.authorLabel =  UI:New('Text', about, L.author):Size(150,25):Point("TOPLEFT", about.image, "BOTTOMLEFT"):Shadow():Top()
		about.authorText =  UI:New('Text', about, AddOn.author):Size(520,25):Point("TOPLEFT", about.authorLabel, "TOPRIGHT"):Color():Shadow():Top()
		about.versionLabel =  UI:New('Text', about, L.version):Size(150,25):Point("TOPLEFT", about.authorLabel, "BOTTOMLEFT", 0, 10):Shadow():Top()
		about.versionText =  UI:New('Text', about, tostring(AddOn.version)):Size(520,25):Point("TOPLEFT", about.versionLabel, "TOPRIGHT"):Color():Shadow():Top()
		about.changeLog = UI:New('ScrollFrame', about):Size(680, 180):Point("TOP", 0, -385):OnShow(
				function(self)
					local text = Util.Strings.Join2("\n", function() return true end, ParsedChangeLog())
					self.text:SetText(text)
					self:Height(self.text:GetStringHeight() + 50)

					self:OnShow(function()
						local height = 6 + self.text:GetStringHeight()
						self:Height(height)
						self:OnShow()
					end)
				end,
				true
		)
		about.changeLog:LayerBorder(0)
		UI:New('DecorationLine', about):Point("BOTTOM", about.changeLog,"TOP",0,0):Point("LEFT", about):Point("RIGHT",about):Size(0,1)
		UI:New('DecorationLine', about):Point("TOP", about.changeLog,"BOTTOM",0,0):Point("LEFT",about):Point("RIGHT",about):Size(0,1)
		about.changeLog.header = UI:New('Text', about.changeLog, L['change_log'], 12):Point("BOTTOMLEFT", about.changeLog,"TOPLEFT", 0, 10):Left()
		about.changeLog.text = UI:New('Text', about.changeLog.content, "", 12):Point("TOPLEFT",3,-3):Point("TOPRIGHT",-3,-3):Left():Color(1,1,1)
		lpad:SetModuleIndex(index)

		self.about = about
	end
end