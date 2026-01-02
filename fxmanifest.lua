fx_version 'cerulean'
lua54 'yes'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

author 'SpoiledMouse'
version '1.0'
description 'aprts_filecabinet'

games {"rdr3"}

client_scripts {'config.lua','client/client.lua','client/events.lua', 'client/nui.lua','client/commands.lua',}
server_scripts {'@oxmysql/lib/MySQL.lua','config.lua','server/server.lua','server/events.lua','server/commands.lua',}
shared_scripts {
    'config.lua',
    '@jo_libs/init.lua',
    '@ox_lib/init.lua'
}


ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/vue.global.js' -- Stáhni si vue 3 (viz níže) nebo použij CDN link v HTML
}