# Vývoj multiplatformní hry v enginu Godot s integrací AI prvků a datovou analytikou

## 1. Úvod
Moderní trendy v náboru studentů a marketingu vzdělávacích institucí se stále častěji orientují k interaktivním formám prezentace. Herní průmysl za posledních 5 let rostl o více než 70 %, což je 3× rychleji než filmový a audiovizuální průmysl. Gamifikace procesů získávání informací je trendem, který v poslední době přibližuje vzdělání mladým lidem navyklým na neustálý přísun podnětů formou okamžité zpětné vazby a dosažitelných cílů. S rostoucím podílem herního průmyslu se dá předpokládat, že dorůstající generace bude tento způsob prezentace brát jako normu, a v případě její neimplementace to bude pro univerzitu nevýhoda. Na tento trend reagují i ostatní univerzity – VUT se svým projektem Hrdina VUT, ČVUT s Neztrat se na ČVUT.

### 1.1 Limitace projektu
Vytvořit kompletní hru je úkol, který je pro jednotlivce v časovém kvantu určeném pro STČ nemožný, především kvůli velkému množství grafických assetů a jiných zdrojů, které by hra vyžadovala. Tento nedostatek jsem se snažil vyřešit využitím AI nástrojů, konkrétně Stable Diffusion XL, více v separátní kapitole. AI generace nicméně nebyla schopna generovat animace a neměla dostatečnou úroveň konzistence, proto jsem ji využil jen pro demonstraci v rámci jedné úrovně hry. Další limitací je právní hledisko. Současná legislativa neumožňuje zpracovat osobní údaje uživatelů čistě z marketingových zájmů bez souhlasu uživatelů. Vzhledem k tomu, že okénko o souhlasu může v náborové hře působit nevhodným dojmem a vzbudit zbytečné otázky, jsem jej v současné demo verzi neimplementoval. Více o sbírání dat v kapitole 5.

### 1.2 Cíl a koncept projektu
Vzhledem k limitacím projektu jsem si stanovil jako cíl vytvořit funkční a kompletní 2D hru, nasaditelnou na webu a stažitelnou jako spustitelný soubor pro Windows, macOS a Linux. Cílem bylo, aby tato hra obsahovala maximální množství recesivního a studentského humoru, který by ji mohl diferencovat od poměrně suchých praktik marketingu, ukázat lidštější tvář univerzity a přiblížit se studentskému vnímání okolí. Dalším cílem je, aby hra byla jednoduše pochopitelná a hratelná za relativně krátkou dobu a poskytovala uživateli přiměřené množství výzev a zábavy bez zbytečné frustrace.

## 2. Herní engine Godot
Výběr herního enginu byl klíčovým faktorem pro úspěch projektu. Godot Engine byl zvolen pro svou otevřenost (open source), jednoduchost a přehlednost, lehkost a vynikající podporu pro export do webového rozhraní i na desktopové platformy. Godot také disponuje velkým množstvím assetů, které jsou volně dostupné a stažitelné.

### 2.1 Architektura a možnosti enginu
Godot využívá systém scén a uzlů (nodes), podobně jako Unity a další konkurenční nástroje. Ten umožňuje vysokou míru hierarchické organizace a dědičnosti díky stromovému uspořádání uzlů – celá hra je strom, jednotlivé scény jsou jeho větve, které lze přidávat, odstraňovat a které mohou mezi sebou komunikovat. Právě dědičnost je koncept, na kterém hra stojí – například téměř všechny entity stojí na jednom jediném kódu a jsou identifikovány jen svými odlišnostmi, což bývají obrázky, dialogy a úkolové předměty, které mohou poskytovat. Tento design především zjednodušuje přidávání nových postav do hry na nutné minimum. Jazyk, ve kterém je projekt napsán, je GDScript – interpretovaný jazyk, koncepcí velmi podobný Pythonu. Engine používá různé předvytvořené funkce, z nichž považuji za důležité zmínit zejména _physics_process, která se volá každý snímek, a _ready, která se volá při zavedení scény do stromu scén.

### 2.2 Použité assety
Hra využívá asset DialogueNodes od tvůrce nagidev, který do enginu přidává nástroje pro vytváření a práci s dialogy pod MIT licencí. Tento nástroj je v projektu použit pod lehkou úpravou. Úpravy zahrnovaly změnu fontů a některých drobností pro správný rendering.

