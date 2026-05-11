--]] Qwerty Creator

local Creator = {}

function Creator.createEntity(config)
    local entityData = {
        Config = config,
        EntityModel = nil,
        Debug = {}
    }
    return entityData
end

function Creator.spawnEntity(entity)
    task.spawn(function()
        local config = entity.Config
        
        -- Определяем дистанцию появления
        local offset = 1
        if config.SpawnLocation == "next next room" then offset = 2
        elseif config.SpawnLocation == "next next next room" then offset = 3 end
        
        local targetRoomNum = game.ReplicatedStorage.GameData.LatestRoom.Value + offset
        local targetRoom = workspace.CurrentRooms:WaitForChild(tostring(targetRoomNum), 10)

        if targetRoom then
            pcall(function()
                local model = game:GetObjects(config.Model)[1]
                model.Parent = workspace
                entity.EntityModel = model
                
                local pivot = targetRoom:FindFirstChild("RoomStart") or targetRoom:FindFirstChild("Base")
                if pivot and model.PrimaryPart then
                    model:SetPrimaryPartCFrame(pivot.CFrame * CFrame.new(0, 5, 0))
                end

                -- Настройка звука
                if config.Sound and config.Sound[1] then
                    local root = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
                    local sound = Instance.new("Sound", root)
                    sound.SoundId = "rbxassetid://" .. config.Sound[1]
                    sound.Volume = config.Sound[2].Volume or 1
                    sound.PlaybackSpeed = config.Sound[2].Pitch or 1
                    sound.Looped = config.Sound[2].Looped or false
                    sound:Play()
                end

                -- Вызов функции после спавна
                if entity.Debug.OnEntitySpawned then
                    entity.Debug.OnEntitySpawned()
                end

                -- ЛОГИКА УДАЛЕНИЯ ПО ВРЕМЕНИ (Delay)
                task.spawn(function()
                    if config.DelayTime then
                        task.wait(config.DelayTime) -- Ждем указанное время
                    else
                        -- Если DelayTime не указан, удаляем когда игрок уйдет далеко
                        repeat task.wait(2) until game.ReplicatedStorage.GameData.LatestRoom.Value > targetRoomNum + 1
                    end
                    
                    if model then 
                        model:Destroy() 
                    end
                end)
            end)
        end
    end)
end

return Creator
