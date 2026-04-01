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
    tr.innerHTML = `
      <td class="win-id">${winIndex[tab.windowId] ?? tab.windowId}</td>
      <td>${tab.id}</td>
      <td>${tab.title ?? ''}</td>
    `;
    tbody.appendChild(tr);
  }

  // show server status
  const status = document.getElementById('status');
  try {
    const r = await fetch(SERVER);
    status.textContent = r.ok ? 'server: connected' : 'server: error';
    status.className = r.ok ? 'ok' : 'err';
  } catch {
    status.textContent = 'server: not running';
    status.className = 'err';
  }
}

render();
