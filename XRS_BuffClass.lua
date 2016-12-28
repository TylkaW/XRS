----------------------------
--      Declaration       --
----------------------------

local AceOO = AceLibrary("AceOO-2.0")
local dewdrop = AceLibrary("Dewdrop-2.0")
local BS = AceLibrary("Babble-Spell-2.2")
local BC = AceLibrary("Babble-Class-2.2")
local SEA = AceLibrary("SpecialEvents-Aura-2.0")
local L = AceLibrary("AceLocale-2.2"):new("XRS")
local compost = AceLibrary("Compost-2.0")
local crayon = AceLibrary("Crayon-2.0")

XRS.buff = AceOO.Class("AceDebug-2.0", "AceEvent-2.0")

----------------------------
--      Main Functions    --
----------------------------

function XRS.buff.prototype:init(pos, data)
    -- Call Superclass
    XRS.buff.super.prototype.init(self)
    
    -- Debugging state
    self:SetDebugging(false)
    
    -- Save data
    self.data = data
    self.pos = pos
    
    -- group init
    if not self.data.group then
        self.data.group = {}
        for i=1,8 do
            self.data.group[i] = true
        end
    end
    
    if not self.data.invertBuff then
        self.data.invertBuff = false
    end
    
    -- Register Events
    self:RegisterEvent("SpecialEvents_UnitBuffGained", "BuffGained")
    self:RegisterEvent("SpecialEvents_UnitBuffLost", "BuffLost")
    self:RegisterEvent("SpecialEvents_AuraRaidRosterUpdate", "RaidRosterUpdate")
    
    self.rru = self:ScheduleRepeatingEvent(self.RaidRosterUpdate, 1, self)
    
    -- Create the visual bar
    self:CreateBuff()
    
    -- Fill the table
    self:UpdateBuffTable()
end

function XRS.buff.prototype:Disable()
    self:RemoveBuff()
    
    self:Debug(self.data.buffs[1], "unregistered")
end

function XRS.buff.prototype:CreateBuff()
    -- The button
	
    self.button = CreateFrame("Button", nil, XRS.frame)
    self.button:Hide()
    self.button:SetWidth(20)
    self.button:SetHeight(20)
	if XRS.LUT_Icon[self.data.buffs[1]] == nil then
		self.button:SetNormalTexture(BS:GetSpellIcon(self.data.buffs[1]) or "Interface\\Icons\\INV_ValentinesCandy" )
	else
		self.button:SetNormalTexture(XRS.LUT_Icon[self.data.buffs[1]])
	end

    self.button:SetScript("OnClick",function()
        if ( IsShiftKeyDown() and arg1 == "LeftButton" ) then
            self:PrintMissingBuffs()
        elseif ( IsControlKeyDown() and arg1 == "LeftButton") then
            self.tooltip:Close()
            self.tooltip:Detach()
		elseif ( IsAltKeyDown() and arg1 == "LeftButton" ) then
			XRS:BuffSelf(self.data.buffs[1], 1)
        elseif ( arg1 == "LeftButton" ) then
            XRS:BuffRaid(self.data.buffs[1], self)
			XRS:BuffSelf(self.data.buffs[1], 0)
		end
    end)
    
    -- The tooltip
    self.tooltip = XRS.bufftooltip:new(self)
    
    -- the string count
    self.count = self.button:CreateFontString("$parentCount","ARTWORK","GameFontNormalSmall")
    self.count:SetWidth(20)
    self.count:SetHeight(20)
    self.count:SetFont(self.count:GetFont(),10,"OUTLINE")
    self:UpdateFontColor()
    self.count:SetPoint("CENTER", self.button, "CENTER", 0, 0)
    self.count:Show()
    
    local yposition = ((math.floor(self.pos / 5))*22)+8
    local xposition = (math.mod(self.pos,5)*22)+10
    
    self.button:SetPoint("BOTTOMLEFT", XRS.frame, "BOTTOMLEFT", xposition, yposition)
    
    -- Register dewdrop
    dewdrop:Register(self.button, 'children', function(level, value) self:CreateDDMenu(level, value) end)
    
    self.button:Show()
    
    self:Debug(self.data.buffs[1], "created")
