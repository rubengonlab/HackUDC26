package com.hackudc.kelea_notes

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.media.MediaRecorder
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.junkdrawer/audio_recorder"
    private val SHARE_CHANNEL = "com.junkdrawer/share_handler"
    private val MIC_PERMISSION_CODE = 101

    private var recorder: MediaRecorder? = null
    private var currentPath: String? = null
    private var pendingResult: MethodChannel.Result? = null

    // Guardamos el enlace recibido hasta que Flutter esté listo para recibirlo
    private var pendingSharedUrl: String? = null
    private var shareMethodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Canal grabación de audio
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "start" -> startRecording(result)
                    "stop"  -> stopRecording(result)
                    else    -> result.notImplemented()
                }
            }

        // Canal de share: Flutter llama a "getSharedUrl" para obtener la URL pendiente
        shareMethodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SHARE_CHANNEL)
        shareMethodChannel!!.setMethodCallHandler { call, result ->
            when (call.method) {
                "getSharedUrl" -> {
                    result.success(pendingSharedUrl)
                    pendingSharedUrl = null
                }
                else -> result.notImplemented()
            }
        }

        // Si la app se abrió directamente desde un Share Intent, procesarlo ahora
        handleShareIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        // La app ya estaba abierta (singleTop) y llega un nuevo intent de share
        handleShareIntent(intent)
        // Notificar a Flutter inmediatamente si el canal ya está listo
        val url = pendingSharedUrl
        if (url != null) {
            shareMethodChannel?.invokeMethod("onSharedUrl", url)
            pendingSharedUrl = null
        }
    }

    private fun handleShareIntent(intent: Intent?) {
        if (intent?.action == Intent.ACTION_SEND &&
            intent.type?.startsWith("text/") == true
        ) {
            val sharedText = intent.getStringExtra(Intent.EXTRA_TEXT)
            if (!sharedText.isNullOrBlank()) {
                pendingSharedUrl = sharedText
            }
        }
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
