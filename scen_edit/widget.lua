function RecieveGadgetMessage(msg)
    local msgParams = String.Explode('|', msg)
    if msgParams[1] ~= SB.messageManager.prefix then
        return
    end
    local op = msgParams[2]

    if op == 'sync' then
        local msgParsed = string.sub(msg, #(SB.messageManager.prefix .. "|sync|") + 1)
        local msgTable = loadstring(msgParsed)()
        local msgObj = Message(msgTable.tag, msgTable.data)
        if msgObj.tag == 'command' then
            SB.commandManager:HandleCommandMessage(msgObj, true)
        end
        return
    end

    -- local tbl = loadstring(msg)()
    -- local data = tbl.data
    -- local tag = tbl.tag
    -- if tag == "msg" then
    --     model:InvokeCallback(data.msgID, data.result)
    -- end
end

local springConfig = {
    HeightMapTexture = { value = 1, type = 'int' },
    LinkIncomingMaxPacketRate = { value = 64000, type = 'int' },
    LinkIncomingMaxWaitingPackets = { value = 512000, type = 'int' },
    LinkIncomingPeakBandwidth = { value = 32768000, type = 'int' },
    LinkIncomingSustainedBandwidth = { value = 2048000, type = 'int' },
    LinkOutgoingBandwidth = { value = 65536000, type = 'int' },
    TextureMemPoolSize = { min = 600, value = 600, type = 'int' }
}

local function DumpConfig()
    Log.Notice("Dump of relevant engine config:")
    for name, _ in pairs(springConfig) do
        Log.Notice(name .. " = " .. Spring.GetConfigString(name, ""))
    end
end

local function CheckConfig()
    if SB.IsSpringConfigValid(springConfig) then
        return
    end

    local window
    window = Window:New {
        x = "25%",
        y = "15%",
        width = 450,
        height = 150,
        parent = screen0,
        resizable = false,
        children = {
            Label:New {
                x = "1%",
                y = "1%",
                width = "99%",
                bottom = "50%",
                caption = "SpringBoard needs to set correct Engine configuration.",
            },
            Button:New {
                x = "5%",
                height = 40,
                bottom = 0,
                width = 180,
                caption = "Set config values",
                OnClick = {
                    function()
                        SB.SetSpringConfig(springConfig)
                        window:Dispose()
                        SB.AskToRestart()
                    end
                }
            },
            Button:New {
                right = "5%",
                height = 40,
                bottom = 0,
                width = 180,
                caption = "Continue without setting",
                OnClick = {
                    function()
                        window:Dispose()
                    end
                }
            },
        },
    }
end

local function CheckSpringBoardDir()
    -- Make the initial SB directory tree and
    -- add a README.txt file if it doesn't exist.
    -- Also prints out the absolute directory path.
    if not VFS.FileExists(SB_ROOT, VFS.RAW) then
        Log.Notice("Creating initial SpringBoard directory")
        Spring.CreateDir(SB_ROOT)
        Spring.CreateDir(SB_PROJECTS_DIR)
        Spring.CreateDir(SB_ASSETS_DIR)
        Spring.CreateDir(SB_EXTS_DIR)
    end

    local readmePath = Path.Join(SB_ROOT, 'README.txt')
    if not VFS.FileExists(readmePath) then
        -- TODO: Maybe we should update the file if there's a change.
        -- Don't want to do it every time as it might be slow and annoying
        -- (updating file mtime unnecessarily).
        local readmetxt = VFS.LoadFile("templates/root_dir_README.txt", VFS.MOD)
        local file = assert(io.open(readmePath, "w"))
        file:write(readmetxt)
        file:close()
    end
end

local function MaybeLoad()
    if not hasScenarioFile and SB.projectDir ~= nil and not SB.projectLoaded then
        Log.Notice("Loading project (from widget)")
        local cmd = LoadProjectCommandWidget(SB.projectDir, false)
        SB.commandManager:execute(cmd, true)
        SB.projectLoaded = true
    end
end

local RELOAD_GADGETS = true
function widget:Initialize()
    VFS.Include("scen_edit/exports.lua")
    LCS = loadstring(VFS.LoadFile(LIBS_DIR .. "lcs/LCS.lua"))
    LCS = LCS()
    VFS.Include(SB_DIR .. "util.lua")
    SB.Include(SB_DIR .. "utils/include.lua")

    Log.Notice('SpringBoard directory path at: ' .. tostring(SB_ROOT_ABS))

    -- we can't have handler=true because then RegisterGlobal doesn't work
    -- so we expose handler API to our widgetHandler
    widgetHandler.DisableWidget = function(_, ...)
        WG.SB_widgetHandler:DisableWidget(...)
    end
    widgetHandler.EnableWidget = function(_, ...)
        WG.SB_widgetHandler:EnableWidget(...)
    end

    widgetHandler:RegisterGlobal("RecieveGadgetMessage", RecieveGadgetMessage)

    local wasEnabled = Spring.IsCheatingEnabled()
    if not wasEnabled then
        Spring.SendCommands("cheat")
    end

    if Spring.GetGameRulesParam("sb_gameMode") ~= "play" and RELOAD_GADGETS then
        reloadGadgets() --uncomment for development
    end

    if not wasEnabled then
        Spring.SendCommands("cheat")
    end

    DumpConfig()
    CheckConfig()
    CheckSpringBoardDir()

    SB.displayUtil = DisplayUtil()

    SB.conf = Conf()
    SB.metaModel = MetaModel()

    --TODO: relocate this
    local metaModelLoader = MetaModelLoader()
    metaModelLoader:Load()

    SB.model = Model()

    SB.commandManager = CommandManager()
    SB.stateManager = StateManager()
    SB.messageManager = MessageManager()

    if Spring.GetGameRulesParam("sb_gameMode") ~= "play" then
        Spring.SendCommands('forcestart')
        SB.view = View()

        local viewAreaManagerListener = ViewAreaManagerListener()
        SB.model.areaManager:addListener(viewAreaManagerListener)

        -- enable global LoS so heightmap changes are always visible
        local cmd = SetGlobalLosCommand({
            allyTeamID = Spring.GetMyAllyTeamID(),
            value = true,
        })
        SB.commandManager:execute(cmd)
    end
    self._START_TIME = os.clock()

    if Spring.GetGameFrame() > 10 then
        MaybeLoad()
    end

    SB.executeDelayed("Initialize")
end

function reloadGadgets()
    Spring.SendCommands("luarules reload")
end

function widget:DrawScreen()
    if SB.view ~= nil then
        SB.stateManager:DrawScreen()
    end
    SB.executeDelayed("DrawScreen")
end

function widget:DrawScreenPost()
    SB.executeDelayed("DrawScreenPost")
end

function widget:DrawScreenEffects()
    SB.executeDelayed("DrawScreenEffects")
end

function widget:DrawWorld()
    if SB.view ~= nil then
        SB.stateManager:DrawWorld()
    end
    SB.executeDelayed("DrawWorld")
    SB.displayUtil:Draw()
    -- HACK
    if SB.DrawWorld ~= nil then
        SB.DrawWorld()
    end
end

function widget:DrawWorldPreUnit()
    if SB.view ~= nil then
        SB.stateManager:DrawWorldPreUnit()
        SB.view:DrawWorldPreUnit()
    end
end

function widget:DrawGroundPreForward()
    -- HACK
    if SB.DrawGroundPreForward ~= nil then
        SB.DrawGroundPreForward()
    end
end

function widget:MousePress(x, y, button)
    if SB.view ~= nil then
        return SB.stateManager:MousePress(x, y, button)
    end
end

function widget:MouseMove(x, y, dx, dy, button)
    if SB.view ~= nil then
        return SB.stateManager:MouseMove(x, y, dx, dy, button)
    end
end

function widget:MouseRelease(x, y, button)
    if SB.view ~= nil then
        return SB.stateManager:MouseRelease(x, y, button)
    end
end

function widget:MouseWheel(up, value)
    if SB.view ~= nil then
        return SB.stateManager:MouseWheel(up, value)
    end
end

function widget:KeyPress(key, mods, isRepeat, label, unicode)
    if SB.view ~= nil then
        return SB.stateManager:KeyPress(key, mods, isRepeat, label, unicode)
    end
end

function widget:GamePreload()
    MaybeLoad()
end

function widget:GameFrame(frameNum)
    if SB.view ~= nil then
        SB.stateManager:GameFrame(frameNum)
    end
    SB.displayUtil:OnFrame()
end

function widget:Update()
    if self._START_TIME and os.clock() - self._START_TIME >= 1 then
        if not RELOAD_GADGETS then
            SB.commandManager:execute(ResendCommand())
        end
        self._START_TIME = nil
    end
    if SB.view ~= nil then
        SB.stateManager:Update()
        SB.view:Update()
    end
    SB.executeDelayed("GameFrame")
    SB.displayUtil:Update()
end

-- Hackery copied from spring kernel in
-- order to take screenshots programatically
local screenTex = nil
local _vsx, _vsy = 0, 0
local function CleanTextures()
    if screenTex then
        gl.DeleteTexture(screenTex)
        screenTex = nil
    end
end

function CreateTextures()
    screenTex = gl.CreateTexture(_vsx, _vsy, {
        -- It means you can draw on the texture ;)
        fbo = true, min_filter = GL.LINEAR, mag_filter = GL.LINEAR,
        wrap_s = GL.CLAMP, wrap_t = GL.CLAMP,
    })
    if screenTex == nil then
        Log.Error("Error creating screen texture for vsx: " ..
            tostring(_vsx) .. ", vsy: " .. tostring(_vsy))
    end
