----------------------------
--      Declaration       --
----------------------------

XRS = AceLibrary("AceAddon-2.0"):new("AceEvent-2.0", "AceDB-2.0", "AceConsole-2.0", "AceDebug-2.0")
local L = AceLibrary("AceLocale-2.2"):new("XRS")
local dewdrop = AceLibrary("Dewdrop-2.0")
local BS = AceLibrary("Babble-Spell-2.2")
local BC = AceLibrary("Babble-Class-2.2")
local crayon = AceLibrary("Crayon-2.0")
local compost = AceLibrary("Compost-2.0")
local roster = AceLibrary("RosterLib-2.0")

BINDING_HEADER_XRS="XRaidStatus"

----------------------------
--      Main Functions    --
----------------------------

function XRS:OnInitialize()
    -- Debugging state
    self:SetDebugging(false)
    
    -- Command structure
    self.options = {
        type="group",
        args = {
            scale = {
                name = L["Scale"], type = "range",
                desc = L["Scale_D"],
                get = function() return self.db.profile.Scale end,
                set = function(v)
                    self.db.profile.Scale = v
                    self:UpdateScale()
                end,
                min = 0.5,
                max = 1.5,
                step = 0.05,
                order = 2
            },
			width = {
				name = L["Width"], type = "range",
				desc = L["Width_D"],
				get = function() return self.db.profile.Width end,
				set = function(v)
					self.db.profile.Width = v
					self:SetWidth()
				end,
				min = 70,
				max = 200,
				step = 5,
				order = 3
			},
            texture = {
                name = L["Textures"], type = 'text',
                desc = L["Textures_D"],
                get = function()
                    return self.db.profile.Texture
                end,
                set = function(name)
                    self:SetBarTexture(name)
                end,
                validate = {},
                order = 4,
            },
            color = {
                name = L["Color_Group"], type = "group",
                desc = L["Color_Group_D"],
                args = {
                    background = {
                        name = L["BColor"], type = 'color',
                        desc = L["BColor_D"],
                        get = function()
                            local bc = self.db.profile.backgroundcolor
                            return bc.r, bc.g, bc.b, bc.a
                        end,
                        set = function(r, g, b, a)
                            self:UpdateBackgroundColor(r,g,b,a)
                        end,
                        hasAlpha = true,
                        order = 1,
                    },
                    title = {
                        name = L["TColor"], type = 'color',
                        desc = L["TColor_D"],
                        get = function()
                            local tc = self.db.profile.titlecolor
                            return tc.r, tc.g, tc.b, tc.a
                        end,
                        set = function(r, g, b, a)
                            self:UpdateTitleColor(r,g,b,a)
                        end,
                        hasAlpha = true,
                        order = 2,
                    },
                    border = {
                        name = L["BOColor"], type = 'color',
                        desc = L["BOColor_D"],
                        get = function()
                            local boc = self.db.profile.bordercolor
                            return boc.r, boc.g, boc.b, boc.a
                        end,
                        set = function(r, g, b, a)
                            self:UpdateBorderColor(r,g,b,a)
                        end,
                        hasAlpha = true,
                        order = 3,
                    },                    
                },
                order = 5
            },
            updaterate = {
                name = L["Update_Rate"], type = "range",
                desc = L["Update_Rate_D"],
                get = function() return self.db.profile.UpdateRate end,
                set = function(v)
                    self:ModifyUpdateRate(v)
                end,
                min = 0.1,
                max = 1.5,
                step = 0.1,
                order = 6
            },
            lock = {
                name = L["Lock"], type = "toggle",
                desc = L["Lock_D"],
                get =   function()
                            return self.db.profile.Locked
                        end,
                        set = function(v)
                            self.db.profile.Locked = v
                        end,
                order = 7
            },
            hint = {
                name = L["Hint"], type = "toggle",
                desc = L["Hint_D"],
                get =   function()
                            return self.db.profile.ShowHint
                        end,
                        set = function(v)
                            self.db.profile.ShowHint = v
                        end,
                order = 8
            },
            blankone = {
                type = "header",
                order = 9
            },
            save = {
                name = L["Save"], type = 'text',
                desc = L["Save_D"],
                usage = "<name>",
                get = false,
                set = function(name) self:SaveConfiguration(name) end,
                order = 11,
                args = {}
            },
            load = {
                name = L["Load"], type = 'group',
                desc = L["Load_D"],
                order = 12,
                args = {}
            },
            delete = {
                name = L["Delete"], type = 'group',
                desc = L["Delete_D"],
                order = 13,
                args = {}
            },
            blanktwo = {
                type = "header",
                order = 19
            },
            new = {
                name = L["New_Group"], type = "group",
                desc = L["New_Group_D"],
                args = {
                    bar = {
                        name = L["Create_Bar"], type = "execute",
                        desc = L["Create_Bar_D"],
                        func = function()
                                    self:CreateNewBar()
                                end,
                        order = 1
                    },
                    buff = {
                        name = L["Create_Button"], type = "execute",
                        desc = L["Create_Button_D"],
                        func = function()
                                    self:CreateNewBuffButton()
                                end,
                        order = 2
                    },
                },
                order = 20,
            },
            blankthree = {
                type = "header",
                order = 29
            },
            deletedb = {
                name = L["Delete_DB"], type = "execute",
                desc = L["Delete_DB_D"],
                func = function()
                            self:ResetDB("profile")
                        end,
                order = 30
            }
        }
    }

    -- Class table
    self.classTable = {
        "Druid",
        "Hunter",
        "Mage",
        "Paladin",
        "Priest",
        "Rogue",
        "Shaman",
        "Warlock",
        "Warrior",
    }
	
    self.LUT_Icon = {
	[L["Restorative_Potion"]] = "Interface\\Icons\\INV_Potion_01",
	[L["Elixir_Frost_Power"]]	 = "Interface\\Icons\\INV_Potion_03",
	[L["Frost_Protection_Potion"]] = "Interface\\Icons\\INV_Potion_20",
	[L["Nature_Protection_Potion"]] = "Interface\\Icons\\INV_Potion_22",
	[L["Shadow_Protection_Potion"]] = "Interface\\Icons\\INV_Potion_23",
	[L["Fire_Protection_Potion"]] = "Interface\\Icons\\INV_Potion_24",
	[L["Arcane_Protection_Potion"]] = "Interface\\Icons\\INV_Potion_83",
	[L["Greater_Arcane_Elixir"]] = "Interface\\Icons\\INV_Potion_25",
	[L["Swiftness_Zanza"]] = "Interface\\Icons\\INV_Potion_31",
	[L["Spirit_Zanza"]] = "Interface\\Icons\\INV_Potion_30",
	[L["Elixir_Mongoose"]] = "Interface\\Icons\\INV_Potion_32",
	[L["Flask_Supreme_Power"]] = "Interface\\Icons\\INV_Potion_41",
	[L["Elixir_Fortitude"]] = "Interface\\Icons\\INV_Potion_43",
	[L["Elixir_Shadow_Power"]] = "Interface\\Icons\\INV_Potion_46",
	[L["Mageblood_Potion"]] = "Interface\\Icons\\INV_Potion_45",
	[L["Elixir_Greater_Firepower"]] = "Interface\\Icons\\INV_Potion_60",
	[L["Flask_Titans"]] = "Interface\\Icons\\INV_Potion_62",
	[L["Elixir_Superior_Defense"]] = "Interface\\Icons\\INV_Potion_66",
	[L["Greater_Stoneshield_Potion"]] = "Interface\\Icons\\INV_Potion_69",
	[L["Winterfall_Firewater"]] = "Interface\\Icons\\INV_Potion_92",
	[L["Flask_Distilled_Wisdom"]] = "Interface\\Icons\\INV_Potion_97",
	[L["Rumsey_Rum_Black_Label"]] = "Interface\\Icons\\INV_Drink_04",
	[L["Juju_Might"]] = "Interface\\Icons\\INV_Misc_MonsterScales_07",
	[L["Juju_Power"]] = "Interface\\Icons\\INV_Misc_MonsterScales_11",
	[L["Well_Fed"]] = "Interface\\Icons\\INV_Misc_Food_01",
	[L["Runn_Tum_Tuber_Surprise"]] = "Interface\\Icons\\INV_Misc_Food_63",
	[L["Nightfin_Soup"]] = "Interface\\Icons\\INV_Drink_04",
	[L["Elixir_Greater_Agility"]] = "Interface\\Icons\\INV_Potion_94",
	[L["Free_Action_Potion"]] = "Interface\\Icons\\INV_Potion_04",
	[L["Blessed_Sunfruit"]] = "Interface\\Icons\\INV_Misc_Food_41",
	[L["Grilled_Squid"]] = "Interface\\Icons\\INV_Misc_Food_13",
	[L["Sagefish_Delight"]] = "Interface\\Icons\\INV_Misc_Fish_21",
	[L["SlipKik_Savvy"]] = "Interface\\Icons\\Spell_Holy_LesserHeal02",
	[L["MolDar_Moxie"]] = "Interface\\Icons\\Spell_Nature_MassTeleport",
	[L["Fengus_Ferocity"]] = "Interface\\Icons\\Spell_Nature_UndyingStrength",
	[L["Dragonslayer"]] = "Interface\\Icons\\INV_Misc_Head_Dragon_01",
	[L["Spirit_Zandalar"]] = "Interface\\Icons\\Ability_Creature_Poison_05",
	}
	
	self.LUT_BUFF = {
	[L["Restorative_Potion"]] = L["Restorative_Potion_Buff"],
	[L["Elixir_Frost_Power"]] = L["Elixir_Frost_Power_Buff"],
	[L["Frost_Protection_Potion"]] = L["Frost_Protection_Potion_Buff"],
	[L["Nature_Protection_Potion"]] = L["Nature_Protection_Potion_Buff"],
	[L["Shadow_Protection_Potion"]] = L["Shadow_Protection_Potion_Buff"],
	[L["Fire_Protection_Potion"]] = L["Fire_Protection_Potion_Buff"],
	[L["Arcane_Protection_Potion"]] = L["Arcane_Protection_Potion_Buff"],
	[L["Greater_Arcane_Elixir"]] = L["Greater_Arcane_Elixir_Buff"],
	[L["Swiftness_Zanza"]] = L["Swiftness_Zanza_Buff"],
	[L["Spirit_Zanza"]] = L["Spirit_Zanza_Buff"],
	[L["Elixir_Mongoose"]] = L["Elixir_Mongoose_Buff"],
	[L["Flask_Supreme_Power"]] = L["Flask_Supreme_Power_Buff"],
	[L["Elixir_Fortitude"]] = L["Elixir_Fortitude_Buff"],
	[L["Elixir_Shadow_Power"]] = L["Elixir_Shadow_Power_Buff"],
	[L["Mageblood_Potion"]] = L["Mageblood_Potion_Buff"],
	[L["Elixir_Greater_Firepower"]] = L["Elixir_Greater_Firepower_Buff"],
	[L["Flask_Titans"]] = L["Flask_Titans_Buff"],
	[L["Elixir_Superior_Defense"]] = L["Elixir_Superior_Defense_Buff"],
	[L["Greater_Stoneshield_Potion"]] = L["Greater_Stoneshield_Potion_Buff"],
	[L["Winterfall_Firewater"]] = L["Winterfall_Firewater_Buff"],
	[L["Flask_Distilled_Wisdom"]] = L["Flask_Distilled_Wisdom_Buff"],
	[L["Rumsey_Rum_Black_Label"]] = L["Rumsey_Rum_Black_Label_Buff"],
	[L["Juju_Might"]] = L["Juju_Might_Buff"],
	[L["Juju_Power"]] = L["Juju_Power_Buff"],
	[L["Well_Fed"]] = L["Well_Fed_Buff"],
	[L["Runn_Tum_Tuber_Surprise"]] = L["Runn_Tum_Tuber_Surprise_Buff"],
	[L["Nightfin_Soup"]] = L["Nightfin_Soup_Buff"],
	[L["Elixir_Greater_Agility"]] = L["Elixir_Greater_Agility_Buff"],
	[L["Free_Action_Potion"]] = L["Free_Action_Potion_Buff"],
	[L["Blessed_Sunfruit"]] = L["Blessed_Sunfruit_Buff"],
	[L["Grilled_Squid"]] = L["Grilled_Squid_Buff"],
	[L["Sagefish_Delight"]] = L["Sagefish_Delight_Buff"],
	}
	
    -- Buff table
    self.buffTable = {
        sta = {
            BS["Power Word: Fortitude"],
            BS["Prayer of Fortitude"],
        },
        motw = {
            BS["Mark of the Wild"],
            BS["Gift of the Wild"],
        },
        ai = {
            BS["Arcane Intellect"],
            BS["Arcane Brilliance"],
        },
        spi = {
            BS["Divine Spirit"],
            BS["Prayer of Spirit"],
        },
        sp = {
            BS["Shadow Protection"],
            BS["Prayer of Shadow Protection"],
        },
		rp = { -- Restorative potion
			self.LUT_BUFF[L["Restorative_Potion"]],
		},
		efp = { -- Elixir of frost power
			self.LUT_BUFF[L["Elixir_Frost_Power"]]
		},
		frpp = {
			self.LUT_BUFF[L["Frost_Protection_Potion"]]
		},
		npp = {
			self.LUT_BUFF[L["Nature_Protection_Potion"]]
		},
		spp = {
			self.LUT_BUFF[L["Shadow_Protection_Potion"]]
		},
		fpp = {
			self.LUT_BUFF[L["Fire_Protection_Potion"]]
		},
		app = {
			self.LUT_BUFF[L["Arcane_Protection_Potion"]]
		},
		gae = {
			self.LUT_BUFF[L["Greater_Arcane_Elixir"]]
		},
		swz = {
			self.LUT_BUFF[L["Swiftness_Zanza"]]
		},
		spz = {
			self.LUT_BUFF[L["Spirit_Zanza"]]
		},
		em = {
			self.LUT_BUFF[L["Elixir_Mongoose"]]
		},
		fsp = {
			self.LUT_BUFF[L["Flask_Supreme_Power"]]
		},
		efo = {
			self.LUT_BUFF[L["Elixir_Fortitude"]]
		},
		esp = {
			self.LUT_BUFF[L["Elixir_Shadow_Power"]]
		},
		map = {
			self.LUT_BUFF[L["Mageblood_Potion"]]
		},
		egf = {
			self.LUT_BUFF[L["Elixir_Greater_Firepower"]]
		},
		ft = {
			self.LUT_BUFF[L["Flask_Titans"]]
		},
		esd = {
			self.LUT_BUFF[L["Elixir_Superior_Defense"]]
		},
		gsp = {
			self.LUT_BUFF[L["Greater_Stoneshield_Potion"]]
		},
		wf = {
			self.LUT_BUFF[L["Winterfall_Firewater"]]
		},
		fdw = {
			self.LUT_BUFF[L["Flask_Distilled_Wisdom"]]
		},
		rrbl = {
			self.LUT_BUFF[L["Rumsey_Rum_Black_Label"]]
		},
		jm = {
			self.LUT_BUFF[L["Juju_Might"]]
		},
		jp = {
			self.LUT_BUFF[L["Juju_Power"]]
		},
		wft = {
			self.LUT_BUFF[L["Well_Fed"]]
		},
		wfh = {
			self.LUT_BUFF[L["Nightfin_Soup"]],
			self.LUT_BUFF[L["Sagefish_Delight"]],
		},
		wfm = {
			self.LUT_BUFF[L["Blessed_Sunfruit"]],
			self.LUT_BUFF[L["Grilled_Squid"]],
		},
		wfc = {
			self.LUT_BUFF[L["Runn_Tum_Tuber_Surprise"]],
			self.LUT_BUFF[L["Nightfin_Soup"]],
			self.LUT_BUFF[L["Sagefish_Delight"]],
		},
		ega = {
			self.LUT_BUFF[L["Elixir_Greater_Agility"]]
		},
		fap = {
			self.LUT_BUFF[L["Free_Action_Potion"]]
		},
		sks = {
			L["SlipKik_Savvy"]
		},
		mdm = {
			L["MolDar_Moxie"]
		},
		ff = {
			L["Fengus_Ferocity"]
		},
		ds = {
			L["Dragonslayer"]
		},
		sz = {
			L["Spirit_Zandalar"]
		},
    }
    
    -- initialize necessary table for storing bars etc.
    self.bars = {}
    self.updatebars = compost:Acquire()
    self.buffs = {}
    
    -- Initialize bar textures
    self.textures = {
        [L["Texture"] .. 1] = "Interface\\Addons\\XRS\\images\\statusbar.tga",
        [L["Texture"] .. 2] = "Interface\\Addons\\XRS\\images\\statusbar2.tga",
        [L["Texture"] .. 3] = "Interface\\Addons\\XRS\\images\\statusbar3.tga",
        [L["Texture"] .. 4] = "Interface\\Addons\\XRS\\images\\statusbar4.tga",
        [L["Texture"] .. 5] = "Interface\\Addons\\XRS\\images\\statusbar5.tga",
        [L["Texture"] .. 6] = "Interface\\Addons\\XRS\\images\\statusbar6.tga",
        ["Standard"] = "Interface\\TargetingFrame\\UI-StatusBar",
		["Diagonal"] = "Interface\\Addons\\XRS\\images\\Diagonal.tga",
		["BantoBar"] = "Interface\\Addons\\XRS\\images\\BantoBar.tga",
		["Skewed"] = "Interface\\Addons\\XRS\\images\\Skewed.tga",
    }
    for k,v in pairs(self.textures) do
        self.options.args.texture.validate[v] = k 
    end        
    
    -- Register everything
    self:RegisterDB("XRSDB")
    self:RegisterDefaults('profile', XRS_DEFAULTS )	
    self:RegisterChatCommand({ "/xraidstatus", "/xrs" }, self.options )
    
    if not self.version then self.version = GetAddOnMetadata("XRS", "Version") end
	local rev = string.gsub(GetAddOnMetadata("XRS", "X-Build"), "%$Revision: (%d+) %$", "%1")
	self.version = self.version .. " |cffff8888r"..rev.."|r"
