fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'babo_chickencap'
author 'babocha'
description 'Capture wild hens/roosters with ox_target '

shared_scripts {
  '@ox_lib/init.lua',
  'config.lua',
}

client_scripts {
  'client.lua',
}

server_scripts {
  'server.lua',
}

