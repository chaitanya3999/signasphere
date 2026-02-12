package com.example.signasphere

import android.content.Context
import android.os.SystemClock
import com.google.mediapipe.framework.image.BitmapImageBuilder
import com.google.mediapipe.framework.image.MPImage
import com.google.mediapipe.tasks.core.BaseOptions
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.handlandmarker.HandLandmarker
import com.google.mediapipe.tasks.vision.handlandmarker.HandLandmarkerResult

class HandLandmarkerHelper(
    val context: Context,
    val handLandmarkerListener: LandmarkerListener
) {
    private var handLandmarker: HandLandmarker? = null
    private val debounceThreshold = 5
    private val gestureHistory = mutableMapOf<String, Int>()

    init {
        setupHandLandmarker()
    }

    fun setupHandLandmarker() {
        val baseOptionsBuilder = BaseOptions.builder().setModelAssetPath("hand_landmarker.task")
        val baseOptions = baseOptionsBuilder.build()

        val optionsBuilder = HandLandmarker.HandLandmarkerOptions.builder()
            .setBaseOptions(baseOptions)
            .setMinHandDetectionConfidence(0.5f)
            .setMinTrackingConfidence(0.5f)
            .setMinHandPresenceConfidence(0.5f)
            .setNumHands(1)
            .setRunningMode(RunningMode.LIVE_STREAM)
            .setResultListener(this::returnLivestreamResult)
            .setErrorListener(this::returnLivestreamError)

        try {
            handLandmarker = HandLandmarker.createFromOptions(context, optionsBuilder.build())
        } catch (e: IllegalStateException) {
            handLandmarkerListener.onError("MediaPipe Init Failed: ${e.message}")
        } catch (e: RuntimeException) {
            handLandmarkerListener.onError("MediaPipe Runtime Error: ${e.message}")
        }
    }

    fun detectLiveStream(imageProxy: androidx.camera.core.ImageProxy) {
        val frameTime = SystemClock.uptimeMillis()
        val bitmap = BitmapUtils.getBitmap(imageProxy)
        imageProxy.close() // Close safely immediately after conversion

        if (bitmap != null) {
            val mpImage = BitmapImageBuilder(bitmap).build()
            handLandmarker?.detectAsync(mpImage, frameTime)
        }
    }

    private fun returnLivestreamResult(result: HandLandmarkerResult, input: MPImage) {
        handLandmarkerListener.onResults(result, input)
        val gesture = recognizeGesture(result)
        if (gesture != "None") {
            debounceGesture(gesture)
        }
    }

    private fun debounceGesture(gesture: String) {
        // Increment count for this gesture
        gestureHistory[gesture] = (gestureHistory[gesture] ?: 0) + 1

        // Decrement others
        gestureHistory.keys.forEach { key ->
            if (key != gesture) {
                gestureHistory[key] = (gestureHistory[key] ?: 0) - 1
                if (gestureHistory[key]!! < 0) gestureHistory[key] = 0
            }
        }

        // Check threshold
        if ((gestureHistory[gesture] ?: 0) > debounceThreshold) {
            handLandmarkerListener.onGestureDetected(gesture)
            // Reset slightly to prevent spam, or keep high to maintain stability
            gestureHistory[gesture] = debounceThreshold // Cap it
        }
    }

    private fun returnLivestreamError(error: RuntimeException) {
        handLandmarkerListener.onError(error.message ?: "Unknown MediaPipe error")
    }

    fun clear() {
        handLandmarker?.close()
        handLandmarker = null
    }

    private fun recognizeGesture(result: HandLandmarkerResult): String {
        if (result.landmarks().isEmpty()) return "None"
        val landmarks = result.landmarks()[0]

        // 0: Wrist
        // 4: ThumbTip, 8: IndexTip, 12: MiddleTip, 16: RingTip, 20: PinkyTip
        // PIP Joints: 6, 10, 14, 18

        val indexTip = landmarks[8]; val indexPip = landmarks[6]
        val middleTip = landmarks[12]; val middlePip = landmarks[10]
        val ringTip = landmarks[16]; val ringPip = landmarks[14]
        val pinkyTip = landmarks[20]; val pinkyPip = landmarks[18]

        // Check if fingers are extended (Tip y < Pip y means UP because Y increases downwards)
        val indexOpen = indexTip.y() < indexPip.y()
        val middleOpen = middleTip.y() < middlePip.y()
        val ringOpen = ringTip.y() < ringPip.y()
        val pinkyOpen = pinkyTip.y() < pinkyPip.y()

        // Thumb Logic (X comparison for left/right handedness)
        // Simplified: Thumb Tip x < Thumb IP x (assuming right hand palm facing camera)
        // For robustness, we check Y too
        // val thumbOpen = landmarks[4].x() < landmarks[3].x()

        if (!indexOpen && !middleOpen && !ringOpen && !pinkyOpen) return "Fist ✊"
        if (indexOpen && middleOpen && ringOpen && pinkyOpen) return "Open Palm ✋"
        if (indexOpen && middleOpen && !ringOpen && !pinkyOpen) return "Victory ✌️"
        if (indexOpen && !middleOpen && !ringOpen && !pinkyOpen) return "Index Up ☝️"
        if (indexOpen && !middleOpen && !ringOpen && pinkyOpen) return "I Love You 🤟"

        return "None"
    }

    interface LandmarkerListener {
        fun onError(error: String)
        fun onResults(result: HandLandmarkerResult, input: MPImage)
        fun onGestureDetected(gesture: String)
    }
}