### 2.3 Licenční podmínky a ekonomické hledisko
Zásadním argumentem pro volbu enginu Godot byly jeho licenční podmínky, které jsou z hlediska vývoje, distribuce i následného provozování hry bezkonkurenční. Godot je distribuován pod svobodnou a extrémně benevolentní licencí MIT. Licence MIT znamená, že tvůrce hry má absolutní svobodu s výsledným produktem nakládat bez nutnosti odvádět jakékoliv licenční poplatky (royalties) nebo řešit skryté poplatky za instalace. Tento přístup ostře kontrastuje s podmínkami jiných populárních nástrojů, jako je například engine Unity. Přestože Unity nabízí bezplatné licence pro studenty a nekomerční využití, pro účely této práce by toto řešení bylo legislativně problematické. Vzhledem k tomu, že hra slouží k sebepropagaci instituce (náborová kampaň Univerzity Obrany), marketingu a proaktivnímu sběru uživatelských dat (fingerprinting), nelze ji klasifikovat jako čistě výzkumný či studijní projekt. Využití Unity by tak s vysokou pravděpodobností vyžadovalo zakoupení komerční licence, což by zbytečně navyšovalo finanční náročnost celého řešení. Zvolený přístup s enginem Godot tak zajišťuje nejen technologickou, ale i ekonomickou a legislativní nezávislost.

## 3. Vývoj
Tato hra je jeden z projektů, který iterativně a v různých podobách vyvíjím již několik let. Za tu dobu se ve hře objevilo mnoho různých mechanik, způsobů vývoje a integrace modulů do projektu. Jedním z hlavních cílů vývoje bylo vytvořit čistý a snadno rozšiřitelný kód. Toho bylo dosaženo důsledným využíváním objektově orientovaného programování v jazyce GDScript.

### 3.1 Unifikace herních objektů
Pro optimalizaci výkonu používá hra systém TileSetů – vrstev, které umožnují poskládání scény z jednotlivých menších a opakujících se textur. Tento princip je použit ve většině úrovní, aby se zamezilo načítání příliš velkých obrázků a assetů. Modularitu pro postavy řeší fakt, že jsou řešeny jako instance bázových scén. Postavy ve hře se dělí prakticky na tři kategorie – hráč, který využívá separátní kód, nepřátelské entity a neutrální entity. Všechny nepřátelské entity dědí z jednoho skriptu a scény – enemy_base – a jediné, co je definuje, je jejich sprite, projektil, který případně používají pro útok, zdraví a další parametry. Všichni nepřátelé sdílí detekci kolizí, pohyb a další základní parametry. Neutrální entity jsou všechny instancemi npc_base a definují je jejich dialogy, obrázky atd. Jednotlivé levely ve hře také sdílí většinu prostředků – UI, sběr dat, stopování času – a jsou jen zděděnými instancemi s odlišnou mapou a některými parametry.

### 3.2 Práce s pamětí, autoload skripty
Při změnách scén využívá Godot 3 základní mechanismy:
1.) smazání scény – uvolní paměť alokovanou pro scénu a odebere ji CPU kvantum
2.) zneviditelnění scény – grafické aspekty nejsou vidět, ale paměť scény a její proměnné jsou stále přístupné a CPU ji zpracovává
3.) oddělení scény od stromu scén – paměť je zachována, ale scéna není zpracovávána CPU

První způsob je použit pro jednotlivé levely – při načítání levelu je celá scéna zavedena do paměti (volání _ready) a začne být zpracovávána (_physics_process, je-li definována). Po ukončení je scéně odebrána paměť a je smazána. Pro zajištění perzistence některých důležitých dat, jako je inventář a statistiky hráče, jsou jako děti kořenu stromu scén přidány tzv. autoload skripty – jsou neustále v paměti a přístupné a fungují jako rozhraní mezi levely a perzistentními daty. Po načtení si tedy level vyžádá aktuální data od těchto skriptů, je-li to žádoucí. Tyto skripty zahrnují:
1.) Globals – globální proměnné, funkce pro sběr dat při spuštění hry
2.) JsonData – rozhraní dodávající informace o předmětech, které jsou pevně definované v JSON souboru
3.) PlayerInventory – skript uchovávající obsah inventáře a hotbaru a poskytující funkce pro správu
4.) InteractionManager – skript starající se o interakce hráče s entitami, jejich správné překrytí a udržuje seznam dosažitelných entit v okolí hráče

### 3.3 Škálovatelnost mechanik
Díky modulárnímu přístupu je přidání nového předmětu (itemu) nebo mechaniky otázkou vytvoření nového zdroje (Resource) nebo podědění stávající scény. To umožňuje rychlou iteraci obsahu bez nutnosti zásahu do jádra herní logiky. Pokud je potřeba přidat nové NPC, stačí definovat jeho dialogový strom a vizuální model, zatímco interaktivní systém zůstává identický pro všechny. To samé platí pro předměty – stačí dodatek v JSON databázi předmětů a dodat stejnojmenný obrázek do příslušné složky, ze které je automaticky načten.

