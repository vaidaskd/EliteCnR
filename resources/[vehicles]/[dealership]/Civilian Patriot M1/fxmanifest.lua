--CREATED BY SHAL--
fx_version "cerulean"
game "gta5"

name "Shal | Patriot MK1"

files {
    '**/*.meta'
}

data_file 'HANDLING_FILE' 'data/handling/*.meta'
data_file 'VEHICLE_LAYOUTS_FILE' 'data/vehiclelayouts/*.meta'
data_file 'VEHICLE_METADATA_FILE' 'data/vehicles/*.meta'
data_file 'CARCOLS_FILE' 'data/carcols/*.meta'
data_file 'VEHICLE_VARIATION_FILE' 'data/carvariations/*.meta'

escrow_ignore {
  'data/handling/*.meta',
  'data/vehiclelayouts/*.meta',
  'data/vehicles/*.meta',
  'data/carcols/*.meta',
  'data/carvariations/*.meta',
  'names.lua',
}

lua54 'yes'

client_script 'names.lua'
