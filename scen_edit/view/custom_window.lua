CustomWindow = AbstractTriggerElementWindow:extends{}

function CustomWindow:init(opts)
    opts.element = opts.condition
    self:super("init", opts)
end

function CustomWindow:GetValidElementTypes()
    return SCEN_EDIT.metaModel.functionTypesByOutput[self.dataType.type]
end

function CustomWindow:GetWindowCaption()
    if self.mode == 'add' then
        return "New expression of type " .. self.dataType.type
    elseif self.mode == 'edit' then
        return "Edit expression of type " .. self.dataType.type
    end
end

function CustomWindow:AddParent()
    table.insert(self.parentObj, self.element)
end
