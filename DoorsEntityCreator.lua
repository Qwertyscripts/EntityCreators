--]] Qwerty Creator

local Creator = {}

function Creator.createEntity(config)
    return {
        Config = config,
        EntityModel = nil,
        Debug = { OnEntitySpawned = function() end }
    }
end

function Creator.spawnEntity(entityData)
    local config = entityData.Config
    local latestRoom = game.ReplicatedStorage:WaitForChild("GameData"):WaitForChild("LatestRoom").Value
    
    local targetRoom = latestRoom
    if config.SpawnLocation == "next next room" then targetRoom = latestRoom + 2 end
    
    local spawnRoom = workspace:WaitForChild("CurrentRooms"):WaitForChild(tostring(targetRoom), 10)
    if not spawnRoom then return end
    
    local success, model = pcall(function() 
        local objects = game:GetObjects(config.Model)
        local asset = objects[1] -- ИСПРАВЛЕНО: Строго берем первый элемент массива модели
        if asset then
            return asset
        end
    end)
    
    if not success or not model then
        model = Instance.new("Model")
        local p = Instance.new("Part", model) p.Name = "PrimaryPart" p.Size = Vector3.new(4,5,4) p.Transparency = 1
        model.PrimaryPart = p
    end
    
    model.Name = config.CustomName or "CustomEntity"
    entityData.EntityModel = model
    
    -- ИСПРАВЛЕНО: Отключение коллизии (No-Clip), чтобы свободно проходить сквозь монстра
    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
            part.Anchored = true -- Фиксируем в воздухе, чтобы детали не падали под карту
        end
    end
    
    local startPart = spawnRoom:FindFirstChild("Entrance") or spawnRoom.PrimaryPart
    if startPart then model:SetPrimaryPartCFrame(startPart.CFrame * CFrame.new(0, 2, 0)) end
    model.Parent = workspace
    
    local pPart = model:WaitForChild("PrimaryPart", 5)
    
    if pPart and config.Sound and type(config.Sound) == "table" then
        local sound = Instance.new("Sound", pPart)
        sound.SoundId = "rbxassetid://" .. tostring(config.Sound[1])
        local sArgs = config.Sound[2]
        if sArgs then
            sound.Volume = sArgs.Volume or 1
            sound.PlaybackSpeed = sArgs.Pitch or 1
            sound.Looped = sArgs.Looped or false
        end
        sound:Play()
    end
    
    -- ИСПРАВЛЕНО: Точное чтение CamShake формата {true, {6, 30, 1, 1}, 100}
    if config.CamShake and config.CamShake[1] == true and pPart then
        task.spawn(function()
            local cam = workspace.CurrentCamera
            local sParams = config.CamShake[2] -- Вложенный массив параметров {6, 30, 1, 1}
            local maxDist = config.CamShake[3] or 100 -- Дистанция (100)
            while model.Parent do
                local char = game.Players.LocalPlayer.Character
                if char and char:FindFirstChild("HumanoidRootPart") then
                    local dist = (char.HumanoidRootPart.Position - pPart.Position).Magnitude
                    if dist <= maxDist then
                        -- Извлекаем первый индекс из подмассива (силу тряски 6)
                        local forceNumber = (sParams and sParams[1]) or 5
                        local intensity = forceNumber * (1 - (dist / maxDist)) / 100
                        cam.CFrame = cam.CFrame * CFrame.Angles(
                            math.random(-10,10)*intensity, 
                            math.random(-10,10)*intensity, 
                            math.random(-10,10)*intensity
                        )
                    end
                end
                task.wait(0.03)
            end
        end)
    end
    
    if entityData.Debug and entityData.Debug.OnEntitySpawned then
        task.spawn(entityData.Debug.OnEntitySpawned)
    end
end

return Creator