end

function XRS:OnEnable()
    -- Register event to update the raid
    self:RegisterEvent("RAID_ROSTER_UPDATE")
    
    -- One time event to check for a raid ...
    self:RegisterEvent("MEETINGSTONE_CHANGED", "MEETINGSTONE_CHANGED", true)
    self:MEETINGSTONE_CHANGED();
end

function XRS:OnDisable()
    -- no more events to handle
    self:UnregisterAllEvents()
    self:LeaveRaid()
end

--[[--------------------------------------------------------------------------------
  Frame Creation 
-----------------------------------------------------------------------------------]]

function XRS:SetupFrames()
    -- Create Tooltip
    if not self.tooltip then
        self.tooltip = CreateFrame("GameTooltip", "XRSTooltip", UIParent, "GameTooltipTemplate")
        self.tooltip:SetScript("OnLoad",function() this:SetOwner(WorldFrame, "ANCHOR_NONE") end)
    end
	
	-- Create XRS Frame
	self.frame = CreateFrame("Frame", "XRSFrame", UIParent)
	self.frame:EnableMouse(true)
	self.frame:SetFrameStrata("MEDIUM")
	self.frame:SetMovable(true)
	self.frame:SetWidth(130)
    self.frame:SetHeight(100)
    -- Create Font String
    self.xrsfs = self.frame:CreateFontString("$parentTitle","ARTWORK","GameFontNormal")
    self.xrsfs:SetText("XRaidStatus")
    self.xrsfs:SetPoint("TOP",0,-5)
    local tc = self.db.profile.titlecolor
    self.xrsfs:SetTextColor(tc.r,tc.g,tc.b,tc.a)
    self.xrsfs:Show()
    -- Backdrop options
    self.frame:SetBackdrop( { 
      bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", 
      edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 16, edgeSize = 16, 
      insets = { left = 5, right = 5, top = 5, bottom = 5 }
    })
    local boc = self.db.profile.bordercolor
    self.frame:SetBackdropBorderColor(boc.r,boc.g,boc.b,boc.a)
    local bc = self.db.profile.backgroundcolor
	self.frame:SetBackdropColor(bc.r,bc.g,bc.b,bc.a)
	self.frame:ClearAllPoints()
	self.frame:SetPoint("CENTER", WorldFrame, "CENTER", 0, 0)
	self.frame:SetScript("OnMouseDown",function()
        if ( arg1 == "LeftButton" ) then
            if not self.db.profile.Locked then
                this:StartMoving()
            end
		end
    end)
    self.frame:SetScript("OnMouseUp",function()
        if ( arg1 == "LeftButton" ) then
			this:StopMovingOrSizing()
			self:SavePosition()
		end
    end)
    self.frame:SetScript("OnHide",function() this:StopMovingOrSizing() end)
    self.frame:SetScript("OnShow",function() 
                            for _,v in ipairs(self.bars) do
                                if v:GetType() ~= "blank" then
                                    v:UpdateBar()
                                end
                            end
                        end)
                        
    -- Frame cannot be dragged off the screen
    self.frame:SetClampedToScreen(true)
    
    -- Update dewdrop table
    self:UpdateDewdrop()
    
    -- Loads the position of the frame
    self:LoadPosition()
    
    -- The scale from the db
    self:UpdateScale()

    self:Debug("XRS Frame created!")
    
    -- Create a button for raid leader options
    if (IsRaidLeader() or IsRaidOfficer()) then
        self:CreateLeaderMenu()
    end
    
    -- Create all bars and buffs
    self:SetupBars()
    self:SetupBuffs()
	self:SetWidth()
