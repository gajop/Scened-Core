SB.Include(SB_VIEW_DIR .. "editor_view.lua")
GrassEditorView = EditorView:extends{}

function GrassEditorView:init()
    self:super("init")

    self.btnAddGrass = TabbedPanelButton({
        x = 0,
        y = 0,
        tooltip = "Add grass",
        children = {
            TabbedPanelImage({ file = SB_IMG_DIR .. "terrain_height.png" }),
            TabbedPanelLabel({ caption = "Add" }),
        },
        OnClick = {
            function()
                SB.stateManager:SetState(GrassEditingState(self))
            end
        },
    })

    self:AddField(NumericField({
        name = "size",
        value = 100,
        minValue = 10,
        maxValue = 5000,
        title = "Size:",
        tooltip = "Size of the paint brush",
    }))

    local children = {
        self.btnAddGrass,
        ScrollPanel:New {
            x = 0,
            y = 80,
            bottom = 30,
            right = 0,
            borderColor = {0,0,0,0},
            horizontalScrollbar = false,
            children = { self.stackPanel },
        },
    }
    self:Finalize(children)
end

function GrassEditorView:IsValidTest(state)
    return state:is_A(TerrainChangeTextureState)
end