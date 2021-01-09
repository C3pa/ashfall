local this = {}
local staticConfigs = require("mer.ashfall.config.staticConfigs")
local skillModule = include("OtherSkills.skillModule")
local refController = require("mer.ashfall.referenceController")
--[[
    Returns a human readable timestamp of the given time (or else the current time)
]]
function this.hourToClockTime ( time )
    local gameTime = time or tes3.findGlobal("GameHour").value
    local formattedTime
    
    local isPM = false
    if gameTime > 12 then
        isPM = true
        gameTime = gameTime - 12
    end
    

    local hourString = math.floor(gameTime)
    -- if gameTime < 10 then 
    --     hourString = string.sub(gameTime, 1, 1)
    -- else
    --     hourString  = string.sub(gameTime, 1, 2)
    -- end

    local minuteTime = ( gameTime - hourString ) * 60
    local minuteString
    if minuteTime < 10 then
        minuteString = "0" .. string.sub( minuteTime, 1, 1 )
    else
        minuteString = string.sub ( minuteTime , 1, 2)
    end

    formattedTime = string.format("%d:%d %s", hourString, minuteString, (isPM and "pm" or "am"))

    return ( formattedTime )
end




--[[
    Transfers an amount from the field of one object to that of another
]]
function this.transferQuantity(source, target, sourceField, targetField, amount)
    source[sourceField] = source[sourceField] - amount
    target[targetField] = target[targetField] + amount
end

--[[
    Checks if there is any static object directly above the given reference.

    This is an expensive function! To see if the player is sheltered, use common.data.isSheltered instead.
]]

function this.getInTent()
    return (tes3.player.data.Ashfall.insideTent or tes3.player.data.Ashfall.insideCoveredBedroll)
end



function this.getTentActiveFromMisc(miscRef)
    return staticConfigs.tentMiscToActiveMap[miscRef.object.id:lower()]
end

function this.getTentMiscFromActive(activeRef)
    return staticConfigs.tentActiveToMiscMap[activeRef.object.id:lower()]
end

function this.checkRefSheltered(reference)

    local sheltered = false

    local tent
    reference = reference or tes3.player

    if this.getInside(reference) then
        return true
    end

    local results = tes3.rayTest{
        position = reference.position,
        direction = {0, 0, 1},
        findAll = true,
        maxDistance = 5000,
        ignore = {reference}
    }
    if results then
        for _, result in ipairs(results) do
            if result and result.reference and result.reference.object then
                sheltered = 
                    ( result.reference.object.objectType == tes3.objectType.static or
                    result.reference.object.objectType == tes3.objectType.activator ) == true

                if this.getTentMiscFromActive(result.reference) then
                    --We're covered by a tent, so we are a bit warmer
                    tent = result.reference
                end
                --this looks weird but it makes sense because we don't break out 
                --of the for loop if sheletered is false
                if sheltered == true then break end
            end
        end
    end
    if reference == tes3.player then
        event.trigger("Ashfall:SetTent", {
            insideTent = (tent ~= nil) and true or false,
            tent = tent
        })
    end
    return sheltered
end

function this.getInside(reference)
    return (
        reference.cell and
        reference.cell.isInterior and 
        not reference.cell.behavesAsExterior
    )
end


--TODO: Null needs to fix collision crashes on Disable/Delete
function this.yeet(reference)
    --timer.delayOneFrame(function()
        reference:disable()
        mwscript.setDelete{ reference = reference}
    --end)}
end

--[[
    Moves the player, designed for short movements 
    which probably won't change cell. but if a cell change
    is required, it uses positionCell as a fallback
]]
function this.movePlayer(e)
    --use positionCell if changing cell
    local orientation = e.orientation or tes3.player.orientation:copy()
    if tes3.player.cell ~= e.cell then
        tes3.positionCell{
            reference = tes3.player,
            position = e.position,
            orientation = orientation,
            cell = e.cell,
            teleportCompanions = false
        }
    else -- avoid positionCell because it sucks
        tes3.player.position = e.position
        tes3.player.orientation = orientation
    end
end

function this.isStack(reference)
    return ( 
        reference.attachments and
        reference.attachments.variables and 
        reference.attachments.variables.count > 1 
    )