end

--[[--------------------------------------------------------------------------------
  Switch Database
-----------------------------------------------------------------------------------]]

function XRS:OnProfileEnable()
    -- this is called every time your profile changes (after the change)
    for _,v in self.bars do
        v:RemoveBar()
    end
    for _,v in self.buffs do
        v:RemoveBuff()
    end
    
    self.bars = {}
    self.buffs = {}
    
    self:SetupBars()
    self:SetupBuffs()
end

--[[--------------------------------------------------------------------------------
  Event Handling
-----------------------------------------------------------------------------------]]
    
function XRS:RegisterRaidEvents()
    -- Register the WoW events
    self:RegisterBucketEvent("UNIT_HEALTH", self.db.profile.UpdateRate)
    self:RegisterBucketEvent("UNIT_MAXHEALTH", self.db.profile.UpdateRate, "UNIT_HEALTH")
    self:RegisterBucketEvent("UNIT_MANA", self.db.profile.UpdateRate)
    self:RegisterBucketEvent("UNIT_MAXMANA", self.db.profile.UpdateRate, "UNIT_MANA")
    self:RegisterEvent("oRA_AfkDndUpdated", "UpdateAfkBars")
    self:RegisterEvent("RosterLib_RosterChanged", "UpdateAfkBars")
	
	self:Debug("Raid events registered")
end

function XRS:MEETINGSTONE_CHANGED()
    if( GetNumRaidMembers() > 0 ) then
        self:RAID_ROSTER_UPDATE()
    end
end
    
--[[--------------------------------------------------------------------------------
  Main processing
-----------------------------------------------------------------------------------]]

function XRS:RAID_ROSTER_UPDATE()
    if( GetNumRaidMembers() > 0 ) then
        if( not self.inRaid ) then
            self.inRaid = true
            self:RegisterRaidEvents()
            if not self.frame then self:SetupFrames() end
        end
        
        self.frame:Show()
        
        if (IsRaidLeader() or IsRaidOfficer()) then
            self:CreateLeaderMenu()
        else
            self:RemoveLeaderMenu()
        end
        
        for _,v in ipairs(self.bars) do
            if v:GetType() ~= "blank" then
                v:UpdateBar()
            end
        end
    elseif( self.inRaid ) then
        self:LeaveRaid()
    end
end

function XRS:SetupBars()    
    local bt = self.db.profile.barTable
      
    for k,v in bt do
        -- get the data
        local d = bt[k]
        -- create the bar
        local bar = self.bar:new(k, d, self.db.profile.Texture)
        -- add the bar to the bartable
        table.insert(self.bars, bar)
    end
    
    self:RebuildClassBarTable()
end

function XRS:SetupBuffs()
    local bt = self.db.profile.buffTable
      
    for k,v in bt do
        -- create the buff
        local buff = self.buff:new(k-1, v)
        -- add the buff to the bufftable
        table.insert(self.buffs, buff)
    end
    
    self:RebuildClassBarTable()
end

function XRS:RebuildClassBarTable()
    self.life = {}
    self.mana = {}
    self.alive = {}
    self.dead = {}
    self.range = {}
    self.offline = {}
    self.afk = {}
	self.pvp = {}
    
    for k,v in ipairs(self.bars) do
        local classes = v:GetClasses()
        local w = v:GetType()
        
        -- Those types need a constant update, no event and no class specific
        if w == "range" or w == "afk" or w == "pvp" then
            table.insert(self[w], v)
        elseif w ~= "blank" then
            -- add the bar to the class bar table (life, mana, ...) for later access
            for _,i in ipairs(classes) do
                i = string.lower(i)
                if not self[w][i] then self[w][i] = {} end
                table.insert(self[w][i], v)
            end
        end
        
        self:Debug("Bar added: "..w)
    end
    
    if table.getn(self.range) == 0 then
        -- cancel the timer
        self:CancelScheduledEvent("rangeID")
    end
    
	self:SetWidth()
end
    
function XRS:LeaveRaid()
    -- cancel the event to update the bars
    self:CancelScheduledEvent("barsID")
    -- hide the frame
    if self.frame then
        self.frame:Hide()
    end
    -- remove the leader menu (if there is one)
    self:RemoveLeaderMenu()
    
    -- disable all buff icons (own events)
    for k,v in ipairs(self.buffs) do
        v:Disable()
    end
    
    -- nil out everything
    self.bars = {}
    self.buffs = {}
    self.frame = nil
    self.xrsfs = nil
    self.inRaid = nil
end

function XRS:COMBAT_START()
    self.inCombat = TRUE
    self:SetVisual()
end