### 3.4 Implementované herní mechaniky
Ve hře je implementován 8směrový pohyb hráče, inventář a hotbar, sada předmětů, které jsou děleny mezi úkolové předměty, zbraně a konzumovatelné předměty. Hráč používá mechaniku zdraví a štítu, které lze získat obchodováním, kdy jednotlivé neutrální postavy mohou nabízet předměty k prodeji za herní měnu, kterou lze najít volně nebo jako odměnu za zneškodnění nepřítele. U neutrálních postav jsou zavedeny dialogy s větvením a reakcemi na aktuální stav hry. Dále jsou ve hře implementováni nepřátelé, u kterých je napsán raycasting a minimální mechaniky pro sledování a detekci hráče na určitou vzdálenost, útoky a animace poškození. Celkem je ve hře 5 úrovní, první dvě klasické a další jako speciální minihry.

## 4. Využití umělé inteligence při tvorbě assetů

### 4.1 Problematika grafických assetů
Hra obsahuje přes 150 grafických assetů, což zabírá obrovské množství času a zdrojů. Po neúspěšné snaze oslovit oddělení marketingu s žádostí o pomoc jsem se rozhodl využít AI generování pro tuto část vývoje.

### 4.2 Infrastruktura pro AI generování, pixel art
Pro generování byl zvolen model **Stable Diffusion XL (SDXL)**. Jako výpočetní prostředí byl vybrán **Kaggle Notebook**, který oproti běžně využívanému Google Colab nabízí významně vyšší hardwarové specifikace, konkrétně 30 GiB paměti a dvě T4 GPU. 

Efekt pixel artu je dosažen použitím **LoRA** (Low-Rank Adaptation). LoRA je technika doladění neuronových sítí, která modifikuje pouze malou podmnožinu parametrů základního modelu pomocí nízkodimenzionálních matic. Místo přetrénování celého modelu se přidají adaptační vrstvy s řádově menším počtem parametrů, které model přizpůsobí specifickému stylu (v tomto případě pixel artu). Tato metoda je výpočetně efektivní a umožňuje rychlé přepínání mezi různými styly bez nutnosti načítat celé oddělené modely. Konkrétně jsem využil `nerijs/pixel-art-xl` z platformy Hugging Face. 

K načtení modelu a generaci slouží Python kód, který se navíc stará i o odstranění pozadí obrázku – AI má tendenci vytvářet zamlžené pozadí nebo detaily, které nejsou žádoucí, a případný upscale nebo downscale. Pro vyšší úroveň detailu a zachování smysluplnosti se osvědčilo generovat assety v 2×–4× vyšším rozlišení a downscalovat je po generaci sdružováním pixelů.

## 5. Datová analytika a identifikace uživatelů
Projekt by měl sloužit ke zviditelnění a popularizaci Univerzity Obrany. Aby šlo efektivně říct, zda tuto funkci plní, musela být implementována nějaká forma sběru dat o uživatelích. Tato sekce pojednává o problémech, na které jsem narazil, a přidružené implementaci HTTP/HTTPS serveru pro příjem dat od běžících instancí hry.

### 5.1 Jak probíhá identifikace uživatelů a jaká data jsou o nich k dispozici
V rámci výzkumu byla implementována metoda digitálního otisku (fingerprinting). Tato technika umožňuje identifikovat uživatele s určitou mírou přesnosti na základě jeho hardwarových a síťových charakteristik, jako jsou rozlišení obrazovky, verze prohlížeče, IP adresy apod., bez nutnosti ukládání cookies. Běžící instance hry, ať už v prohlížeči nebo lokálně, sesbírá pomocí zabudovaných funkcí GDScriptu maximum relevantních informací o uživateli. Z nich je spočítán hash, který je odeslán spolu s daty a funguje jako primární klíč do databáze uživatelů. Hra získává globální IP adresu HTTP requestem na api.ipify.org. Tuto adresu pak posílá na server.

### 5.2 Server
Na serveru jsou data uložena do LiteSQL databáze pro jejich perzistenci. Server dále s daty počítá a sdružuje je do přehledných schémat. Mezi další důležitá data patří odhad majetku uživatele, který je kalkulován na základě hardwarových specifikací, a přibližný odhad regionu na základě veřejné IP adresy. Tyto údaje jsou sdruženy do grafů, které mohou říkat, jaká je cílová skupina pro cílenou reklamu, a zefektivnit marketingové strategie Univerzity.

### 5.3 Protokoly pro komunikaci
Server naslouchá na portech 8080 pro HTTP a 8443 pro HTTPS. Stažitelné aplikace používají HTTP requesty pro jejich jednoduchost, webová verze používá HTTPS. 

