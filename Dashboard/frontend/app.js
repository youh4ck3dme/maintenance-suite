// API Base Configuration for Electron/Capacitor compatibility
const API_BASE = window.location.protocol === 'capacitor-electron:' 
    ? 'http://localhost:3456' 
    : '';

// Elements
const terminal = document.getElementById('terminal');
const lastCleanEl = document.getElementById('last-clean');
const storageUsedBar = document.getElementById('storage-used-bar');
const storageUsedVal = document.getElementById('storage-used-val');
const storageFreeVal = document.getElementById('storage-free-val');
const storageTotal = document.getElementById('storage-total');
const historyBody = document.getElementById('history-body');

function addLog(message, type = '') {
    const line = document.createElement('div');
    line.className = `terminal-line ${type}`;
    const now = new Date().toLocaleTimeString();
    line.textContent = `[${now}] ${message}`;
    terminal.appendChild(line);
    terminal.scrollTop = terminal.scrollHeight;
}

function clearLogs() {
    terminal.innerHTML = '<div class="terminal-line system">Console cleared...</div>';
}

async function fetchStats() {
    try {
        const res = await fetch(`${API_BASE}/api/stats`);
        const data = await res.json();
        
        if (data.total) {
            const usagePercent = Math.round((data.used / data.total) * 100);
            storageUsedBar.style.width = `${usagePercent}%`;
            storageUsedVal.textContent = data.used;
            storageFreeVal.textContent = data.free;
            storageTotal.textContent = `SSD: ${data.total} GB`;
        }
    } catch (err) {
        console.error('Stats fetch error:', err);
    }
}

async function fetchHistory() {
    try {
        const res = await fetch(`${API_BASE}/api/history`);
        const history = await res.json();
        
        if (history && history.length > 0) {
            const lastSession = history[0];
            historyBody.innerHTML = '';
            
            lastSession.breakdown.forEach(item => {
                const row = document.createElement('tr');
                row.innerHTML = `
                    <td>${item.category}</td>
                    <td class="original-value">${item.before.toFixed(1)} MB</td>
                    <td class="freed-value">-${item.freed.toFixed(1)} MB</td>
                    <td>
                        <div>${item.after.toFixed(1)} MB</div>
                        <div class="after-value">${item.after === 0 ? 'CLEAN' : 'RESIDUAL'}</div>
                    </td>
                `;
                historyBody.appendChild(row);
            });

            // Update last clean time from the history timestamp
            lastCleanEl.textContent = lastSession.timestamp;
        }
    } catch (err) {
        console.error('History fetch error:', err);
    }
}

async function runClean(type) {
    const actionName = type === 'diagnose' ? 'diagnostiku' : 'čistenie';
    addLog(`Iniciujem ${actionName}: ${type.toUpperCase()}...`, 'system');
    
    try {
        const response = await fetch(`${API_BASE}/api/run/${type}`, { method: 'POST' });
        const data = await response.json();
        
        if (data.status === 'started') {
            addLog(`Úloha úspešne spustená. Sledujte logy nižšie.`, 'system');
        } else {
            addLog(`Chyba: ${data.error || 'Neznáma chyba'}`, 'error');
        }
    } catch (err) {
        addLog(`Chyba pripojenia k serveru: ${err.message}`, 'error');
    }
}

// SSE Listener
function startLogStream() {
    const eventSource = new EventSource(`${API_BASE}/api/logs`);
    
    eventSource.onmessage = (event) => {
        const data = JSON.parse(event.data);
        addLog(data.message, data.type);
        
        // Refresh stats if cleanup finished
        if (data.message.includes('Maintenance Cleanup Finished')) {
            setTimeout(() => {
                fetchStats();
                fetchHistory();
            }, 1000);
        }
    };

    eventSource.onerror = () => {
        addLog('Strata spojenia s logovacím serverom. Reconnectujem...', 'system');
    };
}

// Initialization
window.onload = () => {
    fetchStats();
    fetchHistory();
    startLogStream();
    addLog('Maintenance Dashboard je pripravený.', 'system');

    // Attach button listener
    const btnFull = document.getElementById('btn-full-clean');
    if (btnFull) {
        btnFull.addEventListener('click', () => runClean('full'));
    }
};

// PWA Install Logic
let deferredPrompt;
const installContainer = document.getElementById('install-container');
const btnInstall = document.getElementById('btn-install');

window.addEventListener('beforeinstallprompt', (e) => {
    // Prevent Chrome 67 and earlier from automatically showing the prompt
    e.preventDefault();
    // Stash the event so it can be triggered later.
    deferredPrompt = e;
    // Update UI notify the user they can install the PWA
    if (installContainer) {
        installContainer.classList.remove('hidden');
    }
});

if (btnInstall) {
    btnInstall.addEventListener('click', async () => {
        if (!deferredPrompt) return;
        // Show the install prompt
        deferredPrompt.prompt();
        // Wait for the user to respond to the prompt
        const { outcome } = await deferredPrompt.userChoice;
        console.log(`User response to the install prompt: ${outcome}`);
        // We've used the prompt, and can't use it again, throw it away
        deferredPrompt = null;
        // Hide the install button
        installContainer.classList.add('hidden');
    });
}

window.addEventListener('appinstalled', () => {
    // Log install to analytics or hide UI
    console.log('PWA was installed');
    if (installContainer) {
        installContainer.classList.add('hidden');
    }
});

// PWA Service Worker Registration
if ('serviceWorker' in navigator) {
    navigator.serviceWorker.register('/sw.js').then(() => {
        console.log('Service Worker Registered');
    });
}
