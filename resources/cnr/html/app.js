(function () {
    'use strict';

    const $ = (id) => document.getElementById(id);
    const PANELS = ['team-select', 'skin-picker', 'rank-picker', 'vehicle-picker', 'help', 'newlife-confirm', 'radio-input', 'inventory', 'ammu-shop', 'dealership'];

    function show(id)     { const el = $(id); if (el) el.classList.remove('hidden'); }
    function hide(id)     { const el = $(id); if (el) el.classList.add('hidden'); }
    function hideAll()    { PANELS.forEach(hide); }
    function isAnyOpen()  { return PANELS.some(id => { const e = $(id); return e && !e.classList.contains('hidden'); }); }

    function post(name, body) {
        return fetch('https://cnr/' + name, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify(body || {})
        }).then(r => r.json()).catch(() => ({ ok: false }));
    }

    const GUIDE = [
        {
            title: '1. Basics',
            html: `
                <p><strong>Elite Cops &amp; Robbers</strong> — pick a side and jump in. No levels or XP: both teams earn <strong>credits</strong> and spend them on gear. Credits are permanent (kept after dying or leaving jail) until spent or you use <code>/newlife</code>.</p>
                <table>
                    <tr><th>Key</th><th>Action</th></tr>
                    <tr><td><code>C</code></td><td>Cops: cuff a wanted robber, or open <strong>arrest options</strong> on a cuffed one</td></tr>
                    <tr><td><code>F</code></td><td>Enter the driver seat / hijack the driver</td></tr>
                    <tr><td><code>G</code></td><td>Enter / exit as a passenger</td></tr>
                    <tr><td><code>L</code></td><td>Lock / unlock your vehicle</td></tr>
                    <tr><td><code>E</code></td><td>Interact (rob stores, shops, terminals)</td></tr>
                    <tr><td><code>I</code></td><td>Inventory — weapons, items, credits</td></tr>
                    <tr><td><code>H</code></td><td>Open this guide</td></tr>
                    <tr><td><code>T</code></td><td>Chat — switch between <strong>Global</strong>, <strong>Local</strong> and <strong>Police Radio</strong></td></tr>
                    <tr><td><code>F7</code></td><td>Players list</td></tr>
                    <tr><td><code>/newlife</code></td><td>Full reset — back to team select</td></tr>
                    <tr><td><code>/help</code></td><td>Open this guide</td></tr>
                </table>
                <p>Your role, credits, cash and jail time are shown on the right-side bar.</p>
            `
        },
        {
            title: '2. Player Colors',
            html: `
                <table>
                    <tr><th>Color</th><th>Meaning</th></tr>
                    <tr><td><strong style="color:#1d6fff">Blue</strong></td><td>Cop</td></tr>
                    <tr><td><strong style="color:#e11d2a">Red</strong></td><td>Wanted robber — visible on the map</td></tr>
                    <tr><td><strong style="color:#ff8c00">Orange</strong></td><td>Prisoner — currently serving jail time</td></tr>
                    <tr><td><strong>White</strong></td><td>Innocent — hidden on the map</td></tr>
                </table>
                <p>An innocent robber stays hidden until they commit a crime (robbery or murder). Then they turn <strong style="color:#e11d2a">red</strong> and appear on the map for cops to hunt. Names in the kill/arrest feed and the join/leave messages use these same colors.</p>
            `
        },
        {
            title: '3. Cops',
            html: `
                <p>Spawn at <strong>Mission Row PD</strong> or <strong>Vespucci PD</strong>. Friendly fire between cops is <strong>off</strong> — you cannot damage other cops.</p>
                <h4>Making an arrest</h4>
                <p>Walk up to a <strong style="color:#e11d2a">wanted</strong> robber and press <code>C</code> to <strong>cuff</strong> them. Press <code>C</code> again next to a cuffed suspect to open the <strong>arrest menu</strong> (Standard or Instant arrest).</p>
                <h4>Earn credits</h4>
                <ul>
                    <li><strong>Standard Arrest</strong> — <strong>+6 credits + $1000</strong>. Cuff, press <code>C</code> for arrest options, pick a station (Mission Row / Vespucci), then escort the suspect to its arrest point.</li>
                    <li><strong>Instant Arrest</strong> — <strong>+3 credits, no cash</strong>. Cuff, press <code>C</code> → Instant Arrest; the suspect is jailed immediately (fewer credits and no $1000, no escort).</li>
                    <li><strong>Kill</strong> a wanted robber — <strong>+1 credit</strong></li>
                </ul>
                <h4>Spend credits</h4>
                <p>At the <strong>Armory</strong> and <strong>Vehicle Yard</strong> NPCs inside any PD: weapons, armor, vehicles and helicopters.</p>
                <h4>Penalties</h4>
                <ul>
                    <li>Killing an innocent player or NPC — <strong>−1 credit</strong></li>
                    <li>Killing an aggressive NPC in self-defense — no penalty</li>
                    <li>Disrupting other players' gameplay can lead to a kick or ban</li>
                </ul>
            `
        },
        {
            title: '4. Robbers',
            html: `
                <p>Spawn at <strong>random locations</strong> across Los Santos. You begin innocent and hidden on the map.</p>
                <h4>Make money</h4>
                <ul>
                    <li><strong>24/7 &amp; liquor stores</strong> — point your gun at the clerk. Reward: <strong>$1,000 + 1 credit</strong>. No credits needed.</li>
                    <li><strong>Jewelry store</strong> — costs <strong>3 credits</strong> to start, pays <strong>$3,000</strong>.</li>
                    <li><strong>Bank</strong> — costs <strong>5 credits</strong> to start, pays <strong>$5,000</strong>.</li>
                </ul>
                <p>Rob 24/7 stores to stack credits, then spend them on the bigger jewelry and bank jobs. Credits stay with you until spent or <code>/newlife</code>. Note: you leave jail with <strong>$0</strong> cash.</p>
                <h4>Buy gear</h4>
                <p>Arm up at any <strong>Ammu-Nation</strong> using cash from your jobs (Pistol $500 up to Sniper $12,000). 24/7 and liquor stores also sell food &amp; snacks; clothing stores and barbers change your look.</p>
            `
        },
        {
            title: '5. Crime & Jail',
            html: `
                <p>Jail time is added automatically per crime, and committing a crime makes you <strong style="color:#e11d2a">wanted</strong>.</p>
                <h4>Innocent robber</h4>
                <ul>
                    <li>Rob a store / jewelry / bank — <strong>wanted + 30 sec</strong></li>
                    <li>Murder any player or NPC — <strong>wanted + 1 min</strong></li>
                    <li>Injure a cop with gunfire — <strong>wanted + 30 sec</strong> (once only)</li>
                    <li>Steal a police vehicle — <strong>wanted + 30 sec</strong> (once per life)</li>
                </ul>
                <h4>Wanted robber</h4>
                <ul>
                    <li>Murder any player or NPC — <strong>+1 min per kill</strong></li>
                    <li>Steal a police vehicle — <strong>+30 sec</strong> (once per life)</li>
                </ul>
                <h4>Where you're held</h4>
                <ul>
                    <li><strong>3 min or less</strong> — shared holding cell at Mission Row or Vespucci</li>
                    <li><strong>More than 3 min</strong> — Bolingbroke Penitentiary</li>
                </ul>
            `
        },
        {
            title: '6. Handcuffs',
            html: `
                <ul>
                    <li>Cops can only cuff <strong>wanted robbers</strong> — stand close and press <code>C</code>.</li>
                    <li>A cuffed robber follows the cop on foot and rides along in their vehicle.</li>
                    <li>Press <code>C</code> again next to a cuffed suspect for <strong>arrest options</strong>: Standard (escort to a station, +6 credits) or Instant (jail now, +3 credits).</li>
                    <li><strong>If the cop dies or disconnects</strong> — the cuffed robber is <strong>freed</strong> (uncuffed automatically).</li>
                    <li><strong>If you disconnect while cuffed</strong> — you go straight to jail on your next connect.</li>
                </ul>
            `
        },
        {
            title: '7. Contributions',
            html: `
                <p>This server is built on community-made mods. Special thanks to these creators.</p>
                <table>
                    <tr><th>Mod</th><th>Author</th><th>Source</th></tr>
                    <tr><td>NativeUI</td><td>FrazzIe</td><td>github.com</td></tr>
                    <tr><td>vMenu</td><td>Tom Grobbe</td><td>github.com</td></tr>
                    <tr><td>bob74_ipl</td><td>Bob 74</td><td>github.com</td></tr>
                    <tr><td>LSPD Brute Stockade</td><td>AGModsTeam</td><td>modshost.co</td></tr>
                    <tr><td>Police Vapid Aleutian</td><td>Darky</td><td>modshost.co</td></tr>
                    <tr><td>Police Grotti Itali RSX</td><td>xOutlaw</td><td>modshost.co</td></tr>
                    <tr><td>Tailgater SR</td><td>Grodd Customs</td><td>modshost.co</td></tr>
                    <tr><td>Ubermacht Cypher MX2</td><td>SupremoCustoms</td><td>modshost.co</td></tr>
                    <tr><td>Mission Row PD</td><td>SLB2k11 (twitch.tv/slb2k11)</td><td>gta5-mods.com</td></tr>
                    <tr><td>Vespucci PD</td><td>ShmannWorks</td><td>buy-tebex.io</td></tr>
                    <tr><td>Alamo Unmarked</td><td>Dzy</td><td>modshost.co</td></tr>
                    <tr><td>LEO RCV</td><td>Arctic Development</td><td>modshost.co</td></tr>
                    <tr><td>Police Dirtbike BF400</td><td>F5544</td><td>gta5-mods.com</td></tr>
                    <tr><td>Police Granger 3600LX</td><td>Fadilj</td><td>modshost.co</td></tr>
                    <tr><td>Pfister Comet ST2</td><td>seb5a</td><td>modshost.co</td></tr>
                    <tr><td>Shinobi Drag</td><td>SilentM503, TheAdmiester</td><td>modshost.co</td></tr>
                    <tr><td>Ubermacht Sentinel RTS</td><td>MadDave95Bonnet</td><td>modshost.co</td></tr>
                    <tr><td>Police Sentinel GTS</td><td>xOutlaw</td><td>modshost.co</td></tr>
                    <tr><td>Civilian Patriot M1</td><td>Model EditShal, ScreenshootsHurricane</td><td>modshost.co</td></tr>
                    <tr><td>Cyclone V10</td><td>SilentM503, TheAdmiester</td><td>modshost.co</td></tr>
                    <tr><td>Dinka Thrust Police Bike</td><td>IlayArye</td><td>gta5-mods.com</td></tr>
                    <tr><td>Dewbauchee Strage</td><td>Alex. KA.</td><td>modshost.co</td></tr>
                    <tr><td>Maibatsu Sanchez SuperMotard</td><td>Nailux</td><td>modshost.co</td></tr>
                    <tr><td>YouTool Interior</td><td>smeggo</td><td>gta5-mods.com</td></tr>
                    <tr><td>Bolingbroke Penitentiary Interior</td><td>MrBrown1999</td><td>gta5-mods.com</td></tr>
                </table>
            `
        },
    ];

    let lastSkinsByTeam = { cop: [], robber: [] };

    function renderTeamSelect(payload) {
        lastSkinsByTeam = (payload && payload.skinsByTeam) || { cop: [], robber: [] };
        hideAll();
        show('team-select');
    }

    document.querySelectorAll('#team-select .js-team').forEach(btn => {
        btn.addEventListener('click', () => {
            const side = btn.parentElement.getAttribute('data-side');
            post('cnr/chooseTeam', { side });
        });
    });

    let creatorState = {
        side: 'cop',
        stations: null,
        gender: 'male',
        father: 0,
        mother: 0,
        shapeMix: 0.5,
        skinMix: 0.5,
        eyes: 0,
        hair: 0,
        hairColor: 0,
        beard: 0,
        beardColor: 0,
        top: 1,
        topTxt: 0,
        pants: 1,
        pantsTxt: 0,
        shoes: 1,
        shoesTxt: 0,
        arms: 0
    };

    function renderSkinPicker(payload) {
        creatorState.side = payload.side || 'cop';
        creatorState.stations = payload.stations || null;


        creatorState.gender = 'male';
        creatorState.father = 0;
        creatorState.mother = 0;
        creatorState.shapeMix = 0.5;
        creatorState.skinMix = 0.5;
        creatorState.eyes = 0;
        creatorState.hair = 4;
        creatorState.hairColor = 2;
        creatorState.beard = 0;
        creatorState.beardColor = 0;
        creatorState.top = 1;
        creatorState.topTxt = 0;
        creatorState.pants = 1;
        creatorState.pantsTxt = 0;
        creatorState.shoes = 1;
        creatorState.shoesTxt = 0;
        creatorState.arms = 0;


        const pickerPanel = document.querySelector('#skin-picker .panel');
        if (pickerPanel) {
            pickerPanel.className = 'panel panel--skin ' + (creatorState.side === 'cop' ? 'panel--accent-cop' : 'panel--accent-robber');
        }

        $('skin-picker-title').textContent = creatorState.side === 'cop' ? 'POLICE RECRUIT' : 'ROBBER CHARACTER';
        $('station-chooser').classList.toggle('hidden', !(creatorState.side === 'cop' && creatorState.stations));


        const isCop = (creatorState.side === 'cop');
        $('clothing-cop-hint').style.display = isCop ? 'block' : 'none';
        document.querySelectorAll('.clothing-item').forEach(el => {
            el.style.display = isCop ? 'none' : 'block';
        });


        updateSliderVisuals();
        updateGenderButtons();
        updateBeardVisibility();


        openTab('parents');

        hideAll();
        show('skin-picker');


        pushCreatorPreview();
    }

    function openTab(tabId) {
        document.querySelectorAll('#skin-picker .creator-tab').forEach(tab => {
            tab.classList.toggle('active', tab.dataset.tab === tabId);
        });
        document.querySelectorAll('#skin-picker .creator-pane').forEach(pane => {
            pane.classList.toggle('hidden', pane.id !== 'pane-' + tabId);
        });
    }

    function updateSliderVisuals() {

        const map = {
            'father': creatorState.father,
            'mother': creatorState.mother,
            'shape': Math.round(creatorState.shapeMix * 100),
            'skin': Math.round(creatorState.skinMix * 100),
            'eyes': creatorState.eyes,
            'hair': creatorState.hair,
            'hair-color': creatorState.hairColor,
            'beard': creatorState.beard,
            'beard-color': creatorState.beardColor,
            'top': creatorState.top,
            'top-txt': creatorState.topTxt,
            'pants': creatorState.pants,
            'pants-txt': creatorState.pantsTxt,
            'shoes': creatorState.shoes,
            'shoes-txt': creatorState.shoesTxt,
            'arms': creatorState.arms
        };

        for (const [key, val] of Object.entries(map)) {
            const input = $('slider-' + key);
            const label = $('val-' + key);
            if (input) input.value = val;
            if (label) label.textContent = val;
        }
    }

    function updateGenderButtons() {
        const isMale = (creatorState.gender === 'male');
        $('gender-male').classList.toggle('active-gender', isMale);
        $('gender-female').classList.toggle('active-gender', !isMale);
    }

    function updateBeardVisibility() {
        const isMale = (creatorState.gender === 'male');
        $('beard-control-group').style.display = isMale ? 'block' : 'none';
        $('beard-color-control-group').style.display = isMale ? 'block' : 'none';
    }

    function pushCreatorPreview() {
        post('cnr/previewSkin', {
            isCustom: true,
            gender: creatorState.gender,
            father: parseInt(creatorState.father, 10),
            mother: parseInt(creatorState.mother, 10),
            shapeMix: parseFloat(creatorState.shapeMix),
            skinMix: parseFloat(creatorState.skinMix),
            eyes: parseInt(creatorState.eyes, 10),
            hair: parseInt(creatorState.hair, 10),
            hairColor: parseInt(creatorState.hairColor, 10),
            beard: parseInt(creatorState.beard, 10),
            beardColor: parseInt(creatorState.beardColor, 10),
            top: parseInt(creatorState.top, 10),
            topTxt: parseInt(creatorState.topTxt, 10),
            pants: parseInt(creatorState.pants, 10),
            pantsTxt: parseInt(creatorState.pantsTxt, 10),
            shoes: parseInt(creatorState.shoes, 10),
            shoesTxt: parseInt(creatorState.shoesTxt, 10),
            arms: parseInt(creatorState.arms, 10),
            side: creatorState.side
        });
    }


    document.querySelectorAll('#skin-picker .creator-tab').forEach(btn => {
        btn.addEventListener('click', () => {
            openTab(btn.dataset.tab);
        });
    });


    $('gender-male').addEventListener('click', () => {
        creatorState.gender = 'male';
        updateGenderButtons();
        updateBeardVisibility();
        pushCreatorPreview();
    });
    $('gender-female').addEventListener('click', () => {
        creatorState.gender = 'female';
        updateGenderButtons();
        updateBeardVisibility();
        pushCreatorPreview();
    });


    const SLIDERS = ['father', 'mother', 'shape', 'skin', 'eyes', 'hair', 'hair-color', 'beard', 'beard-color', 'top', 'top-txt', 'pants', 'pants-txt', 'shoes', 'shoes-txt', 'arms'];
    SLIDERS.forEach(key => {
        const slider = $('slider-' + key);
        if (slider) {
            slider.addEventListener('input', () => {
                const val = parseInt(slider.value, 10);
                $('val-' + key).textContent = val;

                if (key === 'shape') {
                    creatorState.shapeMix = val / 100;
                } else if (key === 'skin') {
                    creatorState.skinMix = val / 100;
                } else {
                    const camelKey = key.replace(/-([a-z])/g, (g) => g[1].toUpperCase());
                    creatorState[camelKey] = val;
                }
                pushCreatorPreview();
            });
        }
    });

    $('skin-random').addEventListener('click', () => {
        creatorState.gender = Math.random() > 0.5 ? 'male' : 'female';
        creatorState.father = Math.floor(Math.random() * 46);
        creatorState.mother = Math.floor(Math.random() * 46);
        creatorState.shapeMix = Math.random();
        creatorState.skinMix = Math.random();
        creatorState.eyes = Math.floor(Math.random() * 32);
        creatorState.hair = Math.floor(Math.random() * 75);
        creatorState.hairColor = Math.floor(Math.random() * 64);
        creatorState.beard = creatorState.gender === 'male' ? Math.floor(Math.random() * 29) : 0;
        creatorState.beardColor = Math.floor(Math.random() * 64);
        creatorState.top = Math.floor(Math.random() * 141);
        creatorState.topTxt = Math.floor(Math.random() * 16);
        creatorState.pants = Math.floor(Math.random() * 91);
        creatorState.pantsTxt = Math.floor(Math.random() * 16);
        creatorState.shoes = Math.floor(Math.random() * 81);
        creatorState.shoesTxt = Math.floor(Math.random() * 16);
        creatorState.arms = Math.floor(Math.random() * 81);

        updateSliderVisuals();
        updateGenderButtons();
        updateBeardVisibility();
        pushCreatorPreview();
    });

    $('skin-spawn').addEventListener('click', () => {
        let station = null;
        if (creatorState.side === 'cop' && creatorState.stations) {
            const r = document.querySelector('#station-chooser input[name=station]:checked');
            station = r ? r.value : 'missionRow';
        }

        const skinData = {
            isCustom: true,
            gender: creatorState.gender,
            father: parseInt(creatorState.father, 10),
            mother: parseInt(creatorState.mother, 10),
            shapeMix: parseFloat(creatorState.shapeMix),
            skinMix: parseFloat(creatorState.skinMix),
            eyes: parseInt(creatorState.eyes, 10),
            hair: parseInt(creatorState.hair, 10),
            hairColor: parseInt(creatorState.hairColor, 10),
            beard: parseInt(creatorState.beard, 10),
            beardColor: parseInt(creatorState.beardColor, 10),
            top: parseInt(creatorState.top, 10),
            topTxt: parseInt(creatorState.topTxt, 10),
            pants: parseInt(creatorState.pants, 10),
            pantsTxt: parseInt(creatorState.pantsTxt, 10),
            shoes: parseInt(creatorState.shoes, 10),
            shoesTxt: parseInt(creatorState.shoesTxt, 10),
            arms: parseInt(creatorState.arms, 10)
        };

        post('cnr/chooseSkin', { side: creatorState.side, skin: skinData, station: station });
        hide('skin-picker');
    });

    let rankState = { ranks: [], xp: 0, selectedRankId: null, selectedSkin: null };

    function renderRankPicker(payload) {
        rankState.ranks = payload.ranks || [];
        rankState.xp    = payload.xp || 0;
        rankState.selectedRankId = null;
        rankState.selectedSkin   = null;

        const list = $('rank-list');
        list.innerHTML = '';
        rankState.ranks.forEach(r => {
            const unlocked = (rankState.xp >= (r.xp || 0));
            const row = document.createElement('div');
            row.className = 'rank-row' + (unlocked ? '' : ' locked');
            row.dataset.rankId = r.id;
            row.innerHTML = `
                <span class="rank-name">${r.id}. ${escapeHtml(r.name)}</span>
                <span class="juris-badge juris-${escapeHtml(r.jurisdiction || '')}">${escapeHtml(r.jurisdiction || '')}</span>
                <span class="xp-badge">${r.xp} XP</span>
                <span class="xp-badge">${unlocked ? '✓' : '🔒'}</span>
            `;
            if (unlocked) {
                row.addEventListener('click', () => selectRank(r));
            }
            list.appendChild(row);
        });
        $('rank-skin-row').classList.add('hidden');
        hideAll();
        show('rank-picker');
    }

    function selectRank(r) {
        rankState.selectedRankId = r.id;
        rankState.selectedSkin = null;
        document.querySelectorAll('#rank-list .rank-row').forEach(el => {
            el.classList.toggle('selected', parseInt(el.dataset.rankId, 10) === r.id);
        });
        $('rank-skin-rank-name').textContent = r.name;
        const chips = $('rank-skin-chips');
        chips.innerHTML = '';
        (r.skins || []).forEach(s => {
            const chip = document.createElement('span');
            chip.className = 'chip';
            chip.textContent = s;
            chip.addEventListener('click', () => {
                rankState.selectedSkin = s;
                chips.querySelectorAll('.chip').forEach(c => c.classList.toggle('selected', c === chip));
            });
            chips.appendChild(chip);
        });
        $('rank-skin-row').classList.remove('hidden');
    }

    $('rank-apply').addEventListener('click', () => {
        if (!rankState.selectedRankId || !rankState.selectedSkin) return;
        post('cnr/applyRank', { rankId: rankState.selectedRankId, skin: rankState.selectedSkin });
        hide('rank-picker');
    });
    $('rank-close').addEventListener('click', () => { post('cnr/closeHelp', {}); hide('rank-picker'); });

    function renderVehiclePicker(payload) {
        const grid = $('vehicle-grid');
        grid.innerHTML = '';
        (payload.vehicles || []).forEach(v => {
            const unlocked = v.unlocked !== false;
            const cell = document.createElement('div');
            cell.className = 'vehicle-cell' + (unlocked ? '' : ' locked');
            cell.innerHTML = `
                <div class="vname">${escapeHtml(v.model || '')}</div>
                <div class="vrank">${escapeHtml(v.rankName || '')}</div>
            `;
            if (unlocked) {
                cell.addEventListener('click', () => {
                    post('cnr/spawnVehicle', { model: v.model });
                    hide('vehicle-picker');
                });
            }
            grid.appendChild(cell);
        });
        hideAll();
        show('vehicle-picker');
    }
    $('vehicle-close').addEventListener('click', () => { post('cnr/closeHelp', {}); hide('vehicle-picker'); });

    function renderHelp() {
        const nav = $('help-nav');
        const content = $('help-content');
        nav.innerHTML = '';
        content.innerHTML = '';
        GUIDE.forEach((sec, i) => {
            const item = document.createElement('div');
            item.className = 'help-nav-item' + (i === 0 ? ' active' : '');
            item.textContent = sec.title;
            item.addEventListener('click', () => {
                document.querySelectorAll('.help-nav-item').forEach(x => x.classList.remove('active'));
                item.classList.add('active');
                content.innerHTML = `<h3>${escapeHtml(sec.title)}</h3>${sec.html}`;
                content.scrollTop = 0;
            });
            nav.appendChild(item);
        });
        content.innerHTML = `<h3>${escapeHtml(GUIDE[0].title)}</h3>${GUIDE[0].html}`;
        hideAll();
        show('help');
    }
    $('help-close').addEventListener('click', () => { post('cnr/closeHelp', {}); hide('help'); });

    function renderNewLifeConfirm() { hideAll(); show('newlife-confirm'); }
    $('newlife-yes').addEventListener('click', () => { post('cnr/newLifeConfirm', { confirm: true,  confirmed: true  }); hide('newlife-confirm'); });
    $('newlife-no').addEventListener('click', () => { post('cnr/newLifeConfirm', { confirm: false, confirmed: false }); hide('newlife-confirm'); });

    function renderRadioInput() {
        $('radio-text').value = '';
        hideAll();
        show('radio-input');
        setTimeout(() => $('radio-text').focus(), 50);
    }
    function sendRadio() {
        const text = ($('radio-text').value || '').trim();
        if (!text) { hide('radio-input'); post('cnr/closeHelp', {}); return; }
        post('cnr/sendRadio', { text });
        hide('radio-input');
    }
    $('radio-send').addEventListener('click', sendRadio);
    $('radio-cancel').addEventListener('click', () => { hide('radio-input'); post('cnr/closeHelp', {}); });
    $('radio-text').addEventListener('keydown', (e) => { if (e.key === 'Enter') sendRadio(); });

    function pushRadioMessage(payload) {
        if (hudState.side !== 'cop') return;
        const feed = $('radio-feed');
        const msg = document.createElement('div');
        msg.className = 'radio-msg';
        msg.innerHTML = `<span class="from">${escapeHtml(payload.from || 'Dispatch')}</span><span class="body">${escapeHtml(payload.text || '')}</span>`;
        feed.appendChild(msg);
        setTimeout(() => msg.classList.add('fading'), 7200);
        setTimeout(() => { if (msg.parentNode) msg.parentNode.removeChild(msg); }, 8000);
        while (feed.childElementCount > 6) feed.removeChild(feed.firstChild);
    }

    let hudState = { side: 'none', xp: 0, jailSeconds: 0, jailDebtSeconds: 0, servingJail: false, rank: null, cash: 0, credits: 0 };

    function renderHud(payload) {
        Object.assign(hudState, payload || {});
        const hud = $('hud');
        const radioFeed = $('radio-feed');
        if (hudState.side !== 'cop' && hudState.side !== 'robber') {
            hud.classList.add('hidden');
            radioFeed.innerHTML = '';
            return;
        }
        if (hudState.side !== 'cop') {
            radioFeed.innerHTML = '';
            hide('radio-input');
        }
        hud.classList.remove('hidden');
        hud.classList.toggle('robber', hudState.side === 'robber');

        $('hud-side-icon').textContent = hudState.side === 'cop' ? '🔵' : '🔴';

        if (hudState.side === 'cop') {
            // Cops have no XP/levels — the bar shows POLICE + credits + cash.
            // Not clamped to 0: killing innocents can push credits negative (-1, -2…)
            // and that penalty must be visible.
            const credits = Math.floor(Number(hudState.credits || 0));
            $('hud-line-primary').innerHTML = '<span>Police Officer</span>';
            $('hud-bar-fill').style.width = '100%';
            $('hud-line-secondary').innerHTML =
                '<span class="hud-xp hud-xp--cop">' + credits + ' credits</span>'
                + '<span class="hud-sep"> · </span>'
                + '<span class="hud-cash">$' + escapeHtml(formatCash(hudState.cash || 0)) + '</span>';
            $('hud-line-jail').innerHTML = '';   // cops have no jail line
        } else {
            // Robber: no XP/levels — credits replace them. Bar is full; credits + cash + jail
            // status sit in the subline.
            const credits = Math.max(0, Math.floor(Number(hudState.credits || 0)));
            const pct = 100;

            const serving = hudState.servingJail && (hudState.jailSeconds || 0) > 0;
            const debt = Math.max(0, Math.floor(Number(hudState.jailDebtSeconds || 0)));
            const sec = Math.max(0, Math.floor(Number(hudState.jailSeconds || 0)));

            // Status word on the bar: PRISONER (orange) while serving, WANTED (red) while
            // wanted / carrying jail debt, otherwise INNOCENT (white).
            let statusWord, statusClass;
            if (serving) { statusWord = 'PRISONER'; statusClass = 'hud-status--prisoner'; }
            else if (hudState.wanted || debt > 0) { statusWord = 'WANTED'; statusClass = 'hud-status--wanted'; }
            else { statusWord = 'INNOCENT'; statusClass = 'hud-status--innocent'; }
            $('hud-line-primary').innerHTML = '<span>ROBBER</span>'
                + '<span class="hud-status ' + statusClass + '">' + statusWord + '</span>';
            $('hud-bar-fill').style.width = pct + '%';

            let jail = 'Clean';
            if (serving) jail = 'Serving ' + formatMMSS(sec);
            else if (debt > 0) jail = 'Jail debt ' + formatMMSS(debt);

            $('hud-line-secondary').innerHTML =
                '<span class="hud-xp hud-xp--rob">' + credits + ' credits</span>'
                + '<span class="hud-sep"> · </span>'
                + '<span class="hud-cash">$' + escapeHtml(formatCash(hudState.cash || 0)) + '</span>';
            // Jail status on its OWN line below credits/cash. Orange while serving / in
            // debt, otherwise a gray "Clean Record". #2
            if (serving || debt > 0) {
                $('hud-line-jail').innerHTML = '<span class="hud-jail">' + escapeHtml(jail) + '</span>';
            } else {
                $('hud-line-jail').innerHTML = '<span class="hud-clean">Clean Record</span>';
            }
        }
    }

    function renderJailUpdate(payload) {
        hudState.jailSeconds = payload.seconds || 0;
        hudState.servingJail = (hudState.jailSeconds || 0) > 0;
        if (hudState.side === 'robber') renderHud({});
    }

    function pushNotify(payload) {
        const cont = $('notifications');
        const t = document.createElement('div');
        t.className = 'toast ' + (payload.level || '');
        t.textContent = payload.text || '';
        cont.appendChild(t);
        setTimeout(() => t.classList.add('fading'), (payload.duration || 4000) - 600);
        setTimeout(() => { if (t.parentNode) t.parentNode.removeChild(t); }, payload.duration || 4000);
        while (cont.childElementCount > 5) cont.removeChild(cont.firstChild);
    }

    function formatMMSS(sec) {
        sec = Math.max(0, sec | 0);
        const m = (sec / 60) | 0;
        const s = sec % 60;
        return (m < 10 ? '0' : '') + m + ':' + (s < 10 ? '0' : '') + s;
    }
    function formatCash(n) {
        n = Math.floor(Number(n) || 0);
        return n.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ',');
    }
    function escapeHtml(s) {
        return String(s == null ? '' : s)
            .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;').replace(/'/g, '&#39;');
    }

    function renderInventory(payload) {
        payload = payload || {};
        const inv = payload.inventory || {};
        const items = payload.items || {};
        const weapons = payload.weapons || [];
        const cash = Number(payload.cash || 0);
        const xp = Number(payload.xp || 0);

        const credits = Number(payload.credits || 0);
        const statusEl = $('inv-status');
        statusEl.innerHTML = `
            <div class="inv-stat"><span class="inv-stat-label">CASH</span><span class="inv-stat-val">$${formatCash(cash)}</span></div>
            <div class="inv-stat"><span class="inv-stat-label">CREDITS</span><span class="inv-stat-val">${Math.floor(credits)}</span></div>
        `;

        const weapEl = $('inv-weapons');
        weapEl.innerHTML = '';
        if (weapons.length === 0) {
            weapEl.innerHTML = '<div class="inv-empty">No weapons equipped.</div>';
        } else {
            weapons.forEach(w => {
                const cell = document.createElement('div');
                cell.className = 'inv-weapon';
                cell.innerHTML = `<span class="wname">${escapeHtml(w.name.replace(/^WEAPON_/, '').replace(/_/g, ' '))}</span><span class="wammo">${w.ammo}</span>`;
                weapEl.appendChild(cell);
            });
        }

        const itemsEl = $('inv-items');
        itemsEl.innerHTML = '';
        const keys = Object.keys(items);
        if (keys.length === 0) {
            itemsEl.innerHTML = '<div class="inv-empty">No consumable items defined.</div>';
        } else {
            keys.forEach(k => {
                const def = items[k] || {};
                const count = inv[k] || 0;
                const cell = document.createElement('div');
                cell.className = 'inv-item' + (count <= 0 ? ' empty' : '');
                cell.innerHTML = `
                    <div class="inv-item-head">
                        <span class="inv-item-name">${escapeHtml(def.label || k)}</span>
                        <span class="inv-item-count">×${count}</span>
                    </div>
                    <div class="inv-item-meta">+${def.heal || 0} HP · max ${def.max || '?'}</div>
                    <button type="button" class="btn btn-primary inv-use" data-key="${escapeHtml(k)}" ${count <= 0 ? 'disabled' : ''}>USE</button>
                `;
                itemsEl.appendChild(cell);
            });
            itemsEl.querySelectorAll('.inv-use').forEach(btn => {
                btn.addEventListener('click', () => {
                    if (btn.hasAttribute('disabled')) return;
                    post('cnr/inventoryUse', { key: btn.dataset.key });
                });
            });
        }

        hideAll();
        show('inventory');
    }
    $('inventory-close').addEventListener('click', () => { post('cnr/inventoryClose', {}); hide('inventory'); });

    function renderAmmuShop(payload) {
        payload = payload || {};
        $('ammu-cash').textContent = formatCash(payload.cash || 0);
        const grid = $('ammu-grid');
        grid.innerHTML = '';

        const byCat = {};
        (payload.items || []).forEach(it => {
            (byCat[it.category || 'Misc'] = byCat[it.category || 'Misc'] || []).push(it);
        });
        Object.keys(byCat).forEach(cat => {
            const header = document.createElement('div');
            header.className = 'shop-cat';
            header.textContent = cat;
            grid.appendChild(header);
            byCat[cat].forEach(it => {
                const cell = document.createElement('div');
                cell.className = 'shop-cell';
                const sub = (it.ammo ? `Ammo +${it.ammo}` : '');
                cell.innerHTML = `
                    <div class="shop-name">${escapeHtml(it.label || it.weapon)}</div>
                    <div class="shop-meta">${escapeHtml(sub)}</div>
                    <div class="shop-price">$${formatCash(it.price || 0)}</div>
                    <button type="button" class="btn btn-primary shop-buy">BUY</button>
                `;
                cell.querySelector('.shop-buy').addEventListener('click', () => {
                    post('cnr/buyWeapon', { key: it.weapon });
                });
                grid.appendChild(cell);
            });
        });
        hideAll();
        show('ammu-shop');
    }
    $('ammu-close').addEventListener('click', () => { post('cnr/closeShop', {}); hide('ammu-shop'); });

    function renderDealership(payload) {
        payload = payload || {};
        $('dealer-cash').textContent = formatCash(payload.cash || 0);
        const grid = $('dealer-grid');
        grid.innerHTML = '';
        (payload.cars || []).forEach(c => {
            const cell = document.createElement('div');
            cell.className = 'shop-cell';
            cell.innerHTML = `
                <div class="shop-name">${escapeHtml(c.label || c.model)}</div>
                <div class="shop-meta">${escapeHtml(c.tier || '')}</div>
                <div class="shop-price">$${formatCash(c.price || 0)}</div>
                <button type="button" class="btn btn-primary shop-buy">BUY</button>
            `;
            cell.querySelector('.shop-buy').addEventListener('click', () => {
                post('cnr/buyCar', { model: c.model });
            });
            grid.appendChild(cell);
        });
        hideAll();
        show('dealership');
    }
    $('dealer-close').addEventListener('click', () => { post('cnr/closeShop', {}); hide('dealership'); });

    window.addEventListener('message', (e) => {
        const data = e.data || {};
        switch (data.type) {
            case 'teamSelect':       renderTeamSelect(data.payload || data); break;
            case 'skinPicker':       renderSkinPicker(data.payload || data); break;
            case 'rankPicker':
            case 'rankList':         renderRankPicker(data.payload || data); break;
            case 'vehiclePicker':    renderVehiclePicker(data.payload || data); break;
            case 'ammuShop':         renderAmmuShop(data.payload || data); break;
            case 'dealership':       renderDealership(data.payload || data); break;
            case 'help':             renderHelp(); break;
            case 'newLifeConfirm':   renderNewLifeConfirm(); break;
            case 'radioInput':       renderRadioInput(); break;
            case 'radioRecv':        pushRadioMessage(data.payload || data); break;
            case 'hudUpdate':        renderHud(data.payload || data); break;
            case 'jailTimeUpdate':   renderJailUpdate(data.payload || data); break;
            case 'notify':           pushNotify(data.payload || data); break;
            case 'inventory':        renderInventory(data.payload || data); break;
            case 'closeInventory':   hide('inventory'); break;
            case 'closeAll':
            case 'close':            hideAll(); break;
        }
    });

    document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape' && isAnyOpen()) {
            hideAll();
            post('cnr/closeHelp', {});
        }
    });
})();
