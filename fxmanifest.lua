fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name "lsk-illenium"
description "Add customizable clothing/tattoo/barber shops into your server direct from the game."
author "luska (@luska1337), special thanks to Zhawty (@zhawty)"
version "1.0.0"

shared_scripts {
	'@ox_lib/init.lua',
	'shared/*.lua'
}

client_scripts {
	'client/*.lua'
}

server_scripts {
	'server/*.lua'
}

files {
    'locales/*'
}