end
--[[
    Allows the creation of messageboxes using buttons that each have their own callback.

    callback: optional function that gets called when the button is clicked

    tooltip: optional table with header and text that will display as a tooltip when the
        button is hovered over

    tooltipDisabled: optional tooltip for when a button has been disabled

    requirements: optional function that, if provided, determines whether the button will be
        call the callback when clicked, or be disabled + greyed out

    {
        message: string,
        buttons: [
            { 
                text: string, 
                callback?: function, 
                tooltip?: { 
                    header: string, 
                    text: string
                },
                tooltipDisabled: { 
                    header: string, 
                    text: string
                },
                requirements?: function,
                doesCancel = boolean --for cancel button compatibility with Right Click Menu Exit
            }
        ]
    }
]]
local messageBoxId = tes3ui.registerID("CustomMessageBox")
function this.messageBox(params)
    --[[
        button = 
    ]]--
    local message = params.message
    local buttons = params.buttons
    local sideBySide = params.sideBySide

    local menu = tes3ui.createMenu{ id = messageBoxId, fixedFrame = true }
    menu:getContentElement().childAlignX = 0.5
    tes3ui.enterMenuMode(messageBoxId)
    local title = menu:createLabel{id = tes3ui.registerID("Ashfall:MessageBox_Title"), text = message}

    local buttonsBlock = menu:createBlock()
    buttonsBlock.borderTop = 4
    buttonsBlock.autoHeight = true
    buttonsBlock.autoWidth = true
    if sideBySide then
        buttonsBlock.flowDirection = "left_to_right"
    else
        buttonsBlock.flowDirection = "top_to_bottom"
        buttonsBlock.childAlignX = 0.5
    end
    for i, data in ipairs(buttons) do
        local doAddButton = true
        if data.showRequirements then
            if data.showRequirements() ~= true then
                doAddButton = false
            end
        end
        if doAddButton then
            --If last button is a Cancel (no callback), register it for Right Click Menu Exit
            local buttonId = tes3ui.registerID("CustomMessageBox_Button")
            if data.doesCancel then
                buttonId = tes3ui.registerID("CustomMessageBox_CancelButton")
            end

            local button = buttonsBlock:createButton{ id = buttonId, text = data.text}

            local disabled = false
            if data.requirements then
                if data.requirements() ~= true then
                    disabled = true
                end
            end

            if disabled then
                button.widget.state = 2
            else
                button:register( "mouseClick", function()
                    if data.callback then
                        data.callback()
                    end
                    tes3ui.leaveMenuMode()
                    menu:destroy()
                end)
            end

            if not disabled and data.tooltip then
                button:register( "help", function()
                    this.createTooltip(data.tooltip)
                end)
            elseif disabled and data.tooltipDisabled then
                button:register( "help", function()
                    this.createTooltip(data.tooltipDisabled)
                end)
            end
        end
    end
end

--[[
    Checks if two refs are near each other, with 
    separate horizontal and vertical distance checks
    params:
        ref1, ref2
        distVertical, distHorizontal
]]
function this.getCloseEnough(e)
    local pos1 = tes3vector3.new(e.ref1.position.x, e.ref1.position.y, 0)
    local pos2 = tes3vector3.new(e.ref2.position.x, e.ref2.position.y, 0)
    local distHorizontal = pos1:distance(pos2)
    local distVertical = math.abs(e.ref1.position.z - e.ref2.position.z)
    return (distHorizontal < e.distHorizontal and distVertical < e.distVertical)
end

--Generic Tooltip with header and description
function this.createTooltip(e)
    local thisHeader, thisLabel = e.header, e.text
    local tooltip = tes3ui.createTooltipMenu()
    
    local outerBlock = tooltip:createBlock({ id = tes3ui.registerID("Ashfall:temperatureIndicator_outerBlock") })
    outerBlock.flowDirection = "top_to_bottom"
    outerBlock.paddingTop = 6
    outerBlock.paddingBottom = 12
    outerBlock.paddingLeft = 6
    outerBlock.paddingRight = 6
    outerBlock.maxWidth = 300
    outerBlock.autoWidth = true
    outerBlock.autoHeight = true    
    
    if thisHeader then
        local headerText = thisHeader
        local headerLabel = outerBlock:createLabel({ id = tes3ui.registerID("Ashfall:temperatureIndicator_header"), text = headerText })
        headerLabel.autoHeight = true
        headerLabel.width = 285
        headerLabel.color = tes3ui.getPalette("header_color")
        headerLabel.wrapText = true
        --header.justifyText = "center"
    end
    if thisLabel then
        local descriptionText = thisLabel
        local descriptionLabel = outerBlock:createLabel({ id = tes3ui.registerID("Ashfall:temperatureIndicator_description"), text = descriptionText })
        descriptionLabel.autoHeight = true
        descriptionLabel.width = 285
        descriptionLabel.wrapText = true
    end
    
    tooltip:updateLayout()
