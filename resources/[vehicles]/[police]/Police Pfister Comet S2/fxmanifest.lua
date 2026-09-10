fx_version 'bodacious'
games {'gta5'}

client_script { 'car_names.lua' }

files {
	'vehicles.meta',
	'carcols.meta',
	'carvariations.meta',
	'handling.meta',
}

data_file 'HANDLING_FILE' 'handling.meta'
data_file 'VEHICLE_METADATA_FILE' 'vehicles.meta'
data_file 'CARCOLS_FILE' 'carcols.meta'
data_file 'VEHICLE_VARIATION_FILE' 'carvariations.meta'
-- Custom AUDIO_* (dlctuner .dat151/.dat54/.dat10.rel) disabled: crashes client on b3258.
