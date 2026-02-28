Documentación rápida para conectar y consumir el servicio de transcripción de audio a texto alojado en la instancia de Oracle mediante Docker.

## 1. Establecer el Túnel SSH

Para acceder a la API de forma segura desde el entorno de desarrollo local, abre una terminal y mantén en ejecución el siguiente comando:

```bash
ssh -L 8000:localhost:8000 -L 11434:localhost:11434 ubuntu@79.72.51.98 -i ~/Cosas_mias/oracle-cloud/ssh-key-2025-12-06.key
```

## 2. Ejemplo de petición
```bash
curl http://localhost:8000/v1/audio/transcriptions  \
   -H "Authorization: Bearer sk-dummy-key" \
   -H "Content-Type: multipart/form-data" \
   -F file="@audio3.ogg" \
   -F model="medium"
```

* Respuesta esperada:
```bash
{
  "text": "Este es el texto transcrito de tu archivo de audio."
}
```

