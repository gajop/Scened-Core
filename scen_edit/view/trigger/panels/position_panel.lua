PositionPanel = AbstractTypePanel:extends{}

function PositionPanel:MakePredefinedOpt()
    --PREDEFINED
    local stackPositionPanel = MakeComponentPanel(self.parent)
    self.cbPredefined = Checkbox:New {
        caption = "Predefined position: ",
        right = 100 + 10,
        x = 1,
        checked = false,
        parent = stackPositionPanel,
    }
    table.insert(self.radioGroup, self.cbPredefined)
    self.btnPredefined = Button:New {
        caption = '...',
        right = 40,
        width = 60,
        height = SB.conf.B_HEIGHT,
        parent = stackPositionPanel,
        position = nil,
    }
    self.OnSelectPosition = function(position)
        self.btnPredefined.position = position
        self.btnPredefined.caption = 'pos'
        self.btnPredefined.tooltip = "(" .. tostring(position.x) .. ", " .. tostring(position.y) .. ", " .. tostring(position.z) .. ")"
        self.btnPredefined:Invalidate()
        if not self.cbPredefined.checked then
            self.cbPredefined:Toggle()
        end
    end
    self.btnPredefined.OnClick = {
        function()
            SB.stateManager:SetState(SelectPositionState(self.OnSelectPosition))
        end
    }
    self.btnPredefinedZoom = Button:New {
        caption = "",
        right = 1,
        width = SB.conf.B_HEIGHT,
        height = SB.conf.B_HEIGHT,
        parent = stackPositionPanel,
        tooltip = "Select position",
        padding = {2, 2, 2, 2},
        children = {
            Image:New {
                file = SB_IMG_DIR .. "position-marker.png",
                height = "100%",
                width = "100%",
            },
        },
        OnClick = {
            function()
                local position = self.btnPredefined.position
                if position ~= nil then
                    Spring.MarkerAddPoint(position.x, position.y, position.z, "")
                end
            end
        }
    }
end

function PositionPanel:UpdateModel(field)
    if self.cbPredefined and self.cbPredefined.checked and self.btnPredefined.position ~= nil then
        field.type = "pred"
        field.value = self.btnPredefined.position
        return true
    elseif self.cbSpecialPosition and self.cbSpecialPosition.checked then
        field.type = "spec"
        field.name = self.cmbSpecialPosition.items[self.cmbSpecialPosition.selected]
        return true
    end
    return self:super('UpdateModel', field)
end

function PositionPanel:UpdatePanel(field)
    if field.type == "pred" then
        if not self.cbPredefined.checked then
            self.cbPredefined:Toggle()
        end
        self.OnSelectPosition(field.value)
        return true
    elseif field.type == "spec" then
        if not self.cbSpecialPosition.checked then
            self.cbSpecialPosition:Toggle()
        end
        self.cmbSpecialPosition:Select(1) --TODO:fix it
        return true
    end
    return self:super('UpdatePanel', field)
end