end

function XRS.buff.prototype:RemoveBuff()
    -- Remove everything
    self:UnregisterAllEvents()
    self:CancelScheduledEvent(self.rru)
    
    local registered = dewdrop:IsRegistered(self.button)
    if registered then 
        dewdrop:Close()
        dewdrop:Unregister(self.button) 
    end
    self.button:Hide()
    self.count:Hide()
    self.count = nil
    self.button = nil
end


function XRS.buff.prototype:BuffGained(unitid, buff)
    local _, _, id = string.find(unitid, "^raid(%d+)$");
    if id then
        if self:InBuffTable(buff) then
            --self:Debug("gain", id, buff, UnitName(unitid))
            self.bufftable[unitid] = true
            self.count:SetText(self:GetMissingBuffCount())
            self.tooltip:Refresh()
        end
    end
	self:UpdateBuffTable()
end

function XRS.buff.prototype:BuffLost(unitid, buff)
    local _, _, id = string.find(unitid, "^raid(%d+)$");
    if id then
        if self:InBuffTable(buff) then
            --self:Debug("lost", id, buff, UnitName(unitid))
            self.bufftable[unitid] = false
            self.count:SetText(self:GetMissingBuffCount())
            self.tooltip:Refresh()
        end
    end
	self:UpdateBuffTable()
end

function XRS.buff.prototype:RaidRosterUpdate()
    self.count:SetText(self:GetMissingBuffCount())
end

function XRS.buff.prototype:InBuffTable(buff)
    for k,v in self.data.buffs do
        if v == buff then
            return true
        end
    end
    return false
end

function XRS.buff.prototype:UpdateBuffTable()
    -- The table to store the values
    self.bufftable = {}
    self.isPlayerBuffed = 0
    for i=1,40 do
        local raidID = "raid"..i
        local _, class = UnitClass(raidID)
        local _, _, subgroup, _, _, _, _, online, isDead = GetRaidRosterInfo(i)
        if UnitExists(raidID) and online and self:IsGroup(subgroup) and self:IsClass(class) and self:UnitHasBuff(raidID) then
            self.bufftable[raidID] = true
			if UnitName("player") == UnitName(raidID) then
				self.isPlayerBuffed = 1
			end
        else
            self.bufftable[raidID] = false
        end
    end
	if self.isPlayerBuffed == 1 then
		self.count:SetTextColor(0.2,0.9,0.2)
	else
		self.count:SetTextColor(0.9,0.2,0.2)
	end
    self.count:SetText(self:GetMissingBuffCount())
end

function XRS.buff.prototype:GetMissingBuffCount()
    local count = 0
    for k,v in self.bufftable do
        local _, _, id = string.find(k, "^raid(%d+)$");
        local _, class = UnitClass(k)
        local _, _, subgroup, _, _, _, _, online, isDead = GetRaidRosterInfo(id)
        if (not v and not self.data.invertBuff) or (v and self.data.invertBuff) then
            if (self.data.unitIsVisible and UnitIsVisible(k)) or (not self.data.unitIsVisible) then 
                if UnitExists(k) and online and not isDead and self:IsGroup(subgroup) and self:IsClass(class) then
                    count = count + 1
                end
            end
        end
    end
    return count
end

function XRS.buff.prototype:UnitHasBuff(raidID)
	
    for _,v in self.data.buffs do
		if XRS.LUT_BUFF[v] == nil then
			if SEA:UnitHasBuff(raidID, v) then
				return true
			end
		else
			if SEA:UnitHasBuff(raidID, XRS.LUT_BUFF[v]) then
				return true
			end
		end
    end
    return false
end