end

function PerformDraw()
    local imgPath = SB.RequestScreenshotPath
    SB.RequestScreenshotPath = nil
    if not imgPath then
        return
    end

    Time.MeasureTime(function()
        if VFS.FileExists(imgPath, nil, VFS.RAW) then
            gl.DeleteTexture(imgPath)
            os.remove(imgPath)
        end
        gl.CopyToTexture(screenTex, 0, 0, 0, 0, _vsx, _vsy)
        --gl.Texture(0, screenTex)
        --gl.TexRect(0, _vsy, _vsx, 0)
        gl.RenderToTexture(screenTex, gl.SaveImage, 0, 0, _vsx, _vsy, imgPath)
        gl.Texture(0, false)
        gl.Texture(imgPath)

        -- Show the console (FIXME: game agnostic way)
        -- Spring.SendCommands("console 1")
    end, function(elapsed)
        Log.Notice(("[%.4fs] Saved project screenshot."):format(elapsed))
    end)
end

function widget:ViewResize()
    _vsx, _vsy = gl.GetViewSizes()
    CleanTextures()
    CreateTextures()
end

function widget:DrawScreenPost(vsx, vsy)
    if not screenTex then
        self:ViewResize()
    end
    PerformDraw()
end

function widget:Shutdown()
    CleanTextures()
end
