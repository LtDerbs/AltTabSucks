const profileInput = document.getElementById('profile-name');
const tokenInput   = document.getElementById('auth-token');
const status       = document.getElementById('status');

chrome.storage.local.get(['profileName', 'authToken'], ({ profileName, authToken }) => {
  profileInput.value = profileName ?? 'Default';
  tokenInput.value   = authToken  ?? '';
});

document.getElementById('save').addEventListener('click', () => {
  const name  = profileInput.value.trim();
  const token = tokenInput.value.trim();
  if (!name) return;
  chrome.storage.local.set({ profileName: name, authToken: token }, () => {
    status.textContent = 'Saved.';
    setTimeout(() => status.textContent = '', 2000);
  });
});
