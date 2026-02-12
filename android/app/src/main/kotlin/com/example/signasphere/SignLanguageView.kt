package com.example.signasphere

import android.content.Context
import android.content.ContextWrapper
import android.os.Handler
import android.os.Looper
import android.view.View
import android.widget.FrameLayout
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.Preview
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import androidx.core.content.ContextCompat
import androidx.lifecycle.LifecycleOwner
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.platform.PlatformView
import java.util.concurrent.Executors

class SignLanguageView(
    context: Context,
    messenger: BinaryMessenger,
    id: Int
) : PlatformView, HandLandmarkerHelper.LandmarkerListener {

    // 1. Initialize FrameLayout
    private val frameLayout: FrameLayout = FrameLayout(context)
    private var previewView: PreviewView
    private var overlayView: OverlayView
    private var handLandmarkerHelper: HandLandmarkerHelper
    private var cameraProvider: ProcessCameraProvider? = null
    private val eventChannel = EventChannel(messenger, "signasphere/gesture_channel_$id")
    private var eventSink: EventChannel.EventSink? = null

    // Performance Control
    private val backgroundExecutor = Executors.newSingleThreadExecutor()
    private var lastFrameTime = 0L
    private val throttleMs = 50L // ~20 FPS Cap

    init {
        // 2. Define LayoutParams to FORCE Match Parent
        val layoutParams = FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT,
            FrameLayout.LayoutParams.MATCH_PARENT
        )

        // 3. Initialize Views
        previewView = PreviewView(context)
        previewView.scaleType = PreviewView.ScaleType.FILL_CENTER

        // 🔥 FORCE TextureView instead of SurfaceView
        previewView.implementationMode = PreviewView.ImplementationMode.COMPATIBLE

        overlayView = OverlayView(context, null)

        // 4. Add Views with LayoutParams (Stacking them correctly)
        frameLayout.addView(previewView, layoutParams) // Bottom Layer
        frameLayout.addView(overlayView, layoutParams) // Top Layer (Transparent)

        handLandmarkerHelper = HandLandmarkerHelper(context, this)

        eventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
            }
            override fun onCancel(arguments: Any?) {
                eventSink = null
            }
        })

        startCamera()
    }

    private fun startCamera() {
        val cameraProviderFuture = ProcessCameraProvider.getInstance(frameLayout.context)
        cameraProviderFuture.addListener({
            try {
                cameraProvider = cameraProviderFuture.get()
                bindCameraUseCases()
            } catch (e: Exception) {
                onError("Camera Provider Init Failed: ${e.message}")
            }
        }, ContextCompat.getMainExecutor(frameLayout.context))
    }

    private fun bindCameraUseCases() {
        val cameraProvider = cameraProvider ?: return
        val cameraSelector = CameraSelector.DEFAULT_FRONT_CAMERA

        val preview = Preview.Builder().build()
        preview.setSurfaceProvider(previewView.surfaceProvider)

        val imageAnalyzer = ImageAnalysis.Builder()
            .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
            .setOutputImageFormat(ImageAnalysis.OUTPUT_IMAGE_FORMAT_YUV_420_888)
            .build()
            .also {
                it.setAnalyzer(backgroundExecutor) { imageProxy ->
                    val currentTime = System.currentTimeMillis()
                    if (currentTime - lastFrameTime < throttleMs) {
                        imageProxy.close()
                        return@setAnalyzer
                    }
                    lastFrameTime = currentTime

                    try {
                        handLandmarkerHelper.detectLiveStream(imageProxy)
                    } catch (e: Exception) {
                        imageProxy.close()
                        onError("Analysis Error: ${e.message}")
                    }
                }
            }

        try {
            cameraProvider.unbindAll()
            val lifecycleOwner = getLifecycleOwner(frameLayout.context)

            if (lifecycleOwner != null) {
                cameraProvider.bindToLifecycle(lifecycleOwner, cameraSelector, preview, imageAnalyzer)
            } else {
                onError("Context is not LifecycleOwner")
            }
        } catch (exc: Exception) {
            onError("Camera Binding Failed: ${exc.message}")
        }
    }

    private fun getLifecycleOwner(context: Context): LifecycleOwner? {
        var curContext = context
        while (curContext is ContextWrapper) {
            if (curContext is LifecycleOwner) {
                return curContext
            }
            curContext = curContext.baseContext
        }
        return null
    }

    override fun getView(): View = frameLayout

    override fun dispose() {
        try {
            cameraProvider?.unbindAll()
            handLandmarkerHelper.clear()
            backgroundExecutor.shutdownNow()
        } catch (e: Exception) {
            // Log error
        }
    }

    override fun onError(error: String) {
        Handler(Looper.getMainLooper()).post {
            eventSink?.error("NATIVE_ERROR", error, null)
        }
    }

    override fun onResults(result: com.google.mediapipe.tasks.vision.handlandmarker.HandLandmarkerResult, input: com.google.mediapipe.framework.image.MPImage) {
        // 1. Update Overlay (Keep existing logic)
        overlayView.post {
            overlayView.setResults(result, input.height, input.width)
        }

        // 2. Send Raw Landmarks to Flutter
        if (result.landmarks().isNotEmpty()) {
            val handLandmarks = result.landmarks()[0] // Get first hand
            val rawPoints = ArrayList<List<Float>>()

            for (landmark in handLandmarks) {
                // MediaPipe gives x, y, z normalized (0.0 - 1.0)
                // We send them as simple lists of floats [x, y, z]
                val point = listOf(landmark.x(), landmark.y(), landmark.z())
                rawPoints.add(point)
            }

            // Send List<List<Float>> to Flutter
            Handler(Looper.getMainLooper()).post {
                eventSink?.success(rawPoints)
            }
        }
    }

    // REMOVE or COMMENT OUT onGestureDetected since we do logic in Flutter now
    override fun onGestureDetected(gesture: String) {
        // No-op: We moved logic to Flutter
    }
}