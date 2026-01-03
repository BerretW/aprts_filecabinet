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
Config.CabinetLocations = {
    [1] = {
        name = "Kartotéka Doktor Valentine",
        coords = vector3(-288.447601, 813.201538, 119.385971),
        jobs = {{
            job = 'doctor',
            grade = 1
        }},
        style = {
            logo = "https://file.whrp.cz/f/3bcf3c60-1933-436b-8fa1-995e09313877", -- Odkaz na logo (transparentní PNG)
            background = "#2c1e14",  -- Hlavní pozadí stolu (tmavé dřevo)
            sidebar = "#3e2723",     -- Pozadí bočního panelu
            accent = "#ff9a02ff",      -- Barva textů a aktivních prvků (zlatá)
            button = "#2e7d32"       -- Barva hlavního tlačítka (zelená)
        },
        heading = 70.0,
        model = 'prop_file_cabinet_01'
    },
    [2] = {
        name = "Kartotéka Policejní Stanice Valentine",
        coords = vector3(-279.171448, 806.143616, 119.380066),
        jobs = {{
            job = 'sheriff',
            grade = 1
        }},
        heading = 180.0,
        model = 'prop_file_cabinet_01'
    },
    [3] = {
        name = "Schránka na stížnosti",
        coords = vector3(-280.187286, 788.078796, 118.700890),
        heading = 90.0,
        
        model = 'prop_file_cabinet_01'
    }
}


-- NOVÉ: Definice typů dokumentů
Config.DocumentTypes = {
    -- NOVÝ TYP: Složka občana
    ['citizen_profile'] = {
        label = "Složka občana",
        description = "Hlavní karta občana s fotografií.",
        isForm = true,
        isProfile = true, -- Identifikátor pro script, že toto je hlavní složka
        fields = {
            { key = "name", label = "Jméno a Příjmení", type = "text", width = "half" },
            { key = "dob", label = "Datum narození", type = "text", width = "half" },
            { key = "photo", label = "URL Fotografie", type = "text", width = "full" }, -- Pole pro fotku
            { key = "residence", label = "Bydliště", type = "text", width = "full" },
            { key = "notes", label = "Poznámky", type = "textarea", width = "full", rows = 5 }
        }
    },
    
    ['medical_report'] = {
        label = "Lékařská složka",
        description = "Oficiální záznam o pacientovi.",
        isForm = true,
        linkedKey = "name", -- TOTO POLE (Jméno pacienta) se musí shodovat s 'name' v citizen_profile
        fields = {
            { key = "name", label = "Jméno pacienta", type = "text", width = "half" },
            { key = "dob", label = "Datum narození", type = "text", width = "half" },
            { key = "blood", label = "Krevní skupina", type = "text", width = "third" },
            { key = "weight", label = "Váha", type = "text", width = "third" },
            { key = "height", label = "Výška", type = "text", width = "third" },
            { key = "diagnosis", label = "Diagnóza", type = "textarea", width = "full", rows = 5 },
            { key = "treatment", label = "Léčba / Předpis", type = "textarea", width = "two-thirds", rows = 3 },
            { key = "doctor", label = "Ošetřující lékař", type = "text", width = "third" }
        }
    },

    ['police_report'] = {
        label = "Policejní hlášení",
        isForm = true,
        linkedKey = "suspect", -- Zde se páruje podle 'suspect' (Podezřelý)
        fields = {
            { key = "date", label = "Datum a Čas", type = "text", width = "half" },
            { key = "location", label = "Místo činu", type = "text", width = "half" },
            { key = "suspect", label = "Podezřelý", type = "text", width = "full" },
            { key = "details", label = "Popis incidentu", type = "textarea", width = "full", rows = 10 }
        }
    },

    ['standard'] = {
        label = "Volný list",
        description = "Prázdný papír.",
        isForm = false
        -- Standardní dokumenty nemají linkedKey, takže zůstanou netříděné,
        -- leda bys jim přidal skryté pole pro jméno.
    }
}