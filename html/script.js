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
            processedFiles: [],
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
            modal: {
                visible: false,
                title: '',
                message: ''
            },
            // Instance Quill editoru
            quill: null,
            focusedField: null,
            activeStyle: {
                logo: null,
                background: '#2c1e14',
                sidebar: '#3e2723',
                accent: '#ffcc80',
                button: '#2e7d32'
            }
        };
    },
    computed: {
        filteredFiles() {
            if (!this.searchQuery) return this.processedFiles;
            const query = this.searchQuery.toLowerCase();

            // Filtrujeme hlavní položky (Složky i volné soubory)
            // Pokud je to složka, chceme ji zobrazit, pokud buď ona nebo její děti odpovídají hledání
            return this.processedFiles.filter(item => {
                const title = this.getFileTitle(item).toLowerCase();
                const matchesSelf = title.includes(query);

                if (item.isFolder) {
                    // Pokud je to složka, zkontroluj i děti
                    const childrenMatch = item.children.some(child =>
                        this.getFileTitle(child).toLowerCase().includes(query)
                    );
                    return matchesSelf || childrenMatch;
                }

                return matchesSelf;
            });
        },
        availableCitizens() {
            let names = [];

            // Projdeme všechny soubory
            this.files.forEach(file => {
                // Kontrola, zda je to složka občana (isProfile z Configu)
                const type = this.getFileType(file);
                const typeConfig = this.docTypes[type];

                if (typeConfig && typeConfig.isProfile) {
                    try {
                        // Pokusíme se vytáhnout jméno z obsahu
                        const content = JSON.parse(file.metadata.content || "{}");

                        // Pokud tam je jméno, přidáme ho
                        if (content.name && typeof content.name === 'string' && content.name.trim().length > 0) {
                            names.push(content.name.trim());
                        }
                    } catch (e) {
                        // Ignorujeme chyby parsování u poškozených souborů
                    }
                }
            });

            // Seřadíme a odstraníme duplicity
            const result = [...new Set(names)].sort();

            // VÝPIS DO F8 KONZOLE (Důležité pro kontrolu!)
            if (this.visible) {
                console.log(`[NAŠEPTÁVAČ] Nalezeno ${result.length} občanů:`, result);
            }

            return result;
        },
        currentSuggestions() {
            if (!this.focusedField) return [];

            // Získáme aktuální text v inputu
            const currentVal = (this.newFile.formData[this.focusedField] || "").toLowerCase();

            // Pokud je input prázdný, nezobrazujeme nic (nebo můžeš vrátit všechny, pokud chceš)
            if (currentVal.length === 0) return [];

            // Filtrujeme availableCitizens
            return this.availableCitizens.filter(name =>
                name.toLowerCase().includes(currentVal)
            );
        },
        themeVars() {
            return {
                '--theme-bg': this.activeStyle.background,
                '--theme-sidebar': this.activeStyle.sidebar,
                '--theme-accent': this.activeStyle.accent,
                '--theme-btn': this.activeStyle.button
            };
        }
    },
    methods: {
        // --- POMOCNÉ FUNKCE PRO ZOBRAZENÍ DAT ---
        onFocus(key) {
            this.focusedField = key;
        },
        onBlur() {
            setTimeout(() => {
                this.focusedField = null;
            }, 200);
        },
        selectSuggestion(name) {
            if (this.focusedField) {
                this.newFile.formData[this.focusedField] = name;
                this.focusedField = null; // Zavřít našeptávač
            }
        },
        showModal(title, message) {
            this.modal.title = title;
            this.modal.message = message;
            this.modal.visible = true;
        },

        closeModal() {
            this.modal.visible = false;
        },
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
        isLinkedField(fieldKey) {
            // 1. Varianta: Je to definované v Configu jako linkedKey?
            const currentTypeConfig = this.docTypes[this.newFile.type];
            if (currentTypeConfig && currentTypeConfig.linkedKey === fieldKey) {
                return true;
            }

            // 2. Varianta: Je to jedno z běžných jmenných polí? (POJISTKA)
            // Pokud se klíč pole rovná některému z těchto, zapneme našeptávač automaticky
            const commonNameFields = ["name", "suspect", "patient", "doctor", "owner", "citizen", "fullname"];
            if (commonNameFields.includes(fieldKey)) {
                return true;
            }

            return false;
        },
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
        processFilesStructure(rawFiles) {
            let profiles = {}; // Mapa: "jméno" -> Objekt složky
            let unlinked = []; // Soubory, které nikam nepatří

            // 1. KROK: Najdi všechny profily občanů
            rawFiles.forEach(file => {
                const type = this.getFileType(file);
                const typeConfig = this.docTypes[type];

                if (typeConfig && typeConfig.isProfile) {
                    // Získáme jméno z obsahu formuláře
                    const contentData = JSON.parse(file.metadata.content || "{}");
                    const citizenName = (contentData.name || "Neznámý").trim().toLowerCase();

                    // Vytvoříme strukturu složky
                    // Přidáme property 'isFolder', 'isOpen', 'children'
                    file.isFolder = true;
                    file.isOpen = false; // Defaultně zavřeno
                    file.children = [];
                    file.citizenNameNormalized = citizenName; // Pro snadné párování

                    // Uložíme do mapy (pokud je jméno unikátní, jinak přepíše - kolize jmen je riziko)
                    profiles[citizenName] = file;
                }
            });

            // 2. KROK: Roztřiď ostatní soubory
            rawFiles.forEach(file => {
                const type = this.getFileType(file);
                const typeConfig = this.docTypes[type];

                // Pokud to je samotný profil, přeskočíme (už jsme ho zpracovali)
                if (typeConfig && typeConfig.isProfile) return;

                let isLinked = false;

                // Pokud má typ definovaný 'linkedKey' (např. 'suspect' nebo 'name')
                if (typeConfig && typeConfig.linkedKey) {
                    try {
                        const contentData = JSON.parse(file.metadata.content || "{}");
                        const targetName = (contentData[typeConfig.linkedKey] || "").trim().toLowerCase();

                        if (targetName && profiles[targetName]) {
                            profiles[targetName].children.push(file);
                            isLinked = true;
                        }
                    } catch (e) {
                        console.error("Chyba při parsování pro linkování:", e);
                    }
                }

                if (!isLinked) {
                    unlinked.push(file);
                }
            });

            // 3. KROK: Vrať pole - napřed profily (Složky), pak volné soubory
            return [...Object.values(profiles), ...unlinked];
        },

        // Upravit toggle metodu pro otevírání složek
        toggleFolder(file) {
            if (file.isFolder) {
                file.isOpen = !file.isOpen;
            } else {
                this.selectFile(file);
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
                            [{ 'list': 'ordered' }, { 'list': 'bullet' }],
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
            if (!this.newFile.title || this.newFile.title.trim() === "") {
                this.showModal("Chyba záznamu", "Dokument musí mít vyplněný nadpis!");
                return;
            }

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
            }).catch(err => { });
        },

        handleMessage(event) {
            const item = event.data;

            if (item.action === 'open') {
                // 1. Nejdřív načteme definice typů (Config)
                this.docTypes = item.docTypes || {};

                // 2. Načteme surová data souborů
                this.files = item.files || [];
                this.emptyPapersCount = item.emptyPapersCount || 0;

                this.cabinetID = item.cabinetID;
                this.cabinetName = item.cabinetName;

                // 3. TEPRVE TEĎ spustíme třídění, protože už máme this.docTypes
                this.processedFiles = this.processFilesStructure(this.files);

                this.visible = true;
                this.searchQuery = '';
                this.mode = 'none';
                this.isSingleFileView = false;
                this.selectedFile = null;
                const s = item.cabinetStyle || {};
                this.activeStyle = {
                    logo: s.logo || null,
                    background: s.background || '#2c1e14',
                    sidebar: s.sidebar || '#3e2723',
                    accent: s.accent || '#ffcc80',
                    button: s.button || '#2e7d32'
                };
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