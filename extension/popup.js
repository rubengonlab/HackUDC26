const pantallaLogin = document.getElementById('pantallaLogin');
const pantallaApp = document.getElementById('pantallaApp');
const estadoDiv = document.getElementById('estado');
const textoNota = document.getElementById('textoNota');

// Elementos de la interfaz
const inputWrapper = document.getElementById('inputWrapper');
const recordingUI = document.getElementById('recordingUI');
const tiempoGrabacion = document.getElementById('tiempoGrabacion');
const btnGrabar = document.getElementById('btnGrabar');
const btnGuardar = document.getElementById('btnGuardar');
const btnCancelar = document.getElementById('btnCancelar');
const toastContainer = document.getElementById('toastContainer');

const colors = { primary: "#FFFFFF", accent: "#FF5856", sec: "#9BA4D5", success: "#10B981" };

// Lógica de auto-ajuste de la caja de texto
textoNota.addEventListener('input', function() {
  this.style.height = 'auto';
  this.style.height = (this.scrollHeight) + 'px';
  if (this.scrollHeight > 280) this.style.overflowY = 'scroll';
  else this.style.overflowY = 'hidden';

  if (this.value.trim().length > 0) {
    btnGrabar.style.display = 'none';
    btnGuardar.style.display = 'flex';
  } else {
    btnGrabar.style.display = 'flex';
    btnGuardar.style.display = 'none';
  }
});

// Chequeo de portapapeles (clic derecho)
chrome.storage.local.get(['notaPendiente'], function(result) {
  if (result.notaPendiente) {
    textoNota.value = result.notaPendiente;
    textoNota.dispatchEvent(new Event('input')); 
    chrome.action.setBadgeText({ text: "" });
    chrome.storage.local.remove('notaPendiente');
  }
});

// Sistema de Login básico
chrome.storage.local.get(['isLoggedIn'], function(result) {
  // Primero ocultamos todo
  pantallaApp.style.display = 'none';
  pantallaLogin.style.display = 'none';

  if (result.isLoggedIn) { 
    pantallaApp.style.display = 'flex'; 
  } else { 
    pantallaLogin.style.display = 'flex'; 
  }
});

// Y en el evento btnEntrar:
document.getElementById('btnEntrar').addEventListener('click', () => {
  const user = document.getElementById('fakeUser').value;
  if (user) {
    chrome.storage.local.set({ isLoggedIn: true, username: user }, () => {
      pantallaLogin.style.display = 'none';
      pantallaApp.style.display = 'flex';
    });
  }
});

document.getElementById('btnSalir').addEventListener('click', () => {
  chrome.storage.local.remove(['isLoggedIn', 'username'], () => {
    pantallaApp.style.display = 'none';
    pantallaLogin.style.display = 'flex';
    document.getElementById('fakeUser').value = '';
    document.getElementById('fakePass').value = '';
    estadoDiv.innerText = '';
    textoNota.value = ''; 
    textoNota.dispatchEvent(new Event('input')); 
  });
});

// --- SISTEMA DE NOTIFICACIONES ELEGANTES (TOAST) ---
function mostrarNotificacion(titulo, subtitulo, esError = false) {
  const toast = document.createElement('div');
  toast.className = `toast ${esError ? 'error' : ''}`;
  
  // Icono SVG según el estado
  const icono = esError 
    ? `<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" style="margin-right: 8px; flex-shrink: 0; color: var(--accent);"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"></path><line x1="12" y1="9" x2="12" y2="13"></line><line x1="12" y1="17" x2="12.01" y2="17"></line></svg>`
    : `<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" style="margin-right: 8px; flex-shrink: 0; color: var(--success);"><polyline points="20 6 9 17 4 12"></polyline></svg>`;

  toast.innerHTML = `
    <div style="display: flex; align-items: center;">
      ${icono}
      <div class="toast-title" style="margin: 0;">${titulo}</div>
    </div>
    <div class="toast-subtitle" style="margin-top: 4px; padding-left: 26px;">"${subtitulo}"</div>
  `;
  
  toastContainer.appendChild(toast);
  
  setTimeout(() => {
    if(toastContainer.contains(toast)) toastContainer.removeChild(toast);
  }, 3000);
}

// ==========================================
// --- GUARDAR TEXTO ---
// ==========================================

