# 🛠 Qwerty Creator API

Легкий и удобный API для создания кастомных сущностей в игре **DOORS** (Roblox). 
Спроектирован специально для использования в фанатских модификациях, таких как **Floor 2**.

## 🚀 Как использовать

Чтобы подключить API в свой скрипт, используйте `loadstring`:

```lua
local Creator = loadstring(game:HttpGet("ССЫЛКА_НА_RAW_ФАЙЛ"))()
```

## 📂 Пример создания монстра

Ниже приведен пример создания статичной сущности, которая появится через 2 комнаты:

```lua
local Entity = Creator.createEntity({
    CustomName = "Trauma",
    Model = "rbxassetid://6685956411", 
    SpawnLocation = "next next room", 
    Sound = { 5375147888, { Volume = 1.5, Pitch = 0.95, Looped = true } },
})

-- Функция, которая сработает при спавне
Entity.Debug.OnEntitySpawned = function()
    local primaryPart = Entity.EntityModel:WaitForChild("PrimaryPart", 10)
    if primaryPart then
        local light = Instance.new("PointLight", primaryPart)
        light.Color = Color3.fromRGB(255, 0, 0)
        light.Brightness = 20
        light.Range = 35
    end
end

-- Заспавнить сущность в мир
Creator.spawnEntity(Entity)
```

## ⚙️ Настройки (Config)


| Параметр | Описание |
| :--- | :--- |
| **CustomName** | Имя вашей сущности |
| **Model** | ID модели в формате `rbxassetid://...` |
| **SpawnLocation** | Где появится (`next room`, `next next room`, `next next next room`) |
| **Sound** | Таблица со звуком: `{ ID, { Volume, Pitch, Looped } }` |

## 🛠 Особенности
- **Авто-очистка**: Сущность автоматически удаляется, когда заканчивается "Delay".
- **Гибкость**: Легкая настройка через Debug-функции.
- **Минимализм**: Работает без тяжелых внешних зависимостей.

---
*Разработано для использования в экзекуторах уровня Solara v3 и выше.*
