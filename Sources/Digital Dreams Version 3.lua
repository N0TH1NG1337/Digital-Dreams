--//Digital Dreams 3 recode. 

local Version = "3.0"

--//Small Change
--@Table
local table_insert, table_remove = table.insert, table.remove
--@Bit 
local bit_lshift, bit_band, bit_bnot = bit.lshift, bit.band, bit.bnot
--@Math
local math_atan, math_atan2, math_cos, math_deg, math_floor, math_pow, math_rad, math_sin, math_sqrt, math_fmod, math_max, math_min, math_abs = math.atan, math.atan2, math.cos, math.deg, math.floor, math.pow, math.rad, math.sin, math.sqrt, math.fmod, math.max, math.min, math.abs
--@String 
local string_format, string_gmatch, string_gsub, string_char = string.format, string.gmatch, string.gsub, string.char
--@Cheat
local HttpGet, GetUsername = network.get, common.get_username

--//FFI
local ffi = require("ffi")
local FFIHandle = {}
ffi.cdef[[

    typedef struct {
        float x;
        float y;
        float z;
    } Vector3_t;

    typedef struct {
        uint8_t r;
        uint8_t g;
        uint8_t b;
        uint8_t a;
    } color_struct_t;

    int VirtualProtect(void* lpAddress, unsigned long dwSize, unsigned long flNewProtect, unsigned long* lpflOldProtect);
    void* VirtualAlloc(void* lpAddress, unsigned long dwSize, unsigned long  flAllocationType, unsigned long flProtect);
    int VirtualFree(void* lpAddress, unsigned long dwSize, unsigned long dwFreeType);

    //bool CreateDirectoryA(const char* lpPathName, void* lpSecurityAttributes);
    void* __stdcall URLDownloadToFileA(void* LPUNKNOWN, const char* LPCSTR, const char* LPCSTR2, int a, int LPBINDSTATUSCALLBACK);
    bool DeleteUrlCacheEntryA(const char* lpszUrlName);

]]

-- credit: suicide 

local Vector3_t = ffi.typeof("Vector3_t")

local native_GetClientEntity = utils.get_vfunc("client.dll", "VClientEntityList003", 3, "void*(__thiscall*)(void*, int)")
local native_GetAttachment = utils.get_vfunc(84, "bool(__thiscall*)(void*, int, Vector3_t&)")
local native_GetAttachmentIndex1st = utils.get_vfunc(468, "int(__thiscall*)(void*, void*)")
local native_GetAttachmentIndex3st = utils.get_vfunc(469, "int(__thiscall*)(void*)")
local native_VirtualProtect = function(lpAddress, dwSize, flNewProtect, lpflOldProtect) return ffi.C.VirtualProtect(ffi.cast("void*", lpAddress), dwSize, flNewProtect, lpflOldProtect) end
local native_FirstMaterial = utils.get_vfunc('materialsystem.dll', 'VMaterialSystem080', 86, "int(__thiscall*)(void*)")
local native_NextMaterial = utils.get_vfunc('materialsystem.dll', 'VMaterialSystem080', 87, "int(__thiscall*)(void*, int)")
local native_InvalidMaterial = utils.get_vfunc('materialsystem.dll', 'VMaterialSystem080', 88, "int(__thiscall*)(void*)")
local native_FindMaterial = utils.get_vfunc('materialsystem.dll', 'VMaterialSystem080', 89, "void*(__thiscall*)(void*, int)")
local native_FindMaterialByName = utils.get_vfunc('materialsystem.dll', 'VMaterialSystem080', 84, "void*(__thiscall*)(void*, const char*, const char*, bool, const char*)")
local native_IsConsoleOpen = utils.get_vfunc('engine.dll', 'VEngineClient014', 11, "bool(__thiscall*)(void*)")
local native_GetName = utils.get_vfunc(0, 'const char*(__thiscall*)(void*)')
local native_AlphaModulate = utils.get_vfunc(27, "void(__thiscall*)(void*, float)")
local native_ColorModulate = utils.get_vfunc(28, "void(__thiscall*)(void*, float, float, float)")
local native_Print = utils.get_vfunc("vstdlib.dll", "VEngineCvar007", 25, "void(__cdecl*)(void*,const color_struct_t&, const char*, ...)")
local native_GetClipboardTextCount = utils.get_vfunc("vgui2.dll", "VGUI_System010", 7, "int(__thiscall*)(void*)")
local native_SetClipboardText = utils.get_vfunc("vgui2.dll", "VGUI_System010", 9, "void(__thiscall*)(void*, const char*, int)")
local native_GetClipboardTextFn = utils.get_vfunc("vgui2.dll", "VGUI_System010", 11, "void(__thiscall*)(void*, int, const char*, int)")
local native_PlaySound = utils.get_vfunc("engine.dll", "IEngineSoundClient003", 12, "void*(__thiscall*)(void*, const char*, float, int, int, float)")
local native_SetClantag = common.set_clan_tag --// insted of using ffi to change it just use cheat api
-- // can be usefull later. // local native_EnergySplash = utils.get_vfunc("client.dll", "IEffects001", 7, "void(__thiscall*)(void*, const struct vec3_t&, const struct vec3_t&, bool)") || -- @ credit : https://www.unknowncheats.me/forum/counterstrike-global-offensive/278624-adding-shit-effects.html
local native_Sparks = utils.get_vfunc("client.dll", "IEffects001", 3, "void(__thiscall*)(void*, Vector3_t&, int, int, Vector3_t&)")

--@vmt hook
local VMTHook = {hooks = {}}
function VMTHook.new(vt)
    local NewHook = {}
    local OrgFunc = {}
    local OldProt = ffi.new("unsigned long[1]")
    local VirtualTable = ffi.cast("intptr_t**", vt)[0]

    NewHook.HookMethod = function(Cast, Func, Method)
        OrgFunc[Method] = VirtualTable[Method]
        native_VirtualProtect(VirtualTable + Method, 4, 0x4, OldProt)
        VirtualTable[Method] = ffi.cast("intptr_t", ffi.cast(Cast, Func))
        native_VirtualProtect(VirtualTable + Method, 4, OldProt[0], OldProt)
        return ffi.cast(Cast, OrgFunc[Method])
    end

    NewHook.UnHookMethod = function(Method)
        native_VirtualProtect(VirtualTable + Method, 4, 0x4, OldProt)
        VirtualTable[Method] = OrgFunc[Method]
        native_VirtualProtect(VirtualTable + Method, 4, OldProt[0], OldProt)
        OrgFunc[Method] = nil
    end

    NewHook.UnHookAll = function()
        for Method, Func in pairs(OrgFunc) do
            NewHook.UnHookMethod(Method)
        end
    end

    table_insert(VMTHook.hooks, NewHook.UnHookAll)
    return NewHook
end

--@files
FFIHandle.UrlMon = ffi.load 'UrlMon'
FFIHandle.Wininet = ffi.load 'WinInet'
local native_DownloadFile = function(From, PathTo)
    FFIHandle.Wininet.DeleteUrlCacheEntryA(From) 
    FFIHandle.UrlMon.URLDownloadToFileA(nil, From, PathTo, 0,0) 
end
--@console color print 
local native_ConsolePrint = function(Text, Color)
    if Color == nil then
        return
    end

    local ColorStruct = ffi.new("color_struct_t")

    ColorStruct.r, ColorStruct.g, ColorStruct.b, ColorStruct.a = Color.r, Color.g, Color.b, Color.a

    native_Print(ColorStruct, Text)
end
--@multi color print
FFIHandle.PrintConsole = function(...)
    local States = {...}

    for Index, Item in ipairs(States) do
        native_ConsolePrint(Item[1], Item[2]:clone())
    end

    native_ConsolePrint("\n", color(255, 255)) -- go sentence lower 
end


--//callback manager
local CallbackManager = {}
CallbackManager.FullRun = false
CallbackManager.CallbacksList = {
    ["render"] = {CallbackData = {}, TypeMethod = events.render},
    ["createmove"] = {CallbackData = {}, TypeMethod = events.createmove},
    ["createmove_run"] = {CallbackData = {}, TypeMethod = events.createmove_run},
    ["aim_fire"] = {CallbackData = {}, TypeMethod = events.aim_fire},
    ["aim_ack"] = {CallbackData = {}, TypeMethod = events.aim_ack},
    ["level_int"] = {CallbackData = {}, TypeMethod = events.level_init},
    ["pre_render"] = {CallbackData = {}, TypeMethod = events.pre_render},
    ["post_render"] = {CallbackData = {}, TypeMethod = events.post_render},
    ["level_int"] = {CallbackData = {}, TypeMethod = events.level_init},
    ["net_update_start"] = {CallbackData = {}, TypeMethod = events.net_update_start},
    ["net_update_end"] = {CallbackData = {}, TypeMethod = events.net_update_end},
    ["shutdown"] = {CallbackData = {}, TypeMethod = events.shutdown}
}

CallbackManager.AddMethod = function(MethodType, MethodPoint, AllowToSkip, MethodName)
    CallbackManager.CallbacksList[MethodType].CallbackData[#CallbackManager.CallbacksList[MethodType].CallbackData + 1] = {
        Method = MethodPoint,
        AllowSkip = AllowToSkip,
        Name = MethodName
    }
end

CallbackManager.RunLua = function(DebugAllow)
    for CallbackName, SelectedCallback in pairs(CallbackManager.CallbacksList) do
        SelectedCallback.TypeMethod:set(function(...)
            for MethodId, MethodData in ipairs(SelectedCallback.CallbackData) do
                if MethodData.AllowSkip or CallbackManager.FullRun then
                    MethodData.Method(...)
                end
            end
        end)
    end
end


--//ClipBroard - i am lazy to use lib for this 
local Clipboard = {}
Clipboard.Import = function()
    local ClipboardTextLength = native_GetClipboardTextCount()
   
    if ClipboardTextLength > 0 then
        local Buffer = ffi.new("char[?]", ClipboardTextLength)
        local Size = ClipboardTextLength * ffi.sizeof("char[?]", ClipboardTextLength)
        native_GetClipboardTextFn(0, Buffer, Size )
        return ffi.string( Buffer, ClipboardTextLength-1)
    end

    return "" -- on fail
end

Clipboard.Export = function(ToExport)
    if ToExport then
        native_SetClipboardText(ToExport, ToExport:len())
    end
end


--//Files
--@create folders 
local Files = {}
Files.Path = common.get_game_directory() .. "\\DigitalData\\"
files.create_folder("csgo\\DigitalData")
files.create_folder("csgo\\DigitalData\\DigitalIcons") 
files.create_folder("csgo\\DigitalData\\DigitalCfgs")

Files.DownloadFiles = {
    Rage = {
        name = "RageBot.png",
        url = "https://cdn.discordapp.com/attachments/1031845917638271006/1031876104291618927/RagebotIcon.png"
    },
    AntiAim = {
        name = "AntiAim.png",
        url = "https://cdn.discordapp.com/attachments/1031845917638271006/1031876081961140254/AntiaimIcon.png"
    },
    Visuals = {
        name = "Visuals.png",
        url = "https://cdn.discordapp.com/attachments/1031845917638271006/1031876102722965574/VisualsIcon.png"
    },
    Misc = {
        name = "Misc.png",
        url = "https://cdn.discordapp.com/attachments/1031845917638271006/1031876103574388756/MiscIcon.png"
    },
    Health = {
        name = "Health.png",
        url = "https://cdn.discordapp.com/attachments/1031845917638271006/1044673704350732318/HPIcon.png"
    },
    Armor = {
        name = "Armor.png",
        url = "https://cdn.discordapp.com/attachments/1031845917638271006/1044673703490895912/ArmorIcon.png"
    },
    Run = {
        name = "Run.png",
        url = "https://i.imgur.com/936MBqT.png"
    },
    Cload = {
        name = "Cload.png",
        url = "https://i.imgur.com/2EjQ59k.png"
    },
    Keybinds = {
        name = "Keybinds.png",
        url = "https://cdn.discordapp.com/attachments/1031845917638271006/1031876084070879233/Keybind.png"
    },
    Speclist = {
        name = "Speclist.png",
        url = "https://i.imgur.com/Ab8THsc.png"
    },
    ColorEdit = {
        name = "ColorEdit.png",
        url = "https://cdn.discordapp.com/attachments/1031845917638271006/1031876082988761168/ColorPicker.png"
    },
    CantAccess = {
        name = "CantAccess.png",
        url = "https://cdn.discordapp.com/attachments/1031845917638271006/1031876082435117126/CanAccessoutdated.png"
    },
    CanAccess = {
        name = "CanAccess.png",
        url = "https://cdn.discordapp.com/attachments/1031845917638271006/1050819236383166534/Signal.png"
    },
    
    Locked = {
        name = "Locked.png",
        url = "https://cdn.discordapp.com/attachments/1031845917638271006/1031876081541722143/Locked.png"
    },
    CustomMode = {
        name = "CustomMode.png",
        url = "https://cdn.discordapp.com/attachments/1031845917638271006/1031876083571752981/CustomMode.png"
    },
    LightMode = {
        name = "LightMode.png",
        url = "https://cdn.discordapp.com/attachments/1031845917638271006/1031876084943310870/LiteMode.png"
    },
    DarkMode = {
        name = "DarkMode.png",
        url = "https://cdn.discordapp.com/attachments/1031845917638271006/1031876103964475393/NightMode.png"
    },
    Warning = {
        name = "Warning.png",
        url = "https://cdn.discordapp.com/attachments/1031845917638271006/1031876103171739678/Warning.png"
    },
    Load = {
        name = "Load.png",
        url = "https://cdn.discordapp.com/attachments/1031845917638271006/1041698017742430228/Load.png"
    },
    Save = {
        name = "Save.png",
        url = "https://cdn.discordapp.com/attachments/1031845917638271006/1031876104719433768/Save.png"
    },
    Share = {
        name = "Share.png",
        url = "https://cdn.discordapp.com/attachments/1031845917638271006/1031876105075966002/Share.png"
    },
    UnderWork = {
        name = "UnderWork.png",
        url = "https://cdn.discordapp.com/attachments/1031845917638271006/1031876105487003669/UnderWork.png"
    },
    ActiveLink = {
        name = "ActiveLink.png",
        url = "https://cdn.discordapp.com/attachments/1031845917638271006/1031876084473528402/Link.png"
    },
    FontMenu = {
        name = "FontMenu.ttf",
        url = "https://cdn.discordapp.com/attachments/1031845917638271006/1031903490039095327/RedHatMono-Regular.ttf"
    },
    Main = {
        name = "Main.png",
        url = "https://cdn.discordapp.com/attachments/1031845917638271006/1032712289368948817/MainIcon.png"
    },
    Star = {
        name = "Star.png",
        url = "https://cdn.discordapp.com/attachments/1031845917638271006/1032713556006797365/Star.png"
    },
    UI = {
        name = "UI.png",
        url = "https://cdn.discordapp.com/attachments/1031845917638271006/1032713556354928721/UI.png"
    },
    Data = {
        name = "Data.png",
        url = "https://cdn.discordapp.com/attachments/1031845917638271006/1032713556778557471/Indicators.png"
    },
    List = {
        name = "List.png",
        url = "https://cdn.discordapp.com/attachments/1031845917638271006/1033794828351324201/List.png"
    },
    MultiList = {
        name = "MultiList.png",
        url = "https://cdn.discordapp.com/attachments/1031845917638271006/1033794828712017960/MultiList.png"
    },
    AddObject = {
        name = "Add.png",
        url = "https://cdn.discordapp.com/attachments/1031845917638271006/1040356574377558056/AddImage.png"
    },
    RemoveObject = {
        name = "Remove.png",
        url = "https://cdn.discordapp.com/attachments/1031845917638271006/1040356591909732362/RemoveImage.png"
    },
    LoadMovie = {
        name = "Movie.gif",
        url = "https://media.giphy.com/media/ixD7oWX1E0pTG1g0tT/giphy.gif"
    },
    NightmareIcon = {
        name = "Nightmare.png",
        url = "https://cdn.discordapp.com/attachments/1031845917638271006/1044671127047376936/NightmareNew.png"
    },
    PublicIcon = {
        name = "Public.png",
        url = "https://cdn.discordapp.com/attachments/1031845917638271006/1044671126640537701/PublicNew.png"
    },
    Buy = {
        name = "Buy.png",
        url = "https://cdn.discordapp.com/attachments/1031845917638271006/1050787743824883722/BuyCart.png"
    }
}
--@check if file is valid
Files.Check = function(FileName)
    local FileSys = ffi.cast("void***", utils.create_interface("filesystem_stdio.dll", "VBaseFileSystem011"))
    local FileExists = ffi.cast("bool(__thiscall*)(void*, const char*, const char*)", FileSys[0][10])

    local IsExist = FileExists(FileSys, Files.Path .. FileName , nil)
    if IsExist then
        return true
    end
    return false
end
--@download the file and check if is valid
Files.Download = function(FilePoint, SkipCheck)
    if SkipCheck then
        goto Skip
    end

    if Files.Check("DigitalIcons\\".. FilePoint.name) then
        return
    end

    ::Skip::

    native_DownloadFile(FilePoint.url, string_format("csgo\\DigitalData\\DigitalIcons\\%s", FilePoint.name))
end
--@download every file from Files.DownloadFiles
for FileId, FilePointer in pairs(Files.DownloadFiles) do
    Files.Download(FilePointer, false)
end
--@cfg create
for Index = 1, 6 do
    if not Files.Check(string_format("DigitalCfgs\\slot%s.txt", tostring(Index))) then
        files.write(string_format("csgo\\DigitalData\\DigitalCfgs\\slot%s.txt", tostring(Index)), "?")
    end
end
--@load Image 
Files.LoadImage = function(FilePoint, Size)
    local FileName = tostring(FilePoint.name)
    local Path = Files.Path .. "DigitalIcons\\".. FileName

    return {Image = (Files.Check("DigitalIcons\\".. FileName) and render.load_image_from_file(Path, Size) or render.load_image(HttpGet(FilePoint.url), Size)), Size = Size} -- load file from url if not downloaded or not accessable
end

Files.LoadFont = function(FilePoint, ...)
    local FileName = tostring(FilePoint.name)
    local Path = Files.Path .. "DigitalIcons\\".. FileName

    return (Files.Check("DigitalIcons\\".. FileName) and render.load_font(Path, ...) or render.load_font("Verdana", ...))
end

Files.Init = function()
    Files.image_LoadRage = Files.LoadImage(Files.DownloadFiles.Rage, vector(25, 25))
    Files.image_LoadAntiAim = Files.LoadImage(Files.DownloadFiles.AntiAim, vector(25, 25))
    Files.image_LoadVisuals = Files.LoadImage(Files.DownloadFiles.Visuals, vector(25, 25))
    Files.image_LoadMisc = Files.LoadImage(Files.DownloadFiles.Misc, vector(25, 25))
    Files.image_LoadCload = {Regular = Files.LoadImage(Files.DownloadFiles.Cload, vector(40, 40)), Log = Files.LoadImage(Files.DownloadFiles.Cload, vector(20, 13))}
    Files.image_LoadCloadWatermark = Files.LoadImage(Files.DownloadFiles.Cload, vector(20, 13))
    Files.image_LoadNightmare = Files.LoadImage(Files.DownloadFiles.NightmareIcon, vector(40, 40))
    Files.image_LoadPublic = Files.LoadImage(Files.DownloadFiles.PublicIcon, vector(40, 40))
    Files.image_LoadHealth = Files.LoadImage(Files.DownloadFiles.Health, vector(20, 20))
    Files.image_LoadArmor = Files.LoadImage(Files.DownloadFiles.Armor, vector(20, 20))
    Files.image_LoadMain = Files.LoadImage(Files.DownloadFiles.Main, vector(20, 20))
    Files.image_LoadCustomMode = Files.LoadImage(Files.DownloadFiles.CustomMode, vector(20, 20))
    Files.image_LoadMiscMenu = Files.LoadImage(Files.DownloadFiles.Misc, vector(20, 20))
    Files.image_LoadWarning = Files.LoadImage(Files.DownloadFiles.Warning, vector(20, 20))
    Files.image_LoadUI = Files.LoadImage(Files.DownloadFiles.UI, vector(20, 20))
    Files.image_LoadData = Files.LoadImage(Files.DownloadFiles.Data, vector(20, 20))
    Files.image_LoadStar = Files.LoadImage(Files.DownloadFiles.Star, vector(20, 20))
    Files.image_LoadVisualsMenu = Files.LoadImage(Files.DownloadFiles.Visuals, vector(20, 20))
    Files.image_LoadColorMenu = Files.LoadImage(Files.DownloadFiles.ColorEdit, vector(20, 20))
    Files.image_LoadSave = Files.LoadImage(Files.DownloadFiles.Save, vector(20, 20))
    Files.image_LoadActiveLink = Files.LoadImage(Files.DownloadFiles.ActiveLink, vector(20, 20))
    Files.image_LoadList = Files.LoadImage(Files.DownloadFiles.List, vector(20, 20))
    Files.image_LoadMultiList = Files.LoadImage(Files.DownloadFiles.MultiList, vector(20, 20))
    Files.image_LoadColorEdit = Files.LoadImage(Files.DownloadFiles.ColorEdit, vector(15, 15))
    Files.image_LoadKeyBind = Files.LoadImage(Files.DownloadFiles.Keybinds, vector(15, 15))
    Files.image_LoadAdd = Files.LoadImage(Files.DownloadFiles.AddObject, vector(16, 16))
    Files.image_LoadRemove = Files.LoadImage(Files.DownloadFiles.RemoveObject, vector(16, 16))
    Files.image_LoadLinkButton = Files.LoadImage(Files.DownloadFiles.ActiveLink, vector(16, 16))
    Files.image_LoadLoadCFG = Files.LoadImage(Files.DownloadFiles.Load, vector(16, 16))
    Files.image_LoadSaveCFG = Files.LoadImage(Files.DownloadFiles.Save, vector(16, 16))
    Files.image_LoadShareCFG = Files.LoadImage(Files.DownloadFiles.Share, vector(16, 16))
    Files.image_LoadLoadCFGIcon = Files.LoadImage(Files.DownloadFiles.Load, vector(20, 20))
    Files.image_LoadSaveCFGIcon = Files.LoadImage(Files.DownloadFiles.Save, vector(20, 20))
    Files.image_LoadShareCFGIcon = Files.LoadImage(Files.DownloadFiles.Share, vector(20, 20))
    Files.image_LoadKeybinds = Files.LoadImage(Files.DownloadFiles.Keybinds, vector(20, 20))
    Files.image_LoadVelocityWarning = Files.LoadImage(Files.DownloadFiles.Warning, vector(25, 25))
    Files.image_LoadLocalBuild = Files.LoadImage(Files.DownloadFiles.Data, vector(30, 30))
    Files.image_LoadIsOutDated = Files.LoadImage(Files.DownloadFiles.CantAccess, vector(30, 30))
    Files.image_LoadIsUpDated = Files.LoadImage(Files.DownloadFiles.CanAccess, vector(30, 30))
    Files.image_LoadVersion = Files.LoadImage(Files.DownloadFiles.ActiveLink, vector(30, 30))
    Files.image_LoadLog = Files.LoadImage(Files.DownloadFiles.Rage, vector(20, 20))
    Files.image_LoadLogMiss = Files.LoadImage(Files.DownloadFiles.Warning, vector(20, 20))
    Files.image_LoadLogBuy = Files.LoadImage(Files.DownloadFiles.Buy, vector(20, 20))
    Files.image_LoadLogHit = Files.LoadImage(Files.DownloadFiles.Star, vector(20, 20))
end


--//local neverlose avatar
local user_url = HttpGet("https://en.neverlose.cc/static/avatars/".. GetUsername() .. ".png")
local user_avatar = render.load_image(user_url, vector(40, 40))


--//helpers
local Helpers = {}
Helpers.Init = function()
    --@Weapons
    Helpers.WeaponsData = {
        ["Knifes"] = {
            ["Zeus x27"] = 31,
            ["Knife"] = 42,
            ["Knife"] = 59,
            ["Skeleton Knife"] = 525,
            ["Talon Knife"] = 523,
            ["Stiletto Knife"] = 522,
            ["Nomad Knife"] = 521,
            ["Navaja Knife"] = 520,
            ["Ursus Knife"] = 519,
            ["Survival Knife"] = 518,
            ["Paracord Knife"] = 517,
            ["Butterfly Knife"] = 515,
            ["Huntsman Knife"] = 509,
            ["Bowie Knife"] = 514,
            ["Falchion Knife"] = 512,
            ["M9 Bayonet"] = 508,
            ["Karambit"] = 507,
            ["Gut Knife"] = 506,
            ["Flip Knife"] = 505,
            ["Classic Knife"] = 503,
            ["Bayonet"] = 500,
            ["Shadow Daggers"] = 516
        },
        ["Main"] = {
            ["SSG 08"] = 40,
            ["AWP"] = 9,
            ["G3SG1"] = 11,
            ["SCAR-20"] = 38,
            ["Galil AR"] = 13,
            ["FAMAS"] = 10,
            ["AK-47"] = 7,
            ["M4A4"] = 16,
            ["M4A1-S"] = 60,
            ["SG 553"] = 39,
            ["AUG"] = 8,
            ["MAC-10"] = 17,
            ["MP9"] = 34,
            ["MP7"] = 33,
            ["UMP-45"] = 24,
            ["PP-Bizon"] = 26,
            ["P90"] = 19,
            ["Nova"] = 35,
            ["XM1014"] = 25,
            ["Sawed-Off"] = 29,
            ["MAG-7"] = 27,
            ["M249"] = 14,
            ["Negev"] = 28,
        },
        ["Pistols"] = {
            ["Glock-18"] = 4,
            ["CZ75-Auto"] = 63,
            ["P250"] = 36,
            ["Five-SeveN"] = 3,
            ["Desert Eagle"] = 1,
            ["R8 Revolver"] = 64,
            ["Dual Berettas"] = 2,
            ["Tec-9"] = 30,
            ["P2000"] = 32,
            ["USP-S"] = 61
        },
        ["Nades"] = {
            ["High Explosive Grenade"] = 44,
            ["Smoke Grenade"] = 45,
            ["Decoy Grenade"] = 47,
            ["Flashbang"] = 43,
            ["Molotov"] = 46,
            ["Incendiary Grenade"] = 48
        }
    }
    Helpers.IsKnife = function(Weapon)
        for Name, Index in pairs(Helpers.WeaponsData["Knifes"]) do
            if Weapon:get_weapon_index() == Index then
                return true
            end
        end
        return false
    end
    Helpers.IsPistol = function(Weapon)
        for Name, Index in pairs(Helpers.WeaponsData["Pistols"]) do
            if Weapon:get_weapon_index() == Index then
                return true
            end
        end
        return false
    end
    Helpers.IsGranade = function(Weapon)
        for Name, Index in pairs(Helpers.WeaponsData["Nades"]) do
            if Weapon:get_weapon_index() == Index then
                return true
            end
        end
        return false
    end
    Helpers.IsPrimary = function(Weapon)
        for Name, Index in pairs(Helpers.WeaponsData["Main"]) do
            if Weapon:get_weapon_index() == Index then
                return true
            end
        end
        return false
    end
    --@Math 
    Helpers.Clamp = function(Value, Min, Max)
        return Value < Min and Min or (Value > Max and Max or Value)
    end
    Helpers.Lerp = function(Start, End, Time) --// thx prince1337 // --
        if Start == nil then
            if type(Start) == 'userdata' then
                Start = color(255, 255)
            else
                Start = 0
            end 
        end

        if (type(Start) == 'userdata') then
            local ColorTable = {0, 0, 0, 0}

            for Index, ColorKey in ipairs({'r', 'g', 'b', 'a'}) do
                ColorTable[Index] = Helpers.Lerp(Start[ColorKey], End[ColorKey], Time)
            end

            return color(unpack(ColorTable))
        end

        local Delta = End - Start
        Delta = Delta * (globals.frametime * (Time))
        Delta = Delta + Start

        if End == 0 and Delta < 0.01 and Delta > -0.01 then
            Delta = 0
        elseif End == 1 and Delta < 1.01 and Delta > 0.99 then
            Delta = 1
        end

        return Delta
    end
    Helpers.LerpText = function(Text, Alpha)
        return string.sub(Text, 1, string.len(Text) * Alpha)
    end
    Helpers.LerpVector = function(StartVector, EndVector, Time)
        local VectorTable = vector(0, 0, 0)

        VectorTable.x = Helpers.Lerp(StartVector.x, EndVector.x, Time)
        VectorTable.y = Helpers.Lerp(StartVector.y, EndVector.y, Time)
        VectorTable.z = Helpers.Lerp(StartVector.z, EndVector.z, Time)

        return VectorTable
    end
    Helpers.NormalizeYaw = function(yaw)
        while yaw > 180 do 
            yaw = yaw - 360 
        end
        while yaw < -180 do 
            yaw = yaw + 360 
        end
        return yaw
    end
    Helpers.CalculateAngle = function(LocalPosition, OtherPosition)
        local RelativeYaw = math_atan((LocalPosition.y - OtherPosition.y) / (LocalPosition.x - OtherPosition.x))
        RelativeYaw = Helpers.NormalizeYaw(RelativeYaw * 180 / math.pi)
        if (LocalPosition.x - OtherPosition.x) >= 0 then
            RelativeYaw = Helpers.NormalizeYaw(RelativeYaw + 180)
        end
        return RelativeYaw
    end
    Helpers.ClosestPointOnRay = function(RayFrom, RayTo, DesiredPoint)
        local To = DesiredPoint - RayFrom
        local Direction = RayTo - RayFrom
        local RayLength = Direction:length()

        Direction.x, Direction.y, Direction.z = Direction.x / RayLength, Direction.y / RayLength, Direction.z / RayLength

        local DirectionAlong = Direction.x * To.x + Direction.y * To.y + Direction.z * To.z

        if (DirectionAlong < 0) then
            return RayFrom
        end

        if (DirectionAlong > RayLength) then
            return RayTo
        end

        return vector(
            RayFrom.x + Direction.x * DirectionAlong, 
            RayFrom.y + Direction.y * DirectionAlong, 
            RayFrom.z + Direction.z * DirectionAlong
        )
    end
    Helpers.AngleForward = function(Angle)
        local SinPitch = math_sin(math_rad(Angle.x))
        local CosPitch = math_cos(math_rad(Angle.x))
        local SinYaw = math_sin(math_rad(Angle.y))
        local CosYaw = math_cos(math_rad(Angle.y))

        return {        
            CosPitch * CosYaw,
            CosPitch * SinYaw,
            -SinPitch
        }
    end
    --@String / Vars
    Helpers.StringToSub = function(Input, Sep) 
        local Table = {} 
        for Str in string_gmatch(Input, "([^"..Sep.."]+)") do 
            Table[#Table + 1] = string_gsub(Str, "\n", "") 
        end 
        return Table
    end
    Helpers.ToInt = function(Input) -- // found somewhere in the internet . useful ig
        local s = tostring(Input)
        local i, j = s:find('%.')
        if (i) then
            return tonumber(s:sub(1, i-1))
        end 
        return Input
    end
    --@Color
    Helpers.ColorAlpha = function(Color, Alpha)
        return color(Color.r, Color.g, Color.b, Color.a * Alpha):clone()
    end
    Helpers.HSV = function(H, S, V)
        return {h = H, s = S, v = V}
    end
    Helpers.RGBtoHSV = function(r, g, b, a)
        local r, g, b = r / 255, g / 255, b / 255
        local max, min = math_max(r, g, b), math_min(r, g, b)
        local h, s, v
        v = max
    
        local d = max - min
        if (max == 0) then 
            s = 0 
        else 
            s = d / max 
        end
    
        if (max == min) then
            h = 0 -- achromatic
        else
            if (max == r) then
            h = (g - b) / d
            if (g < b) then h = h + 6 end
            elseif (max == g) then h = (b - r) / d + 2
            elseif (max == b) then h = (r - g) / d + 4
            end
            h = h / 6
        end
    
        return h, s, v, (a / 255)
    end
    Helpers.HSVtoRGB = function(h, s, v)
        local r, g, b
        local h, s, v = h, s, v

        local i = math_floor(h * 6);
        local f = h * 6 - i;
        local p = v * (1 - s);
        local q = v * (1 - f * s);
        local t = v * (1 - (1 - f) * s);
    
        i = i % 6
    
        if (i == 0) then r, g, b = v, t, p
        elseif (i == 1) then r, g, b = q, v, p
        elseif (i == 2) then r, g, b = p, v, t
        elseif (i == 3) then r, g, b = p, q, v
        elseif (i == 4) then r, g, b = t, p, v
        elseif (i == 5) then r, g, b = v, p, q
        end
    
        return r * 255 , g * 255 , b * 255 -- // ignore Alpha
    end
    Helpers.HexToRGB = function(Hex)
        Hex = Hex:gsub("#", "")
        return color(
            tonumber("0x"..Hex:sub(1,2)), 
            tonumber("0x"..Hex:sub(3,4)), 
            tonumber("0x"..Hex:sub(5,6)), 
            tonumber("0x"..Hex:sub(7,8))
        )
    end
    Helpers.RGBtoHex = function(Color)
        return string_format("#%02x%02x%02x%02x",
            math_floor(Color.r),
            math_floor(Color.g),
            math_floor(Color.b),
            math_floor(Color.a)
        )
    end
    Helpers.ColorConnnection = function(FirstColor, SecondColor)
        local NewR = math_abs(FirstColor.r + SecondColor.r)
        local NewG = math_abs(FirstColor.g + SecondColor.g)
        local NewB = math_abs(FirstColor.b + SecondColor.b)
        local NewA = math_abs(FirstColor.a)
        return color(NewR, NewG, NewB, NewA)
    end
    --@Table
    Helpers.Contains = function(Table, Value, ReturnValue) -- // returns the index on success or or returns nil on fail.
        for Index, Item in pairs(Table) do 
            if (Item == Value) then
                return ReturnValue ~= nil and Item or Index
            end
        end
        return nil
    end
    Helpers.CreateFullTable = function(Table, Value) -- // returns the index on success or or returns nil on fail.
        for Index, Item in pairs(Table) do 
            Item = Value
        end
    end
    Helpers.TableExport = function(Table, Sep) -- // return in case we didnt change anything in the string
        local StringEnd = ""
        for Index, Item in pairs(Table) do
            StringEnd = StringEnd .. tostring(Item) .. (Index == #Table and "" or tostring(Sep))
        end
        return StringEnd == "" and nil or StringEnd
    end
    Helpers.TableCreate = function(String, Sep, Value)
        local Sep = Sep and Sep or ","
        local TableEnd = {}

        local Values = Helpers.StringToSub(String, Sep)

        for Index, Item in pairs(Values) do
            TableEnd[Index] = Item == "true"
        end

        return TableEnd
    end
    --@Vector
    Helpers.IsInBox = function(VectorStart, VectorStartAddX, VectorStartAddY, VectorPoint)
        local Point = VectorPoint and VectorPoint or ui.get_mouse_position()
        local InBox = {x = false, y = false}
        --render.rect_outline(VectorStart, VectorStart + vector(VectorStartAddX, VectorStartAddY), color(255, 255))
        if (Point.x > VectorStart.x and Point.x < VectorStart.x + VectorStartAddX) then
            InBox.x = true
        end
        if (Point.y > VectorStart.y and Point.y < VectorStart.y + VectorStartAddY) then
            InBox.y = true
        end
        if (InBox.x and InBox.y) then
            return true
        end
        return false
    end
    --@Entity
    Helpers.IsInAir = function(PlayerPoint)
        local Flags = PlayerPoint.m_fFlags
        if (Flags == nil) then
            return
        end

        if (bit_band(Flags, 1) == 0) then
            return true
        end

        return false
    end
    --@Cheat + Lua
    Helpers.StringConvert = function(String) -- // use it for cfg system insted to do million checks inside the loop just create function :P
        local IsNumber = tonumber(String) ~= nil

        if (String == nil) then
            return nil
        end

        --@type: color // using prince1337 method for string -> color
        if (String:find("{")) then
            --color
            local StartpPre = String:find("{")
            local EndPre = String:find("}")
            local StringColor = String:sub(StartpPre, EndPre)

            local LoadColor = loadstring('return ' .. StringColor)()

            local Color = color(unpack(LoadColor))
            return Color
        end

        --@table // true - false
        if (String:find(",")) then -- after we check the color the only thing left this type is table values
            return Helpers.TableCreate(String, ",", true)
        end

        --@number
        if (IsNumber) then
            return tonumber(String)
        end

        --@bool
        if (String == "true" or String == "false") then
            return String == "true"
        end

        --@string
        return String
    end
    Helpers.IsMenuVisible = function()
        return ui.get_alpha() == 1
    end
    Helpers.GradientText = function(ColorTable, String)
        local R1, G1, B1, A1 = ColorTable[1]:unpack()
        local R2, G2, B2, A2 = ColorTable[2]:unpack()
        local StringEnd = ""
        local StringLength = #String - 1
        local Inc = 
        {
            r = (R2 - R1) / StringLength,
            g = (G2 - G1) / StringLength,
            b = (B2 - B1) / StringLength, 
            a = (A2 - A1) / StringLength
        }

        for Index = 1, StringLength + 1 do
            StringEnd = StringEnd .. ("\a%02x%02x%02x%02x%s"):format(R1, G1, B1, A1, String:sub(Index, Index))

            R1, G1, B1, A1 = R1 + Inc.r, G1 + Inc.g, B1 + Inc.b, A1 + Inc.a
        end 

        return StringEnd
    end
    Helpers.GradientTextFade = function(Font, Vector, ColorTable, AdditionShit, String, Speed)
        local StringFade = ""

        for i = 1, #String do
            local SelectedTav = String:sub(i, i)
            local FadeColor = Helpers.ColorAlpha(ColorTable[1], math.abs(1 * math.cos(2 * math.pi * (globals.curtime/2) + (i * 0.4) / 4))) -- // i will use speed later
            StringFade = StringFade .. string_format("\a%s" .. SelectedTav, FadeColor:to_hex())
        end

        render.text(Font, Vector, ColorTable[2], AdditionShit, String)
        render.text(Font, Vector, ColorTable[2], AdditionShit, StringFade)
    end
    Helpers.StringUpperCase = function(Str)
        return (Str:gsub("^%l", string.upper))
    end
    Helpers.ClosestTarget = function()
        local LocalPlayer = entity.get_local_player()
        if (not LocalPlayer or not LocalPlayer:is_alive()) then
            return
        end

        local CameraPosition = render.camera_position()
        local CameraAngles = render.camera_angles()

        local Direction = vector():angles(CameraAngles)

        local ClosestDistance, ClosestEnemy = math.huge, nil

        for Index, EnemyPoint in ipairs(entity.get_players(true)) do
            if (not EnemyPoint:is_alive() or EnemyPoint == nil) then
                goto skip
            end

            local HitBoxPosition = EnemyPoint:get_hitbox_position(3) -- // 

            local RayDistance = HitBoxPosition:dist_to_ray(CameraPosition, Direction)

            if (RayDistance < ClosestDistance) then
                ClosestDistance = RayDistance 
                ClosestEnemy = EnemyPoint
            end

            ::skip::
        end

        if (not ClosestEnemy) then
            return nil
        end

        return ({
            Pointer = ClosestEnemy,
            Fov = ClosestDistance
        })
    end
    Helpers.PlayerState = function(PlayerPoint)
        local Flags = PlayerPoint.m_fFlags
        local Velocity = PlayerPoint.m_vecVelocity:length2d()

        if (bit_band(Flags, 1) == 1) then
            if (bit_band(Flags, 4) == 4) then
                if PlayerPoint.m_iTeamNum == 2 then
                    return 3--duck T
                elseif PlayerPoint.m_iTeamNum == 3 then
                    return 4--duck CT
                end
            else
                return Velocity <= 3 and 1 or 2 -- 1 stand // 2 move
            end
        end

        return 5 -- air
    end
    --@switch case
    Helpers.Switch = function(n, ...)
        for _,v in ipairs {...} do
            if v[1] == n or v[1] == nil then
                return v[2](unpack(v[3]))
            end
        end
    end
    Helpers.Case = function(n, f, ...)
        return {n, f, {...}}
    end
    Helpers.Default = function(f, ...)
        return {nil, f, {...}}
    end

    --//enc/dec
    local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/' -- You will need this for encoding/decoding
    -- encoding
    function enc(data)
        return ((data:gsub('.', function(x)
            local r,b='',x:byte()
            for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
            return r;
        end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
            if (#x < 6) then return '' end
            local c=0
            for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
            return b:sub(c+1,c+1)
        end)..({ '', '==', '=' })[#data%3+1])
    end
    -- decoding
    function dec(data)
        data = string_gsub(data, '[^'..b..'=]', '')
        return (data:gsub('.', function(x)
            if (x == '=') then return '' end
            local r,f='',(b:find(x)-1)
            for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
            return r;
        end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
            if (#x ~= 8) then return '' end
            local c=0
            for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
                return string_char(c)
        end))
    end
end


--//user data
local User = {}
User.BuildsList = HttpGet("https://rentry.co/test_versions/raw")
User.CloadVersion = HttpGet("https://rentry.co/cload_version/raw")
User.Announcement = HttpGet("https://rentry.co/CloadAnnouncement/raw")
User.TrashTalkPhases = HttpGet("https://rentry.co/tinkeJtt/raw")
User.CloadCFG = HttpGet("https://rentry.co/CloadCFG/raw")
User.PlayerStates = {"Global", "Stand", "Duck", "Slow Walk", "Move", "Air", "Air Duck", "Use", "Roll"}
User.WeaponsCfg = {"Scout", "Awp", "Auto", "R8", "Deagel"}
User.ConditionsTable = {"Lehal"," No Kevlar", "Stand", "Move", "Duck T", "Duck CT", "Air"}
User.SteamOverlayAPI = panorama.SteamOverlayAPI
User.LocalBuild = "public"
User.Init = function()
    local UsernamesTable = Helpers.StringToSub(User.BuildsList, "|")
    for Index = 1, #UsernamesTable do
        local TableVersion = Helpers.StringToSub(UsernamesTable[Index], "=")
        if GetUsername() == TableVersion[1] then
            User.LocalBuild = TableVersion[2]
            goto skip
        end
    end
    User.LocalBuild = "public"
    ::skip::
end



--//Menu References
local MenuReferences = {}
MenuReferences.Init = function()
    --@Ragebot
    MenuReferences.DoubleTap = ui.find("Aimbot", "Ragebot", "Main", "Double Tap")
    MenuReferences.HideShots = ui.find("Aimbot", "Ragebot", "Main", "Hide Shots")
    MenuReferences.HitChanceGlobal = ui.find("Aimbot", "Ragebot", "Selection", "Hit Chance")
    MenuReferences.AutoPeek = ui.find("Aimbot", "Ragebot", "Main", "Peek Assist")
    MenuReferences.SafePoints = 
    {
        ui.find("Aimbot", "Ragebot", "Safety", "SSG-08", "Safe Points"), -- [SSG-08]
        ui.find("Aimbot", "Ragebot", "Safety", "AWP", "Safe Points"), -- [AWP]
        ui.find("Aimbot", "Ragebot", "Safety", "AutoSnipers", "Safe Points"), -- [AutoSnipers]
        ui.find("Aimbot", "Ragebot", "Safety", "R8 Revolver", "Safe Points"), -- [R8 Revolver]
        ui.find("Aimbot", "Ragebot", "Safety", "Desert Eagle", "Safe Points"), -- [Desert Eagle]
    }
    MenuReferences.BodyAim = 
    {
        ui.find("Aimbot", "Ragebot", "Safety", "SSG-08", "Body Aim"), -- [SSG-08]
        ui.find("Aimbot", "Ragebot", "Safety", "AWP", "Body Aim"), -- [AWP]
        ui.find("Aimbot", "Ragebot", "Safety", "AutoSnipers", "Body Aim"), -- [AutoSnipers]
        ui.find("Aimbot", "Ragebot", "Safety", "R8 Revolver", "Body Aim"), -- [R8 Revolver]
        ui.find("Aimbot", "Ragebot", "Safety", "Desert Eagle", "Body Aim"), -- [Desert Eagle]
    }

    --@Anti Aim
    MenuReferences.Pitch = ui.find("Aimbot", "Anti Aim", "Angles", "Pitch")
    MenuReferences.Yaw = ui.find("Aimbot", "Anti Aim", "Angles", "Yaw")
    MenuReferences.YawBase = ui.find("Aimbot", "Anti Aim", "Angles", "Yaw", "Base")
    MenuReferences.YawOffset = ui.find("Aimbot", "Anti Aim", "Angles", "Yaw", "Offset")
    MenuReferences.YawModifier = ui.find("Aimbot", "Anti Aim", "Angles", "Yaw Modifier")
    MenuReferences.YawModifierOffset = ui.find("Aimbot", "Anti Aim", "Angles", "Yaw Modifier", "Offset")
    MenuReferences.BodyYawOptions = ui.find("Aimbot", "Anti Aim", "Angles", "Body Yaw", "Options")
    MenuReferences.LeftLimit = ui.find("Aimbot", "Anti Aim", "Angles", "Body Yaw", "Left Limit")
    MenuReferences.RightLimit = ui.find("Aimbot", "Anti Aim", "Angles", "Body Yaw", "Right Limit")
    MenuReferences.FreestandDesync = ui.find("Aimbot", "Anti Aim", "Angles", "Body Yaw", "Freestanding")
    MenuReferences.DesyncOnShot = ui.find("Aimbot", "Anti Aim", "Angles", "Body Yaw", "On Shot")
    MenuReferences.LBYMode = ui.find("Aimbot", "Anti Aim", "Angles", "Body Yaw", "LBY Mode")
    MenuReferences.SlowWalk = ui.find("Aimbot", "Anti Aim", "Misc", "Slow Walk")
    MenuReferences.FakeDuck = ui.find("Aimbot", "Anti Aim", "Misc", "Fake Duck")
    MenuReferences.Freestand = ui.find("Aimbot", "Anti Aim", "Angles", "Freestanding")
    MenuReferences.Invert = ui.find("Aimbot", "Anti Aim", "Angles", "Body Yaw", "Inverter")
    MenuReferences.Scope = ui.find("Visuals", "World", "Main", "Override Zoom", "Scope Overlay")

    MenuReferences.PreserveKillFeed = ui.find("Miscellaneous", "Main", "In-Game", "Preserve Kill Feed")
    MenuReferences.ForceAccuracy = ui.find("Aimbot", "Ragebot", "Accuracy", "Auto Stop", "Force Accuracy")
end

local AntiAim = {}
local RageBot = {}
local Visuals = {}
local Misc = {}
local Menu = {}

RageBot.Init = function()
    local NoScopeWeapons = {
        [261] = true,
        [242] = true,
        [233] = true,
        [267] = true
    }

    local IsInAirHitchance = function()
        if not Menu.DataUI["RageBot"]["Main"]["Air Hitchance"] then
            return
        end

        local LocalPlayer = entity.get_local_player()
        if LocalPlayer == nil or not LocalPlayer:is_alive() then
            return
        end

        if not Helpers.IsInAir(LocalPlayer) then
            return
        end

        return Menu.DataUI["RageBot"]["Main"]["Air Chance"]
    end

    local IsNoScopeHitchance = function()
        if not Menu.DataUI["RageBot"]["Main"]["No Scope Hitchance"] then
            return
        end

        local LocalPlayer = entity.get_local_player()
        if LocalPlayer == nil or not LocalPlayer:is_alive() then
            return
        end

        local Weapon = LocalPlayer:get_player_weapon()
        if Weapon == nil then
            return
        end

        if NoScopeWeapons[Weapon:get_classid()] == nil then
            return
        end

        if LocalPlayer.m_bIsScoped then
            return
        end

        return Menu.DataUI["RageBot"]["Main"]["No Scope Chance"]
    end

    local HandleHitchance = function()
        local AirChance = IsInAirHitchance()
        local NoScopeChance = IsNoScopeHitchance()


        if AirChance == nil and NoScopeChance ~= nil then
            MenuReferences.HitChanceGlobal:override(NoScopeChance)
            MenuReferences.ForceAccuracy:override(false)
        elseif AirChance ~= nil and NoScopeChance == nil then
            MenuReferences.HitChanceGlobal:override(AirChance)
            MenuReferences.ForceAccuracy:override(false)
        elseif AirChance == nil and NoScopeChance == nil then
            MenuReferences.HitChanceGlobal:override(nil)
            MenuReferences.ForceAccuracy:override(nil)
        else
            local value = math_max(NoScopeChance, AirChance) 
            MenuReferences.HitChanceGlobal:override(value)
            MenuReferences.ForceAccuracy:override(false)
        end
        
    end

    CallbackManager.AddMethod("createmove", HandleHitchance, false, "Handle Hitchance")
end

--@Anti Aim
AntiAim.Init = function()
    local Main = {}
    local EdgeYaw = {}
    EdgeYaw.IsEdged = false
    EdgeYaw.Yaw = 0
    EdgeYaw.Trace = nil
    local Use = {}
    local AntiBrute = {}

    Main.ManualSide = 0 -- // 2 - left , 1 - right
    local ManualsData = {
        OldTick = -1,
        timePress = -1,
        LastKey = nil,
        FixValue = false
    }
    local Manuals = function()
        if ManualsData.OldTick == globals.tickcount then
            return
        end

        ManualsData.OldTick = globals.tickcount

        if Menu.Render.KeyBinds.Get("Edge Yaw") or Menu.Render.KeyBinds.Get("Manual Back") then
            Main.ManualSide = 0
            return
        end

        if ManualsData.FixValue == false and common.is_button_down(Menu.Keybinds.Data["Manual Right"].Key) then
            Main.ManualSide = Main.ManualSide == 1 and 0 or 1
            ManualsData.LastKey = Menu.Keybinds.Data["Manual Right"].Key
            ManualsData.FixValue = true
        end

        if ManualsData.FixValue == false and common.is_button_down(Menu.Keybinds.Data["Manual Left"].Key) then
            Main.ManualSide = Main.ManualSide == 2 and 0 or 2
            ManualsData.LastKey = Menu.Keybinds.Data["Manual Left"].Key
            ManualsData.FixValue = true
        end

        if ManualsData.LastKey ~= nil then
            if common.is_button_released(ManualsData.LastKey) then
                ManualsData.LastKey = nil
                ManualsData.FixValue = false
            end
        end
    end

    events.player_death:set(function(event)
        local Me = entity.get_local_player()
        local Player = entity.get(event.userid, true)
        if Player == Me then
            Main.ManualSide = 0
        end
    end)

    EdgeYaw.Handle = function()
        EdgeYaw.IsEdged = false
        EdgeYaw.Yaw = 0

        if not Menu.Render.KeyBinds.Get("Edge Yaw") then
            return
        end

        local LocalPlayer = entity.get_local_player()
        if LocalPlayer == nil or not LocalPlayer:is_alive() then
            return
        end

        local LocalEyePosition = LocalPlayer:get_eye_position()
        if LocalEyePosition == nil then 
            return
        end

        local LocalViewAngle = render.camera_angles()

        local EdgeDistance = 8192
        local ClosestPoint = nil

        for I = LocalViewAngle.y - 180, LocalViewAngle.y + 180, 15 do
            local Rotation = math_rad(I)
            local EdgePoint = vector(LocalEyePosition.x + math_cos(Rotation) * 100, LocalEyePosition.y + math_sin(Rotation) * 100, LocalEyePosition.z)
            EdgeYaw.Trace = utils.trace_line(
                LocalEyePosition, 
                EdgePoint, 
                LocalPlayer, 
                0x4600400b
            )

            if EdgeYaw.Trace.fraction * 100 < EdgeDistance then
                EdgeDistance = EdgeYaw.Trace.fraction * 100
                ClosestPoint = EdgePoint
            end
        end

        if EdgeDistance > 30 then
            return
        end

        local YawEdge = Helpers.CalculateAngle(LocalEyePosition, ClosestPoint)
        local Delta = Helpers.NormalizeYaw(LocalViewAngle.y - 180)
        local FinalYaw = Helpers.NormalizeYaw(YawEdge - Delta)

        EdgeYaw.IsEdged = true
        EdgeYaw.Yaw = FinalYaw

    end

    AntiBrute.CurrentTime = 0
    AntiBrute.MissCount = 0
    AntiBrute.DisableFake = false
    AntiBrute.NewValues = {
        Desync = 0,
        Jitter = 0,
    }
    events.bullet_impact:set(function(event)
        if AntiBrute.CurrentTime == globals.realtime then
            return
        end

        local LocalPlayer = entity.get_local_player()
        if LocalPlayer == nil or not LocalPlayer:is_alive() then
            return
        end

        local Player = entity.get(event.userid, true)
        if Player == nil then -- dont need to check if alive ig ggeeeee
            return
        end

        if not Player:is_enemy() or LocalPlayer == Player then
            return
        end

        x = event.x
        y = event.y
        z = event.z

        if x == nil or y == nil or z == nil then
            return
        end

        local ImpactVector = vector(x, y, z)

        local LocalEyePosition = LocalPlayer:get_eye_position()
        if LocalEyePosition == nil then
            return
        end

        local EnemyEyePosition = Player:get_eye_position()
        if EnemyEyePosition == nil then
            return
        end

        local Distance = Helpers.ClosestPointOnRay(ImpactVector, EnemyEyePosition, LocalEyePosition):dist(LocalEyePosition)
        if Distance > 75 then
            return
        end

        AntiBrute.CurrentTime = globals.realtime
        AntiBrute.MissCount = AntiBrute.MissCount + 1
    end)

    local AntiBruteForce = function()
        AntiBrute.DisableFake = false
        if AntiBrute.MissCount == 0 then
            MenuReferences.Invert:override(nil)
            return
        end

        local TotalPhrases = {
            Fake = Menu.DataUI["Anti Aim"]["Anti Bruteforce"]["AmoutOfDesync"],
            Jitter = Menu.DataUI["Anti Aim"]["Anti Bruteforce"]["AmoutOfJitter"]
        }

        if AntiBrute.CurrentTime + 5 < globals.realtime then
            -- 5 and be replaced with any other value . i think 5 seconds is the best. 
            return
        end

        if Menu.DataUI["Anti Aim"]["Anti Bruteforce"]["Enable Desync Phases"] then
            AntiBrute.NewValues.Desync = Menu.DataUI["Anti Aim"]["Anti Bruteforce"][string_format("Phase %d Limit", (AntiBrute.MissCount % TotalPhrases.Fake) + 1)]
            MenuReferences.Invert:override(AntiBrute.NewValues.Desync < 0)
        end

        if Menu.DataUI["Anti Aim"]["Anti Bruteforce"]["Enable Jitter Phases"] then
            AntiBrute.NewValues.Jitter = Menu.DataUI["Anti Aim"]["Anti Bruteforce"][string_format("Phase %d Degree", (AntiBrute.MissCount % TotalPhrases.Jitter) + 1)]
        end

        AntiBrute.DisableFake = true
    end

    --
    local PlayerState = function(cmd) -- User.PlayerStates = {"Global", "Stand", "Duck", "Slow Walk", "Move", "Air", "Air Duck", "Use", "Roll"}
        local LocalPlayer = entity.get_local_player()
        if LocalPlayer == nil or not LocalPlayer:is_alive() then
            return User.PlayerStates[1]
        end

        local Velocity = LocalPlayer.m_vecVelocity:length2d()
        local IsInDuck = LocalPlayer.m_flDuckAmount > 0.1

        if common.is_button_down(0x45) then return User.PlayerStates[8] end

        if cmd ~= nil and cmd.view_angles.z ~= 0 then return User.PlayerStates[9] end

        if Helpers.IsInAir(LocalPlayer) and IsInDuck then return User.PlayerStates[7] end

        if Helpers.IsInAir(LocalPlayer) then return User.PlayerStates[6] end

        if IsInDuck then return User.PlayerStates[3] end

        if Velocity <= 5 then return User.PlayerStates[2] end

        if MenuReferences.SlowWalk:get() then return User.PlayerStates[4] end

        if Velocity > 5 then return User.PlayerStates[5] end

        return User.PlayerStates[1] -- // idk what it can cause it but ig :D
    end

    -- Anti Aim on use
    Use.DisablePitch = false
    Use.Disable = false
    local AntiAimOnUse = function(cmd, LocalPlayer)
        -- we get localplayer as argument to not call the entity get local player everyime
        if not Menu.DataUI["Anti Aim"]["Misc"]["Anti Aim options"][1] then
            Use.DisablePitch = false
            return
        end

        Use.Disable = false

        local LocalVector = LocalPlayer:get_origin()

        local Entities = {}
        table_insert(Entities, entity.get_entities(97))
        table_insert(Entities, entity.get_entities("CPropDoorRotating"))
        if LocalPlayer.m_iTeamNum == 3 then -- check if we ct so we can also count on bomb defuse
            table_insert(Entities, entity.get_entities(129))
        end

        local ActiveWeapon = LocalPlayer:get_player_weapon()
        if ActiveWeapon == nil then
            return
        end

        if ActiveWeapon:get_classname() == "CC4" then
            Use.Disable = true
            goto skip
        end

        for I, SelectedEntity in pairs(Entities) do
            for J = 1, #SelectedEntity do -- in any case there are more than 1 entity in map
                if LocalVector:dist(SelectedEntity[J].m_vecOrigin) < 120 then
                    Use.Disable = true
                    break
                end
            end

            if Use.Disable == true then
                break
            end
        end

        ::skip::

        if not Use.Disable then
            cmd.in_use = 0 -- disable use
            Use.DisablePitch = common.is_button_down(0x45)
            
        end
    end

    local CustomSlowWalk = function(cmd)
        if not Menu.DataUI["Anti Aim"]["Misc"]["Anti Aim options"][2] then
            return
        end

        if not MenuReferences.SlowWalk:get() then
            return
        end

        cmd.forwardmove = Helpers.Clamp(cmd.forwardmove, -Menu.DataUI["Anti Aim"]["Misc"]["SlowWalk Speed"], Menu.DataUI["Anti Aim"]["Misc"]["SlowWalk Speed"])
        cmd.sidemove = Helpers.Clamp(cmd.sidemove, -Menu.DataUI["Anti Aim"]["Misc"]["SlowWalk Speed"], Menu.DataUI["Anti Aim"]["Misc"]["SlowWalk Speed"])
    end

    --Refs handle 
    local Setting = {
        YawOffest = MenuReferences.YawOffset:get(),
        YawModifier = MenuReferences.YawModifier:get(),
        YawModifierOffset = MenuReferences.YawModifierOffset:get(),
        BodyOptions = {""},
        LeftLimit = MenuReferences.LeftLimit:get(),
        RightLimit = MenuReferences.RightLimit:get(),
        Freestand = MenuReferences.FreestandDesync:get(),
        OnShot = MenuReferences.DesyncOnShot:get(),
        LBY = MenuReferences.LBYMode:get(),
    }

    local SetSettings = function(...)
        local Arg = {...}
        Setting.YawOffest = Arg[1]
        Setting.YawModifier = Arg[2]
        Setting.YawModifierOffset = Arg[3]
        Setting.BodyOptions = Arg[4] -- table
        Setting.LeftLimit = Arg[5]
        Setting.RightLimit = Arg[6]
        Setting.Freestand = Arg[7]
        Setting.OnShot = Arg[8]
        Setting.LBY = Arg[9]
    end

    local AutoPresets = function()
        Helpers.Switch(Menu.DataUI["Anti Aim"]["Custom Settings"]["Active Preset"], 
            Helpers.Case("Static", function()
                SetSettings(
                    0,
                    "Disabled",
                    0,
                    {""},
                    60,
                    60,
                    "Off",
                    "Default",
                    "Disabled"
                )
            end, cmd),
            Helpers.Case("New", function()
                SetSettings(
                    0,
                    "Center",
                    23,
                    {"Jitter", "Avoid Overlap"},
                    60,
                    60,
                    "Off",
                    "Switch",
                    "Disabled"
                )
            end, cmd),
            Helpers.Default(function() error("Error Preset Anti Aim") end, nil)
        )
    end

    local DigitalBuilder = function(cmd)
        --
        local LocalState = PlayerState(cmd)
        local ActivePreset = Menu.DataUI["Anti Aim"]["Custom Settings"][string_format("Enable : %s", LocalState)] and LocalState or User.PlayerStates[1]

        local TableOptions = {}

        if Menu.DataUI["Anti Aim"]["Custom Settings"][string_format("%s Sync Side With Jitter", ActivePreset)] and Menu.DataUI["Anti Aim"]["Custom Settings"][string_format("%s Enable Jitter", ActivePreset)] then
            table_insert(TableOptions, "Jitter")
        end

        local DesyncF = Menu.DataUI["Anti Aim"]["Custom Settings"][string_format("%s Desync", ActivePreset)] > 60 and Menu.DataUI["Anti Aim"]["Custom Settings"][string_format("%s Desync", ActivePreset)] - 60 or Menu.DataUI["Anti Aim"]["Custom Settings"][string_format("%s Desync", ActivePreset)]

        SetSettings(
            Menu.DataUI["Anti Aim"]["Custom Settings"][string_format("%s Yaw Add", ActivePreset)],
            Menu.DataUI["Anti Aim"]["Custom Settings"][string_format("%s Enable Jitter", ActivePreset)] and "Center" or "Disabled",
            Menu.DataUI["Anti Aim"]["Custom Settings"][string_format("%s Enable Jitter", ActivePreset)] and Menu.DataUI["Anti Aim"]["Custom Settings"][string_format("%s Jitter Factor", ActivePreset)] or 0,
            TableOptions, -- 
            DesyncF,
            DesyncF,
            Menu.DataUI["Anti Aim"]["Custom Settings"][string_format("%s Freestand", ActivePreset)] and "Peek Fake" or "Off",
            "Switch",
            Menu.DataUI["Anti Aim"]["Custom Settings"][string_format("%s Desync", ActivePreset)] > 60 and "Opposite" or "Disabled"
        )
    end

    local DefaultBuilder = function(cmd)
        --
        local LocalState = PlayerState(cmd)
        local ActivePreset = Menu.DataUI["Anti Aim"]["Custom Settings"][string_format("Enable : %s", LocalState)] and LocalState or User.PlayerStates[1] -- // for any case

        --fake options 

        --fake options
        local TableOptions = {}
        if Menu.DataUI["Anti Aim"]["Custom Settings"][string_format("%s Fake Options", ActivePreset)][1] then
            table_insert(TableOptions, "Avoid Overlap")
        end

        if Menu.DataUI["Anti Aim"]["Custom Settings"][string_format("%s Fake Options", ActivePreset)][2] then
            table_insert(TableOptions, "Jitter")
        end

        if Menu.DataUI["Anti Aim"]["Custom Settings"][string_format("%s Fake Options", ActivePreset)][3] then
            table_insert(TableOptions, "Randomize Jitter")
        end


        SetSettings(
            Menu.DataUI["Anti Aim"]["Custom Settings"][string_format("%s Yaw", ActivePreset)],
            Menu.DataUI["Anti Aim"]["Custom Settings"][string_format("%s Modifier", ActivePreset)],
            Menu.DataUI["Anti Aim"]["Custom Settings"][string_format("%s Modifier Degree", ActivePreset)],
            TableOptions, -- 
            Menu.DataUI["Anti Aim"]["Custom Settings"][string_format("%s Left Limit", ActivePreset)],
            Menu.DataUI["Anti Aim"]["Custom Settings"][string_format("%s Right Limit", ActivePreset)],
            Menu.DataUI["Anti Aim"]["Custom Settings"][string_format("%s Fake Freestand", ActivePreset)],
            Menu.DataUI["Anti Aim"]["Custom Settings"][string_format("%s OnShot", ActivePreset)],
            Menu.DataUI["Anti Aim"]["Custom Settings"][string_format("%s Lby Mode", ActivePreset)]
        )
    end

    local AntiAimSettings = function(cmd, GameRules)
        -- note : no need to do another local player check
        local LocalPlayer = entity.get_local_player()

        AntiAimOnUse(cmd, LocalPlayer)
        CustomSlowWalk(cmd)

        -- lets first of all do all the adition things like static on warmap and on manuals
        if ((Menu.DataUI["Anti Aim"]["Misc"]["Anti Aim options"][4] and GameRules.m_bWarmupPeriod == true) or (Menu.DataUI["Anti Aim"]["Misc"]["Anti Aim options"][3] and not MenuReferences.Freestand:get() and (Main.ManualSide == 1 or Main.ManualSide == 2))) then
            --static
            SetSettings(
                0,
                "Disabled",
                0,
                {""}, -- 
                60,
                60,
                "Off",
                "Default",
                "Disabled"
            )
            return
        end
        
        --if we dont use manuals or static on warmap
        Helpers.Switch(Menu.DataUI["Anti Aim"]["Main"]["Anti Aim"], 
            Helpers.Case("Auto Presets", AutoPresets, cmd),
            Helpers.Case("Digital Builder", DigitalBuilder, cmd),
            Helpers.Case("Default Builder", DefaultBuilder, cmd),
            Helpers.Default(function() error("Error in Anti Aim Selection;") end, nil)
        )

    end

    local MainFunction = function(cmd)
        if Menu.DataUI["Anti Aim"]["Main"]["Anti Aim"] == "None" then
            return
        end
        
        local LocalPlayer = entity.get_local_player()
        if LocalPlayer == nil or not LocalPlayer:is_alive() then
            return
        end

        --Data
        local GameRules = entity.get_game_rules()

        --pitch
        --Use.DisablePitch
        MenuReferences.Pitch:override(Use.DisablePitch and "Disabled" or (Menu.DataUI["Anti Aim"]["Main"]["Pitch Down"] and "Down" or "Disabled"))
        if Use.DisablePitch then
            MenuReferences.Freestand:override(false)
        else
            MenuReferences.Freestand:override(nil)
        end

        MenuReferences.Yaw:override(Menu.DataUI["Anti Aim"]["Main"]["Yaw"] ~= "None" and (Use.DisablePitch and "Disabled" or "Backward") or "Disabled")
        MenuReferences.YawBase:override((Use.DisablePitch or Main.ManualSide == 2 or Main.ManualSide == 1) and "Local View" or Menu.DataUI["Anti Aim"]["Main"]["Yaw"])

        AntiAimSettings(cmd, GameRules)
    end 

    local HandleSettings = function()
        if Menu.DataUI["Anti Aim"]["Main"]["Anti Aim"] == "None" then
            return
        end
        local AddYaw = 0
        if Main.ManualSide == 1 then
            AddYaw = 90
        elseif Main.ManualSide == 2 then
            AddYaw = -90
        end

        MenuReferences.YawOffset:override(EdgeYaw.IsEdged and EdgeYaw.Yaw or Setting.YawOffest + (AddYaw))
        MenuReferences.YawModifier:override(Setting.YawModifier)
        MenuReferences.YawModifierOffset:override((Menu.DataUI["Anti Aim"]["Anti Bruteforce"]["Enable Jitter Phases"] and AntiBrute.DisableFake) and AntiBrute.NewValues.Jitter or Setting.YawModifierOffset)
        
        MenuReferences.BodyYawOptions:set(Setting.BodyOptions)

        MenuReferences.LeftLimit:override((Menu.DataUI["Anti Aim"]["Anti Bruteforce"]["Enable Desync Phases"] and AntiBrute.DisableFake) and math_abs(AntiBrute.NewValues.Desync) or Setting.LeftLimit)
        MenuReferences.RightLimit:override((Menu.DataUI["Anti Aim"]["Anti Bruteforce"]["Enable Desync Phases"] and AntiBrute.DisableFake) and math_abs(AntiBrute.NewValues.Desync) or Setting.RightLimit)
        MenuReferences.FreestandDesync:override(Setting.Freestand)
        MenuReferences.DesyncOnShot:override(Setting.OnShot)
        MenuReferences.LBYMode:override(Setting.LBY)
    end

    CallbackManager.AddMethod("createmove", AntiBruteForce, false, "Anti Bruteforce Values")
    CallbackManager.AddMethod("createmove", HandleSettings, false, "Set Menu Refs")
    CallbackManager.AddMethod("createmove", MainFunction, false, "Main Anti Aim")
    CallbackManager.AddMethod("createmove", Manuals, false, "Manuals")
    CallbackManager.AddMethod("createmove", EdgeYaw.Handle, false, "Edge Yaw")

    --CallbackManager.AddMethod("render", Manuals, false, "Manuals")

    --    render.text(1, vector(200, 200), color(255, 255), nil, Menu.Render.KeyBinds.Get("Edge Yaw"))
   -- end, false, "Test")
end

--@Visuals Handle

Visuals.Init = function() -- Menu.DataUI["Visuals"]["Visuals"]["Visuals Options"][1]
    local DragSystem = function()
        Visuals.Move = {}
        Visuals.Move.Objects = 
        {
            Menu = false,
            MenuSize = false,
            WaterMark = false,
            Keybinds = false,
            Logs = false,
            Velocity = false
        }
        Visuals.Move.IsPosible = function()
            return (not Helpers.Contains(Visuals.Move.Objects, true)) 
        end
    end

    local Handle = {
        Render = {
            AnimationSpeed = 10,
            Screen = render.screen_size(),
            Font = {
                Verdana = {
                    o_11 = render.load_font("Verdana", 11, 'o'),
                    b_10 = render.load_font("Verdana", 10, 'b'),
                },
                New = {
                    a_16 = Files.LoadFont(Files.DownloadFiles.FontMenu, 16, 'a'),
                    a_13 = Files.LoadFont(Files.DownloadFiles.FontMenu, 16, 'a')
                }
            },
            Countainer = function(VectorStart, VectprEnd, Alpha, TopLeft, TopRight, ButtomLeft, ButtomRight)
                if TopLeft ~= nil or TopRight ~= nil or ButtomLeft ~= nil or ButtomRight ~= nil then
                    render.gradient(
                        VectorStart, 
                        VectprEnd, 
                        TopLeft ~= nil and Helpers.ColorAlpha(TopLeft, Alpha) or Helpers.ColorAlpha(color(37, 33, 34, 255), Alpha), 
                        TopRight ~= nil and Helpers.ColorAlpha(TopRight, Alpha) or Helpers.ColorAlpha(color(37, 33, 34, 255), Alpha), 
                        ButtomLeft ~= nil and Helpers.ColorAlpha(ButtomLeft, Alpha) or Helpers.ColorAlpha(color(37, 33, 34, 255), Alpha), 
                        ButtomRight ~= nil and Helpers.ColorAlpha(ButtomRight, Alpha) or Helpers.ColorAlpha(color(37, 33, 34, 255), Alpha), 
                        4
                    )
                else
                    render.rect(VectorStart, VectprEnd, Helpers.ColorAlpha(color(37, 33, 34, 255), Alpha), 4)
                end
                
                render.rect_outline(VectorStart, VectprEnd, Helpers.ColorAlpha(color(67, 63, 64, 255), Alpha), 2, 4)
            end,
        },
        Cvars = {
            drawhud = cvar.cl_drawhud,
            OffsetX = cvar.viewmodel_offset_x,
            OffsetY = cvar.viewmodel_offset_y,
            OffsetZ = cvar.viewmodel_offset_z,
            Fov = cvar.viewmodel_fov,
            Aspect = cvar.r_aspectratio
        },
        Scope = {
            ToLenght = 0,
            Spread = 0,
            StartColor = color(255, 255),
            EndColor = color(255, 255)
        },
        Sparks = {
            Mat = nil
        },
        DamageMarker = {
            Table = {}
        },
        HitMarker = {
            Table = {}
        },
        ViewModel = {
            FixValue = false
        },
        AspectRatio = {
            FixValue = false
        },
        Console = { -- {'vgui_white','vgui/hud/800corner1', 'vgui/hud/800corner2', 'vgui/hud/800corner3', 'vgui/hud/800corner4'}
            Materials = {'vgui_white','vgui/hud/800corner1', 'vgui/hud/800corner2', 'vgui/hud/800corner3', 'vgui/hud/800corner4'},
            MatTable = {nil, nil, nil, nil, nil},
            IsFixed = false,
            OldColor = color(255, 255),
        },
        Animation = {
            HookFunction = nil,
        },
        Logs = {
            Alpha = 0,
            Move = {
                x = 0,
                y = 0,
            },
            ChangeValue = 0,
        },
        HUD = {
            Fade = 0,
            WeaponsAlpha = {
                Global = 0,
                Main = 0,
                Second = 0,
                Knife = 0,
                Nades = 0,
                Other = 0,
                AmmoFade = {Main = 0, Second = 0, Knife = 0, Nades = 0, Other = 0}
            },
            FixedChat = false,
            LastWeapon = nil,
            LastTime = 0,
            PlayersDeath = {},
            IsPlant = false,
            RoundStartTime = 0,
            FadeClock = 0,
            Players = {
                CT = {Fade = 0, Last = 0, Time = 0},
                T = {Fafe = 0, Last = 0, Time = 0}
            },
            PlayerChat = {},
            FadeChat = {
                Size = 0,
                IsHave = 0
            },
            RoundData = {Fade = 0, FadeScale = 0, Time = 0, Won = {Team = 3, Message = "CT Won The Round"}}
        },
        Keybinds = {
            Fade = 0,
            KeyList = {},
            WantWidth = 0,
            ActiveWidth = 0,
            BackGround = 0,
            MoveElement = {x = 0, y = 0}
        },
        WaterMark = {
            Fade = 0,
            SizeExtand = 0,
            MoveElement = {x = 0, y = 0}
        },
        WeaponPanel = {
            FadeVector = {x = 0, y = 0},
            ActiveVector = vector(0, 0),
            FadeElements = {}
        },
        Velocity = {
            Fade = 0,
            MoveElement = {x = 0, y = 0}
        },
        CenterScreen = {
            Fade = 0,
            FadeElements = {},
            ScopeState = 0
        },
        Indicators = {
            {
                Name = "doubletap",
                Method = function()
                    return MenuReferences.DoubleTap:get()
                end
            },
            {
                Name = "hide-shots",
                Method = function()
                    return MenuReferences.HideShots:get()
                end
            },
            {
                Name = "min-damage",
                Method = function()
                    local Binds = ui.get_binds()
                    for Index = 1, #Binds do
                        if Binds[Index].name == 'Minimum Damage' then
                            if Binds[Index].active then
                                return true
                            end
                        end
                    end
                    return false
                end
            },
            {
                Name = "freestand",
                Method = function()
                    return MenuReferences.Freestand:get()
                end
            },
            {
                Name = "autopeek",
                Method = function()
                    return MenuReferences.AutoPeek:get()
                end
            },
            {
                Name = "anti-exploit",
                Method = function()
                    return cvar.cl_lagcompensation:int() == 0
                end
            }
        },
        Nades = {
            Molotovs = {
                HandleEntity = {},
                HandleValues = {},
                FadeUp = {Size = {}, Vector = {}},
            },
            Smokes = {
                FadeUp = {}
            }

        },
        Chat = {
            Fade = 0,
            IsOpen = false,
            IsTeam = false,
            LocalSay = "",
            LastKey = nil,
            IsFixInput = false,
            IsCaps = false,
            BindTeamMenu = ""
        }
    }



    local SpecListRender = function()
        if not Menu.DataUI["Visuals"]["Indicators"]["Select Indicators"][2] then
            return
        end

        local LocalPlayer = entity.get_local_player()
        if LocalPlayer == nil or not LocalPlayer:is_alive() then
            return
        end

        local Specs = LocalPlayer:get_spectators()
        if Specs == nil then 
            return
        end

        if #Specs == 0 then
            return
        end

        local Screen = render.screen_size()

        local Add = 0
        for I = 1, #Specs do
            local Spec = Specs[I]

            if Spec == nil then
                goto skip
            end

            local Name = Spec:get_name()

            local NameSize = render.measure_text(1, nil, Name)

            render.text(1, vector(Screen.x - NameSize.x - 5, 5 + Add), color(255, 255), nil, Name)

            Add = Add + 12

            ::skip::
        end
    end

    local IsMolotovWorking = function(MolotovPoint)
        local Fire = MolotovPoint.m_fireCount
        return Fire ~= nil and Fire > 0
    end

    local OnCreateMove = function(cmd)
        if not Menu.DataUI["Visuals"]["Indicators"]["Select Indicators"][3] then
            return
        end

        local LocalPlayer = entity.get_local_player()
        if LocalPlayer == nil or not LocalPlayer:is_alive() then
            return
        end

        Handle.Nades.Molotovs.HandleValues = {}
        Handle.Nades.Molotovs.HandleEntity = entity.get_entities("CInferno")

        local CellRadius = 40

        if #Handle.Nades.Molotovs.HandleEntity == 0 then
            return
        end

        if Handle.Nades.Molotovs.HandleEntity == nil then
            return
        end

        for I = 1, #Handle.Nades.Molotovs.HandleEntity do
            
            local Molotov = Handle.Nades.Molotovs.HandleEntity[I]
            if not IsMolotovWorking(Molotov) then
                goto skip
            end

            local MolotovVector = Molotov.m_vecOrigin

            local Cells = {}
            local MaxDistance = 0
            local CellMax1, CellMax2

            for I = 1, 64 do
                if Molotov.m_bFireIsBurning[I] then
                    local XDelta = Molotov.m_fireXDelta[I]
                    local YDelta = Molotov.m_fireYDelta[I]
                    local ZDelta = Molotov.m_fireZDelta[I]
                    table_insert(Cells, {XDelta, YDelta, ZDelta})
                end
            end

            for i = 1, #Cells do
                local Cell = Cells[i]
                
                local XD, YD, ZD = unpack(Cell)

                for j = 1, #Cells do
                    local SecondCell = Cells[j]
                    local Distance = math_sqrt((SecondCell[1] - XD)^2 + (SecondCell[2] - YD)^2)
                    if Distance > MaxDistance then
                        MaxDistance = Distance
                        CellMax1 = Cell
                        CellMax2 = SecondCell
                    end
                end
            end

            if CellMax1 ~= nil and CellMax2 ~= nil then
                local VectorCell1 = vector(unpack(CellMax1))
                local VectorCell2 = vector(unpack(CellMax2))

                local FadedVector = VectorCell1:lerp(VectorCell2, 0.5)--Helpers.LerpVector(VectorCell1, VectorCell2, 10)
                local FinalVector = MolotovVector + FadedVector

                local Radius = MaxDistance / 2 + CellRadius

                Handle.Nades.Molotovs.HandleValues[Molotov] = {FinalVector, Radius, Molotov.m_nFireEffectTickBegin}
            end
            ::skip::
        end
    end

    local RenderMolotovs = function()
        if Handle.Nades.Molotovs.HandleEntity == nil then
            return
        end

        if #Handle.Nades.Molotovs.HandleEntity == 0 then
            return
        end

        local Color = Menu.DataUI["Visuals"]["Colors"]["Molotov Color"]:clone()

        local TimeStartBurn = {}
        for I = 1, #Handle.Nades.Molotovs.HandleEntity do
            local Molotov = Handle.Nades.Molotovs.HandleEntity[I]

            if Molotov == nil then
                goto skip
            end

            if Handle.Nades.Molotovs.HandleValues[Molotov] == nil then
                goto skip
            end

            local VectorMolotov = Handle.Nades.Molotovs.HandleValues[Molotov][1]
            local Radius = Handle.Nades.Molotovs.HandleValues[Molotov][2]
            local TickStart = Handle.Nades.Molotovs.HandleValues[Molotov][3]

            local Index = I

            if Handle.Nades.Molotovs.FadeUp.Size[Index] == nil then
                Handle.Nades.Molotovs.FadeUp.Size[Index] = 0
            end

            if Handle.Nades.Molotovs.FadeUp.Vector[Index] == nil then
                Handle.Nades.Molotovs.FadeUp.Vector[Index] = VectorMolotov
            end

            local Time = math.max(0.0, string.format("%.1f", 7.03125 -  globals.tickinterval * (globals.tickcount - TickStart))) / 7
            Handle.Nades.Molotovs.FadeUp.Size[Index] = Helpers.Lerp(Handle.Nades.Molotovs.FadeUp.Size[Index], Time < 0.1 and 0 or Radius, 10)
            Handle.Nades.Molotovs.FadeUp.Vector[Index] = Helpers.LerpVector(Handle.Nades.Molotovs.FadeUp.Vector[Index], VectorMolotov, 20)
            
            if Menu.DataUI["Visuals"]["Indicators"]["Outline Radius"] then
                render.circle_3d_outline(Handle.Nades.Molotovs.FadeUp.Vector[Index], Color, Handle.Nades.Molotovs.FadeUp.Size[Index], 0, 1, 1)
            else
                render.circle_3d_gradient(Handle.Nades.Molotovs.FadeUp.Vector[Index], Color, color(0, 0, 0, 0), Handle.Nades.Molotovs.FadeUp.Size[Index], 0, 1)
            end
            

            ::skip::
        end
    end

    local RenderSmokes = function()
        local Smokes = entity.get_entities("CSmokeGrenadeProjectile")
        if Smokes == nil then
            return
        end

        if #Smokes == 0 then
            return
        end

        local Color = Menu.DataUI["Visuals"]["Colors"]["Smoke Color"]:clone()
        
        for I = 1, #Smokes do
            local Smoke = Smokes[I]
            if Smoke == nil then 
                goto skip
            end

            

            local SmokeVector = Smoke.m_vecOrigin
            local TickStart = Smoke.m_nSmokeEffectTickBegin
            local Index = Smoke:get_index()
            local Time = math.max(0.0, string.format("%.1f", 17.55 -  globals.tickinterval * (globals.tickcount - TickStart)))

            if Handle.Nades.Smokes.FadeUp[Index] == nil then
                Handle.Nades.Smokes.FadeUp[Index] = 0
            end

            Handle.Nades.Smokes.FadeUp[Index] = Helpers.Lerp(Handle.Nades.Smokes.FadeUp[Index], Time < 0.1 and 0 or 125, 10)
            if Menu.DataUI["Visuals"]["Indicators"]["Outline Radius"] then
                render.circle_3d_outline(SmokeVector, Color, Handle.Nades.Smokes.FadeUp[Index], 0, 1, 1)
            else
                render.circle_3d_gradient(SmokeVector, Color, color(0, 0, 0, 0), Handle.Nades.Smokes.FadeUp[Index], 0, 1)
            end

            ::skip::
        end
    end

    local NadesRender = function()

        if not Menu.DataUI["Visuals"]["Indicators"]["Select Indicators"][3] then
            return
        end

        RenderMolotovs()
        RenderSmokes()

    end

    local SparksOnImpact = function(event) -- we use bullet impact event to access every impact .. 
        --native_Sparks // (Visuals_Visuals, "Only Local Impacts"
        if not Menu.DataUI["Visuals"]["Visuals"]["Visuals Options"][2] then
            return
        end

        local LocalPlayer = entity.get_local_player()
        if LocalPlayer == nil then
            return
        end

        local Player = entity.get(event.userid, true)
        if Player == nil then
            return
        end

        if Menu.DataUI["Visuals"]["Visuals"]["Only Local Impacts"] then
            if Player ~= LocalPlayer or not LocalPlayer:is_alive() then
                return
            end
        end

        local event_x = event.x
        local event_y = event.y
        local event_z = event.z

        if event_x == nil or event_y == nil or event_x == nil then
            return
        end

        --Visuals_Colors, "Sparks Color"Menu.DataUI["Visuals"]["Colors"]["Sparks Color"]
        if not Handle.Sparks.Mat then
            Handle.Sparks.Mat = native_FindMaterialByName("effects/spark", nullchar, true, nullchar)
        else
            local Color = Menu.DataUI["Visuals"]["Colors"]["Sparks Color"]:clone()

            native_AlphaModulate(Handle.Sparks.Mat, Color.a / 255)
            native_ColorModulate(Handle.Sparks.Mat, Color.r / 255, Color.g / 255, Color.b / 255)
        end
    
        local VectorSpark = vector(event_x, event_y, event_z)
        native_Sparks(Vector3_t((VectorSpark):unpack()), 5, 2, Vector3_t()) -- // 5 is amount as i understand and 2 is the 1 spark size. ig 5 & 2 is fine for now . 
        -- interesting if chaning 5 and 2 will some how will have impact on the pc prefs
    end

    local ScopeChange = function()
        if not Menu.DataUI["Visuals"]["Visuals"]["Visuals Options"][1] then
            return
        end

        if not Menu.DataUI["Visuals"]["Visuals"]["Visuals Options"][1] then
            MenuReferences.Scope:override(nil)
            return
        end

        MenuReferences.Scope:override("Remove All")

        local LocalPlayer = entity.get_local_player()
        if LocalPlayer == nil or not LocalPlayer:is_alive() then
            return
        end

        local ActiveWeapon = LocalPlayer:get_player_weapon()
        if ActiveWeapon == nil then
            return
        end

        local ScopeCache = {
            Origin = Menu.DataUI["Visuals"]["Visuals"]["Scope Origin"],
            Width = Menu.DataUI["Visuals"]["Visuals"]["Scope Width"],
            Color = Menu.DataUI["Visuals"]["Colors"]["Scope Color"]
        }

        Handle.Scope.ToLenght = Helpers.Lerp(Handle.Scope.ToLenght, LocalPlayer.m_bIsScoped and ScopeCache.Width or 0, Handle.Render.AnimationSpeed * 2)
        Handle.Scope.Spread = Helpers.Lerp(Handle.Scope.Spread, (not LocalPlayer.m_bIsScoped or not Menu.DataUI["Visuals"]["Visuals"]["Spread Offset"]) and 0 or ActiveWeapon:get_inaccuracy() * 100, Handle.Render.AnimationSpeed * 2)

        Handle.Scope.StartColor = Helpers.Lerp(Handle.Scope.StartColor, Menu.DataUI["Visuals"]["Visuals"]["Scope Mode"] == "Gradient Invert" and Helpers.ColorAlpha(ScopeCache.Color, 0) or Helpers.ColorAlpha(ScopeCache.Color, 1), Handle.Render.AnimationSpeed)
        Handle.Scope.EndColor = Helpers.Lerp(Handle.Scope.EndColor, Menu.DataUI["Visuals"]["Visuals"]["Scope Mode"] == "Gradient" and Helpers.ColorAlpha(ScopeCache.Color, 0) or Helpers.ColorAlpha(ScopeCache.Color, 1), Handle.Render.AnimationSpeed)

        --Handle.Render.Screen ScopeCache.Origin ScopeCache.Width

        if Handle.Scope.ToLenght > 1 then
            render.gradient(vector(Handle.Render.Screen.x / 2, Handle.Render.Screen.y / 2 - ScopeCache.Origin - ScopeCache.Width + Handle.Scope.ToLenght - Handle.Scope.Spread), vector(Handle.Render.Screen.x / 2 + 1, Handle.Render.Screen.y / 2 - ScopeCache.Origin - ScopeCache.Width - Handle.Scope.Spread), Handle.Scope.StartColor, Handle.Scope.StartColor, Handle.Scope.EndColor, Handle.Scope.EndColor)
            render.gradient(vector(Handle.Render.Screen.x / 2 - ScopeCache.Origin - ScopeCache.Width + Handle.Scope.ToLenght - Handle.Scope.Spread, Handle.Render.Screen.y / 2), vector(Handle.Render.Screen.x / 2 - ScopeCache.Origin - ScopeCache.Width - Handle.Scope.Spread, Handle.Render.Screen.y / 2  + 1), Handle.Scope.StartColor, Handle.Scope.EndColor, Handle.Scope.StartColor, Handle.Scope.EndColor)
            render.gradient(vector(Handle.Render.Screen.x / 2, Handle.Render.Screen.y / 2 + ScopeCache.Origin + ScopeCache.Width - Handle.Scope.ToLenght + Handle.Scope.Spread), vector(Handle.Render.Screen.x / 2 + 1, Handle.Render.Screen.y / 2 + ScopeCache.Origin + ScopeCache.Width + Handle.Scope.Spread), Handle.Scope.StartColor, Handle.Scope.StartColor, Handle.Scope.EndColor, Handle.Scope.EndColor)
            render.gradient(vector(Handle.Render.Screen.x / 2 + ScopeCache.Origin + ScopeCache.Width - Handle.Scope.ToLenght + Handle.Scope.Spread, Handle.Render.Screen.y / 2), vector(Handle.Render.Screen.x / 2  + ScopeCache.Origin + ScopeCache.Width + Handle.Scope.Spread, Handle.Render.Screen.y / 2  + 1), Handle.Scope.StartColor, Handle.Scope.EndColor, Handle.Scope.StartColor,Handle.Scope.EndColor)
        end
    end

    local PlayerHurt = function(event)
        local RealTime = globals.realtime

        local LocalPlayer = entity.get_local_player()
        if LocalPlayer == nil then
            return
        end

        local Player = entity.get(event.userid, true)
        if Player == nil then
            return
        end

        local event_x, event_y, event_z = Player.m_vecOrigin.x, Player.m_vecOrigin.y, Player.m_vecOrigin.z
        if event_x == nil or event_y == nil or event_z == nil then
            return
        end

        table_insert(Handle.DamageMarker.Table, {Damage = event.dmg_health, Time = RealTime, Vector = vector(event_x, event_y, event_z + 50), HitGroup = event.hitgroup, Alpha = 0})
    end

    local PlayerDeath = function(event)
        --Handle.HUD.PlayersDeath = {}
        -- // note : at this moment i will just render the weapon that was used
        local LocalPlayer = entity.get_local_player()
        local Attacker = entity.get(event.attacker, true)
        local Victim = entity.get(event.userid, true)
        if Victim == nil then
            return
        end
        if Attacker == nil then
            return
        end
        local Weapon = Attacker:get_player_weapon()
        if Weapon == nil then
            return
        end
        local WeaponIcon = Weapon:get_weapon_icon() 
        table_insert(Handle.HUD.PlayersDeath, {
            Victim = Victim:get_name(),
            Attacker = Attacker:get_name(),
            Weapon = WeaponIcon,
            CurrentTime = globals.realtime,
            FadeTime = (Attacker == LocalPlayer) and 99999 or 6,
            Fade = 0,
            IsMe = Attacker == LocalPlayer
        })
    end

    local PlayerSay = function(event) -- player_say
        local LocalPlayer = entity.get_local_player()
        if LocalPlayer == nil then 
            return
        end

        local Entity = entity.get(event.userid, true)
        if Entity == nil then
            return
        end

        local Text = event.text
        if Text == nil then
            return
        end

        --local StartColor = (Entity.m_iTeamNum == 3) and color(100, 100, 200, 255) or (Entity.m_iTeamNum == 2 and color(200, 100, 100, 255) or color(255, 255))
        local EntityName = Entity:get_name() -- (Entity.m_iTeamNum == 3) and "CT" or (Entity.m_iTeamNum == 2 and "T" or "?")
        local IsAlive = Entity:is_alive()
        local Time = globals.realtime

        table_insert(Handle.HUD.PlayerChat, {
            PlayerName = EntityName,
            SayText = Text,
            Alive = IsAlive,
            Time = Time,
            Fade = 0,
            Fixed = 1,
            Team = Entity.m_iTeamNum,
        })
    end

    local RoundEnds = function(event)
        local LocalPlayer = entity.get_local_player()
        if LocalPlayer == nil then 
            return
        end

        if event.winner ~= 2 and event.winner ~= 3 then
            return
        end

        Handle.HUD.RoundData.Time = globals.realtime
        Handle.HUD.RoundData.Won.Team = event.winner
        Handle.HUD.RoundData.Won.Message = (event.winner == 3 and "CT" or (event.winner == 2 and "T" or "?")) .. " Won The Round"
    end

    local RoundStart = function(event)
        -- reset the table
        Handle.HUD.PlayersDeath = {}
        Misc.TableLogs = {}
        Handle.DamageMarker.Table = {}
        Handle.HitMarker.Table = {}
        Handle.HUD.IsPlant = false
        Handle.HUD.RoundStartTime = globals.curtime
        Handle.HUD.Players.CT.Time = globals.realtime
        Handle.HUD.Players.T.Time = globals.realtime
    end

    local BombPlant = function(event)
        Handle.HUD.IsPlant = true
        Handle.HUD.RoundStartTime = globals.curtime
    end

    local DamageRender = function()
        if not Menu.DataUI["Visuals"]["Visuals"]["Visuals Options"][3] then
            return
        end

        local LocalPlayer = entity.get_local_player()
        if LocalPlayer == nil then
            return
        end

        local TimeMax = 5 -- // 5 second ig its ok

        for Index, Damage in pairs(Handle.DamageMarker.Table) do
            if Damage.Time + TimeMax < globals.realtime then
                Damage.Alpha = Helpers.Lerp(Damage.Alpha, 0, Handle.Render.AnimationSpeed)
                if Damage.Alpha == 0 then
                    table_remove(Handle.DamageMarker.Table, Index)
                end
            else
                Damage.Alpha = Helpers.Lerp(Damage.Alpha, 1, Handle.Render.AnimationSpeed * 3)
            end

            local ColorDamage = Damage.HitGroup == 1 and Menu.DataUI["Visuals"]["Colors"]["Head Color"] or Menu.DataUI["Visuals"]["Colors"]["Other Color"]

            render.text(1, render.world_to_screen(Damage.Vector), Helpers.ColorAlpha(ColorDamage, Damage.Alpha), nil, Helpers.LerpText(Damage.Damage, Damage.Alpha))
            Damage.Vector.z = Damage.Vector.z + (0.4*(2 / 3))
        end
    end

    local BulletVector = function(shot)
        table_insert(Handle.HitMarker.Table, {Vector = shot.aim, Time = globals.realtime, Alpha = 0})
    end

    local HitMarkerRender = function()
        if not Menu.DataUI["Visuals"]["Visuals"]["Visuals Options"][4] then
            return
        end

        local LocalPlayer = entity.get_local_player()
        if LocalPlayer == nil then
            return
        end

        local TimeMax = 5

        for Index, Marker in pairs(Handle.HitMarker.Table) do
            --
            if Marker.Time + TimeMax < globals.realtime then
                Marker.Alpha = Helpers.Lerp(Marker.Alpha, 0, Handle.Render.AnimationSpeed)

                if Marker.Alpha == 0 then
                    table_remove(Handle.HitMarker.Table, Index)
                end
            else
                Marker.Alpha = Helpers.Lerp(Marker.Alpha, 1, Handle.Render.AnimationSpeed)
            end

            local Color = Menu.DataUI["Visuals"]["Colors"]["Marker Color"]
            local ScreenVector = render.world_to_screen(Marker.Vector)
            if ScreenVector == nil then
                goto skip
            end

            --Hitmarker Data
            local Size = 5
            
            --Visuals_Visuals, "Hit Marker Type", {"Line +", "Gradient +", "Invert Gradient +", "Line x"}
            Helpers.Switch(Menu.DataUI["Visuals"]["Visuals"]["Hit Marker Type"],
                Helpers.Case("Line +", function()
                    render.line(ScreenVector + vector(-Size, 0), ScreenVector + vector(Size, 0), Helpers.ColorAlpha(Color, Marker.Alpha))
                    render.line(ScreenVector + vector(0, -Size), ScreenVector + vector(0, Size), Helpers.ColorAlpha(Color, Marker.Alpha))
                    
                end),
                Helpers.Case("Gradient +", function()
                    render.gradient(ScreenVector + vector(0, -Size-2), ScreenVector + vector(1, -2), Helpers.ColorAlpha(Color, 0), Helpers.ColorAlpha(Color, 0), Helpers.ColorAlpha(Color, Marker.Alpha), Helpers.ColorAlpha(Color, Marker.Alpha))
                    render.gradient(ScreenVector + vector(-Size-2, 0), ScreenVector + vector(-2, 1), Helpers.ColorAlpha(Color, 0), Helpers.ColorAlpha(Color, Marker.Alpha), Helpers.ColorAlpha(Color, 0), Helpers.ColorAlpha(Color, Marker.Alpha))
                    render.gradient(ScreenVector + vector(0, 2), ScreenVector + vector(1, Size+2), Helpers.ColorAlpha(Color, Marker.Alpha), Helpers.ColorAlpha(Color, Marker.Alpha), Helpers.ColorAlpha(Color, 0), Helpers.ColorAlpha(Color, 0))
                    render.gradient(ScreenVector + vector(2, 0), ScreenVector + vector(Size+2, 1), Helpers.ColorAlpha(Color, Marker.Alpha), Helpers.ColorAlpha(Color, 0), Helpers.ColorAlpha(Color, Marker.Alpha), Helpers.ColorAlpha(Color, 0))
                end),
                Helpers.Case("Invert Gradient +", function()
                    render.gradient(ScreenVector + vector(0, -Size-2), ScreenVector + vector(1, -2), Helpers.ColorAlpha(Color, Marker.Alpha), Helpers.ColorAlpha(Color, Marker.Alpha), Helpers.ColorAlpha(Color, 0), Helpers.ColorAlpha(Color, 0))
                    render.gradient(ScreenVector + vector(-Size-2, 0), ScreenVector + vector(-2, 1), Helpers.ColorAlpha(Color, Marker.Alpha), Helpers.ColorAlpha(Color, 0), Helpers.ColorAlpha(Color, Marker.Alpha), Helpers.ColorAlpha(Color, 0))
                    render.gradient(ScreenVector + vector(0, 2), ScreenVector + vector(1, Size+2), Helpers.ColorAlpha(Color, 0), Helpers.ColorAlpha(Color, 0), Helpers.ColorAlpha(Color, Marker.Alpha), Helpers.ColorAlpha(Color, Marker.Alpha))
                    render.gradient(ScreenVector + vector(2, 0), ScreenVector + vector(Size+2, 1), Helpers.ColorAlpha(Color, 0), Helpers.ColorAlpha(Color, Marker.Alpha), Helpers.ColorAlpha(Color, 0), Helpers.ColorAlpha(Color, Marker.Alpha))
                end),
                Helpers.Case("Line x", function()
                    render.line(ScreenVector + vector(-Size, -Size), ScreenVector + vector(Size, Size), Helpers.ColorAlpha(Color, Marker.Alpha))
                    render.line(ScreenVector + vector(-Size, Size), ScreenVector + vector(Size, -Size), Helpers.ColorAlpha(Color, Marker.Alpha))
                end)
            )

            ::skip::
        end
    end

    local OverrideViewModel = function(...)
        local Args = {...}

        Handle.Cvars.OffsetX:int(Args[1], true)
        Handle.Cvars.OffsetY:int(Args[2], true)
        Handle.Cvars.OffsetZ:int(Args[3], true)
        Handle.Cvars.Fov:int(Args[4], true)
    end

    local ViewModelRender = function()
        if not Menu.DataUI["Visuals"]["Visuals"]["Visuals Options"][5] then
            if Handle.ViewModel.FixValue == true then
                OverrideViewModel(0, 0, 0, 60)
                Handle.ViewModel.FixValue = false
            end
            return
        end

        local FinalValues = {
            Menu.DataUI["Visuals"]["Visuals"]["Offset X"],
            Menu.DataUI["Visuals"]["Visuals"]["Offset Y"],
            Menu.DataUI["Visuals"]["Visuals"]["Offset Z"],
            Menu.DataUI["Visuals"]["Visuals"]["Offset Fov"]
        }

        OverrideViewModel(unpack(FinalValues))
        Handle.ViewModel.FixValue = true
    end

    local AspectRatioRender = function()
        --Handle.AspectRatio.FixValue = false
        if not Menu.DataUI["Visuals"]["Visuals"]["Visuals Options"][6] then
            if Handle.AspectRatio.FixValue == true then
                Handle.Cvars.Aspect:float(0, true)
                Handle.AspectRatio.FixValue = false
            end
            return
        end

        local SliderValue = Menu.DataUI["Visuals"]["Visuals"]["Aspect Ratio"]

        local Mult = 2 - (SliderValue * 0.01)
        local NewValue = (Handle.Render.Screen.x * Mult) / Handle.Render.Screen.y

        if Mult == 1 then
            NewValue = 0
        end

        Handle.Cvars.Aspect:float(NewValue, true)
        Handle.AspectRatio.FixValue = true
    end

    local FindNameMaterial = function()
        if Handle.Console.MatTable[1] then
            return
        end
        
        local material = native_FirstMaterial()
        local found_count = 0

        while (found_count < 5 ) 
        do
            local mat = native_FindMaterial(material)
            local name = native_GetName(mat)

            for i = 1, #Handle.Console.Materials do 
                if ffi.string(name) == Handle.Console.Materials[i] then
                    Handle.Console.MatTable[i] = mat
                    found_count = found_count + 1
                end
            end

            material = native_NextMaterial(material)
        end
    end

    local OverideColor = function(Color)
        for Index, Mat in pairs(Handle.Console.MatTable) do
            native_ColorModulate(Mat, Color.r / 255, Color.g / 255, Color.b / 255)
            native_AlphaModulate(Mat, Color.a / 255)
        end
    end

    local ConsoleRender = function()
        if not Menu.DataUI["Visuals"]["Visuals"]["Visuals Options"][7] then
            if Handle.Console.IsFixed == true and Handle.Console.OldColor ~= color(255, 255) then
                Handle.Console.OldColor = Helpers.Lerp(Handle.Console.OldColor, color(255, 255), Handle.Render.AnimationSpeed)
                OverideColor(Handle.Console.OldColor)
                if Handle.Console.OldColor == color(255, 255) then
                    Handle.Console.IsFixed = false
                end
            end
            return
        end

        FindNameMaterial()
        local Color = Menu.DataUI["Visuals"]["Colors"]["Console Color"]:clone()
        if not native_IsConsoleOpen() then
            return
        end

        Handle.Console.OldColor = Helpers.Lerp(Handle.Console.OldColor, Color, Handle.Render.AnimationSpeed)

        OverideColor(Handle.Console.OldColor)
        --Handle.Console.OldColor = Color
        Handle.Console.IsFixed = true
    end

    local LocalAntimation = function(thisptr, edx)
        local LocalPlayer = entity.get_local_player()
        Handle.Animation.HookFunction(thisptr, edx)
        
        if not Menu.DataUI["Visuals"]["Visuals"]["Visuals Options"][8] then
            return
        end

        if Menu.DataUI["Visuals"]["Visuals"]["Legs Options"][1] then
            LocalPlayer.m_flPoseParameter[6] = 1
        end
        if Menu.DataUI["Visuals"]["Visuals"]["Legs Options"][2] then
            LocalPlayer.m_flPoseParameter[0] = globals.tickcount % 3 == 0 and (Menu.DataUI["Visuals"]["Visuals"]["Move Legs Jitter"] / 10) or 1
        end

        --[[
        0 :
        0.5 - forward
        0.8 - 0.9 still
        1 - backward
        --]]
    end

    local UpdateHook = function()
        local LocalPlayer = entity.get_local_player() -- native_GetClientEntity
        if LocalPlayer == nil or not LocalPlayer:is_alive() then
            return
        end

        local LocalEntity = native_GetClientEntity(LocalPlayer:get_index())
        if not LocalEntity or Handle.Animation.HookFunction then
            return
        end

        local NewPoint = VMTHook.new(LocalEntity)
        Handle.Animation.HookFunction = NewPoint.HookMethod("void(__fastcall*)(void*, void*)", LocalAntimation, 224)
    end

    local RenderMultiColorText = function(Font, Vector, GlobalAlpha, Table)
        if #Table == 0 then
            return
        end

        local TextSize = 0

        --[[
        [1] == Text
        [2] == Color
        --]]

        for Index, Item in pairs(Table) do
            render.text(Font, Vector + vector(TextSize, 0), Helpers.ColorAlpha(Item[2], GlobalAlpha), nil, tostring(Item[1]))
            TextSize = TextSize + render.measure_text(Font, nil, tostring(Item[1])).x
        end

        return TextSize -- // i will use it to center it insted of calling seperate function.
    end

    local CalculateText = function(font, data, Text)
        local TextSize = {x = 0, y = 0}

        for I, Item in pairs(Text) do
            local SelectedTable = render.measure_text(font, data, tostring(Item[1]))
            TextSize.x = TextSize.x + SelectedTable.x -- // since i know it will be used for multi color
            if SelectedTable.y >= TextSize.y then
                TextSize.y = SelectedTable.y -- // no metter what will be
            end
        end
            


        return TextSize
    end

    local RenderNewLog = function(Vector, Text, Icon, Alpha, Color, Disable, Center)

        -- @ render background
        local TextSize = CalculateText(Handle.Render.Font.Verdana.o_11, nil, Text)
        local YBack = 30

        local IconAdd = not Disable and Icon.Size.x + 10 or 5 -- // i will use local icon table
        local BackGround = Center and (TextSize.x + IconAdd + 5) / 2 or 0

        
        render.rect(Vector + vector(-BackGround, 0), Vector + vector(TextSize.x + IconAdd + 5 - BackGround, YBack), Helpers.ColorAlpha(Menu.DataUI["Misc"]["Misc"]["Background Logs"]:clone(), Alpha), 4)
        if Menu.DataUI["Misc"]["Misc"]["Background Logs"]:clone().a > 0 then
            render.rect_outline(Vector + vector(-BackGround, 0), Vector + vector(TextSize.x + IconAdd + 5 - BackGround, YBack), Helpers.ColorAlpha(Menu.DataUI["Misc"]["Misc"]["Outline Logs"]:clone(), Alpha), 1, 4)
        end
        --render.rect(Vector + vector(-BackGround, 0), Vector + vector(TextSize.x + IconAdd + 5 - BackGround, YBack), Helpers.ColorAlpha(Menu.DataUI["Misc"]["Misc"]["Background Logs"]:clone(), Alpha), 4) 
        if not Disable then
            render.rect(Vector + vector(5 - BackGround, 5), Vector + vector(5 - BackGround, 5) + Icon.Size, Helpers.ColorAlpha(Menu.DataUI["Misc"]["Misc"]["Icon Background Logs"]:clone(), Alpha), 4)
            render.texture(Icon.Image, Vector + vector(5 - BackGround, 5), Icon.Size, Helpers.ColorAlpha(Color, Alpha))
        end

        RenderMultiColorText(Handle.Render.Font.Verdana.o_11, Vector + vector(IconAdd - BackGround, YBack / 2 - TextSize.y / 2), Alpha, Text)
        return {x = TextSize.x + IconAdd + 5, y = YBack, xCenter = BackGround}
    end

    local LogsRender = function()
        --Misc.TableLogs
        local TimeVisible = #Misc.TableLogs > 10 and 2 or 5
        local Mouse = ui.get_mouse_position()
        
        if Helpers.IsMenuVisible() and Menu.DataUI["Misc"]["Misc"]["Logs Options"][2] then
            Handle.Logs.Alpha = Helpers.Lerp(Handle.Logs.Alpha, 1, Handle.Render.AnimationSpeed)
        else
            Handle.Logs.Alpha = Helpers.Lerp(Handle.Logs.Alpha, 0, Handle.Render.AnimationSpeed)
        end

        local VectorLogs = vector(Menu.Neverlose.LogsVectorX:get(), Menu.Neverlose.LogsVectorY:get()) --// for now lets set it to 10, 5
        local DisableIcon = Menu.DataUI["Misc"]["Misc"]["Disable Icon"]

        -- @ center option
        local XChange = Menu.Neverlose.LogsVectorX:get() > 300


        local ReturnSize = RenderNewLog(VectorLogs, {
            {"example log, ", color(255, 255, 255, 255)},
            {"you ", Menu.Neverlose.MainColor:get()},
            {"can ", color(255, 255, 255, 255)},
            {"move ", Menu.Neverlose.MainColor:get()},
            {"it and ", color(255, 255, 255, 255)},
            {"change styles ", Menu.Neverlose.MainColor:get()}
        }, Files.image_LoadLog, Handle.Logs.Alpha, Menu.Neverlose.MainColor:get(), DisableIcon, XChange)

        local AdditionY = Handle.Logs.Alpha
        local Lower = Menu.DataUI["Misc"]["Misc"]["Background Logs"]:clone().a < 2 and 22 or 40

        for Index, SelectedLog in ipairs(Misc.TableLogs) do

            SelectedLog[3] = Helpers.Lerp(SelectedLog[3], (SelectedLog[2] + TimeVisible < globals.realtime) and 0 or 1, Handle.Render.AnimationSpeed)

            RenderNewLog(VectorLogs + vector(0, AdditionY * Lower), SelectedLog[1], SelectedLog[6], SelectedLog[3], SelectedLog[5], DisableIcon, XChange)

            AdditionY = AdditionY + (SelectedLog[3])
        end

        if #Misc.TableLogs > 20 then
            table_remove(Misc.TableLogs, 1)
        end

        -- @ move object 
        local IsHovered = Helpers.IsInBox(VectorLogs + vector(-ReturnSize.xCenter, 0), ReturnSize.x, ReturnSize.y)

        if IsHovered then
            if common.is_button_down(1) and Visuals.Move.IsPosible() then
                Visuals.Move.Objects.Logs = true
                Handle.Logs.Move.x = Menu.Neverlose.LogsVectorX:get() - Mouse.x
                Handle.Logs.Move.y = Menu.Neverlose.LogsVectorY:get() - Mouse.y
            end

            if common.is_button_down(2) and globals.realtime > Handle.Logs.ChangeValue + 0.2 then
                Handle.Logs.ChangeValue = globals.realtime
                Menu.Neverlose.LogsIcon.Point.UI[Menu.Neverlose.LogsIcon.Index].Value = not Menu.Neverlose.LogsIcon.Point.UI[Menu.Neverlose.LogsIcon.Index].Value
                --Menu.DataUI["Misc"]["Misc"]["Disable Icon"] = not Menu.DataUI["Misc"]["Misc"]["Disable Icon"]
            end
        end

        if not common.is_button_down(1) then
            Visuals.Move.Objects.Logs = false
        end

        if Visuals.Move.Objects.Logs and Helpers.IsMenuVisible() then
            Menu.Neverlose.LogsVectorX:set(Handle.Logs.Move.x + Mouse.x)
            Menu.Neverlose.LogsVectorY:set(Handle.Logs.Move.y + Mouse.y)
        end

    end

    local CenterScreenIndicators = function()
        local LocalPlayer = entity.get_local_player()
        if LocalPlayer == nil or not LocalPlayer:is_alive() then
            return
        end

        if not Menu.DataUI["Visuals"]["Indicators"]["Select Indicators"][1] then
            Handle.CenterScreen.Fade = Helpers.Lerp(Handle.CenterScreen.Fade, 0, 20)
            if Handle.CenterScreen.Fade == 0 then
                return
            end
        else
            Handle.CenterScreen.Fade = Helpers.Lerp(Handle.CenterScreen.Fade, 1, 20)
        end

        local Screen = render.screen_size()
        local Vector = vector(Screen.x/2, Screen.y/2 + 5)

        local BackGround = Menu.DataUI["Visuals"]["Colors"]["Indicator Background Color"]:clone()
        local Fade = Menu.DataUI["Visuals"]["Colors"]["Indicator Fade Color"]:clone()

        local NameColors = {
            Menu.DataUI["Visuals"]["Indicators"]["Invert Name Colors"] and Fade or BackGround,
            Menu.DataUI["Visuals"]["Indicators"]["Invert Name Colors"] and BackGround or Fade,
        }

        Handle.CenterScreen.ScopeState = Helpers.Lerp(Handle.CenterScreen.ScopeState, LocalPlayer.m_bIsScoped and 0 or 1, 20)

        local DigitalDreamsSize = render.measure_text(Handle.Render.Font.New.a_13, nil, "Digital-Dreams")
        local AddOnScope = math_abs(Handle.CenterScreen.ScopeState-1) * 5
        Helpers.GradientTextFade(Handle.Render.Font.New.a_13, Vector + vector( - (Handle.CenterScreen.ScopeState * (DigitalDreamsSize.x / 2)) + AddOnScope, 0), {Helpers.ColorAlpha(NameColors[1], Handle.CenterScreen.Fade), Helpers.ColorAlpha(NameColors[2], Handle.CenterScreen.Fade)}, nil, "Digital-Dreams")

        local RenderFade = 20
        for Index, Item in ipairs(Handle.Indicators) do
            if Handle.CenterScreen.FadeElements[Item.Name] == nil then
                Handle.CenterScreen.FadeElements[Item.Name] = 0
            end

            Handle.CenterScreen.FadeElements[Item.Name] = Helpers.Lerp(Handle.CenterScreen.FadeElements[Item.Name], Item.Method() and 1 or 0, 20)

            local ItemNameSize = render.measure_text(Handle.Render.Font.New.a_13, nil, Item.Name)

            --Helpers.GradientTextFade(Handle.Render.Font.New.a_13, Vector + vector(- (Handle.CenterScreen.ScopeState * (ItemNameSize.x / 2)) + AddOnScope, RenderFade), {Helpers.ColorAlpha(BackGround, Handle.CenterScreen.Fade), Helpers.ColorAlpha(Fade, Handle.CenterScreen.Fade)}, nil, Helpers.LerpText(Item.Name, Handle.CenterScreen.FadeElements[Item.Name]))
            render.text(Handle.Render.Font.New.a_13, Vector + vector(- (Handle.CenterScreen.ScopeState * (ItemNameSize.x / 2)) + AddOnScope, RenderFade), Helpers.ColorAlpha(Fade, Handle.CenterScreen.Fade), nil, Helpers.LerpText(Item.Name, Handle.CenterScreen.FadeElements[Item.Name]))

            RenderFade = RenderFade + (15 * Handle.CenterScreen.FadeElements[Item.Name])
        end

    end

    local RenderHealthAndArmor = function(Vector, LocalTable, SizesTable, Alpha)
        local LocalPlayer = entity.get_local_player()
        if LocalPlayer == nil or not LocalPlayer:is_alive() then
            return
        end

        local HealthText, HealthVector = math_min(LocalTable.Health, 100), math_min(LocalTable.Health, 100)
        local ArmorText, ArmorVector = math_min(LocalTable.Armor, 100), math_min(LocalTable.Armor, 100)

        Handle.Render.Countainer(Vector, Vector + SizesTable, Alpha)

        render.rect(Vector + vector(5, 5), Vector + vector(5 + Files.image_LoadArmor.Size.x, 5 + Files.image_LoadArmor.Size.y), Helpers.ColorAlpha(color(35, 255), Alpha), 4)
        render.rect(Vector + vector(5, 10 + Files.image_LoadArmor.Size.y), Vector + vector(5 + Files.image_LoadHealth.Size.x, 10 + Files.image_LoadArmor.Size.y + Files.image_LoadHealth.Size.y), Helpers.ColorAlpha(color(35, 255), Alpha), 4)

        render.texture(Files.image_LoadArmor.Image, Vector + vector(5, 5), Files.image_LoadArmor.Size, Helpers.ColorAlpha(ArmorText == 0 and color(255, 0, 0, 255) or color(255, 255), Alpha))
        render.texture(Files.image_LoadHealth.Image, Vector + vector(5, 10 + Files.image_LoadArmor.Size.y), Files.image_LoadHealth.Size, Helpers.ColorAlpha(HealthText == 0 and color(255, 0, 0, 255) or color(255, 255), Alpha))

        render.text(Handle.Render.Font.New.a_16, Vector + vector(10 + Files.image_LoadArmor.Size.x, 7), Helpers.ColorAlpha(color(255, 255), Alpha), nil, ArmorText)
        render.text(Handle.Render.Font.New.a_16, Vector + vector(10 + Files.image_LoadHealth.Size.x, 12 + Files.image_LoadArmor.Size.y), Helpers.ColorAlpha(color(255, 255), Alpha), nil, HealthText)


        if ArmorVector > 2 then
            render.rect(Vector + vector(37 + Files.image_LoadArmor.Size.x, 13), Vector + vector(35 + Files.image_LoadArmor.Size.x + ArmorVector, 15 + 2), Helpers.ColorAlpha(Menu.Neverlose.MainColor:get(), Alpha), 2)
        end
        
        render.rect(Vector + vector(37 + Files.image_LoadArmor.Size.x, 19 + Files.image_LoadArmor.Size.y), Vector + vector(35 + Files.image_LoadArmor.Size.x + HealthVector, 23 + Files.image_LoadArmor.Size.y), Helpers.ColorAlpha(Menu.Neverlose.MainColor:get(), Alpha), 2)
    end

    local GetWeapons = function(Weapons)
        local WeaponTable = {
            Main = nil,
            Second = nil,
            Knife = {}, -- // for zeus and etc
            Nades = {},
            Other = {}
        }

        for Index, Weapon in pairs(Weapons) do
            if Helpers.IsPrimary(Weapon) then
                WeaponTable.Main = Weapon
                goto skip
            end

            if Helpers.IsPistol(Weapon) then
                WeaponTable.Second = Weapon
                goto skip
            end

            if Helpers.IsKnife(Weapon) then
                --WeaponTable.Knife = Weapon
                WeaponTable.Knife[#WeaponTable.Knife + 1] = Weapon
                goto skip
            end

            if Helpers.IsGranade(Weapon) then
                WeaponTable.Nades[#WeaponTable.Nades + 1] = Weapon
                goto skip
            end 

            WeaponTable.Other[#WeaponTable.Other + 1] = Weapon

            ::skip::
        end

        return WeaponTable
    end

    local GetOverAllIcon = function(Table, Seperate)
        local End = (#Table) * 5
        for I, T in pairs(Table) do
            End = End + T:get_weapon_icon().width
        end
        return End
    end

    local RenderWeapons = function(Vector, VectorSize, TableWeapons, ActiveWeapon, Alpha)
        --Handle.HUD.WeaponsAlpha = {
        --    Main = 0,
        --    Second = 0,
        --    Knife = 0,
        --    Nades = 0
        --},
       -- Handle.Render.Countainer(Vector, Vector + VectorSize, Alpha)
        --local BoxSize = VectorSize.y - 20
        --local Icon = ActiveWeapon:get_weapon_icon()
        --render.rect(Vector + VectorSize + vector(- (Icon.width) - 20, - BoxSize - 10), Vector + VectorSize + vector(-10, -10), Helpers.ColorAlpha(color(25, 255), Alpha), 4)
        --render.texture(Icon, Vector + VectorSize + vector(- (Icon.width) - 15, - (BoxSize / 2) - 10 - (Icon.height) / 2), vector(Icon.width, Icon.height), Helpers.ColorAlpha(color(255, 255), Alpha))

        local Ammo = {
            Main = ActiveWeapon and ActiveWeapon.m_iClip1 or 0,
            Other = ActiveWeapon and ActiveWeapon.m_iPrimaryReserveAmmoCount or 0
        }

        local TextAmmo = tostring(Ammo.Main) .. " / " .. tostring(Ammo.Other)
        local AmmoSize = render.measure_text(Handle.Render.Font.New.a_16, nil, TextAmmo)
        --render.text(Handle.Render.Font.New.a_16, Vector + vector(10, (BoxSize / 2) + 10 - (AmmoSize.y / 2)), Helpers.ColorAlpha(color(255, 255), Alpha), nil, TextAmmo)

        local NormalWeapons = GetWeapons(TableWeapons)
        local XRemove = 0

        if ActiveWeapon ~= Handle.HUD.LastWeapon then
            Handle.HUD.LastTime = globals.realtime
            Handle.HUD.LastWeapon = ActiveWeapon
        end

        Handle.HUD.WeaponsAlpha.Global = Helpers.Lerp(Handle.HUD.WeaponsAlpha.Global, Handle.HUD.LastTime + 5 < globals.realtime and 0 or 1, 20)

        Handle.HUD.WeaponsAlpha.Main = Helpers.Lerp(Handle.HUD.WeaponsAlpha.Main, NormalWeapons.Main and 1 or 0, 20)

        Handle.HUD.WeaponsAlpha.AmmoFade.Main = Helpers.Lerp(Handle.HUD.WeaponsAlpha.AmmoFade.Main, (NormalWeapons.Main ~= nil and ActiveWeapon == NormalWeapons.Main) and 1 or 0, 20)
        Handle.HUD.WeaponsAlpha.AmmoFade.Second = Helpers.Lerp(Handle.HUD.WeaponsAlpha.AmmoFade.Second, (NormalWeapons.Second ~= nil and ActiveWeapon == NormalWeapons.Second) and 1 or 0, 20)
        --Knife = 0, Nades = 0, Other = 0
        Handle.HUD.WeaponsAlpha.AmmoFade.Knife = Helpers.Lerp(Handle.HUD.WeaponsAlpha.AmmoFade.Knife, (NormalWeapons.Knife ~= nil and Helpers.Contains(NormalWeapons.Knife, ActiveWeapon)) and 1 or 0, 20)
        Handle.HUD.WeaponsAlpha.AmmoFade.Nades = Helpers.Lerp(Handle.HUD.WeaponsAlpha.AmmoFade.Nades, (NormalWeapons.Nades ~= nil and Helpers.Contains(NormalWeapons.Nades, ActiveWeapon)) and 1 or 0, 20)
        Handle.HUD.WeaponsAlpha.AmmoFade.Other = Helpers.Lerp(Handle.HUD.WeaponsAlpha.AmmoFade.Other, (NormalWeapons.Other ~= nil and Helpers.Contains(NormalWeapons.Other, ActiveWeapon)) and 1 or 0, 20)

        Handle.HUD.WeaponsAlpha.Second = Helpers.Lerp(Handle.HUD.WeaponsAlpha.Second, NormalWeapons.Second and 1 or 0, 20)
        Handle.HUD.WeaponsAlpha.Knife = Helpers.Lerp(Handle.HUD.WeaponsAlpha.Knife, #NormalWeapons.Knife > 0 and 1 or 0, 20)
        Handle.HUD.WeaponsAlpha.Nades = Helpers.Lerp(Handle.HUD.WeaponsAlpha.Nades, #NormalWeapons.Nades > 0 and 1 or 0, 20)
        Handle.HUD.WeaponsAlpha.Other = Helpers.Lerp(Handle.HUD.WeaponsAlpha.Other, #NormalWeapons.Other > 0 and 1 or 0, 20)

        local Add_Main = 16 * Handle.HUD.WeaponsAlpha.AmmoFade.Main
        if Handle.HUD.WeaponsAlpha.Main > 0 and NormalWeapons.Main ~= nil then
            local IconMain = NormalWeapons.Main:get_weapon_icon()
            Handle.Render.Countainer(Vector + vector(VectorSize.x - (IconMain.width) - 10 - (65 * Handle.HUD.WeaponsAlpha.AmmoFade.Main), - 10 - 40 - Add_Main), Vector + vector(VectorSize.x, - 10), Alpha * Handle.HUD.WeaponsAlpha.Main * (Handle.HUD.WeaponsAlpha.AmmoFade.Main == 1 and 1 or Handle.HUD.WeaponsAlpha.Global))
            render.texture(IconMain, Vector + vector(VectorSize.x - (IconMain.width) - 5, - 10 - 20 - IconMain.height / 2 - Add_Main), vector(IconMain.width, IconMain.height), Helpers.ColorAlpha(color(255, 255), Alpha * Handle.HUD.WeaponsAlpha.Main * (Handle.HUD.WeaponsAlpha.AmmoFade.Main == 1 and 1 or Handle.HUD.WeaponsAlpha.Global) * (NormalWeapons.Main == ActiveWeapon and 1 or 0.4)))
            if Handle.HUD.WeaponsAlpha.AmmoFade.Main > 0 then
                render.text(Handle.Render.Font.New.a_16, Vector + vector(VectorSize.x - (IconMain.width) - 70, - 30 - AmmoSize.y / 2 - Add_Main), Helpers.ColorAlpha(color(255, 255), Alpha * Handle.HUD.WeaponsAlpha.AmmoFade.Main), nil, TextAmmo)
                render.text(Handle.Render.Font.New.a_16, Vector + vector(VectorSize.x - (IconMain.width) - 70, - 30), Helpers.ColorAlpha(color(255, 255), Alpha * Handle.HUD.WeaponsAlpha.AmmoFade.Main), nil, NormalWeapons.Main:get_name())
            end
        end
        XRemove = XRemove + ((- 50 - (Add_Main)) * Handle.HUD.WeaponsAlpha.Main)

        local Add_Second = 16 * Handle.HUD.WeaponsAlpha.AmmoFade.Second
        if Handle.HUD.WeaponsAlpha.Second > 0 and NormalWeapons.Second ~= nil then
            local IconMain = NormalWeapons.Second:get_weapon_icon()
            Handle.Render.Countainer(Vector + vector(VectorSize.x - (IconMain.width) - 10 - (65 * Handle.HUD.WeaponsAlpha.AmmoFade.Second), - 10 - 40 + XRemove - Add_Second), Vector + vector(VectorSize.x, -10 + XRemove), Alpha * Handle.HUD.WeaponsAlpha.Second * (Handle.HUD.WeaponsAlpha.AmmoFade.Second == 1 and 1 or Handle.HUD.WeaponsAlpha.Global))
            render.texture(IconMain, Vector + vector(VectorSize.x - (IconMain.width) - 5, - 10 - 20 - IconMain.height / 2 + XRemove - Add_Second), vector(IconMain.width, IconMain.height), Helpers.ColorAlpha(color(255, 255), Alpha * Handle.HUD.WeaponsAlpha.Second * (Handle.HUD.WeaponsAlpha.AmmoFade.Second == 1 and 1 or Handle.HUD.WeaponsAlpha.Global) * (NormalWeapons.Second == ActiveWeapon and 1 or 0.4)))
            if Handle.HUD.WeaponsAlpha.AmmoFade.Second > 0 then
                render.text(Handle.Render.Font.New.a_16, Vector + vector(VectorSize.x - (IconMain.width) - 70, - 30 - AmmoSize.y / 2 + XRemove - Add_Second), Helpers.ColorAlpha(color(255, 255), Alpha * Handle.HUD.WeaponsAlpha.AmmoFade.Second), nil, TextAmmo)
                render.text(Handle.Render.Font.New.a_16, Vector + vector(VectorSize.x - (IconMain.width) - 70, - 30 + XRemove), Helpers.ColorAlpha(color(255, 255), Alpha * Handle.HUD.WeaponsAlpha.AmmoFade.Second), nil, NormalWeapons.Second:get_name())
            end
        end
        XRemove = XRemove + ((- 50 - (Add_Second)) * Handle.HUD.WeaponsAlpha.Second)

        local Add_Knifes = 16 * Handle.HUD.WeaponsAlpha.AmmoFade.Knife
        if Handle.HUD.WeaponsAlpha.Knife > 0 then
            local AddSize = GetOverAllIcon(NormalWeapons.Knife)
            local NameWeapon = Helpers.Contains(NormalWeapons.Knife, ActiveWeapon, true)
            local BoxAdd = NameWeapon and math_max(AddSize, render.measure_text(Handle.Render.Font.New.a_16, nil, NameWeapon:get_name()).x) or AddSize
            Handle.Render.Countainer(Vector + vector(VectorSize.x - math_max(AddSize, BoxAdd * Handle.HUD.WeaponsAlpha.AmmoFade.Knife) - 10, - 10 - 40 + XRemove - Add_Knifes), Vector + vector(VectorSize.x, -10 + XRemove), Alpha * Handle.HUD.WeaponsAlpha.Knife * (Handle.HUD.WeaponsAlpha.AmmoFade.Knife == 1 and 1 or Handle.HUD.WeaponsAlpha.Global))
            local Add = 0
            for I, Item in pairs(NormalWeapons.Knife) do
                local IconItem = Item:get_weapon_icon()
                render.texture(IconItem, Vector + vector(VectorSize.x - AddSize - 5 + Add, - 10 - 20 - IconItem.height / 2 + XRemove - Add_Knifes), vector(IconItem.width, IconItem.height), Helpers.ColorAlpha(color(255, 255), Alpha * Handle.HUD.WeaponsAlpha.Knife * (Handle.HUD.WeaponsAlpha.AmmoFade.Knife == 1 and 1 or Handle.HUD.WeaponsAlpha.Global) * (Item == ActiveWeapon and 1 or 0.4)))
                Add = Add + IconItem.width + 5
            end
            
            if Handle.HUD.WeaponsAlpha.AmmoFade.Knife > 0 and NameWeapon then
                render.text(Handle.Render.Font.New.a_16, Vector + vector(VectorSize.x - (BoxAdd) - 5, - 30 + XRemove), Helpers.ColorAlpha(color(255, 255), Alpha * Handle.HUD.WeaponsAlpha.AmmoFade.Knife), nil, NameWeapon:get_name())
            end
        end
        XRemove = XRemove + ((- 50 - (Add_Knifes)) * Handle.HUD.WeaponsAlpha.Knife)

        local Add_Nades = 16 * Handle.HUD.WeaponsAlpha.AmmoFade.Nades
        if Handle.HUD.WeaponsAlpha.Nades > 0 then
            local AddSize = GetOverAllIcon(NormalWeapons.Nades)
            local NameWeapon = Helpers.Contains(NormalWeapons.Nades, ActiveWeapon, true)
            local BoxAdd = NameWeapon and math_max(AddSize, render.measure_text(Handle.Render.Font.New.a_16, nil, NameWeapon:get_name()).x) or AddSize
            Handle.Render.Countainer(Vector + vector(VectorSize.x - math_max(AddSize, BoxAdd * Handle.HUD.WeaponsAlpha.AmmoFade.Nades) - 10, - 10 - 40 + XRemove - Add_Nades), Vector + vector(VectorSize.x, -10 + XRemove), Alpha * Handle.HUD.WeaponsAlpha.Nades * (Handle.HUD.WeaponsAlpha.AmmoFade.Nades == 1 and 1 or Handle.HUD.WeaponsAlpha.Global))
            local Add = 0
            for I, Item in pairs(NormalWeapons.Nades) do
                local IconItem = Item:get_weapon_icon()
                render.texture(IconItem, Vector + vector(VectorSize.x - AddSize - 5 + Add, - 10 - 20 - IconItem.height / 2 + XRemove - Add_Nades), vector(IconItem.width, IconItem.height), Helpers.ColorAlpha(color(255, 255), Alpha * Handle.HUD.WeaponsAlpha.Nades * (Handle.HUD.WeaponsAlpha.AmmoFade.Nades == 1 and 1 or Handle.HUD.WeaponsAlpha.Global) * (Item == ActiveWeapon and 1 or 0.4)))
                Add = Add + IconItem.width + 5
            end

            if Handle.HUD.WeaponsAlpha.AmmoFade.Nades > 0 and NameWeapon then
                render.text(Handle.Render.Font.New.a_16, Vector + vector(VectorSize.x - (BoxAdd) - 5, - 30 + XRemove), Helpers.ColorAlpha(color(255, 255), Alpha * Handle.HUD.WeaponsAlpha.AmmoFade.Nades), nil, NameWeapon:get_name())
            end
        end
        XRemove = XRemove + ((- 50 - (Add_Nades)) * Handle.HUD.WeaponsAlpha.Nades)

        if Handle.HUD.WeaponsAlpha.Other > 0 then
            local AddSize = GetOverAllIcon(NormalWeapons.Other)
            Handle.Render.Countainer(Vector + vector(VectorSize.x - AddSize - 10, - 10 - 40 + XRemove), Vector + vector(VectorSize.x, -10 + XRemove), Alpha * Handle.HUD.WeaponsAlpha.Other * Handle.HUD.WeaponsAlpha.Global)
            local Add = 0
            for I, Item in pairs(NormalWeapons.Other) do
                local IconItem = Item:get_weapon_icon()
                render.texture(IconItem, Vector + vector(VectorSize.x - AddSize - 2.5 + Add, - 10 - 20 - IconItem.height / 2 + XRemove), vector(IconItem.width, IconItem.height), Helpers.ColorAlpha(color(255, 255), Alpha * Handle.HUD.WeaponsAlpha.Other * Handle.HUD.WeaponsAlpha.Global * (Item == ActiveWeapon and 1 or 0.4)))
                Add = Add + IconItem.width + 5
            end
        end


    end

    local GetPlayerWeapons = function(Player) -- // when neverlose have broken entity get all weapons XD
        local Table = {}

        for i = 0, 63 do
            local Entity = entity.get(Player.m_hMyWeapons[i])
            if Entity ~= nil then
                Table[#Table + 1] = Entity
            end
        end
        return Table
    end

    local RenderKillFeed = function(VectorUp, Alpha)
        --Handle.HUD.PlayersDeath
        local LocalPlayer = entity.get_local_player()

        local AddVector = 0
        for Index, Kill in ipairs(Handle.HUD.PlayersDeath) do
            -- // same logic like logs hhh
            if not MenuReferences.PreserveKillFeed:get() and Kill.FadeTime ==  99999 then
                Kill.FadeTime = 6
            end

            if Kill.CurrentTime + Kill.FadeTime < globals.realtime then
                Kill.Fade = Helpers.Lerp(Kill.Fade, 0, 10)
                --if Kill.Fade == 0 then
                --    table_remove(Handle.HUD.PlayersDeath, Index)
                --end
            else
                Kill.Fade = Helpers.Lerp(Kill.Fade, 1, 20)
            end

            if Kill.Victim == nil then
                goto skip
            end

            if Kill.Attacker == nil then
                goto skip
            end

            if Kill.Weapon == nil then
                goto skip
            end

            --@ players data
            local VictimName = Kill.Victim--:get_name()

            if VictimName:len() > 50 then
                VictimName = string.sub(VictimName, 1, 50)
                VictimName = VictimName .. "..."
            end

            local AttackerName = Kill.Attacker--:get_name() or "?"

            if AttackerName:len() > 50 then
                AttackerName = string.sub(AttackerName, 1, 50)
                AttackerName = AttackerName .. "..."
            end

            
            local GetWeaponIcon = Kill.Weapon
            if GetWeaponIcon == nil then
                goto skip
            end
            -- // weapon icon need to be in y = 16 if y of the text is 16
            local IconScale = 16.0 / GetWeaponIcon.height -- // we will use it
            local IconSize = vector(GetWeaponIcon.width * IconScale * 0.7, GetWeaponIcon.height * IconScale * 0.7)

            local NamesScale = {
                Attacker = render.measure_text(Handle.Render.Font.New.a_16, nil, AttackerName),
                Victim = render.measure_text(Handle.Render.Font.New.a_16, nil, VictimName)
            }

            local AllWidth = NamesScale.Attacker.x + NamesScale.Victim.x + IconSize.x + 30

            local AnimatedAttackerName = AttackerName--Helpers.LerpText(AttackerName, Kill.Fade)
            local AnimatedVictimName = VictimName--Helpers.LerpText(VictimName, Kill.Fade)

            Handle.Render.Countainer(VectorUp + vector(-AllWidth, AddVector * 30), VectorUp + vector(0, 20 + AddVector * 30), Alpha * Kill.Fade, nil, nil, Kill.IsMe and color(150, 36, 36, 255) or nil, nil)
            render.text(Handle.Render.Font.New.a_16, VectorUp + vector(-AllWidth + 5, 1+ AddVector * 30), Helpers.ColorAlpha(color(255, 255), Alpha * Kill.Fade), nil, AnimatedAttackerName)
            render.texture(GetWeaponIcon, VectorUp + vector(-AllWidth + 15 + NamesScale.Attacker.x, 11 - (IconSize.y / 2) + AddVector * 30), IconSize, Helpers.ColorAlpha(color(255, 255), Alpha * Kill.Fade))
            render.text(Handle.Render.Font.New.a_16, VectorUp + vector(-AllWidth + 25 + IconSize.x + NamesScale.Attacker.x, 1 + AddVector * 30), Helpers.ColorAlpha(color(255, 255), Alpha * Kill.Fade), nil, AnimatedVictimName)
            AddVector = AddVector + Kill.Fade

            ::skip::
        end
        if AddVector > 20 then
            table_remove(Handle.HUD.PlayersDeath, 1)
        end
    end

    local RoundTime = function()
        local GameRules = entity.get_game_rules()
        local FreezeTime = cvar.mp_freezetime:int()
        local Time = Handle.HUD.IsPlant and cvar.mp_c4timer:int() or (GameRules.m_bFreezePeriod and FreezeTime or GameRules.m_iRoundTime + FreezeTime)
        --Handle.HUD.IsPlant = true
        --Handle.HUD.RoundStartTime = globals.curtime
        local TimeLeft = (Handle.HUD.RoundStartTime + Time) - globals.curtime

        if TimeLeft <= 0 then
            return nil
        end

        local Min = math_floor(TimeLeft / 60)
        local Seconds = math_floor(TimeLeft % 59)

        local EndClock = tostring(Min and tostring(Min) .. ":" or "0:") .. tostring(Seconds and (Seconds > 9 and tostring(Seconds) or "0" .. tostring(Seconds)) or "00")
        return EndClock
    end

    local GetPlayersAlive = function()
        local Players = {
            CT = 0,
            T = 0
        }

        local AllPlayers = entity.get_players(false, true)
        if AllPlayers == nil then
            return Players
        end

        for Index, Player in pairs(AllPlayers) do
            if Player == nil then
                goto skip
            end

            if Player.m_iTeamNum == 2 and Player:is_alive() then
                Players.T = Players.T + 1
            end

            if Player.m_iTeamNum == 3 and Player:is_alive() then
                Players.CT = Players.CT + 1
            end

            ::skip::
        end

        return Players
    end
    
    local GetRrounds = function()
        local CTeamEntities = entity.get_entities("CCSTeam")
        --print(#CTeamEntities)
        local Rounds = {
            CT = CTeamEntities[4].m_scoreTotal,
            T = CTeamEntities[3].m_scoreTotal
        }

        return Rounds
    end

    local RenderRound = function(Vector, Alpha)
        -- vector will be the center
        local GameRules = entity.get_game_rules()
        local Time = RoundTime()
        local PlayersCount = GetPlayersAlive()
        local Rounds = GetRrounds()

        local IsWarmup = GameRules.m_bWarmupPeriod
        if Time == nil then
            return
        end

        local ClockText = IsWarmup and "Warm up" or tostring(Time)
        local TextSize = 55 --@no need cus we want it static@ render.measure_text(Handle.Render.Font.New.a_16, nil, ClockText)
        --TextSize = TextSize + (IsWarmup and 0 or 50)

        Handle.HUD.FadeClock = Helpers.Lerp(Handle.HUD.FadeClock, TextSize, 20)
        
        Handle.Render.Countainer(Vector + vector(- (Handle.HUD.FadeClock / 2), 30), Vector + vector((Handle.HUD.FadeClock / 2), 60), Alpha, nil, nil, nil, nil)
        if Handle.HUD.IsPlant then
            local NewPulse = math_floor(math_sin((globals.realtime % 3) * 4) * (255 / 2 - 1) + 255 / 2) / 255--math_floor(math_sin(math_rad((globals.realtime * 6) % 360)))
            render.shadow(Vector + vector(- (Handle.HUD.FadeClock / 2), 30), Vector + vector((Handle.HUD.FadeClock / 2), 60), Helpers.ColorAlpha(color(255, 0, 0, 255), Alpha * NewPulse), 10, 0, 4)
        end

        render.text(Handle.Render.Font.New.a_16, Vector + vector(0, 45), Helpers.ColorAlpha(color(255, 255), Alpha), 'c', ClockText)

        Handle.Render.Countainer(Vector + vector(- (Handle.HUD.FadeClock / 2) - 35, 30), Vector + vector(- (Handle.HUD.FadeClock / 2) - 5, 60), Alpha, nil, nil, color(200, 36, 36, 255), nil)
        render.text(Handle.Render.Font.New.a_16, Vector + vector(-(Handle.HUD.FadeClock / 2) - 30 / 2 - 5, 45), Helpers.ColorAlpha(color(255, 255), Alpha), 'c', Rounds.T)

        Handle.Render.Countainer(Vector + vector((Handle.HUD.FadeClock / 2) + 5, 30), Vector + vector((Handle.HUD.FadeClock / 2) + 35, 60), Alpha, nil, nil, nil, color(36, 36, 200, 255))
        render.text(Handle.Render.Font.New.a_16, Vector + vector((Handle.HUD.FadeClock / 2) + 5 + 30 / 2, 45), Helpers.ColorAlpha(color(255, 255), Alpha), 'c', Rounds.CT)


        --Players = {
        --    CT = {Fade = 0, Last = 0},
        --    T = {Fafe = 0, Last = 0}
        if PlayersCount.CT ~= Handle.HUD.Players.CT.Last then
            Handle.HUD.Players.CT.Time = globals.realtime
            Handle.HUD.Players.CT.Last = PlayersCount.CT
        end

        Handle.HUD.Players.CT.Fade = Helpers.Lerp(Handle.HUD.Players.CT.Fade, Handle.HUD.Players.CT.Time + 5 < globals.realtime and 0 or 1, 10)
        
        if PlayersCount.T ~= Handle.HUD.Players.T.Last then
            Handle.HUD.Players.T.Time = globals.realtime
            Handle.HUD.Players.T.Last = PlayersCount.T
        end

        Handle.HUD.Players.T.Fade = Helpers.Lerp(Handle.HUD.Players.T.Fade, Handle.HUD.Players.T.Time + 5 < globals.realtime and 0 or 1, 10)

        local PlayersScales = {
            CT = render.measure_text(Handle.Render.Font.New.a_16, nil, tostring(PlayersCount.CT) .. " CT Alive"),
            T = render.measure_text(Handle.Render.Font.New.a_16, nil, tostring(PlayersCount.T) .. " T Alive")
        }

        Handle.Render.Countainer(Vector + vector(- (Handle.HUD.FadeClock) - 10 - PlayersScales.T.x, 80), Vector + vector(- (Handle.HUD.FadeClock), 110), Alpha * Handle.HUD.Players.T.Fade, nil, nil, color(200, 36, 36, 255), nil)
        render.text(Handle.Render.Font.New.a_16, Vector + vector(- Handle.HUD.FadeClock - 5 - PlayersScales.T.x / 2, 95), Helpers.ColorAlpha(color(255, 255), Alpha * Handle.HUD.Players.T.Fade), 'c', tostring(PlayersCount.T) .. " T Alive")

        Handle.Render.Countainer(Vector + vector((Handle.HUD.FadeClock), 80), Vector + vector((Handle.HUD.FadeClock) + 10 + PlayersScales.CT.x, 110), Alpha * Handle.HUD.Players.CT.Fade, nil, nil, nil, color(36, 36, 200, 255))
        render.text(Handle.Render.Font.New.a_16, Vector + vector(Handle.HUD.FadeClock + 5 + PlayersScales.CT.x / 2, 95), Helpers.ColorAlpha(color(255, 255), Alpha * Handle.HUD.Players.CT.Fade), 'c', tostring(PlayersCount.CT) .. " CT Alive")
        --render.text(Handle.Render.Font.New.a_16, Vector + vector(-Handle.HUD.FadeClock / 2 + 5, 45 - PlayersScales.T.y / 2), Helpers.ColorAlpha(color(255, 100, 100, 255), Alpha), nil, PlayersCount.T)
        --render.text(Handle.Render.Font.New.a_16, Vector + vector(Handle.HUD.FadeClock / 2 - 5 - PlayersScales.CT.x, 45 - PlayersScales.CT.y / 2), Helpers.ColorAlpha(color(100, 100, 255, 255), Alpha), nil, PlayersCount.CT)
        

    end

    local RenderEndRound = function(Vector, Size, Alpha) -- position == center screen.
        --a_24
        if Handle.HUD.RoundData.Time + 5 < globals.realtime then
            Handle.HUD.RoundData.Fade = Helpers.Lerp(Handle.HUD.RoundData.Fade, 0, 20)
            if Handle.HUD.RoundData.Fade == 0 then
                return
            end
        else
            Handle.HUD.RoundData.Fade = Helpers.Lerp(Handle.HUD.RoundData.Fade, 1, 20)
        end

        Handle.HUD.RoundData.FadeScale = Helpers.Lerp(Handle.HUD.RoundData.FadeScale, render.measure_text(Handle.Render.Font.New.a_16, nil, Handle.HUD.RoundData.Won.Message).x + 20, 20)

        Handle.Render.Countainer(Vector + vector(- (Handle.HUD.RoundData.FadeScale / 2), 0), Vector + vector((Handle.HUD.RoundData.FadeScale / 2), Size.y), Alpha * Handle.HUD.RoundData.Fade, nil, nil, nil, nil)

        render.text(Handle.Render.Font.New.a_16, Vector + vector(0, Size.y / 2), Helpers.ColorAlpha(color(255, 255), Alpha * Handle.HUD.RoundData.Fade), 'c', Handle.HUD.RoundData.Won.Message)

    end

    local FixLine = function(String, MaxLengh)
        local TextCopy = String
        local CopyLength = render.measure_text(Handle.Render.Font.New.a_16, nil, TextCopy)

        while (CopyLength.x > MaxLengh) do
            TextCopy = string.sub(TextCopy, 1, -2)
            CopyLength = render.measure_text(Handle.Render.Font.New.a_16, nil, TextCopy)
        end

        local ChangeIndex = TextCopy:len()
        local StartString = string.sub(String, 1, ChangeIndex-1)
        local EndString = string.sub(String, ChangeIndex, -1)
        --local Result = StartString .. "\n" .. EndString
        return StartString, EndString
        --return Result
    end

    local RenderChat = function(Vector, MaxSize, Alpha)
        --Handle.HUD.PlayerChat
        --Handle.HUD.FadeChat = {
        --    Size = 0,
        --    IsHave = 0

        Handle.HUD.FadeChat.IsHave = Helpers.Lerp(Handle.HUD.FadeChat.IsHave, (#Handle.HUD.PlayerChat > 0 or Helpers.IsMenuVisible()) and 1 or 0, 20)
        

        Handle.Render.Countainer(Vector , Vector + vector(MaxSize.x, Handle.HUD.FadeChat.Size), Alpha * 0.5 * Handle.HUD.FadeChat.IsHave)

        local Add = 0

        for Index, Say in ipairs(Handle.HUD.PlayerChat) do
            if Say.Time + 5 < globals.realtime then
                Say.Fade = Helpers.Lerp(Say.Fade, 0, 20)
                if Say.Fade == 0 then
                    table_remove(Handle.HUD.PlayerChat, Index)
                end
            else
                Say.Fade = Helpers.Lerp(Say.Fade, 1, 20)
            end

            local DeadText = Say.Alive and "" or "DEAD - "
            local Text = DeadText .. Say.PlayerName .. " : " .. Say.SayText
            local TextSize = render.measure_text(Handle.Render.Font.New.a_16, nil, Text)
            --local PlayerName = render.measure_text(Handle.Render.Font.New.a_16, nil, Say.PlayerName .. " : ")

            local Count = 1
            if TextSize.x > MaxSize.x - 10 then
                local Start, End = "", ""

                Start, End = FixLine(Text, MaxSize.x - 10)

                local EndSize = render.measure_text(Handle.Render.Font.New.a_16, nil, End)
                local NewEnd = ""

                if EndSize.x > MaxSize.x - 10 then
                    --[[
                        struct : 
                        [1] - string to store continiue -- //  NewEnd
                        [2] - string to store end result
                    ]]
                    local StringEnd = End
                    while (EndSize.x > MaxSize.x - 10) do
                        local S1, E1 = FixLine(StringEnd, MaxSize.x - 10)
                        NewEnd = NewEnd .. S1 .. "\n"
                        StringEnd = E1

                        EndSize = render.measure_text(Handle.Render.Font.New.a_16, nil, StringEnd)
                        Count = Count + 1
                    end
                    NewEnd = NewEnd .. StringEnd

                else
                    NewEnd = End
                end

                Text = Start .. "\n" .. NewEnd
                Count = Count + 1
            end

            local AnimatedText = Helpers.LerpText(Text, Say.Fade)

            render.text(Handle.Render.Font.New.a_16, Vector + vector(5, 5 + Add * 18), Helpers.ColorAlpha(color(255, 255), Alpha * Say.Fade * Handle.HUD.FadeChat.IsHave), nil, AnimatedText)

            Add = Add + (Count*Say.Fade)
        end

        if Add > 10 then
            table_remove(Handle.HUD.PlayerChat, 1)
        end

        Handle.HUD.FadeChat.Size = math_min(MaxSize.y, Helpers.Lerp(Handle.HUD.FadeChat.Size, Add * 18 + 10, 20))
    end
    
    local EnableGameMovement = function(cmd)
        if Handle.Chat.IsOpen == true or Handle.Chat.IsTeam == true then
            
            for i = 1, 128 do
                cmd.buttons = bit.band(cmd.buttons, bit.bnot(bit.lshift(1, i)))
            end

            cmd.forwardmove = 0
            cmd.sidemove = 0
            cmd.upmove = 0
        end
    end

    events.mouse_input:set(function() 
        if Handle.Chat.IsOpen or Handle.Chat.IsTeam then 
            return false 
        end 
    end)

    local IsKeyPressed = function(key)
        if type(key) == "table" then
            if Handle.Chat.IsFixInput == false and common.is_button_down(key[1]) and common.is_button_down(key[2]) then
                Handle.Chat.LastKey = key[2]
                Handle.Chat.IsFixInput = true
                return true
            end
        else
            if Handle.Chat.IsFixInput == false and common.is_button_down(key) then
                Handle.Chat.LastKey = key
                Handle.Chat.IsFixInput = true
                return true
            end
        end
        return false
    end

    local TypeChat = function(Vector, Alpha)
        if Handle.Chat.IsOpen == false and Handle.Chat.IsTeam == false then
            Handle.Chat.LocalSay = ""
            Handle.Chat.Fade = Helpers.Lerp(Handle.Chat.Fade, 0, 20)
            if IsKeyPressed(0x59) then
                Handle.Chat.IsOpen = true
            end

            if IsKeyPressed(0x55) then
                Handle.Chat.IsTeam = true
            end
        else
            Handle.Chat.Fade = Helpers.Lerp(Handle.Chat.Fade, 1, 20)

            if IsKeyPressed(0x1B) then
                Handle.Chat.IsOpen = false
                Handle.Chat.IsTeam = false
            end
            
            if IsKeyPressed(0x0D) then
                if Handle.Chat.IsOpen == true then
                    utils.console_exec("say " ..  tostring(Handle.Chat.LocalSay) .. " ")
                end

                if Handle.Chat.IsTeam == true then
                    utils.console_exec("say_team " ..  tostring(Handle.Chat.LocalSay) .. " ")
                end

                Handle.Chat.LocalSay = ""
                Handle.Chat.IsOpen = false
                Handle.Chat.IsTeam = false
            end

            if IsKeyPressed(0x08) then -- delete
                Handle.Chat.LocalSay = string.sub(Handle.Chat.LocalSay, 1, - 2)
            end

            if IsKeyPressed(0x20) then -- space
                Handle.Chat.LocalSay = Handle.Chat.LocalSay .. " "
            end

            if IsKeyPressed(0x14) then -- caps
                Handle.Chat.IsCaps = not Handle.Chat.IsCaps
            end

            for I = 48, 90 do
                if IsKeyPressed(I) then -- key
                    Handle.Chat.LocalSay = Handle.Chat.LocalSay .. (Handle.Chat.IsCaps and string.char(I):upper() or string.char(I):lower())
                end
            end

            -- execptions
            if IsKeyPressed({0x10, 0xBB}) then -- +
                Handle.Chat.LocalSay = Handle.Chat.LocalSay .. "+"
            end

            if IsKeyPressed(0xBB) then -- =
                Handle.Chat.LocalSay = Handle.Chat.LocalSay .. "="
            end

            if IsKeyPressed({0x10, 0xBD}) then -- +
                Handle.Chat.LocalSay = Handle.Chat.LocalSay .. "_"
            end
            
            if IsKeyPressed(0xBD) then -- =
                Handle.Chat.LocalSay = Handle.Chat.LocalSay .. "-"
            end

            if IsKeyPressed({0x10, 0xBC}) then -- <
                Handle.Chat.LocalSay = Handle.Chat.LocalSay .. "<"
            end
            
            if IsKeyPressed(0xBC) then -- ,
                Handle.Chat.LocalSay = Handle.Chat.LocalSay .. "-"
            end

            if IsKeyPressed({0x10, 0xBE}) then -- >
                Handle.Chat.LocalSay = Handle.Chat.LocalSay .. ">"
            end
            
            if IsKeyPressed(0xBE) then -- .
                Handle.Chat.LocalSay = Handle.Chat.LocalSay .. "."
            end

            if IsKeyPressed({0x10, 0xBF}) then -- ?
                Handle.Chat.LocalSay = Handle.Chat.LocalSay .. "?"
            end
            
            if IsKeyPressed(0xBF) then -- /
                Handle.Chat.LocalSay = Handle.Chat.LocalSay .. "/"
            end
            
        end

        local ResualtText = (Handle.Chat.IsTeam and "To-Team : " or "To-All : ") .. Handle.Chat.LocalSay
        local TextSize = render.measure_text(Handle.Render.Font.New.a_16, nil, ResualtText)
        Handle.Render.Countainer(Vector, Vector + vector((TextSize.x + 10) * Handle.Chat.Fade, 20), Alpha * Handle.Chat.Fade)
        render.text(Handle.Render.Font.New.a_16, Vector + vector(5, 10 - TextSize.y / 2), Helpers.ColorAlpha(color(255, 255), Alpha * Handle.Chat.Fade), nil, ResualtText)

        if Handle.Chat.LastKey ~= nil then
            if common.is_button_released(Handle.Chat.LastKey) then
                Handle.Chat.LastKey = nil
                Handle.Chat.IsFixInput = false
            end
        end
    end

    local Crosshair = function(Vector, Alpha)
        --[[
        cl_crosshairsize
        ? cl_crosshairstyle ?
        cl_crosshairdot [1 -> true / 0 -> false]
        cl_crosshairthickness [0.1 - 6]
        cl_crosshairgap [-5, 5]

        --]]
        local LocalPlayer = entity.get_local_player()
        if LocalPlayer == nil or not LocalPlayer:is_alive() then
            return
        end

        if LocalPlayer.m_bIsScoped then
            return
        end

        local Length = cvar.cl_crosshairsize:float()
        local IsDot = cvar.cl_crosshairdot:int() == 1
        local Thicknes = cvar.cl_crosshairthickness:float()
        local Gap = cvar.cl_crosshairgap:float() + 4
        local Color = color(cvar.cl_crosshaircolor_r:float(), cvar.cl_crosshaircolor_g:float(), cvar.cl_crosshaircolor_b:float(), cvar.cl_crosshairalpha:float())


        -- top
        if cvar.cl_crosshair_t:int() ~= 1 then
            render.rect(Vector + vector(0, -(Length * 3 + Gap) + 1), Vector + vector(Thicknes * 10, -Gap + 1), Color)
        end
        render.rect(Vector + vector(0,  Gap + 1), Vector + vector(Thicknes * 10, Gap + (Length * 3) + 1), Color)
        render.rect(Vector + vector(-(Length * 3 + Gap) + 1, 0), Vector + vector(- Gap + 1, Thicknes * 10), Color)
        render.rect(Vector + vector(Gap + 1, 0), Vector + vector(Gap + (Length * 3) + 1, Thicknes * 10), Color)
        if IsDot then
            render.rect(Vector , Vector + vector(1, 1), Color)
        end
    end

    local HUD = function() -- // going to be most cancer now . uwu
        local LocalPlayer = entity.get_local_player()
        if LocalPlayer == nil then
            return
        end

        
        if not Menu.DataUI["Visuals"]["UI"]["UI Elements"][4] then
            Handle.Cvars.drawhud:int(1)
            if Handle.HUD.FixedChat == true then
                utils.console_exec('bind y "messagemode"')
                utils.console_exec('bind m "teammenu"')
                utils.console_exec('bind u "messagemode2"')
                Handle.HUD.FixedChat = false
            end
            Handle.HUD.Fade = Helpers.Lerp(Handle.HUD.Fade, 0, 10)
            if Handle.HUD.Fade == 0 then
                return
            end
        else
            Handle.HUD.Fade = Helpers.Lerp(Handle.HUD.Fade, 1, 10)
        end

        -- @ local data 
        local Health = LocalPlayer.m_iHealth
        local Armor = LocalPlayer.m_ArmorValue
        local Weapons = GetPlayerWeapons(LocalPlayer)--LocalPlayer:get_player_weapon(true)
        
        local Weapon = LocalPlayer:get_player_weapon()

        local Screen = render.screen_size()

        if not Menu.DataUI["Visuals"]["UI"]["HUD Disabled Options"][1] then
            RenderHealthAndArmor(vector(10, Screen.y - 65), {Health = Health, Armor = Armor}, vector(170, 55), Handle.HUD.Fade)
        end
        if not Menu.DataUI["Visuals"]["UI"]["HUD Disabled Options"][2] then
            RenderWeapons(vector(Screen.x - 210, Screen.y - 5), vector(200, 55), Weapons, Weapon, Handle.HUD.Fade)
        end
        if not Menu.DataUI["Visuals"]["UI"]["HUD Disabled Options"][3] then
            RenderKillFeed(vector(Screen.x - 10, 50), Handle.HUD.Fade)
        end
        if not Menu.DataUI["Visuals"]["UI"]["HUD Disabled Options"][4] then
            RenderRound(vector(Screen.x / 2, 10), Handle.HUD.Fade)
            RenderEndRound(vector(Screen.x / 2, 200), vector(150, 50), Handle.HUD.Fade)
        end
        if not Menu.DataUI["Misc"]["Misc"]["Remove"][1] then
            RenderChat(vector(10, Screen.y - 350), vector(550, 250), Handle.HUD.Fade)
            TypeChat(vector(10, Screen.y - 100), Handle.HUD.Fade)
        end

        Crosshair(vector(Screen.x / 2, Screen.y / 2), Handle.HUD.Fade)
        

        if Handle.HUD.FixedChat == false and Menu.DataUI["Visuals"]["UI"]["UI Elements"][4] then
            utils.console_exec("unbind y")
            utils.console_exec("unbind m")
            utils.console_exec("unbind u")
        end
        Handle.HUD.FixedChat = true
        Handle.Cvars.drawhud:int(0)
    end

    local Keybinds = function()
        ---@ region : render
        local Vector = vector(Menu.Neverlose.KeyVectorX:get(), Menu.Neverlose.KeyVectorY:get())
        local TextVector = 0
        local AddO = 35
        local TextSize = render.measure_text(Handle.Render.Font.New.a_13, nil, "KeyBinds")
        local KeybindsData = ui.get_binds()
        local Mouse = ui.get_mouse_position()
        local KeyModes = {
            [1] = "hold",
            [2] = "toggle"
        }

        Handle.Keybinds.WantWidth = 0

        if not Menu.DataUI["Visuals"]["UI"]["UI Elements"][2] then
            Handle.Keybinds.Fade = Helpers.Lerp(Handle.Keybinds.Fade, 0, 20)
            if Handle.Keybinds.Fade == 0 then
                return
            end
        else
            Handle.Keybinds.Fade = Helpers.Lerp(Handle.Keybinds.Fade, (#KeybindsData > 0 or Helpers.IsMenuVisible()) and 1 or 0, 20)
        end

        
        Handle.Keybinds.BackGround = Helpers.Lerp(Handle.Keybinds.BackGround, #KeybindsData * 20, 20)
        --render.rect(Vector + vector(0, AddO), Vector + vector(Handle.Keybinds.ActiveWidth, AddO + Handle.Keybinds.BackGround), Helpers.ColorAlpha(color(1, 1, 0, 255), Handle.Keybinds.Fade), 4)
        if Handle.Keybinds.BackGround > 1 then
            render.gradient(Vector + vector(0, AddO), Vector + vector(Handle.Keybinds.ActiveWidth, AddO + Handle.Keybinds.BackGround), Helpers.ColorAlpha(Menu.DataUI["Visuals"]["Colors"]["UI Box Top Left"]:clone(), Handle.Keybinds.Fade), Helpers.ColorAlpha(Menu.DataUI["Visuals"]["Colors"]["UI Box Top Right"]:clone(), Handle.Keybinds.Fade), Helpers.ColorAlpha(Menu.DataUI["Visuals"]["Colors"]["UI Box Bottom Left"]:clone(), Handle.Keybinds.Fade), Helpers.ColorAlpha(Menu.DataUI["Visuals"]["Colors"]["UI Box Bottom Right"]:clone(), Handle.Keybinds.Fade), 2)
            render.rect_outline(Vector + vector(0, AddO), Vector + vector(Handle.Keybinds.ActiveWidth, AddO + Handle.Keybinds.BackGround), Helpers.ColorAlpha(color(67, 63, 64, 255), Handle.Keybinds.Fade), 1, 2)
        end
        
        for Index, Key in ipairs(KeybindsData) do
            if Handle.Keybinds.KeyList[Key.name] == nil then
                Handle.Keybinds.KeyList[Key.name] = 0
            end

            Handle.Keybinds.KeyList[Key.name] = Helpers.Lerp(Handle.Keybinds.KeyList[Key.name], Key.active and 1 or 0, 20)

            local KeyValue = type(Key.value) == "table" and Helpers.TableExport(Key.value, ",") or ((tostring(Key.value) == "true" or tostring(Key.value) == "false") and KeyModes[Key.mode] or Key.value)
            
            local BindsNamesSize = {
                Name = render.measure_text(Handle.Render.Font.New.a_13, nil, Key.name),
                Value = render.measure_text(Handle.Render.Font.New.a_13, nil, KeyValue)
            }

            local SelectedBindWidth = BindsNamesSize.Name.x + BindsNamesSize.Value.x + 30 -- // 10 -  * 2 and 10 is width

            if SelectedBindWidth > 170 then
                if SelectedBindWidth > Handle.Keybinds.WantWidth then
                    Handle.Keybinds.WantWidth = SelectedBindWidth
                end
            end

            render.text(Handle.Render.Font.New.a_13, Vector + vector(5, AddO + 10 - BindsNamesSize.Name.y / 2), Helpers.ColorAlpha(color(255, 255), Handle.Keybinds.Fade * Handle.Keybinds.KeyList[Key.name]), nil, Key.name)
            render.text(Handle.Render.Font.New.a_13, Vector + vector(Handle.Keybinds.ActiveWidth - 5 - BindsNamesSize.Value.x, AddO + 10 - BindsNamesSize.Name.y / 2), Helpers.ColorAlpha(color(255, 255), Handle.Keybinds.Fade * Handle.Keybinds.KeyList[Key.name]), nil, KeyValue)

            AddO = Key.active and AddO + 20 or AddO + 20 * Handle.Keybinds.KeyList[Key.name]
        end

        if Handle.Keybinds.WantWidth > 170 then
            
            Handle.Keybinds.ActiveWidth = math_min(Handle.Keybinds.WantWidth, Helpers.Lerp(Handle.Keybinds.ActiveWidth, Handle.Keybinds.WantWidth, 20) + 0.1)
            
        else
            Handle.Keybinds.ActiveWidth = Helpers.Lerp(Handle.Keybinds.ActiveWidth, 170, 20)
        end


        render.gradient(Vector, Vector + vector(Handle.Keybinds.ActiveWidth, 28), Helpers.ColorAlpha(Menu.DataUI["Visuals"]["Colors"]["UI Box Top Left"]:clone(), Handle.Keybinds.Fade), Helpers.ColorAlpha(Menu.DataUI["Visuals"]["Colors"]["UI Box Top Right"]:clone(), Handle.Keybinds.Fade), Helpers.ColorAlpha(Menu.DataUI["Visuals"]["Colors"]["UI Box Bottom Left"]:clone(), Handle.Keybinds.Fade), Helpers.ColorAlpha(Menu.DataUI["Visuals"]["Colors"]["UI Box Bottom Right"]:clone(), Handle.Keybinds.Fade), 3)
        --render.rect(Vector, Vector + vector(Handle.Keybinds.ActiveWidth, 28), Helpers.ColorAlpha(color(37, 33, 34, 255), Handle.Keybinds.Fade), 3)
        render.rect_outline(Vector, Vector + vector(Handle.Keybinds.ActiveWidth, 28), Helpers.ColorAlpha(color(67, 63, 64, 255), Handle.Keybinds.Fade), 1.5, 3)

        render.texture(Files.image_LoadKeybinds.Image, Vector + vector(5, 28 / 2 - Files.image_LoadKeybinds.Size.y / 2), Files.image_LoadKeybinds.Size, Helpers.ColorAlpha(color(255, 255), Handle.Keybinds.Fade))

        render.text(Handle.Render.Font.New.a_13, Vector + vector(30, 28 / 2 - TextSize.y / 2), Helpers.ColorAlpha(color(255, 255), Handle.Keybinds.Fade), nil, "KeyBinds")


        ---@ region : movement
        --Visuals.Move.Objects.Keybinds = false
        
        local IsHovered = Helpers.IsInBox(Vector, Handle.Keybinds.ActiveWidth, 28)
        if IsHovered then
            if common.is_button_down(1) and Visuals.Move.IsPosible() then
                if Menu.RenderComponents.InteractData.Slider == "" and not Helpers.Contains(Menu.RenderComponents.InteractData.ListOpen, true) and not Helpers.Contains(Menu.RenderComponents.InteractData.MultiListOpen, true) and not Menu.RenderComponents.InteractData.IsHue and not Menu.RenderComponents.InteractData.IsValueSaturation and not Menu.RenderComponents.InteractData.IsAlpha and Menu.RenderComponents.InteractData.ColorOpen == "" and Menu.RenderComponents.InteractData.BindTypeSelection == "" then
                    Visuals.Move.Objects.Keybinds = true
                    Handle.Keybinds.MoveElement.x = Vector.x - Mouse.x
                    Handle.Keybinds.MoveElement.y = Vector.y - Mouse.y
                end
            end
        end

        if common.is_button_released(1) then
            Visuals.Move.Objects.Keybinds = false
        end

        if Visuals.Move.Objects.Keybinds == true and Helpers.IsMenuVisible() then
            Menu.Neverlose.KeyVectorX:set(math_floor(Handle.Keybinds.MoveElement.x + Mouse.x))
            Menu.Neverlose.KeyVectorY:set(math_floor(Handle.Keybinds.MoveElement.y + Mouse.y))
        end
        
    end

    local WaterMark = function()
        local Vector = vector(Menu.Neverlose.WaterVectorX:get(), Menu.Neverlose.WaterVectorY:get())
        local Mouse = ui.get_mouse_position()

        if not Menu.DataUI["Visuals"]["UI"]["UI Elements"][1] then
            Handle.WaterMark.Fade = Helpers.Lerp(Handle.WaterMark.Fade, 0, 20)
            if Handle.WaterMark.Fade == 0 then
                return
            end
        else
            Handle.WaterMark.Fade = Helpers.Lerp(Handle.WaterMark.Fade, 1, 20)
        end

        local WaterMarkText = ""
        --"Watermark Options", {"Name", "Build", "TickRate", "Time", "Server IP"}
        if Menu.DataUI["Visuals"]["UI"]["Watermark Options"][1] then
            -- name
            WaterMarkText = WaterMarkText .. "  " .. GetUsername()
        end

        if Menu.DataUI["Visuals"]["UI"]["Watermark Options"][2] then
            -- build
            WaterMarkText = WaterMarkText .. "  " .. User.LocalBuild
        end

        if Menu.DataUI["Visuals"]["UI"]["Watermark Options"][3] then
            -- ping
            local net = utils.net_channel()
            WaterMarkText = WaterMarkText .. "  " .. math.floor((net and net.latency[0] * 1000) or 0) .. " ms"
        end

        if Menu.DataUI["Visuals"]["UI"]["Watermark Options"][4] then
            -- time
            local TimeTable = common.get_system_time()
            local TimeString = TimeTable.hours .. ":" .. (tostring(TimeTable.minutes):len() == 1 and "0" .. tostring(TimeTable.minutes) or tostring(TimeTable.minutes) )
            WaterMarkText = WaterMarkText .. "  " .. TimeString
        end


        local EndTextSize = render.measure_text(Handle.Render.Font.New.a_13, nil, WaterMarkText)

        Handle.WaterMark.SizeExtand = Helpers.Lerp(Handle.WaterMark.SizeExtand, EndTextSize.x + 30, 20)

        render.gradient(Vector + vector(-Handle.WaterMark.SizeExtand, 0), Vector + vector(0, 28), Helpers.ColorAlpha(Menu.DataUI["Visuals"]["Colors"]["UI Box Top Left"]:clone(), Handle.WaterMark.Fade), Helpers.ColorAlpha(Menu.DataUI["Visuals"]["Colors"]["UI Box Top Right"]:clone(), Handle.WaterMark.Fade), Helpers.ColorAlpha(Menu.DataUI["Visuals"]["Colors"]["UI Box Bottom Left"]:clone(), Handle.WaterMark.Fade), Helpers.ColorAlpha(Menu.DataUI["Visuals"]["Colors"]["UI Box Bottom Right"]:clone(), Handle.WaterMark.Fade), 3)
        render.rect_outline(Vector + vector(-Handle.WaterMark.SizeExtand, 0), Vector + vector(0, 28), Helpers.ColorAlpha(color(67, 63, 64, 255), Handle.WaterMark.Fade), 1.5, 3)

        render.texture(Files.image_LoadCloadWatermark.Image, Vector + vector( - Handle.WaterMark.SizeExtand + 5, 30 / 2 - Files.image_LoadCloadWatermark.Size.y / 2), Files.image_LoadCloadWatermark.Size, Helpers.ColorAlpha(color(255, 255), Handle.WaterMark.Fade))
        render.text(Handle.Render.Font.New.a_13, Vector + vector(-Handle.WaterMark.SizeExtand + 25, 28 / 2 - EndTextSize.y / 2), Helpers.ColorAlpha(color(255, 255), Handle.WaterMark.Fade), nil, WaterMarkText)
        

        local IsHovered = Helpers.IsInBox(Vector + vector(-Handle.WaterMark.SizeExtand, 0), Handle.WaterMark.SizeExtand, 28)
        if IsHovered then
            if common.is_button_down(1) and Visuals.Move.IsPosible() then
                if Menu.RenderComponents.InteractData.Slider == "" and not Helpers.Contains(Menu.RenderComponents.InteractData.ListOpen, true) and not Helpers.Contains(Menu.RenderComponents.InteractData.MultiListOpen, true) and not Menu.RenderComponents.InteractData.IsHue and not Menu.RenderComponents.InteractData.IsValueSaturation and not Menu.RenderComponents.InteractData.IsAlpha and Menu.RenderComponents.InteractData.ColorOpen == "" and Menu.RenderComponents.InteractData.BindTypeSelection == "" then
                    Visuals.Move.Objects.WaterMark = true
                    Handle.WaterMark.MoveElement.x = Vector.x - Mouse.x
                    Handle.WaterMark.MoveElement.y = Vector.y - Mouse.y
                end
            end
        end

        if common.is_button_released(1) then
            Visuals.Move.Objects.WaterMark = false
        end

        if Visuals.Move.Objects.WaterMark == true and Helpers.IsMenuVisible() then
            Menu.Neverlose.WaterVectorX:set(math_floor(Handle.WaterMark.MoveElement.x + Mouse.x))
            Menu.Neverlose.WaterVectorY:set(math_floor(Handle.WaterMark.MoveElement.y + Mouse.y))
        end

    end

    local GetMuzzle = function(IsThirdPerson)
        local LocalPlayer = entity.get_local_player()
        if LocalPlayer == nil then
            return
        end

        local Weapon = LocalPlayer:get_player_weapon()
        if Weapon == nil then
            return
        end

        local Model = IsThirdPerson and Weapon.m_hWeaponWorldModel or LocalPlayer.m_hViewModel[0]
        local ActiveWeapon = native_GetClientEntity(Weapon:get_index())
        local g_Model = native_GetClientEntity(entity.get(Model):get_index())

        if ActiveWeapon == nil or g_Model == nil then
            return
        end

        local AttachmentVector = ffi.new("Vector3_t[1]")
        local AttachmentIndex = IsThirdPerson and native_GetAttachmentIndex3st(ActiveWeapon) or native_GetAttachmentIndex1st(ActiveWeapon, g_Model)

        if AttachmentIndex > 0 and native_GetAttachment(g_Model, AttachmentIndex, AttachmentVector[0]) then
            return { x = AttachmentVector[0].x, y = AttachmentVector[0].y, z = AttachmentVector[0].z }
        end

        return nil
    end

    local WeaponPanel = function()
        local LocalPlayer = entity.get_local_player()
        if LocalPlayer == nil or not LocalPlayer:is_alive() then
            return
        end

        if not Menu.DataUI["Visuals"]["UI"]["UI Elements"][3] then
            return
        end

        local MuzzleVector = GetMuzzle(false)
        if MuzzleVector == nil then
            return
        end

        local StomachVector = LocalPlayer:get_hitbox_position(3)
        if StomachVector == nil then
            return
        end

        if common.is_in_thirdperson() then
            MuzzleVector = {x = StomachVector.x, y = StomachVector.y, z = StomachVector.z}
        end

        local ScreenPosition = render.world_to_screen(vector(MuzzleVector.x, MuzzleVector.y, MuzzleVector.z))
        if ScreenPosition == nil then
            return
        end

        local Screen = render.screen_size()

        if not Helpers.IsInBox(vector(0, 0), Screen.x, Screen.y, ScreenPosition) then
            return
        end
        
        --Handle.WeaponPanel.FadeVector = {x = 0, y = 0}
        Handle.WeaponPanel.FadeVector.x = Helpers.Lerp(Handle.WeaponPanel.ActiveVector.x, ScreenPosition.x, 10)
        Handle.WeaponPanel.FadeVector.y = Helpers.Lerp(Handle.WeaponPanel.ActiveVector.y, ScreenPosition.y, 10)


        Handle.WeaponPanel.ActiveVector.x = tostring(Handle.WeaponPanel.ActiveVector.x) == "nan" and Screen.x / 1.5 or Handle.WeaponPanel.FadeVector.x
        Handle.WeaponPanel.ActiveVector.y = tostring(Handle.WeaponPanel.ActiveVector.y) == "nan" and Screen.y / 1.5 or Handle.WeaponPanel.FadeVector.y


        local AddVector = cvar.cl_righthand:int() == 0 and 20 or -100
        local FadedVector = vector(Handle.WeaponPanel.FadeVector.x + AddVector, Handle.WeaponPanel.FadeVector.y)
        local RenderFade = 0

        

        for Index, Item in ipairs(Handle.Indicators) do
            if Handle.WeaponPanel.FadeElements[Item.Name] == nil then
                Handle.WeaponPanel.FadeElements[Item.Name] = 0
            end

            Handle.WeaponPanel.FadeElements[Item.Name] = Helpers.Lerp(Handle.WeaponPanel.FadeElements[Item.Name], Item.Method() and 1 or 0, 20)

            local ItemNameSize = render.measure_text(Handle.Render.Font.New.a_13, nil, Helpers.StringUpperCase(Item.Name))

            render.gradient(FadedVector + vector(0, RenderFade), FadedVector + vector(ItemNameSize.x + 10, RenderFade + 20), Helpers.ColorAlpha(Menu.DataUI["Visuals"]["Colors"]["UI Box Top Left"]:clone(), Handle.WeaponPanel.FadeElements[Item.Name]), Helpers.ColorAlpha(Menu.DataUI["Visuals"]["Colors"]["UI Box Top Right"]:clone(), Handle.WeaponPanel.FadeElements[Item.Name]), Helpers.ColorAlpha(Menu.DataUI["Visuals"]["Colors"]["UI Box Bottom Left"]:clone(), Handle.WeaponPanel.FadeElements[Item.Name]), Helpers.ColorAlpha(Menu.DataUI["Visuals"]["Colors"]["UI Box Bottom Right"]:clone(), Handle.WeaponPanel.FadeElements[Item.Name]), 2)
            render.rect_outline(FadedVector + vector(0, RenderFade), FadedVector + vector(ItemNameSize.x + 10, RenderFade + 20), Helpers.ColorAlpha(color(67, 63, 64, 255), Handle.WeaponPanel.FadeElements[Item.Name]), 1, 2)

            render.text(Handle.Render.Font.New.a_13, FadedVector + vector(5, RenderFade + 10 - ItemNameSize.y / 2), Helpers.ColorAlpha(color(255, 255), Handle.WeaponPanel.FadeElements[Item.Name]), nil, Helpers.StringUpperCase(Item.Name))

            RenderFade = RenderFade + (30 * Handle.WeaponPanel.FadeElements[Item.Name])
        end


    end

    local Velocity = function()
        local LocalPlayer = entity.get_local_player()
        if LocalPlayer == nil then
            return
        end


        local VelocityVar = LocalPlayer.m_flVelocityModifier
        if VelocityVar == nil then
            return
        end

        if not Menu.DataUI["Visuals"]["UI"]["UI Elements"][5] then
            Handle.Velocity.Fade = Helpers.Lerp(Handle.Velocity.Fade, 0, 20)
            if Handle.Velocity.Fade == nil then
                return
            end
        else
            Handle.Velocity.Fade = Helpers.Lerp(Handle.Velocity.Fade, (Helpers.IsMenuVisible() or VelocityVar < 1) and 1 or 0, 20)
        end

        local Vector = vector(Menu.Neverlose.VelocityVectorX:get(), Menu.Neverlose.VelocityVectorY:get())
        if Vector == nil then
            return
        end

        local VectorSize = vector(200, 50)

        render.gradient(Vector, Vector + VectorSize, Helpers.ColorAlpha(Menu.DataUI["Visuals"]["Colors"]["UI Box Top Left"]:clone(), Handle.Velocity.Fade), Helpers.ColorAlpha(Menu.DataUI["Visuals"]["Colors"]["UI Box Top Right"]:clone(), Handle.Velocity.Fade), Helpers.ColorAlpha(Menu.DataUI["Visuals"]["Colors"]["UI Box Bottom Left"]:clone(), Handle.Velocity.Fade), Helpers.ColorAlpha(Menu.DataUI["Visuals"]["Colors"]["UI Box Bottom Right"]:clone(), Handle.Velocity.Fade), 2)
        render.rect_outline(Vector, Vector + VectorSize, Helpers.ColorAlpha(color(67, 63, 64, 255), Handle.Velocity.Fade), 1, 2)

        local TextSize = render.measure_text(Handle.Render.Font.New.a_13, nil, "Unsafe Velocity")
        local AdditionText = (not LocalPlayer:is_alive()) and "" or "(" .. tostring(math_floor(100 - VelocityVar*100)) .. "%)"
        render.text(Handle.Render.Font.New.a_13, Vector + vector(20 + Files.image_LoadVelocityWarning.Size.x, VectorSize.y / 2 - TextSize.y / 2), Helpers.ColorAlpha(color(255, 255), Handle.Velocity.Fade), nil, "Unsafe Velocity " .. AdditionText)

        local FadeUp = math_floor(math_sin((globals.realtime % 3) * 4) * (255 / 2 - 1) + 255 / 2) / 255
        render.texture(Files.image_LoadVelocityWarning.Image, Vector + vector(10, VectorSize.y / 2 - Files.image_LoadVelocityWarning.Size.y / 2), Files.image_LoadVelocityWarning.Size, Helpers.ColorAlpha(color(255, 36, 36, 255), Handle.Velocity.Fade * FadeUp))

        local Mouse = ui.get_mouse_position()
        local IsHovered = Helpers.IsInBox(Vector, VectorSize.x, VectorSize.y)
        if IsHovered then
            if common.is_button_down(1) and Visuals.Move.IsPosible() then
                if Menu.RenderComponents.InteractData.Slider == "" and not Helpers.Contains(Menu.RenderComponents.InteractData.ListOpen, true) and not Helpers.Contains(Menu.RenderComponents.InteractData.MultiListOpen, true) and not Menu.RenderComponents.InteractData.IsHue and not Menu.RenderComponents.InteractData.IsValueSaturation and not Menu.RenderComponents.InteractData.IsAlpha and Menu.RenderComponents.InteractData.ColorOpen == "" and Menu.RenderComponents.InteractData.BindTypeSelection == "" then
                    Visuals.Move.Objects.Velocity = true
                    Handle.Velocity.MoveElement.x = Vector.x - Mouse.x
                    Handle.Velocity.MoveElement.y = Vector.y - Mouse.y
                end
            end
        end

        if common.is_button_released(1) then
            Visuals.Move.Objects.Velocity = false
        end

        if Visuals.Move.Objects.Velocity == true and Helpers.IsMenuVisible() then
            Menu.Neverlose.VelocityVectorX:set(math_floor(Handle.Velocity.MoveElement.x + Mouse.x))
            Menu.Neverlose.VelocityVectorY:set(math_floor(Handle.Velocity.MoveElement.y + Mouse.y))
        end

    end

    local ShutDownFunction = function()
        MenuReferences.Scope:override(nil)
        Handle.Cvars.drawhud:int(1)

        native_AlphaModulate(Handle.Sparks.Mat, 1)
        native_ColorModulate(Handle.Sparks.Mat, 1, 1, 1)

        for i, unHookFunc in ipairs(VMTHook.hooks) do
            unHookFunc()
        end
    end

    DragSystem()
    CallbackManager.AddMethod("render", SpecListRender, false, "Speclist")
    CallbackManager.AddMethod("render", ScopeChange, false, "Scope Changer")
    CallbackManager.AddMethod("render", NadesRender, false, "Render Nades")
    CallbackManager.AddMethod("render", CenterScreenIndicators, false, "Center Screen Indicators")
    CallbackManager.AddMethod("render", HUD, false, "HUD Render")
    CallbackManager.AddMethod("render", Keybinds, false, "Keybinds Render")
    CallbackManager.AddMethod("render", WaterMark, false, "Watermark Render")
    CallbackManager.AddMethod("render", WeaponPanel, false, "Weapon Panel Render")
    CallbackManager.AddMethod("render", Velocity, false, "Velocity Warning Render")
    CallbackManager.AddMethod("render", DamageRender, false, "Damage Render") 
    CallbackManager.AddMethod("render", HitMarkerRender, false, "Marker Render")
    CallbackManager.AddMethod("render", ViewModelRender, false, "View Model Render")
    CallbackManager.AddMethod("render", AspectRatioRender, false, "Aspect Ratio Render")
    CallbackManager.AddMethod("render", ConsoleRender, false, "Console Color Render")  
    CallbackManager.AddMethod("render", LogsRender, false, "Logs Render")
    CallbackManager.AddMethod("createmove", UpdateHook, false, "Update Hook")
    CallbackManager.AddMethod("createmove_run", OnCreateMove, false, "OnCreateMoveRun")
    CallbackManager.AddMethod("createmove", EnableGameMovement, false, "Change Game Move")
    CallbackManager.AddMethod("shutdown", ShutDownFunction, false, "ShutDown Visuals")
    CallbackManager.AddMethod("aim_ack", BulletVector, false, "HitMarker Vector")
    events.bullet_impact:set(SparksOnImpact)
    events.player_hurt:set(PlayerHurt)
    events.player_death:set(PlayerDeath)
    events.round_start:set(RoundStart)
    events.round_end:set(RoundEnds)
    events.bomb_planted:set(BombPlant)
    events.player_say:set(PlayerSay)
end



Misc.Init = function()
    Misc.TableLogs = {} -- // for later visuals render

    local Handle = {
        ClanTag = {
            TagTable = {
                "☁️","☁️l","☁️al","☁️tal","☁️ital","☁️gital","☁️igital","☁️Digital","☁️Digital", "D☁️igital","Dr☁️gital","Dre☁️ital","Drea☁️tal","Dream☁️al","Dreams☁️l","Dreams ☁️","Dreams☁️", "Dream☁️","Drea☁️", "Dre☁️", "Dr☁️", "D☁️","☁️"
            },
            IsFixed = false,
            LastIter = nil
            
        },
        Logs = {
            HitBoxes = {
                [0] = 'generic',
                'head', 
                'chest', 
                'stomach',
                'left arm', 
                'right arm',
                'left leg', 
                'right leg',
                'neck', 
                'generic', 
                'gear'
            }
        },
    }
    
    local ClanTagRender = function()
        if not Menu.DataUI["Misc"]["Misc"]["ClanTag"] then
            if Handle.ClanTag.IsFixed == true then
                native_SetClantag(" ")
                Handle.ClanTag.IsFixed = false
            end
            return
        end
        
        if not globals.is_connected then
            return
        end

        local NetChannel = utils.net_channel()
        if NetChannel == nil then
            return
        end

        local RawLatency = NetChannel.latency[0]
        local Latency = RawLatency / globals.tickinterval
        local TickCount = globals.tickcount + Latency
        local Iter = math_floor(math_fmod(TickCount / 25, #Handle.ClanTag.TagTable))
        if Iter ~= Handle.ClanTag.LastIter then
            if Handle.ClanTag.TagTable[Iter] ~= nil then
                native_SetClantag(Handle.ClanTag.TagTable[Iter])
            end

            Handle.ClanTag.LastIter = Iter
        end

        Handle.ClanTag.IsFixed = true
    end

    local AimData = function(shot)
        local Reason = shot.state
        local Entity = shot.target
        local Name = Entity:get_name()

        local ColorBaseReason = {
            ["correction"] = Menu.DataUI["Misc"]["Misc"]["Correction Color"]:clone(),
            ["spread"] = Menu.DataUI["Misc"]["Misc"]["Spread Color"]:clone(),
            ["misprediction"] = Menu.DataUI["Misc"]["Misc"]["Misprediction Color"]:clone(),
            ["prediction error"] = Menu.DataUI["Misc"]["Misc"]["Prediction error Color"]:clone(),
            ["lagcomp failure"] = Menu.DataUI["Misc"]["Misc"]["Lagcomp failure Color"]:clone(),
            ["unregistered shot"] = Menu.DataUI["Misc"]["Misc"]["Unregistered shot Color"]:clone()
        }

        local HitColor = Menu.DataUI["Misc"]["Misc"]["Hit Color"] and Menu.DataUI["Misc"]["Misc"]["Hit Color"]:clone() or color(255, 255)
        
        if Reason == nil then
            -- hit
            if not Menu.DataUI["Misc"]["Misc"]["Logs Types"][1] then
                return
            end

            if Menu.DataUI["Misc"]["Misc"]["Logs Options"][2] then
                table_insert(Misc.TableLogs, {
                    {
                        {"Hit ", color(255, 255)},
                        {tostring(Name), HitColor},
                        {"'s ", color(255, 255)},
                        {tostring(Handle.Logs.HitBoxes[shot.hitgroup]), HitColor},
                        {" for ", color(255, 255)},
                        {tostring(shot.damage), HitColor},
                        {" damage ", color(255, 255)}

                    },
                    globals.realtime,
                    0,
                    0,
                    HitColor,
                    Files.image_LoadLogHit
                })
            end

            if Menu.DataUI["Misc"]["Misc"]["Logs Options"][1] then
                FFIHandle.PrintConsole(
                    {"Digital ➤ " , HitColor},
                    {"Hit ", color(255, 255)},
                    {tostring(Name), HitColor},
                    {"'s ", color(255, 255)},
                    {tostring(Handle.Logs.HitBoxes[shot.hitgroup]), HitColor},
                    {" for ", color(255, 255)},
                    {tostring(shot.damage), HitColor},
                    {" damage (wanted ", color(255, 255)},
                    {tostring(shot.wanted_damage), HitColor},
                    {") bt = ", color(255, 255)},
                    {tostring(shot.backtrack), HitColor}
                )
            end

            return
        end
        
        if not Menu.DataUI["Misc"]["Misc"]["Logs Types"][2] then
            return
        end

        -- miss
        local ColorMiss = color(255, 0, 0, 255)
        if ColorBaseReason[Reason] ~= nil then
            ColorMiss = ColorBaseReason[Reason]:clone()
        else
            ColorMiss = Menu.DataUI["Misc"]["Misc"]["Other Color"]:clone()
        end
        
        if Menu.DataUI["Misc"]["Misc"]["Logs Options"][2] then
            table_insert(Misc.TableLogs, {
                {

                    {"Missed ", color(255, 255)},
                    {tostring(Name), ColorMiss},
                    {"'s ", color(255, 255)},
                    {tostring(Handle.Logs.HitBoxes[shot.wanted_hitgroup]), ColorMiss},
                    {" due to ", color(255, 255)},
                    {tostring(Reason), ColorMiss}

                },
                globals.realtime,
                0,
                0,
                ColorMiss,
                Files.image_LoadLogMiss
            })
        end

        if Menu.DataUI["Misc"]["Misc"]["Logs Options"][1] then
            FFIHandle.PrintConsole(
                {"Digital ➤ " , ColorMiss},
                {"Missed ", color(255, 255)},
                {tostring(Name), ColorMiss},
                {"'s ", color(255, 255)},
                {tostring(Handle.Logs.HitBoxes[shot.wanted_hitgroup]), ColorMiss},
                {" due to ", color(255, 255)},
                {tostring(Reason), ColorMiss},
                {" (wanted ", color(255, 255)},
                {tostring(shot.wanted_damage), ColorMiss},
                {") bt = ", color(255, 255)},
                {tostring(shot.backtrack), ColorMiss}
            )
        end
    end

    local NadesData = function(event)
        local LocalPlayer = entity.get_local_player()
        if LocalPlayer == nil or not LocalPlayer:is_alive() then
            return
        end

        if entity.get(event.attacker, true) ~= LocalPlayer then
            return
        end

        local Victim = entity.get(event.userid, true)
        if Victim == nil then
            return
        end

        local Name = Victim:get_name()

        local NadesDamage = event.dmg_health
        if NadesDamage == nil then
            return
        end

        local HitColor = Menu.DataUI["Misc"]["Misc"]["Hit Color"] and Menu.DataUI["Misc"]["Misc"]["Hit Color"]:clone() or color(255, 255)

        if tostring(event.weapon) == "inferno" then
            --molotov
            if not Menu.DataUI["Misc"]["Misc"]["Logs Types"][1] then
                return
            end

            if Menu.DataUI["Misc"]["Misc"]["Logs Options"][2] then
                table_insert(Misc.TableLogs, {
                    {
                        {"Burned ", color(255, 255)},
                        {tostring(Name), HitColor},
                        {" for ", color(255, 255)},
                        {tostring(NadesDamage), HitColor},
                        {" damage", color(255, 255)}

                    },
                    globals.realtime,
                    0,
                    0,
                    HitColor,
                    Files.image_LoadLogHit
                })
            end

            if Menu.DataUI["Misc"]["Misc"]["Logs Options"][1] then
                FFIHandle.PrintConsole(
                    {"Digital ➤ " , HitColor},
                    {"Burned ", color(255, 255)},
                    {tostring(Name), HitColor},
                    {" for ", color(255, 255)},
                    {tostring(NadesDamage), HitColor},
                    {" damage", color(255, 255)}
                )
            end

        end

        if tostring(event.weapon) == "hegrenade" then

            if not Menu.DataUI["Misc"]["Misc"]["Logs Types"][1] then
                return
            end

            if Menu.DataUI["Misc"]["Misc"]["Logs Options"][2] then
                table_insert(Misc.TableLogs, {
                    {
                        {"Naded ", color(255, 255)},
                        {tostring(Name), HitColor},
                        {" for ", color(255, 255)},
                        {tostring(NadesDamage), HitColor},
                        {" damage", color(255, 255)}

                    },
                    globals.realtime,
                    0,
                    0,
                    HitColor,
                    Files.image_LoadLogHit
                })
            end

            if Menu.DataUI["Misc"]["Misc"]["Logs Options"][1] then
                FFIHandle.PrintConsole(
                    {"Digital ➤ " , HitColor},
                    {"Naded ", color(255, 255)},
                    {tostring(Name), HitColor},
                    {" for ", color(255, 255)},
                    {tostring(NadesDamage), HitColor},
                    {" damage", color(255, 255)}
                )
            end
        end
    end

    local LocalHurt = function(event)
        local LocalPlayer = entity.get_local_player()
        if LocalPlayer == nil or not LocalPlayer:is_alive() then
            return
        end

        if entity.get(event.userid, true) ~= LocalPlayer  then
            return
        end

        local Attacker = entity.get(event.attacker, true)
        if Attacker == nil then
            return
        end

        if not Attacker:is_player() then
            return
        end

        local Damaged = event.dmg_health
        local Name = Attacker:get_name()
        local HurtColor = Menu.DataUI["Misc"]["Misc"]["Hurt Color"] and Menu.DataUI["Misc"]["Misc"]["Hurt Color"]:clone() or color(255, 255)


        if Menu.DataUI["Misc"]["Misc"]["Logs Types"][3] then
            if Menu.DataUI["Misc"]["Misc"]["Logs Options"][2] then
                table_insert(Misc.TableLogs, {
                    {
                        {"Player ", color(255, 255)},
                        {tostring(Name), HurtColor},
                        {" hurt you for ", color(255, 255)},
                        {tostring(Damaged), HurtColor},
                        {" damage", color(255, 255)}
    
                    },
                    globals.realtime,
                    0,
                    0,
                    HurtColor,
                    Files.image_LoadLogMiss
                })
            end
    
            if Menu.DataUI["Misc"]["Misc"]["Logs Options"][1] then
                FFIHandle.PrintConsole(
                    {"Digital ➤ " , HurtColor},
                    {"Player ", color(255, 255)},
                    {tostring(Name), HurtColor},
                    {" hurt you for ", color(255, 255)},
                    {tostring(Damaged), HurtColor},
                    {" damage", color(255, 255)}
                )
            end
        end

        local SoundsPaths = {
            ["Switch"] = "buttons/arena_switch_press_02.wav",
            ["Warning"] = "resource/warning.wav",
            ["Wood Stop"] = "doors/wood_stop1.wav",
            ["Wood Strain"] = "physics/wood/wood_strain7.wav",
            ["Wood Plank"] = "physics/wood/wood_plank_impact_hard4.wav"
        }

        if not Menu.DataUI["Misc"]["Misc"]["Local Hurt Sound"] then
            return
        end

        local Sound = SoundsPaths[Menu.DataUI["Misc"]["Misc"]["Local Hurt Sound"]]
        if Sound == nil then
            return
        end

        native_PlaySound(Sound, Menu.DataUI["Misc"]["Misc"]["Volume"] / 100, 100, 0, 0)
    end

    local ItemPurchase = function(event)
        local LocalPlayer = entity.get_local_player()
        if LocalPlayer == nil or not LocalPlayer:is_alive() then
            return
        end

        if not Menu.DataUI["Misc"]["Misc"]["Logs Types"][4] then
            return
        end

        local User = entity.get(event.userid, true)
        if User == nil then
            return
        end

        if not User:is_player() then
            return
        end

        if User == LocalPlayer then
            return
        end

        local TeamUser = event.team
        if LocalPlayer.m_iTeamNum == TeamUser then
            return
        end

        local ColorBuy = Menu.DataUI["Misc"]["Misc"]["Purchase Color"] and Menu.DataUI["Misc"]["Misc"]["Purchase Color"]:clone() or color(255, 255)
        local ItemBought = event.weapon
        local UserName = User:get_name()

        if string.find(ItemBought, "weapon_") then
            ItemBought = string.gsub(ItemBought, "weapon_", "")
        end

        if string.find(ItemBought, "item_") then
            ItemBought = string.gsub(ItemBought, "item_", "")
        end

        local Name = User:get_name()
        
        if Menu.DataUI["Misc"]["Misc"]["Logs Options"][2] then
            table_insert(Misc.TableLogs, {
                {

                    {"Player ", color(255, 255)},
                    {tostring(Name), ColorBuy},
                    {" bought ", color(255, 255)},
                    {tostring(ItemBought), ColorBuy}

                },
                globals.realtime,
                0,
                0,
                ColorBuy,
                Files.image_LoadLogBuy
            })
        end

        if Menu.DataUI["Misc"]["Misc"]["Logs Options"][1] then
            FFIHandle.PrintConsole(
                {"Digital ➤ " , ColorBuy},
                {"Player ", color(255, 255)},
                {tostring(Name), ColorBuy},
                {" bought ", color(255, 255)},
                {tostring(ItemBought), ColorBuy}
            )
        end
    end

    local RemoveElments = function()
        cvar.cl_chatfilters:int(Menu.DataUI["Misc"]["Misc"]["Remove"][1] and 0 or 63) 
        cvar.cl_drawhud_force_radar:int(Menu.DataUI["Misc"]["Misc"]["Remove"][2] and -1 or 1)
        cvar.cl_ragdoll_physics_enable:int(Menu.DataUI["Misc"]["Misc"]["Remove"][3] and 0 or 1)
    end

    local TrashTalkP = Helpers.StringToSub(User.TrashTalkPhases, "|")
    local PlayerDeath = function(event)
        if not Menu.DataUI["Misc"]["Misc"]["Trash Talk"] then
            return
        end

        local LocalPlayer = entity.get_local_player()
        if LocalPlayer == nil or not LocalPlayer:is_alive() then
            return
        end

        local Attacker = entity.get(event.attacker, true)
        if Attacker == nil then
            return
        end

        if Attacker ~= LocalPlayer then
            return
        end

        local SelectedPhase = TrashTalkP[utils.random_int(1, #TrashTalkP)]
        if SelectedPhase == nil then
            return
        end

        utils.execute_after(SelectedPhase:len() > 20 and 3 or 1, function()
            utils.console_exec("say " ..  tostring(SelectedPhase) .. " ")
        end)
    end

    local PlayerHurt = function(event)
        NadesData(event)
        LocalHurt(event)
    end

    local ShutDownMisc = function()
        native_SetClantag(" ")
        cvar.cl_ragdoll_physics_enable:int(1)
        cvar.cl_chatfilters:int(63) 
        cvar.cl_drawhud_force_radar:int(1)
    end

    CallbackManager.AddMethod("render", ClanTagRender, false, "ClanTag Render")
    CallbackManager.AddMethod("render", RemoveElments, false, "Remove Elements")
    CallbackManager.AddMethod("aim_ack", AimData, false, "Aim Data")
    CallbackManager.AddMethod("shutdown", ShutDownMisc, false, "ShutDown Misc")
    events.player_hurt:set(PlayerHurt)
    events.item_purchase:set(ItemPurchase)
    events.player_death:set(PlayerDeath)
end

Menu.Init = function()
    Menu.GlobalTime = 0 -- // we will use it for menu ui elements
    Menu.MenuData = 
    {
        Size = vector(300, 300),
        -- // dont need it for now // SubTabsPointer = {},
        ScreenSize = render.screen_size(),
        Logs = {}
    }
    Menu.Components = {}
    --@sub tabs mechanic
    Menu.IsSomeComponentsShowen = {}
    --@draw components Handle
    Menu.DrawComponents = {}
    --@keybinds handle & data
    Menu.Keybinds = {Names = {}, Data = {}}
    Menu.VirtualKeysNames = 
    {
        {0x1B, "-"},
        {0x03, "m3"},
        {0x05, "m4"},
        {0x06, "m5"},
        {0x08, "Back"},
        {0x09, "Tab"},
        {0x0D, "Enter"},
        {0x10, "Shift"},
        {0x11, "Ctrl"},
        {0x12, "Alt"}, -- 10

        {0x13, "Pause"},
        {0x14, "Caps"},
        {0x20, "Space"},
        {0x25, "Left"},
        {0x26, "Up"},
        {0x27, "Right"},
        {0x28, "Down"},
        {0x29, "Select"}, -- 18

        {0x30, "0"}, -- 19
        {0x31, "1"},
        {0x32, "2"},
        {0x33, "3"},
        {0x34, "4"},
        {0x35, "5"},
        {0x36, "6"},
        {0x37, "7"},
        {0x38, "8"},
        {0x39, "9"},
        {0x41, "A"},
        {0x42, "B"},
        {0x43, "C"},
        {0x44, "D"},
        {0x45, "E"},
        {0x46, "F"},
        {0x47, "G"},
        {0x48, "H"},
        {0x49, "I"},
        {0x4A, "J"},
        {0x4B, "K"},
        {0x4C, "L"},
        {0x4D, "M"},
        {0x4E, "N"},
        {0x4F, "O"},
        {0x50, "P"},
        {0x51, "Q"},
        {0x52, "R"},
        {0x53, "S"},
        {0x54, "T"},
        {0x55, "U"},
        {0x56, "V"},
        {0x57, "W"},
        {0x58, "X"},
        {0x59, "Y"},
        {0x5A, "Z"}, -- -12


        {0x70, "F1"}, -- =11
        {0x71, "F2"},
        {0x72, "F3"},
        {0x73, "F4"},
        {0x74, "F5"},
        {0x75, "F6"},
        {0x76, "F7"},
        {0x77, "F8"},
        {0x78, "F9"},
        {0x79, "F10"},
        {0x7A, "F11"}
    }
    Menu.KeybindsModes = {"hold", "toggle", "always"}
    --@MenuTabs
    Menu.Tabs = 
    {
        {"RageBot", Files.image_LoadRage, 0}, 
        {"Anti Aim", Files.image_LoadAntiAim, 0},
        {"Visuals", Files.image_LoadVisuals, 0},
        {"Misc", Files.image_LoadMisc, 0},
    }
    --@MenuSubTabs
    Menu.DrawComponents.SubTabs = {}
    --@MenuElementsData
    Menu.DataUI = {}
    --@create holders for tab
    for Index, SelectedTab in pairs(Menu.Tabs) do
        local TabName = SelectedTab[1]

        Menu.DrawComponents.SubTabs[TabName] = {} -- create holder for subtab data for later
        --Menu.IsSomeComponentsShowen[TabName] = false -- close every tab/subtab in menu background

        Menu.DataUI[TabName] = {}
    end
    --@neverlose menu elements
    Menu.Neverlose = {}
    Menu.Neverlose.Init = function()
        ui.sidebar(Helpers.GradientText({color(36, 255), color(200, 255)}, (User.LocalBuild ~= "public" and "Digital [" .. User.LocalBuild .. "]"  or "Digital Dreams")), "cloud")
        Menu.Neverlose.MainGroup = ui.create("Main")
        Menu.Neverlose.HideGroup = ui.create("Hide")
        Menu.Neverlose.UpdateLogGroup = ui.create("Update")

        --update log
        Menu.Neverlose.UpdateLogGroup:label("Help me")

        --main color
        Menu.Neverlose.MainColor = Menu.Neverlose.MainGroup:color_picker("UI active color", color(122,48,169, 255))

        Menu.Neverlose.BoxAddX = Menu.Neverlose.MainGroup:slider("Menu Add X", 0, 1000, 500, 1):set_visible(false) -- Menu.Render.MenuWidth
        Menu.Neverlose.BoxAddY = Menu.Neverlose.MainGroup:slider("Menu Add Y", 0, 1000, 500, 1):set_visible(false) -- Menu.Render.MenuWidth
        --Menu.Render.MenuWidth = 500
        --Menu.Render.Length = 500

        --vectors
        Menu.Neverlose.MenuVectorX = Menu.Neverlose.HideGroup:slider("menu x", 0, Menu.MenuData.ScreenSize.x, 300, 1):set_visible(false)
        Menu.Neverlose.MenuVectorY = Menu.Neverlose.HideGroup:slider("menu y", 0, Menu.MenuData.ScreenSize.y, 300, 1):set_visible(false)

        Menu.Neverlose.LogsVectorX = Menu.Neverlose.HideGroup:slider("logs x", 0, Menu.MenuData.ScreenSize.x, 15, 1):set_visible(false)
        Menu.Neverlose.LogsVectorY = Menu.Neverlose.HideGroup:slider("logs y", 0, Menu.MenuData.ScreenSize.y, 5, 1):set_visible(false)

        Menu.Neverlose.KeyVectorX = Menu.Neverlose.HideGroup:slider("keys x", 0, Menu.MenuData.ScreenSize.x, 100, 1):set_visible(false)
        Menu.Neverlose.KeyVectorY = Menu.Neverlose.HideGroup:slider("keys y", 0, Menu.MenuData.ScreenSize.y, 100, 1):set_visible(false)

        Menu.Neverlose.WaterVectorX = Menu.Neverlose.HideGroup:slider("water x", 0, Menu.MenuData.ScreenSize.x, Menu.MenuData.ScreenSize.x - 100, 1):set_visible(false)
        Menu.Neverlose.WaterVectorY = Menu.Neverlose.HideGroup:slider("water y", 0, Menu.MenuData.ScreenSize.y, 10, 1):set_visible(false)

        Menu.Neverlose.VelocityVectorX = Menu.Neverlose.HideGroup:slider("velocity x", 0, Menu.MenuData.ScreenSize.x, Menu.MenuData.ScreenSize.x /2 - 100, 1):set_visible(false)
        Menu.Neverlose.VelocityVectorY = Menu.Neverlose.HideGroup:slider("velocity y", 0, Menu.MenuData.ScreenSize.y, 300, 1):set_visible(false)

        --items vectors
        --?
        Menu.Neverlose.MainGroup:button("Reload Files", function()
            for FileId, FilePointer in pairs(Files.DownloadFiles) do
                Files.Download(FilePointer, true)
            end
        end)
    end
    --@create menu components
    Menu.Components.Init = function()
        --@subtab
        Menu.Components.SubTab = function(Tab, NewName, IconPointer)
            Menu.DataUI[Tab][NewName] = {}

            local SeletedIndex = #Menu.DrawComponents.SubTabs[Tab] + 1

            Menu.DrawComponents.SubTabs[Tab][SeletedIndex] = 
            {
                Tab = Tab,
                SubTab = NewName,
                Icon = IconPointer,
                UI = {}
            }

            if Menu.IsSomeComponentsShowen[Tab] == nil then
                Menu.IsSomeComponentsShowen[Tab] = Menu.DrawComponents.SubTabs[Tab][SeletedIndex].UI
            end

            return Menu.DrawComponents.SubTabs[Tab][SeletedIndex] -- returns point to the subtab data to edit the ui later
        end
        --@checkbox
        Menu.Components.CheckBox = function(SubPointer, Name, DefaultValue, VisibleCheck)
            local DefaultValue = DefaultValue and DefaultValue or false -- set or create default value
            local VisibleCheck = VisibleCheck and VisibleCheck or function() return true end

            local SelectedIndex = #SubPointer.UI + 1 -- get the local index for this checkbox

            SubPointer.UI[SelectedIndex] = 
            { -- create the elements in list
                Name = Name,
                Type = "Switch",
                Value = DefaultValue,
                Visible = VisibleCheck,
                Point = nil,
                ExternalData = nil
            }

            Menu.DataUI[SubPointer.Tab][SubPointer.SubTab][Name] = DefaultValue -- create value holder
            return {Index = SelectedIndex, Point = SubPointer} -- returns pointer that we can modifie later
        end
        --@slider
        Menu.Components.Slider = function(SubPointer, Name, MinimumValue, MaximumValue, DefaultValue, VisibleCheck)
            local DefaultValue = DefaultValue and DefaultValue or MinimumValue -- set or create default value
            local VisibleCheck = VisibleCheck and VisibleCheck or function() return true end

            local SelectedIndex = #SubPointer.UI + 1 -- get the local index for this checkbox

            SubPointer.UI[SelectedIndex] = 
            { -- create the elements in list
                Name = Name,
                Type = "Slider",
                Value = DefaultValue,
                Visible = VisibleCheck,
                Point = nil,
                ExternalData = {Min = MinimumValue, Max = MaximumValue}
            }

            Menu.DataUI[SubPointer.Tab][SubPointer.SubTab][Name] = DefaultValue -- create value holder
            return {Index = SelectedIndex, Point = SubPointer} -- returns pointer that we can modifie later
        end
        --@combo box
        Menu.Components.ListBox = function(SubPointer, Name, TablesValue, DefaultValue, VisibleCheck)
            local DefaultValue = DefaultValue and DefaultValue or TablesValue[1] -- set or create default value
            local VisibleCheck = VisibleCheck and VisibleCheck or function() return true end

            local SelectedIndex = #SubPointer.UI + 1 -- get the local index for this checkbox

            SubPointer.UI[SelectedIndex] = 
            { -- create the elements in list
                Name = Name,
                Type = "ListBox",
                Value = DefaultValue,
                Visible = VisibleCheck,
                Point = nil,
                ExternalData = {Items = TablesValue, SubPointer = SubPointer}
            }

            Menu.DataUI[SubPointer.Tab][SubPointer.SubTab][Name] = DefaultValue -- create value holder
            return {Index = SelectedIndex, Point = SubPointer} -- returns pointer that we can modifie later
        end
        --@multi combo box
        Menu.Components.MultiListBox = function(SubPointer, Name, TablesValue, DefaultValue, VisibleCheck)
            local DefaultValue = DefaultValue and DefaultValue or false -- set or create default value
            local VisibleCheck = VisibleCheck and VisibleCheck or function() return true end

            local SelectedIndex = #SubPointer.UI + 1 -- get the local index for this checkbox

            local TableValues = {}
            for Index = 1, #TablesValue do
                TableValues[Index] = DefaultValue
            end

            SubPointer.UI[SelectedIndex] = 
            { -- create the elements in list
                Name = Name,
                Type = "MultiListBox",
                Value = TableValues,
                Visible = VisibleCheck,
                Point = nil,
                ExternalData = {Items = TablesValue, SubPointer = SubPointer}
            }

            Menu.DataUI[SubPointer.Tab][SubPointer.SubTab][Name] = TableValues -- create value holder
            return {Index = SelectedIndex, Point = SubPointer} -- returns pointer that we can modifie later
        end
        --@color edit 
        Menu.Components.ColorEdit = function(SubPointer, Name, DefaultValue, PickerSize, VisibleCheck)
            local DefaultValue = DefaultValue and DefaultValue or color(255, 255) -- set or create default value
            --local PickerSize = PickerSize and PickerSize or 120 -- set or create the picker size to draw
            local VisibleCheck = VisibleCheck and VisibleCheck or function() return true end

            local SelectedIndex = #SubPointer.UI + 1 -- get the local index for this checkbox

            SubPointer.UI[SelectedIndex] = 
            { -- create the elements in list
                Name = Name,
                Type = "ColorEdit",
                Value = DefaultValue,
                Visible = VisibleCheck,
                Point = nil,
                ExternalData = {DefaultColor = DefaultValue:clone()}
            }

            Menu.DataUI[SubPointer.Tab][SubPointer.SubTab][Name] = DefaultValue -- create value holder
            return {Index = SelectedIndex, Point = SubPointer} -- returns pointer that we can modifie later
        end
        --@keybinds
        Menu.Components.KeyBind = function(SubPointer, Name, DefaultValue, DistableMode, VisibleCheck)
            local DefaultValue = DefaultValue and DefaultValue or 0x1B -- set or create default value
            local DistableMode = DistableMode and DistableMode or false -- set or create the picker size to draw
            local VisibleCheck = VisibleCheck and VisibleCheck or function() return true end

            local SelectedIndex = #SubPointer.UI + 1 -- get the local index for this checkbox

            Menu.Keybinds.Data[Name] = 
            { -- create data holder for menu
                Key = DefaultValue,
                KeyType = "hold",
                Value = false
            }

            Menu.Keybinds.Names[#Menu.Keybinds.Names + 1] = Name -- create list to loop later go get the value

            SubPointer.UI[SelectedIndex] = 
            { -- create the elements in list
                Name = Name,
                Type = "KeyBind",
                Value = DefaultValue,
                Visible = VisibleCheck,
                Point = nil,
                ExternalData = {KeyType = "hold", IsDisabled = DistableMode}
            }

            -- // dont need it - i will use it later maybe //Menu.DataUI[SubPointer.Tab][SubPointer.SubTab][Name] = DefaultValue -- create value holder
            return {Index = SelectedIndex, Point = SubPointer} -- returns pointer that we can modifie later
        end
        --@button
        Menu.Components.Button = function(SubPointer, Name, FunctionToRun, VisibleCheck, IconToDraw)
            local SelectedIndex = #SubPointer.UI + 1 -- get the local index for this checkbox
            local VisibleCheck = VisibleCheck and VisibleCheck or function() return true end


            SubPointer.UI[SelectedIndex] = 
            { -- create the elements in list
                Name = Name,
                Type = "Button",
                Value = DefaultValue,
                Visible = VisibleCheck,
                Point = nil,
                ExternalData = {ToRun = FunctionToRun, Icon = IconToDraw}
            }
            return {Index = SelectedIndex, Point = SubPointer} -- returns pointer that we can modifie later
        end
        --@delete ui component
        Menu.Components.Delete = function(SubPointer, Name)
            for Index, ItemUI in pairs(SubPointer.UI) do
                if ItemUI.Name == Name then
                    table_remove(SubPointer.UI, Index)
                    return true
                end
            end
            return nil -- return nil on fail to find
        end
    end
    Menu.Components.GetCFG = function()
        local Txt = ""
        
        for Index, Tab in ipairs(Menu.Tabs) do
            local TabData = ""
            if Menu.DataUI["Misc"]["CFG"]["Select Tabs To Use"][Index] then
                local TabName = Tab[1]

                for J, SubTab in pairs(Menu.DrawComponents.SubTabs[TabName]) do
                    for ItemIndex, Item in pairs(SubTab.UI) do
                        local UIValue = nil
                        
                        if Item.Type == "Button" then
                            UIValue = "?"
                        elseif type(Item.Value) == 'userdata' then
                            local ColorHandle = "{"
                            ColorHandle = ColorHandle .. Item.Value.r .. ","
                            ColorHandle = ColorHandle .. Item.Value.g .. ","
                            ColorHandle = ColorHandle .. Item.Value.b .. ","
                            ColorHandle = ColorHandle .. Item.Value.a .. "}"
                            UIValue = ColorHandle
                        elseif type(Item.Value) == "table" then
                            UIValue = Helpers.TableExport(Item.Value, ",")
                        else
                            UIValue = tostring(Item.Value)
                        end
    
                        TabData = TabData .. SubTab.SubTab .. "#" .. Item.Name .. "#" .. tostring(UIValue) .. "|"
                    end
                end
            else
                TabData = "?"
            end

            Txt = Txt .. TabData .. "<"
        end

        if Txt == "" then
            error("Error in Getting CFG Data")
        end
        
        return Txt
    end
    local FindElement = function(Table, SubName, ItemName)
        local Loop = Helpers.StringToSub(Table[1], Table[2])
        for I, Item in pairs(Loop) do
            local SlotLoop = Helpers.StringToSub(Item, Table[3])

            if SlotLoop[1] == SubName and SlotLoop[2] == ItemName then
                return SlotLoop[3]
            end
        end

        return nil -- // return nil on fail
    end
    Menu.Components.SetCFG = function(Code)
        local txt = dec(Code)

        local TabData = Helpers.StringToSub(txt, "<")
        
        for Index, Tab in ipairs(Menu.Tabs) do
            if not Menu.DataUI["Misc"]["CFG"]["Select Tabs To Use"][Index] then
                goto skip
            end

            if TabData[Index] == "?" or TabData[Index] == nil then
                goto skip
            end

            --local CFGTag = Helpers.StringToSub(TabData[Index], "|")

            local TabName = Tab[1]

            for J, SubTab in pairs(Menu.DrawComponents.SubTabs[TabName]) do
                for ItemIndex, Item in pairs(SubTab.UI) do

                    if Item.Type == "Button" then
                        goto skip_item
                    end

                    local SlotData = FindElement({TabData[Index], "|", "#"}, SubTab.SubTab, Item.Name)
                    if SlotData == nil then
                        goto skip_item
                    end

                    local Value = Helpers.StringConvert(SlotData)
                    if Value == nil then
                        goto skip_item
                    end

                    if type(Item.Value) ~= type(Value) then
                        print("False Convert in " .. Item.Name)
                        print("Convert Type : " .. type(Value))
                        print("Need Type : " .. type(Item.Value))
                        goto skip_item
                    end

                    Item.Value = Value

                    ::skip_item::

                end
            end


            ::skip::
        end
    end

    --@build menu components
    Menu.Components.BuildItems = function()
        local RageBot_Main = Menu.Components.SubTab("RageBot", "Main", Files.image_LoadMain) -- // _ == " "
        --local RageBot_Weapons = Menu.Components.SubTab("RageBot", "Weapons", Files.image_LoadCustomMode)

        local Anti_Aim_Main = Menu.Components.SubTab("Anti Aim", "Main", Files.image_LoadMain)
        local Anti_Aim_Misc = Menu.Components.SubTab("Anti Aim", "Misc", Files.image_LoadMiscMenu)
        local Anti_Aim_CustomSettings = Menu.Components.SubTab("Anti Aim", "Custom Settings", Files.image_LoadCustomMode)
        local Anti_Aim_Anti_Brutforce = Menu.Components.SubTab("Anti Aim", "Anti Bruteforce", Files.image_LoadWarning)

        local Visuals_UI = Menu.Components.SubTab("Visuals", "UI", Files.image_LoadUI)
        local Visuals_Visuals = Menu.Components.SubTab("Visuals", "Visuals", Files.image_LoadVisualsMenu)
        local Visuals_Indicators = Menu.Components.SubTab("Visuals", "Indicators", Files.image_LoadData)
        local Visuals_Colors = Menu.Components.SubTab("Visuals", "Colors", Files.image_LoadColorMenu)

        local Misc_Misc = Menu.Components.SubTab("Misc", "Misc", Files.image_LoadMiscMenu)
        local Misc_CFG = Menu.Components.SubTab("Misc", "CFG", Files.image_LoadSave)
        local Misc_Local = Menu.Components.SubTab("Misc", "Local", Files.image_LoadActiveLink)
        local Misc_Menu = Menu.Components.SubTab("Misc", "Menu", Files.image_LoadUI)

        Menu.Components.CheckBox(RageBot_Main, "Air Hitchance", false)
        Menu.Components.Slider(RageBot_Main, "Air Chance", 0, 100, 50, function() return Menu.DataUI["RageBot"]["Main"]["Air Hitchance"] end)
        Menu.Components.CheckBox(RageBot_Main, "No Scope Hitchance", false)
        Menu.Components.Slider(RageBot_Main, "No Scope Chance", 0, 100, 50, function() return Menu.DataUI["RageBot"]["Main"]["No Scope Hitchance"] end)

        --[[
        Menu.Components.CheckBox(RageBot_Weapons, "Enable External", false)
        Menu.Components.ListBox(RageBot_Weapons, "Select Weapon", User.WeaponsCfg, nil, function() return Menu.DataUI["RageBot"]["Weapons"]["Enable External"] end)

        for Index, Weapon in pairs(User.WeaponsCfg) do
            Menu.Components.CheckBox(RageBot_Weapons, string_format("Enable: %s", Weapon), false, function() return Menu.DataUI["RageBot"]["Weapons"]["Enable External"] and Menu.DataUI["RageBot"]["Weapons"]["Select Weapon"] == Weapon end)

            Menu.Components.MultiListBox(RageBot_Weapons, string_format("%s Safe", Weapon), User.ConditionsTable, false, function() return Menu.DataUI["RageBot"]["Weapons"]["Enable External"] and Menu.DataUI["RageBot"]["Weapons"]["Select Weapon"] == Weapon and Menu.DataUI["RageBot"]["Weapons"][string_format("Enable: %s", Weapon)] end)
            Menu.Components.ListBox(RageBot_Weapons, string_format("%s Safe Options", Weapon), {"Prefer", "Force"}, nil, function() return Menu.DataUI["RageBot"]["Weapons"]["Enable External"] and Menu.DataUI["RageBot"]["Weapons"]["Select Weapon"] == Weapon and Menu.DataUI["RageBot"]["Weapons"][string_format("Enable: %s", Weapon)] and Helpers.Contains(Menu.DataUI["RageBot"]["Weapons"][string_format("%s Safe", Weapon)], true) end)

            Menu.Components.MultiListBox(RageBot_Weapons, string_format("%s Baim", Weapon), User.ConditionsTable, false, function() return Menu.DataUI["RageBot"]["Weapons"]["Enable External"] and Menu.DataUI["RageBot"]["Weapons"]["Select Weapon"] == Weapon and Menu.DataUI["RageBot"]["Weapons"][string_format("Enable: %s", Weapon)] end)
            Menu.Components.ListBox(RageBot_Weapons, string_format("%s Baim Options", Weapon), {"Prefer", "Force"}, nil, function() return Menu.DataUI["RageBot"]["Weapons"]["Enable External"] and Menu.DataUI["RageBot"]["Weapons"]["Select Weapon"] == Weapon and Menu.DataUI["RageBot"]["Weapons"][string_format("Enable: %s", Weapon)] and Helpers.Contains(Menu.DataUI["RageBot"]["Weapons"][string_format("%s Baim", Weapon)], true) end)
        end

        --]]
        Menu.Components.ListBox(Anti_Aim_Main, "Anti Aim", {"None", "Auto Presets", "Digital Builder", "Default Builder"})
        Menu.Components.CheckBox(Anti_Aim_Main, "Pitch Down", false, function() return Menu.DataUI["Anti Aim"]["Main"]["Anti Aim"] ~= "None" end)
        Menu.Components.ListBox(Anti_Aim_Main, "Yaw", {"None", "Local View", "At Target"}, nil, function() return Menu.DataUI["Anti Aim"]["Main"]["Anti Aim"] ~= "None" end)
        Menu.Components.KeyBind(Anti_Aim_Main, "Manual Left", nil, true, function() return Menu.DataUI["Anti Aim"]["Main"]["Anti Aim"] ~= "None" end)
        Menu.Components.KeyBind(Anti_Aim_Main, "Manual Right", nil, true, function() return Menu.DataUI["Anti Aim"]["Main"]["Anti Aim"] ~= "None" end)
        Menu.Components.KeyBind(Anti_Aim_Main, "Manual Back", nil, true, function() return Menu.DataUI["Anti Aim"]["Main"]["Anti Aim"] ~= "None" end)
        Menu.Components.KeyBind(Anti_Aim_Main, "Edge Yaw", nil, false, function() return Menu.DataUI["Anti Aim"]["Main"]["Anti Aim"] ~= "None" end)
        Menu.Components.MultiListBox(Anti_Aim_Misc, "Anti Aim options", {"Allow on use","Custom SlowWalk","Static Manuals","Static on warmup"}, false, function() return Menu.DataUI["Anti Aim"]["Main"]["Anti Aim"] ~= "None" end)
        Menu.Components.Slider(Anti_Aim_Misc, "SlowWalk Speed", 0, 75, 40, function() return Menu.DataUI["Anti Aim"]["Main"]["Anti Aim"] ~= "None" and Menu.DataUI["Anti Aim"]["Misc"]["Anti Aim options"][2] end)
        Menu.Components.ListBox(Anti_Aim_CustomSettings, "Active Preset", {"Static", "New"}, nil, function() return Menu.DataUI["Anti Aim"]["Main"]["Anti Aim"] == "Auto Presets" end)
        Menu.Components.ListBox(Anti_Aim_CustomSettings, "Active State", User.PlayerStates, nil, function() return Menu.DataUI["Anti Aim"]["Main"]["Anti Aim"] ~= "None" and Menu.DataUI["Anti Aim"]["Main"]["Anti Aim"] ~= "Auto Presets" end)

        for Index = 1, 9 do
            if Index == 1 then
                Menu.Components.CheckBox(Anti_Aim_CustomSettings, string_format("Enable : %s", User.PlayerStates[Index]), true, function() return false end)
            else
                Menu.Components.CheckBox(Anti_Aim_CustomSettings, string_format("Enable : %s", User.PlayerStates[Index]), false, function() return (Menu.DataUI["Anti Aim"]["Custom Settings"]["Active State"] == User.PlayerStates[Index] and (Menu.DataUI["Anti Aim"]["Main"]["Anti Aim"] ~= "None" and Menu.DataUI["Anti Aim"]["Main"]["Anti Aim"] ~= "Auto Presets")) end)
            end

            Menu.Components.Slider(Anti_Aim_CustomSettings, string_format("%s Yaw", User.PlayerStates[Index]), -180, 180, 0, function() return Menu.DataUI["Anti Aim"]["Main"]["Anti Aim"] == "Default Builder" and Menu.DataUI["Anti Aim"]["Custom Settings"]["Active State"] == User.PlayerStates[Index] and Menu.DataUI["Anti Aim"]["Custom Settings"][string_format("Enable : %s", User.PlayerStates[Index])] end)
            Menu.Components.ListBox(Anti_Aim_CustomSettings, string_format("%s Modifier", User.PlayerStates[Index]), {"Disabled","Center","Offset","Random","Spin"}, nil, function() return Menu.DataUI["Anti Aim"]["Main"]["Anti Aim"] == "Default Builder" and Menu.DataUI["Anti Aim"]["Custom Settings"]["Active State"] == User.PlayerStates[Index] and Menu.DataUI["Anti Aim"]["Custom Settings"][string_format("Enable : %s", User.PlayerStates[Index])] end)
            Menu.Components.Slider(Anti_Aim_CustomSettings, string_format("%s Modifier Degree", User.PlayerStates[Index]), -180, 180, 0, function() return Menu.DataUI["Anti Aim"]["Main"]["Anti Aim"] == "Default Builder" and Menu.DataUI["Anti Aim"]["Custom Settings"]["Active State"] == User.PlayerStates[Index] and Menu.DataUI["Anti Aim"]["Custom Settings"][string_format("Enable : %s", User.PlayerStates[Index])] and Menu.DataUI["Anti Aim"]["Custom Settings"][ string_format("%s Modifier", User.PlayerStates[Index])] ~= "Disabled" end)
            Menu.Components.Slider(Anti_Aim_CustomSettings, string_format("%s Left Limit", User.PlayerStates[Index]), 0, 60, 0, function() return Menu.DataUI["Anti Aim"]["Main"]["Anti Aim"] == "Default Builder" and Menu.DataUI["Anti Aim"]["Custom Settings"]["Active State"] == User.PlayerStates[Index] and Menu.DataUI["Anti Aim"]["Custom Settings"][string_format("Enable : %s", User.PlayerStates[Index])] end)
            Menu.Components.Slider(Anti_Aim_CustomSettings, string_format("%s Right Limit", User.PlayerStates[Index]), 0, 60, 0, function() return Menu.DataUI["Anti Aim"]["Main"]["Anti Aim"] == "Default Builder" and Menu.DataUI["Anti Aim"]["Custom Settings"]["Active State"] == User.PlayerStates[Index] and Menu.DataUI["Anti Aim"]["Custom Settings"][string_format("Enable : %s", User.PlayerStates[Index])] end)
            Menu.Components.MultiListBox(Anti_Aim_CustomSettings, string_format("%s Fake Options", User.PlayerStates[Index]), {"Avoid Overlap","Jitter","Randomize Jitter"}, false, function() return Menu.DataUI["Anti Aim"]["Main"]["Anti Aim"] == "Default Builder" and Menu.DataUI["Anti Aim"]["Custom Settings"]["Active State"] == User.PlayerStates[Index] and Menu.DataUI["Anti Aim"]["Custom Settings"][string_format("Enable : %s", User.PlayerStates[Index])] end)
            Menu.Components.ListBox(Anti_Aim_CustomSettings, string_format("%s Lby Mode", User.PlayerStates[Index]), {"Disabled", "Opposite", "Sway"}, nil, function() return Menu.DataUI["Anti Aim"]["Main"]["Anti Aim"] == "Default Builder" and Menu.DataUI["Anti Aim"]["Custom Settings"]["Active State"] == User.PlayerStates[Index] and Menu.DataUI["Anti Aim"]["Custom Settings"][string_format("Enable : %s", User.PlayerStates[Index])] end)
            Menu.Components.ListBox(Anti_Aim_CustomSettings, string_format("%s Fake Freestand", User.PlayerStates[Index]), {"Off", "Peek Fake", "Peek Real"}, nil, function() return Menu.DataUI["Anti Aim"]["Main"]["Anti Aim"] == "Default Builder" and Menu.DataUI["Anti Aim"]["Custom Settings"]["Active State"] == User.PlayerStates[Index] and Menu.DataUI["Anti Aim"]["Custom Settings"][string_format("Enable : %s", User.PlayerStates[Index])] end)
            Menu.Components.ListBox(Anti_Aim_CustomSettings, string_format("%s OnShot", User.PlayerStates[Index]), {"Default", "Opposite", "Freestanding", "Switch"}, nil, function() return Menu.DataUI["Anti Aim"]["Main"]["Anti Aim"] == "Default Builder" and Menu.DataUI["Anti Aim"]["Custom Settings"]["Active State"] == User.PlayerStates[Index] and Menu.DataUI["Anti Aim"]["Custom Settings"][string_format("Enable : %s", User.PlayerStates[Index])] end)
            
            Menu.Components.Slider(Anti_Aim_CustomSettings, string_format("%s Yaw Add", User.PlayerStates[Index]), -180, 180, 0, function() return Menu.DataUI["Anti Aim"]["Main"]["Anti Aim"] == "Digital Builder" and Menu.DataUI["Anti Aim"]["Custom Settings"]["Active State"] == User.PlayerStates[Index] and Menu.DataUI["Anti Aim"]["Custom Settings"][string_format("Enable : %s", User.PlayerStates[Index])] end)
            Menu.Components.CheckBox(Anti_Aim_CustomSettings, string_format("%s Enable Jitter", User.PlayerStates[Index]), false, function() return Menu.DataUI["Anti Aim"]["Main"]["Anti Aim"] == "Digital Builder" and Menu.DataUI["Anti Aim"]["Custom Settings"]["Active State"] == User.PlayerStates[Index] and Menu.DataUI["Anti Aim"]["Custom Settings"][string_format("Enable : %s", User.PlayerStates[Index])] end)
            Menu.Components.Slider(Anti_Aim_CustomSettings, string_format("%s Jitter Factor", User.PlayerStates[Index]), -180, 180, 0, function() return Menu.DataUI["Anti Aim"]["Main"]["Anti Aim"] == "Digital Builder" and Menu.DataUI["Anti Aim"]["Custom Settings"]["Active State"] == User.PlayerStates[Index] and Menu.DataUI["Anti Aim"]["Custom Settings"][string_format("Enable : %s", User.PlayerStates[Index])] and Menu.DataUI["Anti Aim"]["Custom Settings"][string_format("%s Enable Jitter", User.PlayerStates[Index])] end)
            Menu.Components.Slider(Anti_Aim_CustomSettings, string_format("%s Desync", User.PlayerStates[Index]), 0, 100, 0, function() return Menu.DataUI["Anti Aim"]["Main"]["Anti Aim"] == "Digital Builder" and Menu.DataUI["Anti Aim"]["Custom Settings"]["Active State"] == User.PlayerStates[Index] and Menu.DataUI["Anti Aim"]["Custom Settings"][string_format("Enable : %s", User.PlayerStates[Index])] end)
            Menu.Components.CheckBox(Anti_Aim_CustomSettings, string_format("%s Sync Side With Jitter", User.PlayerStates[Index]), false, function() return Menu.DataUI["Anti Aim"]["Main"]["Anti Aim"] == "Digital Builder" and Menu.DataUI["Anti Aim"]["Custom Settings"]["Active State"] == User.PlayerStates[Index] and Menu.DataUI["Anti Aim"]["Custom Settings"][string_format("Enable : %s", User.PlayerStates[Index])] and Menu.DataUI["Anti Aim"]["Custom Settings"][string_format("%s Enable Jitter", User.PlayerStates[Index])] end)
            Menu.Components.CheckBox(Anti_Aim_CustomSettings, string_format("%s Freestand", User.PlayerStates[Index]), false, function() return Menu.DataUI["Anti Aim"]["Main"]["Anti Aim"] == "Digital Builder" and Menu.DataUI["Anti Aim"]["Custom Settings"]["Active State"] == User.PlayerStates[Index] and Menu.DataUI["Anti Aim"]["Custom Settings"][string_format("Enable : %s", User.PlayerStates[Index])] end)

        end

        local AntiBrutePointers = {
            Desync = Menu.Components.Slider(Anti_Aim_Anti_Brutforce, "AmoutOfDesync", 2, 12, 2, function() return false end),
            Jitter = Menu.Components.Slider(Anti_Aim_Anti_Brutforce, "AmoutOfJitter", 2, 12, 2, function() return false end),
        }

        Menu.Components.ListBox(Anti_Aim_Anti_Brutforce, "Anti Bruteforce Type", {"Default", "Change Jitter"}, nil, function() return Menu.DataUI["Anti Aim"]["Main"]["Anti Aim"] ~= "None" end)
        Menu.Components.CheckBox(Anti_Aim_Anti_Brutforce, "Enable Desync Phases", false, function() return Menu.DataUI["Anti Aim"]["Main"]["Anti Aim"] ~= "None" and Menu.DataUI["Anti Aim"]["Anti Bruteforce"]["Anti Bruteforce Type"] == "Default" end)
        Menu.Components.CheckBox(Anti_Aim_Anti_Brutforce, "Enable Jitter Phases", false, function() return Menu.DataUI["Anti Aim"]["Main"]["Anti Aim"] ~= "None" and Menu.DataUI["Anti Aim"]["Anti Bruteforce"]["Anti Bruteforce Type"] == "Change Jitter" end)

        Menu.Components.Button(Anti_Aim_Anti_Brutforce, "Add Phase", function()
            if Menu.DataUI["Anti Aim"]["Anti Bruteforce"]["Anti Bruteforce Type"] == "Default" then
                if Menu.DataUI["Anti Aim"]["Anti Bruteforce"]["AmoutOfDesync"] > 11 then
                    native_PlaySound("resource/warning.wav", 1, 100, 0, 0)
                    table_insert(Menu.MenuData.Logs, {"Cant Load More than 12", Files.image_LoadWarning, 0, globals.realtime})
                    return -- // error log here .
                end

                AntiBrutePointers.Desync.Point.UI[AntiBrutePointers.Desync.Index].Value = AntiBrutePointers.Desync.Point.UI[AntiBrutePointers.Desync.Index].Value + 1
            end

            if Menu.DataUI["Anti Aim"]["Anti Bruteforce"]["Anti Bruteforce Type"] == "Change Jitter" then
                if Menu.DataUI["Anti Aim"]["Anti Bruteforce"]["AmoutOfJitter"] > 11 then
                    native_PlaySound("resource/warning.wav", 1, 100, 0, 0)
                    table_insert(Menu.MenuData.Logs, {"Cant Load More than 12", Files.image_LoadWarning, 0, globals.realtime})
                    return -- // error log here .
                end

                AntiBrutePointers.Jitter.Point.UI[AntiBrutePointers.Jitter.Index].Value = AntiBrutePointers.Jitter.Point.UI[AntiBrutePointers.Jitter.Index].Value + 1
            end
        end, function() 
            return ((Menu.DataUI["Anti Aim"]["Anti Bruteforce"]["Anti Bruteforce Type"] == "Default" and Menu.DataUI["Anti Aim"]["Anti Bruteforce"]["Enable Desync Phases"]) or (Menu.DataUI["Anti Aim"]["Anti Bruteforce"]["Anti Bruteforce Type"] == "Change Jitter" and Menu.DataUI["Anti Aim"]["Anti Bruteforce"]["Enable Jitter Phases"])) and Menu.DataUI["Anti Aim"]["Main"]["Anti Aim"] ~= "None" 
        end, Files.image_LoadAdd)


        Menu.Components.Button(Anti_Aim_Anti_Brutforce, "Remove Phase", function()
            if Menu.DataUI["Anti Aim"]["Anti Bruteforce"]["Anti Bruteforce Type"] == "Default" then
                if Menu.DataUI["Anti Aim"]["Anti Bruteforce"]["AmoutOfDesync"] <= 2 then
                    native_PlaySound("resource/warning.wav", 1, 100, 0, 0)
                    table_insert(Menu.MenuData.Logs, {"Cant Load Less than 2", Files.image_LoadWarning, 0, globals.realtime})
                    return -- // error log here .
                end

                AntiBrutePointers.Desync.Point.UI[AntiBrutePointers.Desync.Index].Value = AntiBrutePointers.Desync.Point.UI[AntiBrutePointers.Desync.Index].Value - 1
            end

            if Menu.DataUI["Anti Aim"]["Anti Bruteforce"]["Anti Bruteforce Type"] == "Change Jitter" then
                if Menu.DataUI["Anti Aim"]["Anti Bruteforce"]["AmoutOfJitter"] <= 2 then
                    native_PlaySound("resource/warning.wav", 1, 100, 0, 0)
                    table_insert(Menu.MenuData.Logs, {"Cant Load Less than 2", Files.image_LoadWarning, 0, globals.realtime})
                    return -- // error log here .
                end

                AntiBrutePointers.Jitter.Point.UI[AntiBrutePointers.Jitter.Index].Value = AntiBrutePointers.Jitter.Point.UI[AntiBrutePointers.Jitter.Index].Value - 1
            end
        end, function() 
            return ((Menu.DataUI["Anti Aim"]["Anti Bruteforce"]["Anti Bruteforce Type"] == "Default" and Menu.DataUI["Anti Aim"]["Anti Bruteforce"]["Enable Desync Phases"]) or (Menu.DataUI["Anti Aim"]["Anti Bruteforce"]["Anti Bruteforce Type"] == "Change Jitter" and Menu.DataUI["Anti Aim"]["Anti Bruteforce"]["Enable Jitter Phases"])) and Menu.DataUI["Anti Aim"]["Main"]["Anti Aim"] ~= "None" 
        end, Files.image_LoadRemove)

        for Index = 1, 12 do
            Menu.Components.Slider(Anti_Aim_Anti_Brutforce, string_format("Phase %d Limit", Index), -60, 60, 0, function() return Menu.DataUI["Anti Aim"]["Anti Bruteforce"]["Anti Bruteforce Type"] == "Default" and Menu.DataUI["Anti Aim"]["Anti Bruteforce"]["Enable Desync Phases"] and Index <= Menu.DataUI["Anti Aim"]["Anti Bruteforce"]["AmoutOfDesync"] and Menu.DataUI["Anti Aim"]["Main"]["Anti Aim"] ~= "None" end)

            Menu.Components.Slider(Anti_Aim_Anti_Brutforce, string_format("Phase %d Degree", Index), -180, 180, 0, function() return Menu.DataUI["Anti Aim"]["Anti Bruteforce"]["Anti Bruteforce Type"] == "Change Jitter" and Menu.DataUI["Anti Aim"]["Anti Bruteforce"]["Enable Jitter Phases"] and Index <= Menu.DataUI["Anti Aim"]["Anti Bruteforce"]["AmoutOfJitter"] and Menu.DataUI["Anti Aim"]["Main"]["Anti Aim"] ~= "None" end)
        end

        Menu.Components.MultiListBox(Visuals_UI, "UI Elements", {"Watermark", "Keybinds", "Weapon Panel", "HUD", "Velocity Warning"})
        Menu.Components.MultiListBox(Visuals_UI, "Watermark Options", {"Name", "Build", "Ping", "Time"}, false, function() return Menu.DataUI["Visuals"]["UI"]["UI Elements"][1] end)
        Menu.Components.MultiListBox(Visuals_UI, "HUD Disabled Options", {"HP and Armor", "Weapons", "KillFeed", "Map Data"}, false, function() return Menu.DataUI["Visuals"]["UI"]["UI Elements"][4] end)
        Menu.Components.MultiListBox(Visuals_Visuals, "Visuals Options", {"Scope Changer", "Splash Impact", "World Damage", "Hit Marker", "View Model", "Aspect Ratio", "Console Changer", "Legs Anim"})
        Menu.Components.ListBox(Visuals_Visuals, "Scope Mode", {"Gradient", "Gradient Invert", "Line"}, nil, function() return Menu.DataUI["Visuals"]["Visuals"]["Visuals Options"][1] end)
        Menu.Components.Slider(Visuals_Visuals, "Scope Origin", 0, 150, 10, function() return Menu.DataUI["Visuals"]["Visuals"]["Visuals Options"][1] end)
        Menu.Components.Slider(Visuals_Visuals, "Scope Width", 0, 350, 10, function() return Menu.DataUI["Visuals"]["Visuals"]["Visuals Options"][1] end)
        Menu.Components.CheckBox(Visuals_Visuals, "Spread Offset", false, function() return Menu.DataUI["Visuals"]["Visuals"]["Visuals Options"][1] end)
        Menu.Components.CheckBox(Visuals_Visuals, "Only Local Impacts", true, function() return Menu.DataUI["Visuals"]["Visuals"]["Visuals Options"][2] end)
        Menu.Components.ListBox(Visuals_Visuals, "Hit Marker Type", {"Line +", "Gradient +", "Invert Gradient +", "Line x"}, nil, function() return Menu.DataUI["Visuals"]["Visuals"]["Visuals Options"][4] end)
        Menu.Components.Slider(Visuals_Visuals, "Offset X", -40, 40, 0, function() return Menu.DataUI["Visuals"]["Visuals"]["Visuals Options"][5] end)
        Menu.Components.Slider(Visuals_Visuals, "Offset Y", -40, 40, 0, function() return Menu.DataUI["Visuals"]["Visuals"]["Visuals Options"][5] end)
        Menu.Components.Slider(Visuals_Visuals, "Offset Z", -40, 40, 0, function() return Menu.DataUI["Visuals"]["Visuals"]["Visuals Options"][5] end)
        Menu.Components.Slider(Visuals_Visuals, "Offset Fov", 0, 170, 60, function() return Menu.DataUI["Visuals"]["Visuals"]["Visuals Options"][5] end)
        Menu.Components.Slider(Visuals_Visuals, "Aspect Ratio", 50, 200, 100, function() return Menu.DataUI["Visuals"]["Visuals"]["Visuals Options"][6] end)
        Menu.Components.MultiListBox(Visuals_Visuals, "Legs Options", {"Static In Air", "Static In Move"}, false, function() return Menu.DataUI["Visuals"]["Visuals"]["Visuals Options"][8] end)
        Menu.Components.Slider(Visuals_Visuals, "Move Legs Jitter", 5, 10, 6, function() return Menu.DataUI["Visuals"]["Visuals"]["Visuals Options"][8] and Menu.DataUI["Visuals"]["Visuals"]["Legs Options"][2] end)
        Menu.Components.MultiListBox(Visuals_Indicators, "Select Indicators", {"Center Screen", "Speclist", "Grenade Radius"})
        Menu.Components.CheckBox(Visuals_Indicators, "Invert Name Colors", false, function() return Menu.DataUI["Visuals"]["Indicators"]["Select Indicators"][1] end)
        Menu.Components.CheckBox(Visuals_Indicators, "Outline Radius", false, function() return Menu.DataUI["Visuals"]["Indicators"]["Select Indicators"][3] end)
        -- colors 
        Menu.Components.ListBox(Visuals_Colors, "Color Edit", {"UI", "Visuals", "Indicators"})
        Menu.Components.ColorEdit(Visuals_Colors, "UI Box Top Left", color(56, 51, 57, 255), nil, function() return Menu.DataUI["Visuals"]["Colors"]["Color Edit"] == "UI" end)
        Menu.Components.ColorEdit(Visuals_Colors, "UI Box Top Right", color(1, 1, 0, 50), nil, function() return Menu.DataUI["Visuals"]["Colors"]["Color Edit"] == "UI" end)
        Menu.Components.ColorEdit(Visuals_Colors, "UI Box Bottom Left", color(1, 1, 0, 255), nil, function() return Menu.DataUI["Visuals"]["Colors"]["Color Edit"] == "UI" end)
        Menu.Components.ColorEdit(Visuals_Colors, "UI Box Bottom Right", color(56, 51, 57, 50), nil, function() return Menu.DataUI["Visuals"]["Colors"]["Color Edit"] == "UI" end)
        Menu.Components.ColorEdit(Visuals_Colors, "Scope Color", color(150, 150, 255, 255), nil, function() return Menu.DataUI["Visuals"]["Colors"]["Color Edit"] == "Visuals" and Menu.DataUI["Visuals"]["Visuals"]["Visuals Options"][1] end)
        Menu.Components.ColorEdit(Visuals_Colors, "Sparks Color", color(150, 150, 255, 255), nil, function() return Menu.DataUI["Visuals"]["Colors"]["Color Edit"] == "Visuals" and Menu.DataUI["Visuals"]["Visuals"]["Visuals Options"][2] end)
        Menu.Components.ColorEdit(Visuals_Colors, "Head Color", color(255, 10, 10, 255), nil, function() return Menu.DataUI["Visuals"]["Colors"]["Color Edit"] == "Visuals" and Menu.DataUI["Visuals"]["Visuals"]["Visuals Options"][3] end)
        Menu.Components.ColorEdit(Visuals_Colors, "Other Color", color(255, 255), nil, function() return Menu.DataUI["Visuals"]["Colors"]["Color Edit"] == "Visuals" and Menu.DataUI["Visuals"]["Visuals"]["Visuals Options"][3] end)
        Menu.Components.ColorEdit(Visuals_Colors, "Marker Color", color(255, 255), nil, function() return Menu.DataUI["Visuals"]["Colors"]["Color Edit"] == "Visuals" and Menu.DataUI["Visuals"]["Visuals"]["Visuals Options"][4] end)
        Menu.Components.ColorEdit(Visuals_Colors, "Console Color", color(255, 255), nil, function() return Menu.DataUI["Visuals"]["Colors"]["Color Edit"] == "Visuals" and Menu.DataUI["Visuals"]["Visuals"]["Visuals Options"][7] end)
        Menu.Components.ColorEdit(Visuals_Colors, "Indicator Background Color", color(0, 255), nil, function() return Menu.DataUI["Visuals"]["Colors"]["Color Edit"] == "Indicators" and Menu.DataUI["Visuals"]["Indicators"]["Select Indicators"][1] end)
        Menu.Components.ColorEdit(Visuals_Colors, "Indicator Fade Color", color(226, 221, 227, 255), nil, function() return Menu.DataUI["Visuals"]["Colors"]["Color Edit"] == "Indicators" and Menu.DataUI["Visuals"]["Indicators"]["Select Indicators"][1] end)
        Menu.Components.ColorEdit(Visuals_Colors, "Molotov Color", color(200, 50, 50, 255), nil, function() return Menu.DataUI["Visuals"]["Colors"]["Color Edit"] == "Indicators" and Menu.DataUI["Visuals"]["Indicators"]["Select Indicators"][3] end)
        Menu.Components.ColorEdit(Visuals_Colors, "Smoke Color", color(50, 50, 200, 255), nil, function() return Menu.DataUI["Visuals"]["Colors"]["Color Edit"] == "Indicators" and Menu.DataUI["Visuals"]["Indicators"]["Select Indicators"][3] end)
        
        Menu.Components.CheckBox(Misc_Misc, "ClanTag", false)
        Menu.Components.CheckBox(Misc_Misc, "Trash Talk", false)
        Menu.Components.MultiListBox(Misc_Misc, "Logs Options", {"Console Logs", "Visual Logs"}, false)
        Menu.Components.MultiListBox(Misc_Misc, "Logs Types", {"Hit", "Miss", "Hurt", "Purchases"}, false, function() return Menu.DataUI["Misc"]["Misc"]["Logs Options"][1] or Menu.DataUI["Misc"]["Misc"]["Logs Options"][2] end)
        Menu.Neverlose.LogsIcon = Menu.Components.CheckBox(Misc_Misc, "Disable Icon", false, function() return false end)
        Menu.Components.CheckBox(Misc_Misc, "Manage Logs Colors", false, function() return Menu.DataUI["Misc"]["Misc"]["Logs Options"][1] or Menu.DataUI["Misc"]["Misc"]["Logs Options"][2] end)
        Menu.Components.ColorEdit(Misc_Misc, "Background Logs", color(37, 33, 34, 255), nil, function() return (Menu.DataUI["Misc"]["Misc"]["Logs Options"][1] or Menu.DataUI["Misc"]["Misc"]["Logs Options"][2]) and Menu.DataUI["Misc"]["Misc"]["Manage Logs Colors"] end)
        Menu.Components.ColorEdit(Misc_Misc, "Outline Logs", color(67, 63, 64, 255), nil, function() return (Menu.DataUI["Misc"]["Misc"]["Logs Options"][1] or Menu.DataUI["Misc"]["Misc"]["Logs Options"][2]) and Menu.DataUI["Misc"]["Misc"]["Manage Logs Colors"] end)
        Menu.Components.ColorEdit(Misc_Misc, "Icon Background Logs", color(36, 36, 36, 255), nil, function() return (Menu.DataUI["Misc"]["Misc"]["Logs Options"][1] or Menu.DataUI["Misc"]["Misc"]["Logs Options"][2]) and Menu.DataUI["Misc"]["Misc"]["Manage Logs Colors"] end)
        Menu.Components.ColorEdit(Misc_Misc, "Hit Color", color(255, 255), nil, function() return (Menu.DataUI["Misc"]["Misc"]["Logs Options"][1] or Menu.DataUI["Misc"]["Misc"]["Logs Options"][2]) and Menu.DataUI["Misc"]["Misc"]["Manage Logs Colors"] and Menu.DataUI["Misc"]["Misc"]["Logs Types"][1] end)
        Menu.Components.ColorEdit(Misc_Misc, "Correction Color", color(255, 255), nil, function() return (Menu.DataUI["Misc"]["Misc"]["Logs Options"][1] or Menu.DataUI["Misc"]["Misc"]["Logs Options"][2]) and Menu.DataUI["Misc"]["Misc"]["Manage Logs Colors"] and Menu.DataUI["Misc"]["Misc"]["Logs Types"][2] end)
        Menu.Components.ColorEdit(Misc_Misc, "Spread Color", color(255, 255), nil, function() return (Menu.DataUI["Misc"]["Misc"]["Logs Options"][1] or Menu.DataUI["Misc"]["Misc"]["Logs Options"][2]) and Menu.DataUI["Misc"]["Misc"]["Manage Logs Colors"] and Menu.DataUI["Misc"]["Misc"]["Logs Types"][2] end)
        Menu.Components.ColorEdit(Misc_Misc, "Misprediction Color", color(255, 255), nil, function() return (Menu.DataUI["Misc"]["Misc"]["Logs Options"][1] or Menu.DataUI["Misc"]["Misc"]["Logs Options"][2]) and Menu.DataUI["Misc"]["Misc"]["Manage Logs Colors"] and Menu.DataUI["Misc"]["Misc"]["Logs Types"][2] end)
        Menu.Components.ColorEdit(Misc_Misc, "Prediction error Color", color(255, 255), nil, function() return (Menu.DataUI["Misc"]["Misc"]["Logs Options"][1] or Menu.DataUI["Misc"]["Misc"]["Logs Options"][2]) and Menu.DataUI["Misc"]["Misc"]["Manage Logs Colors"] and Menu.DataUI["Misc"]["Misc"]["Logs Types"][2] end)
        Menu.Components.ColorEdit(Misc_Misc, "Lagcomp failure Color", color(255, 255), nil, function() return (Menu.DataUI["Misc"]["Misc"]["Logs Options"][1] or Menu.DataUI["Misc"]["Misc"]["Logs Options"][2]) and Menu.DataUI["Misc"]["Misc"]["Manage Logs Colors"] and Menu.DataUI["Misc"]["Misc"]["Logs Types"][2] end)
        Menu.Components.ColorEdit(Misc_Misc, "Unregistered shot Color", color(255, 255), nil, function() return (Menu.DataUI["Misc"]["Misc"]["Logs Options"][1] or Menu.DataUI["Misc"]["Misc"]["Logs Options"][2]) and Menu.DataUI["Misc"]["Misc"]["Manage Logs Colors"] and Menu.DataUI["Misc"]["Misc"]["Logs Types"][2] end)
        Menu.Components.ColorEdit(Misc_Misc, "Other Color", color(255, 255), nil, function() return (Menu.DataUI["Misc"]["Misc"]["Logs Options"][1] or Menu.DataUI["Misc"]["Misc"]["Logs Options"][2]) and Menu.DataUI["Misc"]["Misc"]["Manage Logs Colors"] and Menu.DataUI["Misc"]["Misc"]["Logs Types"][2] end)
        Menu.Components.ColorEdit(Misc_Misc, "Hurt Color", color(255, 255), nil, function() return (Menu.DataUI["Misc"]["Misc"]["Logs Options"][1] or Menu.DataUI["Misc"]["Misc"]["Logs Options"][2]) and Menu.DataUI["Misc"]["Misc"]["Manage Logs Colors"] and Menu.DataUI["Misc"]["Misc"]["Logs Types"][3] end)
        Menu.Components.ColorEdit(Misc_Misc, "Purchase Color", color(255, 255), nil, function() return (Menu.DataUI["Misc"]["Misc"]["Logs Options"][1] or Menu.DataUI["Misc"]["Misc"]["Logs Options"][2]) and Menu.DataUI["Misc"]["Misc"]["Manage Logs Colors"] and Menu.DataUI["Misc"]["Misc"]["Logs Types"][4] end)
        Menu.Components.ListBox(Misc_Misc, "Local Hurt Sound", {"None", "Switch", "Warning", "Wood Stop", "Wood Strain", "Wood Plank"})
        Menu.Components.Slider(Misc_Misc, "Volume", 1, 100, 80, function() return Menu.DataUI["Misc"]["Misc"]["Local Hurt Sound"] ~= "None" end)
        Menu.Components.MultiListBox(Misc_Misc, "Remove", {"Chat", "Radar", "Ragdoll Physics"})

        --cfg system Misc_CFG
        Menu.Components.ListBox(Misc_CFG, "Select CFG", {"Default", "slot1", "slot2", "slot3", "slot4", "slot5", "slot6"}) -- // slot 6 will be by default loaded as default cfg and updated
        Menu.Components.MultiListBox(Misc_CFG, "Select Tabs To Use", {"RageBot", "Anti Aim", "Visuals", "Misc"})
        Menu.Components.CheckBox(Misc_CFG, "Auto Save")

        Menu.Components.Button(Misc_CFG, "Save Slot CFG", function() 
            local EncEnd = enc(Menu.Components.GetCFG())
            files.write(string_format("csgo\\DigitalData\\DigitalCfgs\\%s.txt", Menu.DataUI["Misc"]["CFG"]["Select CFG"]), EncEnd)
            table_insert(Menu.MenuData.Logs, {"Saved Slot CFG", Files.image_LoadSaveCFGIcon, 0, globals.realtime})
            native_PlaySound("resource/warning.wav", 1, 100, 0, 0)
        end, function()
            return Helpers.Contains(Menu.DataUI["Misc"]["CFG"]["Select Tabs To Use"], true) and Menu.DataUI["Misc"]["CFG"]["Select CFG"] ~= "Default"
        end, Files.image_LoadSaveCFG)

        Menu.Components.Button(Misc_CFG, "Load Slot CFG", function() 
            local FileData = Menu.DataUI["Misc"]["CFG"]["Select CFG"] == "Default" and User.CloadCFG or files.read(string_format("csgo\\DigitalData\\DigitalCfgs\\%s.txt", Menu.DataUI["Misc"]["CFG"]["Select CFG"]))
            if FileData == "?" then
                print("Error in Reading File")
            else
                Menu.Components.SetCFG(FileData)
            end
            table_insert(Menu.MenuData.Logs, {"Loaded Slot CFG", Files.image_LoadLoadCFGIcon, 0, globals.realtime})
            native_PlaySound("resource/warning.wav", 1, 100, 0, 0)
        end, function()
            return Helpers.Contains(Menu.DataUI["Misc"]["CFG"]["Select Tabs To Use"], true)
        end, Files.image_LoadLoadCFG)

        Menu.Components.Button(Misc_CFG, "Get CFG Code", function() 
            local EncEnd = enc(Menu.Components.GetCFG())
            Clipboard.Export(EncEnd)
            table_insert(Menu.MenuData.Logs, {"Copied CFG Code", Files.image_LoadShareCFGIcon, 0, globals.realtime})
            native_PlaySound("resource/warning.wav", 1, 100, 0, 0)
        end, function()
            return Helpers.Contains(Menu.DataUI["Misc"]["CFG"]["Select Tabs To Use"], true) and Menu.DataUI["Misc"]["CFG"]["Select CFG"] ~= "Default"
        end, Files.image_LoadShareCFG)

        Menu.Components.Button(Misc_CFG, "Load CFG Code", function() 
            local CodeData = Clipboard.Import()
            Menu.Components.SetCFG(CodeData)
            table_insert(Menu.MenuData.Logs, {"Loaded CFG Code", Files.image_LoadLoadCFGIcon, 0, globals.realtime})
            native_PlaySound("resource/warning.wav", 1, 100, 0, 0)
        end, function()
            return Helpers.Contains(Menu.DataUI["Misc"]["CFG"]["Select Tabs To Use"], true)
        end, Files.image_LoadLoadCFG)


        Menu.Components.Button(Misc_Local, "Video Guide", function() User.SteamOverlayAPI.OpenExternalBrowserURL("https://www.youtube.com/watch?v=c-uhHm6fRAw") end, nil, Files.image_LoadLinkButton)
        Menu.Components.Button(Misc_Local, "Join Discord", function() User.SteamOverlayAPI.OpenExternalBrowserURL("https://discord.gg/SD6xeBA4MR") end, nil, Files.image_LoadLinkButton)
        Menu.Components.Button(Misc_Local, "Digital Dreams Nightmare", function() User.SteamOverlayAPI.OpenExternalBrowserURL("https://en.neverlose.cc/market/item?id=PqSomv") end, nil, Files.image_LoadLinkButton)

        Menu.Components.ListBox(Misc_Menu, "Menu Theme", {"One Color", "Custom"})
        Menu.Components.ColorEdit(Misc_Menu, "Menu Color", color(120, 120, 255, 255), nil, function() return Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "One Color" end)
        Menu.Components.ListBox(Misc_Menu, "Custom Option", {"Background", "Icon", "Tabs", "SubTabs", "UI", "UI-CheckBoxes", "UI-Sliders", "UI-ListBoxes", "UI-ColorPickers", "UI-Keybinds", "UI-Buttons", "Event Log System"}, nil, function() return Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" end)
        Menu.Components.ColorEdit(Misc_Menu, "BackGround Top Left", color(56, 51, 57, 255), nil, function() return Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Custom Option"] == "Background" end)
        Menu.Components.ColorEdit(Misc_Menu, "BackGround Top Right", color(1, 1, 0, 255), nil, function() return Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Custom Option"] == "Background" end)
        Menu.Components.ColorEdit(Misc_Menu, "BackGround Bottom Left", color(1, 1, 0, 255), nil, function() return Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Custom Option"] == "Background" end)
        Menu.Components.ColorEdit(Misc_Menu, "BackGround Move Inactive", color(56, 51, 57, 255), nil, function() return Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Custom Option"] == "Background" end)
        Menu.Components.ColorEdit(Misc_Menu, "BackGround Move Active", color(56, 1, 1, 255), nil, function() return Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Custom Option"] == "Background" end)
        Menu.Components.ColorEdit(Misc_Menu, "BackGround OutLine", color(67, 63, 64, 255), nil, function() return Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Custom Option"] == "Background" end)
        Menu.Components.ColorEdit(Misc_Menu, "Icon Top Left", color(1, 1, 0, 255), nil, function() return Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Custom Option"] == "Icon" end)
        Menu.Components.ColorEdit(Misc_Menu, "Icon Top Right", color(100, 255), nil, function() return Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Custom Option"] == "Icon" end)
        Menu.Components.ColorEdit(Misc_Menu, "Icon Bottom Left", color(100, 255), nil, function() return Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Custom Option"] == "Icon" end)
        Menu.Components.ColorEdit(Misc_Menu, "Icon Bottom Right", color(1, 1, 0, 255), nil, function() return Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Custom Option"] == "Icon" end)
        Menu.Components.ColorEdit(Misc_Menu, "Icon Background", color(37, 33, 34, 255 * 0.4), nil, function() return Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Custom Option"] == "Icon" end)
        Menu.Components.ColorEdit(Misc_Menu, "Icon OutLine", color(67, 63, 64, 255 * 0.5), nil, function() return Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Custom Option"] == "Icon" end)
        Menu.Components.ColorEdit(Misc_Menu, "Digital Text", color(255, 255), nil, function() return Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Custom Option"] == "Icon" end)
        Menu.Components.ColorEdit(Misc_Menu, "Dreams Text", color(255, 255), nil, function() return Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Custom Option"] == "Icon" end)
        Menu.Components.ColorEdit(Misc_Menu, "BackGround Tabs", color(37, 33, 34, 255 * 0.4), nil, function() return Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Custom Option"] == "Tabs" end)
        Menu.Components.ColorEdit(Misc_Menu, "Tabs OutLine", color(67, 63, 64, 255 * 0.5), nil, function() return Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Custom Option"] == "Tabs" end)
        Menu.Components.ColorEdit(Misc_Menu, "Tabs Select Top Left", color(1, 1, 0, 255), nil, function() return Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Custom Option"] == "Tabs" end)
        Menu.Components.ColorEdit(Misc_Menu, "Tabs Select Top Right",color(100, 255), nil, function() return Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Custom Option"] == "Tabs" end)
        Menu.Components.ColorEdit(Misc_Menu, "Tabs Select Bottom Left", color(100, 255), nil, function() return Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Custom Option"] == "Tabs" end)
        Menu.Components.ColorEdit(Misc_Menu, "Tabs Select Bottom Right", color(1, 1, 0, 255), nil, function() return Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Custom Option"] == "Tabs" end)
        Menu.Components.ColorEdit(Misc_Menu, "Tabs Icon", color(255, 255), nil, function() return Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Custom Option"] == "Tabs" end)
        Menu.Components.ColorEdit(Misc_Menu, "BackGround SubTabs", color(37, 33, 34, 255 * 0.4), nil, function() return Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Custom Option"] == "SubTabs" end)
        Menu.Components.ColorEdit(Misc_Menu, "SubTabs OutLine", color(67, 63, 64, 255 * 0.5), nil, function() return Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Custom Option"] == "SubTabs" end)
        Menu.Components.ColorEdit(Misc_Menu, "SubTabs Select Top Left", color(1, 1, 0, 255), nil, function() return Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Custom Option"] == "SubTabs" end)
        Menu.Components.ColorEdit(Misc_Menu, "SubTabs Select Top Right", color(100, 255), nil, function() return Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Custom Option"] == "SubTabs" end)
        Menu.Components.ColorEdit(Misc_Menu, "SubTabs Select Bottom Left", color(100, 255), nil, function() return Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Custom Option"] == "SubTabs" end)
        Menu.Components.ColorEdit(Misc_Menu, "SubTabs Select Bottom Right", color(1, 1, 0, 255), nil, function() return Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Custom Option"] == "SubTabs" end)
        Menu.Components.ColorEdit(Misc_Menu, "SubTabs Icon", color(255, 255), nil, function() return Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Custom Option"] == "SubTabs" end)
        Menu.Components.ColorEdit(Misc_Menu, "SubTabs Text", color(255, 255), nil, function() return Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Custom Option"] == "SubTabs" end)
        Menu.Components.ColorEdit(Misc_Menu, "BackGround UI", color(37, 33, 34, 255 * 0.4), nil, function() return Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Custom Option"] == "UI" end)
        Menu.Components.ColorEdit(Misc_Menu, "UI OutLine", color(67, 63, 64, 255 * 0.5), nil, function() return Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Custom Option"] == "UI" end)
        Menu.Components.ColorEdit(Misc_Menu, "CheckBox Text", color(255, 255), nil, function() return Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Custom Option"] == "UI-CheckBoxes" end)
        Menu.Components.ColorEdit(Misc_Menu, "CheckBox Background Inactive", color(67, 63, 64, 100), nil, function() return Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Custom Option"] == "UI-CheckBoxes" end)
        Menu.Components.ColorEdit(Misc_Menu, "CheckBox Background Active", color(255, 100), nil, function() return Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Custom Option"] == "UI-CheckBoxes" end)
        Menu.Components.ColorEdit(Misc_Menu, "CheckBox Inactive", color(67, 63, 64, 255), nil, function() return Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Custom Option"] == "UI-CheckBoxes" end)
        Menu.Components.ColorEdit(Misc_Menu, "CheckBox Active", color(255, 255), nil, function() return Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Custom Option"] == "UI-CheckBoxes" end)
        Menu.Components.ColorEdit(Misc_Menu, "Slider Text", color(255, 255), nil, function() return Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Custom Option"] == "UI-Sliders" end)
        Menu.Components.ColorEdit(Misc_Menu, "Slider Vale Text", color(255, 255), nil, function() return Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Custom Option"] == "UI-Sliders" end)
        Menu.Components.ColorEdit(Misc_Menu, "Slider Background Value", color(67, 63, 64, 255), nil, function() return Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Custom Option"] == "UI-Sliders" end)
        Menu.Components.ColorEdit(Misc_Menu, "Slider Value", color(255, 255), nil, function() return Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Custom Option"] == "UI-Sliders" end)
        Menu.Components.ColorEdit(Misc_Menu, "ListBox Background", color(37, 33, 34, 255), nil, function() return Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Custom Option"] == "UI-ListBoxes" end)
        Menu.Components.ColorEdit(Misc_Menu, "ListBox Outline", color(67, 63, 64, 255), nil, function() return Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Custom Option"] == "UI-ListBoxes" end)
        Menu.Components.ColorEdit(Misc_Menu, "ListBox Open Background", color(37, 33, 34, 255), nil, function() return Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Custom Option"] == "UI-ListBoxes" end)
        Menu.Components.ColorEdit(Misc_Menu, "ListBox Open Outline", color(67, 63, 64, 255), nil, function() return Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Custom Option"] == "UI-ListBoxes" end)
        Menu.Components.ColorEdit(Misc_Menu, "ListBox Top Left", color(255, 255), nil, function() return Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Custom Option"] == "UI-ListBoxes" end)
        Menu.Components.ColorEdit(Misc_Menu, "ListBox Top Right", color(1, 1, 0, 255), nil, function() return Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Custom Option"] == "UI-ListBoxes" end)
        Menu.Components.ColorEdit(Misc_Menu, "ListBox Bottom Left", color(1, 1, 0, 255), nil, function() return Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Custom Option"] == "UI-ListBoxes" end)
        Menu.Components.ColorEdit(Misc_Menu, "ListBox Bottom Right", color(255, 255), nil, function() return Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Custom Option"] == "UI-ListBoxes" end)
        Menu.Components.ColorEdit(Misc_Menu, "ListBox Icon", color(255, 255), nil, function() return Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Custom Option"] == "UI-ListBoxes" end)
        Menu.Components.ColorEdit(Misc_Menu, "ListBox Text", color(255, 255), nil, function() return Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Custom Option"] == "UI-ListBoxes" end)
        Menu.Components.ColorEdit(Misc_Menu, "ListBox Value", color(255, 255), nil, function() return Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Custom Option"] == "UI-ListBoxes" end)
        Menu.Components.ColorEdit(Misc_Menu, "ListBox Values", color(255, 255), nil, function() return Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Custom Option"] == "UI-ListBoxes" end)
        Menu.Components.ColorEdit(Misc_Menu, "ListBox Selected Values", color(255, 255), nil, function() return Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Custom Option"] == "UI-ListBoxes" end)
        Menu.Components.ColorEdit(Misc_Menu, "ColorPicker Background", color(37, 33, 34, 255), nil, function() return Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Custom Option"] == "UI-ColorPickers" end)
        Menu.Components.ColorEdit(Misc_Menu, "ColorPicker Open Background", color(37, 33, 34, 255), nil, function() return Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Custom Option"] == "UI-ColorPickers" end)
        Menu.Components.ColorEdit(Misc_Menu, "ColorPicker Top Left", color(100, 100, 100, 255), nil, function() return Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Custom Option"] == "UI-ColorPickers" end)
        Menu.Components.ColorEdit(Misc_Menu, "ColorPicker Top Right", color(1, 1, 0, 255), nil, function() return Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Custom Option"] == "UI-ColorPickers" end)
        Menu.Components.ColorEdit(Misc_Menu, "ColorPicker Bottom Left", color(1, 1, 0, 255), nil, function() return Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Custom Option"] == "UI-ColorPickers" end)
        Menu.Components.ColorEdit(Misc_Menu, "ColorPicker Bottom Right", color(100, 100, 100, 255), nil, function() return Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Custom Option"] == "UI-ColorPickers" end)
        Menu.Components.ColorEdit(Misc_Menu, "ColorPicker Icon", color(255, 255), nil, function() return Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Custom Option"] == "UI-ColorPickers" end)
        Menu.Components.ColorEdit(Misc_Menu, "ColorPicker Text", color(255, 255), nil, function() return Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Custom Option"] == "UI-ColorPickers" end)
        Menu.Components.ColorEdit(Misc_Menu, "ColorPicker Buttons", color(255, 255), nil, function() return Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Custom Option"] == "UI-ColorPickers" end)
        Menu.Components.ColorEdit(Misc_Menu, "Keybind Background", color(37, 33, 34, 255), nil, function() return Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Custom Option"] == "UI-Keybinds" end)
        --Menu.Components.ColorEdit(Misc_Menu, "Keybind Open Background", color(1, 1, 0, 255), nil, function() return Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Custom Option"] == "UI-Keybinds" end)
        Menu.Components.ColorEdit(Misc_Menu, "Keybind Top Left", color(100, 100, 100, 255), nil, function() return Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Custom Option"] == "UI-Keybinds" end)
        Menu.Components.ColorEdit(Misc_Menu, "Keybind Top Right", color(1, 1, 0, 255), nil, function() return Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Custom Option"] == "UI-Keybinds" end)
        Menu.Components.ColorEdit(Misc_Menu, "Keybind Bottom Left", color(1, 1, 0, 255), nil, function() return Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Custom Option"] == "UI-Keybinds" end)
        Menu.Components.ColorEdit(Misc_Menu, "Keybind Bottom Right", color(100, 100, 100, 255), nil, function() return Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Custom Option"] == "UI-Keybinds" end)
        Menu.Components.ColorEdit(Misc_Menu, "Keybind Icon", color(255, 255), nil, function() return Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Custom Option"] == "UI-Keybinds" end)
        Menu.Components.ColorEdit(Misc_Menu, "Keybind Text", color(255, 255), nil, function() return Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Custom Option"] == "UI-Keybinds" end)
        Menu.Components.ColorEdit(Misc_Menu, "Keybind Key", color(255, 255), nil, function() return Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Custom Option"] == "UI-Keybinds" end)
        Menu.Components.ColorEdit(Misc_Menu, "Keybind Binding", color(255, 255), nil, function() return Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Custom Option"] == "UI-Keybinds" end)
        Menu.Components.ColorEdit(Misc_Menu, "Keybind Mode Inactive", color(255, 255), nil, function() return Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Custom Option"] == "UI-Keybinds" end)
        Menu.Components.ColorEdit(Misc_Menu, "Keybind Mode Active", color(255, 255), nil, function() return Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Custom Option"] == "UI-Keybinds" end)
        Menu.Components.ColorEdit(Misc_Menu, "Button Background", color(37, 33, 34, 255), nil, function() return Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Custom Option"] == "UI-Buttons" end)
        Menu.Components.ColorEdit(Misc_Menu, "Button Top Left", color(100, 100, 100, 255), nil, function() return Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Custom Option"] == "UI-Buttons" end)
        Menu.Components.ColorEdit(Misc_Menu, "Button Top Right", color(1, 1, 0, 255), nil, function() return Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Custom Option"] == "UI-Buttons" end)
        Menu.Components.ColorEdit(Misc_Menu, "Button Bottom Left", color(1, 1, 0, 255), nil, function() return Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Custom Option"] == "UI-Buttons" end)
        Menu.Components.ColorEdit(Misc_Menu, "Button Bottom Right", color(100, 100, 100, 255), nil, function() return Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Custom Option"] == "UI-Buttons" end)
        Menu.Components.ColorEdit(Misc_Menu, "Button Icon", color(255, 255), nil, function() return Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Custom Option"] == "UI-Buttons" end)
        Menu.Components.ColorEdit(Misc_Menu, "Button Text", color(255, 255), nil, function() return Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Custom Option"] == "UI-Buttons" end)
        Menu.Components.ColorEdit(Misc_Menu, "Event Background", color(37, 33, 34, 255), nil, function() return Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Custom Option"] == "Event Log System" end)
        Menu.Components.ColorEdit(Misc_Menu, "Event Outline", color(67, 63, 64, 255), nil, function() return Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Custom Option"] == "Event Log System" end)
        Menu.Components.ColorEdit(Misc_Menu, "Event Icon Background", color(37, 33, 34, 0), nil, function() return Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Custom Option"] == "Event Log System" end)
        Menu.Components.ColorEdit(Misc_Menu, "Event Icon", color(255, 255), nil, function() return Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Custom Option"] == "Event Log System" end)
        Menu.Components.ColorEdit(Misc_Menu, "Event Text", color(255, 255), nil, function() return Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Custom Option"] == "Event Log System" end)

    end 
    
    --@components types draw 
    Menu.RenderComponents = {}
    Menu.RenderComponents.InteractData = {
        Slider = "",
        SliderValue = "",
        ListOpen = {},
        MultiListOpen = {},
        ColorOpen = "",
        IsHue = false,
        IsValueSaturation = false,
        IsAlpha = false,
        BindSelection = "",
        BindTypeSelection = "",
    }

    local MenuColors = {
        MainColor = color(255, 255),
        BackGroundTopLeft = color(56, 51, 57, 255),
        BackGroundTopRight = color(1, 1, 0, 255),
        BackGroundBottomLeft = color(1, 1, 0, 255),
        BackGroundMove = color(56, 51, 57, 255),
        BackGroundOutLine = color(67, 63, 64, 255),
        IconCoverBackGround = {color(0, 255), color(120, 120, 255, 255), color(120, 120, 255, 255), color(0, 255)},
        IconBackground = color(37, 33, 34, 255),
        IconOutline = color(67, 63, 64, 255),
        DigitalText = color(255, 255),
        DreamsText = color(255, 255),
        BackGroundTabs = color(37, 33, 34, 255),
        TabsOutLine = color(67, 63, 64, 255),
        TabsSelectGradient = {color(0, 255), color(120, 120, 255, 255), color(120, 120, 255, 255), color(0, 255)},
        TabsIcon = color(255, 255),
        BackGroundSubTabs = color(37, 33, 34, 255),
        SubTabsOutLine = color(67, 63, 64, 255),
        SubTabsSelectGradient = {color(0, 255), color(120, 120, 255, 255), color(120, 120, 255, 255), color(0, 255)},
        SubTabsIcon = color(255, 255),
        SubTabsText = color(255, 255),
        BackGroundUI = color(37, 33, 34, 255),
        UIOutLine = color(67, 63, 64, 255),
        CheckBoxText = color(255, 255),
        CheckBoxInactive = color(50, 255),
        CheckBoxActive = color(120, 120, 255, 255),
        CheckBoxBackgroundInactive = color(30, 255),
        CheckBoxBackgroundActive = color(120, 120, 255, 255),
        SliderText = color(255, 255),
        SliderValeText = color(255, 255),
        SliderBackgroundValue = color(67, 63, 64, 255),
        SliderValue = color(120, 120, 255, 255),
        ListBoxBackground = color(37, 33, 34, 255),
        ListBoxOutline = color(67, 63, 64, 255),
        ListBoxOpenBackground = color(37, 33, 34, 255),
        ListBoxOpenOutline = color(67, 63, 64, 255),
        ListBoxGradient = {color(0, 255), color(120, 120, 255, 255), color(120, 120, 255, 255), color(0, 255)},
        ListBoxIcon = color(255, 255),
        ListBoxText = color(255, 255),
        ListBoxValue = color(255, 255),
        ListBoxValues = color(255, 255),
        ListBoxSelectedValues = color(255, 255),
        ColorPickerBackground = color(37, 33, 34, 255),
        ColorPickerOpenBackground = color(37, 33, 34, 255),
        ColorPickerGradient = {color(0, 255), color(120, 120, 255, 255), color(120, 120, 255, 255), color(0, 255)},
        ColorPickerIcon = color(255, 255),
        ColorPickerText = color(255, 255),
        ColorPickerButtons = color(255, 255),
        KeybindBackground = color(37, 33, 34, 255),
        KeybindGradient = {color(0, 255), color(120, 120, 255, 255), color(120, 120, 255, 255), color(0, 255)},
        KeybindIcon = color(255, 255),
        KeybindText = color(255, 255),
        KeybindKey = color(255, 255),
        KeybindBinding = color(255, 0, 0, 255),
        KeybindModeInactive = color(255, 255),
        KeybindModeActive = color(120, 120, 255, 255),
        ButtonBackground = color(37, 33, 34, 255),
        ButtonGradient = {color(0, 255), color(120, 120, 255, 255), color(120, 120, 255, 255), color(0, 255)},
        ButtonIcon = color(255, 255),
        ButtonText = color(255, 255),
        EventBackground = color(37, 33, 34, 255),
        EventOutline = color(67, 63, 64, 255),
        EventIconBackground = color(37, 33, 34, 0),
        EventIcon = color(255, 255),
        EventText = color(255, 255),
    }


    Menu.RenderComponents.Data = 
    {
        ["Switch"] = 
        {
            Color = 
            {
                BackGroundSwitch = {},
                Switch = {},
            },
            Fade = {
                FadeSwitch = {}
            },
            Size = {
                Width = 20,
                Length = 8,
                PickerRadius = 6
            }
        },

        ["Slider"] = 
        {
            Fade = {
                FadeSliderNumber = {},
                FadeSlider = {},
                FadeValue = {}
            },
            LastPress = globals.tickcount
        },

        ["ListBox"] = 
        {
            Fade = {Open = {}},
            Items = {Fade = {}}
        },

        ["MultiListBox"] = 
        {
            Fade = {Open = {}},
            Items = {Fade = {}}
        },

        ["ColorEdit"] = 
        {
            Fade = {Open = {}},
            Hue = {},
            Saturation = {},
            Value = {},
            Alpha = {},
            HueColors = {
                color(255, 0, 0, 255), -- red
                color(255, 255, 0, 255), -- yellow
                color(0, 255, 0, 255), -- green
                color(0, 255, 255, 255), -- light blue
                color(0, 0, 255, 255), -- blue
                color(255, 0, 255, 255), -- pink
                color(255, 0, 0, 255), -- red
            },
        },

        ["KeyBind"] = 
        {
            Fade = {Open = {}, Length = {}, ColorChange = {}},
            Modes = {
                {"H", "hold"},
                {"T", "toggle"},
                {"A", "always"}
            },
        },

        ["Button"] = 
        {
            Fade = {Open = {}},
        },
    }
    Menu.RenderComponents.Types = 
    { -- // notes: [1] - ... we will use it to get more information later if we will need to such as width and etc | [2] - AdditionData[1] font , AdditionData[2] full alpha , AdditionData[3] hald alpha , AdditionData[4] width, AdditionData[5] spacing 
        ["Switch"] = function(RenderVector, ItemPoint, Alpha, ...)
            local AdditionData = {...}
            local Name = ItemPoint.Name
            local Value = ItemPoint.Value

            --create values on nil tables
            if Menu.RenderComponents.Data["Switch"].Color.BackGroundSwitch[Name] == nil then
                Menu.RenderComponents.Data["Switch"].Color.BackGroundSwitch[Name] = color(30, 255)
            end

            if Menu.RenderComponents.Data["Switch"].Color.Switch[Name] == nil then
                Menu.RenderComponents.Data["Switch"].Color.Switch[Name] = color(255, 255)
            end

            if Menu.RenderComponents.Data["Switch"].Fade.FadeSwitch[Name] == nil then
                Menu.RenderComponents.Data["Switch"].Fade.FadeSwitch[Name] = 0
            end
            
            --check if the value is covered 
            if AdditionData[2] ~= 0 then
                --render the name 
                render.text(AdditionData[1], RenderVector, Helpers.ColorAlpha(MenuColors.CheckBoxText, Alpha * AdditionData[2]), nil, Name)

                --check mechanic
                local IsInCheckBoxArea = Helpers.IsInBox(RenderVector + vector(AdditionData[4] - Menu.Render.MenuBorder * 2 - Menu.RenderComponents.Data["Switch"].Size.Width - 5, 10 - Menu.RenderComponents.Data["Switch"].Size.PickerRadius), Menu.RenderComponents.Data["Switch"].Size.Width + 10, Menu.RenderComponents.Data["Switch"].Size.PickerRadius*2)

                if IsInCheckBoxArea then
                    if Visuals.Move.IsPosible() and Menu.RenderComponents.InteractData.Slider == "" and not Helpers.Contains(Menu.RenderComponents.InteractData.ListOpen, true) and not Helpers.Contains(Menu.RenderComponents.InteractData.MultiListOpen, true) and not Menu.RenderComponents.InteractData.IsHue and not Menu.RenderComponents.InteractData.IsValueSaturation and not Menu.RenderComponents.InteractData.IsAlpha and Menu.RenderComponents.InteractData.ColorOpen == "" and Menu.RenderComponents.InteractData.BindTypeSelection == "" then -- other ui check later
                        if common.is_button_down(1) and globals.realtime > Menu.GlobalTime + 0.2 then
                            Menu.GlobalTime = globals.realtime
                            ItemPoint.Value = not ItemPoint.Value
                        end
                    end
                end

                --animations
                Menu.RenderComponents.Data["Switch"].Fade.FadeSwitch[Name] = Helpers.Lerp(Menu.RenderComponents.Data["Switch"].Fade.FadeSwitch[Name], Value and 0 or 1, 20)
                Menu.RenderComponents.Data["Switch"].Color.BackGroundSwitch[Name] = Helpers.Lerp(Menu.RenderComponents.Data["Switch"].Color.BackGroundSwitch[Name], Value and MenuColors.CheckBoxBackgroundActive or MenuColors.CheckBoxBackgroundInactive, 20)
                Menu.RenderComponents.Data["Switch"].Color.Switch[Name] = Helpers.Lerp(Menu.RenderComponents.Data["Switch"].Color.Switch[Name], Value and MenuColors.CheckBoxActive or MenuColors.CheckBoxInactive, 20)

                --render background
                render.rect(RenderVector + vector(AdditionData[4] - Menu.Render.MenuBorder * 2 - Menu.RenderComponents.Data["Switch"].Size.Width, 10 - Menu.RenderComponents.Data["Switch"].Size.Length/2), RenderVector + vector(AdditionData[4] - Menu.Render.MenuBorder * 2, 10 + Menu.RenderComponents.Data["Switch"].Size.Length/2), Helpers.ColorAlpha(Menu.RenderComponents.Data["Switch"].Color.BackGroundSwitch[Name], Alpha * AdditionData[2]), Menu.RenderComponents.Data["Switch"].Size.Length/2)
                
                render.circle(RenderVector + vector(AdditionData[4] - Menu.Render.MenuBorder * 2 - Menu.RenderComponents.Data["Switch"].Size.Width * Menu.RenderComponents.Data["Switch"].Fade.FadeSwitch[Name], 10), Helpers.ColorAlpha(Menu.RenderComponents.Data["Switch"].Color.Switch[Name], Alpha * AdditionData[2]), Menu.RenderComponents.Data["Switch"].Size.PickerRadius, 0, 1)
            end


            return 1, 0
        end,

        ["Slider"] = function(RenderVector, ItemPoint, Alpha, ...)
            local AdditionData = {...}
            local Name = ItemPoint.Name
            local Value = ItemPoint.Value
            local SliderData = ItemPoint.ExternalData -- {Min = MinimumValue, Max = MaximumValue}
            local ValueSize = render.measure_text(AdditionData[1], nil, Value)
            local Mouse = ui.get_mouse_position()
            local ModeSlider = (AdditionData[4] - Menu.Render.MenuBorder * 2) / (SliderData.Max - SliderData.Min)

            --render the name 
            render.text(AdditionData[1], RenderVector, Helpers.ColorAlpha(MenuColors.SliderText, Alpha * AdditionData[2] * AdditionData[3]), nil, Name)
            
            
            --create nil values
            if Menu.RenderComponents.Data["Slider"].Fade.FadeSlider[Name] == nil then
                Menu.RenderComponents.Data["Slider"].Fade.FadeSlider[Name] = 0
            end

            if Menu.RenderComponents.Data["Slider"].Fade.FadeSliderNumber[Name] == nil then
                Menu.RenderComponents.Data["Slider"].Fade.FadeSliderNumber[Name] = 0
            end

            if Menu.RenderComponents.Data["Slider"].Fade.FadeValue[Name] == nil then
                Menu.RenderComponents.Data["Slider"].Fade.FadeValue[Name] = 0
            end

            --fade the values
            Menu.RenderComponents.Data["Slider"].Fade.FadeValue[Name] = Helpers.Lerp(Menu.RenderComponents.Data["Slider"].Fade.FadeValue[Name], Value, 20)
            Menu.RenderComponents.Data["Slider"].Fade.FadeSliderNumber[Name] = Helpers.Lerp(Menu.RenderComponents.Data["Slider"].Fade.FadeSliderNumber[Name], Menu.RenderComponents.InteractData.SliderValue == Name and 1 or 0, 20)
            Menu.RenderComponents.Data["Slider"].Fade.FadeSlider[Name] = Helpers.Lerp(Menu.RenderComponents.Data["Slider"].Fade.FadeSlider[Name], Menu.RenderComponents.InteractData.Slider == Name and 1 or 0, 40)
            --Menu.RenderComponents.InteractData.Slider . SliderValue

            --usable area Menu.Render.MenuBorder
            local SliderArea = Helpers.IsInBox(RenderVector + vector(0, Menu.Render.SpaceUI + 1), AdditionData[4] - Menu.Render.MenuBorder * 2, ValueSize.y-1)
            local NumberArea = Helpers.IsInBox(RenderVector + vector(AdditionData[4] - Menu.Render.MenuBorder * 2 - ValueSize.x, 0), ValueSize.x, ValueSize.y)

            --use mechanic 
            if AdditionData[2] ~= 0 then
                if common.is_button_down(1) and Visuals.Move.IsPosible() and Menu.RenderComponents.InteractData.Slider == "" and not Helpers.Contains(Menu.RenderComponents.InteractData.ListOpen, true) and not Helpers.Contains(Menu.RenderComponents.InteractData.MultiListOpen, true) and not Menu.RenderComponents.InteractData.IsHue and not Menu.RenderComponents.InteractData.IsValueSaturation and not Menu.RenderComponents.InteractData.IsAlpha and Menu.RenderComponents.InteractData.ColorOpen == "" and Menu.RenderComponents.InteractData.BindTypeSelection == "" then -- and (true <- values for other ui elements)
                    if SliderArea then
                        Menu.RenderComponents.InteractData.Slider = Name
                    end
                elseif not common.is_button_down(1) and Visuals.Move.IsPosible() and Menu.RenderComponents.InteractData.Slider ~= "" and not Helpers.Contains(Menu.RenderComponents.InteractData.ListOpen, true) and not Helpers.Contains(Menu.RenderComponents.InteractData.MultiListOpen, true) then -- and (true <- values for other ui elements)
                    Menu.RenderComponents.InteractData.Slider = ""
                end

                --// number
                
                if NumberArea then
                    if common.is_button_down(0x11) and Menu.RenderComponents.InteractData.SliderValue == "" then
                        Menu.RenderComponents.InteractData.SliderValue = Name
                    else
                        Menu.RenderComponents.InteractData.SliderValue = ""
                    end
                else
                    if Menu.RenderComponents.InteractData.SliderValue == Name then
                        Menu.RenderComponents.InteractData.SliderValue = ""
                    end
                end
                
            end
            
            if Menu.RenderComponents.InteractData.Slider == Name then
                --local Mult = (math_max(Helpers.ToInt(Mouse.y - (RenderVector.y + Menu.Render.SpaceUI + ValueSize.y/2)), 125))
                local TempValue = SliderData.Min + Helpers.ToInt((Mouse.x - RenderVector.x) / ModeSlider) -- TODO : value * distance.y // for lower value based the distance from the slider

                if TempValue > SliderData.Max then
                    TempValue = SliderData.Max
                end

                if TempValue < SliderData.Min then
                    TempValue = SliderData.Min
                end

                ItemPoint.Value = math_floor(TempValue)
            end
            --value number
            if Menu.RenderComponents.InteractData.SliderValue == Name then
                local TempValue = Value

                --Menu.RenderComponents.Data["Slider"].LastPress = globals.tickcount
                if globals.tickcount > Menu.RenderComponents.Data["Slider"].LastPress + 8 then
                    if common.is_button_down(0x25) then
                        TempValue = TempValue - 1
                    elseif common.is_button_down(0x27) then
                        TempValue = TempValue + 1
                    end

                    Menu.RenderComponents.Data["Slider"].LastPress = globals.tickcount
                end

                if TempValue > SliderData.Max then
                    TempValue = SliderData.Max
                end

                if TempValue < SliderData.Min then
                    TempValue = SliderData.Min
                end

                ItemPoint.Value = TempValue
            end


            --render all the stuff
            --render value text
            
            render.gradient(RenderVector + vector(AdditionData[4] - Menu.Render.MenuBorder * 2 - ValueSize.x, 0), RenderVector + vector(AdditionData[4] - Menu.Render.MenuBorder * 2, ValueSize.y), Helpers.ColorAlpha(MenuColors.SliderValue, Alpha * AdditionData[2] * AdditionData[3] * Menu.RenderComponents.Data["Slider"].Fade.FadeSliderNumber[Name]), Helpers.ColorAlpha(MenuColors.SliderValue, 0), Helpers.ColorAlpha(MenuColors.SliderValue, 0), Helpers.ColorAlpha(MenuColors.SliderValue, 0), 3)
            render.text(AdditionData[1], RenderVector + vector(AdditionData[4] - Menu.Render.MenuBorder * 2 - ValueSize.x, 0), Helpers.ColorAlpha(MenuColors.SliderValeText, Alpha * AdditionData[2] * AdditionData[3]), nil, Value)
            

            --render slider itself
            if AdditionData[2] ~= 0 then

                render.rect(RenderVector + vector(0, Menu.Render.SpaceUI + ValueSize.y/2 - 1), RenderVector + vector(AdditionData[4] - Menu.Render.MenuBorder * 2, Menu.Render.SpaceUI + ValueSize.y/2 + 2 ), Helpers.ColorAlpha(MenuColors.SliderBackgroundValue, Alpha * AdditionData[2]), 1)
                render.rect(RenderVector + vector(0, Menu.Render.SpaceUI + ValueSize.y/2 - 1), RenderVector + vector((Menu.RenderComponents.Data["Slider"].Fade.FadeValue[Name] - SliderData.Min) * ModeSlider - 1, Menu.Render.SpaceUI + ValueSize.y/2 + 1), Helpers.ColorAlpha(MenuColors.SliderValue, Alpha * AdditionData[2]), 1)
                render.circle_gradient(
                    RenderVector + vector((Value - SliderData.Min) * ModeSlider, Menu.Render.SpaceUI + ValueSize.y/2), 
                    Helpers.ColorAlpha(MenuColors.SliderValue, Alpha * AdditionData[2]), 
                    Helpers.ColorAlpha(color(0, 255), Alpha * AdditionData[2]), 
                    3 + 3*Menu.RenderComponents.Data["Slider"].Fade.FadeSlider[Name], 
                    0, 
                    1
                )
            end

            return 2, 0
        end,

        ["ListBox"] = function(RenderVector, ItemPoint, Alpha, ...)
            local AdditionData = {...}
            local Name = ItemPoint.Name
            local Value = ItemPoint.Value
            local ComboData = ItemPoint.ExternalData.Items
            local ValueSize = render.measure_text(AdditionData[1], nil, Value)
            local Mouse = ui.get_mouse_position()

            --render the name 
            render.text(AdditionData[1], RenderVector, Helpers.ColorAlpha(MenuColors.ListBoxText, Alpha * AdditionData[2] * AdditionData[3]), nil, Name)

            --create empty values 
            if Menu.RenderComponents.InteractData.ListOpen[Name] == nil then
                Menu.RenderComponents.InteractData.ListOpen[Name] = false
            end

            if Menu.RenderComponents.Data["ListBox"].Fade.Open[Name] == nil then
                Menu.RenderComponents.Data["ListBox"].Fade.Open[Name] = 0
            end

            --fade
            Menu.RenderComponents.Data["ListBox"].Fade.Open[Name] = Helpers.Lerp(Menu.RenderComponents.Data["ListBox"].Fade.Open[Name], Menu.RenderComponents.InteractData.ListOpen[Name] and 1 or 0, 20)

            --usable area
            local InClickableArea = Helpers.IsInBox(RenderVector + vector(0, Menu.Render.SpaceUI + Menu.Render.SpaceUI * Menu.RenderComponents.Data["ListBox"].Fade.Open[Name]), AdditionData[4] - Menu.Render.MenuBorder * 2, Menu.Render.SpaceUI + ((- 4) * math_abs(Menu.RenderComponents.Data["ListBox"].Fade.Open[Name]-1)) + ((#ComboData - 1*Menu.RenderComponents.Data["ListBox"].Fade.Open[Name])*Menu.Render.SpaceUI) * Menu.RenderComponents.Data["ListBox"].Fade.Open[Name])
            --local InClickableAreaOpen = Helpers.IsInBox()

            if AdditionData[2] ~= 0 then
                --open mechanic and not Helpers.Contains(Menu.RenderComponents.InteractData.ListOpen, true)
                if common.is_button_down(1) and Visuals.Move.IsPosible() and Menu.RenderComponents.InteractData.Slider == "" and not Helpers.Contains(Menu.RenderComponents.InteractData.MultiListOpen, true) and not Menu.RenderComponents.InteractData.IsHue and not Menu.RenderComponents.InteractData.IsValueSaturation and not Menu.RenderComponents.InteractData.IsAlpha and Menu.RenderComponents.InteractData.ColorOpen == "" and Menu.RenderComponents.InteractData.BindTypeSelection == "" then
                    if Menu.RenderComponents.InteractData.ListOpen[Name] == false then
                        if InClickableArea then
                            if not Helpers.Contains(Menu.RenderComponents.InteractData.ListOpen, true) then
                                if globals.realtime > Menu.GlobalTime + 0.2 then
                                    Menu.GlobalTime = globals.realtime
                                    Menu.RenderComponents.InteractData.ListOpen[Name] = true
                                end
                            end
                        end
                    else
                        if not InClickableArea then
                            if globals.realtime > Menu.GlobalTime + 0.2 then
                                Menu.GlobalTime = globals.realtime
                                Menu.RenderComponents.InteractData.ListOpen[Name] = false
                            end
                        end
                    end
                end 
            else
                Menu.RenderComponents.InteractData.ListOpen[Name] = false
            end


            --render
            if AdditionData[2] ~= 0 then -- color(30, 255)
                render.rect(RenderVector + vector(0, Menu.Render.SpaceUI), RenderVector + vector(AdditionData[4] - Menu.Render.MenuBorder * 3 - (Menu.Render.SpaceUI-4), Menu.Render.SpaceUI + (Menu.Render.SpaceUI-4)), Helpers.ColorAlpha(MenuColors.ListBoxBackground, Alpha * AdditionData[2]), 3)
                render.rect_outline(RenderVector + vector(0, Menu.Render.SpaceUI), RenderVector + vector(AdditionData[4] - Menu.Render.MenuBorder * 3 - (Menu.Render.SpaceUI-4), Menu.Render.SpaceUI + (Menu.Render.SpaceUI-4)), Helpers.ColorAlpha(MenuColors.ListBoxOutline,  Alpha * AdditionData[2]), 1, 3)
                render.gradient(RenderVector + vector(AdditionData[4] - Menu.Render.MenuBorder * 2 - (Menu.Render.SpaceUI-4), Menu.Render.SpaceUI), RenderVector + vector(AdditionData[4] - Menu.Render.MenuBorder * 2, Menu.Render.SpaceUI + (Menu.Render.SpaceUI-4)), Helpers.ColorAlpha(MenuColors.ListBoxGradient[1], Alpha * AdditionData[2]), Helpers.ColorAlpha(MenuColors.ListBoxGradient[2], Alpha * AdditionData[2]), Helpers.ColorAlpha(MenuColors.ListBoxGradient[3], Alpha * AdditionData[2]), Helpers.ColorAlpha(MenuColors.ListBoxGradient[4], Alpha * AdditionData[2]), 3)
                --+
                render.line(RenderVector + vector(AdditionData[4] - Menu.Render.MenuBorder * 2 - (Menu.Render.SpaceUI-4) + 4, Menu.Render.SpaceUI + (Menu.Render.SpaceUI-4)/2), RenderVector + vector(AdditionData[4] - Menu.Render.MenuBorder * 2 - 4, Menu.Render.SpaceUI + (Menu.Render.SpaceUI-4)/2), Helpers.ColorAlpha(MenuColors.ListBoxIcon, Alpha * AdditionData[2]))
                render.line(RenderVector + vector(AdditionData[4] - Menu.Render.MenuBorder * 2 - (Menu.Render.SpaceUI-4)/2, Menu.Render.SpaceUI + 4), RenderVector + vector(AdditionData[4] - Menu.Render.MenuBorder * 2 - (Menu.Render.SpaceUI-4)/2, Menu.Render.SpaceUI + (Menu.Render.SpaceUI-4) - 4), Helpers.ColorAlpha(MenuColors.ListBoxIcon, Alpha * AdditionData[2] * math_abs(Menu.RenderComponents.Data["ListBox"].Fade.Open[Name]-1)))
                
                render.text(AdditionData[1], RenderVector + vector(Menu.Render.MenuBorder, Menu.Render.SpaceUI + (Menu.Render.SpaceUI-6)/2 - ValueSize.y/2), Helpers.ColorAlpha(MenuColors.ListBoxValue, Alpha * AdditionData[2]), nil, Value)

                if Menu.RenderComponents.Data["ListBox"].Fade.Open[Name] ~= 0 then
                    render.rect(RenderVector + vector(0, Menu.Render.SpaceUI + (Menu.Render.SpaceUI-2)), RenderVector + vector(AdditionData[4] - Menu.Render.MenuBorder * 2, Menu.Render.SpaceUI + (Menu.Render.SpaceUI-2) + (#ComboData*Menu.Render.SpaceUI) * Menu.RenderComponents.Data["ListBox"].Fade.Open[Name]), Helpers.ColorAlpha(MenuColors.ListBoxOpenBackground, Alpha * AdditionData[2] * Menu.RenderComponents.Data["ListBox"].Fade.Open[Name]), 3)
                    render.rect_outline(RenderVector + vector(0, Menu.Render.SpaceUI + (Menu.Render.SpaceUI-2)), RenderVector + vector(AdditionData[4] - Menu.Render.MenuBorder * 2, Menu.Render.SpaceUI + (Menu.Render.SpaceUI-2) + (#ComboData*Menu.Render.SpaceUI) * Menu.RenderComponents.Data["ListBox"].Fade.Open[Name]), Helpers.ColorAlpha(MenuColors.ListBoxOpenOutline,  Alpha * AdditionData[2] * Menu.RenderComponents.Data["ListBox"].Fade.Open[Name]), 1, 3)
                    for Index, Item in pairs(ComboData) do
                        local YAddition = (Index-1) * Menu.Render.SpaceUI
                        local ComboItemSignature = Name .. "$" .. Item

                        if Menu.RenderComponents.Data["ListBox"].Items.Fade[ComboItemSignature] == nil then
                            Menu.RenderComponents.Data["ListBox"].Items.Fade[ComboItemSignature] = 0
                        end

                        local IsOnItem = Helpers.IsInBox(RenderVector + vector(0, Menu.Render.SpaceUI + (Menu.Render.SpaceUI) + YAddition), AdditionData[4] - Menu.Render.MenuBorder * 2, Menu.Render.SpaceUI)

                        Menu.RenderComponents.Data["ListBox"].Items.Fade[ComboItemSignature] = Helpers.Lerp(Menu.RenderComponents.Data["ListBox"].Items.Fade[ComboItemSignature], IsOnItem and 1 or 0.5, 20)

                        if IsOnItem then
                            if common.is_button_down(1) and globals.realtime > Menu.GlobalTime + 0.2 then
                                Menu.GlobalTime = globals.realtime
                                ItemPoint.Value = Item
                            end
                        end

                        if Item == Value then
                            render.circle_gradient(RenderVector + vector(Menu.Render.MenuBorder, Menu.Render.SpaceUI + (Menu.Render.SpaceUI) + YAddition + ValueSize.y/2 + 2), Helpers.ColorAlpha(Menu.Render.ActiveColor[1], 0), Helpers.ColorAlpha(MenuColors.ListBoxSelectedValues, Alpha * AdditionData[2] * Menu.RenderComponents.Data["ListBox"].Fade.Open[Name]), 3, 0, 1)
                        end

                        render.text(AdditionData[1], RenderVector + vector(Menu.Render.MenuBorder * 2, Menu.Render.SpaceUI + (Menu.Render.SpaceUI) + YAddition), Helpers.ColorAlpha(MenuColors.ListBoxValues, Alpha * AdditionData[2] * Menu.RenderComponents.Data["ListBox"].Fade.Open[Name] * Menu.RenderComponents.Data["ListBox"].Items.Fade[ComboItemSignature]), nil, Item) 
                    end
                end
            end

            return 2, (#ComboData*Menu.Render.SpaceUI)*(Menu.RenderComponents.InteractData.ListOpen[Name] and 1 or 0)
        end,

        ["MultiListBox"] = function(RenderVector, ItemPoint, Alpha, ...)
            local AdditionData = {...}
            local Name = ItemPoint.Name

            local Value = ""
            local ComboData = ItemPoint.ExternalData.Items
            --Value = Helpers.TableExport(ComboData)
            local Mouse = ui.get_mouse_position()

            --get the value as string
            local TableValue = {}
            for I, J in pairs(ComboData) do
                if ItemPoint.Value[I] then
                    TableValue[#TableValue + 1] = J
                end
            end
            Value = Helpers.TableExport(TableValue, ", ")
            if Value:len() > 25 then
                Value = string.sub(Value, 1, 25)
                Value = Value .. "..."
            end

            local ValueSize = render.measure_text(AdditionData[1], nil, Value)

            --render the name 
            render.text(AdditionData[1], RenderVector, Helpers.ColorAlpha(MenuColors.ListBoxText, Alpha * AdditionData[2] * AdditionData[3]), nil, Name)

            --create empty values 
            if Menu.RenderComponents.InteractData.MultiListOpen[Name] == nil then
                Menu.RenderComponents.InteractData.MultiListOpen[Name] = false
            end

            if Menu.RenderComponents.Data["MultiListBox"].Fade.Open[Name] == nil then
                Menu.RenderComponents.Data["MultiListBox"].Fade.Open[Name] = 0
            end

            --fade
            Menu.RenderComponents.Data["MultiListBox"].Fade.Open[Name] = Helpers.Lerp(Menu.RenderComponents.Data["MultiListBox"].Fade.Open[Name], Menu.RenderComponents.InteractData.MultiListOpen[Name] and 1 or 0, 30)

            --usable area
            local InClickableArea = Helpers.IsInBox(RenderVector + vector(0, Menu.Render.SpaceUI + Menu.Render.SpaceUI * Menu.RenderComponents.Data["MultiListBox"].Fade.Open[Name]), AdditionData[4] - Menu.Render.MenuBorder * 2, Menu.Render.SpaceUI + ((- 4) * math_abs(Menu.RenderComponents.Data["MultiListBox"].Fade.Open[Name]-1)) + ((#ComboData - 1*Menu.RenderComponents.Data["MultiListBox"].Fade.Open[Name])*Menu.Render.SpaceUI) * Menu.RenderComponents.Data["MultiListBox"].Fade.Open[Name])
            --local InClickableAreaOpen = Helpers.IsInBox()

            if AdditionData[2] ~= 0 then
                --open mechanic and not Helpers.Contains(Menu.RenderComponents.InteractData.ListOpen, true)
                if common.is_button_down(1) and Visuals.Move.IsPosible() and Menu.RenderComponents.InteractData.Slider == "" and not Helpers.Contains(Menu.RenderComponents.InteractData.ListOpen, true) and not Menu.RenderComponents.InteractData.IsHue and not Menu.RenderComponents.InteractData.IsValueSaturation and not Menu.RenderComponents.InteractData.IsAlpha and Menu.RenderComponents.InteractData.ColorOpen == "" and Menu.RenderComponents.InteractData.BindTypeSelection == "" then
                    if Menu.RenderComponents.InteractData.MultiListOpen[Name] == false then
                        if InClickableArea then
                            if not Helpers.Contains(Menu.RenderComponents.InteractData.MultiListOpen, true) then
                                if globals.realtime > Menu.GlobalTime + 0.2 then
                                    Menu.GlobalTime = globals.realtime
                                    Menu.RenderComponents.InteractData.MultiListOpen[Name] = true
                                end
                            end
                        end
                    else
                        if not InClickableArea then
                            if globals.realtime > Menu.GlobalTime + 0.2 then
                                Menu.GlobalTime = globals.realtime
                                Menu.RenderComponents.InteractData.MultiListOpen[Name] = false
                            end
                        end
                    end
                end 
            else
                Menu.RenderComponents.InteractData.MultiListOpen[Name] = false
            end

            --Files.image_LoadList = Files.LoadImage(Files.DownloadFiles.List, vector(15, 15))
            --Files.image_LoadMultiList = Files.LoadImage(Files.DownloadFiles.MultiList, vector(15, 15))

            --render
            if AdditionData[2] ~= 0 then -- color(30, 255)
                render.rect(RenderVector + vector(0, Menu.Render.SpaceUI), RenderVector + vector(AdditionData[4] - Menu.Render.MenuBorder * 3 - (Menu.Render.SpaceUI-4), Menu.Render.SpaceUI + (Menu.Render.SpaceUI-4)), Helpers.ColorAlpha(MenuColors.ListBoxBackground, Alpha * AdditionData[2]), 3)
                render.rect_outline(RenderVector + vector(0, Menu.Render.SpaceUI), RenderVector + vector(AdditionData[4] - Menu.Render.MenuBorder * 3 - (Menu.Render.SpaceUI-4), Menu.Render.SpaceUI + (Menu.Render.SpaceUI-4)), Helpers.ColorAlpha(MenuColors.ListBoxOutline,  Alpha * AdditionData[2]), 1, 3)
                render.gradient(RenderVector + vector(AdditionData[4] - Menu.Render.MenuBorder * 2 - (Menu.Render.SpaceUI-4), Menu.Render.SpaceUI), RenderVector + vector(AdditionData[4] - Menu.Render.MenuBorder * 2, Menu.Render.SpaceUI + (Menu.Render.SpaceUI-4)), Helpers.ColorAlpha(MenuColors.ListBoxGradient[1], Alpha * AdditionData[2]), Helpers.ColorAlpha(MenuColors.ListBoxGradient[2], Alpha * AdditionData[2]), Helpers.ColorAlpha(MenuColors.ListBoxGradient[3], Alpha * AdditionData[2]), Helpers.ColorAlpha(MenuColors.ListBoxGradient[4], Alpha * AdditionData[2]), 3)
                --+
                render.line(RenderVector + vector(AdditionData[4] - Menu.Render.MenuBorder * 2 - (Menu.Render.SpaceUI-4) + 4, Menu.Render.SpaceUI + (Menu.Render.SpaceUI-4)/2), RenderVector + vector(AdditionData[4] - Menu.Render.MenuBorder * 2 - 4, Menu.Render.SpaceUI + (Menu.Render.SpaceUI-4)/2), Helpers.ColorAlpha(MenuColors.ListBoxIcon, Alpha * AdditionData[2]))
                render.line(RenderVector + vector(AdditionData[4] - Menu.Render.MenuBorder * 2 - (Menu.Render.SpaceUI-4)/2, Menu.Render.SpaceUI + 4), RenderVector + vector(AdditionData[4] - Menu.Render.MenuBorder * 2 - (Menu.Render.SpaceUI-4)/2, Menu.Render.SpaceUI + (Menu.Render.SpaceUI-4) - 4), Helpers.ColorAlpha(MenuColors.ListBoxIcon, Alpha * AdditionData[2] * math_abs(Menu.RenderComponents.Data["MultiListBox"].Fade.Open[Name]-1)))
                

                if Menu.RenderComponents.Data["MultiListBox"].Fade.Open[Name] ~= 0 then
                    render.rect(RenderVector + vector(0, Menu.Render.SpaceUI + (Menu.Render.SpaceUI-2)), RenderVector + vector(AdditionData[4] - Menu.Render.MenuBorder * 2, Menu.Render.SpaceUI + (Menu.Render.SpaceUI-2) + (#ComboData*Menu.Render.SpaceUI) * Menu.RenderComponents.Data["MultiListBox"].Fade.Open[Name]), Helpers.ColorAlpha(MenuColors.ListBoxOpenBackground, Alpha * AdditionData[2] * Menu.RenderComponents.Data["MultiListBox"].Fade.Open[Name]), 3)
                    render.rect_outline(RenderVector + vector(0, Menu.Render.SpaceUI + (Menu.Render.SpaceUI-2)), RenderVector + vector(AdditionData[4] - Menu.Render.MenuBorder * 2, Menu.Render.SpaceUI + (Menu.Render.SpaceUI-2) + (#ComboData*Menu.Render.SpaceUI) * Menu.RenderComponents.Data["MultiListBox"].Fade.Open[Name]), Helpers.ColorAlpha(MenuColors.ListBoxOpenOutline,  Alpha * AdditionData[2] * Menu.RenderComponents.Data["MultiListBox"].Fade.Open[Name]), 1, 3)

                    for Index, Item in pairs(ComboData) do
                        local YAddition = (Index-1) * Menu.Render.SpaceUI
                        local ComboItemSignature = Name .. "$" .. Item

                        if Menu.RenderComponents.Data["MultiListBox"].Items.Fade[ComboItemSignature] == nil then
                            Menu.RenderComponents.Data["MultiListBox"].Items.Fade[ComboItemSignature] = 0
                        end

                        local IsOnItem = Helpers.IsInBox(RenderVector + vector(0, Menu.Render.SpaceUI + (Menu.Render.SpaceUI) + YAddition), AdditionData[4] - Menu.Render.MenuBorder * 2, Menu.Render.SpaceUI)

                        Menu.RenderComponents.Data["MultiListBox"].Items.Fade[ComboItemSignature] = Helpers.Lerp(Menu.RenderComponents.Data["MultiListBox"].Items.Fade[ComboItemSignature], IsOnItem and 1 or 0.5, 20)

                        if IsOnItem then
                            if common.is_button_down(1) and globals.realtime > Menu.GlobalTime + 0.2 then
                                Menu.GlobalTime = globals.realtime
                                ItemPoint.Value[Index] = not ItemPoint.Value[Index]
                            end
                        end

                        if ItemPoint.Value[Index] then
                            render.circle_gradient(RenderVector + vector(Menu.Render.MenuBorder, Menu.Render.SpaceUI + (Menu.Render.SpaceUI) + YAddition + render.measure_text(AdditionData[1], nil, Item).y/2 + 2), Helpers.ColorAlpha(MenuColors.ListBoxSelectedValues, 0), Helpers.ColorAlpha(MenuColors.ListBoxSelectedValues, Alpha * AdditionData[2] * Menu.RenderComponents.Data["MultiListBox"].Fade.Open[Name]), 3, 0, 1)
                            --render.circle_gradient(RenderVector + vector(Menu.Render.MenuBorder, Menu.Render.SpaceUI + (Menu.Render.SpaceUI) + YAddition + render.measure_text(AdditionData[1], nil, Item).y/2 + 2), Helpers.ColorAlpha(MenuColors.ListBoxSelectedValues, Alpha * AdditionData[2] * Menu.RenderComponents.Data["MultiListBox"].Fade.Open[Name]), 3, 0, 1)
                        end

                        render.text(AdditionData[1], RenderVector + vector(Menu.Render.MenuBorder * 2, Menu.Render.SpaceUI + (Menu.Render.SpaceUI) + YAddition), Helpers.ColorAlpha(MenuColors.ListBoxValues, Alpha * AdditionData[2] * Menu.RenderComponents.Data["MultiListBox"].Fade.Open[Name] * Menu.RenderComponents.Data["MultiListBox"].Items.Fade[ComboItemSignature]), nil, Item) 
                    end
                end
                render.text(AdditionData[1], RenderVector + vector(Menu.Render.MenuBorder, Menu.Render.SpaceUI + (Menu.Render.SpaceUI-6)/2 - ValueSize.y/2), Helpers.ColorAlpha(MenuColors.ListBoxValue, Alpha * AdditionData[2]), nil, Value) 
                
            end
            --ListBox
            return 2, (#ComboData*Menu.Render.SpaceUI)*(Menu.RenderComponents.InteractData.MultiListOpen[Name] and 1 or 0)
        end,

        ["ColorEdit"] = function(RenderVector, ItemPoint, Alpha, ...)
            local AdditionData = {...}
            local Name = ItemPoint.Name
            local Value = ItemPoint.Value
            local DefaultColor = ItemPoint.ExternalData.DefaultColor:clone()
            local Mouse = ui.get_mouse_position()
            local Icon = Files.image_LoadColorEdit

            local NewWidth = AdditionData[4] - Menu.Render.MenuBorder * 6
            local PickerSize = vector(NewWidth, NewWidth)
            local BoxAdd = 40

            --is in vectors 
            local IsOnOpen = Helpers.IsInBox(RenderVector + vector(AdditionData[4] - Menu.Render.MenuBorder * 2 - (Menu.Render.SpaceUI-4)*2, 4), (Menu.Render.SpaceUI-4)*2, (Menu.Render.SpaceUI - 4))
            local IsOnPicker = Helpers.IsInBox(RenderVector + vector(0, Menu.Render.SpaceUI), AdditionData[4] - Menu.Render.MenuBorder * 2, AdditionData[4] - Menu.Render.MenuBorder * 6 + Menu.Render.SpaceUI*2.2)

            --create empty value
            if Menu.RenderComponents.Data["ColorEdit"].Fade.Open[Name] == nil then
                Menu.RenderComponents.Data["ColorEdit"].Fade.Open[Name] = 0
            end

            --IsHue = false,
            --IsValueSaturation = false,
            --IsAlpha = false,

            --check area
            if AdditionData[2] ~= 0 then
                if common.is_button_down(1) and Visuals.Move.IsPosible() and Menu.RenderComponents.InteractData.Slider == "" and not Helpers.Contains(Menu.RenderComponents.InteractData.ListOpen, true) and not Helpers.Contains(Menu.RenderComponents.InteractData.MultiListOpen, true) and Menu.RenderComponents.InteractData.BindTypeSelection == "" then
                    if Menu.RenderComponents.InteractData.ColorOpen == "" then
                        if IsOnOpen then
                            if globals.realtime > Menu.GlobalTime + 0.2 then
                                Menu.GlobalTime = globals.realtime
                                Menu.RenderComponents.InteractData.ColorOpen = Name
                            end
                        end
                    elseif Menu.RenderComponents.InteractData.ColorOpen == Name then
                        if not IsOnPicker and not Menu.RenderComponents.InteractData.IsHue and not Menu.RenderComponents.InteractData.IsValueSaturation and not Menu.RenderComponents.InteractData.IsAlpha then
                            if globals.realtime > Menu.GlobalTime + 0.2 then
                                Menu.GlobalTime = globals.realtime
                                Menu.RenderComponents.InteractData.ColorOpen = ""
                            end
                        end
                    end
                end
            end

            Menu.RenderComponents.Data["ColorEdit"].Fade.Open[Name] = Helpers.Lerp(Menu.RenderComponents.Data["ColorEdit"].Fade.Open[Name], Menu.RenderComponents.InteractData.ColorOpen == Name and 1 or 0, 20)

            --render
            if AdditionData[2] ~= 0 then 
                render.text(AdditionData[1], RenderVector, Helpers.ColorAlpha(MenuColors.ColorPickerText, Alpha * AdditionData[2]), nil, Name)

                --create new var for more easy name hhh :P
                local AlphaPicker = Menu.RenderComponents.Data["ColorEdit"].Fade.Open[Name]
                --render icon Files.image_LoadColorEdit

                render.rect(RenderVector + vector(AdditionData[4] - Menu.Render.MenuBorder * 2 - (Menu.Render.SpaceUI-4)*2, 0), RenderVector + vector(AdditionData[4] - Menu.Render.MenuBorder * 2, (Menu.Render.SpaceUI-4)), Helpers.ColorAlpha(MenuColors.ColorPickerBackground, Alpha * AdditionData[2]), 3)
                render.gradient(RenderVector + vector(AdditionData[4] - Menu.Render.MenuBorder * 2 - (Menu.Render.SpaceUI-4), 0), RenderVector + vector(AdditionData[4] - Menu.Render.MenuBorder * 2, (Menu.Render.SpaceUI-4)), Helpers.ColorAlpha(MenuColors.ColorPickerGradient[1], Alpha * AdditionData[2]), Helpers.ColorAlpha(MenuColors.ColorPickerGradient[2], Alpha * AdditionData[2]), Helpers.ColorAlpha(MenuColors.ColorPickerGradient[3], Alpha * AdditionData[2]), Helpers.ColorAlpha(MenuColors.ColorPickerGradient[4], Alpha * AdditionData[2]), 3)

                render.texture(Icon.Image, RenderVector + vector(AdditionData[4] - Menu.Render.MenuBorder * 2 - (Menu.Render.SpaceUI-4)/2 - Icon.Size.x/2, (Menu.Render.SpaceUI)/2 - Icon.Size.y/2), Icon.Size, Helpers.ColorAlpha(MenuColors.ColorPickerIcon, Alpha * AdditionData[2]))
                render.circle_gradient(RenderVector + vector(AdditionData[4] - Menu.Render.MenuBorder * 2 - (Menu.Render.SpaceUI-4)*1.5, Menu.Render.SpaceUI/2 - 2), Helpers.ColorAlpha(color(Value.r, Value.g, Value.b, 255), Alpha * AdditionData[2]), Helpers.ColorAlpha(Value:clone(), Alpha * AdditionData[2]), 5, 0, 1)


                if AlphaPicker ~= 0 then
                    local PickerVector = RenderVector + vector(Menu.Render.SpaceUI*0.2, Menu.Render.SpaceUI*1.2)

                    --sliders values
                    local HuePickerWidth = 2.0
                    local SelectSize = 3

                    --create empty values
                    if Menu.RenderComponents.Data["ColorEdit"].Hue[Name] == nil then
                        Menu.RenderComponents.Data["ColorEdit"].Hue[Name], Menu.RenderComponents.Data["ColorEdit"].Saturation[Name], Menu.RenderComponents.Data["ColorEdit"].Value[Name], Menu.RenderComponents.Data["ColorEdit"].Alpha[Name] = Helpers.RGBtoHSV(Value.r, Value.g, Value.b, Value.a)
                    end

                    --local AlphaValue = Value.a / 255
                    render.rect(PickerVector + vector(-(Menu.Render.SpaceUI*0.2), -(Menu.Render.SpaceUI*0.2)), PickerVector + vector(AdditionData[4] - Menu.Render.MenuBorder * 2 - (Menu.Render.SpaceUI*0.2), PickerSize.y + Menu.Render.SpaceUI*2), Helpers.ColorAlpha(MenuColors.ColorPickerOpenBackground, Alpha * AdditionData[2] * AlphaPicker), 4)

                    --hue slider
                    local Hue = color(255, 255, 255, 255)
                    Hue.r, Hue.g, Hue.b = Helpers.HSVtoRGB(Menu.RenderComponents.Data["ColorEdit"].Hue[Name], 1, 1)
                    for Index = 1, 6 do
                        render.gradient(
                            PickerVector + vector(
                                PickerSize.x + (BoxAdd / 4),
                                (Index - 1) * (PickerSize.y / 6)
                            ),
                            PickerVector + vector(
                                PickerSize.x + (BoxAdd / 4) + HuePickerWidth,
                                (Index) * (PickerSize.y / 6)
                            ),
                            Helpers.ColorAlpha(Menu.RenderComponents.Data["ColorEdit"].HueColors[Index], Alpha * AdditionData[2] * AlphaPicker),
                            Helpers.ColorAlpha(Menu.RenderComponents.Data["ColorEdit"].HueColors[Index], Alpha * AdditionData[2] * AlphaPicker),
                            Helpers.ColorAlpha(Menu.RenderComponents.Data["ColorEdit"].HueColors[Index + 1], Alpha * AdditionData[2] * AlphaPicker),
                            Helpers.ColorAlpha(Menu.RenderComponents.Data["ColorEdit"].HueColors[Index + 1], Alpha * AdditionData[2] * AlphaPicker)
                        )
                    end

                    -- picker
                    render.poly(
                        Helpers.ColorAlpha(color(255, 255), Alpha * AdditionData[2] * AlphaPicker),
                        PickerVector + vector(
                            PickerSize.x + (BoxAdd / 4) + HuePickerWidth + 1,
                            Menu.RenderComponents.Data["ColorEdit"].Hue[Name] * PickerSize.y
                        ),
                        PickerVector + vector(
                            PickerSize.x + (BoxAdd / 4) + HuePickerWidth + 5,
                            Menu.RenderComponents.Data["ColorEdit"].Hue[Name] * PickerSize.y - 2
                        ),
                        PickerVector + vector(
                            PickerSize.x + (BoxAdd / 4) + HuePickerWidth + 5,
                            Menu.RenderComponents.Data["ColorEdit"].Hue[Name] * PickerSize.y + 2
                        )
                    )

                    render.circle(
                        PickerVector + vector(
                            PickerSize.x + (BoxAdd / 4) + HuePickerWidth + SelectSize * 2 + 7,
                            Menu.RenderComponents.Data["ColorEdit"].Hue[Name] * PickerSize.y
                        ),
                        Helpers.ColorAlpha(Hue, Alpha * AdditionData[2] * AlphaPicker),
                        SelectSize * 1.2,
                        0,
                        1
                    )


                    render.gradient(
                        PickerVector + vector(
                            0,
                            PickerSize.y + (BoxAdd / 4)
                        ),
                        PickerVector + vector(
                            PickerSize.x,
                            PickerSize.y + (BoxAdd / 4) + HuePickerWidth
                        ),
                        Helpers.ColorAlpha(color(0, 0, 0, 255), Alpha * AdditionData[2] * AlphaPicker),
                        Helpers.ColorAlpha(color(Value.r, Value.g, Value.b, 255), Alpha * AdditionData[2] * AlphaPicker),
                        Helpers.ColorAlpha(color(0, 0, 0, 255), Alpha * AdditionData[2] * AlphaPicker),
                        Helpers.ColorAlpha(color(Value.r, Value.g, Value.b, 255), Alpha * AdditionData[2] * AlphaPicker)
                    )


                    --render.poly(
                    --    Helpers.ColorAlpha(color(255, 255), Alpha * AdditionData[2] * AlphaPicker),
                    --    PickerVector + vector(
                    --        PickerSize.x * Menu.RenderComponents.Data["ColorEdit"].Alpha[Name],
                    --        PickerSize.y + (BoxAdd / 4) + HuePickerWidth
                    --    ),
                    --    PickerVector + vector(
                    --        PickerSize.x * Menu.RenderComponents.Data["ColorEdit"].Alpha[Name] - 2,
                    --        PickerSize.y + (BoxAdd / 4) + HuePickerWidth + 5
                    --    ),
                    --    PickerVector + vector(
                    --        PickerSize.x * Menu.RenderComponents.Data["ColorEdit"].Alpha[Name] + 2,
                    --        PickerSize.y + (BoxAdd / 4) + HuePickerWidth + 5
                    --    )
                    --)

                    render.circle(
                        PickerVector + vector(
                            PickerSize.x * Menu.RenderComponents.Data["ColorEdit"].Alpha[Name],
                            PickerSize.y + (BoxAdd / 4) + HuePickerWidth / 2
                        ),
                        Helpers.ColorAlpha(color(0, 255), Alpha * AdditionData[2] * AlphaPicker),
                        SelectSize,
                        0,
                        1
                    )

                    render.circle(
                        PickerVector + vector(
                            PickerSize.x * Menu.RenderComponents.Data["ColorEdit"].Alpha[Name],
                            PickerSize.y + (BoxAdd / 4) + HuePickerWidth / 2
                        ),
                        Helpers.ColorAlpha(color(Value.r, Value.g, Value.b, 255), Alpha * AdditionData[2] * AlphaPicker * Menu.RenderComponents.Data["ColorEdit"].Alpha[Name]),
                        SelectSize,
                        0,
                        1
                    )

                    --@render background for value & saturation
                    local COBlack = color(0, 0, 0, 255)
                    local CONoBlack = color(0, 0, 0, 0)
                    local COWhite = color(255, 255, 255, 255)

                    render.rect_outline(PickerVector, PickerVector + PickerSize, Helpers.ColorAlpha(COWhite, Alpha * AdditionData[2] * AlphaPicker), 2, 2)

                    render.gradient(
                        PickerVector,
                        PickerVector + PickerSize,
                        Helpers.ColorAlpha(COWhite, Alpha * AdditionData[2] * AlphaPicker),
                        Helpers.ColorAlpha(Hue, Alpha * AdditionData[2] * AlphaPicker),
                        Helpers.ColorAlpha(COWhite, Alpha * AdditionData[2] * AlphaPicker),
                        Helpers.ColorAlpha(Hue, Alpha * AdditionData[2] * AlphaPicker),
                        3
                    )
                    render.gradient(
                        PickerVector,
                        PickerVector + PickerSize,
                        Helpers.ColorAlpha(CONoBlack, Alpha * AdditionData[2] * AlphaPicker),
                        Helpers.ColorAlpha(CONoBlack, Alpha * AdditionData[2] * AlphaPicker),
                        Helpers.ColorAlpha(COBlack, Alpha * AdditionData[2] * AlphaPicker),
                        Helpers.ColorAlpha(COBlack, Alpha * AdditionData[2] * AlphaPicker),
                        2
                    )

                    local PickerPos = PickerVector + vector(Menu.RenderComponents.Data["ColorEdit"].Saturation[Name] * PickerSize.x, (1 - Menu.RenderComponents.Data["ColorEdit"].Value[Name]) * PickerSize.y)
                    render.circle_outline(
                        PickerPos,
                        Helpers.ColorAlpha(color(230, 230, 230, 255), Alpha * AdditionData[2] * AlphaPicker),
                        5,
                        90,
                        1,
                        1
                    )
                    render.circle(
                        PickerPos,
                        Helpers.ColorAlpha(color(Value.r, Value.g, Value.b, 255), Alpha * AdditionData[2] * AlphaPicker),
                        4,
                        90,
                        1
                    )

                    --
                    -- @ hex
                    local HexValue = Helpers.RGBtoHex(ItemPoint.Value:clone())
                    local CopyPasteSize = {
                        Copy = render.measure_text(AdditionData[1], nil, "Copy"),
                        Paste = render.measure_text(AdditionData[1], nil, "Paste"),
                        Default = render.measure_text(AdditionData[1], nil, "Default")
                    }

                    render.text(AdditionData[1], PickerVector + vector(0, PickerSize.y + (BoxAdd / 2)), Helpers.ColorAlpha(MenuColors.ColorPickerButtons, Alpha * AdditionData[2] * AlphaPicker), nil, "Copy")
                    render.text(AdditionData[1], PickerVector + vector(10 + CopyPasteSize.Copy.x, PickerSize.y + (BoxAdd / 2)), Helpers.ColorAlpha(MenuColors.ColorPickerButtons, Alpha * AdditionData[2] * AlphaPicker), nil, "Paste")

                    render.text(AdditionData[1], PickerVector + vector(20 + CopyPasteSize.Copy.x + CopyPasteSize.Paste.x, PickerSize.y + (BoxAdd / 2)), Helpers.ColorAlpha(MenuColors.ColorPickerButtons, Alpha * AdditionData[2] * AlphaPicker), nil, "Default")

                    local IsHoveredCopy = Helpers.IsInBox(PickerVector + vector(0, PickerSize.y + (BoxAdd / 2)), CopyPasteSize.Copy.x, CopyPasteSize.Copy.y)
                    local IsHoveredPaste = Helpers.IsInBox(PickerVector + vector(10 + CopyPasteSize.Copy.x, PickerSize.y + (BoxAdd / 2)), CopyPasteSize.Paste.x, CopyPasteSize.Paste.y)

                    local IsHoveredDefault = Helpers.IsInBox(PickerVector + vector(20 + CopyPasteSize.Copy.x + CopyPasteSize.Paste.x, PickerSize.y + (BoxAdd / 2)), CopyPasteSize.Default.x, CopyPasteSize.Default.y)

                    if IsHoveredDefault then
                        if not Menu.RenderComponents.InteractData.IsHue and not Menu.RenderComponents.InteractData.IsValueSaturation and not Menu.RenderComponents.InteractData.IsAlpha then
                            if common.is_button_down(1) and globals.realtime > Menu.GlobalTime + 0.2 then 
                                Menu.GlobalTime = globals.realtime

                                Menu.RenderComponents.Data["ColorEdit"].Hue[Name], Menu.RenderComponents.Data["ColorEdit"].Saturation[Name], Menu.RenderComponents.Data["ColorEdit"].Value[Name], Menu.RenderComponents.Data["ColorEdit"].Alpha[Name] = Helpers.RGBtoHSV(DefaultColor.r, DefaultColor.g, DefaultColor.b, DefaultColor.a)
                                native_PlaySound("resource/warning.wav", 1, 100, 0, 0)
                            end
                        end
                    end

                    if IsHoveredCopy then
                        if not Menu.RenderComponents.InteractData.IsHue and not Menu.RenderComponents.InteractData.IsValueSaturation and not Menu.RenderComponents.InteractData.IsAlpha then
                            if common.is_button_down(1) and globals.realtime > Menu.GlobalTime + 0.2 then 
                                Menu.GlobalTime = globals.realtime

                                Clipboard.Export(HexValue)
                                table_insert(Menu.MenuData.Logs, {"Copied Color", Files.image_LoadColorMenu, 0, globals.realtime})
                                native_PlaySound("resource/warning.wav", 1, 100, 0, 0)
                            end
                        end
                    end

                    if IsHoveredPaste then
                        if not Menu.RenderComponents.InteractData.IsHue and not Menu.RenderComponents.InteractData.IsValueSaturation and not Menu.RenderComponents.InteractData.IsAlpha then
                            if common.is_button_down(1) and globals.realtime > Menu.GlobalTime + 0.2 then 
                                Menu.GlobalTime = globals.realtime

                                local NewColor1 = Helpers.HexToRGB(Clipboard.Import())
                                
                                Menu.RenderComponents.Data["ColorEdit"].Hue[Name], Menu.RenderComponents.Data["ColorEdit"].Saturation[Name], Menu.RenderComponents.Data["ColorEdit"].Value[Name], Menu.RenderComponents.Data["ColorEdit"].Alpha[Name] = Helpers.RGBtoHSV(NewColor1.r, NewColor1.g, NewColor1.b, NewColor1.a)
                                table_insert(Menu.MenuData.Logs, {"Pasted Color", Files.image_LoadColorMenu, 0, globals.realtime})
                                native_PlaySound("resource/warning.wav", 1, 100, 0, 0)
                            end
                        end
                    end

                    local IsHoveredValueSaturation = Helpers.IsInBox(PickerVector, PickerSize.x, PickerSize.y)
                    local IsHoveredHue = Helpers.IsInBox(PickerVector + vector(PickerSize.x + (BoxAdd / 4) - HuePickerWidth, 0), HuePickerWidth * 2, PickerSize.y)
                    local IsHoveredAlpha = Helpers.IsInBox(PickerVector + vector(0, PickerSize.y + (BoxAdd / 4) - HuePickerWidth), PickerSize.x, HuePickerWidth * 2)

                    --@value & saturation
                    if common.is_button_down(1) and not Menu.RenderComponents.InteractData.IsHue and not Menu.RenderComponents.InteractData.IsValueSaturation and not Menu.RenderComponents.InteractData.IsAlpha then
                        if IsHoveredValueSaturation then
                            Menu.RenderComponents.InteractData.IsValueSaturation = true
                        end
                    elseif not common.is_button_down(1) and not Menu.RenderComponents.InteractData.IsHue and Menu.RenderComponents.InteractData.IsValueSaturation and not Menu.RenderComponents.InteractData.IsAlpha then
                        Menu.RenderComponents.InteractData.IsValueSaturation = false
                    end

                    if Menu.RenderComponents.InteractData.IsValueSaturation then
                        local MousePosInCanvas = vector(Mouse.x - PickerVector.x, Mouse.y - PickerVector.y)

                        -- << clamp >>
                        if MousePosInCanvas.x < 0 then
                            MousePosInCanvas.x = 0
                        elseif MousePosInCanvas.x > PickerSize.x - 1 then
                            MousePosInCanvas.x = PickerSize.x - 1
                        end

                        if MousePosInCanvas.y < 0 then
                            MousePosInCanvas.y = 0
                        elseif MousePosInCanvas.y > PickerSize.y - 1 then
                            MousePosInCanvas.y = PickerSize.y - 1
                        end
                        
                        Menu.RenderComponents.Data["ColorEdit"].Value[Name] = 1 - (MousePosInCanvas.y / (PickerSize.y - 1))
                        Menu.RenderComponents.Data["ColorEdit"].Saturation[Name] = (MousePosInCanvas.x / (PickerSize.x - 1))
                    end

                    --@hue
                    if common.is_button_down(1) and not Menu.RenderComponents.InteractData.IsHue and not Menu.RenderComponents.InteractData.IsValueSaturation and not Menu.RenderComponents.InteractData.IsAlpha then
                        if IsHoveredHue then
                            Menu.RenderComponents.InteractData.IsHue = true
                        end
                    elseif not common.is_button_down(1) and Menu.RenderComponents.InteractData.IsHue and not Menu.RenderComponents.InteractData.IsValueSaturation and not Menu.RenderComponents.InteractData.IsAlpha then
                        Menu.RenderComponents.InteractData.IsHue = false
                    end

                    if Menu.RenderComponents.InteractData.IsHue then
                        local NewVec = PickerVector + vector(PickerSize.x + (BoxAdd / 4), 0)
                        local MousePosInCanvas = vector(Mouse.x - NewVec.x, Mouse.y - NewVec.y)

                        -- /* Previous horizontal bar will represent hue=1 (bottom) as hue=0 (top). Since both colors are red, we clamp at (-2, above edge) to avoid visual continuities */
                        if MousePosInCanvas.y < 0 then
                            MousePosInCanvas.y = 0
                        elseif MousePosInCanvas.y > PickerSize.y - 2 then
                            MousePosInCanvas.y = PickerSize.y - 2 
                        end

                        Menu.RenderComponents.Data["ColorEdit"].Hue[Name] = (MousePosInCanvas.y / (PickerSize.y - 1))
                    end

                    --@alpha
                    if common.is_button_down(1) and not Menu.RenderComponents.InteractData.IsHue and not Menu.RenderComponents.InteractData.IsValueSaturation and not Menu.RenderComponents.InteractData.IsAlpha then
                        if IsHoveredAlpha then
                            Menu.RenderComponents.InteractData.IsAlpha = true
                        end
                    elseif not common.is_button_down(1) and not Menu.RenderComponents.InteractData.IsHue and not Menu.RenderComponents.InteractData.IsValueSaturation and Menu.RenderComponents.InteractData.IsAlpha then
                        Menu.RenderComponents.InteractData.IsAlpha = false
                    end

                    if Menu.RenderComponents.InteractData.IsAlpha then
                        local NewVec = PickerVector + vector(0, PickerSize.y + (BoxAdd / 4))
                        local MousePosInCanvas = vector(Mouse.x - NewVec.x, Mouse.y - NewVec.y)

                        if MousePosInCanvas.x < 0 then
                            MousePosInCanvas.x = 0
                        elseif MousePosInCanvas.x > PickerSize.x - 1 then
                            MousePosInCanvas.x = PickerSize.x - 1
                        end

                        Menu.RenderComponents.Data["ColorEdit"].Alpha[Name] = (MousePosInCanvas.x / (PickerSize.x - 1))
                    end

                    local NewColor = color(255, Menu.RenderComponents.Data["ColorEdit"].Alpha[Name]*255)
                    NewColor.r, NewColor.g, NewColor.b = Helpers.HSVtoRGB(Menu.RenderComponents.Data["ColorEdit"].Hue[Name], Menu.RenderComponents.Data["ColorEdit"].Saturation[Name], Menu.RenderComponents.Data["ColorEdit"].Value[Name])

                    ItemPoint.Value = NewColor
                end

            end


            --Menu.RenderComponents.Data["ColorEdit"].Hue
            --Menu.RenderComponents.Data["ColorEdit"].Saturation
            --Menu.RenderComponents.Data["ColorEdit"].Value

            


            return 1, (Menu.Render.SpaceUI*2+(AdditionData[4] - Menu.Render.MenuBorder * 6))*(Menu.RenderComponents.InteractData.ColorOpen == Name and 1 or 0)
        end,

        ["KeyBind"] = function(RenderVector, ItemPoint, Alpha, ...)
            local AdditionData = {...}
            local Mouse = ui.get_mouse_position()
            local Name = ItemPoint.Name
            local Value = ItemPoint.Value
            local TableData = ItemPoint.ExternalData
            local Icon = Files.image_LoadKeyBind

            render.text(AdditionData[1], RenderVector, Helpers.ColorAlpha(MenuColors.KeybindText, Alpha * AdditionData[2]), nil, Name)

            --create empty value to fade
            if Menu.RenderComponents.Data["KeyBind"].Fade.Length[Name] == nil then
                Menu.RenderComponents.Data["KeyBind"].Fade.Length[Name] = 0
            end

            if Menu.RenderComponents.Data["KeyBind"].Fade.Open[Name] == nil then
                Menu.RenderComponents.Data["KeyBind"].Fade.Open[Name] = 0
            end

            if Menu.RenderComponents.Data["KeyBind"].Fade.ColorChange[Name] == nil then
                Menu.RenderComponents.Data["KeyBind"].Fade.ColorChange[Name] = color(255, 255)
            end

            


            local KeyName = ""
            for Index, Key in pairs(Menu.VirtualKeysNames) do
                if Key[1] == Value then
                    KeyName = Key[2]
                    break
                end
            end
            if KeyName == "" then
                --KeyName = "Error"
                error("Error in Keybind " .. tostring(ItemPoint.Name) .. " Value")
            end

            local ValueSize = render.measure_text(AdditionData[1], nil, KeyName)
            Menu.RenderComponents.Data["KeyBind"].Fade.Length[Name] = Helpers.Lerp(Menu.RenderComponents.Data["KeyBind"].Fade.Length[Name], ValueSize.x + 8, 40)

            if AdditionData[2] ~= 0 then
                render.rect(RenderVector + vector(AdditionData[4] - Menu.Render.MenuBorder * 2 - (Menu.Render.SpaceUI-4) - Menu.RenderComponents.Data["KeyBind"].Fade.Length[Name] - Menu.RenderComponents.Data["KeyBind"].Fade.Open[Name], 0), RenderVector + vector(AdditionData[4] - Menu.Render.MenuBorder * 2, (Menu.Render.SpaceUI-4)), Helpers.ColorAlpha(MenuColors.KeybindBackground, Alpha * AdditionData[2]), 3)
                render.gradient(RenderVector + vector(AdditionData[4] - Menu.Render.MenuBorder * 2 - (Menu.Render.SpaceUI-4), 0), RenderVector + vector(AdditionData[4] - Menu.Render.MenuBorder * 2, (Menu.Render.SpaceUI-4)), Helpers.ColorAlpha(MenuColors.KeybindGradient[1], Alpha * AdditionData[2]), Helpers.ColorAlpha(MenuColors.KeybindGradient[2], Alpha * AdditionData[2]), Helpers.ColorAlpha(MenuColors.KeybindGradient[3], Alpha * AdditionData[2]), Helpers.ColorAlpha(MenuColors.KeybindGradient[4], Alpha * AdditionData[2]), 3)

                render.texture(Icon.Image, RenderVector + vector(AdditionData[4] - Menu.Render.MenuBorder * 2 - (Menu.Render.SpaceUI-4)/2 - Icon.Size.x/2, (Menu.Render.SpaceUI)/2 - Icon.Size.y/2 - 2), Icon.Size, Helpers.ColorAlpha(MenuColors.KeybindIcon, Alpha * AdditionData[2]))
                --render.circle_gradient(RenderVector + vector(AdditionData[4] - Menu.Render.MenuBorder * 2 - (Menu.Render.SpaceUI-4)*1.5, Menu.Render.SpaceUI/2 - 2), Helpers.ColorAlpha(color(Value.r, Value.g, Value.b, 255), Alpha * AdditionData[2]), Helpers.ColorAlpha(Value:clone(), Alpha * AdditionData[2]), 5, 0, 1)

                render.text(AdditionData[1], RenderVector + vector(AdditionData[4] - Menu.Render.MenuBorder * 2 - (Menu.Render.SpaceUI-4) - ValueSize.x - 4, 0), Helpers.ColorAlpha(Menu.RenderComponents.Data["KeyBind"].Fade.ColorChange[Name], Alpha * AdditionData[2]), nil, KeyName)

                --use mechanic
                local IsHoveredKey = Helpers.IsInBox(RenderVector + vector(AdditionData[4] - Menu.Render.MenuBorder * 2 - (Menu.Render.SpaceUI-4) - Menu.RenderComponents.Data["KeyBind"].Fade.Length[Name] - Menu.RenderComponents.Data["KeyBind"].Fade.Open[Name], 0), Menu.RenderComponents.Data["KeyBind"].Fade.Length[Name] + (Menu.Render.SpaceUI-4) + Menu.RenderComponents.Data["KeyBind"].Fade.Open[Name], (Menu.Render.SpaceUI-4))

                if common.is_button_down(1) and Visuals.Move.IsPosible() and Menu.RenderComponents.InteractData.Slider == "" and not Helpers.Contains(Menu.RenderComponents.InteractData.ListOpen, true) and not Helpers.Contains(Menu.RenderComponents.InteractData.MultiListOpen, true) and not Menu.RenderComponents.InteractData.IsHue and not Menu.RenderComponents.InteractData.IsValueSaturation and not Menu.RenderComponents.InteractData.IsAlpha and Menu.RenderComponents.InteractData.ColorOpen == "" then
                    if IsHoveredKey then
                        if Menu.RenderComponents.InteractData.BindSelection == "" and Menu.RenderComponents.InteractData.BindTypeSelection == "" then
                            Menu.RenderComponents.InteractData.BindSelection = Name
                        end
                    else
                        if Menu.RenderComponents.InteractData.BindSelection == Name then
                            Menu.RenderComponents.InteractData.BindSelection = ""
                        end
                    end
                end

                if common.is_button_down(2) and Visuals.Move.IsPosible() and Menu.RenderComponents.InteractData.Slider == "" and not Helpers.Contains(Menu.RenderComponents.InteractData.ListOpen, true) and not Helpers.Contains(Menu.RenderComponents.InteractData.MultiListOpen, true) and not Menu.RenderComponents.InteractData.IsHue and not Menu.RenderComponents.InteractData.IsValueSaturation and not Menu.RenderComponents.InteractData.IsAlpha and Menu.RenderComponents.InteractData.ColorOpen == "" then
                    if IsHoveredKey then
                        if Menu.RenderComponents.InteractData.BindTypeSelection == "" then
                            if TableData.IsDisabled ~= true then
                                if globals.realtime > Menu.GlobalTime + 0.2 then
                                    Menu.GlobalTime = globals.realtime
                                    Menu.RenderComponents.InteractData.BindTypeSelection = Name
                                end
                            end
                        end
                    end
                        
                    if Menu.RenderComponents.InteractData.BindTypeSelection == Name then
                        if globals.realtime > Menu.GlobalTime + 0.2 then
                            Menu.GlobalTime = globals.realtime
                            Menu.RenderComponents.InteractData.BindTypeSelection = ""
                        end
                    end
                end

                if common.is_button_down(1) and not IsHoveredKey then
                    if Menu.RenderComponents.InteractData.BindTypeSelection == Name then
                        if globals.realtime > Menu.GlobalTime + 0.2 then
                            Menu.GlobalTime = globals.realtime
                            Menu.RenderComponents.InteractData.BindTypeSelection = ""
                        end
                    end
                end

                

                Menu.RenderComponents.Data["KeyBind"].Fade.ColorChange[Name] = Helpers.Lerp(Menu.RenderComponents.Data["KeyBind"].Fade.ColorChange[Name], Menu.RenderComponents.InteractData.BindSelection == Name and MenuColors.KeybindBinding or MenuColors.KeybindKey, 20)

                if Menu.RenderComponents.InteractData.BindSelection == Name then
                    for Index, Key in pairs(Menu.VirtualKeysNames) do
                        if common.is_button_down(Key[1]) then
                            ItemPoint.Value = Key[1]
                            Menu.RenderComponents.InteractData.BindSelection = ""
                            break
                        end
                    end
                end

                


                if TableData.IsDisabled ~= true then
                    local Xadd = 0
                    if Menu.RenderComponents.InteractData.BindTypeSelection == Name then
                        Xadd = Menu.Render.MenuBorder*0.75
                        for Index, Mod in pairs(Menu.RenderComponents.Data["KeyBind"].Modes) do
                            local MdSize = render.measure_text(AdditionData[1], nil, Mod[1])

                            if common.is_button_down(1) and Helpers.IsInBox(RenderVector + vector(AdditionData[4] - Menu.Render.MenuBorder * 3 - (Menu.Render.SpaceUI-4) - ValueSize.x - 4 - MdSize.x - Xadd, 0), MdSize.x, MdSize.y) then
                                TableData.KeyType = Mod[2]
                            end

                            render.text(AdditionData[1], RenderVector + vector(AdditionData[4] - Menu.Render.MenuBorder * 3 - (Menu.Render.SpaceUI-4) - ValueSize.x - 4 - MdSize.x - Xadd, 0), Helpers.ColorAlpha(TableData.KeyType == Mod[2] and MenuColors.KeybindModeActive or MenuColors.KeybindModeInactive, Alpha * AdditionData[2]), nil,  Mod[1])
                            Xadd = Xadd + MdSize.x + Menu.Render.MenuBorder
                        end
                    end
                    Menu.RenderComponents.Data["KeyBind"].Fade.Open[Name] = Helpers.Lerp(Menu.RenderComponents.Data["KeyBind"].Fade.Open[Name], Xadd, 20)
                end

            end

            Menu.Keybinds.Data[Name].Type = TableData.KeyType

            return 1, 0
        end,

        ["Button"] = function(RenderVector, ItemPoint, Alpha, ...)
            local AdditionData = {...}
            local Mouse = ui.get_mouse_position()
            local Name = ItemPoint.Name
            local TableData = ItemPoint.ExternalData

            local IconSpace = TableData.Icon and (Menu.Render.SpaceUI-4) + Menu.Render.MenuBorder or 0 
            local NameSpace = render.measure_text(AdditionData[1], nil, Name)

            if Menu.RenderComponents.Data["Button"].Fade.Open[Name] == nil then
                Menu.RenderComponents.Data["Button"].Fade.Open[Name] = 0
            end

            local HoveredAddition = false --// we will use it to create anim on hover and press

            if AdditionData[2] ~= 0 then
                if IconSpace ~= 0 then 
                    render.gradient(RenderVector, RenderVector + vector((Menu.Render.SpaceUI-4), (Menu.Render.SpaceUI-4)), Helpers.ColorAlpha(MenuColors.ButtonGradient[1], Alpha * AdditionData[2]), Helpers.ColorAlpha(MenuColors.ButtonGradient[2], Alpha * AdditionData[2]), Helpers.ColorAlpha(MenuColors.ButtonGradient[3], Alpha * AdditionData[2]), Helpers.ColorAlpha(MenuColors.ButtonGradient[4], Alpha * AdditionData[2]), 3)
                    render.texture(TableData.Icon.Image, RenderVector + vector((Menu.Render.SpaceUI-4) / 2 - TableData.Icon.Size.x/2, (Menu.Render.SpaceUI-4)/2 - TableData.Icon.Size.y/2), TableData.Icon.Size, Helpers.ColorAlpha(MenuColors.ButtonIcon, Alpha * AdditionData[2]))
                end

                render.rect(RenderVector + vector(IconSpace + Menu.RenderComponents.Data["Button"].Fade.Open[Name], 0), RenderVector + vector(IconSpace + NameSpace.x + 10 + Menu.RenderComponents.Data["Button"].Fade.Open[Name], (Menu.Render.SpaceUI-4)), Helpers.ColorAlpha(MenuColors.ButtonBackground, Alpha * AdditionData[2]), 3)
                render.text(AdditionData[1], RenderVector + vector(IconSpace + Menu.RenderComponents.Data["Button"].Fade.Open[Name] + 5, (Menu.Render.SpaceUI-4) / 2 - NameSpace.y / 2), Helpers.ColorAlpha(MenuColors.ButtonText, Alpha * AdditionData[2]), nil, Name)

                local Hovered = Helpers.IsInBox(RenderVector, IconSpace + NameSpace.x + 30, (Menu.Render.SpaceUI-4))

                if Hovered then
                    if Visuals.Move.IsPosible() and Menu.RenderComponents.InteractData.Slider == "" and not Helpers.Contains(Menu.RenderComponents.InteractData.ListOpen, true) and not Helpers.Contains(Menu.RenderComponents.InteractData.MultiListOpen, true) and not Menu.RenderComponents.InteractData.IsHue and not Menu.RenderComponents.InteractData.IsValueSaturation and not Menu.RenderComponents.InteractData.IsAlpha and Menu.RenderComponents.InteractData.ColorOpen == "" and Menu.RenderComponents.InteractData.BindTypeSelection == "" then
                        if common.is_button_down(1) and globals.realtime > Menu.GlobalTime + 0.2 then
                            Menu.GlobalTime = globals.realtime
                            TableData.ToRun()
                            Menu.RenderComponents.Data["Button"].Fade.Open[Name] = 40
                        end
                        HoveredAddition = true
                    end
                end

                --animate 
                Menu.RenderComponents.Data["Button"].Fade.Open[Name] = Helpers.Lerp(Menu.RenderComponents.Data["Button"].Fade.Open[Name], HoveredAddition and 20 or 0, 20)
            end


            return 1, 0
        end
    }

    --@menu render
    Menu.Render = {}
    Menu.Render.AdditionData = {}
    Menu.Render.GetYAxis = function(SubTabPoint)
        local ReturnY = 0
        for Index, Point in pairs(SubTabPoint) do
            local ItemSig = "UwUDaddy$" .. Point.Name
            if Menu.Render.AdditionData[ItemSig] == nil then
                Menu.Render.AdditionData[ItemSig] = 0
            end

            Menu.Render.AdditionData[ItemSig] = Helpers.Lerp(Menu.Render.AdditionData[ItemSig], Point.Visible() and 1 or 0, 20)
            local DontForgetToAdd = (Point.Type == "Slider" or Point.Type == "ListBox" or Point.Type == "MultiListBox") and 2 or 1

            ReturnY = ReturnY + DontForgetToAdd * Menu.Render.AdditionData[ItemSig]
        end

        return ReturnY
    end

    --@init function 
    Menu.Render.Init = function()
        Menu.Render.MenuWidth = Menu.Neverlose.BoxAddX:get() -- Menu.Render.MenuWidth--500
        Menu.Render.Length = Menu.Neverlose.BoxAddY:get()--500
        Menu.Render.Add = 0
        Menu.Render.LengthFade = 500
        Menu.Render.TabsSpace = Menu.Render.MenuWidth * 0.4
        Menu.Render.MenuBorder = 10
        Menu.Render.ActiveHalfWindowSize = 0
        Menu.Render.SaveData = (Menu.Render.MenuWidth - Menu.Render.MenuBorder * 3 - Menu.Render.TabsSpace)

        Menu.Render.MenuVectorFadeX = 0
        Menu.Render.MenuVectorFadeY = 0
        Menu.Render.MenuVectorMoveX = 0
        Menu.Render.MenuVectorMoveY = 0

        Menu.Render.MenuVectorSizeX = 0
        Menu.Render.MenuVectorSizeY = 0

        Menu.Render.FadeBackGround = 0
        Menu.Render.FadeComponents = 0

        --fonts
        Menu.Render.FontMain = Files.LoadFont(Files.DownloadFiles.FontMenu, 18, 'ba')
        Menu.Render.FontUserName = Files.LoadFont(Files.DownloadFiles.FontMenu, 18, 'ba')
        Menu.Render.FontSubTab = Files.LoadFont(Files.DownloadFiles.FontMenu, 18, 'ba')
        Menu.Render.FontUIComponents = Files.LoadFont(Files.DownloadFiles.FontMenu, 16, 'a')
        
        --colors 
        Menu.Render.ThemeModeColor = {
            Light = color(255, 255),
            Dark = color(255, 255),
            Custom = color(255, 255),
            ActiveMode = "Light"
        }
        Menu.Render.ActiveColor = {
            color(163, 42, 163, 255),
            color(201,30,138,255),
            color(115,55,160,255),
            color(155,57,156,255)
        }
        
        Menu.Render.ActiveTab = "RageBot"
        Menu.Render.TabsFade = {}
        Menu.Render.SubTabsFade = {}

        Menu.Render.FadeUI = {}
        Menu.Render.FadeVisibleUI = {Full = {}, Half = {}}
        Menu.Render.SpaceUI = 20

        Menu.Render.IconCload = vector(40, 26)

    end

    Menu.Render.VisualsChanges = function()
        Menu.Render.MenuWidth = Menu.Neverlose.BoxAddX:get() 
        Menu.Render.Length = Menu.Neverlose.BoxAddY:get()--500
        Menu.Render.TabsSpace = Menu.Render.MenuWidth * 0.4
        Menu.Render.SaveData = (Menu.Render.MenuWidth - Menu.Render.MenuBorder * 3 - Menu.Render.TabsSpace)

        Menu.Render.FadeBackGround = Helpers.Lerp(Menu.Render.FadeBackGround, ui.get_alpha(), 20)

        Menu.Render.FadeComponents = Helpers.Lerp(Menu.Render.FadeComponents, Menu.Render.FadeBackGround == 1 and 1 or 0, 20)
        Menu.Render.Add = 0
        if Menu.IsSomeComponentsShowen[Menu.Render.ActiveTab] ~= nil then
            if (Menu.Render.GetYAxis(Menu.IsSomeComponentsShowen[Menu.Render.ActiveTab]) * Menu.Render.SpaceUI) > (Menu.Render.Length - (Menu.Render.MenuBorder * 4 + Menu.Render.IconCload.y * 2)) then
                Menu.Render.Add = Menu.Render.GetYAxis(Menu.IsSomeComponentsShowen[Menu.Render.ActiveTab]) * Menu.Render.SpaceUI + (Menu.Render.MenuBorder * 5 + Menu.Render.IconCload.y * 2) - Menu.Render.Length 
            end
        end

        Menu.Render.LengthFade = Helpers.Lerp(Menu.Render.LengthFade, Menu.Render.Length + Menu.Render.Add, 20)

        MenuColors.MainColor = Helpers.Lerp(MenuColors.MainColor, Menu.Neverlose.MainColor:get(), 20)
        
        Menu.Render.MenuVectorFadeX = Menu.Neverlose.MenuVectorX:get()
        Menu.Render.MenuVectorFadeY = Menu.Neverlose.MenuVectorY:get()

        Menu.Render.ActiveColor[1] = Helpers.Lerp(Menu.Render.ActiveColor[1], MenuColors.MainColor, 20)
        Menu.Render.ActiveColor[0] = color(0, 0, 0, 255)
        Menu.Render.ActiveColor[2] = Menu.Render.ActiveColor[1]
        Menu.Render.ActiveColor[3] = color(0, 0, 0, 255)

        local AnimFadeSpeed = 10
        -- @ colors
        MenuColors.BackGroundTopLeft = Helpers.Lerp(MenuColors.BackGroundTopLeft, Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["BackGround Top Left"]:clone() or color(56, 51, 57, 255), AnimFadeSpeed)
        MenuColors.BackGroundTopRight = Helpers.Lerp(MenuColors.BackGroundTopRight, Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["BackGround Top Right"]:clone() or color(1, 1, 0, 255), AnimFadeSpeed)
        MenuColors.BackGroundBottomLeft = Helpers.Lerp(MenuColors.BackGroundBottomLeft, Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["BackGround Bottom Left"]:clone() or color(1, 1, 0, 255), AnimFadeSpeed)
        MenuColors.BackGroundMove = Helpers.Lerp(MenuColors.BackGroundMove, Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and (Visuals.Move.Objects.MenuSize and Menu.DataUI["Misc"]["Menu"]["BackGround Move Active"]:clone() or Menu.DataUI["Misc"]["Menu"]["BackGround Move Inactive"]:clone()) or (Visuals.Move.Objects.MenuSize and color(56, 1, 1, 255) or color(56, 51, 57, 255)), AnimFadeSpeed)
        MenuColors.BackGroundOutLine = Helpers.Lerp(MenuColors.BackGroundOutLine, Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["BackGround OutLine"]:clone() or color(67, 63, 64, 255), AnimFadeSpeed)
        MenuColors.IconCoverBackGround[1] = Helpers.Lerp(MenuColors.IconCoverBackGround[1], Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Icon Top Left"]:clone() or color(0, 255), AnimFadeSpeed)
        MenuColors.IconCoverBackGround[2] = Helpers.Lerp(MenuColors.IconCoverBackGround[2], Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Icon Top Right"]:clone() or MenuColors.MainColor, AnimFadeSpeed)
        MenuColors.IconCoverBackGround[3] = Helpers.Lerp(MenuColors.IconCoverBackGround[3], Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Icon Bottom Left"]:clone() or MenuColors.MainColor, AnimFadeSpeed)
        MenuColors.IconCoverBackGround[4] = Helpers.Lerp(MenuColors.IconCoverBackGround[4], Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Icon Bottom Right"]:clone() or color(0, 255), AnimFadeSpeed)
        MenuColors.IconBackground = Helpers.Lerp(MenuColors.IconBackground, Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Icon Background"]:clone() or color(37, 33, 34, 255 * 0.4), AnimFadeSpeed)
        MenuColors.IconOutline = Helpers.Lerp(MenuColors.IconOutline, Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Icon OutLine"]:clone() or color(67, 63, 64, 255 * 0.5), AnimFadeSpeed)
        MenuColors.DigitalText = Helpers.Lerp(MenuColors.DigitalText, Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Digital Text"]:clone() or color(255, 255), AnimFadeSpeed)
        MenuColors.DreamsText = Helpers.Lerp(MenuColors.DreamsText, Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Dreams Text"]:clone() or MenuColors.MainColor, AnimFadeSpeed)
        MenuColors.TabsSelectGradient[1] = Helpers.Lerp(MenuColors.TabsSelectGradient[1], Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Tabs Select Top Left"]:clone() or color(0, 255), AnimFadeSpeed)
        MenuColors.TabsSelectGradient[2] = Helpers.Lerp(MenuColors.TabsSelectGradient[2], Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Tabs Select Top Right"]:clone() or MenuColors.MainColor, AnimFadeSpeed)
        MenuColors.TabsSelectGradient[3] = Helpers.Lerp(MenuColors.TabsSelectGradient[3], Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Tabs Select Bottom Left"]:clone() or MenuColors.MainColor, AnimFadeSpeed)
        MenuColors.TabsSelectGradient[4] = Helpers.Lerp(MenuColors.TabsSelectGradient[4], Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Tabs Select Bottom Right"]:clone() or color(0, 255), AnimFadeSpeed)
        MenuColors.BackGroundTabs = Helpers.Lerp(MenuColors.BackGroundTabs, Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["BackGround Tabs"]:clone() or color(37, 33, 34, 255 * 0.4), AnimFadeSpeed)
        MenuColors.TabsOutLine = Helpers.Lerp(MenuColors.TabsOutLine, Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Tabs OutLine"]:clone() or color(67, 63, 64, 255 * 0.5), AnimFadeSpeed)
        MenuColors.TabsIcon = Helpers.Lerp(MenuColors.TabsIcon, Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Tabs Icon"]:clone() or color(255, 255), AnimFadeSpeed)
        MenuColors.BackGroundSubTabs = Helpers.Lerp(MenuColors.BackGroundSubTabs, Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["BackGround SubTabs"]:clone() or color(37, 33, 34, 255 * 0.4), AnimFadeSpeed)
        MenuColors.SubTabsOutLine = Helpers.Lerp(MenuColors.SubTabsOutLine, Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["SubTabs OutLine"]:clone() or color(67, 63, 64, 255 * 0.5), AnimFadeSpeed)
        MenuColors.SubTabsSelectGradient[1] = Helpers.Lerp(MenuColors.SubTabsSelectGradient[1], Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["SubTabs Select Top Left"]:clone() or color(0, 255), AnimFadeSpeed)
        MenuColors.SubTabsSelectGradient[2] = Helpers.Lerp(MenuColors.SubTabsSelectGradient[2], Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["SubTabs Select Top Right"]:clone() or MenuColors.MainColor, AnimFadeSpeed)
        MenuColors.SubTabsSelectGradient[3] = Helpers.Lerp(MenuColors.SubTabsSelectGradient[2], Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["SubTabs Select Bottom Left"]:clone() or MenuColors.MainColor, AnimFadeSpeed)
        MenuColors.SubTabsSelectGradient[4] = Helpers.Lerp(MenuColors.SubTabsSelectGradient[4], Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["SubTabs Select Bottom Right"]:clone() or color(0, 255), AnimFadeSpeed)
        MenuColors.SubTabsIcon = Helpers.Lerp(MenuColors.SubTabsIcon, Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["SubTabs Icon"]:clone() or color(255, 255), AnimFadeSpeed)
        MenuColors.SubTabsText = Helpers.Lerp(MenuColors.SubTabsText, Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["SubTabs Text"]:clone() or color(255, 255), AnimFadeSpeed)
        MenuColors.BackGroundUI = Helpers.Lerp(MenuColors.BackGroundUI, Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["BackGround UI"]:clone() or color(37, 33, 34, 255 * 0.4), AnimFadeSpeed)
        MenuColors.UIOutLine = Helpers.Lerp(MenuColors.UIOutLine, Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["UI OutLine"]:clone() or color(67, 63, 64, 255 * 0.5), AnimFadeSpeed)
        MenuColors.CheckBoxInactive = Helpers.Lerp(MenuColors.CheckBoxInactive, Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["CheckBox Inactive"]:clone() or color(50, 255), AnimFadeSpeed)
        MenuColors.CheckBoxActive = Helpers.Lerp(MenuColors.CheckBoxActive, Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["CheckBox Active"]:clone() or MenuColors.MainColor, AnimFadeSpeed)
        MenuColors.CheckBoxBackgroundInactive = Helpers.Lerp(MenuColors.CheckBoxBackgroundInactive, Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["CheckBox Background Inactive"]:clone() or color(30, 255), AnimFadeSpeed)
        MenuColors.CheckBoxBackgroundActive = Helpers.Lerp(MenuColors.CheckBoxBackgroundActive, Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["CheckBox Background Active"]:clone() or Helpers.ColorAlpha(MenuColors.MainColor, 0.5), AnimFadeSpeed)
        MenuColors.CheckBoxText = Helpers.Lerp(MenuColors.CheckBoxText, Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["CheckBox Text"]:clone() or color(255, 255), AnimFadeSpeed)
        MenuColors.SliderText = Helpers.Lerp(MenuColors.SliderText, Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Slider Text"]:clone() or color(255, 255), AnimFadeSpeed)
        MenuColors.SliderValeText = Helpers.Lerp(MenuColors.SliderValeText, Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Slider Vale Text"]:clone() or color(255, 255), AnimFadeSpeed)
        MenuColors.SliderBackgroundValue = Helpers.Lerp(MenuColors.SliderBackgroundValue, Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Slider Background Value"]:clone() or color(67, 63, 64, 255), AnimFadeSpeed)
        MenuColors.SliderValue = Helpers.Lerp(MenuColors.SliderValue, Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Slider Value"]:clone() or MenuColors.MainColor, AnimFadeSpeed)
        MenuColors.ListBoxBackground = Helpers.Lerp(MenuColors.ListBoxBackground, Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["ListBox Background"]:clone() or color(37, 33, 34, 255), AnimFadeSpeed)
        MenuColors.ListBoxOutline = Helpers.Lerp(MenuColors.ListBoxOutline, Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["ListBox Outline"]:clone() or color(67, 63, 64, 255), AnimFadeSpeed)
        MenuColors.ListBoxOpenBackground = Helpers.Lerp(MenuColors.ListBoxOpenBackground, Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["ListBox Open Background"]:clone() or color(37, 33, 34, 255), AnimFadeSpeed)
        MenuColors.ListBoxOpenOutline = Helpers.Lerp(MenuColors.ListBoxOpenOutline, Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["ListBox Open Outline"]:clone() or color(67, 63, 64, 255), AnimFadeSpeed)
        MenuColors.ListBoxGradient[1] = Helpers.Lerp(MenuColors.ListBoxGradient[1], Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["ListBox Top Left"]:clone() or color(0, 255), AnimFadeSpeed)
        MenuColors.ListBoxGradient[2] = Helpers.Lerp(MenuColors.ListBoxGradient[2], Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["ListBox Top Right"]:clone() or MenuColors.MainColor, AnimFadeSpeed)
        MenuColors.ListBoxGradient[3] = Helpers.Lerp(MenuColors.ListBoxGradient[3], Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["ListBox Bottom Left"]:clone() or MenuColors.MainColor, AnimFadeSpeed)
        MenuColors.ListBoxGradient[4] = Helpers.Lerp(MenuColors.ListBoxGradient[4], Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["ListBox Bottom Right"]:clone() or color(0, 255), AnimFadeSpeed)
        MenuColors.ListBoxIcon = Helpers.Lerp(MenuColors.ListBoxIcon, Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["ListBox Icon"]:clone() or color(255, 255), AnimFadeSpeed)
        MenuColors.ListBoxText = Helpers.Lerp(MenuColors.ListBoxText, Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["ListBox Text"]:clone() or color(255, 255), AnimFadeSpeed)
        MenuColors.ListBoxValue = Helpers.Lerp(MenuColors.ListBoxValue, Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["ListBox Value"]:clone() or color(255, 255), AnimFadeSpeed)
        MenuColors.ListBoxValues = Helpers.Lerp(MenuColors.ListBoxValues, Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["ListBox Values"]:clone() or color(255, 255), AnimFadeSpeed)
        MenuColors.ListBoxSelectedValues = Helpers.Lerp(MenuColors.ListBoxSelectedValues, Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["ListBox Selected Values"]:clone() or MenuColors.MainColor, AnimFadeSpeed)
        MenuColors.ColorPickerBackground = Helpers.Lerp(MenuColors.ColorPickerBackground, Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["ColorPicker Background"]:clone() or color(37, 33, 34, 255), AnimFadeSpeed)
        MenuColors.ColorPickerOpenBackground = Helpers.Lerp(MenuColors.ColorPickerOpenBackground, Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["ColorPicker Open Background"]:clone() or color(37, 33, 34, 255), AnimFadeSpeed)
        MenuColors.ColorPickerGradient[1] = Helpers.Lerp(MenuColors.ColorPickerGradient[1], Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["ColorPicker Top Left"]:clone() or color(0, 255), AnimFadeSpeed)
        MenuColors.ColorPickerGradient[2] = Helpers.Lerp(MenuColors.ColorPickerGradient[2], Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["ColorPicker Top Right"]:clone() or MenuColors.MainColor, AnimFadeSpeed)
        MenuColors.ColorPickerGradient[3] = Helpers.Lerp(MenuColors.ColorPickerGradient[3], Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["ColorPicker Bottom Left"]:clone() or MenuColors.MainColor, AnimFadeSpeed)
        MenuColors.ColorPickerGradient[4] = Helpers.Lerp(MenuColors.ColorPickerGradient[4], Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["ColorPicker Bottom Right"]:clone() or color(0, 255), AnimFadeSpeed)
        MenuColors.ColorPickerIcon = Helpers.Lerp(MenuColors.ColorPickerIcon, Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["ColorPicker Icon"]:clone() or color(255, 255), AnimFadeSpeed)
        MenuColors.ColorPickerText = Helpers.Lerp(MenuColors.ColorPickerText, Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["ColorPicker Text"]:clone() or color(255, 255), AnimFadeSpeed)
        MenuColors.ColorPickerButtons = Helpers.Lerp(MenuColors.ColorPickerButtons, Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["ColorPicker Buttons"]:clone() or color(255, 255), AnimFadeSpeed)
        MenuColors.KeybindBackground = Helpers.Lerp(MenuColors.KeybindBackground, Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Keybind Background"]:clone() or color(37, 33, 34, 255), AnimFadeSpeed)
        MenuColors.KeybindGradient[1] = Helpers.Lerp(MenuColors.KeybindGradient[1], Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Keybind Top Left"]:clone() or color(0, 255), AnimFadeSpeed)
        MenuColors.KeybindGradient[2] = Helpers.Lerp(MenuColors.KeybindGradient[2], Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Keybind Top Right"]:clone() or MenuColors.MainColor, AnimFadeSpeed)
        MenuColors.KeybindGradient[3] = Helpers.Lerp(MenuColors.KeybindGradient[3], Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Keybind Bottom Left"]:clone() or MenuColors.MainColor, AnimFadeSpeed)
        MenuColors.KeybindGradient[4] = Helpers.Lerp(MenuColors.KeybindGradient[4], Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Keybind Bottom Right"]:clone() or color(0, 255), AnimFadeSpeed)
        MenuColors.KeybindIcon = Helpers.Lerp(MenuColors.KeybindIcon, Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Keybind Icon"]:clone() or color(255, 255), AnimFadeSpeed)
        MenuColors.KeybindText = Helpers.Lerp(MenuColors.KeybindText, Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Keybind Text"]:clone() or color(255, 255), AnimFadeSpeed)
        MenuColors.KeybindKey = Helpers.Lerp(MenuColors.KeybindKey, Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Keybind Key"]:clone() or color(255, 255), AnimFadeSpeed)
        MenuColors.KeybindBinding = Helpers.Lerp(MenuColors.KeybindBinding, Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Keybind Binding"]:clone() or color(255, 0, 0, 255), AnimFadeSpeed)
        MenuColors.KeybindModeInactive = Helpers.Lerp(MenuColors.KeybindModeInactive, Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Keybind Mode Inactive"]:clone() or color(255, 255), AnimFadeSpeed)
        MenuColors.KeybindModeActive = Helpers.Lerp(MenuColors.KeybindModeActive, Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Keybind Mode Active"]:clone() or MenuColors.MainColor, AnimFadeSpeed)
        MenuColors.ButtonBackground = Helpers.Lerp(MenuColors.ButtonBackground, Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Button Background"]:clone() or color(37, 33, 34, 255), AnimFadeSpeed)
        MenuColors.ButtonGradient[1] = Helpers.Lerp(MenuColors.ButtonGradient[1], Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Button Top Left"]:clone() or color(0, 255), AnimFadeSpeed)
        MenuColors.ButtonGradient[2] = Helpers.Lerp(MenuColors.ButtonGradient[2], Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Button Top Right"]:clone() or MenuColors.MainColor, AnimFadeSpeed)
        MenuColors.ButtonGradient[3] = Helpers.Lerp(MenuColors.ButtonGradient[3], Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Button Bottom Left"]:clone() or MenuColors.MainColor, AnimFadeSpeed)
        MenuColors.ButtonGradient[4] = Helpers.Lerp(MenuColors.ButtonGradient[4], Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Button Bottom Right"]:clone() or color(0, 255), AnimFadeSpeed)
        MenuColors.ButtonIcon = Helpers.Lerp(MenuColors.ButtonIcon, Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Button Icon"]:clone() or color(255, 255), AnimFadeSpeed)
        MenuColors.ButtonText = Helpers.Lerp(MenuColors.ButtonText, Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Button Text"]:clone() or color(255, 255), AnimFadeSpeed)
        MenuColors.EventBackground = Helpers.Lerp(MenuColors.EventBackground, Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Event Background"]:clone() or color(37, 33, 34, 255 * 0.7), AnimFadeSpeed)
        MenuColors.EventOutline = Helpers.Lerp(MenuColors.EventOutline, Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Event Outline"]:clone() or color(67, 63, 64, 255), AnimFadeSpeed)
        MenuColors.EventIconBackground = Helpers.Lerp(MenuColors.EventIconBackground, Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Event Icon Background"]:clone() or color(37, 33, 34, 255), AnimFadeSpeed)
        MenuColors.EventIcon = Helpers.Lerp(MenuColors.EventIcon, Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Event Icon"]:clone() or color(255, 255), AnimFadeSpeed)
        MenuColors.EventText = Helpers.Lerp(MenuColors.EventText, Menu.DataUI["Misc"]["Menu"]["Menu Theme"] == "Custom" and Menu.DataUI["Misc"]["Menu"]["Event Text"]:clone() or color(255, 255), AnimFadeSpeed)


    end
    
    Menu.Render.Countainer = function(VectorStart, VectprEnd, Alpha, ColorBack, ColorOutline)
        render.rect(VectorStart, VectprEnd, Helpers.ColorAlpha(ColorBack and ColorBack or color(37, 33, 34, 255), Alpha), 5)
        render.rect_outline(VectorStart, VectprEnd, Helpers.ColorAlpha(ColorOutline and ColorOutline or color(67, 63, 64, 255), Alpha * 0.5), 3, 5)
    end

    Menu.Render.Handle = function()
        if Menu.Render.FadeBackGround == 0 then
            return
        end

        --local menu vector
        local RenderVector = vector(Menu.Render.MenuVectorFadeX, Menu.Render.MenuVectorFadeY)

        

        --render background 
        render.gradient(RenderVector, RenderVector + vector(Menu.Render.MenuWidth, Menu.Render.LengthFade), Helpers.ColorAlpha(MenuColors.BackGroundTopLeft, Menu.Render.FadeBackGround), Helpers.ColorAlpha(MenuColors.BackGroundTopRight, Menu.Render.FadeBackGround), Helpers.ColorAlpha(MenuColors.BackGroundBottomLeft, Menu.Render.FadeBackGround), Helpers.ColorAlpha(MenuColors.BackGroundMove, Menu.Render.FadeBackGround), 5)
        render.rect_outline(RenderVector, RenderVector + vector(Menu.Render.MenuWidth, Menu.Render.LengthFade), Helpers.ColorAlpha(MenuColors.BackGroundOutLine, Menu.Render.FadeBackGround), 3, 5)

        --background of icon
        Menu.Render.Countainer(RenderVector + vector(Menu.Render.MenuBorder, Menu.Render.MenuBorder), RenderVector + vector(Menu.Render.MenuBorder + Menu.Render.TabsSpace, Menu.Render.MenuBorder + Menu.Render.IconCload.y * 2), Menu.Render.FadeBackGround * Menu.Render.FadeComponents, MenuColors.IconBackground, MenuColors.IconOutline)
        render.gradient(RenderVector + vector(Menu.Render.MenuBorder*2, Menu.Render.MenuBorder + Menu.Render.IconCload.y - Files.image_LoadCload.Regular.Size.y / 2), RenderVector + vector(Menu.Render.MenuBorder*2 + Files.image_LoadCload.Regular.Size.x, Menu.Render.MenuBorder + Menu.Render.IconCload.y + Files.image_LoadCload.Regular.Size.y / 2), Helpers.ColorAlpha(MenuColors.IconCoverBackGround[1], Menu.Render.FadeBackGround * Menu.Render.FadeComponents), Helpers.ColorAlpha(MenuColors.IconCoverBackGround[2], Menu.Render.FadeBackGround * Menu.Render.FadeComponents), Helpers.ColorAlpha(MenuColors.IconCoverBackGround[3], Menu.Render.FadeBackGround * Menu.Render.FadeComponents), Helpers.ColorAlpha(MenuColors.IconCoverBackGround[4], Menu.Render.FadeBackGround * Menu.Render.FadeComponents), 7)

        --background of tabs
        Menu.Render.Countainer(RenderVector + vector(Menu.Render.MenuBorder, Menu.Render.MenuBorder * 2 + Menu.Render.IconCload.y * 2), RenderVector + vector(Menu.Render.MenuBorder + Menu.Render.TabsSpace, Menu.Render.MenuBorder * 2 + Menu.Render.IconCload.y * 5), Menu.Render.FadeBackGround * Menu.Render.FadeComponents, MenuColors.BackGroundTabs, MenuColors.TabsOutLine)
        
        --background of subtabs
        Menu.Render.Countainer(RenderVector + vector(Menu.Render.MenuBorder, Menu.Render.MenuBorder * 3 + Menu.Render.IconCload.y * 5), RenderVector + vector(Menu.Render.MenuBorder + Menu.Render.TabsSpace, Menu.Render.LengthFade - Menu.Render.MenuBorder), Menu.Render.FadeBackGround * Menu.Render.FadeComponents, MenuColors.BackGroundSubTabs, MenuColors.SubTabsOutLine)

        --background of user
        Menu.Render.Countainer(RenderVector + vector(Menu.Render.MenuBorder * 2 + Menu.Render.TabsSpace, Menu.Render.MenuBorder), RenderVector + vector(Menu.Render.MenuWidth - Menu.Render.MenuBorder, Menu.Render.MenuBorder + Menu.Render.IconCload.y * 2), Menu.Render.FadeBackGround * Menu.Render.FadeComponents, MenuColors.IconBackground, MenuColors.IconOutline)

        --ui
        Menu.Render.Countainer(RenderVector + vector(Menu.Render.MenuBorder * 2 + Menu.Render.TabsSpace, Menu.Render.MenuBorder * 2 + Menu.Render.IconCload.y * 2), RenderVector + vector(Menu.Render.MenuWidth - Menu.Render.MenuBorder, Menu.Render.LengthFade - Menu.Render.MenuBorder), Menu.Render.FadeBackGround * Menu.Render.FadeComponents, MenuColors.BackGroundUI, MenuColors.UIOutLine)

        --all the icons and texts
        render.texture(User.LocalBuild == "public" and Files.image_LoadPublic.Image or Files.image_LoadNightmare.Image, RenderVector + vector(Menu.Render.MenuBorder * 2, Menu.Render.MenuBorder + Menu.Render.IconCload.y - Files.image_LoadNightmare.Size.y / 2), Files.image_LoadNightmare.Size, Helpers.ColorAlpha(color(255, 255), Menu.Render.FadeBackGround * Menu.Render.FadeComponents))

        render.text(Menu.Render.FontMain, RenderVector + vector(Menu.Render.MenuBorder * 3 + Files.image_LoadCload.Regular.Size.x, Menu.Render.MenuBorder + Menu.Render.IconCload.y - 20), Helpers.ColorAlpha(MenuColors.DigitalText, Menu.Render.FadeBackGround * Menu.Render.FadeComponents), nil, "Digital")
        render.text(Menu.Render.FontMain, RenderVector + vector(Menu.Render.MenuBorder * 3 + Files.image_LoadCload.Regular.Size.x, Menu.Render.MenuBorder + Menu.Render.IconCload.y + 2), Helpers.ColorAlpha(MenuColors.DreamsText, Menu.Render.FadeBackGround * Menu.Render.FadeComponents), nil, "Dreams")

        render.texture(user_avatar, RenderVector + vector(Menu.Render.MenuBorder * 3 + Menu.Render.TabsSpace, Menu.Render.MenuBorder + Menu.Render.IconCload.y - 20), vector(40, 40), Helpers.ColorAlpha(color(255, 255), Menu.Render.FadeBackGround * Menu.Render.FadeComponents))

        render.text(Menu.Render.FontUserName, RenderVector + vector(Menu.Render.MenuBorder * 4 + Menu.Render.TabsSpace + 40, Menu.Render.MenuBorder + Menu.Render.IconCload.y - 20), Helpers.ColorAlpha(MenuColors.DigitalText, Menu.Render.FadeBackGround * Menu.Render.FadeComponents), nil, (GetUsername()))
        render.text(Menu.Render.FontUserName, RenderVector + vector(Menu.Render.MenuBorder * 4 + Menu.Render.TabsSpace + 40, Menu.Render.MenuBorder + Menu.Render.IconCload.y + 20 - 18), Helpers.ColorAlpha(MenuColors.DreamsText, Menu.Render.FadeBackGround * Menu.Render.FadeComponents), nil, User.LocalBuild)

        --ui system
        local TabIconSpace = ((#Menu.Tabs) * 25 + (#Menu.Tabs - 1) * 15) / 2
        for Index, SelectedTab in ipairs(Menu.Tabs) do
            local TabName = SelectedTab[1]

            if Menu.Render.TabsFade[Index] == nil then
                Menu.Render.TabsFade[Index] = 0
            end

            render.gradient(RenderVector + vector(Menu.Render.MenuBorder + Menu.Render.TabsSpace / 2 - TabIconSpace + ((Index-1) * 25 + ((Index-1) * 15)) , Menu.Render.MenuBorder * 2 + Menu.Render.IconCload.y * 3), RenderVector + vector(Menu.Render.MenuBorder + Menu.Render.TabsSpace / 2 - TabIconSpace + ((Index-1) * 25 + ((Index-1) * 15)) + SelectedTab[2].Size.x , Menu.Render.MenuBorder * 2 + Menu.Render.IconCload.y * 3 + SelectedTab[2].Size.y), Helpers.ColorAlpha(MenuColors.TabsSelectGradient[1], Menu.Render.FadeBackGround * Menu.Render.FadeComponents * Menu.Render.TabsFade[Index]), Helpers.ColorAlpha(MenuColors.TabsSelectGradient[2], Menu.Render.FadeBackGround * Menu.Render.FadeComponents * Menu.Render.TabsFade[Index]), Helpers.ColorAlpha(MenuColors.TabsSelectGradient[3], Menu.Render.FadeBackGround * Menu.Render.FadeComponents * Menu.Render.TabsFade[Index]), Helpers.ColorAlpha(MenuColors.TabsSelectGradient[4], Menu.Render.FadeBackGround * Menu.Render.FadeComponents * Menu.Render.TabsFade[Index]), 7)
            render.texture(SelectedTab[2].Image, RenderVector + vector(Menu.Render.MenuBorder + Menu.Render.TabsSpace / 2 - TabIconSpace + ((Index-1) * 25 + ((Index-1) * 15)) , Menu.Render.MenuBorder * 2 + Menu.Render.IconCload.y * 3), SelectedTab[2].Size, Helpers.ColorAlpha(MenuColors.TabsIcon, Menu.Render.FadeBackGround * Menu.Render.FadeComponents))

            Menu.Render.TabsFade[Index] = Helpers.Lerp(Menu.Render.TabsFade[Index], Menu.Render.ActiveTab == TabName and 1 or 0, 20)

            local InClickableArea = Helpers.IsInBox(RenderVector + vector(Menu.Render.MenuBorder + Menu.Render.TabsSpace / 2 - TabIconSpace + ((Index-1) * 25 + ((Index-1) * 15)) , Menu.Render.MenuBorder * 2 + Menu.Render.IconCload.y * 3), SelectedTab[2].Size.x, SelectedTab[2].Size.y)

            if InClickableArea then
                if Visuals.Move.IsPosible() and Menu.RenderComponents.InteractData.Slider == "" and not Helpers.Contains(Menu.RenderComponents.InteractData.ListOpen, true) and not Helpers.Contains(Menu.RenderComponents.InteractData.MultiListOpen, true) and not Menu.RenderComponents.InteractData.IsHue and not Menu.RenderComponents.InteractData.IsValueSaturation and not Menu.RenderComponents.InteractData.IsAlpha and Menu.RenderComponents.InteractData.ColorOpen == "" and Menu.RenderComponents.InteractData.BindTypeSelection == "" then -- add here all the checkes later
                    if common.is_button_down(1) and globals.realtime > Menu.GlobalTime + 0.2 then
                        Menu.GlobalTime = globals.realtime
                        Menu.Render.ActiveTab = TabName
                    end
                end
            end

            if Menu.Render.TabsFade[Index] ~= 0 then
                for IndexSubTab, SubTab in pairs(Menu.DrawComponents.SubTabs[TabName]) do
                    local SubTabSigrature = TabName .. "$" .. SubTab.SubTab

                    if Menu.Render.SubTabsFade[SubTabSigrature] == nil then
                        Menu.Render.SubTabsFade[SubTabSigrature] = 0
                    end

                    local SubTabTextSize = render.measure_text(Menu.Render.FontSubTab, nil, SubTab.SubTab)

                    render.gradient(RenderVector + vector(Menu.Render.MenuBorder * 2 - 5, Menu.Render.MenuBorder * 5 + Menu.Render.IconCload.y * 5 + ((IndexSubTab-1) * 36) * Menu.Render.TabsFade[Index] + SubTabTextSize.y/2 - SubTab.Icon.Size.y/2 - 5), RenderVector + vector(Menu.Render.MenuBorder * 2 + SubTab.Icon.Size.x + 5, Menu.Render.MenuBorder * 5 + Menu.Render.IconCload.y * 5 + ((IndexSubTab-1) * 36) * Menu.Render.TabsFade[Index] + SubTabTextSize.y/2 - SubTab.Icon.Size.y/2 + SubTab.Icon.Size.y + 5), Helpers.ColorAlpha(MenuColors.SubTabsSelectGradient[1], Menu.Render.FadeBackGround * Menu.Render.FadeComponents * Menu.Render.TabsFade[Index] * Menu.Render.SubTabsFade[SubTabSigrature]), Helpers.ColorAlpha(MenuColors.SubTabsSelectGradient[2], Menu.Render.FadeBackGround * Menu.Render.FadeComponents * Menu.Render.TabsFade[Index] * Menu.Render.SubTabsFade[SubTabSigrature]), Helpers.ColorAlpha(MenuColors.SubTabsSelectGradient[3], Menu.Render.FadeBackGround * Menu.Render.FadeComponents * Menu.Render.TabsFade[Index] * Menu.Render.SubTabsFade[SubTabSigrature]), Helpers.ColorAlpha(MenuColors.SubTabsSelectGradient[4], Menu.Render.FadeBackGround * Menu.Render.FadeComponents * Menu.Render.TabsFade[Index] * Menu.Render.SubTabsFade[SubTabSigrature]), 7)
                    render.texture(SubTab.Icon.Image, RenderVector + vector(Menu.Render.MenuBorder * 2, Menu.Render.MenuBorder * 5 + Menu.Render.IconCload.y * 5 + ((IndexSubTab-1) * 36) * Menu.Render.TabsFade[Index] + SubTabTextSize.y/2 - SubTab.Icon.Size.y/2), SubTab.Icon.Size, Helpers.ColorAlpha(MenuColors.SubTabsIcon, Menu.Render.FadeBackGround * Menu.Render.FadeComponents * Menu.Render.TabsFade[Index]))

                    render.text(Menu.Render.FontSubTab, RenderVector + vector(Menu.Render.MenuBorder * 3 + SubTab.Icon.Size.x, Menu.Render.MenuBorder * 5 + Menu.Render.IconCload.y * 5 + ((IndexSubTab-1) * 36) * Menu.Render.TabsFade[Index]), Helpers.ColorAlpha(MenuColors.SubTabsText, Menu.Render.FadeBackGround * Menu.Render.FadeComponents * Menu.Render.TabsFade[Index]), nil, SubTab.SubTab)

                    Menu.Render.SubTabsFade[SubTabSigrature] = Helpers.Lerp(Menu.Render.SubTabsFade[SubTabSigrature], Menu.IsSomeComponentsShowen[TabName] == SubTab.UI and 1 or 0, 20)

                    local InClickableAreaOfSubTab = Helpers.IsInBox(RenderVector + vector(Menu.Render.MenuBorder, Menu.Render.MenuBorder * 5 + Menu.Render.IconCload.y * 5 + ((IndexSubTab-1) * 36) * Menu.Render.TabsFade[Index] - 1), Menu.Render.TabsSpace, 20)

                    if InClickableAreaOfSubTab then
                        if Visuals.Move.IsPosible() and Menu.RenderComponents.InteractData.Slider == "" and not Helpers.Contains(Menu.RenderComponents.InteractData.ListOpen, true) and not Helpers.Contains(Menu.RenderComponents.InteractData.MultiListOpen, true) and not Menu.RenderComponents.InteractData.IsHue and not Menu.RenderComponents.InteractData.IsValueSaturation and not Menu.RenderComponents.InteractData.IsAlpha and Menu.RenderComponents.InteractData.ColorOpen == "" and Menu.RenderComponents.InteractData.BindTypeSelection == "" then -- set later when other objetc will be added
                            if common.is_button_down(1) and globals.realtime > Menu.GlobalTime + 0.2 then
                                Menu.GlobalTime = globals.realtime
                                Menu.IsSomeComponentsShowen[TabName] = SubTab.UI
                            end
                        end
                    end
                    

                    --UI : help me . (note; create second tab if the amount of the ui is > [some amount idk], another note : need to fix the fade of ui when it covered)
                    local VectorUI = RenderVector + vector(Menu.Render.MenuBorder * 3 + Menu.Render.TabsSpace, Menu.Render.MenuBorder * 3 + Menu.Render.IconCload.y * 2)
                    local AdditionY = 0
                    local DropDown = nil
                    if Menu.Render.SubTabsFade[SubTabSigrature] ~= 0 then
                        for IndexUI, PointerUI in pairs(SubTab.UI) do
                            local ComponentSignature = SubTabSigrature .. "$" .. PointerUI.Name
                            local Is2SlotComponent = (PointerUI.Type == "Slider" or PointerUI.Type == "ListBox" or PointerUI.Type == "MultiListBox")

                            if Menu.Render.FadeUI[ComponentSignature] == nil then
                                Menu.Render.FadeUI[ComponentSignature] = 0
                            end

                            if Menu.Render.FadeVisibleUI.Full[ComponentSignature] == nil then
                                Menu.Render.FadeVisibleUI.Full[ComponentSignature] = 0
                            end

                            if Is2SlotComponent and Menu.Render.FadeVisibleUI.Half[ComponentSignature] == nil then
                                Menu.Render.FadeVisibleUI.Half[ComponentSignature] = 0
                            end

                            --drop cover mechanic // cancer as fuck but works
                            local DisableUI = {Full = false, Half = false}
                            if DropDown ~= nil then
                                if Is2SlotComponent then
                                    if 5 + (AdditionY * Menu.Render.SpaceUI) >= DropDown.StartPoint - 1 and 5 + (AdditionY * Menu.Render.SpaceUI) + (Menu.Render.SpaceUI*2 - 1) < DropDown.StartPoint + DropDown.CoverAmount then
                                        DisableUI.Full = true
                                    elseif 5 + (AdditionY * Menu.Render.SpaceUI) >= DropDown.StartPoint - 1 and 5 + (AdditionY * Menu.Render.SpaceUI) + (Menu.Render.SpaceUI - 1) < DropDown.StartPoint + DropDown.CoverAmount and 5 + (AdditionY * Menu.Render.SpaceUI) + (Menu.Render.SpaceUI*2 - 1) > DropDown.StartPoint + DropDown.CoverAmount then
                                        DisableUI.Half = true
                                        DisableUI.Full = false
                                    end
                                else
                                    if 5 + (AdditionY * Menu.Render.SpaceUI) >= DropDown.StartPoint - 1 and 5 + (AdditionY * Menu.Render.SpaceUI) + (Menu.Render.SpaceUI - 1) < DropDown.StartPoint + DropDown.CoverAmount then
                                        DisableUI.Full = true
                                    end
                                end
                            end

                            Menu.Render.FadeUI[ComponentSignature] = Helpers.Lerp(Menu.Render.FadeUI[ComponentSignature], PointerUI.Visible() and 1 or 0, 10)
                            Menu.Render.FadeVisibleUI.Full[ComponentSignature] = Helpers.Lerp(Menu.Render.FadeVisibleUI.Full[ComponentSignature], DisableUI.Full and 0 or 1, 15)
                            Menu.Render.FadeVisibleUI.Half[ComponentSignature] = Helpers.Lerp(Menu.Render.FadeVisibleUI.Half[ComponentSignature], DisableUI.Half and 0 or 1, 15)
                            
                            local ItemCollect = {SlotHeight = 0, DropDownCover = 0}
                            if Menu.Render.FadeUI[ComponentSignature] ~= 0 then
                                ItemCollect.SlotHeight, ItemCollect.DropDownCover = Menu.RenderComponents.Types[PointerUI.Type](VectorUI + vector(0, AdditionY * Menu.Render.SpaceUI), PointerUI, (Menu.Render.FadeBackGround * Menu.Render.FadeComponents * Menu.Render.TabsFade[Index] * Menu.Render.SubTabsFade[SubTabSigrature] * Menu.Render.FadeUI[ComponentSignature]), Menu.Render.FontUIComponents, Menu.Render.FadeVisibleUI.Full[ComponentSignature], Menu.Render.FadeVisibleUI.Half[ComponentSignature], Menu.Render.SaveData)
                            end

                            -- $$$
                            if ItemCollect.DropDownCover ~= 0 then
                                DropDown = 
                                {
                                    StartPoint = 5 + (AdditionY * Menu.Render.SpaceUI) + (ItemCollect.SlotHeight*Menu.Render.SpaceUI), -- // basiclly the start location of the element
                                    CoverAmount = (ItemCollect.DropDownCover) -- // in any case just remove the Menu.Render.SpaceUI or replace it with 1
                                }
                            end

                            AdditionY = AdditionY + ItemCollect.SlotHeight * Menu.Render.FadeUI[ComponentSignature]
                        end
                    end
                end
            end
        end

        local Mouse = ui.get_mouse_position()
        local IsHoveredMenu = Helpers.IsInBox(RenderVector + vector(Menu.Render.MenuBorder, Menu.Render.MenuBorder), Menu.Render.TabsSpace, Menu.Render.IconCload.y * 2) -- i will use the icon .. the best solution for now
        if IsHoveredMenu then
            if Visuals.Move.IsPosible() and Menu.RenderComponents.InteractData.Slider == "" and not Helpers.Contains(Menu.RenderComponents.InteractData.ListOpen, true) and not Helpers.Contains(Menu.RenderComponents.InteractData.MultiListOpen, true) and not Menu.RenderComponents.InteractData.IsHue and not Menu.RenderComponents.InteractData.IsValueSaturation and not Menu.RenderComponents.InteractData.IsAlpha and Menu.RenderComponents.InteractData.ColorOpen == "" and Menu.RenderComponents.InteractData.BindTypeSelection == "" then
                if common.is_button_down(1) then
                    Visuals.Move.Objects.Menu = true
                    Menu.Render.MenuVectorMoveX = Menu.Neverlose.MenuVectorX:get() - Mouse.x
                    Menu.Render.MenuVectorMoveY = Menu.Neverlose.MenuVectorY:get() - Mouse.y
                end
            end
        end

        if common.is_button_released(1) then
            Visuals.Move.Objects.Menu = false
        end

        if Visuals.Move.Objects.Menu and Helpers.IsMenuVisible() then
            Menu.Neverlose.MenuVectorX:set(math_floor(Menu.Render.MenuVectorMoveX + Mouse.x))
            Menu.Neverlose.MenuVectorY:set(math_floor(Menu.Render.MenuVectorMoveY + Mouse.y))
        end

        local IsHoveredOnSize = Helpers.IsInBox(RenderVector + vector(Menu.Neverlose.BoxAddX:get() - 10, Menu.Neverlose.BoxAddY:get() + Menu.Render.Add - 10), 10, 10)
        if IsHoveredOnSize then
            if common.is_button_down(1) then
                if Visuals.Move.IsPosible() and Menu.RenderComponents.InteractData.Slider == "" and not Helpers.Contains(Menu.RenderComponents.InteractData.ListOpen, true) and not Helpers.Contains(Menu.RenderComponents.InteractData.MultiListOpen, true) and not Menu.RenderComponents.InteractData.IsHue and not Menu.RenderComponents.InteractData.IsValueSaturation and not Menu.RenderComponents.InteractData.IsAlpha and Menu.RenderComponents.InteractData.ColorOpen == "" and Menu.RenderComponents.InteractData.BindTypeSelection == "" then
                    Visuals.Move.Objects.MenuSize = true
                    Menu.Render.MenuVectorSizeX = (RenderVector.x + Menu.Neverlose.BoxAddX:get()) - Mouse.x
                    Menu.Render.MenuVectorSizeY = (RenderVector.y + Menu.Neverlose.BoxAddY:get()) - Mouse.y
                end
            end
        end

        if common.is_button_released(1) then
            Visuals.Move.Objects.MenuSize = false
        end

        if Visuals.Move.Objects.MenuSize and Helpers.IsMenuVisible() then
            Menu.Neverlose.BoxAddX:set(math_floor(Menu.Render.MenuVectorSizeX + Mouse.x - RenderVector.x))
            Menu.Neverlose.BoxAddY:set(math_floor(Menu.Render.MenuVectorSizeX + Mouse.y - RenderVector.y))
        end
        
        -- // could use clamp function but i am lazy :P
        if Menu.Neverlose.BoxAddX:get() < 485 then
            Menu.Neverlose.BoxAddX:set(485)
        end

        if Menu.Neverlose.BoxAddX:get() > 1000 then
            Menu.Neverlose.BoxAddX:set(1000)
        end

        if Menu.Neverlose.BoxAddY:get() < 500 then
            Menu.Neverlose.BoxAddY:set(500)
        end

        if Menu.Neverlose.BoxAddY:get() > 1000 then
            Menu.Neverlose.BoxAddY:set(1000)
        end

        -- // hehehehe
        Menu.Neverlose.MainColor:set(Menu.DataUI["Misc"]["Menu"]["Menu Color"]:clone())
    end

    Menu.Render.ValuesUpdate = function()
        for Index, SelectedTab in ipairs(Menu.Tabs) do
            local TabName = SelectedTab[1]
            for IndexSubTab, SubTab in pairs(Menu.DrawComponents.SubTabs[TabName]) do
                for IndexUI, PointerUI in pairs(SubTab.UI) do
                    if PointerUI.Type == "KeyBind" then
                        Menu.Keybinds.Data[PointerUI.Name].Key = PointerUI.Value
                    end
                    Menu.DataUI[TabName][SubTab.SubTab][PointerUI.Name] = PointerUI.Value
                end
            end
        end
    end

    Menu.Render.KeyBinds = {}
    Menu.Render.KeyBinds.OldTick = -1
    Menu.Render.KeyBinds.TickCounts = {}
    Menu.Render.KeyBinds.Fixed = false
    Menu.Render.KeyBinds.LastKeyBind = nil
    Menu.Render.KeyBinds.Handle = function()
        if Menu.Render.KeyBinds.OldTick == globals.tickcount then
            return
        end

        Menu.Render.KeyBinds.OldTick = globals.tickcount

        for Index, Key in pairs(Menu.Keybinds.Names) do
            if Menu.Keybinds.Data[Key].Key == 0x1B then
                Menu.Keybinds.Data[Key].Value = false
                goto skip
            end

            if Menu.Render.KeyBinds.TickCounts[Key] == nil then
                Menu.Render.KeyBinds.TickCounts[Key] = -1
            end

            Helpers.Switch(Menu.Keybinds.Data[Key].Type, 
                Helpers.Case("hold", function() Menu.Keybinds.Data[Key].Value = common.is_button_down(Menu.Keybinds.Data[Key].Key) end),
                Helpers.Case("toggle", function() 

                    if Menu.Render.KeyBinds.Fixed == false and common.is_button_down(Menu.Keybinds.Data[Key].Key) then
                        Menu.Keybinds.Data[Key].Value = not Menu.Keybinds.Data[Key].Value
                        Menu.Render.KeyBinds.LastKeyBind = Menu.Keybinds.Data[Key].Key
                        Menu.Render.KeyBinds.Fixed = true
                    end 

                    if Menu.Render.KeyBinds.LastKeyBind ~= nil then
                        if common.is_button_released(Menu.Render.KeyBinds.LastKeyBind) then
                            Menu.Render.KeyBinds.Fixed = false
                            Menu.Render.KeyBinds.LastKeyBind = nil
                        end
                    end
                end),
                Helpers.Case("always", function() Menu.Keybinds.Data[Key].Value = true end)
            )


            ::skip::
        end
    end

    local MenuEventSystem = function()
        local VectorSTART = vector(Menu.MenuData.ScreenSize.x / 2 + 300, 50)
        local MaxTime = 5 -- // 5 second for each event should be enough
        
        local DropEventVector = 0

        for Index, Event in pairs(Menu.MenuData.Logs) do
            local StringSize = render.measure_text(Menu.Render.FontUIComponents, nil, Event[1])
            local BackGroundSize = Event[2].Size.x + 15 + StringSize.x -- // use to center the event log

            if Event[4] + MaxTime < globals.realtime and Event[3] == 0 then
                table_remove(Menu.MenuData.Logs, Index)
            end

            Event[3] = Helpers.Lerp(Event[3], Event[4] + MaxTime < globals.realtime and 0 or 1, 10)

            Menu.Render.Countainer(VectorSTART + vector(- (BackGroundSize / 2), DropEventVector * 40), VectorSTART + vector(BackGroundSize / 2, DropEventVector * 40 + 30), Event[3], MenuColors.EventBackground, MenuColors.EventOutline)
            render.rect(VectorSTART + vector(- (BackGroundSize / 2) + 5, DropEventVector * 40 + 5), VectorSTART + vector(- (BackGroundSize / 2) + 5 + Event[2].Size.x, DropEventVector * 40 + 5 + Event[2].Size.y), Helpers.ColorAlpha(MenuColors.EventIconBackground, Event[3]), 4)

            render.texture(Event[2].Image, VectorSTART + vector(- (BackGroundSize / 2) + 5, DropEventVector * 40 + 5), Event[2].Size, Helpers.ColorAlpha(MenuColors.EventIcon, Event[3]))

            render.text(Menu.Render.FontUIComponents, VectorSTART + vector(- (BackGroundSize / 2) + 10 + Event[2].Size.x, DropEventVector * 40 + 15 - StringSize.y / 2), Helpers.ColorAlpha(MenuColors.EventText, Event[3]), nil, Event[1])

            DropEventVector = DropEventVector + Event[3]
        end
    end

    Menu.Render.KeyBinds.Get = function(Name)
        return Menu.Keybinds.Data[Name].Value
    end


    Menu.Neverlose.Init()
    Menu.Components.Init()
    Menu.Components.BuildItems()
    Menu.Render.Init()

    CallbackManager.AddMethod("render", Menu.Render.VisualsChanges, false, "Menu Animations")
    CallbackManager.AddMethod("render", Menu.Render.Handle, false, "Menu Render")
    CallbackManager.AddMethod("render", Menu.Render.ValuesUpdate, false, "Update Menu Values")
    CallbackManager.AddMethod("render", Menu.Render.KeyBinds.Handle, false, "Handle KeyBinds")
    CallbackManager.AddMethod("render", MenuEventSystem, false, "Event Log System")
    events.mouse_input:set(function() 
        if Helpers.IsMenuVisible() then 
            return false 
        end 
    end)
    CallbackManager.AddMethod("shutdown", function() 
        if Menu.DataUI["Misc"]["CFG"]["Auto Save"] then
            Menu.DataUI["Misc"]["CFG"]["Select Tabs To Use"] = {true, true, true, true}
            local EncEnd = enc(Menu.Components.GetCFG())
            if Menu.DataUI["Misc"]["CFG"]["Select CFG"] ~= "Default" then
                files.write(string_format("csgo\\DigitalData\\DigitalCfgs\\%s.txt", Menu.DataUI["Misc"]["CFG"]["Select CFG"]), EncEnd)
            end
        end
    end, false, "Destroy Menu")
end


local Load = {}
Load.Init = function()
    local Time = {
        Wait = globals.realtime,
        Start = globals.realtime + 5,
    }
    local LoadFade = {
        BackGround = 0,
        Icons = 0,
        Announcement = 0
    }
    local LoaderSizes = {
        Width = 500,
        Length = 250,
        IconSpace = 100,
        SpaceBorder = 10,
    }
    local SwitchMode = false
    local FontLoad = Files.LoadFont(Files.DownloadFiles.FontMenu, 16, 'a')
    local LoadButton = Files.LoadFont(Files.DownloadFiles.FontMenu, 18, 'ba')
    local IsAnnouncement = false

    Load.Render = function()
        if CallbackManager.FullRun == true then
            return
        end

        if Time.Wait + 5 > globals.realtime then
            return
        end

        local LoadVector = vector(Menu.Neverlose.MenuVectorX:get(), Menu.Neverlose.MenuVectorY:get())

        LoadFade.Announcement = Helpers.Lerp(LoadFade.Announcement, IsAnnouncement and 1 or 0, 20)
        local AddAnn = LoadFade.Announcement * (render.measure_text(FontLoad, nil, User.Announcement).x + 20)

        --background
        render.gradient(LoadVector, LoadVector + vector(LoaderSizes.Width * LoadFade.BackGround + AddAnn, LoaderSizes.Length), Helpers.ColorAlpha(color(56, 51, 57, 255), LoadFade.BackGround), Helpers.ColorAlpha(color(1, 1, 0, 255), LoadFade.BackGround), Helpers.ColorAlpha(color(1, 1, 0, 255), LoadFade.BackGround), Helpers.ColorAlpha(color(56, 51, 57, 255), LoadFade.BackGround), 5)
        render.rect_outline(LoadVector, LoadVector + vector(LoaderSizes.Width * LoadFade.BackGround + AddAnn, LoaderSizes.Length), Helpers.ColorAlpha(color(67, 63, 64, 255), LoadFade.BackGround), 3, 5)

        render.texture(User.LocalBuild == "public" and Files.image_LoadPublic.Image or Files.image_LoadNightmare.Image, LoadVector + vector(LoaderSizes.IconSpace / 2 - Files.image_LoadNightmare.Size.x / 2, LoaderSizes.Length / 2 - Files.image_LoadNightmare.Size.y / 2), Files.image_LoadNightmare.Size, Helpers.ColorAlpha(color(255, 255), LoadFade.BackGround))

        --icons 
        render.rect(LoadVector + vector(LoaderSizes.IconSpace, LoaderSizes.SpaceBorder), LoadVector + vector(LoaderSizes.Width * LoadFade.BackGround - LoaderSizes.SpaceBorder + AddAnn, LoaderSizes.Length - LoaderSizes.SpaceBorder), Helpers.ColorAlpha(color(37, 33, 34, 255), LoadFade.BackGround * LoadFade.Icons * 0.4), 5)
        render.rect_outline(LoadVector + vector(LoaderSizes.IconSpace, LoaderSizes.SpaceBorder), LoadVector + vector(LoaderSizes.Width * LoadFade.BackGround - LoaderSizes.SpaceBorder + AddAnn, LoaderSizes.Length - LoaderSizes.SpaceBorder), Helpers.ColorAlpha(color(67, 63, 64, 255), LoadFade.BackGround * LoadFade.Icons * 0.5), 3, 5)

        render.text(FontLoad, LoadVector + vector(LoaderSizes.Width * LoadFade.BackGround - LoaderSizes.SpaceBorder + 10, LoaderSizes.SpaceBorder * 2), Helpers.ColorAlpha(color(255, 255), LoadFade.Announcement * LoadFade.BackGround * LoadFade.Icons), nil, User.Announcement)
        --
        local Vectors = {
            Center = LoadVector + vector(LoaderSizes.IconSpace + (LoaderSizes.Width * LoadFade.BackGround - LoaderSizes.SpaceBorder - LoaderSizes.IconSpace) / 2, 60),
            Left = LoadVector + vector(LoaderSizes.IconSpace + (LoaderSizes.Width * LoadFade.BackGround - LoaderSizes.SpaceBorder - LoaderSizes.IconSpace) / 2 - 100, 60),
            Right = LoadVector + vector(LoaderSizes.IconSpace + (LoaderSizes.Width * LoadFade.BackGround - LoaderSizes.SpaceBorder - LoaderSizes.IconSpace) / 2 + 100, 60),
        }
        --Files.image_LoadLocalBuild = Files.LoadImage(Files.DownloadFiles.Data, vector(15, 15))
        --Files.image_LoadVersion = Files.LoadImage(Files.DownloadFiles.CantAccess, vector(15, 15))
        --Files.image_LoadVersion = Files.LoadImage(Files.DownloadFiles.ActiveLink, vector(15, 15))
        render.texture(Files.image_LoadLocalBuild.Image, Vectors.Left + vector(-Files.image_LoadLocalBuild.Size.x/2, 0), Files.image_LoadLocalBuild.Size, Helpers.ColorAlpha(color(255, 255), LoadFade.BackGround * LoadFade.Icons))
        render.text(FontLoad, Vectors.Left + vector(0, 40), Helpers.ColorAlpha(color(255, 255), LoadFade.BackGround * LoadFade.Icons), 'c', User.LocalBuild)

        render.texture(Files.image_LoadVersion.Image, Vectors.Center + vector(-Files.image_LoadVersion.Size.x/2, 0), Files.image_LoadVersion.Size, Helpers.ColorAlpha(color(255, 255), LoadFade.BackGround * LoadFade.Icons))
        render.text(FontLoad, Vectors.Center + vector(0, 40), Helpers.ColorAlpha(color(255, 255), LoadFade.BackGround * LoadFade.Icons), 'c', Version)

        local ImageDated = Version == User.CloadVersion and Files.image_LoadIsUpDated or Files.image_LoadIsOutDated 
        
        render.texture(ImageDated.Image, Vectors.Right + vector(-ImageDated.Size.x/2, 0), ImageDated.Size, Helpers.ColorAlpha(color(255, 255), LoadFade.BackGround * LoadFade.Icons))
        render.text(FontLoad, Vectors.Right + vector(0, 40), Helpers.ColorAlpha(color(255, 255), LoadFade.BackGround * LoadFade.Icons), 'c', (Version == User.CloadVersion and "Up-To Date" or "OutDated"))

        local LoadSize = render.measure_text(LoadButton, nil, "Load Lua")
        render.rect_outline(Vectors.Center + vector(-LoadSize.x/2 - 5 - 100, 150 - LoadSize.y/2 - 5), Vectors.Center + vector(LoadSize.x/2 + 5 - 100, 150 + LoadSize.y/2 + 5), Helpers.ColorAlpha(color(255, 255), LoadFade.BackGround * LoadFade.Icons), 1.5, 3)
        render.text(LoadButton, Vectors.Center + vector(-100, 150), Helpers.ColorAlpha(color(255, 255), LoadFade.BackGround * LoadFade.Icons), 'c', "Load Lua")

        local AnsSize = render.measure_text(LoadButton, nil, "Announcement")
        render.rect_outline(Vectors.Center + vector(-AnsSize.x/2 - 5 + 100, 150 - AnsSize.y/2 - 5), Vectors.Center + vector(AnsSize.x/2 + 5 + 100, 150 + AnsSize.y/2 + 5), Helpers.ColorAlpha(color(255, 255), LoadFade.BackGround * LoadFade.Icons), 1.5, 3)
        render.text(LoadButton, Vectors.Center + vector(100, 150), Helpers.ColorAlpha(color(255, 255), LoadFade.BackGround * LoadFade.Icons), 'c', "Announcement")

        --animate
        LoadFade.BackGround = Helpers.Lerp(LoadFade.BackGround, SwitchMode and 0 or 1, 10)
        LoadFade.Icons = Helpers.Lerp(LoadFade.Icons, LoadFade.BackGround == 1 and 1 or 0, 10)

        if SwitchMode and LoadFade.BackGround == 0 then
            CallbackManager.FullRun = true
        end

        local HoveredLoad = Helpers.IsInBox(Vectors.Center + vector(-LoadSize.x/2 - 5 - 100, 150 - LoadSize.y/2 - 5), LoadSize.x + 10, LoadSize.y + 10)
        if HoveredLoad then
            if common.is_button_down(1) and globals.realtime > Menu.GlobalTime + 0.2 then
                Menu.GlobalTime = globals.realtime
                SwitchMode = true
            end
        end

        local HoveredAnn = Helpers.IsInBox(Vectors.Center + vector(-AnsSize.x/2 - 5 + 100, 150 - AnsSize.y/2 - 5), AnsSize.x + 10, AnsSize.y + 10)
        if HoveredAnn then
            if common.is_button_down(1) and globals.realtime > Menu.GlobalTime + 0.2 then
                Menu.GlobalTime = globals.realtime
                IsAnnouncement = not IsAnnouncement
            end
        end


        local Mouse = ui.get_mouse_position()
        local IsHoveredMenu = Helpers.IsInBox(LoadVector, LoaderSizes.IconSpace, LoaderSizes.Length) -- i will use the icon .. the best solution for now
        if IsHoveredMenu then
            if Visuals.Move.IsPosible() and Menu.RenderComponents.InteractData.Slider == "" and not Helpers.Contains(Menu.RenderComponents.InteractData.ListOpen, true) and not Helpers.Contains(Menu.RenderComponents.InteractData.MultiListOpen, true) and not Menu.RenderComponents.InteractData.IsHue and not Menu.RenderComponents.InteractData.IsValueSaturation and not Menu.RenderComponents.InteractData.IsAlpha and Menu.RenderComponents.InteractData.ColorOpen == "" and Menu.RenderComponents.InteractData.BindTypeSelection == "" then
                if common.is_button_down(1) then
                    Visuals.Move.Objects.Menu = true
                    Menu.Render.MenuVectorMoveX = Menu.Neverlose.MenuVectorX:get() - Mouse.x
                    Menu.Render.MenuVectorMoveY = Menu.Neverlose.MenuVectorY:get() - Mouse.y
                end
            end
        end

        if common.is_button_released(1) then
            Visuals.Move.Objects.Menu = false
        end

        if Visuals.Move.Objects.Menu and Helpers.IsMenuVisible() then
            Menu.Neverlose.MenuVectorX:set(math_floor(Menu.Render.MenuVectorMoveX + Mouse.x))
            Menu.Neverlose.MenuVectorY:set(math_floor(Menu.Render.MenuVectorMoveY + Mouse.y))
        end



    end

    CallbackManager.AddMethod("render", Load.Render, true, "Lua Load")
end



--//lua components install and run
Files.Init()
Helpers.Init()
User.Init()
MenuReferences.Init()
Misc.Init()
RageBot.Init()
AntiAim.Init()
Visuals.Init()
Menu.Init()
Load.Init()
CallbackManager.RunLua(false)
