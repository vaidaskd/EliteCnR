fx_version 'cerulean'
game 'gta5'

author 'AGModsTeam'
description 'Brute Stockade - Emergency Pack'
version 'v1.5'

files {
	'data/vehicles.meta',
	'data/carvariations.meta',
	'data/carcols.meta',
	'data/vehiclelayouts.meta',
}

data_file 'VEHICLE_METADATA_FILE' 'data/vehicles.meta'
data_file 'CARCOLS_FILE' 'data/carcols.meta'
data_file 'VEHICLE_VARIATION_FILE' 'data/carvariations.meta'
data_file 'VEHICLE_LAYOUTS_FILE' 'data/vehiclelayouts.meta'
-- Custom AUDIO_GAMEDATA disabled: ported .dat151.rel crashes the client on b3258.
client_script 'vehicle_names.lua'
