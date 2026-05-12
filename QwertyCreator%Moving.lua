-- Qwerty Creator for MovingEntities
local Creator = {}

function Creator.createEntity(config)
    local entity = {
        Config = config,
        EntityModel = nil,
        Debug = { OnEntitySpawned = function() end }
    }
    
    local success, objects = pcall(function()
        return game:GetObjects(config.Model)
    end)
    
    if success and objects and objects[1] then
        entity.EntityModel = objects[1]
        entity.EntityModel.Name = config.CustomName
        if not entity.EntityModel.PrimaryPart then
            entity.EntityModel.PrimaryPart = entity.EntityModel:FindFirstChildWhichIsA("BasePart") or entity.EntityModel:FindFirstChild("PrimaryPart")
        end
    else
        warn("Creator: Не удалось загрузить модель по ID " .. tostring(config.Model))
    end
    
    return entity
end

function Creator.spawnEntity(entity)
    local model = entity.EntityModel
    if not model or not model.PrimaryPart then return end
    
    local config = entity.Config
    local char = game.Players.LocalPlayer.Character
    local brokenRooms = {} 
    model.Parent = workspace

    -- 0. FLICKER LIGHTS (Мигание перед прилетом)
    if config.FlickerLights and config.FlickerLights[1] then
        task.spawn(function()
            for i = 1, 5 do
                for _, room in pairs(workspace.CurrentRooms:GetChildren()) do
                    for _, l in pairs(room:GetDescendants()) do
                        if l:IsA("Light") then l.Enabled = not l.Enabled end
                    end
                end
                task.wait(config.FlickerLights[2] or 0.5)
            end
            -- Возвращаем свет перед началом движения
            for _, room in pairs(workspace.CurrentRooms:GetChildren()) do
                for _, l in pairs(room:GetDescendants()) do
                    if l:IsA("Light") then l.Enabled = true end
                end
            end
        end)
    end

    -- 1. Свет
    if entity.Debug and entity.Debug.OnEntitySpawned then
        task.spawn(entity.Debug.OnEntitySpawned)
    end

    -- 2. Звук
    if config.Sound and config.Sound[1] ~= 0 then
        local s = Instance.new("Sound", model.PrimaryPart)
        s.SoundId = "rbxassetid://" .. tostring(config.Sound[1])
        s.Volume = config.Sound[2] and config.Sound[2].Volume or 1
        s.PlaybackSpeed = config.Sound[2] and config.Sound[2].Pitch or 1
        s.Looped = config.Sound[2] and config.Sound[2].Looped or false
        s.RollOffMaxDistance = 250
        s:Play()
    end

    -- 3. ПОЗИЦИЯ (behind = самая дальняя)
    local rooms = workspace.CurrentRooms:GetChildren()
    local spawnRoom = nil
    
    if config.SpawnLocation == "behind" then
        local minNum = 1000 
        for _, r in pairs(rooms) do
            local num = tonumber(r.Name)
            if num and num < minNum then
                minNum = num
                spawnRoom = r
            end
        end
    end
    
    spawnRoom = spawnRoom or workspace.CurrentRooms:FindFirstChild(tostring(game.ReplicatedStorage.GameData.LatestRoom.Value))
    local startNode = spawnRoom:WaitForChild("Door"):WaitForChild("Door")
    model:SetPrimaryPartCFrame(startNode.CFrame * CFrame.new(0, config.HeightOffset or 0, 0))

    -- 4. ДВИЖЕНИЕ
    local TS = game:GetService("TweenService")
    local targetRoomNum = game.ReplicatedStorage.GameData.LatestRoom.Value
    local targetRoom = workspace.CurrentRooms:FindFirstChild(tostring(targetRoomNum))
    local endNode = targetRoom.Door.Door
    
    local distance = (model.PrimaryPart.Position - endNode.Position).Magnitude + 300
    local duration = distance / config.Speed
    local tween = TS:Create(model.PrimaryPart, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
        CFrame = endNode.CFrame * CFrame.new(0, 0, -300)
    })

    -- 5. ЦИКЛ (ТРЯСКА, УБИЙСТВО, BREAKLIGHTS)
    local runLoop
    runLoop = game:GetService("RunService").Heartbeat:Connect(function()
        if not model.Parent or not char or not char:FindFirstChild("Humanoid") then 
            runLoop:Disconnect() 
            return 
        end
        
        local root = char:FindFirstChild("HumanoidRootPart")
        if root then
            local modelPos = model.PrimaryPart.Position
            local playerPos = root.Position
            local distToPlayer = (modelPos - playerPos).Magnitude
            
            -- CamShake
            if config.CamShake and config.CamShake[1] and distToPlayer < config.CamShake[3] then
                local intensity = (1 - (distToPlayer / config.CamShake[3])) * config.CamShake[2][1]
                char.Humanoid.CameraOffset = Vector3.new(
                    math.random(-intensity, intensity)/10,
                    math.random(-intensity, intensity)/10,
                    math.random(-intensity, intensity)/10
                )
            else
                char.Humanoid.CameraOffset = Vector3.new(0,0,0)
            end
            
            -- Kill
            if config.CanKill and distToPlayer < config.KillRange then
                char.Humanoid.Health = 0
                runLoop:Disconnect()
            end

            -- BreakLights
            if config.BreakLights then
                for _, room in pairs(workspace.CurrentRooms:GetChildren()) do
                    if not brokenRooms[room] then
                        local roomPos = room:GetPivot().Position
                        if (modelPos - roomPos).Magnitude < 60 then
                            brokenRooms[room] = true
                            for _, l in pairs(room:GetDescendants()) do
                                if l:IsA("Light") then 
                                    l.Enabled = false 
                                    if l.Name == "PointLight" or l.ClassName == "PointLight" then
                                         local s = Instance.new("Sound", l.Parent)
                                         s.SoundId = "rbxassetid://4548303061"
                                         s.Volume = 0.4
                                         s:Play()
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end)

    -- ЗАПУСК (Ждем DelayTime и летим)
    task.wait(config.DelayTime or 0)
    tween:Play()
    tween.Completed:Connect(function()
        model:Destroy()
        if runLoop then runLoop:Disconnect() end
        if char and char:FindFirstChild("Humanoid") then char.Humanoid.CameraOffset = Vector3.new(0,0,0) end
    end)
end

return Creator
