local _, AddOn = ...
-- @type UI.Native
local NativeUI = AddOn.Require('UI.Native')
--- @type UI.Native.Widget
local BaseWidget = AddOn.ImportPackage('UI.Native').Widget
--- @type LibUtil
local Util = AddOn:GetLibrary("Util")
--- @type UI.Util
local UIUtil = AddOn.Require('UI.Util')
local Logging = AddOn:GetLibrary('Logging')

--- @class UI.Widgets.EditBox
local EditBox = AddOn.Package('UI.Widgets'):Class('EditBox', BaseWidget)

function EditBox:initialize(parent, name, maxLetters, numeric)
    BaseWidget.initialize(self, parent, name)
    self.maxLetters = maxLetters
    self.numeric = numeric
end

function EditBox:Create()
    local eb = CreateFrame("EditBox", self.name, self.parent, BackdropTemplateMixin and "BackdropTemplate")
    eb:EnableMouse(true)

    BaseWidget.Border(eb,0.24,0.25,0.3,1,1)

    eb.Background = eb:CreateTexture(nil,"BACKGROUND")
    eb.Background:SetColorTexture(0,0,0,.3)
    eb.Background:SetPoint("TOPLEFT")
    eb.Background:SetPoint("BOTTOMRIGHT")

    eb:SetFontObject("ChatFontNormal")
    eb:SetTextInsets(4, 4, 0, 0)

    eb:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    eb:SetScript("OnEditFocusLost", function(self) self:HighlightText(0, 0) end)
    eb:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)

    eb:SetAutoFocus(false)

    if self.maxLetters then eb:SetMaxLetters(self.maxLetters) end
    if self.numeric then eb:SetNumeric(true) end

    BaseWidget.Mod(
        eb,
        'Text', EditBox.SetText,
        'Tooltip', EditBox.SetTooltip,
        'OnChange', EditBox.OnChange,
        'OnFocus', EditBox.OnFocus,
        'InsideIcon', EditBox.InsideIcon,
        'AddSearchIcon',EditBox.AddSearchIcon,
        'LeftText', EditBox.AddLeftText,
        'TopText', EditBox.AddLeftTop,
        'BackgroundText',EditBox.AddBackgroundText,
        'ColorBorder', EditBox.ColorBorder,
        'GetTextHighlight', EditBox.GetTextHighlight,
        'OnDatasourceConfigured',  EditBox.OnDatasourceConfigured
    )

    eb:SetFontObject(BaseWidget.FontNormal)

    return eb
end

function EditBox.OnDatasourceConfigured(self)
    self:OnChange(Util.Functions.Noop)
    self:SetText(self.ds:Get())
    self:OnChange(
        Util.Functions.Debounce(
            function(self, userInput)
                Logging:Trace("EditBox.OnChange(%s)", tostring(userInput))
                if userInput then
                    self.ds:Set(self:GetText())
                end
            end, -- function
            1, -- seconds
            true -- leading
        )
    )
end

function EditBox.SetText(self, text)
    self:SetText(text or "")
    self:SetCursorPosition(0)
    return self
end

function EditBox.SetTooltip(self, title, ...)
    self.tipTitle = title
    self.tipLines = {...}

    self:SetScript(
        "OnEnter",
        function(self)
            local lines = Util.Tables.Copy(self.tipLines or {})
            UIUtil.ShowTooltip(self, nil, self.tipTitle, unpack(lines))
        end
    )

    self:SetScript("OnLeave", function() UIUtil:HideTooltip() end)

    return self
end

function EditBox.OnChange(self, fn)
    self:SetScript("OnTextChanged",fn)
    return self
end

function EditBox.OnFocus(self,gained,lost)
    self:SetScript("OnEditFocusGained",gained)
    self:SetScript("OnEditFocusLost",lost)
    return self
end

function EditBox.InsideIcon(self,texture,size,offset)
    self.insideIcon = self.insideIcon or self:CreateTexture(nil, "BACKGROUND",nil,2)
    self.insideIcon:SetPoint("RIGHT",-(offset or 2),0)
    self.insideIcon:SetSize(size or 14,size or 14)
    self.insideIcon:SetTexture(texture or "")
    return self
end

function EditBox.AddSearchIcon(self,size)
    return self:InsideIcon([[Interface\Common\UI-Searchbox-Icon]], size or 15)
end


function EditBox.AddLeftText(self,text,size)
    if self.leftText then
        self.leftText:SetText(text)
    else
        self.leftText = NativeUI:New('Text', self, text, size or 11):Point("RIGHT",self,"LEFT",-5,0):Right()
    end
    return self
end

function EditBox.AddLeftTop(self,text,size)
    if self.leftText then
        self.leftText:SetText(text)
    else
        self.leftText = NativeUI:New('Text', self, text, size or 11):Point("BOTTOM",self,"TOP",0,2)
    end
    return self
end

function EditBox.AddBackgroundText(self,text)
    if not self.backgroundText then
        self.backgroundText =
            NativeUI:New('Text', self, nil, 12, "ChatFontNormal"):Point("LEFT",2,0):Point("RIGHT",-2,0):Color(.5,.5,.5)
    end

    local function FocusGained(self)
        self.backgroundText:SetText("")
    end

    local function FocusLost(self)
        local text = self:GetText()
        if not text or text == "" then
            self.backgroundText:SetText(self.backText)
        end
    end

    local function BgCheck(self)
        local text = self:GetText()
        if (not text or Util.Strings.IsEmpty(text))and not self:HasFocus() then
            self.backgroundText:SetText(self.backText)
        else
            self.backgroundText:SetText("")
        end
    end

    self.backText = text
    self:OnFocus(FocusGained, FocusLost)
    self.BackgroundTextCheck = BgCheck
    self:BackgroundTextCheck()
    return self
end

function EditBox.ColorBorder(self,cR,cG,cB,cA)
    if Util.Objects.IsNumber(cR) then
        BaseWidget.Border(self,cR,cG,cB,cA,1)
    elseif cR then
        BaseWidget.Border(self,0.74,0.25,0.3,1,1)
    else
        BaseWidget.Border(self,0.24,0.25,0.3,1,1)
    end
    return self
end

function EditBox.GetTextHighlight(self)
    local text,cursor = self:GetText(),self:GetCursorPosition()
    self:Insert("")
    local textNew, cursorNew = self:GetText(), self:GetCursorPosition()
    self:SetText( text )
    self:SetCursorPosition( cursor )
    local spos, epos = cursorNew, #text - ( #textNew - cursorNew )
    self:HighlightText(spos, epos)
    return spos, epos
end

NativeUI:RegisterWidget('EditBox', EditBox)