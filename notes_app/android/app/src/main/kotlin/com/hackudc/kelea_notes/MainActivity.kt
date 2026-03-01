package com.hackudc.kelea_notes

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.media.MediaPlayer
import android.media.MediaRecorder
import android.net.Uri
import android.os.Build
import android.os.Parcelable
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.net.HttpURLConnection
import java.net.URL

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.junkdrawer/audio_recorder"
    private val SHARE_CHANNEL = "com.junkdrawer/share_handler"
    private val MIC_PERMISSION_CODE = 101

    private var recorder: MediaRecorder? = null
    private var player: MediaPlayer? = null
    private var currentPath: String? = null
    private var pendingResult: MethodChannel.Result? = null

    private var pendingSharedUrl: String? = null
    private var pendingSharedImageUri: String? = null
    private var shareMethodChannel: MethodChannel? = null
    private var audioChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        audioChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        audioChannel!!.setMethodCallHandler { call, result ->
            when (call.method) {
                "start"        -> startRecording(result)
                "stop"         -> stopRecording(result)
                "playUrl"      -> {
                    val url = call.argument<String>("url")
                    if (url == null) { result.error("INVALID_URL", "URL nula", null); return@setMethodCallHandler }
                    playUrl(url, result)
                }
                "stopPlayback" -> { stopPlayback(); result.success(null) }
                else           -> result.notImplemented()
            }
        }

        shareMethodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SHARE_CHANNEL)
        shareMethodChannel!!.setMethodCallHandler { call, result ->
            when (call.method) {
                "getSharedUrl" -> {
                    result.success(pendingSharedUrl)
                    pendingSharedUrl = null
                }
                "getSharedImageUri" -> {
                    result.success(pendingSharedImageUri)
                    pendingSharedImageUri = null
                }
                "copyUriToCache" -> {
                    val uriString = call.argument<String>("uri")
                    if (uriString == null) {
                        result.error("INVALID_URI", "URI nulo", null)
                        return@setMethodCallHandler
                    }
                    try {
                        val uri = Uri.parse(uriString)
                        val mimeType = contentResolver.getType(uri) ?: "image/jpeg"
                        val ext = when {
                            mimeType.contains("png")  -> ".png"
                            mimeType.contains("webp") -> ".webp"
                            mimeType.contains("gif")  -> ".gif"
                            else -> ".jpg"
                        }
                        val outFile = File(cacheDir, "shared_img_${System.currentTimeMillis()}$ext")
                        contentResolver.openInputStream(uri)?.use { input ->
                            FileOutputStream(outFile).use { output -> input.copyTo(output) }
                        }
                        result.success(outFile.absolutePath)
                    } catch (e: Exception) {
                        result.error("COPY_ERROR", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        handleShareIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleShareIntent(intent)
        // Notificar a Flutter inmediatamente si el canal ya está listo
        pendingSharedUrl?.let {
            shareMethodChannel?.invokeMethod("onSharedUrl", it)
            pendingSharedUrl = null
        }
        pendingSharedImageUri?.let {
            shareMethodChannel?.invokeMethod("onSharedImageUri", it)
            pendingSharedImageUri = null
        }
    }

    private fun handleShareIntent(intent: Intent?) {
        when {
            // Imagen única compartida
            intent?.action == Intent.ACTION_SEND && intent.type?.startsWith("image/") == true -> {
                val uri: Uri? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
                } else {
                    @Suppress("DEPRECATION")
                    intent.getParcelableExtra<Parcelable>(Intent.EXTRA_STREAM) as? Uri
                }
                uri?.let { pendingSharedImageUri = it.toString() }
            }
            // Múltiples imágenes — usamos la primera
            intent?.action == Intent.ACTION_SEND_MULTIPLE && intent.type?.startsWith("image/") == true -> {
                val uris: ArrayList<Uri>? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    intent.getParcelableArrayListExtra(Intent.EXTRA_STREAM, Uri::class.java)
                } else {
                    @Suppress("DEPRECATION")
                    intent.getParcelableArrayListExtra(Intent.EXTRA_STREAM)
                }
                uris?.firstOrNull()?.let { pendingSharedImageUri = it.toString() }
            }
            // Texto / enlace compartido
            intent?.action == Intent.ACTION_SEND && intent.type?.startsWith("text/") == true -> {
                val sharedText = intent.getStringExtra(Intent.EXTRA_TEXT)
                if (!sharedText.isNullOrBlank()) pendingSharedUrl = sharedText
            }
        }
    }

    private fun playUrl(url: String, result: MethodChannel.Result) {
        stopPlayback()
        var resultSent = false

        fun safeError(code: String, msg: String) {
            if (!resultSent) { resultSent = true; result.error(code, msg, null) }
        }
        fun safeSuccess() {
            if (!resultSent) { resultSent = true; result.success(null) }
        }

        val mainHandler = android.os.Handler(android.os.Looper.getMainLooper())

        Thread {
            try {
                val conn = URL(url).openConnection() as HttpURLConnection
                conn.connectTimeout = 15_000
                conn.readTimeout    = 0          // sin límite: necesario para archivos grandes
                conn.instanceFollowRedirects = true
                conn.connect()

                val code = conn.responseCode
                if (code != 200) {
                    conn.disconnect()
                    mainHandler.post { safeError("PLAYER_ERROR", "HTTP $code") }
                    return@Thread
                }

                // Extensión desde Content-Type
                val contentType = conn.contentType ?: ""
                val ext = when {
                    contentType.contains("mpeg") || contentType.contains("mp3") -> "mp3"
                    contentType.contains("mp4")  || contentType.contains("m4a") -> "m4a"
                    contentType.contains("ogg")                                  -> "ogg"
                    contentType.contains("wav")                                  -> "wav"
                    contentType.contains("aac")                                  -> "aac"
                    else                                                         -> "m4a"
                }

                val tmp = File(cacheDir, "play_${System.currentTimeMillis()}.$ext")
                try {
                    conn.inputStream.use { input ->
                        FileOutputStream(tmp).use { out ->
                            input.copyTo(out, bufferSize = 64 * 1024) // 64 KB por chunk
                        }
                    }
                } finally {
                    conn.disconnect()
                }

                mainHandler.post {
                    try {
                        val mp = MediaPlayer()
                        mp.setDataSource(tmp.absolutePath)
                        mp.setOnPreparedListener {
                            it.start()
                            safeSuccess()
                            audioChannel?.invokeMethod("onPlaybackStarted", null)
                        }
                        mp.setOnCompletionListener {
                            audioChannel?.invokeMethod("onPlaybackCompleted", null)
                            stopPlayback()
                            try { tmp.delete() } catch (_: Exception) {}
                        }
                        mp.setOnErrorListener { _, what, extra ->
                            safeError("PLAYER_ERROR", "MediaPlayer error $what/$extra")
                            stopPlayback()
                            try { tmp.delete() } catch (_: Exception) {}
                            true
                        }
                        player = mp
                        mp.prepareAsync()
                    } catch (e: Exception) {
                        safeError("PLAYER_ERROR", e.message ?: "Error al preparar el reproductor")
                        try { tmp.delete() } catch (_: Exception) {}
                    }
                }
            } catch (e: Throwable) {
                mainHandler.post { safeError("PLAYER_ERROR", e.message ?: "Error de red") }
            }
        }.also { t ->
            t.uncaughtExceptionHandler = Thread.UncaughtExceptionHandler { _, e ->
                mainHandler.post { safeError("PLAYER_ERROR", e.message ?: "Error inesperado") }
            }
            t.start()
        }
    }

    private fun stopPlayback() {
        try {
            player?.apply { if (isPlaying) stop(); reset(); release() }
        } catch (_: Exception) {}
        player = null
    }

    override fun onDestroy() {
        stopPlayback()
        recorder?.apply { try { stop() } catch (_: Exception) {}; reset(); release() }
        recorder = null
        super.onDestroy()
    }

    private fun startRecording(result: MethodChannel.Result) {
        // Verificar permiso
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO)
            != PackageManager.PERMISSION_GRANTED
        ) {
            pendingResult = result
            ActivityCompat.requestPermissions(
                this, arrayOf(Manifest.permission.RECORD_AUDIO), MIC_PERMISSION_CODE
            )
            return
        }
        doStartRecording(result)
    }

    private fun doStartRecording(result: MethodChannel.Result) {
        try {
            val dir = cacheDir
            val file = File(dir, "rec_${System.currentTimeMillis()}.m4a")
            currentPath = file.absolutePath

            @Suppress("DEPRECATION")
            val rec = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                MediaRecorder(this)
            } else {
                MediaRecorder()
            }
            rec.setAudioSource(MediaRecorder.AudioSource.MIC)
            rec.setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
            rec.setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
            rec.setAudioEncodingBitRate(128_000)
            rec.setAudioSamplingRate(44_100)
            rec.setOutputFile(currentPath)
            rec.prepare()
            rec.start()
            recorder = rec
            result.success(currentPath)
        } catch (e: Exception) {
            result.error("RECORDER_ERROR", e.message, null)
        }
    }

    private fun stopRecording(result: MethodChannel.Result) {
        try {
            recorder?.apply {
                stop()
                reset()
                release()
            }
            recorder = null
            result.success(currentPath)
            currentPath = null
        } catch (e: Exception) {
            result.error("RECORDER_ERROR", e.message, null)
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int, permissions: Array<out String>, grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == MIC_PERMISSION_CODE) {
            val pending = pendingResult ?: return
            pendingResult = null
            if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                doStartRecording(pending)
            } else {
                pending.error("PERMISSION_DENIED", "Permiso de micrófono denegado", null)
            }
        }
    }
}
