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
Config.EmptyPaperItem = 'product_paper'
Config.CabinetLocations= {
    [1]={name = "Kartotéka Doktor Valentine", coords =vector3(-288.447601, 813.201538, 119.385971),jobs = {{job = 'doctor', grade = 1}}, heading = 70.0, model = 'prop_file_cabinet_01'},
}

-- NOVÉ: Definice typů dokumentů
Config.DocumentTypes = {
    ['standard'] = {
        label = "Volný list (Editor)",
        description = "Prázdný papír pro psaní poznámek.",
        isForm = false
    },
    ['medical_report'] = {
        label = "Lékařská složka",
        description = "Oficiální záznam o pacientovi.",
        isForm = true,
        fields = {
            -- První řádek: Jméno a Datum narození vedle sebe (každý half)
            { key = "name", label = "Jméno pacienta", type = "text", width = "half" },
            { key = "dob", label = "Datum narození", type = "text", width = "half" },
            
            -- Druhý řádek: 3 malé údaje vedle sebe (third)
            { key = "blood", label = "Krevní skupina", type = "text", width = "third" },
            { key = "weight", label = "Váha", type = "text", width = "third" },
            { key = "height", label = "Výška", type = "text", width = "third" },

            -- Třetí řádek: Diagnóza přes celou šířku a vyšší (full)
            { key = "diagnosis", label = "Diagnóza", type = "textarea", width = "full", rows = 5 },
            
            -- Čtvrtý řádek: Léčba (dvě třetiny) a Podpis (jedna třetina)
            { key = "treatment", label = "Léčba / Předpis", type = "textarea", width = "two-thirds", rows = 3 },
            { key = "doctor", label = "Ošetřující lékař", type = "text", width = "third" }
        }
    },
    ['police_report'] = {
        label = "Policejní hlášení",
        isForm = true,
        fields = {
            { key = "date", label = "Datum a Čas", type = "text", width = "half" },
            { key = "location", label = "Místo činu", type = "text", width = "half" },
            { key = "suspect", label = "Podezřelý", type = "text", width = "full" },
            { key = "details", label = "Popis incidentu", type = "textarea", width = "full", rows = 10 }
        }
    }
}