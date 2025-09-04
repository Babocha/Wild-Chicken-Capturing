Config = {}

-- Items compatibles avec ton coop:
Config.ItemHen         = 'hen'
Config.ItemRooster     = 'rooster'
Config.ItemFeed        = 'chicken_feed'  -- utilisé pour "Bait"
Config.ItemCapture     = nil             -- ex: 'animal_crate' si tu veux le rendre obligatoire (sinon nil)

-- Métadonnées à l'ajout
Config.BreedsMax       = 3

-- Capture / Appât
Config.BaitDurationMs  = 6000            -- 6s "appâté"
Config.CaptureDuration = 6000            -- 6s progress
Config.FailChance      = 0.15            -- 15% d’échec (le poulet s’enfuit)
Config.RequireBaitToCapture = true       -- true = il faut appâter avant capture
Config.CaptureRange    = 2.5             -- distance max au moment de capturer

-- Spawn sauvage
Config.Wild = {
  Enabled   = true,
  SexRatio  = { hen = 0.6, rooster = 0.4 },  -- proba à la capture
  TickMs    = 15000,                          -- loop serveur de gestion des zones
  Zones = {
    { name='Grapeseed North', center=vec3(2410.0, 5070.0, 46.9), radius=120.0, maxPeds=6, respawn={min=120, max=300} },
    { name='Raton Canyon',    center=vec3(2129.33, 5184.6, 55.71), radius=160.0, maxPeds=8, respawn={min=180, max=360} },
  }
}

-- UI / Emotes (optionnels côté client pour l’immersion)
Config.Emotes = {
  Bait    = { 'mechanic4' },  -- /e mechanic4
  Capture = { 'mechanic4' },  -- /e mechanic4
  UseEmotes = true,
  EmoteCommandPrefix = 'e',   -- /e <emote>
  EmoteStopCommand   = 'e c'  -- /e c   (arrêt)
}

Config.Wild.Blips = {
  enabled     = true,
  name        = 'Wild chickens',
  sprite      = 141,   -- change si tu veux un autre pictogramme
  color       = 5,
  scale       = 0.85,
  radiusColor = 25,
  radiusAlpha = 80,
}

-- Logs/commandes debug
Config.Debug = true
