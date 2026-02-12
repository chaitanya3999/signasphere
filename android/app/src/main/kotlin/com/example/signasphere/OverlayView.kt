package com.example.signasphere

import android.content.Context
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.util.AttributeSet
import android.view.View
import com.google.mediapipe.tasks.vision.handlandmarker.HandLandmarkerResult
import kotlin.math.max
import kotlin.math.min

class OverlayView(context: Context?, attrs: AttributeSet?) : View(context, attrs) {
    private var results: HandLandmarkerResult? = null
    private var linePaint = Paint()
    private var pointPaint = Paint()

    private var scaleFactor: Float = 1f
    private var imageWidth: Int = 1
    private var imageHeight: Int = 1

    init {
        initPaints()
    }

    fun clear() {
        results = null
        invalidate()
    }

    private fun initPaints() {
        linePaint.color = Color.CYAN
        linePaint.strokeWidth = 8f
        linePaint.style = Paint.Style.STROKE

        pointPaint.color = Color.WHITE
        pointPaint.strokeWidth = 10f
        pointPaint.style = Paint.Style.FILL
    }

    override fun draw(canvas: Canvas) {
        super.draw(canvas)

        results?.let { handLandmarkerResult ->
            for (landmark in handLandmarkerResult.landmarks()) {
                // ... (Keep existing connection drawing code here) ...
                // Thumb
                drawLine(canvas, landmark[0], landmark[1])
                drawLine(canvas, landmark[1], landmark[2])
                drawLine(canvas, landmark[2], landmark[3])
                drawLine(canvas, landmark[3], landmark[4])
                // Index
                drawLine(canvas, landmark[0], landmark[5])
                drawLine(canvas, landmark[5], landmark[6])
                drawLine(canvas, landmark[6], landmark[7])
                drawLine(canvas, landmark[7], landmark[8])
                // Middle
                drawLine(canvas, landmark[9], landmark[10])
                drawLine(canvas, landmark[10], landmark[11])
                drawLine(canvas, landmark[11], landmark[12])
                drawLine(canvas, landmark[12], landmark[9])
                drawLine(canvas, landmark[0], landmark[9])
                // Ring
                drawLine(canvas, landmark[13], landmark[14])
                drawLine(canvas, landmark[14], landmark[15])
                drawLine(canvas, landmark[15], landmark[16])
                drawLine(canvas, landmark[13], landmark[0])
                // Pinky
                drawLine(canvas, landmark[17], landmark[18])
                drawLine(canvas, landmark[18], landmark[19])
                drawLine(canvas, landmark[19], landmark[20])
                drawLine(canvas, landmark[17], landmark[0])

                // Landmarks
                for (normalizedLandmark in landmark) {
                    val x = normalizedLandmark.x() * imageWidth * scaleFactor
                    val y = normalizedLandmark.y() * imageHeight * scaleFactor

                    val offsetX = (width - imageWidth * scaleFactor) / 2f
                    val offsetY = (height - imageHeight * scaleFactor) / 2f

                    canvas.drawCircle(x + offsetX, y + offsetY, 8f, pointPaint)
                }
            }
        }
    }

    private fun drawLine(canvas: Canvas, start: com.google.mediapipe.tasks.components.containers.NormalizedLandmark, end: com.google.mediapipe.tasks.components.containers.NormalizedLandmark) {
        val startX = start.x() * imageWidth * scaleFactor
        val startY = start.y() * imageHeight * scaleFactor
        val endX = end.x() * imageWidth * scaleFactor
        val endY = end.y() * imageHeight * scaleFactor

        // Adjust for center-crop (Fill Type)
        val offsetX = (width - imageWidth * scaleFactor) / 2f
        val offsetY = (height - imageHeight * scaleFactor) / 2f

        canvas.drawLine(startX + offsetX, startY + offsetY, endX + offsetX, endY + offsetY, linePaint)
    }

    fun setResults(
        handLandmarkerResult: HandLandmarkerResult,
        imageHeight: Int,
        imageWidth: Int
    ) {
        this.results = handLandmarkerResult
        this.imageHeight = imageHeight
        this.imageWidth = imageWidth

        // Calculate scale to FILL the screen (Center Crop behavior)
        // This matches standard CameraX PreviewView.ScaleType.FILL_CENTER
        val scaleX = width * 1f / imageWidth
        val scaleY = height * 1f / imageHeight
        this.scaleFactor = max(scaleX, scaleY)

        invalidate()
    }
}