end

function this.recoverStats(e)
    local interval = e.interval
    local isResting = e.resting
    local endurance = tes3.mobilePlayer.endurance.base
    local isStunted = tes3.isAffectedBy{ reference = tes3.player, effect = tes3.effect.stuntedMagicka}
    local fFatigueReturnBase = tes3.findGMST(tes3.gmst.fFatigueReturnBase).value
    local fFatigueReturnMult = tes3.findGMST(tes3.gmst.fFatigueReturnMult).value
    local fEndFatigueMult = tes3.findGMST(tes3.gmst.fEndFatigueMult).value
    if isResting then
        local healthRecovery = interval * 0.1 * endurance
        tes3.modStatistic{ reference = tes3.player, name = "health", current = healthRecovery }
        if not isStunted then
            local intelligence = tes3.mobilePlayer.intelligence.base
            local fRestMagicMult = tes3.findGMST(tes3.gmst.fRestMagicMult).value
            local magickaRecovery = fRestMagicMult * intelligence * interval
        
            tes3.modStatistic{ reference = tes3.player, name = "magicka", current = magickaRecovery }
        end
    end
    local normalisedEndurance = math.clamp(endurance/100, 0.0, 1.0)
    local fatigueRecoveryBase = fFatigueReturnBase + fFatigueReturnMult * ( 1 - normalisedEndurance)
    local fatigueRecovery = fatigueRecoveryBase * fEndFatigueMult * endurance * interval

    tes3.modStatistic{ reference = tes3.player, name = "fatigue", current = fatigueRecovery }
end


--[[
    Create a popup with a slider that sets a table value
]]
local menuId = tes3ui.registerID("Ashfall:SliderPopup")
function this.createSliderPopup(params)
    assert(params.label)
    assert(params.varId)
    assert(params.table)
    --[[Optional params:
        jump - slider jump value
        okayCallback - function called on Okay
        cancelCallback - function called on Cancel
    ]]
    local menu = tes3ui.createMenu{ id = menuId, fixedFrame = true }
    tes3ui.enterMenuMode(menuId)
    --Slider
    local sliderBlock = menu:createBlock()
    sliderBlock.width = 500
    sliderBlock.autoHeight = true
    mwse.mcm.createSlider(
        menu,
        {
            label = params.label,
            min = params.min or 0,
            max = params.max or 100,
            jump = params.jump or 10,
            variable = mwse.mcm.createTableVariable{
                id = params.varId,
                table = params.table
            },
        }
    )
    local buttonBlock = menu:createBlock()
    buttonBlock.autoHeight = true
    buttonBlock.widthProportional = 1.0
    buttonBlock.childAlignX = 1.0
    --Okay
    local okayButton = buttonBlock:createButton{
        text = tes3.findGMST(tes3.gmst.sOK).value
    }
    okayButton:register("mouseClick",
        function()
            menu:destroy()
            tes3ui.leaveMenuMode(menuId)
            if params.okayCallback then
                timer.delayOneFrame(params.okayCallback)
            end
        end
    )
    --Cancel
    local cancelButton = buttonBlock:createButton{
        text = tes3.findGMST(tes3.gmst.sCancel).value
    }
    cancelButton:register("mouseClick",
        function()
            menu:destroy()
            tes3ui.leaveMenuMode(menuId)
            if params.cancelCallback then
                timer.delayOneFrame(params.cancelCallback)
            end
        end
    )
    menu:getTopLevelMenu():updateLayout()
end

local function setControlsDisabled(state)
    tes3.mobilePlayer.controlsDisabled = state
    tes3.mobilePlayer.jumpingDisabled = state
    tes3.mobilePlayer.attackDisabled = state
    tes3.mobilePlayer.magicDisabled = state
    tes3.mobilePlayer.mouseLookDisabled = state
end
function this.disableControls()
    setControlsDisabled(true)
end

function this.getUniqueCellId(cell)
    if cell.isInterior then
        return cell.id:lower()
    else
        return string.format("%s (%s,%s)",
        cell.id:lower(), 
        cell.gridX, 
        cell.gridY)
    end
end


function this.enableControls()
    setControlsDisabled(false)
    tes3.runLegacyScript{command = "EnableInventoryMenu"}
