local common = require ("mer.ashfall.common.common")
local CampfireUtil = require("mer.ashfall.camping.campfire.CampfireUtil")
local foodConfig = common.staticConfigs.foodConfig
local hungerController = require("mer.ashfall.needs.hungerController")
local skillSurvivalGrillingIncrement = 5
local patinaController = require("mer.ashfall.camping.patinaController")

----------------------------
--Grilling
-----------------------------


--How much fuel level affects grill cook speed
local function calculateCookMultiplier(heatLevel)
    return 350 * math.min(math.remap(heatLevel, 0, 10, 0.5, 2.5), 2.5)
end

--How much ingredient weight affects grill cook speed
local function calculateCookWeightModifier(ingredObject)
    return math.clamp(math.remap(ingredObject.weight, 1, 2, 1, 0.5), 0.25, 4.0)
end

--Checks if the ingredient has been placed on a campfire
local function findGriller(ingredient)


    local result = common.helper.getGroundBelowRef{ ref = ingredient}
    if result and result.reference then
        --Find cooking pot attached to campfire
        local node = result.object

        local onGrill
        local grillNodes = {
            SWITCH_BASE = true,
            ATTACH_GRILL = true,
            ATTACH_FIREWOOD = true,
            ASHFALL_GRILLER = true
        }
        while node and node.parent do
            if grillNodes[node.name:upper()] then
                onGrill = true
                break
            else
                node = node.parent
            end
        end
        --Node below ingredient is a cooking pot node
        if onGrill then
            return result.reference
        end
    else
        common.log:debug("ray return nothing")
    end
end



local function resetCookingTime(ingredRef)
    if not common.helper.isStack(ingredRef) and ingredRef.data then
        ingredRef.data.lastCookUpdated = nil
    end
end

local function startCookingIngredient(ingredient, timestamp)

    --If you placed a stack, return all but one to the player
    if common.helper.isStack(ingredient) then
        local count = ingredient.attachments.variables.count
        mwscript.addItem{ reference = tes3.player, item = ingredient.object, count = (count - 1) }
        ingredient.attachments.variables.count = 1
    else
        --only check data for non-stack I guess?
        if ingredient.data.grillState == "burnt" then
            common.log:trace("Already burnt")
            return
        end
    end
    timestamp = timestamp or tes3.getSimulationTimestamp()
    ingredient.data.lastCookUpdated = timestamp
    tes3.messageBox("%s begins to cook.", ingredient.object.name)
    tes3.playSound{ sound = "potion fail", pitch = 0.8, reference = ingredient }

    -- local smoke = tes3.loadMesh("ashfall\\cookingSmoke.nif"):clone()
    -- ingredient.sceneNode:attachChild(smoke, true)
    -- ingredient.sceneNode:update()
    -- ingredient.sceneNode:updateNodeEffects()
end


local function addGrillPatina(campfire,interval)
    if campfire.sceneNode and campfire.data.grillId then

        local grillNode = campfire.sceneNode:getObjectByName("ATTACH_STAND")
            or campfire.sceneNode:getObjectByName("ATTACH_GRILL")
            or campfire.sceneNode:getObjectByName("SWITCH_GRILL")
        local patinaAmount = campfire.data.grillPatinaAmount or 0
        local newAmount = math.clamp(patinaAmount+ interval * 100, 0, 100)
        local didAddPatina = patinaController.addPatina(grillNode, newAmount)
        if didAddPatina then
            campfire.data.grillPatinaAmount = newAmount
            common.log:debug("Added patina to %s node, new amount: %s",grillNode, campfire.data.grillPatinaAmount)
        else
            common.log:debug("Mesh incompatible with patina mechanic, did not apply")
        end
    end
end

local function grillFoodItem(ingredReference, timestamp)
    --Can only grill certain types of food
    if foodConfig.getGrillValues(ingredReference.object) then
        local campfire = findGriller(ingredReference)
        if campfire then
            if campfire.data.isLit then
                if common.helper.isStack(ingredReference) or ingredReference.data.lastCookUpdated == nil then
                    startCookingIngredient(ingredReference, timestamp)
                    return
                end

                ingredReference.data.lastCookUpdated = ingredReference.data.lastCookUpdated or timestamp
                ingredReference.data.cookedAmount = ingredReference.data.cookedAmount or 0

                local difference = timestamp - ingredReference.data.lastCookUpdated
                if difference > 0.008 then

                    addGrillPatina(campfire, difference)
                    ingredReference.data.lastCookUpdated = timestamp

                    local thisCookMulti = calculateCookMultiplier(CampfireUtil.getHeat(campfire.data))
                    local weightMulti = calculateCookWeightModifier(ingredReference.object)
                    ingredReference.data.cookedAmount = ingredReference.data.cookedAmount + ( difference * thisCookMulti * weightMulti)
                    local cookedAmount = ingredReference.data.cookedAmount

                    local burnLimit = hungerController.getBurnLimit()
                    --Cooked your food
                    local justCooked = cookedAmount > 100
                        and cookedAmount < burnLimit
                        and ingredReference.data.grillState ~= "cooked"
                        and ingredReference.data.grillState ~= "burnt"

                    --burned your food
                    local justBurnt = cookedAmount > burnLimit
                        and ingredReference.data.grillState ~= "burnt"

                    if justCooked then
                        --You need a grill to properly cook food
                        if campfire.data.hasGrill then
                            ingredReference.data.grillState = "cooked"
                            tes3.playSound{ sound = "potion fail", pitch = 0.7, reference = ingredReference }
                            common.skills.survival:progressSkill(skillSurvivalGrillingIncrement)
                            event.trigger("Ashfall:ingredCooked", { reference = ingredReference})
                        else
                            --if no grill attached, then the food always burns
                            justBurnt = true
                        end
                    end

                    if justBurnt then
                        ingredReference.data.grillState = "burnt"
                        tes3.playSound{ sound = "potion fail", pitch = 0.9, reference = ingredReference }
                        event.trigger("Ashfall:ingredCooked", { reference = ingredReference})
                    end

                    --Only play sounds/messages if not transitioning from cell
                    --Check how long has passed as a bit of a hack
                    local justChangedCell = difference > 0.01
                    if not justChangedCell then
                        if justBurnt then
                            tes3.messageBox("%s has become burnt.", ingredReference.object.name)
                        elseif justCooked then
                            tes3.messageBox("%s is fully cooked.", ingredReference.object.name)
                        end
                    end

                    tes3ui.refreshTooltip()
                end
            else
                --reset grill time if campfire is unlit
                resetCookingTime(ingredReference)
            end
        else
            --reset grill time if not placed on a campfire
            resetCookingTime(ingredReference)
        end
    end
