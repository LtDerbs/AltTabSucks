const profileSelect = document.getElementById('profile-select');
const tokenInput    = document.getElementById('auth-token');
const profileHint   = document.getElementById('profile-hint');
const status        = document.getElementById('status');

function setHint(msg, isError = false) {
  profileHint.textContent = msg;
  profileHint.style.color = isError ? '#c00' : '#888';
}

function populateSelect(profiles, savedName) {
  profileSelect.innerHTML = '';
  if (profiles.length === 0) {
    const opt = document.createElement('option');
    opt.value = savedName ?? '';
    opt.textContent = savedName ? savedName : '(no profiles — start AltTabSucks and click ↺)';
    profileSelect.appendChild(opt);
    return;
  }

  let matched = false;
  for (const p of profiles) {
    const opt = document.createElement('option');
    opt.value = p;
    opt.textContent = p;
    if (p === savedName) { opt.selected = true; matched = true; }
    profileSelect.appendChild(opt);
  }

  // Saved profile no longer in list — add it as a distinct option so it isn't silently lost
  if (savedName && !matched) {
    const opt = document.createElement('option');
    opt.value = savedName;
    opt.textContent = savedName + ' (saved, not in list)';
    opt.selected = true;
    profileSelect.insertBefore(opt, profileSelect.firstChild);
  }

  // Auto-select first if nothing saved yet
  if (!savedName) profileSelect.selectedIndex = 0;
}

async function fetchProfiles(token, savedName) {
  if (!token) {
    populateSelect([], savedName);
    setHint('Enter your auth token, then click ↺ to load profiles.');
    return;
  }
  setHint('Fetching…');
  try {
    const res = await fetch('http://localhost:9876/profiles', {
      headers: { 'X-AltTabSucks-Token': token }
    });
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    const profiles = await res.json();
    populateSelect(profiles, savedName);
    setHint(profiles.length > 0
      ? `${profiles.length} profile${profiles.length > 1 ? 's' : ''} loaded.`
      : 'No profiles returned — AltTabSucks may still be starting up.');
  } catch {
    populateSelect([], savedName);
    setHint('Server not reachable — start AltTabSucks and click ↺.', true);
  }
}

chrome.storage.local.get(['profileName', 'authToken'], ({ profileName, authToken }) => {
  tokenInput.value = authToken ?? '';
  fetchProfiles(authToken, profileName);
});

document.getElementById('fetch-profiles').addEventListener('click', () => {
  const token = tokenInput.value.trim();
  const saved = profileSelect.value || undefined;
  fetchProfiles(token, saved);
});

document.getElementById('save').addEventListener('click', () => {
  const name  = profileSelect.value.trim();
  const token = tokenInput.value.trim();
  if (!name) return;
  chrome.storage.local.get(['profileName'], ({ profileName: oldName }) => {
    if (oldName && oldName !== name) {
      fetch(`http://localhost:9876/tabs?profile=${encodeURIComponent(oldName)}`, {
        method: 'DELETE',
        headers: { 'X-AltTabSucks-Token': token }
      }).catch(() => {});
    }
    chrome.storage.local.set({ profileName: name, authToken: token }, () => {
      status.textContent = 'Saved.';
      setTimeout(() => status.textContent = '', 2000);
    });
  });
});