function XRS.buff.prototype:CreateDDMenu(level, value)
    -- Create drewdrop menu
    if level == 1 then
        dewdrop:AddLine( 'text', self.data.buffs[1], 'isTitle', true )
        dewdrop:AddLine('text', L["Buff_Text"],
                        'hasArrow', true,
                        'value', "buff",
                        'tooltipTitle', L["Buff_TTTitle"],
                        'tooltipText', L["Buff_TTText"]
                        )
        dewdrop:AddLine('text', L["Classes"],
                        'hasArrow', true,
                        'value', "classes",
                        'tooltipTitle', L["Classes_TTTitle"],
                        'tooltipText', L["Classes_TTText"]
                        )
        dewdrop:AddLine( 'text', L["Groups"],
                         'hasArrow', true,
                         'value', "groups",
                         'tooltipTitle', L["Groups_TTTitle"],
                         'tooltipText', L["Groups_TTText"]
                        )
        dewdrop:AddLine('text', L["Invert"],
                        'checked', self.data.invertBuff,
                        'func', function() 
                            self.data.invertBuff = not self.data.invertBuff
                            self:UpdateFontColor()
                            self.count:SetText(self:GetMissingBuffCount())
                        end)
        dewdrop:AddLine('text', L["UnitIsVisible"],
                        'checked', self.data.unitIsVisible,
                        'func', function() 
                            self.data.unitIsVisible = not self.data.unitIsVisible
                            self.count:SetText(self:GetMissingBuffCount())
                        end)
        dewdrop:AddLine()
        dewdrop:AddLine('text', L["Delete_Buff_Text"],
                        'func', function()
                                self:DeleteBuff()
                            end,
                        'tooltipTitle', L["Delete_Buff_TTTitle"],
                        'tooltipText', L["Delete_Buff_TTText"]
                        )
    elseif level == 2 then
        if value == "buff" then
            dewdrop:AddLine('text', L["Predefined_Text"],
                            'hasArrow', true,
                            'value', "predefined",
                            'tooltipTitle', L["Predefined_TTTitle"],
                            'tooltipText', L["Predefined_TTText"]
                            )
            local editBoxText = self.data.buffs[2] and "" or self.data.buffs[1]
            dewdrop:AddLine(
                            'text', L["Enter_Buff"],
                            'hasArrow', true,
                            'hasEditBox', true,
                            'editBoxFunc', function(name)
                                self:ChangeBuff({name})
                            end,
                            'editBoxText', editBoxText,
                            'tooltipTitle', L["Enter_Buff_TTTitle"],
                            'tooltipText', L["Enter_Buff_TTText"]
                            )
        elseif value == "classes" then
            local isChecked
            isChecked = self:IsClass("druid")
            dewdrop:AddLine('text', BC["Druid"],
                            'checked', isChecked,
                            'func', function() self:AddRemoveClass("druid") end)
            isChecked = self:IsClass("hunter")
            dewdrop:AddLine('text', BC["Hunter"],
                            'checked', isChecked,
                            'func', function() self:AddRemoveClass("hunter") end)
            isChecked = self:IsClass("mage")
            dewdrop:AddLine('text', BC["Mage"],
                            'checked', isChecked,
                            'func', function() self:AddRemoveClass("mage") end)
            if UnitFactionGroup("player") == "Alliance" then
                isChecked = self:IsClass("paladin")
                dewdrop:AddLine('text', BC["Paladin"],
                                'checked', isChecked,
                                'func', function() self:AddRemoveClass("paladin") end)
            end
            isChecked = self:IsClass("priest")
            dewdrop:AddLine('text', BC["Priest"],
                            'checked', isChecked,
                            'func', function() self:AddRemoveClass("priest") end)
            isChecked = self:IsClass("rogue")
            dewdrop:AddLine('text', BC["Rogue"],
                            'checked', isChecked,
                            'func', function() self:AddRemoveClass("rogue") end)
            if UnitFactionGroup("player") == "Horde" then
                isChecked = self:IsClass("Shaman")
                dewdrop:AddLine('text', BC["Shaman"],
                                'checked', isChecked,
                                'func', function() self:AddRemoveClass("shaman") end)
            end
            isChecked = self:IsClass("warlock")
            dewdrop:AddLine('text', BC["Warlock"],
                            'checked', isChecked,
                            'func', function() self:AddRemoveClass("warlock") end)
            isChecked = self:IsClass("warrior")
            dewdrop:AddLine('text', BC["Warrior"],
                            'checked', isChecked,
                            'func', function() self:AddRemoveClass("warrior") end)
        elseif value == "groups" then
            for i=1,8 do
                local isChecked
                local number = i
                isChecked = self:IsGroup(number)
                dewdrop:AddLine( 'text', L["Group"].." "..number,
                                 'checked', isChecked,
                                 'func', function() self:AddRemoveGroup(number) end)
            end
        end

		elseif level == 3 then    
			if value == "predefined" then
				dewdrop:AddLine( 'text', L["Raid_Buff"],
							 'hasArrow', true,
							 'value', "raid_buffs",
							 'tooltipTitle', L["Raid_Buff"],
							 'tooltipText', L["Raid_Buff_TTText"]
						  )
				dewdrop:AddLine( 'text', L["Tank_Conso"],
							 'hasArrow', true,
							 'value', "tank_conso",
							 'tooltipTitle', L["Tank_Conso"],
							 'tooltipText', L["Tank_Conso_TTText"]
						  )
				dewdrop:AddLine( 'text', L["Healer_Conso"],
							 'hasArrow', true,
							 'value', "healer_conso",
							 'tooltipTitle', L["Healer_Conso"],
							 'tooltipText', L["Healer_Conso_TTText"]
						  )
				dewdrop:AddLine( 'text', L["Melee_Conso"],
							 'hasArrow', true,
							 'value', "melee_conso",
							 'tooltipTitle', L["Melee_Conso"],
							 'tooltipText', L["Melee_Conso_TTText"]
						  )
				dewdrop:AddLine( 'text', L["Caster_Conso"],
							 'hasArrow', true,
							 'value', "caster_conso",
							 'tooltipTitle', L["Caster_Conso"],
							 'tooltipText', L["Caster_Conso_TTText"]
						  )
			end
							
		elseif level == 4 then
			if value == "raid_buffs" then
				dewdrop:AddLine( 'text', L["Class_Buff"], 'isTitle', true )
				dewdrop:AddLine('text', BS["Arcane Intellect"],
                            'isRadio', true,
                            'checked', self.data.buffs[1] == BS["Arcane Intellect"] and self.data.buffs[2] == BS["Arcane Brilliance"],
                            'func', function() self:ChangeBuff({BS["Arcane Intellect"], BS["Arcane Brilliance"]}) end)
				dewdrop:AddLine('text', BS["Power Word: Fortitude"],
                            'isRadio', true,
                            'checked', self.data.buffs[1] == BS["Power Word: Fortitude"] and self.data.buffs[2] == BS["Prayer of Fortitude"],
                            'func', function() self:ChangeBuff({BS["Power Word: Fortitude"], BS["Prayer of Fortitude"]}) end)
				dewdrop:AddLine('text', BS["Mark of the Wild"],
                            'isRadio', true,
                            'checked', self.data.buffs[1] == BS["Mark of the Wild"] and self.data.buffs[2] == BS["Gift of the Wild"],
                            'func', function() self:ChangeBuff({BS["Mark of the Wild"], BS["Gift of the Wild"]}) end)
				dewdrop:AddLine('text', BS["Divine Spirit"],
                            'isRadio', true,
                            'checked', self.data.buffs[1] == BS["Divine Spirit"] and self.data.buffs[2] == BS["Prayer of Spirit"],
                            'func', function() self:ChangeBuff({BS["Divine Spirit"], BS["Prayer of Spirit"]}) end)
				dewdrop:AddLine('text', BS["Shadow Protection"],
                            'isRadio', true,
                            'checked', self.data.buffs[1] == BS["Shadow Protection"] and self.data.buffs[2] == BS["Prayer of Shadow Protection"],
                            'func', function() self:ChangeBuff({BS["Shadow Protection"], BS["Prayer of Shadow Protection"]}) end)
				
				if UnitFactionGroup("player") == "Alliance" then
					dewdrop:AddLine('text', BS["Blessing of Kings"],
									'isRadio', true,
									'checked', self.data.buffs[1] == BS["Blessing of Kings"] and self.data.buffs[2] == BS["Greater Blessing of Kings"],
									'func', function() self:ChangeBuff({BS["Blessing of Kings"], BS["Greater Blessing of Kings"]}) end)
					dewdrop:AddLine('text', BS["Blessing of Light"],
									'isRadio', true,
									'checked', self.data.buffs[1] == BS["Blessing of Light"] and self.data.buffs[2] == BS["Greater Blessing of Light"],
									'func', function() self:ChangeBuff({BS["Blessing of Light"], BS["Greater Blessing of Light"]}) end)
					dewdrop:AddLine('text', BS["Blessing of Might"],
									'isRadio', true,
									'checked', self.data.buffs[1] == BS["Blessing of Might"] and self.data.buffs[2] == BS["Greater Blessing of Might"],
									'func', function() self:ChangeBuff({BS["Blessing of Might"], BS["Greater Blessing of Might"]}) end)
					dewdrop:AddLine('text', BS["Blessing of Salvation"],
									'isRadio', true,
									'checked', self.data.buffs[1] == BS["Blessing of Salvation"] and self.data.buffs[2] == BS["Greater Blessing of Salvation"],
									'func', function() self:ChangeBuff({BS["Blessing of Salvation"], BS["Greater Blessing of Salvation"]}) end)
					dewdrop:AddLine('text', BS["Blessing of Sanctuary"],
									'isRadio', true,
									'checked', self.data.buffs[1] == BS["Blessing of Sanctuary"] and self.data.buffs[2] == BS["Greater Blessing of Sanctuary"],
									'func', function() self:ChangeBuff({BS["Blessing of Sanctuary"], BS["Greater Blessing of Sanctuary"]}) end)
					dewdrop:AddLine('text', BS["Blessing of Wisdom"],
									'isRadio', true,
									'checked', self.data.buffs[1] == BS["Blessing of Wisdom"] and self.data.buffs[2] == BS["Greater Blessing of Wisdom"],
									'func', function() self:ChangeBuff({BS["Blessing of Wisdom"], BS["Greater Blessing of Wisdom"]}) end)
				end
				
				dewdrop:AddLine( 'text', L["Raid_Buff"], 'isTitle', true )
				dewdrop:AddLine( 'text', L["Dragonslayer"],
					'isRadio', true,
					'checked', self.data.buffs[1] == L["Dragonslayer"],
					'func', function() self:ChangeBuff({L["Dragonslayer"]}) end)
				dewdrop:AddLine( 'text', L["Spirit_Zanza"],
					'isRadio', true,
					'checked', self.data.buffs[1] == L["Spirit_Zanza"],
					'func', function() self:ChangeBuff({L["Spirit_Zanza"]}) end)
				dewdrop:AddLine( 'text', L["Swiftness_Zanza"],
					'isRadio', true,
					'checked', self.data.buffs[1] == L["Swiftness_Zanza"],
					'func', function() self:ChangeBuff({L["Swiftness_Zanza"]}) end)
				dewdrop:AddLine( 'text', L["Spirit_Zandalar"],
					'isRadio', true,
					'checked', self.data.buffs[1] == L["Spirit_Zandalar"],
					'func', function() self:ChangeBuff({L["Spirit_Zandalar"]}) end)
				dewdrop:AddLine( 'text', L["SlipKik_Savvy"],
					'isRadio', true,
					'checked', self.data.buffs[1] == L["SlipKik_Savvy"],
					'func', function() self:ChangeBuff({L["SlipKik_Savvy"]}) end)
				dewdrop:AddLine( 'text', L["MolDar_Moxie"],
					'isRadio', true,
					'checked', self.data.buffs[1] == L["MolDar_Moxie"],
					'func', function() self:ChangeBuff({L["MolDar_Moxie"]}) end)
				dewdrop:AddLine( 'text', L["Fengus_Ferocity"],
					'isRadio', true,
					'checked', self.data.buffs[1] == L["Fengus_Ferocity"],
					'func', function() self:ChangeBuff({L["Fengus_Ferocity"]}) end)
				
				dewdrop:AddLine( 'text', L["Protection_Potion"], 'isTitle', true )
				dewdrop:AddLine( 'text', L["Arcane_Protection_Potion"],
					'isRadio', true,
					'checked', self.data.buffs[1] == L["Arcane_Protection_Potion"],
					'func', function() self:ChangeBuff({L["Arcane_Protection_Potion"]}) end)
				dewdrop:AddLine( 'text', L["Fire_Protection_Potion"],
					'isRadio', true,
					'checked', self.data.buffs[1] == L["Fire_Protection_Potion"],
					'func', function() self:ChangeBuff({L["Fire_Protection_Potion"]}) end)
				dewdrop:AddLine( 'text', L["Frost_Protection_Potion"],
					'isRadio', true,
					'checked', self.data.buffs[1] == L["Frost_Protection_Potion"],
					'func', function() self:ChangeBuff({L["Frost_Protection_Potion"]}) end)
				dewdrop:AddLine( 'text', L["Nature_Protection_Potion"],
					'isRadio', true,
					'checked', self.data.buffs[1] == L["Nature_Protection_Potion"],
					'func', function() self:ChangeBuff({L["Nature_Protection_Potion"]}) end)
				dewdrop:AddLine( 'text', L["Shadow_Protection_Potion"],
					'isRadio', true,
					'checked', self.data.buffs[1] == L["Shadow_Protection_Potion"],
					'func', function() self:ChangeBuff({L["Shadow_Protection_Potion"]}) end)
					
			elseif value == "tank_conso" then
				dewdrop:AddLine( 'text', L["Elixir_Superior_Defense"],
					'isRadio', true,
					'checked', self.data.buffs[1] == L["Elixir_Superior_Defense"],
					'func', function() self:ChangeBuff({L["Elixir_Superior_Defense"]}) end)
				dewdrop:AddLine( 'text', L["Elixir_Fortitude"],
					'isRadio', true,
					'checked', self.data.buffs[1] == L["Elixir_Fortitude"],
					'func', function() self:ChangeBuff({L["Elixir_Fortitude"]}) end)
				dewdrop:AddLine( 'text', L["Flask_Titans"],
					'isRadio', true,
					'checked', self.data.buffs[1] == L["Flask_Titans"],
					'func', function() self:ChangeBuff({L["Flask_Titans"]}) end)
				dewdrop:AddLine( 'text', L["Well_Fed"],
					'isRadio', true,
					'checked', self.data.buffs[1] == L["Well_Fed"],
					'func', function() self:ChangeBuff({L["Well_Fed"]}) end)
				dewdrop:AddLine( 'text', L["Elixir_Greater_Agility"],
					'isRadio', true,
					'checked', self.data.buffs[1] == L["Elixir_Greater_Agility"],
					'func', function() self:ChangeBuff({L["Elixir_Greater_Agility"]}) end)
				dewdrop:AddLine( 'text', L["Rumsey_Rum_Black_Label"],
					'isRadio', true,
					'checked', self.data.buffs[1] == L["Rumsey_Rum_Black_Label"],
					'func', function() self:ChangeBuff({L["Rumsey_Rum_Black_Label"]}) end)
								 
			elseif value == "healer_conso" then
				dewdrop:AddLine( 'text', L["Mageblood_Potion"],
					'isRadio', true,
					'checked', self.data.buffs[1] == L["Mageblood_Potion"],
					'func', function() self:ChangeBuff({L["Mageblood_Potion"]}) end)
				dewdrop:AddLine( 'text', L["Well_Fed"],
					'isRadio', true,
					'checked', self.data.buffs[1] == L["Well_Fed"],
					'func', function() self:ChangeBuff({L["Well_Fed"]}) end)
				dewdrop:AddLine( 'text', L["Flask_Distilled_Wisdom"],
					'isRadio', true,
					'checked', self.data.buffs[1] == L["Flask_Distilled_Wisdom"],
					'func', function() self:ChangeBuff({L["Flask_Distilled_Wisdom"]}) end)
					
			elseif value == "melee_conso" then
				
				dewdrop:AddLine( 'text', L["Elixir_Mongoose"],
					'isRadio', true,
					'checked', self.data.buffs[1] == L["Elixir_Mongoose"],
					'func', function() self:ChangeBuff({L["Elixir_Mongoose"]}) end)
				dewdrop:AddLine( 'text', L["Winterfall_Firewater"],
					'isRadio', true,
					'checked', self.data.buffs[1] == L["Winterfall_Firewater"],
					'func', function() self:ChangeBuff({L["Winterfall_Firewater"]}) end)
				dewdrop:AddLine( 'text', L["Juju_Might"],
					'isRadio', true,
					'checked', self.data.buffs[1] == L["Juju_Might"],
					'func', function() self:ChangeBuff({L["Juju_Might"]}) end)
				dewdrop:AddLine( 'text', L["Juju_Power"],
					'isRadio', true,
					'checked', self.data.buffs[1] == L["Juju_Power"],
					'func', function() self:ChangeBuff({L["Juju_Power"]}) end)
				dewdrop:AddLine( 'text', L["Well_Fed"],
					'isRadio', true,
					'checked', self.data.buffs[1] == L["Well_Fed"],
					'func', function() self:ChangeBuff({L["Well_Fed"]}) end)
								 
			elseif value == "caster_conso" then
				dewdrop:AddLine( 'text', L["Greater_Arcane_Elixir"],
					'isRadio', true,
					'checked', self.data.buffs[1] == L["Greater_Arcane_Elixir"],
					'func', function() self:ChangeBuff({L["Greater_Arcane_Elixir"]}) end)
				dewdrop:AddLine( 'text', L["Elixir_Frost_Power"],
					'isRadio', true,
					'checked', self.data.buffs[1] == L["Elixir_Frost_Power"],
					'func', function() self:ChangeBuff({L["Elixir_Frost_Power"]}) end)
				dewdrop:AddLine( 'text', L["Elixir_Greater_Firepower"],
					'isRadio', true,
					'checked', self.data.buffs[1] == L["Elixir_Greater_Firepower"],
					'func', function() self:ChangeBuff({L["Elixir_Greater_Firepower"]}) end)
				dewdrop:AddLine( 'text', L["Elixir_Shadow_Power"],
					'isRadio', true,
					'checked', self.data.buffs[1] == L["Elixir_Shadow_Power"],
					'func', function() self:ChangeBuff({L["Elixir_Shadow_Power"]}) end)
				dewdrop:AddLine( 'text', L["Mageblood_Potion"],
					'isRadio', true,
					'checked', self.data.buffs[1] == L["Mageblood_Potion"],
					'func', function() self:ChangeBuff({L["Mageblood_Potion"]}) end)
				dewdrop:AddLine( 'text', L["Well_Fed"],
					'isRadio', true,
					'checked', self.data.buffs[1] == L["Well_Fed"],
					'func', function() self:ChangeBuff({L["Well_Fed"]}) end)
				dewdrop:AddLine( 'text', L["Flask_Supreme_Power"],
					'isRadio', true,
					'checked', self.data.buffs[1] == L["Flask_Supreme_Power"],
					'func', function() self:ChangeBuff({L["Flask_Supreme_Power"]}) end)
			end
		end			
    end

