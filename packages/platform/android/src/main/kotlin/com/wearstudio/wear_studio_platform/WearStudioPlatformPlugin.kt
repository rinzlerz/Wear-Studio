package com.wearstudio.wear_studio_platform

import android.content.Context
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import com.google.android.gms.common.api.ApiException
import com.google.android.gms.common.api.CommonStatusCodes
import com.google.android.gms.tasks.Task
import com.google.android.gms.wearable.CapabilityClient
import com.google.android.gms.wearable.DataClient
import com.google.android.gms.wearable.DataEvent
import com.google.android.gms.wearable.DataEventBuffer
import com.google.android.gms.wearable.DataItem
import com.google.android.gms.wearable.MessageClient
import com.google.android.gms.wearable.MessageEvent
import com.google.android.gms.wearable.Node
import com.google.android.gms.wearable.PutDataRequest
import com.google.android.gms.wearable.Wearable
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Exposes the Wear OS Data Layer and basic device facts to Dart.
 *
 * This class only translates between platform channels and Google Play
 * services Wearable APIs. All decisions (what to sync, validation, revisions)
 * live in Dart (packages/core), per PRD §2.2.
 *
 * Phase 1 limitation: events are delivered only while a Flutter engine is
 * attached and Dart is listening. Background delivery needs a
 * WearableListenerService (planned for the sync milestone).
 */
// Only Flutter types appear in the class signature. The Wearable listeners
// are private fields, so apps that register this plugin compile without
// Play services classes on their own compile classpath.
class WearStudioPlatformPlugin :
    FlutterPlugin,
    MethodChannel.MethodCallHandler,
    EventChannel.StreamHandler {

    private lateinit var context: Context
    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var eventSink: EventChannel.EventSink? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        methodChannel = MethodChannel(binding.binaryMessenger, METHOD_CHANNEL)
        methodChannel.setMethodCallHandler(this)
        eventChannel = EventChannel(binding.binaryMessenger, EVENT_CHANNEL)
        eventChannel.setStreamHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        stopListening()
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
    }

    // ---------------------------------------------------------------- methods

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getDeviceInfo" -> result.success(deviceInfo())

            "getLocalNode" ->
                Wearable.getNodeClient(context).localNode
                    .respond(result) { nodeToMap(it) }

            "getConnectedNodes" ->
                Wearable.getNodeClient(context).connectedNodes
                    .respond(result) { nodes -> nodes.map { nodeToMap(it) } }

            "getCapableNodes" -> {
                val capability = call.argument<String>("capability")
                    ?: return result.error("bad_args", "capability is required", null)
                Wearable.getCapabilityClient(context)
                    .getCapability(capability, CapabilityClient.FILTER_REACHABLE)
                    .respond(result) { info -> info.nodes.map { nodeToMap(it) } }
            }

            "sendMessage" -> {
                val nodeId = call.argument<String>("nodeId")
                val path = call.argument<String>("path")
                val data = call.argument<ByteArray>("data") ?: ByteArray(0)
                if (nodeId == null || path == null) {
                    return result.error("bad_args", "nodeId and path are required", null)
                }
                Wearable.getMessageClient(context)
                    .sendMessage(nodeId, path, data)
                    .respond(result) { null }
            }

            "putData" -> {
                val path = call.argument<String>("path")
                    ?: return result.error("bad_args", "path is required", null)
                val data = call.argument<ByteArray>("data") ?: ByteArray(0)
                val urgent = call.argument<Boolean>("urgent") ?: true
                val request = PutDataRequest.create(path).setData(data)
                if (urgent) request.setUrgent()
                Wearable.getDataClient(context)
                    .putDataItem(request)
                    .respond(result) { null }
            }

            "getDataItems" -> {
                val path = call.argument<String>("path")
                    ?: return result.error("bad_args", "path is required", null)
                // No host => items at this path from every node.
                val uri = Uri.Builder()
                    .scheme(PutDataRequest.WEAR_URI_SCHEME)
                    .path(path)
                    .build()
                Wearable.getDataClient(context)
                    .getDataItems(uri)
                    .respond(result) { buffer ->
                        try {
                            buffer.map { dataItemToMap(it) }
                        } finally {
                            buffer.release()
                        }
                    }
            }

            else -> result.notImplemented()
        }
    }

    // ----------------------------------------------------------------- events

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        Wearable.getMessageClient(context).addListener(messageListener)
        Wearable.getDataClient(context).addListener(dataListener)
    }

    override fun onCancel(arguments: Any?) {
        stopListening()
    }

    private fun stopListening() {
        if (eventSink == null) return
        eventSink = null
        Wearable.getMessageClient(context).removeListener(messageListener)
        Wearable.getDataClient(context).removeListener(dataListener)
    }

    // Wearable listeners are called on the main thread, which is where
    // EventSink must be used.
    private val messageListener = MessageClient.OnMessageReceivedListener { event ->
        onMessageReceived(event)
    }

    private val dataListener = DataClient.OnDataChangedListener { events ->
        onDataChanged(events)
    }

    private fun onMessageReceived(event: MessageEvent) {
        eventSink?.success(
            mapOf(
                "type" to "message",
                "path" to event.path,
                "sourceNodeId" to event.sourceNodeId,
                "data" to event.data,
            ),
        )
    }

    private fun onDataChanged(events: DataEventBuffer) {
        val sink = eventSink ?: return
        // The buffer is only valid during this callback, so copy everything now.
        val copies = events.map { event ->
            val item = event.dataItem
            mapOf(
                "type" to if (event.type == DataEvent.TYPE_DELETED) "dataDeleted" else "dataChanged",
                "path" to item.uri.path,
                "sourceNodeId" to item.uri.host,
                "data" to item.data,
            )
        }
        copies.forEach { sink.success(it) }
    }

    // ---------------------------------------------------------------- helpers

    private fun deviceInfo(): Map<String, Any?> = mapOf(
        "isWatch" to context.packageManager.hasSystemFeature(PackageManager.FEATURE_WATCH),
        "isScreenRound" to (
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.M &&
                context.resources.configuration.isScreenRound
            ),
        "manufacturer" to Build.MANUFACTURER,
        "model" to Build.MODEL,
        "sdkInt" to Build.VERSION.SDK_INT,
    )

    private fun nodeToMap(node: Node): Map<String, Any?> = mapOf(
        "id" to node.id,
        "displayName" to node.displayName,
        "isNearby" to node.isNearby,
    )

    private fun dataItemToMap(item: DataItem): Map<String, Any?> = mapOf(
        "path" to item.uri.path,
        "sourceNodeId" to item.uri.host,
        "data" to item.data,
    )

    private fun <T> Task<T>.respond(
        result: MethodChannel.Result,
        transform: (T) -> Any?,
    ) {
        addOnSuccessListener { value ->
            try {
                result.success(transform(value))
            } catch (e: Exception) {
                result.error("internal", e.message, null)
            }
        }
        addOnFailureListener { e -> result.error(errorCode(e), e.message, null) }
    }

    private fun errorCode(e: Exception): String {
        val status = (e as? ApiException)?.statusCode ?: return "failed"
        return if (status == CommonStatusCodes.API_NOT_CONNECTED) {
            "unavailable" // Wearable API missing (e.g. phone without a paired watch app).
        } else {
            "api_$status"
        }
    }

    companion object {
        const val METHOD_CHANNEL = "com.wearstudio/platform"
        const val EVENT_CHANNEL = "com.wearstudio/platform/events"
    }
}
