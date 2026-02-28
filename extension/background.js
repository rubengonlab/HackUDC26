chrome.runtime.onInstalled.addListener(() => {
  chrome.contextMenus.create({
    id: "enviar-cerebro",
    title: "Copiar al portapapeles de Kelea",
    contexts: ["selection"]
  });
});

chrome.contextMenus.onClicked.addListener((info, tab) => {
  if (info.menuItemId === "enviar-cerebro") {
    chrome.storage.local.set({ notaPendiente: info.selectionText }, () => {
      chrome.action.setBadgeText({ text: "1" });
      chrome.action.setBadgeBackgroundColor({ color: "#FF5856" }); // Rojo Coral Kelea
    });
  }
});