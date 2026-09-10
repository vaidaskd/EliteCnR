fx_version 'cerulean'
game 'gta5'

author 'DarKy'
version '1.0'

files {
    'data/vehicles.meta',
    'data/handling.meta',
	'data/carcols.meta',
	'data/carvariations.meta',

    'data/audio/polaleutian_game.dat151.rel',
}

data_file 'VEHICLE_METADATA_FILE' 'data/vehicles.meta'
data_file 'HANDLING_FILE' 'data/handling.meta'
data_file 'CARCOLS_FILE' 'data/carcols.meta'
data_file 'VEHICLE_VARIATION_FILE' 'data/carvariations.meta'

data_file 'AUDIO_GAMEDATA' 'data/audio/polaleutian_game.dat'

client_script 'vehicles_names.lua'