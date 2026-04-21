package com.studyapp.recall_app

import android.os.Handler
import android.os.Looper
import com.google.mediapipe.tasks.genai.llminference.LlmInference
import com.google.mediapipe.tasks.genai.llminference.LlmInferenceSession
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.Executors
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

class OnDeviceAiChannel {
    companion object {
        private const val CHANNEL = "recall_app/on_device_ai"

        private val mainHandler = Handler(Looper.getMainLooper())
        private val executor = Executors.newSingleThreadExecutor()

        lateinit var appContext: android.content.Context

        private var cachedEngine: LlmInference? = null
        private var cachedModelPath: String? = null

        fun register(flutterEngine: FlutterEngine) {
            MethodChannel(
                flutterEngine.dartExecutor.binaryMessenger,
                CHANNEL
            ).setMethodCallHandler { call: MethodCall, result: MethodChannel.Result ->
                when (call.method) {
                    "checkModel" -> handleCheckModel(call, result)
                    "runInference" -> handleRunInference(call, result)
                    "unloadModel" -> handleUnloadModel(result)
                    else -> result.notImplemented()
                }
            }
        }

        private fun handleCheckModel(call: MethodCall, result: MethodChannel.Result) {
            val modelPath = call.argument<String>("modelPath").orEmpty().trim()
            executor.execute {
                try {
                    if (modelPath.isEmpty()) {
                        postSuccess(result, mapOf(
                            "ready" to false,
                            "message" to "No model path provided."
                        ))
                        return@execute
                    }
                    val file = File(modelPath)
                    if (!file.exists()) {
                        postSuccess(result, mapOf(
                            "ready" to false,
                            "message" to "Model file not found: $modelPath"
                        ))
                        return@execute
                    }
                    val sizeMb = file.length() / (1024 * 1024)

                    // Actually try to load the model to verify it is compatible
                    // with MediaPipe LlmInference (not just that the file exists).
                    val options = LlmInference.LlmInferenceOptions.builder()
                        .setModelPath(modelPath)
                        .setMaxTokens(64)
                        .setMaxTopK(1)
                        .build()
                    val testEngine = LlmInference.createFromOptions(appContext, options)
                    testEngine.close()

                    postSuccess(result, mapOf(
                        "ready" to true,
                        "message" to "Model ready ($sizeMb MB)",
                        "sizeMb" to sizeMb
                    ))
                } catch (t: Throwable) {
                    postSuccess(result, mapOf(
                        "ready" to false,
                        "message" to "Model load failed: ${t.message}"
                    ))
                }
            }
        }

        private fun handleRunInference(call: MethodCall, result: MethodChannel.Result) {
            val modelPath = call.argument<String>("modelPath").orEmpty().trim()
            val prompt = call.argument<String>("prompt").orEmpty()
            val maxTokens = call.argument<Int>("maxTokens") ?: 2048
            // temperature=0 → greedy decoding → deterministic JSON output.
            // topK=1 forces the single most likely token at each step.
            val temperature = call.argument<Double>("temperature")?.toFloat() ?: 0.0f
            val topK = (call.argument<Int>("topK") ?: 1).coerceAtLeast(1)

            executor.execute {
                try {
                    if (modelPath.isEmpty()) {
                        postError(result, "no_model", "No model path provided.", null)
                        return@execute
                    }
                    if (prompt.isBlank()) {
                        postError(result, "no_prompt", "Prompt is empty.", null)
                        return@execute
                    }

                    // Create a fresh engine each time to avoid the MediaPipe
                    // "Packet timestamp mismatch" crash that occurs when reusing
                    // an LlmInference instance for multiple generateResponse calls.
                    releaseEngine()

                    val options = LlmInference.LlmInferenceOptions.builder()
                        .setModelPath(modelPath)
                        .setMaxTokens(maxTokens)
                        .setMaxTopK(topK)
                        .build()

                    val engine = LlmInference.createFromOptions(appContext, options)
                    cachedEngine = engine
                    cachedModelPath = modelPath

                    val sessionOptions = LlmInferenceSession.LlmInferenceSessionOptions.builder()
                        .setTemperature(temperature)
                        .setTopK(topK)
                        .setTopP(1.0f)
                        .build()
                    val session = LlmInferenceSession.createFromOptions(engine, sessionOptions)
                    session.addQueryChunk(prompt)

                    // Use async streaming API to collect the full response.
                    val sb = StringBuilder()
                    val latch = CountDownLatch(1)
                    var streamError: Throwable? = null

                    session.generateResponseAsync { partialResult, done ->
                        try {
                            if (partialResult != null) {
                                sb.append(partialResult)
                            }
                            if (done) {
                                latch.countDown()
                            }
                        } catch (t: Throwable) {
                            streamError = t
                            latch.countDown()
                        }
                    }

                    if (!latch.await(120, TimeUnit.SECONDS)) {
                        closeSession(session)
                        releaseEngine()
                        postError(result, "timeout", "Inference timed out after 120 seconds.", null)
                        return@execute
                    }

                    // Release engine after each inference to prevent timestamp issues
                    closeSession(session)
                    releaseEngine()

                    if (streamError != null) {
                        throw streamError!!
                    }

                    val response = sb.toString().trim()
                    if (response.isEmpty()) {
                        postError(result, "empty_response", "Model returned empty response.", null)
                        return@execute
                    }

                    postSuccess(result, response)
                } catch (t: Throwable) {
                    releaseEngine()
                    postError(result, "inference_failed", t.message ?: t.javaClass.simpleName, null)
                }
            }
        }

        private fun handleUnloadModel(result: MethodChannel.Result) {
            executor.execute {
                releaseEngine()
                postSuccess(result, "unloaded")
            }
        }

        private fun releaseEngine() {
            try {
                cachedEngine?.close()
            } catch (_: Throwable) {}
            cachedEngine = null
            cachedModelPath = null
        }

        private fun closeSession(session: LlmInferenceSession) {
            try {
                session.close()
            } catch (_: Throwable) {}
        }

        private fun postSuccess(result: MethodChannel.Result, value: Any) {
            mainHandler.post { result.success(value) }
        }

        private fun postError(result: MethodChannel.Result, code: String, message: String, details: Any?) {
            mainHandler.post { result.error(code, message, details) }
        }
    }
}
