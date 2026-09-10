fx_version 'cerulean'
game 'gta5'

files {
	'data/**/carcols.meta',
	'data/**/carvariations.meta',
	'data/**/handling.meta',
	'data/**/vehiclelayouts.meta',
	'data/**/vehicles.meta',
	'data/**/dlctext.meta',
}

data_file 'HANDLING_FILE' 'data/**/handling.meta'
data_file 'DLC_TEXT_FILE' 'data/**/dlctext.meta'
data_file 'VEHICLE_METADATA_FILE' 'data/**/vehicles.meta'
data_file 'CARCOLS_FILE' 'data/**/carcols.meta'
data_file 'VEHICLE_VARIATION_FILE' 'data/**/carvariations.meta'
data_file 'VEHICLE_LAYOUTS_FILE' 'data/**/vehiclelayouts.meta'
-- Custom AUDIO_* (.dat151/.dat54.rel) disabled: crashes the client on b3258.
client_script 'vehicle_names.lua'
