SB.Include(SB_VIEW_ACTIONS_DIR .. "save_as_action.lua")
SaveAction = SaveAsAction:extends{}

function SaveAction:execute()
    if SB.projectDir == nil then
        self:super("execute")
    else
        local path = SB.projectDir
        Log.Notice("Saving project: " .. path .. " ...")
        local saveCommand = SaveCommand(path)
        SB.commandManager:execute(saveCommand, true)
        Log.Notice("Saved project.")
    end
end