function XRS:COMBAT_STOP()
    self.inCombat = FALSE
    self:RaidCheck()
    self:SetVisual()
end

function XRS:UNIT_HEALTH(units)
    for unit in pairs(units) do
        _, class = UnitClass(unit)
        if not class then return end
        class = string.lower(class)
        if self.life[class] then
            for _,v in self.life[class] do
                -- Update every bar which is affected by that event and class
                self:AddToQueue(v)
            end
        end
        
        if self.alive[class] then
            for _,v in self.alive[class] do
                self:AddToQueue(v)
            end
        end
        
        if self.dead[class] then
            for _,v in self.dead[class] do
                self:AddToQueue(v)
            end
        end
        
        if self.offline[class] then
            for _,v in self.offline[class] do
                self:AddToQueue(v)
            end
        end
    end
	
	self:UpdateAllBars()
end

function XRS:UNIT_MANA(units)
    for unit in pairs(units) do
        _, class = UnitClass(unit)
        if not class then return end
        class = string.lower(class)
        if self.mana[class] then
            for _,v in self.mana[class] do
                self:AddToQueue(v)
            end
        end
    end
	
	self:UpdateAllBars()
end

function XRS:SavePosition()    
    local scale = self.frame:GetEffectiveScale()
	local worldscale = UIParent:GetEffectiveScale()
	
	local x,y = self.frame:GetLeft()*scale,self.frame:GetTop()*scale - (UIParent:GetTop())*worldscale

	if not self.db.profile.Position then 
		self.db.profile.Position = {}
	end
	
	self.db.profile.Position.x = x
	self.db.profile.Position.y = y
end

function XRS:LoadPosition()
	if(self.db.profile.Position) then
		local x = self.db.profile.Position.x
		local y = self.db.profile.Position.y
		local scale = self.frame:GetEffectiveScale()
		
		self.frame:SetPoint("TOPLEFT", UIParent,"TOPLEFT", x/scale, y/scale)
	else
		self.frame:SetPoint("CENTER", UIParent, "CENTER")
	end
end

function XRS:UpdateScale()
    if self.frame then
        self.frame:SetScale(self.db.profile.Scale)
        self:LoadPosition()
    end
end

function XRS:CreateNewBar()
    local classes = {"Druid"}
    local pos = table.getn(self.db.profile.barTable)+1
    local name = "New bar <"..pos..">"
    local w = "life"
    
    -- Create temp table
    local tempTable = {}
    tempTable.name = name
    tempTable.c = classes
    tempTable.w = w
    
    -- Create the bar
    local bar = self.bar:new(pos, tempTable, self.db.profile.Texture)
    
    -- Add the temp table to the table in the db for saving
    table.insert(self.db.profile.barTable, pos, tempTable)
    table.insert(self.bars, bar)
    
    -- Update class bar table
    self:RebuildClassBarTable()
end

-- Delete the specified bar
function XRS:DeleteBar(bar)
    for k,v in self.bars do
        if v == bar then
            table.remove(self.bars, k)
            table.remove(self.db.profile.barTable, k)
        end
    end
    
    -- Update class bar table
    self:RebuildClassBarTable()
    
    -- Update visual position
    for k,v in self.bars do
        v:SetPosition(k)
    end
end

-- Save the configuration
function XRS:SaveConfiguration(name)
    -- Save configuration into the db
    if not self.db.profile.configs then self.db.profile.configs = {} end
    self.db.profile.configs[name] = {}
    self:TableCopy(self.db.profile.barTable, self.db.profile.configs[name])
    
    -- Update dewdrop
    XRS:UpdateDewdrop()
end

-- Load the configuration
function XRS:LoadConfiguration(name)
    for k,v in self.bars do
        v:RemoveBar()
    end
    
    self.bars = {}
    self.db.profile.barTable = {}
    
    self:TableCopy(self.db.profile.configs[name], self.db.profile.barTable)

    self:SetupBars()
end

-- A helper function to copy tables
function XRS:TableCopy(from, to)
    for k,v in from do
        if type(v)=="table" then
            to[k] = {}
            self:TableCopy(from[k], to[k])
        else
            to[k] = v
        end
    end
end

-- Delete the configuration
function XRS:DeleteConfiguration(name)
    self.db.profile.configs[name] = nil
    
    -- Update dewdrop
    XRS:UpdateDewdrop()
end

-- Update dewdrop table
function XRS:UpdateDewdrop()
    -- Init the load configuration category
	local count = 1
	if self.db.profile.configs then
	    self.options.args.load.args = {}
	    self.options.args.delete.args = {}
    	for k,_ in self.db.profile.configs do
    	    local string_count = tostring(count)
    	    local val = k
    	    self.options.args.load.args[string_count] = {}
    	    self.options.args.load.args[string_count].name = k
    	    self.options.args.load.args[string_count].type = "execute"
    	    self.options.args.load.args[string_count].desc = "Load "..k
    	    self.options.args.load.args[string_count].func = function() self:LoadConfiguration(val) end
    	    
    	    self.options.args.delete.args[string_count] = {}
    	    self.options.args.delete.args[string_count].name = k
    	    self.options.args.delete.args[string_count].type = "execute"
    	    self.options.args.delete.args[string_count].desc = "Load "..k
    	    self.options.args.delete.args[string_count].func = function() self:DeleteConfiguration(val) end
    	    count = count + 1
        end
    end

    dewdrop:Register(self.frame, 'children', self.options)
end

-- Move the bar up
function XRS:BarUp(bar)
    local pos = bar:GetPosition()
    local bt = self.db.profile.barTable
    
    if bar:GetPosition() == 1 then return end
    
    self.bars[pos], self.bars[pos-1] = self.bars[pos-1], self.bars[pos]
    bt[pos], bt[pos-1] = bt[pos-1], bt[pos]
    
    self.bars[pos]:SetPosition(pos)
    self.bars[pos-1]:SetPosition(pos-1)
end

-- Move the bar down
function XRS:BarDown(bar)
    local pos = bar:GetPosition()
    local bt = self.db.profile.barTable
    
    if bar:GetPosition() == table.getn(self.bars) then return end
    
    self.bars[pos], self.bars[pos+1] = self.bars[pos+1], self.bars[pos]
    bt[pos], bt[pos+1] = bt[pos+1], bt[pos]
    
    self.bars[pos]:SetPosition(pos)
    self.bars[pos+1]:SetPosition(pos+1)
end

-- Create a button for raid leader options
function XRS:CreateLeaderMenu()
    if not self.leaderbutton then
        self.leaderbutton = CreateFrame("Button", nil, self.frame)
        self.leaderbutton:SetWidth(16)
        self.leaderbutton:SetHeight(16)
        self.leaderbutton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up")
        self.leaderbutton:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Down") 
        self.leaderbutton:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
        self.leaderbutton:SetScript("OnClick",function() dewdrop:Open(self.leaderbutton) end)
        self.leaderbutton:ClearAllPoints()
        self.leaderbutton:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 5, -5)
        
        -- Register dewdrop
        dewdrop:Register(self.leaderbutton, 'dontHook', true, 'children', function(level, value) self:CreateDDLeaderMenu(level, value) end)
        
        self.leaderbutton:Show()
        
        self:Debug("Leader Button created!")
    end
end

-- Removes the button if the player is not a raid leader
function XRS:RemoveLeaderMenu()
    if self.leaderbutton then
        self.leaderbutton:Hide()
        dewdrop:Unregister(self.leaderbutton)
        self.leaderbutton = nil
    end
end

