package app.rork.you_smart_health_companion

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val STEP_CHANNEL = "app.rork.you/steps"
    private var sensorManager: SensorManager? = null
    private var stepSensor: Sensor? = null
    private var currentStepCount: Int = 0
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
        stepSensor = sensorManager?.getDefaultSensor(Sensor.TYPE_STEP_COUNTER)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, STEP_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getStepCount" -> {
                    if (stepSensor != null) {
                        // Register temporary listener to get current value
                        val listener = object : SensorEventListener {
                            override fun onSensorChanged(event: SensorEvent?) {
                                event?.let {
                                    currentStepCount = it.values[0].toInt()
                                    result.success(currentStepCount)
                                    // Unregister after getting value
                                    sensorManager?.unregisterListener(this)
                                }
                            }
                            
                            override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {
                                // Not needed
                            }
                        }
                        
                        sensorManager?.registerListener(
                            listener,
                            stepSensor,
                            SensorManager.SENSOR_DELAY_NORMAL
                        )
                        
                        // Timeout after 1 second if no data
                        android.os.Handler(mainLooper).postDelayed({
                            sensorManager?.unregisterListener(listener)
                            if (currentStepCount == 0) {
                                result.error("SENSOR_ERROR", "No step data available", null)
                            }
                        }, 1000)
                    } else {
                        result.error("NO_SENSOR", "Step counter sensor not available", null)
                    }
                }
                "isStepCounterAvailable" -> {
                    result.success(stepSensor != null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