function XRS.buff.prototype:ChangeBuff(buff)
	
    self.data.buffs = {}
    for k,v in buff do
        self.data.buffs[k] = v
    end
	if XRS.LUT_Icon[self.data.buffs[1]] == nil then
		self.button:SetNormalTexture(BS:GetSpellIcon(self.data.buffs[1]) or "Interface\\Icons\\INV_ValentinesCandy" )
	else
		self.button:SetNormalTexture(XRS.LUT_Icon[self.data.buffs[1]])
	end
    self:UpdateBuffTable()
end	

function XRS.buff.prototype:DeleteBuff()
    self:RemoveBuff()
    XRS:DeleteBuff(self)
end

function XRS.buff.prototype:SetPosition(pos)
    self.pos = pos-1
    
    local yposition = ((math.floor(self.pos / 5))*22)+8
    local xposition = (math.mod(self.pos,5)*22)+10
    
    self.button:SetPoint("BOTTOMLEFT", XRS.frame, "BOTTOMLEFT", xposition, yposition)
end

function XRS.buff.prototype:GetObject()
    return self.button
end

function XRS.buff.prototype:GetType()
    return "button"
end

function XRS.buff.prototype:GetBuffs()
    return self.data.buffs
end

function XRS.buff.prototype:GetBuffTable()
    return self.bufftable
