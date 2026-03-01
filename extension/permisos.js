/*
 * SPDX-FileCopyrightText: Copyright (c) 2026 Rubén González Laballós
 * SPDX-License-Identifier: MIT
 */
document.getElementById('btnPermitir').addEventListener('click', async () => {
  const mensajeDiv = document.getElementById('mensaje');
  
  try {
    // Aquí es donde Chrome saca el mensajito de arriba a la izquierda
    const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
    
    // Si llegamos aquí, ¡el usuario ha dicho que sí!
    // Apagamos el micro inmediatamente, solo queríamos el permiso
    stream.getTracks().forEach(track => track.stop());
    
    mensajeDiv.innerText = "¡Permiso concedido! Ya puedes cerrar esta pestaña y grabar desde el icono de la extensión.";
    mensajeDiv.style.color = "#4CAF50";
    document.getElementById('btnPermitir').style.display = 'none';

  } catch (err) {
    mensajeDiv.innerText = "Permiso denegado. Por favor, haz clic en el icono del micrófono en la barra de direcciones ☝️ y permítelo.";
    mensajeDiv.style.color = "#E63946";
  }
});