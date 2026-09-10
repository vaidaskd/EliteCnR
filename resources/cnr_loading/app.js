(function () {
    'use strict';

    // ---- Rotating gameplay tips ----
    var TIPS = [
        'Aim a weapon at a store clerk for 1 second to start a robbery — you get $1,000 and 1 credit.',
        'Jewelry pays $3,000 (3 credits to start); banks pay $5,000 (5 credits). Rob 24/7 stores first to stack credits.',
        'Cops: approach a wanted robber on foot and press C to cuff them, then press C again for arrest options.',
        'Standard Arrest: escort a cuffed suspect to a station arrest point for +6 credits and $1000. Instant Arrest jails them on the spot for +3 credits.',
        'Starting a robbery marks you WANTED — a red blip visible to all cops until arrested or jailed.',
        'There are no levels or ranks. Both sides use a credit system — earn credits, spend them on gear.',
        '3 minutes or less of jail time? You serve it at Mission Row or Vespucci holding cells.',
        'More than 3 minutes of jail sends you to Bolingbroke Penitentiary.',
        'Press T to chat — switch between Global, Local and Police Radio channels.',
        'Cops spawn at Mission Row PD or Vespucci PD — your choice at character creation.',
        'Spend credits at the armory NPC for better weapons, armor, and police vehicles.',
        'As a cop, killing an innocent (non-wanted) player or NPC costs 1 credit — only red-blip targets are fair game.',
        'Stealing a new police car adds 30 seconds to your jail time. Murder adds 1 minute; a robbery adds 30 seconds.',
        'Press H in-game to open the full server guide with rules and credit costs.',
        'Innocent robbers turn WANTED the moment they commit a crime — then cops can hunt and cuff them.',
        'Cops earn 1 credit per kill but 6 credits per arrest — always prioritise the cuffs.',
        'Name colors: blue = cop, red = wanted robber, orange = prisoner, white = innocent (hidden on the map).',
    ];

    var tipEl = document.getElementById('tip');
    var tipIndex = 0;

    function showNextTip() {
        if (!tipEl) return;
        tipEl.style.opacity = '0';
        setTimeout(function () {
            tipIndex = (tipIndex + 1) % TIPS.length;
            tipEl.textContent = TIPS[tipIndex];
            tipEl.style.opacity = '1';
        }, 400);
    }
    // Random starting tip, then rotate.
    tipIndex = Math.floor(Math.random() * TIPS.length);
    if (tipEl) tipEl.textContent = TIPS[tipIndex];
    setInterval(showNextTip, 5000);

    // ---- Progress bar ----
    var barEl = document.getElementById('bar');
    var pctEl = document.getElementById('pct');
    var statusEl = document.getElementById('status');

    var shown = 0;     // what the bar currently displays (0..100)
    var target = 0;    // where we want it to be (0..100)

    function render() {
        // Ease the displayed value toward the target so it always feels alive.
        shown += (target - shown) * 0.12;
        if (target - shown < 0.3) shown = target;
        var v = Math.max(0, Math.min(100, shown));
        if (barEl) barEl.style.width = v.toFixed(1) + '%';
        if (pctEl) pctEl.textContent = Math.round(v) + '%';
        requestAnimationFrame(render);
    }
    requestAnimationFrame(render);

    function setTarget(pct) {
        if (typeof pct !== 'number' || isNaN(pct)) return;
        target = Math.max(target, Math.min(100, pct)); // never go backwards
    }

    function setStatus(text) {
        if (statusEl && text) statusEl.textContent = String(text);
    }

    // Trim/clean a raw FiveM log line into something presentable.
    function prettyLog(line) {
        if (!line) return null;
        var s = String(line).replace(/\s+/g, ' ').trim();
        s = s.replace(/^\[[^\]]*\]\s*/, ''); // strip a leading [tag]
        if (!s) return null;
        if (s.length > 70) s = s.slice(0, 67) + '…';
        return s;
    }

    // FiveM dispatches loading-screen events as window 'message' events.
    window.addEventListener('message', function (e) {
        var data = e.data || {};
        switch (data.eventName) {
            case 'loadProgress':
                // loadFraction is 0..1
                setTarget((data.loadFraction || 0) * 100);
                break;
            case 'startInitFunctionOrder':
                setStatus('Preparing systems…');
                break;
            case 'startInitFunction':
                setStatus('Initializing ' + (data.type || 'game') + '…');
                break;
            case 'initFunctionInvoking':
                if (typeof data.idx === 'number' && typeof data.count === 'number' && data.count > 0) {
                    setStatus('Loading ' + (data.type || 'data') + ' (' + (data.idx + 1) + '/' + data.count + ')…');
                }
                break;
            case 'startDataFileEntries':
                setStatus('Mounting data files…');
                break;
            case 'onDataFileEntry':
                // Keep status lively without spamming; show the file name occasionally.
                if (data.name && Math.random() < 0.15) setStatus('Mounting ' + prettyLog(data.name));
                break;
            case 'performMapLoadFunction':
                setStatus('Building the world…');
                break;
            case 'onLogLine': {
                var pretty = prettyLog(data.message);
                if (pretty) setStatus(pretty);
                break;
            }
            default:
                break;
        }
    });

    // Gentle "creep" so the bar drifts forward even before/while events are sparse,
    // capped below 100 until the engine actually reports completion.
    setInterval(function () {
        if (target < 90) setTarget(target + 1.5);
    }, 700);

    // ---- Background music + mute/unmute ----
    var bgm = document.getElementById('bgm');
    var musicBtn = document.getElementById('music-toggle');
    if (bgm && musicBtn) {
        var iconEl = musicBtn.querySelector('.music-toggle__icon');
        var labelEl = musicBtn.querySelector('.music-toggle__label');
        bgm.volume = 0.45;

        // Remember the player's choice across loads.
        var muted = false;
        try { muted = localStorage.getItem('cnr_bgm_muted') === '1'; } catch (e) {}

        function applyMuted() {
            bgm.muted = muted;
            musicBtn.classList.toggle('muted', muted);
            if (iconEl) iconEl.textContent = muted ? '🔇' : '🔊';
            if (labelEl) labelEl.textContent = muted ? 'Music Off' : 'Music On';
            try { localStorage.setItem('cnr_bgm_muted', muted ? '1' : '0'); } catch (e) {}
        }

        function tryPlay() {
            var p = bgm.play();
            if (p && typeof p.catch === 'function') { p.catch(function () {}); }
        }

        applyMuted();
        tryPlay();

        // Some CEF builds block autoplay until a user gesture — start on the first input.
        function kickstart() {
            tryPlay();
            window.removeEventListener('click', kickstart);
            window.removeEventListener('keydown', kickstart);
            window.removeEventListener('mousemove', kickstart);
        }
        window.addEventListener('click', kickstart);
        window.addEventListener('keydown', kickstart);
        window.addEventListener('mousemove', kickstart);

        musicBtn.addEventListener('click', function (e) {
            e.preventDefault();
            muted = !muted;
            applyMuted();
            if (!muted) tryPlay();
        });
    }
})();