end

function XRS.buff.prototype:ToString()
    return self.data.buffs[1]
end

function XRS.buff.prototype:IsClass(class)
    if not class then return false end
    for _,v in self.data.c do
        if string.lower(v) == string.lower(class) then return true end
    end
    return false
end

function XRS.buff.prototype:IsGroup(group)
    return self.data.group[group]
end

function XRS.buff.prototype:AddRemoveClass(class)
    self:Debug("Class: "..class)
    if self:IsClass(class) then
        self:Debug("Remove: "..class)
        self:RemoveClass(class)
    else
        self:Debug("Add: "..class)
        self:AddClass(class)
    end
    self:UpdateBuffTable()
end

function XRS.buff.prototype:AddRemoveGroup(group)
    self.data.group[group] = not self.data.group[group]
    self:UpdateBuffTable()
end

function XRS.buff.prototype:RemoveClass(class)
    for k,v in self.data.c do
        if string.lower(v) == string.lower(class) then
            table.remove(self.data.c, k)
        end
    end
end

function XRS.buff.prototype:AddClass(class)
    table.insert(self.data.c, class)
end

function XRS.buff.prototype:PrintMissingBuffs()
    if not IsRaidLeader() and not IsRaidOfficer() then 
        XRS:Print("Need Leader/Admin rights to do this!")
    else
        local t = compost:Acquire()
        for k,v in self.bufftable do
            local _, _, id = string.find(k, "^raid(%d+)$");
            local _, class = UnitClass(k)
            local _, _, subgroup, _, _, _, _, online, isDead = GetRaidRosterInfo(id)
            if (self.data.unitIsVisible and UnitIsVisible(k)) or (not self.data.unitIsVisible) then 
                if v == false and UnitExists(k) and online and not isDead and self:IsGroup(subgroup) and self:IsClass(class) then
                    local name = UnitName(k)
                    table.insert(t, name)
                end
            end
        end
        
        local count = table.getn(t)
        local name = self:ToString()
        
        if (count==0) then self:RaidOutput(string.format("%s :: "..L["Full buffed!"], name)) return end
        if (count>0) then self:RaidOutput(string.format("%s :: "..count..L[" missing."], name)) end
        
        self:RaidOutput(table.concat(t, ", "))
        
        compost:Reclaim(t)
        t = nil
    end
