fx_version 'cerulean'
games {'gta5'}

data_file 'HANDLING_FILE' 'data/handling.meta'
data_file 'VEHICLE_METADATA_FILE' 'data/vehicles.meta'
data_file 'CARCOLS_FILE' 'data/carcols.meta'
data_file 'VEHICLE_VARIATION_FILE' 'data/carvariations.meta'
data_file 'AUDIO_GAMEDATA' 'audioconfig/ta160am11_game.dat'
data_file 'AUDIO_SOUNDDATA' 'audioconfig/ta160am11_sounds.dat'
data_file 'AUDIO_WAVEPACK' 'sfx/dlc_ta160am11'

files {
  'data/handling.meta',
  'data/vehicles.meta',
  'data/carcols.meta',
  'data/carvariations.meta',
  'audioconfig/*.dat151.rel',
  'audioconfig/*.dat54.rel',
  'sfx/**/*.awc'
}

client_script 'names.lua'
lua54 'yes'