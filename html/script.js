const { createApp, nextTick } = Vue;

const app = createApp({
    data() {
        return {
            // Stav viditelnosti
            visible: false,
            
            // Data kartotéky
            cabinetID: null,
            cabinetName: "Kartotéka",
            files: [],
            emptyPapersCount: 0,
            
            // Konfigurace typů dokumentů (načte se z Lua)
            docTypes: {}, 
            
            // UI State
            searchQuery: '',
            mode: 'none', // 'none', 'read', 'create', 'edit'
            selectedFile: null, // Aktuálně zobrazený soubor
            originalFile: null, // Původní soubor při editaci (pro ID)
            isSingleFileView: false, // True = otevřeno z inventáře (skryje šuplík)
            
            // Data pro nový/editovaný soubor
            newFile: { 
                title: '', 
                type: 'standard', 
                content: '', 
                formData: {} 
            },
            
            // Instance Quill editoru
            quill: null
        };
    },
    computed: {
        // Filtrování seznamu podle vyhledávání
        filteredFiles() {
            if (!this.searchQuery) return this.files;
            const query = this.searchQuery.toLowerCase();
            
            return this.files.filter(file => {
                const title = this.getFileTitle(file).toLowerCase();
                const typeLabel = this.getFileLabel(file).toLowerCase();
                return title.includes(query) || typeLabel.includes(query);
            });
        }
    },
    methods: {
        // --- POMOCNÉ FUNKCE PRO ZOBRAZENÍ DAT ---
        
        getFileTitle(file) {
            if (!file || !file.metadata) return "Poškozený záznam";
            return file.metadata.title || "Bez názvu";
        },
        getFileType(file) {
            if (!file || !file.metadata) return 'standard';
            return file.metadata.docType || 'standard';
        },
        getFileLabel(file) {
            const type = this.getFileType(file);
            if (this.docTypes[type]) return this.docTypes[type].label;
            return "Dokument";
        },
        getFileContent(file) {
            if (!file || !file.metadata) return "";
            return file.metadata.content || "";
        },
        
        // --- LOGIKA PRO FORMULÁŘE ---
        
        getFormFields(file) {
            const type = this.getFileType(file);
            if (this.docTypes[type] && this.docTypes[type].isForm) {
                return this.docTypes[type].fields;
            }
            return [];
        },
        getFormFieldValue(file, key) {
            try {
                // Obsah formulářů je uložen jako JSON string
                const content = file.metadata.content;
                if (!content) return "—";
                const data = JSON.parse(content);
                return data[key] || "—";
            } catch (e) {
                return "Neplatná data";
            }
        },

        // --- AKCE UI ---

        selectFile(file) {
            this.selectedFile = file;
            this.mode = 'read';
            this.originalFile = null;
        },
        
        // Zahájení vytváření nového spisu
        async startCreating() {
            if (this.emptyPapersCount > 0) {
                this.newFile = { title: '', type: 'standard', content: '', formData: {} };
                this.mode = 'create';
                this.selectedFile = null;
                this.originalFile = null;
                
                // Počkáme na vykreslení DOMu a nahodíme editor
                await nextTick();
                this.initQuill();
            }
        },

        // Zahájení editace existujícího spisu
        async startEditing(fileToEdit) {
            this.selectedFile = null;
            this.originalFile = fileToEdit; // Uložíme si původní (potřebujeme jeho ID)

            // Předvyplníme data
            this.newFile.title = this.getFileTitle(fileToEdit);
            this.newFile.type = this.getFileType(fileToEdit);

            const typeConfig = this.docTypes[this.newFile.type];

            if (typeConfig && typeConfig.isForm) {
                // Formulář: Převedeme JSON content zpět na objekt
                try {
                    this.newFile.formData = JSON.parse(fileToEdit.metadata.content || "{}");
                } catch (e) {
                    this.newFile.formData = {};
                }
                this.newFile.content = '';
            } else {
                // Quill: Načteme HTML content
                this.newFile.content = fileToEdit.metadata.content || '';
                this.newFile.formData = {};
            }
            
            this.mode = 'edit';
            await nextTick();
            // Inicializujeme Quill s existujícím obsahem (pokud to není formulář)
            this.initQuill(this.newFile.content); 
        },

        // Zrušení akce
        cancelEditCreate() {
            if (this.originalFile) {
                // Pokud jsme editovali, vrátíme se k zobrazení původního souboru
                this.selectFile(this.originalFile);
            } else {
                // Jinak reset
                this.mode = 'none';
            }
            this.originalFile = null;
        },

        // Při změně typu dokumentu (dropdown v create mode)
        onTypeChange() {
            // Reset dat
            this.newFile.formData = {};
            this.newFile.content = '';
            
            const typeCfg = this.docTypes[this.newFile.type];
            if (typeCfg && !typeCfg.isForm) {
                // Přepnuto na editor -> nahodit Quill
                nextTick(() => this.initQuill());
            } else {
                // Přepnuto na formulář -> zničit Quill
                if (this.quill) {
                    this.quill = null; 
                    // (DOM element se skryje díky v-show/v-if ve Vue)
                }
            }
        },

        // Inicializace Quill Editoru
        initQuill(initialContent = '') {
            const container = document.getElementById('quill-editor');
            const typeConfig = this.docTypes[this.newFile.type];

            // Inicializujeme jen pokud to NENÍ formulář
            if (container && typeConfig && !typeConfig.isForm) {
                // Vyčistit starý obsah
                container.innerHTML = ""; 
                
                this.quill = new Quill('#quill-editor', {
                    theme: 'snow',
                    modules: {
                        toolbar: [
                            ['bold', 'italic', 'underline', 'strike'],
                            [{ 'header': [1, 2, false] }],
                            [{ 'list': 'ordered'}, { 'list': 'bullet' }],
                            ['clean']
                        ]
                    },
                    placeholder: 'Zde pište text...'
                });
                
                // Pokud máme obsah (editace), vložíme ho
                if (initialContent) {
                    this.quill.root.innerHTML = initialContent;
                }
            }
        },

        // --- KOMUNIKACE SE SERVEREM ---

        saveFile() {
            // Validace
            if (!this.newFile.title || this.newFile.title.trim() === "") return;

            let finalContent = "";
            const typeConfig = this.docTypes[this.newFile.type];

            // Extrakce obsahu
            if (typeConfig && typeConfig.isForm) {
                finalContent = JSON.stringify(this.newFile.formData);
            } else {
                if (this.quill) finalContent = this.quill.root.innerHTML;
            }

            // Rozlišení Editace vs. Nový
            const isEditing = this.mode === 'edit';
            const originalItemID = isEditing ? this.originalFile.crafted_id : null;

            const endpoint = isEditing ? 'editFile' : 'addFile';

            fetch(`https://${GetParentResourceName()}/${endpoint}`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json; charset=UTF-8' },
                body: JSON.stringify({
                    cabinetID: this.cabinetID,
                    originalItemID: originalItemID,
                    title: this.newFile.title,
                    content: finalContent,
                    docType: this.newFile.type
                })
            }).then(() => {
                this.closeMenu();
            }).catch(err => console.error("Save Error:", err));
        },

        copyFile(file) {
            if (this.emptyPapersCount <= 0) return;

            const title = this.getFileTitle(file);
            const type = this.getFileType(file);
            const content = file.metadata && file.metadata.content ? file.metadata.content : "";

            fetch(`https://${GetParentResourceName()}/copyFile`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json; charset=UTF-8' },
                body: JSON.stringify({
                    cabinetID: this.cabinetID,
                    title: title,
                    content: content,
                    docType: type
                })
            }).then(() => {
                // Po zkopírování můžeme zavřít nebo zůstat
                // this.closeMenu();
                // Prozatím jen resetujeme výběr, aby se refreshnul list (pokud se refreshne automaticky)
                // Ale jelikož list refreshuje jen server event 'open', raději zavřeme.
                this.closeMenu();
            }).catch(err => console.error("Copy Error:", err));
        },

        closeMenu() {
            this.visible = false;
            // Reset stavu
            this.mode = 'none';
            this.searchQuery = '';
            this.selectedFile = null;
            this.originalFile = null;
            this.quill = null;
            this.isSingleFileView = false; // Reset single view

            fetch(`https://${GetParentResourceName()}/close`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json; charset=UTF-8' },
                body: JSON.stringify({})
            }).catch(err => {});
        },

        handleMessage(event) {
            const item = event.data;
            
            // 1. Otevření celé kartotéky
            if (item.action === 'open') {
                this.cabinetID = item.cabinetID;
                this.cabinetName = item.cabinetName;
                this.files = item.files || [];
                this.emptyPapersCount = item.emptyPapersCount || 0;
                this.docTypes = item.docTypes || {};
                
                this.visible = true;
                this.searchQuery = '';
                this.mode = 'none';
                this.isSingleFileView = false; 
                this.selectedFile = null;
            }
            
            // 2. Otevření jednoho souboru (z inventáře)
            if (item.action === 'openSingleFile') {
                this.docTypes = item.docTypes || {};
                
                this.selectedFile = item.file;
                this.mode = 'read';
                this.isSingleFileView = true; // Skryje šuplík a editaci
                
                this.visible = true;
            }

            // 3. Zavření
            if (item.action === 'close') {
                this.visible = false;
            }
        }
    },
    mounted() {
        window.addEventListener('message', this.handleMessage);
        window.addEventListener('keydown', (e) => {
            if (this.visible && e.key === 'Escape') {
                if (this.mode === 'create' || this.mode === 'edit') {
                    this.cancelEditCreate();
                } else {
                    this.closeMenu();
                }
            }
        });
        console.log("FileCabinet Script Loaded");
    }
});

app.mount('#app');