function XRS:CreateDDLeaderMenu(level, value)
    -- Create drewdrop menu
    if level == 1 then
        dewdrop:AddLine( 'text', L["Raid_Leader_Options"], 'isTitle', true )
        dewdrop:AddLine( 'text', L["Buff_Check"],
            			 'hasArrow', true,
            			 'value', "bc",
            			 'tooltipTitle', L["Buff_Check"],
            			 'tooltipText', L["Buff_Check_TTText"]
            		  )
        dewdrop:AddLine( 'text', L["Ready_Check"],
                         'func', function()
                            DoReadyCheck()
                         end,
                         'tooltipTitle', L["Ready_Check"],
            			 'tooltipText', L["Ready_Check_TTText"]
                      )
    elseif level == 2 then
        if value == "bc" then
            dewdrop:AddLine( 'text', L["Select_Buffs"],
            			 'hasArrow', true,
            			 'value', "buffs",
            			 'tooltipTitle', L["Select_Buffs"],
            			 'tooltipText', L["Select_Buffs_TTText"]
            		  )
            dewdrop:AddLine( 'text', L["Start_Check"],
                         'func', function()
                            XRS:BuffCheck()
                         end,
                         'tooltipTitle', L["Start_Check"],
            			 'tooltipText', L["Start_Check_TTText"]
                      )
        end
    elseif level == 3 then    
        if value == "buffs" then
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
			dewdrop:AddLine( 'text', BS["Arcane Intellect"],
							 'checked', self.db.profile.buffcheck.ai,
							 'func', function() self.db.profile.buffcheck.ai = not self.db.profile.buffcheck.ai end)
			dewdrop:AddLine( 'text', BS["Mark of the Wild"],
							 'checked', self.db.profile.buffcheck.motw,
							 'func', function() self.db.profile.buffcheck.motw = not self.db.profile.buffcheck.motw end)
			dewdrop:AddLine( 'text', BS["Power Word: Fortitude"],
							 'checked', self.db.profile.buffcheck.sta,
							 'func', function() self.db.profile.buffcheck.sta = not self.db.profile.buffcheck.sta end)
			dewdrop:AddLine( 'text', BS["Divine Spirit"],
							 'checked', self.db.profile.buffcheck.spi,
							 'func', function() self.db.profile.buffcheck.spi = not self.db.profile.buffcheck.spi end)
			dewdrop:AddLine( 'text', BS["Shadow Protection"],
							 'checked', self.db.profile.buffcheck.sp,
							 'func', function() self.db.profile.buffcheck.sp = not self.db.profile.buffcheck.sp end)
			
			dewdrop:AddLine( 'text', L["Raid_Buff"], 'isTitle', true )
			dewdrop:AddLine( 'text', L["Spirit_Zanza"],
							 'checked', self.db.profile.buffcheck.spz,
							 'func', function() self.db.profile.buffcheck.spz = not self.db.profile.buffcheck.spz end)
			dewdrop:AddLine( 'text', L["Swiftness_Zanza"],
							 'checked', self.db.profile.buffcheck.swz,
							 'func', function() self.db.profile.buffcheck.swz = not self.db.profile.buffcheck.swz end)
			dewdrop:AddLine( 'text', L["Spirit_Zandalar"],
							 'checked', self.db.profile.buffcheck.sz,
							 'func', function() self.db.profile.buffcheck.sz = not self.db.profile.buffcheck.sz end)
			dewdrop:AddLine( 'text', L["Dragonslayer"],
							 'checked', self.db.profile.buffcheck.ds,
							 'func', function() self.db.profile.buffcheck.ds = not self.db.profile.buffcheck.ds end)
			dewdrop:AddLine( 'text', L["SlipKik_Savvy"],
							 'checked', self.db.profile.buffcheck.sks,
							 'func', function() self.db.profile.buffcheck.sks = not self.db.profile.buffcheck.sks end)
			dewdrop:AddLine( 'text', L["MolDar_Moxie"],
							 'checked', self.db.profile.buffcheck.mdm,
							 'func', function() self.db.profile.buffcheck.mdm = not self.db.profile.buffcheck.mdm end)
			dewdrop:AddLine( 'text', L["Fengus_Ferocity"],
							 'checked', self.db.profile.buffcheck.ff,
							 'func', function() self.db.profile.buffcheck.ff = not self.db.profile.buffcheck.ff end)
			
			dewdrop:AddLine( 'text', L["Protection_Potion"], 'isTitle', true )
			dewdrop:AddLine( 'text', L["Arcane_Protection_Potion"],
							 'checked', self.db.profile.buffcheck.app,
							 'func', function() self.db.profile.buffcheck.app = not self.db.profile.buffcheck.app end)
			dewdrop:AddLine( 'text', L["Fire_Protection_Potion"],
							 'checked', self.db.profile.buffcheck.fpp,
							 'func', function() self.db.profile.buffcheck.fpp = not self.db.profile.buffcheck.fpp end)
			dewdrop:AddLine( 'text', L["Frost_Protection_Potion"],
							 'checked', self.db.profile.buffcheck.frpp,
							 'func', function() self.db.profile.buffcheck.frpp = not self.db.profile.buffcheck.frpp end)
			dewdrop:AddLine( 'text', L["Nature_Protection_Potion"],
							 'checked', self.db.profile.buffcheck.npp,
							 'func', function() self.db.profile.buffcheck.npp = not self.db.profile.buffcheck.npp end)
			dewdrop:AddLine( 'text', L["Shadow_Protection_Potion"],
							 'checked', self.db.profile.buffcheck.spp,
							 'func', function() self.db.profile.buffcheck.spp = not self.db.profile.buffcheck.spp end)
		
		elseif value == "tank_conso" then
			dewdrop:AddLine( 'text', L["Elixir_Superior_Defense"],
							 'checked', self.db.profile.buffcheck.esd,
							 'func', function() self.db.profile.buffcheck.esd = not self.db.profile.buffcheck.esd end)
			dewdrop:AddLine( 'text', L["Elixir_Fortitude"],
							 'checked', self.db.profile.buffcheck.efo,
							 'func', function() self.db.profile.buffcheck.efo = not self.db.profile.buffcheck.efo end)
			dewdrop:AddLine( 'text', L["Flask_Titans"],
							 'checked', self.db.profile.buffcheck.ft,
							 'func', function() self.db.profile.buffcheck.ft = not self.db.profile.buffcheck.ft end)
			dewdrop:AddLine( 'text', L["Well_Fed"],
							 'checked', self.db.profile.buffcheck.wft,
							 'func', function() self.db.profile.buffcheck.wft = not self.db.profile.buffcheck.wft end)
			dewdrop:AddLine( 'text', L["Elixir_Greater_Agility"],
							 'checked', self.db.profile.buffcheck.ega,
							 'func', function() self.db.profile.buffcheck.ega = not self.db.profile.buffcheck.ega end)
			dewdrop:AddLine( 'text', L["Rumsey_Rum_Black_Label"],
							 'checked', self.db.profile.buffcheck.rrbl,
							 'func', function() self.db.profile.buffcheck.rrbl = not self.db.profile.buffcheck.rrbl end)
							 
		elseif value == "healer_conso" then
			dewdrop:AddLine( 'text', L["Mageblood_Potion"],
							 'checked', self.db.profile.buffcheck.map,
							 'func', function() self.db.profile.buffcheck.map = not self.db.profile.buffcheck.map end)
			dewdrop:AddLine( 'text', L["Well_Fed"],
							 'checked', self.db.profile.buffcheck.wfh,
							 'func', function() self.db.profile.buffcheck.wfh = not self.db.profile.buffcheck.wfh end)
			dewdrop:AddLine( 'text', L["Flask_Distilled_Wisdom"],
							 'checked', self.db.profile.buffcheck.fdw,
							 'func', function() self.db.profile.buffcheck.fdw = not self.db.profile.buffcheck.fdw end)
			
		elseif value == "melee_conso" then
			dewdrop:AddLine( 'text', L["Elixir_Mongoose"],
							 'checked', self.db.profile.buffcheck.em,
							 'func', function() self.db.profile.buffcheck.em = not self.db.profile.buffcheck.em end)
			dewdrop:AddLine( 'text', L["Winterfall_Firewater"],
							 'checked', self.db.profile.buffcheck.wf,
							 'func', function() self.db.profile.buffcheck.wf = not self.db.profile.buffcheck.wf end)
			dewdrop:AddLine( 'text', L["Juju_Might"],
							 'checked', self.db.profile.buffcheck.jm,
							 'func', function() self.db.profile.buffcheck.jm = not self.db.profile.buffcheck.jm end)
			dewdrop:AddLine( 'text', L["Juju_Power"],
							 'checked', self.db.profile.buffcheck.jp,
							 'func', function() self.db.profile.buffcheck.jp = not self.db.profile.buffcheck.jp end)
			dewdrop:AddLine( 'text', L["Well_Fed"],
							 'checked', self.db.profile.buffcheck.wfm,
							 'func', function() self.db.profile.buffcheck.wfm = not self.db.profile.buffcheck.wfm end)
							 
		elseif value == "caster_conso" then
			dewdrop:AddLine( 'text', L["Greater_Arcane_Elixir"],
							 'checked', self.db.profile.buffcheck.gae,
							 'func', function() self.db.profile.buffcheck.gae = not self.db.profile.buffcheck.gae end)
			dewdrop:AddLine( 'text', L["Elixir_Frost_Power"],
							 'checked', self.db.profile.buffcheck.efp,
							 'func', function() self.db.profile.buffcheck.efp = not self.db.profile.buffcheck.efp end)
			dewdrop:AddLine( 'text', L["Elixir_Greater_Firepower"],
							 'checked', self.db.profile.buffcheck.egf,
							 'func', function() self.db.profile.buffcheck.egf = not self.db.profile.buffcheck.egf end)
			dewdrop:AddLine( 'text', L["Elixir_Shadow_Power"],
							 'checked', self.db.profile.buffcheck.esp,
							 'func', function() self.db.profile.buffcheck.esp = not self.db.profile.buffcheck.esp end)
			dewdrop:AddLine( 'text', L["Mageblood_Potion"],
							 'checked', self.db.profile.buffcheck.map,
							 'func', function() self.db.profile.buffcheck.map = not self.db.profile.buffcheck.map end)
			dewdrop:AddLine( 'text', L["Well_Fed"],
							 'checked', self.db.profile.buffcheck.wfc,
							 'func', function() self.db.profile.buffcheck.wfc = not self.db.profile.buffcheck.wfc end)
			dewdrop:AddLine( 'text', L["Flask_Supreme_Power"],
							 'checked', self.db.profile.buffcheck.fsp,
							 'func', function() self.db.profile.buffcheck.fsp = not self.db.profile.buffcheck.fsp end)
		end
	
	end			
