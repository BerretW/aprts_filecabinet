const { createApp } = Vue;

const app = createApp({
    data() {
        return {
            visible: false, // Výchozí stav skryté
            cabinetID: null,
            cabinetName: "Kartotéka",
            files: [], 
            emptyPapersCount: 0,
            
            // UI State
            mode: 'none', // 'none', 'read', 'create'
            selectedFile: null,
            newFile: {
                title: '',
                content: ''
            }
        };
    },
    methods: {
        getFileTitle(file) {
            // Bezpečné získání názvu
            if (file && file.metadata && file.metadata.title) {
                return file.metadata.title;
            }
            return "Neznámý spis";
        },
        getFileContent(file) {
            // Bezpečné získání obsahu
            if (file && file.metadata && file.metadata.content) {
                return file.metadata.content;
            }
            return "Obsah nelze přečíst...";
        },
        
        selectFile(file) {
            this.selectedFile = file;
            this.mode = 'read';
        },
        
        startCreating() {
            if (this.emptyPapersCount > 0) {
                this.newFile.title = '';
                this.newFile.content = '';
                this.mode = 'create';
                this.selectedFile = null;
            }
        },

        saveFile() {
            if (!this.newFile.title || !this.newFile.content) {
                return; 
            }

            // Odeslání dat do Lua
            fetch(`https://${GetParentResourceName()}/addFile`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json; charset=UTF-8',
                },
                body: JSON.stringify({
                    cabinetID: this.cabinetID,
                    title: this.newFile.title,
                    content: this.newFile.content
                })
            }).then(() => {
                // Zavřeme menu po uložení
                this.closeMenu();
            }).catch(err => {
                console.error("Chyba při ukládání:", err);
            });
        },

        closeMenu() {
            this.visible = false;
            // Reset stavu při zavření
            this.mode = 'none';
            this.selectedFile = null;

            fetch(`https://${GetParentResourceName()}/close`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json; charset=UTF-8',
                },
                body: JSON.stringify({})
            }).catch(err => {});
        },

        handleMessage(event) {
            // Debugovací výpis - uvidíš v F8 konzoli
            // console.log("NUI PŘIJALO DATA:", JSON.stringify(event.data));

            const item = event.data;
            if (item.action === 'open') {
                this.cabinetID = item.cabinetID;
                this.cabinetName = item.cabinetName || "Kartotéka";
                this.files = item.files || [];
                this.emptyPapersCount = item.emptyPapersCount || 0;
                
                // Teprve teď zobrazíme
                this.visible = true;
            }
            
            // Pokud by přišel příkaz na zavření z Lua
            if (item.action === 'close') {
                this.visible = false;
            }
        }
    },
    mounted() {
        // Naslouchání zprávám z Lua
        window.addEventListener('message', this.handleMessage);
        
        // Zavření přes ESC
        window.addEventListener('keydown', (e) => {
            if (this.visible && e.key === 'Escape') {
                this.closeMenu();
            }
        });
        
        console.log("FileCabinet NUI Loaded.");
    }
});

app.mount('#app');