**HTTPS** (Hypertext Transfer Protocol Secure) je šifrovaná verze HTTP protokolu využívající TLS/SSL certifikáty k zabezpečení komunikace mezi klientem a serverem. Implementace HTTPS je nutná z několika důvodů:
1.) Moderní prohlížeče blokují tzv. **Mixed Content** – situaci, kdy HTTPS stránka (hra běžící na claude.ai nebo jiné HTTPS doméně) se pokouší komunikovat s HTTP serverem. Prohlížeče z bezpečnostních důvodů takové requesty automaticky blokují.
2.) **CORS** (Cross-Origin Resource Sharing) je bezpečnostní mechanismus prohlížečů, který omezuje, ze kterých domén může webová aplikace načítat zdroje. Pro správnou funkčnost je žádoucí, aby server i hra běžely pod stejnou doménou, nebo aby server explicitně povolil přístup z domény hry pomocí CORS hlaviček.

V aktuální prezentační fázi je toto řešeno na `localhostu` s využitím self-signed certifikátů.

### 5.4 Právní rámec
Použití fingerprintingu podléhá regulaci GDPR a ePrivacy. Sběr informací je prováděn za účelem statistického vyhodnocení úspěšnosti náborové kampaně, přičemž uživatel by měl být v reálném nasazení informován o rozsahu sbíraných dat prostřednictvím informačního banneru nebo souhlasu.

## 6. Herní úrovně a implementované mechaniky
Tato kapitola popisuje konkrétní implementace úrovní.

### 6.1 Rekrutační pracoviště
Prvním úkolem hráče je zvládnout pohovor na rekrutačním pracovišti. Po příchodu na pracoviště však hráč zjistí, že dokumenty zamčené ve stolech se vzbouřily a začaly napadat svoje okolí. Cílem je zneškodnit dokumenty, což hráč zvládne jejich podepsáním pomocí házení propisek. Úroveň slouží k základnímu seznámení s designem a funkcemi hry.

### 6.2 Vyšetření ve vojenské nemocnici
Druhá úroveň staví hráče do vojenské nemocnice, kde nastane komplikace. V celé nemocnici vypadlo světlo a cílem hráče je s omezeným světlem projít bludištěm, nalézt klíč od skříně s pojistkami a nahodit je. V tom mu brání přízraky Libora, které jsou v nemocnici.

### 6.3 Příjímací zkoušky
Úroveň reprezentující příjímací zkoušky je pojata jako závodní minihra, kde je úkolem hráče porazit v závodu závodníky konkurenční univerzity TUV.

### 6.4 Kurz základní přípravy ve Vyškově
Tento level využívá po své vizuální stránce assety generované Stable Diffusion XL. Cílem hráče je sestřelovat stíhačky z pohybujícího se tanku pohybem myši. K tomu jej motivuje instruktor základní přípravy postupným ukazováním zavedené taktické výstroje.

### 6.5 Slavnostní přísaha
Zde je úkolem hráče správně projít slavnostní pochod. Hráč se snaží sjednotit krok pochodující jednotky do rytmu s pochodem K Defilé. Hudba ale postupně zrychluje a zpomaluje, jak to už v praxi bývá, což tento úkol značně ztěžuje. Většina testerů se shodla, že hraní této úrovně vylepšilo jejich úroveň pořadové přípravy.

## 7. Závěr a možnosti uplatnění
Předložená práce demonstruje, že Godot Engine je vysoce efektivním nástrojem pro tvorbu multiplatformních aplikací a nastiňuje komplexní možnosti jeho využití. Propojení herních mechanik s integrací AI při tvorbě assetů ukazuje moderní cestu vývoje, která šetří čas i zdroje.

**Shrnutí důležitých informací:**
* Byla vytvořena funkční 2D hra s 5 úrovněmi, plně hratelná v prohlížeči i na desktopu.
* Byl implementován modulární systém umožňující snadné rozšiřování o nový obsah.
* Využití SDXL s LoRA na platformě Kaggle se ukázalo jako robustní řešení pro generování herní grafiky ve stylu pixel art.
* Systém fingerprintingu poskytuje cenná data pro marketingové účely při zachování technické funkčnosti v rámci webových standardů.

**Možnosti uplatnění:**
Poznatky z této práce lze využít nejen při náboru studentů na vysoké školy, ale také v širším kontextu firemního vzdělávání, interaktivního marketingu nebo při vývoji nenáročných herních aplikací pro státní správu a samosprávu. Další rozvoj projektu by se mohl zaměřit na hlubší integraci procedurálního generování obsahu přímo v reálném čase.