end

-- Starts the buff check
function XRS:BuffCheck()
    if not IsRaidLeader() and not IsRaidOfficer() then return end
    local missingTable = compost:Acquire()
    
    local bt = self.buffTable
	
	for num=1,40 do
	   if (UnitExists("raid"..num) and UnitIsConnected("raid"..num)) then
            local raidname = UnitName("raid"..num)
	        if self.db.profile.buffcheck.sta then
    	        if not missingTable.sta then missingTable.sta = {} end
                local b1, b2 = self:AuraScan("raid"..num, bt.sta)
                if (not (b1 or b2)) then table.insert(missingTable.sta, raidname) end
            end
            
            if self.db.profile.buffcheck.motw then
                if not missingTable.motw then missingTable.motw = { } end
                b1, b2 = self:AuraScan("raid"..num, bt.motw)
                if (not (b1 or b2)) then table.insert(missingTable.motw, raidname) end
            end
            
            if self.db.profile.buffcheck.sp then
                if not missingTable.sp then missingTable.sp = { } end
                b1, b2 = self:AuraScan("raid"..num, bt.sp)
                if (not (b1 or b2)) then table.insert(missingTable.sp, raidname) end
            end
			
			if self.db.profile.buffcheck.mdm then
                    if not missingTable.mdm then missingTable.mdm = { } end
                    b1, b2 = self:AuraScan("raid"..num, bt.mdm)
                    if (not (b1 or b2)) then table.insert(missingTable.mdm, raidname) end
            end
			
			if self.db.profile.buffcheck.ds then
                    if not missingTable.ds then missingTable.ds = { } end
                    b1, b2 = self:AuraScan("raid"..num, bt.ds)
                    if (not (b1 or b2)) then table.insert(missingTable.ds, raidname) end
            end
			
			if self.db.profile.buffcheck.sz then
                    if not missingTable.sz then missingTable.sz = { } end
                    b1, b2 = self:AuraScan("raid"..num, bt.sz)
                    if (not (b1 or b2)) then table.insert(missingTable.sz, raidname) end
            end
			
			if self.db.profile.buffcheck.swz then
                    if not missingTable.swz then missingTable.swz = { } end
                    b1, b2 = self:AuraScan("raid"..num, bt.swz)
                    if (not (b1 or b2)) then table.insert(missingTable.swz, raidname) end
            end
			
			if self.db.profile.buffcheck.spz then
                    if not missingTable.spz then missingTable.spz = { } end
                    b1, b2 = self:AuraScan("raid"..num, bt.spz)
                    if (not (b1 or b2)) then table.insert(missingTable.spz, raidname) end
            end
			
			if self.db.profile.buffcheck.app then
                    if not missingTable.app then missingTable.app = { } end
                    b1, b2 = self:AuraScan("raid"..num, bt.app)
                    if (not (b1 or b2)) then table.insert(missingTable.app, raidname) end
            end
			
			if self.db.profile.buffcheck.fpp then
                    if not missingTable.fpp then missingTable.fpp = { } end
                    b1, b2 = self:AuraScan("raid"..num, bt.fpp)
                    if (not (b1 or b2)) then table.insert(missingTable.fpp, raidname) end
            end
			
			if self.db.profile.buffcheck.frpp then
                    if not missingTable.frpp then missingTable.frpp = { } end
                    b1, b2 = self:AuraScan("raid"..num, bt.frpp)
                    if (not (b1 or b2)) then table.insert(missingTable.frpp, raidname) end
            end
			
			if self.db.profile.buffcheck.npp then
                    if not missingTable.npp then missingTable.npp = { } end
                    b1, b2 = self:AuraScan("raid"..num, bt.npp)
                    if (not (b1 or b2)) then table.insert(missingTable.npp, raidname) end
            end
			
			if self.db.profile.buffcheck.spp then
                    if not missingTable.spp then missingTable.spp = { } end
                    b1, b2 = self:AuraScan("raid"..num, bt.spp)
                    if (not (b1 or b2)) then table.insert(missingTable.spp, raidname) end
            end
            
            local _, class = UnitClass("raid"..num) 
            if (class ~= "WARRIOR" and class ~= "ROGUE") then
                if self.db.profile.buffcheck.spi then
                    if not missingTable.spi then missingTable.spi = { } end
                    b1, b2 = self:AuraScan("raid"..num, bt.spi)
                    if (not (b1 or b2)) then table.insert(missingTable.spi, raidname) end
                end
                
                if self.db.profile.buffcheck.ai then
                    if not missingTable.ai then missingTable.ai = { } end
                    b1, b2 = self:AuraScan("raid"..num, bt.ai)
                    if (not (b1 or b2)) then table.insert(missingTable.ai, raidname) end
                end
            end
			if (class == "SHAMAN" or class == "DRUIDE" or class == "PRIEST" or class == "PALADIN") then
				if self.db.profile.buffcheck.map then
                    if not missingTable.map then missingTable.map = { } end
                    b1, b2 = self:AuraScan("raid"..num, bt.map)
                    if (not (b1 or b2)) then table.insert(missingTable.map, raidname) end
				end
				if self.db.profile.buffcheck.wfh then
                    if not missingTable.wfh then missingTable.wfh = { } end
                    b1, b2 = self:AuraScan("raid"..num, bt.wfh)
                    if (not (b1 or b2)) then table.insert(missingTable.wfh, raidname) end
				end
				if self.db.profile.buffcheck.fdw then
                    if not missingTable.fdw then missingTable.fdw = { } end
                    b1, b2 = self:AuraScan("raid"..num, bt.fdw)
                    if (not (b1 or b2)) then table.insert(missingTable.fdw, raidname) end
				end
			end
			if (class == "HUNT") then
				if self.db.profile.buffcheck.jm then
                    if not missingTable.jm then missingTable.jm = { } end
                    b1, b2 = self:AuraScan("raid"..num, bt.jm)
                    if (not (b1 or b2)) then table.insert(missingTable.jm, raidname) end
				end
				if self.db.profile.buffcheck.em then
                    if not missingTable.em then missingTable.em = { } end
                    b1, b2 = self:AuraScan("raid"..num, bt.em)
                    if (not (b1 or b2)) then table.insert(missingTable.em, raidname) end
				end
				if self.db.profile.buffcheck.wfm then
                    if not missingTable.wfm then missingTable.wfm = { } end
                    b1, b2 = self:AuraScan("raid"..num, bt.wfm)
                    if (not (b1 or b2)) then table.insert(missingTable.wfm, raidname) end
				end
			end
			if (class == "MAGE") then
				if self.db.profile.buffcheck.efp then
                    if not missingTable.efp then missingTable.efp = { } end
                    b1, b2 = self:AuraScan("raid"..num, bt.efp)
                    if (not (b1 or b2)) then table.insert(missingTable.efp, raidname) end
				end
				if self.db.profile.buffcheck.egf then
                    if not missingTable.egf then missingTable.egf = { } end
                    b1, b2 = self:AuraScan("raid"..num, bt.egf)
                    if (not (b1 or b2)) then table.insert(missingTable.egf, raidname) end
				end
				if self.db.profile.buffcheck.gae then
                    if not missingTable.gae then missingTable.gae = { } end
                    b1, b2 = self:AuraScan("raid"..num, bt.gae)
                    if (not (b1 or b2)) then table.insert(missingTable.gae, raidname) end
				end
				if self.db.profile.buffcheck.map then
                    if not missingTable.map then missingTable.map = { } end
                    b1, b2 = self:AuraScan("raid"..num, bt.map)
                    if (not (b1 or b2)) then table.insert(missingTable.map, raidname) end
				end
				if self.db.profile.buffcheck.wfc then
                    if not missingTable.wfc then missingTable.wfc = { } end
                    b1, b2 = self:AuraScan("raid"..num, bt.wfc)
                    if (not (b1 or b2)) then table.insert(missingTable.wfc, raidname) end
				end
				if self.db.profile.buffcheck.fsp then
                    if not missingTable.fsp then missingTable.fsp = { } end
                    b1, b2 = self:AuraScan("raid"..num, bt.fsp)
                    if (not (b1 or b2)) then table.insert(missingTable.fsp, raidname) end
				end
			end
			if (class == "ROGUE") then
				if self.db.profile.buffcheck.jm then
                    if not missingTable.jm then missingTable.jm = { } end
                    b1, b2 = self:AuraScan("raid"..num, bt.jm)
                    if (not (b1 or b2)) then table.insert(missingTable.jm, raidname) end
				end
				if self.db.profile.buffcheck.jp then
                    if not missingTable.jp then missingTable.jp = { } end
                    b1, b2 = self:AuraScan("raid"..num, bt.jp)
                    if (not (b1 or b2)) then table.insert(missingTable.jp, raidname) end
				end
				if self.db.profile.buffcheck.em then
                    if not missingTable.em then missingTable.em = { } end
                    b1, b2 = self:AuraScan("raid"..num, bt.em)
                    if (not (b1 or b2)) then table.insert(missingTable.em, raidname) end
				end
				if self.db.profile.buffcheck.wfm then
                    if not missingTable.wfm then missingTable.wfm = { } end
                    b1, b2 = self:AuraScan("raid"..num, bt.wfm)
                    if (not (b1 or b2)) then table.insert(missingTable.wfm, raidname) end
				end
			end
			if (class == "WARLOCK") then
				if self.db.profile.buffcheck.esp then
                    if not missingTable.esp then missingTable.esp = { } end
                    b1, b2 = self:AuraScan("raid"..num, bt.esp)
                    if (not (b1 or b2)) then table.insert(missingTable.esp, raidname) end
				end
				if self.db.profile.buffcheck.gae then
                    if not missingTable.gae then missingTable.gae = { } end
                    b1, b2 = self:AuraScan("raid"..num, bt.gae)
                    if (not (b1 or b2)) then table.insert(missingTable.gae, raidname) end
				end
				if self.db.profile.buffcheck.wfc then
                    if not missingTable.wfc then missingTable.wfc = { } end
                    b1, b2 = self:AuraScan("raid"..num, bt.wfc)
                    if (not (b1 or b2)) then table.insert(missingTable.wfc, raidname) end
				end
				if self.db.profile.buffcheck.fsp then
                    if not missingTable.fsp then missingTable.fsp = { } end
                    b1, b2 = self:AuraScan("raid"..num, bt.fsp)
                    if (not (b1 or b2)) then table.insert(missingTable.fsp, raidname) end
				end
			end
			if (class == "WARRIOR") then
				if self.db.profile.buffcheck.esd then
                    if not missingTable.esd then missingTable.esd = { } end
                    b1, b2 = self:AuraScan("raid"..num, bt.esd)
                    if (not (b1 or b2)) then table.insert(missingTable.esd, raidname) end
				end
				if self.db.profile.buffcheck.efo then
                    if not missingTable.efo then missingTable.efo = { } end
                    b1, b2 = self:AuraScan("raid"..num, bt.efo)
                    if (not (b1 or b2)) then table.insert(missingTable.efo, raidname) end
				end
				if self.db.profile.buffcheck.ft then
                    if not missingTable.ft then missingTable.ft = { } end
                    b1, b2 = self:AuraScan("raid"..num, bt.ft)
                    if (not (b1 or b2)) then table.insert(missingTable.ft, raidname) end
				end
				if self.db.profile.buffcheck.wft then
                    if not missingTable.wft then missingTable.wft = { } end
                    b1, b2 = self:AuraScan("raid"..num, bt.wft)
                    if (not (b1 or b2)) then table.insert(missingTable.wft, raidname) end
				end
				if self.db.profile.buffcheck.ega then
                    if not missingTable.ega then missingTable.ega = { } end
                    b1, b2 = self:AuraScan("raid"..num, bt.ega)
                    if (not (b1 or b2)) then table.insert(missingTable.ega, raidname) end
				end
				if self.db.profile.buffcheck.rrbl then
                    if not missingTable.rrbl then missingTable.rrbl = { } end
                    b1, b2 = self:AuraScan("raid"..num, bt.rrbl)
                    if (not (b1 or b2)) then table.insert(missingTable.rrbl, raidname) end
				end	
			end
       end 
    end
    
    self:OutputBuffCheck(missingTable)
    compost:Reclaim(missingTable)
    missingTable = nil