btnGuardar.addEventListener('click', async () => {
  if (mediaRecorder && mediaRecorder.state === 'recording') {
    grabacionCancelada = false;
    mediaRecorder.stop();
    return;
  }

  const texto = textoNota.value;
  if (!texto.trim()) return;
  
  // Guardamos un extracto cortito para la notificación visual
  const textoCorto = texto.length > 40 ? texto.substring(0, 40) + "..." : texto;

  // Limpiar caja de texto inmediatamente para que el usuario sienta que ha terminado
  textoNota.value = '';
  textoNota.style.height = 'auto';
  textoNota.dispatchEvent(new Event('input'));

  estadoDiv.innerText = "Sincronizando con JunkDrawer...";

  chrome.storage.local.get(['username'], async function(result) {
    chrome.tabs.query({active: true, currentWindow: true}, async (tabs) => {
      try {
        const res = await fetch("http://localhost:8080/junkdrawer/text", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ content: texto })
        });

        if (res.ok) {
          estadoDiv.innerText = "";
          // ¡Aquí está la magia de la notificación corporativa!
          mostrarNotificacion("Guardado en tu cuenta de notas", textoCorto);
        } else throw new Error("Error del servidor");
      } catch (err) {
        estadoDiv.innerText = "";
        mostrarNotificacion("Error al guardar nota", "Error en el servidor", true);
      }
    });
  });
});

// ==========================================
// --- LÓGICA DE GRABACIÓN CORPORATIVA ---
// ==========================================

let mediaRecorder;
let audioChunks = [];
let grabacionCancelada = false; 
let cronometroInterval;
let segundosGrabacion = 0;

function resetUI() {
  clearInterval(cronometroInterval);
  recordingUI.style.display = 'none';
  inputWrapper.style.display = 'flex';
  btnGuardar.classList.remove('is-recording'); 
  textoNota.dispatchEvent(new Event('input')); 
  estadoDiv.innerText = '';
}

function actualizarCronometro() {
  segundosGrabacion++;
  const minutos = String(Math.floor(segundosGrabacion / 60)).padStart(2, '0');
  const segundos = String(segundosGrabacion % 60).padStart(2, '0');
  tiempoGrabacion.innerText = `${minutos}:${segundos}`;
}

btnGrabar.addEventListener('click', async () => {
  try {
    const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
    mediaRecorder = new MediaRecorder(stream);
    grabacionCancelada = false; 
    
    mediaRecorder.ondataavailable = event => { if (event.data.size > 0) audioChunks.push(event.data); };

    mediaRecorder.onstop = () => {
      stream.getTracks().forEach(track => track.stop()); 
      if (!grabacionCancelada) {
        const audioBlob = new Blob(audioChunks, { type: 'audio/webm' });
        enviarAudioAlBackend(audioBlob);
      } else {
        estadoDiv.innerText = "Nota de voz descartada";
        setTimeout(() => { estadoDiv.innerText = ''; }, 2000);
      }
      audioChunks = []; 
      resetUI();        
    };

    inputWrapper.style.display = 'none';
    recordingUI.style.display = 'flex';
    
    btnGrabar.style.display = 'none';
    btnGuardar.style.display = 'flex'; 
    btnGuardar.classList.add('is-recording');
    
    segundosGrabacion = 0;
    tiempoGrabacion.innerText = "00:00";
    cronometroInterval = setInterval(actualizarCronometro, 1000);

    mediaRecorder.start();

  } catch (err) {
    if (err.name === 'NotAllowedError' || err.name === 'PermissionDeniedError' || err.message.includes('Permission')) {
      chrome.tabs.create({ url: chrome.runtime.getURL("permisos.html") });
    } else {
      estadoDiv.innerText = "Error de hardware de audio";
    }
  }
});

btnCancelar.addEventListener('click', () => {
  if (mediaRecorder && mediaRecorder.state === 'recording') { 
    grabacionCancelada = true; 
    mediaRecorder.stop(); 
  }
});

async function enviarAudioAlBackend(audioBlob) {
  estadoDiv.innerText = "Sincronizando audio...";

  const formData = new FormData();
  formData.append('file', audioBlob, 'nota_voz.webm');

  try {
    const response = await fetch("http://localhost:8080/junkdrawer/audio", { method: "POST", body: formData });
    if (response.ok) {
      estadoDiv.innerText = "";
      mostrarNotificacion("Audio guardado en tu cuenta", "🎙️ Nota de voz de Kelea");
    } else throw new Error();
  } catch (err) {
    estadoDiv.innerText = "";
    mostrarNotificacion("Error al subir audio", "Servidor no disponible", true);
  }
}