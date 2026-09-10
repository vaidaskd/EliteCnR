(function () {
  const RES = (typeof GetParentResourceName === 'function') ? GetParentResourceName() : 'cnr_chat';

  const chat       = document.getElementById('chat');
  const messages   = document.getElementById('messages');
  const inputbar   = document.getElementById('inputbar');
  const input      = document.getElementById('input');
  const colorPanel = document.getElementById('colorpanel');
  const emojiPanel = document.getElementById('emojipanel');
  const btnColor   = document.getElementById('btn-color');
  const btnEmoji   = document.getElementById('btn-emoji');
  const btnGif     = document.getElementById('btn-gif');
  const suggestionsEl = document.getElementById('suggestions');

  let allSuggestions = [];   // [{ name, help }]
  let suggMatches = [];      // currently shown matches
  let suggIndex = 0;         // highlighted match

  let selectedColor = null;          // player-chosen text colour (#rrggbb) or null
  const MAX_MESSAGES = 60;
  const FADE_MS = 12000;

  // ── channels ────────────────────────────────────────────────────────────
  const channelsEl = document.getElementById('channels');
  const chLabel     = document.getElementById('ch-label');
  let activeChannel = 'global';            // which channel's messages are shown / sent to
  let isCop = false;
  const CH_NAMES = { global: 'GLOBAL', local: 'LOCAL', police: 'POLICE RADIO' };
  const buffers = { global: [], local: [], police: [] };   // per-channel { html } rows

  // ── helpers ───────────────────────────────────────────────────────────
  function esc(s) {
    return String(s == null ? '' : s)
      .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;').replace(/'/g, '&#39;');
  }

  // GTA ^0-^9 colour codes → spans
  const CARET = {
    '0': '#ffffff', '1': '#ff5a5a', '2': '#36d17a', '3': '#ffd24a', '4': '#4ea1ff',
    '5': '#5fd0e0', '6': '#c07af0', '7': '#ffffff', '8': '#ff9f2e', '9': '#9aa3b2'
  };
  function parseCaret(text) {
    // Supports ^0-^9 palette codes AND ^#rrggbb hex codes (^7 resets to white).
    const parts = String(text == null ? '' : text).split(/(\^#[0-9a-fA-F]{6}|\^[0-9])/g);
    let html = '';
    let color = null;
    for (const part of parts) {
      if (/^\^#[0-9a-fA-F]{6}$/.test(part)) {
        color = part.slice(1);              // '#rrggbb'
      } else if (/^\^[0-9]$/.test(part)) {
        color = CARET[part[1]];
      } else if (part.length) {
        html += color
          ? `<span style="color:${color}">${esc(part)}</span>`
          : esc(part);
      }
    }
    return html;
  }

  function rgbToCss(c) {
    if (Array.isArray(c) && c.length >= 3) return `rgb(${c[0]|0},${c[1]|0},${c[2]|0})`;
    if (typeof c === 'string' && c) return c;
    return null;
  }

  function makeRow() {
    const div = document.createElement('div');
    div.className = 'msg';
    return div;
  }

  function pushRow(div) {
    messages.appendChild(div);
    while (messages.childElementCount > MAX_MESSAGES) messages.removeChild(messages.firstChild);
    messages.scrollTop = messages.scrollHeight;
  }

  // Join/leave announcements belong only in the cnr game feed (role-coloured). Drop any
  // chat-rendered "<name> joined/left the server" duplicate, whatever resource emits it.
  // Player chat (message.cnr) is never filtered.
  function isJoinLeaveAnnounce(message) {
    if (typeof message === 'string') message = { args: [message] };
    if (typeof message !== 'object' || message === null || message.cnr) return false;
    const parts = [];
    const collect = (v) => {
      if (typeof v === 'string') parts.push(v);
      else if (Array.isArray(v)) v.forEach(x => { if (typeof x === 'string') parts.push(x); });
    };
    collect(message.args); collect(message.message); collect(message.text); collect(message.name);
    const s = parts.join(' ').toLowerCase();
    return s.includes('joined the server') || s.includes('left the server')
        || s.includes('joined the game') || s.includes('left the game')
        || s.includes(' joined.') || s.includes(' left (')
        || s.includes('connected') || s.includes('disconnected');
  }

  function addMessage(message) {
    if (typeof message === 'string') message = { args: [message] };
    if (typeof message !== 'object' || message === null) return;
    if (isJoinLeaveAnnounce(message)) return;
    const div = makeRow();
    let html = '';

    if (message.cnr) {
      // CnR player message: coloured name (id) + text
      const nc = message.nameColor || '#ffffff';
      const tc = message.textColor || '#ffffff';
      html += `<span class="name" style="color:${esc(nc)}">${esc(message.name)}</span>`;
      html += `<span class="body">: </span>`;
      html += `<span class="body" style="color:${esc(tc)}">${esc(message.text)}</span>`;
      if (message.gif || message.image) html += `<img class="gif" src="${esc(message.gif || message.image)}">`;
    } else if (Array.isArray(message.args)) {
      // Cfx-style { args, color, multiline } message (system / commands / welcome)
      const args = message.args;
      const color = rgbToCss(message.color);
      if (args.length >= 2) {
        html += `<span class="name"${color ? ` style="color:${color}"` : ''}>${esc(args[0])}</span> `;
        html += `<span class="body">${parseCaret(args.slice(1).join(' '))}</span>`;
      } else if (args.length === 1) {
        html += `<span class="body"${color ? ` style="color:${color}"` : ''}>${parseCaret(args[0])}</span>`;
      }
      if (message.image) html += `<img class="gif" src="${esc(message.image)}">`;
    } else if (typeof message.message === 'string') {
      // gfx-chat style { type, name, message, color } payload (CnR.Chat.Say/System/Notice)
      const color = rgbToCss(message.color) || '#ffffff';
      if (message.name) {
        html += `<span class="name" style="color:${esc(color)}">${esc(message.name)}</span><span class="body">: </span>`;
      }
      html += `<span class="body">${parseCaret(message.message)}</span>`;
      if (message.image || message.gif) html += `<img class="gif" src="${esc(message.image || message.gif)}">`;
    } else {
      return;
    }

    // Route to the message's channel buffer; only render now if it's the active view.
    const ch = channelOf(message);
    buffers[ch].push(html);
    while (buffers[ch].length > MAX_MESSAGES) buffers[ch].shift();
    if (ch === activeChannel) {
      div.innerHTML = html;
      pushRow(div);
    }
  }

  function channelOf(message) {
    if (message && typeof message === 'object' && message.channel) {
      const c = String(message.channel);
      if (c === 'local' || c === 'police') return c;
    }
    return 'global';   // welcome / system / command output all live in GLOBAL
  }

  // Re-render the message list for the active channel from its buffer.
  function renderChannel() {
    messages.innerHTML = '';
    const rows = buffers[activeChannel] || [];
    for (const html of rows) {
      const div = makeRow();
      div.innerHTML = html;
      messages.appendChild(div);
    }
    messages.scrollTop = messages.scrollHeight;
  }

  function setChannel(ch) {
    if (ch === 'police' && !isCop) return;
    if (!buffers[ch]) return;
    activeChannel = ch;
    if (chLabel) chLabel.textContent = CH_NAMES[ch] || 'GLOBAL';
    channelsEl.querySelectorAll('.ch-tab').forEach(function (t) {
      t.classList.toggle('active', t.getAttribute('data-ch') === ch);
    });
    renderChannel();
  }

  channelsEl.addEventListener('mousedown', function (e) {
    const tab = e.target.closest('.ch-tab');
    if (!tab) return;
    e.preventDefault();
    setChannel(tab.getAttribute('data-ch'));
    input.focus();
  });

  // ── command suggestions ("/" autocomplete) ──────────────────────────────
  function hideSuggestions() {
    suggMatches = [];
    suggIndex = 0;
    suggestionsEl.classList.add('hidden');
    suggestionsEl.innerHTML = '';
  }

  function renderSuggestions() {
    const val = input.value;
    if (!val || val[0] !== '/') { hideSuggestions(); return; }
    const token = val.split(' ')[0].toLowerCase();   // e.g. "/new"
    suggMatches = allSuggestions
      .filter(s => s.name.toLowerCase().indexOf(token) === 0)
      .slice(0, 6);
    if (suggMatches.length === 0) { hideSuggestions(); return; }
    if (suggIndex >= suggMatches.length) suggIndex = 0;
    suggestionsEl.innerHTML = suggMatches.map((s, i) =>
      `<div class="sugg${i === suggIndex ? ' active' : ''}" data-i="${i}">` +
        `<span class="sugg-name">${esc(s.name)}</span>` +
        (s.help ? `<span class="sugg-help">${esc(s.help)}</span>` : '') +
      `</div>`).join('');
    suggestionsEl.classList.remove('hidden');
  }

  function completeSuggestion() {
    if (!suggMatches.length) return false;
    const s = suggMatches[suggIndex] || suggMatches[0];
    input.value = s.name + ' ';
    input.focus();
    renderSuggestions();
    return true;
  }

  suggestionsEl.addEventListener('mousedown', (e) => {
    // mousedown (not click) so the input doesn't blur first
    const row = e.target.closest('.sugg');
    if (!row) return;
    e.preventDefault();
    suggIndex = parseInt(row.getAttribute('data-i'), 10) || 0;
    completeSuggestion();
  });

  // ── input open/close ──────────────────────────────────────────────────
  function openInput(cop) {
    isCop = !!cop;
    chat.classList.add('active');
    channelsEl.classList.remove('hidden');
    const policeTab = channelsEl.querySelector('.ch-police');
    if (policeTab) policeTab.classList.toggle('hidden', !isCop);
    if (activeChannel === 'police' && !isCop) setChannel('global');
    else setChannel(activeChannel);   // refresh the view + active tab highlight
    inputbar.classList.remove('hidden');
    input.value = '';
    hideSuggestions();
    // strip any stray key from the open keybind
    setTimeout(() => { input.value = ''; input.focus(); }, 0);
    messages.scrollTop = messages.scrollHeight;
  }

  function closeInput(send) {
    let payload = null;
    if (send) {
      const text = input.value.trim();
      if (text.length) payload = { text, color: selectedColor, channel: activeChannel };
    }
    input.value = '';
    hideSuggestions();
    inputbar.classList.add('hidden');
    channelsEl.classList.add('hidden');
    colorPanel.classList.add('hidden');
    emojiPanel.classList.add('hidden');
    btnColor.classList.remove('active');
    btnEmoji.classList.remove('active');
    chat.classList.remove('active');
    input.blur();

    if (payload) post('cnr_chat:send', payload);
    else post('cnr_chat:close', {});
  }

  function post(cb, data) {
    fetch(`https://${RES}/${cb}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify(data || {})
    }).catch(() => {});
  }

  // ── events from client.lua ──────────────────────────────────────────────
  window.addEventListener('message', (e) => {
    const d = e.data || {};
    if (d.type === 'addMessage') addMessage(d.message);
    else if (d.type === 'openInput') openInput(d.isCop);
    else if (d.type === 'clear') { buffers.global = []; buffers.local = []; buffers.police = []; messages.innerHTML = ''; }
    else if (d.type === 'suggestions') { allSuggestions = Array.isArray(d.list) ? d.list : []; renderSuggestions(); }
  });

  input.addEventListener('input', () => { suggIndex = 0; renderSuggestions(); });

  input.addEventListener('keydown', (e) => {
    if (e.key === 'Enter') { e.preventDefault(); closeInput(true); }
    else if (e.key === 'Escape') { e.preventDefault(); closeInput(false); }
    else if (e.key === 'Tab') {
      // Tab completes the highlighted suggestion instead of leaving the field.
      if (suggMatches.length) { e.preventDefault(); completeSuggestion(); }
    } else if (e.key === 'ArrowDown') {
      if (suggMatches.length) { e.preventDefault(); suggIndex = (suggIndex + 1) % suggMatches.length; renderSuggestions(); }
    } else if (e.key === 'ArrowUp') {
      if (suggMatches.length) { e.preventDefault(); suggIndex = (suggIndex - 1 + suggMatches.length) % suggMatches.length; renderSuggestions(); }
    }
  });

  // Escape always closes, even if focus moved to a tool button after a click.
  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' && chat.classList.contains('active')) {
      e.preventDefault();
      closeInput(false);
    }
  });

  // ── colour picker ───────────────────────────────────────────────────────
  const SWATCHES = ['#ffffff', '#ff5a5a', '#ff9f2e', '#ffd24a', '#36d17a',
                    '#4ea1ff', '#5fd0e0', '#c07af0', '#ff7ac0', '#9aa3b2'];
  SWATCHES.forEach((hex, i) => {
    const s = document.createElement('div');
    s.className = 'swatch' + (i === 0 ? ' sel' : '');
    s.style.background = hex;
    s.addEventListener('click', () => {
      selectedColor = (hex === '#ffffff') ? null : hex;
      colorPanel.querySelectorAll('.swatch').forEach(x => x.classList.remove('sel'));
      s.classList.add('sel');
      input.focus();
    });
    colorPanel.appendChild(s);
  });
  btnColor.addEventListener('click', (e) => {
    e.preventDefault();
    colorPanel.classList.toggle('hidden');
    emojiPanel.classList.add('hidden');
    btnColor.classList.toggle('active', !colorPanel.classList.contains('hidden'));
    btnEmoji.classList.remove('active');
    input.focus();
  });

  // ── emoji picker ──────────────────────────────────────────────────────────
  const EMOJIS = ['😀','😂','😅','😍','😎','😭','😡','🤔','🤣','😉','😘','🙃',
                  '👍','👎','👌','🙏','💪','👀','🔥','💯','💀','👻','🤡','💩',
                  '❤️','💔','⭐','💰','💵','🚗','🚓','🔫','🚨','🏃','🎉','😈'];
  EMOJIS.forEach(em => {
    const span = document.createElement('span');
    span.className = 'emoji';
    span.textContent = em;
    span.addEventListener('click', () => {
      input.value += em;
      input.focus();
    });
    emojiPanel.appendChild(span);
  });
  btnEmoji.addEventListener('click', (e) => {
    e.preventDefault();
    emojiPanel.classList.toggle('hidden');
    colorPanel.classList.add('hidden');
    btnEmoji.classList.toggle('active', !emojiPanel.classList.contains('hidden'));
    btnColor.classList.remove('active');
    input.focus();
  });

  // GIF — disabled until an API key is configured.
  btnGif.addEventListener('click', (e) => {
    e.preventDefault();
    input.focus();
  });
})();