end

-- Helper function to check for missing buffs
function XRS:AuraScan(u, db)
   t = "XRSTooltip" local tdb = {}
   getglobal(t):SetOwner(WorldFrame, "ANCHOR_NONE");
   if type(u) ~= "string" then
      db = u u = "player"
   end
   for k, v in db do local n, b = 1
      local fnd = function(f, txt, n)
         getglobal(t):ClearLines()
         getglobal(t)[f](getglobal(t), u, n)
         b = getglobal(t..txt):GetText()
         if strfind(b or "", v) then
            tinsert(tdb, k, n)
         end
      end
      while UnitBuff(u, n) do
         if fnd("SetUnitBuff",
            "TextLeft1", n) then break
         end
         n = n + 1
      end
      n = 1
   end
   return unpack(tdb)
end

-- Output the table to the raid chat
function XRS:OutputBuffCheck(tbl)
    local count = 0
    for k,v in tbl do
        count = count + table.getn(tbl[k])
    end
    
    if (count==0) then self:RaidOutput("XRS :: "..L["No Buffs Needed!"]) return end
    if (count>0) then self:RaidOutput("XRS :: "..count..L[" missing buffs."]) end
    
    for k,v in tbl do
        if table.getn(tbl[k]) > 0 then
            local msg = "<"..self.buffTable[k][1].."> : "
            msg = msg..table.concat(tbl[k], ", ")
            self:RaidOutput(msg)
        end
    end
end

-- Message output to the raid frame
function XRS:RaidOutput(msg)
    SendChatMessage(msg, "RAID")
	DEFAULT_CHAT_FRAME:AddMessage(msg)
end

-- Sets the bar textures of every bar
function XRS:SetBarTexture(name)
    self.db.profile.Texture = name
    for _,v in ipairs(self.bars)do
        v:SetBarTexture(name)        
    end
end

-- Updates the Background Color of the main frame
function XRS:UpdateBackgroundColor(r,g,b,a)
    local bc = self.db.profile.backgroundcolor
    bc.r, bc.g, bc.b, bc.a = r, g, b, a
	self.frame:SetBackdropColor(r,g,b,a)
end

-- Updates the Title Color
function XRS:UpdateTitleColor(r,g,b,a)
    local tc = self.db.profile.titlecolor
    tc.r, tc.g, tc.b, tc.a = r, g, b, a
    self.xrsfs:SetTextColor(r,g,b,a)
end

-- Updates the Border Color
function XRS:UpdateBorderColor(r,g,b,a)
    local boc = self.db.profile.bordercolor
    boc.r, boc.g, boc.b, boc.a = r, g, b, a
    self.frame:SetBackdropBorderColor(r,g,b,a)
end

function XRS:ModifyUpdateRate(rate)
    self.db.profile.UpdateRate = rate

    local registered = self:IsBucketEventRegistered("UNIT_HEALTH")
    if registered then
        self:RegisterBucketEvent("UNIT_HEALTH", rate)
        self:RegisterBucketEvent("UNIT_MAXHEALTH", rate, "UNIT_HEALTH")
        self:RegisterBucketEvent("UNIT_MANA", rate)
        self:RegisterBucketEvent("UNIT_MAXMANA", rate, "UNIT_MANA")
    end
end

-- Add the bar to the queue to update it later
function XRS:AddToQueue(bar)
    if not self:AlreadyQueued(bar) then self.updatebars[bar] = bar end
end

-- Checks if the bar is already queued for an update
function XRS:AlreadyQueued(bar)
    if self.updatebars[bar] then return true end
    return false
end

-- Update all bars where an event occured
--local inittime, initmem, endtime, endmem
function XRS:UpdateAllBars()
	--inittime, initmem = GetTime(), gcinfo()
    for _,v in pairs(self.updatebars) do
        v:UpdateBar()
    end
    for _,v in ipairs(self.range) do
        v:UpdateBar()
    end
	for _,v in ipairs(self.pvp) do
        v:UpdateBar()
    end
    self.updatebars = compost:Erase(self.updatebars)
	--endtime, endmem = GetTime(), gcinfo()
	--self:Debug(string.format("%s - %s (%s / %s)", endmem-initmem, endtime-inittime, initmem, endmem)) 
end

-- Create a new buff button
function XRS:CreateNewBuffButton()
    local classes = {"Druid"}
    local buffs = {BS["Power Word: Fortitude"], BS["Prayer of Fortitude"]}
    
    -- Create temp table
    local tempTable = {}
    tempTable.c = classes
    tempTable.buffs = buffs
    
    local position = table.getn(self.buffs)
    
    table.insert(self.db.profile.buffTable, tempTable)
    table.insert(self.buffs, self.buff:new(position, tempTable))
    
    -- Update class bar table
    self:RebuildClassBarTable()
