LoadModelCommand = AbstractCommand:extends{}
LoadModelCommand.className = "LoadModelCommand"

function LoadModelCommand:init(modelString)
    self.className = "LoadModelCommand"
    self.modelString = modelString
end

function LoadModelCommand:execute()
    SB.model:Clear()
    -- wait a bit if it's already loaded, but start immediately otherwise
    if Spring.GetGameFrame() ~= nil and Spring.GetGameFrame() > 30 then 
        GG.Delay.DelayCall(function()
            self:Load()
        end, {}, 2)
    else
        self:Load()
    end
end

function LoadModelCommand:Load()
    Log.Notice("Loading model...")
    local mission = loadstring(self.modelString)()
    SB.model:Load(mission)
end
