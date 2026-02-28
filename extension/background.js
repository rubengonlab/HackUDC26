// Crear la opción en el menú al instalar
chrome.runtime.onInstalled.addListener(() => {
  chrome.contextMenus.create({
    id: "sendSelection",
    title: "🧠 Enviar selección al Cerebro",
    contexts: ["selection"]
  });
});

// Escuchar cuando el usuario hace clic en esa opción
chrome.contextMenus.onClicked.addListener((info, tab) => {
  if (info.menuItemId === "sendSelection") {
    enviarBackend(info.selectionText);
  }
});

// Función para enviar al servidor de Oracle
async function enviarBackend(contenido) {
  const URL = "http://localhost:8080/api/items";
  try {
    await fetch(URL, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        content: contenido,
        type: "TEXT_SELECTION",
        source: "browser_extension"
      })
    });
  } catch (err) {
    console.error("Error enviando:", err);
  }
}