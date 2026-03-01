/*
 * SPDX-FileCopyrightText: Copyright (c) 2026 Rubén González Laballós
 * SPDX-License-Identifier: MIT
 */
chrome.runtime.onInstalled.addListener(() => {
  chrome.contextMenus.create({
    id: "enviar-cerebro",
    title: "Copiar al portapapeles de Kelea",
    contexts: ["selection"]
  });
});

chrome.contextMenus.onClicked.addListener(async (info, tab) => {
  if (info.menuItemId === "enviar-cerebro") {
    
    await chrome.storage.local.set({ notaPendiente: info.selectionText });
    chrome.action.setBadgeText({ text: "1" });
    chrome.action.setBadgeBackgroundColor({ color: "#FF5856" }); // Rojo Coral Kelea

    if (chrome.action && chrome.action.openPopup) {
      chrome.action.openPopup().catch((err) => {
        console.warn("No se pudo abrir el popup nativo, usando alternativa...", err);
        abrirVentanaFallback();
      });
    } else {
      abrirVentanaFallback();
    }
  }
});

function abrirVentanaFallback() {
  chrome.windows.create({
    url: "popup.html",
    type: "popup",
    width: 360,
    height: 600
  });
}