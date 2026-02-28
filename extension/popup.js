const pantallaLogin = document.getElementById('pantallaLogin');
const pantallaApp = document.getElementById('pantallaApp');
const estadoDiv = document.getElementById('estado');
const textoNota = document.getElementById('textoNota');

// --- COLORES THEME ---
const colors = { primary: "#1A1F4D", accent: "#FF5856", sec: "#6B7280", success: "#10B981" };

chrome.storage.local.get(['notaPendiente'], function(result) {
  if (result.notaPendiente) {
    textoNota.value = result.notaPendiente;
    chrome.action.setBadgeText({ text: "" });
    chrome.storage.local.remove('notaPendiente');
  }
});

chrome.storage.local.get(['isLoggedIn'], function(result) {
  if (result.isLoggedIn) { pantallaApp.style.display = 'block'; } 
  else { pantallaLogin.style.display = 'block'; }
});

document.getElementById('btnEntrar').addEventListener('click', () => {
  const user = document.getElementById('fakeUser').value;
  if (user) {
    chrome.storage.local.set({ isLoggedIn: true, username: user }, () => {
      pantallaLogin.style.display = 'none';
      pantallaApp.style.display = 'block';
    });
  }
});

document.getElementById('btnSalir').addEventListener('click', () => {
  chrome.storage.local.remove(['isLoggedIn', 'username'], () => {
    pantallaApp.style.display = 'none';
    pantallaLogin.style.display = 'block';
    document.getElementById('fakeUser').value = '';
    document.getElementById('fakePass').value = '';
    if(estadoDiv) estadoDiv.innerText = '';
    textoNota.value = ''; 
  });
});

document.getElementById('btnGuardar').addEventListener('click', async () => {
  const texto = textoNota.value;
  if (!texto.trim()) return;

  estadoDiv.innerText = "Enviando texto...";
  estadoDiv.style.color = colors.primary; // Antes white

  chrome.storage.local.get(['username'], async function(result) {
    chrome.tabs.query({active: true, currentWindow: true}, async (tabs) => {
      try {
        const res = await fetch("http://localhost:8080/junkdrawer/text", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ content: texto, url: tabs[0].url, type: "MANUAL_NOTE", author: result.username })
        });

        if (res.ok) {
          estadoDiv.innerText = " ¡Texto Guardado!";
          estadoDiv.style.color = colors.success;
          setTimeout(() => window.close(), 1000);
        } else throw new Error("Servidor no dio un OK.");
      } catch (err) {
        estadoDiv.innerText = " Backend en desarrollo. No enviado.";
        estadoDiv.style.color = colors.accent;
      }
    });
  });
});

let mediaRecorder;
let audioChunks = [];
let grabacionCancelada = false; 

const btnGrabar = document.getElementById('btnGrabar');
const btnDetener = document.getElementById('btnDetener');
const btnCancelar = document.getElementById('btnCancelar'); 

function resetUI() {
  btnGrabar.style.display = 'block';
  btnDetener.style.display = 'none';
  btnCancelar.style.display = 'none';
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
        estadoDiv.innerText = "Grabación descartada.";
        estadoDiv.style.color = colors.sec;
      }
      audioChunks = []; 
      resetUI();        
    };

    mediaRecorder.start();
    btnGrabar.style.display = 'none';
    btnCancelar.style.display = 'block';
    btnDetener.style.display = 'block';
    
    estadoDiv.innerText = "🔴 Grabando... (No cierres la ventana)";
    estadoDiv.style.color = colors.accent; 

  } catch (err) {
    if (err.name === 'NotAllowedError' || err.name === 'PermissionDeniedError' || err.message.includes('Permission')) {
      estadoDiv.innerText = "Abriendo permisos...";
      estadoDiv.style.color = colors.sec;
      chrome.tabs.create({ url: chrome.runtime.getURL("permisos.html") });
    } else {
      estadoDiv.innerText = "Error con el micrófono.";
      estadoDiv.style.color = colors.accent;
    }
  }
});

btnDetener.addEventListener('click', () => {
  if (mediaRecorder && mediaRecorder.state === 'recording') { grabacionCancelada = false; mediaRecorder.stop(); }
});

btnCancelar.addEventListener('click', () => {
  if (mediaRecorder && mediaRecorder.state === 'recording') { grabacionCancelada = true; mediaRecorder.stop(); }
});

async function enviarAudioAlBackend(audioBlob) {
  estadoDiv.innerText = "Subiendo audio...";
  estadoDiv.style.color = colors.primary;

  const formData = new FormData();
  formData.append('file', audioBlob, 'nota_voz.webm');

  try {
    const response = await fetch("http://localhost:8080/junkdrawer/audio", { method: "POST", body: formData });
    if (response.ok) {
      estadoDiv.innerText = "¡Audio guardado!";
      estadoDiv.style.color = colors.success;
      setTimeout(() => window.close(), 1500);
    } else throw new Error();
  } catch (err) {
    estadoDiv.innerText = "Backend en desarrollo. Audio no guardado.";
    estadoDiv.style.color = colors.accent;
  }
}