end

function XRS.buff.prototype:RaidOutput(msg)
    SendChatMessage(msg, "RAID")
end

-- Cast a buff on a specified person
function XRS.buff.prototype:BuffPerson(id, spells)
	local selfCast = GetCVar("autoSelfCast")
	SetCVar("autoSelfCast", "0")
    local initialTarget = UnitName("target")
    local isEnemy = UnitIsEnemy("player","target")
    
    ClearTarget()
    if IsShiftKeyDown() then
        CastSpellByName(spells[2])
    else
        CastSpellByName(spells[1])
    end
    if UnitIsVisible(id) and SpellCanTargetUnit(id) then
        XRS:Print(string.format("%s: %s", crayon:Silver(UnitName(id)), crayon:Orange(spells[2] or spells[1])))
        SpellTargetUnit(id)
    end
    
    if SpellIsTargeting() then SpellStopCasting() end
    XRS:ReTarget(initialTarget, isEnemy)
	SetCVar("autoSelfCast", selfCast)
end

function XRS.buff.prototype:UpdateFontColor()
    if self.data.invertBuff then
        self.count:SetTextColor(0.2,0.2,0.9)
    else
        self.count:SetTextColor(0.9,0.4,0.4)
    end
end

function XRS.buff.prototype:SetWidth(width)
	local buffcount = math.floor(width/22)
	local yposition = ((math.floor(self.pos / buffcount))*22)+8
	local xposition = (math.mod(self.pos,buffcount)*22)+10

	self.button:SetPoint("BOTTOMLEFT", XRS.frame, "BOTTOMLEFT", xposition, yposition)
end
