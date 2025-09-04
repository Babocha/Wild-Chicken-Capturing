-- babo_chickencap - client
-- Dépendances: ox_lib, ox_target

local function randFrom(t)
  return (type(t)=='table' and #t>0) and t[math.random(1,#t)] or nil
end

-- Emotes helpers (dpEmotes/qb-emotes, etc.)
local function playEmoteList(list, duration)
  if not Config.Emotes or not Config.Emotes.UseEmotes then
    if duration and duration > 0 then Wait(duration) end
    return
  end
  local prefix = Config.Emotes.EmoteCommandPrefix or 'e'
  local stop   = Config.Emotes.EmoteStopCommand or 'e c'
  local em = randFrom(list or {})
  if em and em ~= '' then ExecuteCommand(('%s %s'):format(prefix, em)) end
  if duration and duration > 0 then Wait(duration) end
  ExecuteCommand(stop)
end

-- ===== State keys =====
local WILD_KEY       = 'babo_wild'      -- statebag bool
local BAIT_UNTIL_KEY = 'babo_baitUntil' -- client: tick de fin en ms (GetGameTimer)
local HEN_HASH       = joaat('a_c_hen')

-- ===== Blips de zones (configurable) =====
local ZoneBlips = {}

local function setupZoneBlips()
  local Z = Config.Wild and Config.Wild.Zones
  if not Z or type(Z) ~= 'table' then return end

  local B = (Config.Wild.Blips or {})
  if B.enabled == false then return end

  local sprite      = B.sprite      or 141   -- icône (change-le si tu veux)
  local color       = B.color       or 5
  local scale       = B.scale       or 0.85
  local name        = B.name        or 'Wild chickens'
  local radiusColor = B.radiusColor or 25
  local radiusAlpha = B.radiusAlpha or 80

  for _, z in ipairs(Z) do
    local c = z.center; local r = (z.radius or 120.0) + 0.0
    if c and r > 0.0 then
      -- disque semi-transparent
      local br = AddBlipForRadius(c.x, c.y, c.z, r)
      SetBlipColour(br, radiusColor)
      SetBlipAlpha(br, radiusAlpha)

      -- blip central
      local bc = AddBlipForCoord(c.x, c.y, c.z)
      SetBlipSprite(bc, sprite)
      SetBlipColour(bc, color)
      SetBlipScale(bc, scale)
      BeginTextCommandSetBlipName('STRING')
      AddTextComponentString(name)
      EndTextCommandSetBlipName(bc)

      ZoneBlips[#ZoneBlips+1] = br
      ZoneBlips[#ZoneBlips+1] = bc
    end
  end
end

local function clearZoneBlips()
  for _, b in ipairs(ZoneBlips) do if DoesBlipExist(b) then RemoveBlip(b) end end
  ZoneBlips = {}
end

AddEventHandler('onResourceStart', function(res)
  if res == GetCurrentResourceName() then CreateThread(setupZoneBlips) end
end)
AddEventHandler('onResourceStop', function(res)
  if res == GetCurrentResourceName() then clearZoneBlips() end
end)


-- ===== Helpers entity =====
local function isValidEntity(ent)
  return ent and ent ~= 0 and DoesEntityExist(ent) and GetEntityType(ent) == 1
end

local function isWild(entity)
  if not isValidEntity(entity) then return false end
  local st = Entity(entity).state
  return st and st[WILD_KEY] == true
end

local function isBaited(entity)
  if not isValidEntity(entity) then return false end
  local st    = Entity(entity).state
  local endMs = st and st[BAIT_UNTIL_KEY] or 0
  return (endMs or 0) > GetGameTimer()
end

local function canCapture(entity)
  if not isValidEntity(entity) then return false end
  if Config.RequireBaitToCapture then
    return isBaited(entity)
  else
    return true
  end
end

-- === Zone helpers ===
local function getZoneByName(name)
  for _, z in ipairs((Config.Wild and Config.Wild.Zones) or {}) do
    if z.name == name then return z end
  end
  return nil
end

local function pickPointInCircle(center, radius)
  local r = math.sqrt(math.random()) * radius
  local t = math.random() * 2.0 * math.pi
  return vector3(center.x + r * math.cos(t), center.y + r * math.sin(t), center.z)
end

local function requestCtrl(ent, tries)
  tries = tries or 5
  if NetworkHasControlOfEntity(ent) then return true end
  NetworkRequestControlOfEntity(ent)
  local ok = false
  for i=1,tries do
    Wait(50)
    if NetworkHasControlOfEntity(ent) then ok = true break end
  end
  return ok
end

-- Fait errer la poule DANS sa zone et la remet dedans si elle sort
local function startWanderInZone(ped, zoneName)
  local Z = getZoneByName(zoneName)
  if not Z then return end
  local center = vector3(Z.center.x, Z.center.y, Z.center.z)
  local radius = (Z.radius or 120.0) * 1.0
  local inner  = math.max(5.0, radius - 3.0)        -- rayon cible pour errer
  local margin = math.min(12.0, radius * 0.15)      -- marge avant la limite

  -- Tâche d’errance “dans une aire” si dispo, sinon wander simple
  if requestCtrl(ped) and TaskWanderInArea then
    ClearPedTasks(ped)
    TaskWanderInArea(ped, center.x, center.y, center.z, inner, 1.0, 5.0)
    SetPedKeepTask(ped, true)
  else
    TaskWanderStandard(ped, 10.0, 10)
  end

  -- Boucle de contrôle des limites (suspendue si appât actif)
  CreateThread(function()
    while DoesEntityExist(ped) do
      Wait(2500)
      -- ne force rien si appât : on laisse la poule venir vers le joueur
      local st = Entity(ped).state
      local baitEnd = (st and st['babo_baitUntil']) or 0
      if baitEnd > GetGameTimer() then goto continue end

      local pos  = GetEntityCoords(ped)
      local dist = #(pos - center)

      if dist > radius then
        -- déborder : on la renvoie à un point à l’intérieur
        if requestCtrl(ped) then
          local dest = pickPointInCircle(center, radius - 2.0)
          ClearPedTasks(ped)
          TaskGoToCoordAnyMeans(ped, dest.x, dest.y, dest.z, 1.2, 0, 0, 786603, 0.0)
        end
      elseif dist > (radius - margin) then
        -- proche de la limite : on la “pousse” légèrement vers l’intérieur
        if requestCtrl(ped) then
          local dest = pickPointInCircle(center, radius - margin - 1.0)
          TaskGoToCoordAnyMeans(ped, dest.x, dest.y, dest.z, 1.2, 0, 0, 786603, 0.0)
        end
      end

      ::continue::
    end
  end)
end



-- ===== ox_target: options sur le MODEL "A_C_HEN" =====
CreateThread(function()
  exports.ox_target:addModel(HEN_HASH, {
    -- Bait
    {
      label = 'Bait (uses feed)',
      icon = 'fa-solid fa-seedling',
      distance = 2.0,
      canInteract = function(entity, distance)
        if not isValidEntity(entity) then return false end
        if not isWild(entity) then return false end
        return (not isBaited(entity)) and (distance or 99) <= 2.0
      end,
      onSelect = function(data)
        local entity = data.entity
        if not isValidEntity(entity) or not isWild(entity) then return end

        local dur = Config.BaitDurationMs or 6000
        -- jouer l'émote en même temps que la progress
        CreateThread(function() playEmoteList(Config.Emotes and Config.Emotes.Bait, dur) end)
        local ok = lib.progressCircle({
          duration = dur,
          label = 'Sprinkling feed...',
          position = 'bottom',
          useWhileDead = false,
          canCancel = true,
          disable = { move=true, car=true, combat=true },
        })
        if not ok then return end

        if not isValidEntity(entity) then return end
        local netId = NetworkGetNetworkIdFromEntity(entity)
        if netId and netId ~= 0 then
          TriggerServerEvent('babo:wild:bait', netId)
        end
      end
    },
    -- Capture
    {
      label = 'Capture',
      icon  = 'fa-solid fa-hand',
      distance = 2.5,
      canInteract = function(entity, distance)
        if not isValidEntity(entity) then return false end
        if not isWild(entity) then return false end
        if not canCapture(entity) then return false end
        return (distance or 99) <= (Config.CaptureRange or 2.5)
      end,
      onSelect = function(data)
        local entity = data.entity
        if not isValidEntity(entity) or not isWild(entity) then return end

        local netId = NetworkGetNetworkIdFromEntity(entity)
        if not netId or netId == 0 then return end

        -- Pré-validation + verrou serveur (évite "not baited" pendant la progress)
        local ok, err = lib.callback.await('babo:wild:captureStart', false, netId)
        if not ok then
          if err and lib and lib.notify then lib.notify({ type='error', description=err }) end
          return
        end

        local dur = Config.CaptureDuration or 6000
        CreateThread(function() playEmoteList(Config.Emotes and Config.Emotes.Capture, dur) end)
        local prog = lib.progressCircle({
          duration = dur,
          label    = 'Catching...',
          position = 'bottom',
          useWhileDead = false,
          canCancel = true,
          disable = { move=true, car=true, combat=true },
        })
        if not prog then
          -- si le joueur annule, le lock expirera côté serveur
          return
        end

        TriggerServerEvent('babo:wild:capture', netId)
      end
    }
  })
end)

-- ===== Spawn demandé par le serveur =====
RegisterNetEvent('babo:wild:spawnPed', function(zoneName, coords)
  local model = HEN_HASH
  RequestModel(model)
  while not HasModelLoaded(model) do Wait(0) end

  local x,y,z = coords.x, coords.y, coords.z
  local found, gz = GetGroundZFor_3dCoord(x, y, z+50.0, false)
  if found then z = gz + 0.05 end

  local ped = CreatePed(28, model, x, y, z, math.random()*360.0, true, true)
  SetEntityAsMissionEntity(ped, true, true)
  SetBlockingOfNonTemporaryEvents(ped, true)
  TaskWanderStandard(ped, 10.0, 10)
  SetModelAsNoLongerNeeded(model)

  local netId = NetworkGetNetworkIdFromEntity(ped)
  Entity(ped).state:set(WILD_KEY, true, true)  -- marquer sauvage (client)
  TriggerServerEvent('babo:wild:pedSpawned', zoneName, netId)
  startWanderInZone(ped, zoneName)

end)

-- ===== Appât: durée en ms (le client calcule son tick de fin) =====
-- ===== Appât: durée en ms + position du joueur qui bait =====
RegisterNetEvent('babo:wild:setBait', function(netId, durationMs, baitPos)
  if not NetworkDoesNetworkIdExist(netId) then return end
  local ent = NetworkGetEntityFromNetworkId(netId)
  if not DoesEntityExist(ent) then return end

  local dur = tonumber(durationMs) or 0
  local endTick = GetGameTimer() + math.max(0, dur)
  Entity(ent).state:set(BAIT_UNTIL_KEY, endTick, true)

  -- On essaye de prendre le contrôle pour lui donner une tâche
  if not NetworkHasControlOfEntity(ent) then
    NetworkRequestControlOfEntity(ent)
  end

  -- Si on a la position du joueur qui a bait => la poule se déplace vers lui
  if baitPos and baitPos.x then
    local dest = vector3(baitPos.x, baitPos.y, baitPos.z)

    -- on annule sa wander pour forcer la marche vers le joueur
    ClearPedTasks(ent)
    TaskGoToCoordAnyMeans(ent, dest.x, dest.y, dest.z, 1.2, 0, 0, 786603, 0.0)

    -- petit loop: dès qu'elle est proche, elle "reste calme" le reste du temps
    CreateThread(function()
      local deadline = endTick
      while DoesEntityExist(ent) and GetGameTimer() < deadline do
        local pos = GetEntityCoords(ent)
        if #(pos - dest) <= 1.7 then
          TaskStandStill(ent, math.max(0, deadline - GetGameTimer()))
          break
        end
        Wait(400)
      end
    end)
  else
    -- fallback: si pas de position, elle reste calme sur place comme avant
    TaskStandStill(ent, dur)
  end
end)


-- ===== Suppression du ped après capture =====
RegisterNetEvent('babo:wild:deletePed', function(netId)
  if not NetworkDoesNetworkIdExist(netId) then return end
  local ent = NetworkGetEntityFromNetworkId(netId)
  if DoesEntityExist(ent) then DeleteEntity(ent) end
end)

-- reconstruit les blips à la demande
RegisterNetEvent('babo:wild:rebuildBlips', function()
  clearZoneBlips()
  setupZoneBlips()
end)

-- appel initial même si on a juste refresh le client
CreateThread(function()
  Wait(500)
  setupZoneBlips()
end)