-- babo_chickencap - server (no client-only network natives)
-- Dépendances: ox_lib, ox_inventory

local inv = exports.ox_inventory

local function now() return os.time() end
local function D(fmt, ...)
  if Config.Debug then
    print(('[babo_chickencap][srv] '..fmt):format(...))
  end
end

local function toVec3(v)
  if type(v) == 'vector3' then return v end
  return vec3(v.x, v.y, v.z)
end

local function isAdmin(src)
  -- Console/Server (src==0) autorisé
  if src == 0 then return true end
  -- ACE custom "babo.chickencap"
  return IsPlayerAceAllowed(src, 'babo.chickencap')
end


local ZONES = {}  -- [name] = { center, radius, maxPeds, respawn, peds = { [netId] = { spawnTs, sex, baitUntil, captureBy?, captureLock? } } }

local function chooseSex()
  local r = math.random()
  local pr = Config.Wild.SexRatio or { hen = 0.6, rooster = 0.4 }
  return (r <= (pr.hen or 0.6)) and 'hen' or 'rooster'
end

local function playersNear(center, radius)
  local list, r2 = {}, (radius + 200.0)
  for _, sid in pairs(GetPlayers()) do
    local ped = GetPlayerPed(sid)
    local p = GetEntityCoords(ped)
    if #(p - center) <= r2 then
      list[#list+1] = tonumber(sid)
    end
  end
  return list
end

local function pickPointInCircle(center, radius)
  local r = math.sqrt(math.random()) * radius
  local t = math.random() * 2.0 * math.pi
  return vec3(center.x + r * math.cos(t), center.y + r * math.sin(t), center.z)
end

local function findZoneByNetId(netId)
  for name, z in pairs(ZONES) do
    if z.peds[netId] ~= nil then return name, z end
  end
  return nil, nil
end

-- ===== Init zones =====
CreateThread(function()
  math.randomseed(GetGameTimer() % 2147483646)
  for _, z in ipairs(Config.Wild.Zones or {}) do
    ZONES[z.name] = {
      name    = z.name,
      center  = toVec3(z.center),
      radius  = z.radius or 120.0,
      maxPeds = z.maxPeds or 6,
      respawn = z.respawn or { min = 180, max = 420 },
      peds    = {}, -- netId -> { spawnTs, sex, baitUntil, captureBy?, captureLock? }
    }
  end
end)

-- ===== Spawn manager (server pilote; client spawn visuel) =====
CreateThread(function()
  while true do
    Wait(Config.Wild.TickMs or 15000)
    if not (Config.Wild and Config.Wild.Enabled) then goto cont end

    for name, zone in pairs(ZONES) do
      local count = 0
      for _ in pairs(zone.peds) do count = count + 1 end

      if count < zone.maxPeds then
        local near = playersNear(zone.center, zone.radius)
        if #near > 0 then
          local tgt = near[math.random(1, #near)]
          local pos = pickPointInCircle(zone.center, zone.radius)
          TriggerClientEvent('babo:wild:spawnPed', tgt, name, pos)
          -- l'enregistrement se fait via pedSpawned (netId)
        end
      end
    end

    ::cont::
  end
end)

-- ===== Confirmation client: un ped a été spawné =====
RegisterNetEvent('babo:wild:pedSpawned', function(zoneName, netId)
  local z = ZONES[zoneName]; if not z then return end
  if not netId or type(netId) ~= 'number' then return end

  if z.peds[netId] == nil then
    z.peds[netId] = { spawnTs = now(), sex = chooseSex(), baitUntil = 0 }
    D('SPAWN ok: zone=%s netId=%s sex=%s', zoneName, netId, z.peds[netId].sex)
  end
end)

-- ===== Bait (appât) =====
RegisterNetEvent('babo:wild:bait', function(netId)
  local src = source
  if type(netId) ~= 'number' then return end

  local zoneRef, pedMeta
  for _, z in pairs(ZONES or {}) do
    if z.peds and z.peds[netId] then
      zoneRef = z
      pedMeta = z.peds[netId]
      break
    end
  end
  if not zoneRef or not pedMeta then
    TriggerClientEvent('ox_lib:notify', src, { type='error', description='Not a valid target.' })
    D('BAIT fail: netId=%s missing in ZONES', tostring(netId))
    return
  end

  -- Consomme le feed
  local feedItem = Config.ItemFeed or 'chicken_feed'
  local have = inv:GetItemCount(src, feedItem) or 0
  if have <= 0 then
    TriggerClientEvent('ox_lib:notify', src, { type='error', description='You need chicken feed.' })
    D('BAIT fail: player %s no feed', src)
    return
  end
  inv:RemoveItem(src, feedItem, 1)

  local durMs  = tonumber(Config.BaitDurationMs) or 6000
  local untilTs = now() + math.floor(durMs / 1000)
  pedMeta.baitUntil = untilTs

local ped = GetPlayerPed(src)
local p = GetEntityCoords(ped)
TriggerClientEvent('babo:wild:setBait', -1, netId, durMs, { x = p.x, y = p.y, z = p.z })
  D('BAIT ok: netId=%s until=%s (now=%s, +%ss)', netId, pedMeta.baitUntil, now(), math.floor(durMs/1000))
end)

-- ===== Capture: pré-validation + lock (callback) =====
lib.callback.register('babo:wild:captureStart', function(source, netId)
  local src = source
  if type(netId) ~= 'number' then return false, 'Invalid target.' end

  local zoneName, z = findZoneByNetId(netId)
  if not z then return false, 'Not a valid target.' end

  local pedMeta = z.peds[netId]
  if not pedMeta then return false, 'It already escaped.' end

  if Config.RequireBaitToCapture then
    local left = (pedMeta.baitUntil or 0) - now()
    if left <= 0 then
      D('CAPTURE start fail: netId=%s not baited (left=%ss)', netId, left)
      return false, 'The hen is not baited.'
    end
  end

  local lockSec = math.ceil((Config.CaptureDuration or 6000) / 1000) + 2
  pedMeta.captureBy   = src
  pedMeta.captureLock = now() + lockSec

  D('CAPTURE start ok: netId=%s by=%s lock=%ss', netId, src, lockSec)
  return true
end)

-- ===== Capture: finalisation =====
RegisterNetEvent('babo:wild:capture', function(netId)
  local src = source
  if type(netId) ~= 'number' then return end

  local zname, z = findZoneByNetId(netId)
  if not z then
    TriggerClientEvent('ox_lib:notify', src, { type='error', description='Not a valid target.' })
    D('CAPTURE fail: netId=%s missing zone', tostring(netId))
    return
  end

  local pedMeta = z.peds[netId]
  if not pedMeta then
    TriggerClientEvent('ox_lib:notify', src, { type='error', description='It already escaped.' })
    D('CAPTURE fail: netId=%s missing meta', tostring(netId))
    return
  end

  -- Lock obligatoire
  if pedMeta.captureBy ~= src or (pedMeta.captureLock or 0) <= now() then
    TriggerClientEvent('ox_lib:notify', src, { type='error', description='Capture interrupted.' })
    D('CAPTURE fail: lock mismatch/expired netId=%s by=%s lockBy=%s until=%s now=%s',
      netId, src, tostring(pedMeta.captureBy), tostring(pedMeta.captureLock), now())
    return
  end
  -- Nettoie le lock
  pedMeta.captureBy, pedMeta.captureLock = nil, nil

  -- RNG
  if math.random() < (Config.FailChance or 0.15) then
    pedMeta.baitUntil = 0
    TriggerClientEvent('ox_lib:notify', src, { type='error', description='It escaped!' })
    D('CAPTURE RNG fail: netId=%s', netId)
    return
  end

  -- Don d'item
  local sex  = pedMeta.sex or 'hen'
  local name = (sex == 'rooster') and (Config.ItemRooster or 'rooster') or (Config.ItemHen or 'hen')
  local maxB = Config.BreedsMax or 3
  local meta = { breeds_left = maxB, is_old = 0, cid = math.random(100000, 999999), info = ('%d/%d'):format(maxB, maxB) }

  local ok = inv:AddItem(src, name, 1, meta)
  if not ok then
    TriggerClientEvent('ox_lib:notify', src, { type='error', description='Inventory full.' })
    D('CAPTURE fail: inv full for player %s', src)
    return
  end
  if Config.ItemCapture then inv:RemoveItem(src, Config.ItemCapture, 1) end

  z.peds[netId] = nil
  TriggerClientEvent('babo:wild:deletePed', -1, netId)
  TriggerClientEvent('ox_lib:notify', src, { type='success', description=('Captured a wild %s.'):format(sex) })
  D('CAPTURE ok: netId=%s -> item=%s', netId, name)
end)

-- ===== Commandes DEBUG =====
local function ensureDebugZoneFor(src)
  local ped = GetPlayerPed(src)
  local pos = GetEntityCoords(ped)
  ZONES.DEBUG = ZONES.DEBUG or { name='DEBUG', center=pos, radius=100.0, maxPeds=20, respawn={min=10,max=20}, peds={} }
  ZONES.DEBUG.center = pos
  return ZONES.DEBUG
end

RegisterCommand('bch_debug', function(src, args)
  local function isAdmin(src)
  -- Console/Server (src==0) autorisé
  if src == 0 then return true end
  -- ACE custom "babo.chickencap"
  return IsPlayerAceAllowed(src, 'babo.chickencap')
end

  local v = args[1]
  if v == '1' or v == 'true' then Config.Debug = true
  elseif v == '0' or v == 'false' then Config.Debug = false
  else Config.Debug = not Config.Debug end
  local msg = ('babo_chickencap debug = %s'):format(tostring(Config.Debug))
  print('[babo_chickencap] '..msg)
  if src>0 then TriggerClientEvent('ox_lib:notify', src, { type='inform', description=msg }) end
end, false)

RegisterCommand('bch_spawn', function(src, args)
  if not isAdmin(src) then return end
  local count = tonumber(args[1] or '3') or 3
  ensureDebugZoneFor(src)
  local ped = GetPlayerPed(src)
  local base = GetEntityCoords(ped)
  for i=1,count do
    local angle = math.random()*math.pi*2
    local dist  = 5.0 + math.random()*8.0
    local pos   = vec3(base.x+math.cos(angle)*dist, base.y+math.sin(angle)*dist, base.z)
    TriggerClientEvent('babo:wild:spawnPed', src, 'DEBUG', pos)
  end
  if src>0 then TriggerClientEvent('ox_lib:notify', src, { type='success', description=('Spawned %d wild hens (DEBUG).'):format(count) }) end
  D('DEBUG spawn: %d near player %s', count, src)
end, false)

RegisterCommand('bch_list', function(src)
  if not isAdmin(src) then return end
  local lines = {}
  for name,z in pairs(ZONES) do
    local cnt=0; for _ in pairs(z.peds) do cnt=cnt+1 end
    lines[#lines+1] = ('Zone %s: %d peds'):format(name, cnt)
    for netId,meta in pairs(z.peds) do
      lines[#lines+1] = ('  - netId=%s sex=%s baitUntil=%s (left=%ss)')
        :format(netId, meta.sex or '?', tostring(meta.baitUntil or 0), (meta.baitUntil or 0)-now())
    end
  end
  print('[babo_chickencap]\n'..table.concat(lines, '\n'))
  if src>0 then TriggerClientEvent('ox_lib:notify', src, { type='inform', description='Printed to server console.' }) end
end, false)

RegisterCommand('bch_bait', function(src, args)
  if not isAdmin(src) then return end
  local netId = tonumber(args[1] or '')
  local durMs = tonumber(args[2] or tostring(Config.BaitDurationMs or 6000)) or 6000
  if not netId then if src>0 then TriggerClientEvent('ox_lib:notify', src, { type='error', description='Usage: /bch_bait <netId> [ms]' }) end return end
  local z, pedMeta
  for _,zz in pairs(ZONES) do if zz.peds[netId] then z=zz; pedMeta=zz.peds[netId]; break end end
  if not z or not pedMeta then if src>0 then TriggerClientEvent('ox_lib:notify', src, { type='error', description='netId not found.' }) end return end
  pedMeta.baitUntil = now() + math.floor(durMs/1000)
  TriggerClientEvent('babo:wild:setBait', -1, netId, durMs)
  D('DEBUG bait forced: netId=%s +%sms', netId, durMs)
end, false)

RegisterCommand('bch_clear', function(src)
  if not isAdmin(src) then return end
  for _,z in pairs(ZONES) do
    for netId,_ in pairs(z.peds) do
      TriggerClientEvent('babo:wild:deletePed', -1, netId)
    end
    z.peds = {}
  end
  if src>0 then TriggerClientEvent('ox_lib:notify', src, { type='success', description='Cleared all wild hens.' }) end
  D('DEBUG clear: all zones emptied')
end, false)
