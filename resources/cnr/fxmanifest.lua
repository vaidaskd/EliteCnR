fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'cnr'
description 'Custom Cops & Robbers gamemode.'
author 'CnR Team'
version '1.0.0'

dependency 'bob74_ipl'
dependency 'NativeUI'
dependency 'oxmysql'

ui_page 'html/index.html'

shared_scripts {
    'config.lua',
    'shared/util.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/persistence.lua',
    'server/chat.lua',
    'server/inventory.lua',
    'server/robbery.lua',
    'server/crime.lua',
    'server/arrest.lua',
    'server/jail.lua',
    'server/respawn.lua',
    'server/tattoo.lua',
    'server/commands.lua',
    'server/ranks.lua',
    'server/vehicle_autoload.lua',
    'server/vehicles.lua',
    'server/shops.lua',
    'server/armory.lua',
    'server/player_list.lua',
}

client_scripts {
    '@NativeUI/NativeUI/NativeUI.lua',
    'client/native_ui.lua',
    'client/vehicle_preview.lua',
    'client/native_menus.lua',
    'client/rank_preview.lua',
    'client/armory.lua',
    'client/main.lua',
    'client/world.lua',
    'client/ambient_vehicles.lua',
    'client/ipl.lua',
    'client/keybinds.lua',
    'client/peds.lua',
    'client/blips.lua',
    'client/markers.lua',
    'client/robbery.lua',
    'client/crime.lua',
    'client/arrest.lua',
    'client/jail.lua',
    'client/safe_zone.lua',
    'client/inventory.lua',
    'client/respawn.lua',
    'client/commands.lua',
    'client/admin_noclip.lua',
    'client/position.lua',
    'client/weapons.lua',
    'client/ranks.lua',
    'client/vehicles.lua',
    'client/player_list.lua',
    'client/station.lua',
    'client/donut.lua',
    'client/shops.lua',
    'client/tattoo.lua',
    'client/chat_channels.lua',
    'client/tuner.lua',
    'client/spawn.lua',
    'client/char_menu.lua',
    'client/nui.lua',
    'client/hud.lua',
}

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
}
