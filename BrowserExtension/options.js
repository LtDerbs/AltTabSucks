const input  = document.getElementById('profile-name');
const status = document.getElementById('status');

chrome.storage.local.get('profileName', ({ profileName }) => {
  input.value = profileName ?? 'Default';
});

document.getElementById('save').addEventListener('click', () => {
  const name = input.value.trim();
  if (!name) return;
  chrome.storage.local.set({ profileName: name }, () => {
    status.textContent = 'Saved.';
    setTimeout(() => status.textContent = '', 2000);
  });
});
