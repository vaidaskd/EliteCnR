fx_version 'cerulean'
game 'gta5'

author 'Grodd Customs https://grodd.tebex.io/'
description 'Tailgater SR'
version '1.0.0'


files {
  'data/**/vehicles.meta',
  'data/**/carcols.meta',
  'data/**/carvariations.meta',
  'data/**/handling.meta',
}


data_file 'VEHICLE_METADATA_FILE'   'data/**/vehicles.meta'
data_file 'CARCOLS_FILE'            'data/**/carcols.meta'
data_file 'VEHICLE_VARIATION_FILE'  'data/**/carvariations.meta'
data_file 'HANDLING_FILE'           'data/**/handling.meta'


escrow_ignore {
  'data/**/*.meta'
}