end


--update any food that is currently grilling
local function grillFoodSimulate(e)
    for _, cell in pairs( tes3.getActiveCells() ) do
        for ingredient in cell:iterateReferences(tes3.objectType.ingredient) do
            grillFoodItem(ingredient, e.timestamp)
        end
        for ingredient in cell:iterateReferences(tes3.objectType.alchemy) do
            grillFoodItem(ingredient, e.timestamp)
        end
    end
end
event.register("simulate", grillFoodSimulate)




local function doAddingredToStew(campfire, reference)
    if not foodConfig.getStewBuffForId(reference.object) then
        tes3.messageBox("%s can not be added to a stew.", reference.object.name)
        common.helper.pickUp(reference)
        return
    end

    if not campfire.data.waterCapacity then
        tes3.messageBox("Cooking pot must be attached to a campfire.")
        common.helper.pickUp(reference)
        return
    end

    local amount = common.helper.getStackCount(reference)
    local amountAdded = CampfireUtil.addIngredToStew{
        campfire = campfire,
        count = amount,
        item = reference.object
    }

    common.log:debug("amountAdded: %s", amountAdded)
    if amountAdded < amount then
        reference.attachments.variables.count = reference.attachments.variables.count - amountAdded

        if amountAdded >= 1 then
            tes3.messageBox("Added %s %s to stew.", amountAdded, reference.object.name)
        else
            tes3.messageBox("You cannot add any more %s.", foodConfig.getFoodTypeResolveMeat(reference.object):lower())
        end
        common.helper.pickUp(reference)
    else
        tes3.messageBox("Added %s %s to stew.", amountAdded, reference.object.name)
        common.helper.yeet(reference)
    end
    return

end

--Place food on a grill or into a pot
local function foodPlaced(e)

    if e.reference and e.reference.object then
        local isIngredient = e.reference.object.objectType == tes3.objectType.ingredient
        if not isIngredient then return end

        timer.frame.delayOneFrame(function()
            --place in pot
            local campfire = CampfireUtil.getPlacedOnContainer()
            if campfire then
                local utensilData = CampfireUtil.getDataFromUtensilOrCampfire{
                    dataHolder = campfire,
                    object = campfire.object
                }
                local hasWater = campfire.data.waterAmount and campfire.data.waterAmount > 0
                local hasLadle = campfire.data.ladle == true
                --ingredient placed on a cooking pot with water in it
                if hasWater and hasLadle and utensilData and utensilData.holdsStew then
                    doAddingredToStew(campfire, e.reference)
                end
            elseif foodConfig.getGrillValues(e.reference.object) then
                local timestamp = tes3.getSimulationTimestamp()
                local ingredReference = e.reference
                --Reset grill time for meat and veges
                resetCookingTime(ingredReference)
                grillFoodItem(ingredReference, timestamp)
            end
        end)
    end
end
event.register("referenceSceneNodeCreated" , foodPlaced)

--Empty a cooking pot or kettle, reseting all data
local function clearUtensilData(e)

    common.log:debug("Clearing Utensil Data")
    local campfire = e.campfire
    campfire.data.stewProgress = nil
    campfire.data.stewLevels = nil
    campfire.data.waterAmount = nil
    campfire.data.waterHeat = nil
    campfire.data.waterType = nil
    campfire.data.teaProgress = nil


    if e.removeUtensil then
        campfire.data.utensil = nil
        campfire.data.ladle = nil
        campfire.data.utensilId = nil
        campfire.data.utensilData = nil
        campfire.data.utensilPatinaAmount = nil
    end
    event.trigger("Ashfall:UpdateAttachNodes", {campfire = campfire})
end
event.register("Ashfall:Campfire_clear_utensils", clearUtensilData)