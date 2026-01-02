Config = {}
Config.Debug = false
Config.DST = 1
Config.GreenTimeStart = 16
Config.GreenTimeEnd = 23
Config.ActiveTimeStart = 23
Config.ActiveTimeEnd = 3


Config.WebHook =
    ""
Config.ServerName = 'WestHaven ** Loger'
Config.DiscordColor = 16753920
Config.Jobs = {
    {job = 'police', grade = 1},
    {job = 'doctor', grade = 3}
}

Config.InventoryPrefix = "aprts_filecabinet_"
Config.FileItem = 'filecabinet_key'
Config.FolderItem = 'folder_key'
Config.CabinetLoactions= {
    [1]={name = "Kartotéka Doktor Valentine", coords =vector3(-288.447601, 813.201538, 119.385971),jobs = {{job = 'doctor', grade = 1}}, heading = 70.0, model = 'prop_file_cabinet_01'},
}