end
--[[
    Fades out, passes time then runs callback when finished
]]--
function this.fadeTimeOut( hoursPassed, secondsTaken, callback )
    local function fadeTimeIn()
        this.enableControls()
        callback()
        tes3.player.data.Ashfall.fadeBlock = false
    end
    tes3.player.data.Ashfall.fadeBlock = true
    tes3.fadeOut({ duration = 0.5 })
    this.disableControls()
    --Halfway through, advance gamehour
    local iterations = 10
    timer.start({
        type = timer.real,
        iterations = iterations,
        duration = ( secondsTaken / iterations ),
        callback = (
            function()
                local gameHour = tes3.findGlobal("gameHour")
                gameHour.value = gameHour.value + (hoursPassed/iterations)
            end
        )
    })
    --All the way through, fade back in
    timer.start({
        type = timer.real,
        iterations = 1,
        duration = secondsTaken,
        callback = (
            function()
                local fadeBackTime = 1
                tes3.fadeIn({ duration = fadeBackTime })
                timer.start({
                    type = timer.real,
                    iterations = 1,
                    duration = fadeBackTime, 
                    callback = fadeTimeIn
                })
            end
        )
    })
end

function this.iterateRefItems(ref)
    local function iterator()
        for _, stack in pairs(ref.object.inventory) do
            local item = stack.object
            local count = stack.count
            -- first yield stacks with custom data
            if stack.variables then
                for _, data in pairs(stack.variables) do
                    coroutine.yield(item, data.count, data)
                    count = count - data.count
                end
            end
            -- then yield all the remaining copies
            if count > 0 then
                coroutine.yield(item, count)
            end
        end
    end
    return coroutine.wrap(iterator)
end

--[[
    Restore lost fatigue to prevent collapsing
]]
function this.restoreFatigue()
    
    local previousFatigue = tes3.mobilePlayer.fatigue.current
    timer.delayOneFrame(function()
        local newFatigue = tes3.mobilePlayer.fatigue.current
        if previousFatigue >= 0 and newFatigue < 0 then
            tes3.mobilePlayer.fatigue.current = previousFatigue
        end
    end)
end
 
--[[
    Attempt to contract a disease
]]
local defaultChance = 1.0
local maxSurvivalEffect = 0.5
function this.tryContractDisease(spellID)
    local spell = tes3.getObject(spellID)
    local resistDisease = tes3.mobilePlayer.resistCommonDisease 
    if spell.castType == tes3.spellType.blight then
        resistDisease = tes3.mobilePlayer.resistBlightDisease 
    end

    local survival = skillModule.getSkill("Ashfall:Survival").value
    local resistEffect = math.remap( math.min(resistDisease, 100), 0, 100, 1.0, 0.0 )
    local survivalEffect =  math.remap( math.min(survival, 100), 0, 100, 1.0, maxSurvivalEffect )

    
    local catchChance = defaultChance * resistEffect * survivalEffect
    local roll= math.random()
    if roll < catchChance then
        if not tes3.player.object.spells:contains(spell) then
            tes3.messageBox(tes3.findGMST(tes3.gmst.sMagicContractDisease).value, spell.name)
            mwscript.addSpell{ reference = tes3.player, spell = spell  }
        end
    end
end

--[[
    Get a number between 0 and 1 based on the current day of the year, 
    where 0 is the middle of Winter and 1 is the middle of Summer
]]
local day
local month
function this.getSeasonMultiplier()
    day = day or tes3.worldController.day
    month = month or tes3.worldController.month
    local dayOfYear = day.value + tes3.getCumulativeDaysForMonth(month.value)
    local dayAdjusted = dayOfYear < 196 and dayOfYear  or ( 196 - ( dayOfYear - 196 ) ) 
    local seasonMultiplier = math.remap(dayAdjusted, 0, 196, 0, 1)
    return seasonMultiplier
end



function this.iterateRefType(refType, callback)
    for ref, _ in pairs(refController.controllers[refType].references) do
        --check requirements in case it's no longer valid
        if refController.controllers[refType]:requirements(ref) then
            if ref.sceneNode then
                callback(ref)
            end
        else
            --no longer valid, remove from ref list
            refController.controllers[refType].references[ref] = nil
        end
    end
end

function this.traverseRoots(roots)
    local function iter(nodes)
        for _, node in ipairs(nodes or roots) do
            if node then
                coroutine.yield(node)
                if node.children then
                    iter(node.children)
                end
            end
        end
    end
    return coroutine.wrap(iter)