end

-- Delete the specified bar
function XRS:DeleteBuff(buff)
    for k,v in self.buffs do
        if v == buff then
            table.remove(self.buffs, k)
            table.remove(self.db.profile.buffTable, k)
            break
        end
    end
    
    -- Update class bar table
    self:RebuildClassBarTable()
    
    -- Update visual position
    for k,v in self.buffs do
        v:SetPosition(k)
    end
end

-- Press a button to buff the raid
function XRS:BuffButtonPress()
    if not self.inRaid then return end
    _, class = UnitClass("player")
    if (class=="DRUID") then self:BuffRaid(BS["Mark of the Wild"])
    elseif (class=="PRIEST") then self:BuffRaid(BS["Power Word: Fortitude"])
    elseif (class=="MAGE") then self:BuffRaid(BS["Arcane Intellect"])
    end
end

function XRS:BuffSelf(spell, itemUse)
	
	local buff_name = self.LUT_BUFF[spell]
	if buff_name == nil then return end
	local hasBuff=0
	local strbuff, ind, namebuff = self:FindBuffXRS(buff_name, 'player', nil)
	if (ind) then hasBuff = 1 end	
	local bag = 0
	local slot = 0
	local totalcount = 0
	for i = 4, 0, -1 do
		local bagSlot = GetContainerNumSlots(i)
		if bagSlot > 0 then
			for j=1, bagSlot do
				local texture, itemCount = GetContainerItemInfo(i, j)
				if (itemCount) then
					local itemLink = GetContainerItemLink(i,j)
					local _, _, itemCode = strfind(itemLink, "(%d+):")
					local itemName, _, _, _, _, _ = GetItemInfo(itemCode)
					if itemName == spell then
						bag = i
						slot = j
						_, count = GetContainerItemInfo(i,j)
						totalcount = totalcount + count
						
					end
				end
			end
		end
	end
	if hasBuff==1 then 
		self:Print(string.format("%s", crayon:Silver( L["BUFF_PRESENT"] .. " " .. buff_name .. " ( " .. floor(GetPlayerBuffTimeLeft(ind-1)/60) .. "min" .. floor(math.mod(GetPlayerBuffTimeLeft(ind-1) ,60)) .. "s " .. L["Remaining"] .. " )")))
		self:Print(string.format("%s", crayon:Silver(totalcount .. " " .. spell .. " " .. L["In_Bags"])))
	else
		if(itemUse==1 and totalcount > 0 ) then
			UseContainerItem(bag, slot , 1)
			self:Print(string.format("%s", crayon:Silver(L["Buff_Now"] .. " " .. spell .." (" .. totalcount - 1 .. " " .. L["Remaining"] .. " " .. L["In_Bags"] .. ")")))
		else
			self:Print(string.format("%s", crayon:Silver(totalcount .. " " .. spell .. " " .. L["In_Bags"])))
		end
	end
end



local buffRaidPosition = 1
function XRS:BuffRaid(spell, buffClass)
	local selfCast = GetCVar("autoSelfCast")
	SetCVar("autoSelfCast", "0")
    if not buffClass then
        for _,v in self.buffs do
            local buffs = v:GetBuffs()
            for _, i in buffs do
                if i == spell then
                    buffClass = v
                    break
                end
            end
        end
    end

    if buffClass then
        local bt = buffClass:GetBuffTable()
        
        if buffRaidPosition >= 40 then buffRaidPosition = 1 end
        local initialTarget = UnitName("target")
        local isEnemy = UnitIsEnemy("player","target")
        ClearTarget()
        CastSpellByName(spell)
        
        for i=buffRaidPosition, 40 do
            local raidID = "raid"..i
            buffRaidPosition = i
            if bt[raidID] == false and UnitIsVisible(raidID) and SpellCanTargetUnit(raidID) then
                local _, class = UnitClass(raidID)
                local _, _, subgroup, _, _, _, _, online, isDead = GetRaidRosterInfo(i)
                if buffClass:IsGroup(subgroup) and buffClass:IsClass(class) then
                    self:Print(string.format("%s: %s", crayon:Silver(UnitName(raidID)), crayon:Orange(spell)))
                    SpellTargetUnit(raidID)
                    buffRaidPosition = i + 1
                    break
                end
            end
        end
        
        if SpellIsTargeting() then SpellStopCasting() end
        self:ReTarget(initialTarget, isEnemy)
    end
	SetCVar("autoSelfCast", selfCast)
end

function XRS:ReTarget(initialTarget, isEnemy)
    -- all that follows simply attempts to return back to original target
    if isEnemy then
        -- if a friendly wasn't targetted, we can return to them reliably
        TargetLastEnemy()
    elseif not initialTarget then
        -- if no initial target, clear target
        ClearTarget()
    else
        TargetByName(initialTarget)
        -- attempt to target initial target
        if UnitName("target")~=initialTarget then
            -- if attempt failed, scan through raid to target by raid unit
            for i=1,40 do
                if UnitName("raid"..i)==initialTarget then
                    TargetUnit("raid"..i)
                end
            end
            if UnitName("target")~=initialTarget then
                -- if we still failed, clear target. possible if a pet was out of range
                ClearTarget()
            end
        end
    end
end

function XRS:FindBuffXRS( obuff, unit, item)
	if not Tooltip_buff then
        Tooltip_buff = CreateFrame("GameTooltip", "XRS_Buff_Tooltip", UIParent, "GameTooltipTemplate")
		Tooltip_buff:Hide()
        Tooltip_buff:SetScript("OnLoad",function() this:SetOwner(WorldFrame, "ANCHOR_NONE") end)
    end
	local buff=strlower(obuff);
	
	local textleft1=getglobal(Tooltip_buff:GetName().."TextLeft1");
	if ( not unit ) then
		unit ='player';
	end
	local my, me, mc, oy, oe, oc = GetWeaponEnchantInfo();
	if ( my ) then
		Tooltip_buff:SetOwner(UIParent, "ANCHOR_NONE");
		Tooltip_buff:SetInventoryItem( unit, 16);
		for i=1, 23 do
			local text = getglobal("XRS_Buff_TooltipTextLeft"..i):GetText();
			if ( not text ) then
				break;
			elseif (text and strlower(text) == buff) then
				Tooltip_buff:Hide();
				return "main",me, mc;
			end
		end
		Tooltip_buff:Hide();
	elseif ( oy ) then
		Tooltip_buff:SetOwner(UIParent, "ANCHOR_NONE");
		Tooltip_buff:SetInventoryItem( unit, 17);
		for i=1, 23 do
			local text = getglobal("XRS_Buff_TooltipTextLeft"..i):GetText();
			if ( not text ) then
				break;
			elseif (text and strlower(text) == buff) then
				Tooltip_buff:Hide();
				return "off", oe, oc;
			end
		end
		Tooltip_buff:Hide();
	end
	if ( item ) then return end
	Tooltip_buff:SetOwner(UIParent, "ANCHOR_NONE");
	Tooltip_buff:SetTrackingSpell();
	local b = textleft1:GetText();
	if ( b and strlower(b) == buff ) then
		Tooltip_buff:Hide();
		return "track",b;
	end
	local c=nil;
	for i=1, 32 do
		Tooltip_buff:SetOwner(UIParent, "ANCHOR_NONE");
		Tooltip_buff:SetUnitBuff(unit, i);
		b = textleft1:GetText();
		Tooltip_buff:Hide();
		if ( b and strlower(b) == buff ) then
			return "buff", i, b;
		elseif ( c==b ) then
			break;
		end
		--c = b;
	end
	c=nil;
	for i=1, 16 do
		Tooltip_buff:SetOwner(UIParent, "ANCHOR_NONE");
		Tooltip_buff:SetUnitDebuff(unit, i);
		b = textleft1:GetText();
		Tooltip_buff:Hide();
		if ( b and strlower(b) == buff ) then
			return "debuff", i, b;
		elseif ( c==b) then
			break;
		end
		--c = b;
	end
	Tooltip_buff:Hide();
end

function XRS:GetHintOption()
    return self.db.profile.ShowHint
end

function XRS:UpdateAfkBars()
    for _,v in ipairs(self.afk) do
        v:UpdateBar()
    end
end

function XRS:SetWidth()
	local width = self.db.profile.Width
	
	local barcount = table.getn(self.bars)
	local buffscount = math.ceil(table.getn(self.buffs) / math.floor(width/22))
	self.frame:SetHeight(30 + (barcount * 16) + ((buffscount)*22))
	
	for _,v in ipairs(self.bars) do
		v:SetWidth(width)
	end
	for _,v in ipairs(self.buffs) do
		v:SetWidth(width)
	end
	self.frame:SetWidth(width + 15)
end