const SERVER = 'http://localhost:9876/tabs';

async function render() {
  const [tabs, windows] = await Promise.all([
    chrome.tabs.query({}),
    chrome.windows.getAll()
  ]);

  const winIndex = Object.fromEntries(windows.map((w, i) => [w.id, i + 1]));
  const tbody = document.getElementById('tab-list');

  for (const tab of tabs) {
    const tr = document.createElement('tr');
    const tdWin   = document.createElement('td');
    const tdId    = document.createElement('td');
    const tdTitle = document.createElement('td');
    tdWin.className   = 'win-id';
    tdWin.textContent   = winIndex[tab.windowId] ?? tab.windowId;
    tdId.textContent    = tab.id;
    tdTitle.textContent = tab.title ?? '';
    tr.append(tdWin, tdId, tdTitle);
    tbody.appendChild(tr);
  }

  // show server status
  const status = document.getElementById('status');
  try {
    const { authToken = '' } = await chrome.storage.local.get('authToken');
    const r = await fetch(SERVER, { headers: { 'X-AltTabSucks-Token': authToken } });
    status.textContent = r.ok ? 'server: connected' : `server: error (${r.status})`;
    status.className = r.ok ? 'ok' : 'err';
  } catch {
    status.textContent = 'server: not running';
    status.className = 'err';
  }
}

render();