end

function this.addDecal(reference, texturePath)
    for node in this.traverseRoots{reference.sceneNode} do
        if node.RTTI.name == "NiTriShape" then
            local texturing_property = node:getProperty(0x4)
            local base_map = texturing_property.maps[3]
            base_map.texture = niSourceTexture.createFromPath(texturePath)
        end
    end
end

local ID33 = tes3matrix33.new(1,0,0,0,1,0,0,0,1)

function this.rotationDifference(vec1, vec2)
    vec1 = vec1:normalized()
    vec2 = vec2:normalized()

    local axis = vec1:cross(vec2)
    local norm = axis:length()
    if norm < 1e-5 then
        return ID33:toEulerXYZ()
    end

    local angle = math.asin(norm)
    if vec1:dot(vec2) < 0 then
        angle = math.pi - angle
    end

    axis:normalize()

    local m = ID33:copy()
    m:toRotation(-angle, axis.x, axis.y, axis.z)
    return m:toEulerXYZ()
end

function this.getGroundBelowRef(e)
    local ref = e.ref 
    local rootHeight = e.rootHeight or 50
    local ignoreList = e.ignoreList
    if not ref then return end
    local height = rootHeight + 10
    local result = tes3.rayTest{
        position = {ref.position.x, ref.position.y, ref.position.z + height}, 
        direction = {0, 0, -1},
        ignore = ignoreList or {ref, tes3.player},
        returnNormal = true,
        useBackTriangles = true
    }
    return result
end


local function doIgnoreMesh(ref)
    local objType = ref.object.objectType
    if objType == tes3.objectType.static or objType == tes3.objectType.activator then
        return false
    end
    return true
end

function this.orientRefToGround(params)
    local ref = params.ref
    local maxSteepness = params.maxSteepness
    local ignoreList = params.ignoreList or {}
    local rootHeight = params.rootHeight or 0

    table.insert(ignoreList, tes3.player)
    for thisRef in ref.cell:iterateReferences() do
        if doIgnoreMesh(thisRef) then
            table.insert(ignoreList, thisRef)
        end
    end

    local result = this.getGroundBelowRef({ref = ref, ignoreList = ignoreList, rootHeight = rootHeight})
    if not result then 
        --This only happens when the ref is 
        --beyond the edge of the active cells
        return false
    end
    ref.position = { ref.position.x, ref.position.y, result.intersection.z }
    local UP = tes3vector3.new(0,0,1)
    
    local newOrientation = this.rotationDifference(UP, result.normal)
    
    if maxSteepness then
        newOrientation.x = math.clamp(newOrientation.x, (0-maxSteepness), maxSteepness)
        newOrientation.y = math.clamp(newOrientation.y, (0-maxSteepness), maxSteepness)
        
    end
    newOrientation.z = ref.orientation.z

    ref.orientation = newOrientation
    return true
end


--Cooking functions

--How much water heat affects stew cook speed
function this.calculateWaterHeatEffect(waterHeat)
    return math.remap(waterHeat, staticConfigs.hotWaterHeatValue, 100, 1, 10)
end

function this.calculateStewWarmthBuff(waterHeat)
    return math.remap(waterHeat, staticConfigs.hotWaterHeatValue, 100, 10, 15)
end

--Use survival skill to determine how long a buff should last
function this.calculateStewBuffDuration()
    return math.remap(skillModule.getSkill("Ashfall:Survival").value, 0, 100, 4, 16)
end

--Use survival skill to determine how strong a buff should be
function this.calculateStewBuffStrength(value, min, max)
    local effectValue = math.remap(value, 0, 100, min, max)
    local skillEffect = math.remap(skillModule.getSkill("Ashfall:Survival").value, 0, 100, 0.25, 1.0)
    return effectValue * skillEffect
end

--Use survival skill to determine how long a buff should last
function this.calculateTeaBuffDuration(amount, maxDuration)
    --Drinking more than limit doesn't increase duration
    local minDuration = 0.5
    local amountLimitLow = 0
    local amountLimitHigh = 50
    amount = math.clamp(amount, amountLimitLow, amountLimitHigh)
    local duration = math.remap(amount, 0, amountLimitHigh, minDuration, maxDuration)
    --Max survival skill doubles duration
    local survivalSkill = skillModule.getSkill("Ashfall:Survival").value
    local skillMulti =  math.remap(survivalSkill, 0, 100, 1.0, 2.0)
    return duration * skillMulti
end

return this