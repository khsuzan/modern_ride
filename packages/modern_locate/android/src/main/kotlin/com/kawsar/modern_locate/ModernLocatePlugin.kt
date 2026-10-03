package com.kawsar.modern_locate

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.location.LocationManager
import android.net.Uri
import android.os.Looper
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.google.android.gms.location.*
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry

class ModernLocatePlugin : FlutterPlugin, MethodChannel.MethodCallHandler, EventChannel.StreamHandler, ActivityAware,
    PluginRegistry.RequestPermissionsResultListener {

    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private lateinit var context: Context
    private var activity: Activity? = null
    private var activityBinding: ActivityPluginBinding? = null

    private lateinit var fusedLocationClient: FusedLocationProviderClient
    private var locationCallback: LocationCallback? = null

    private var pendingPermissionResult: MethodChannel.Result? = null
    private val PERMISSION_REQUEST_CODE = 4401

    private val PREFS_NAME = "modern_locate_prefs"
    private val KEY_REQUESTED_ONCE = "permission_requested_once"

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        fusedLocationClient = LocationServices.getFusedLocationProviderClient(context)

        methodChannel = MethodChannel(binding.binaryMessenger, "modern_locate/control")
        methodChannel.setMethodCallHandler(this)

        eventChannel = EventChannel(binding.binaryMessenger, "modern_locate/stream")
        eventChannel.setStreamHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "checkPermission" -> handleCheckPermission(result)
            "requestPermission" -> handleRequestPermission(result)
            "getCurrentLocation" -> handleGetCurrentLocation(result)
            "openAppSettings" -> handleOpenAppSettings(result)
            else -> result.notImplemented()
        }
    }

    private fun markPermissionRequested() {
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .putBoolean(KEY_REQUESTED_ONCE, true)
            .apply()
    }

    private fun hasRequestedOnce(): Boolean {
        return context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .getBoolean(KEY_REQUESTED_ONCE, false)
    }

    private fun hasPermission(): Boolean {
        val fineGranted = ContextCompat.checkSelfPermission(
            context, Manifest.permission.ACCESS_FINE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED

        val coarseGranted = ContextCompat.checkSelfPermission(
            context, Manifest.permission.ACCESS_COARSE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED

        return fineGranted || coarseGranted
    }

    private fun isGpsEnabled(): Boolean {
        val locationManager = context.getSystemService(Context.LOCATION_SERVICE) as LocationManager
        return locationManager.isProviderEnabled(LocationManager.GPS_PROVIDER) ||
                locationManager.isProviderEnabled(LocationManager.NETWORK_PROVIDER)
    }

    private fun handleCheckPermission(result: MethodChannel.Result) {
        if (hasPermission()) {
            result.success("granted")
            return
        }

        val act = activity
        if (act == null) {
            result.success("denied")
            return
        }

        val shouldShowRationale = ActivityCompat.shouldShowRequestPermissionRationale(
            act, Manifest.permission.ACCESS_FINE_LOCATION
        )

        if (hasRequestedOnce() && !shouldShowRationale) {
            result.success("permanently_denied")
        } else {
            result.success("denied")
        }
    }

    private fun handleRequestPermission(result: MethodChannel.Result) {
        if (hasPermission()) {
            result.success("granted")
            return
        }
        val currentActivity = activity
        if (currentActivity == null) {
            result.error("NO_ACTIVITY", "Activity not available", null)
            return
        }

        markPermissionRequested()
        pendingPermissionResult = result
        ActivityCompat.requestPermissions(
            currentActivity,
            arrayOf(Manifest.permission.ACCESS_FINE_LOCATION, Manifest.permission.ACCESS_COARSE_LOCATION),
            PERMISSION_REQUEST_CODE
        )
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ): Boolean {
        if (requestCode == PERMISSION_REQUEST_CODE) {
            if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                pendingPermissionResult?.success("granted")
            } else {
                val act = activity
                val permanentlyDenied = if (act != null) {
                    !ActivityCompat.shouldShowRequestPermissionRationale(act, Manifest.permission.ACCESS_FINE_LOCATION)
                } else false

                if (permanentlyDenied) {
                    pendingPermissionResult?.success("permanently_denied")
                } else {
                    pendingPermissionResult?.success("denied")
                }
            }
            pendingPermissionResult = null
            return true
        }
        return false
    }

    private fun handleGetCurrentLocation(result: MethodChannel.Result) {
        if (!hasPermission()) {
            result.error("PERMISSION_DENIED", "Location permission not granted", null)
            return
        }
        if (!isGpsEnabled()) {
            result.error("SERVICES_DISABLED", "Device GPS is disabled", null)
            return
        }

        fusedLocationClient.lastLocation.addOnSuccessListener { location ->
            if (location != null) {
                result.success(buildLocationMap(location))
            } else {
                fusedLocationClient.getCurrentLocation(Priority.PRIORITY_HIGH_ACCURACY, null)
                    .addOnSuccessListener { freshLocation ->
                        if (freshLocation != null) {
                            result.success(buildLocationMap(freshLocation))
                        } else {
                            result.error("TIMEOUT", "Location fix timed out", null)
                        }
                    }
                    .addOnFailureListener { e ->
                        result.error("LOCATION_ERROR", e.localizedMessage, null)
                    }
            }
        }.addOnFailureListener { e ->
            result.error("LOCATION_ERROR", e.localizedMessage, null)
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        if (!hasPermission()) {
            events?.error("PERMISSION_DENIED", "Location permission not granted", null)
            return
        }
        if (!isGpsEnabled()) {
            events?.error("SERVICES_DISABLED", "Device GPS is disabled", null)
            return
        }

        val locationRequest = LocationRequest.Builder(Priority.PRIORITY_HIGH_ACCURACY, 2000L)
            .setMinUpdateIntervalMillis(1000L)
            .build()

        locationCallback = object : LocationCallback() {
            override fun onLocationResult(locationResult: LocationResult) {
                val loc = locationResult.lastLocation ?: return
                events?.success(buildLocationMap(loc))
            }
        }

        fusedLocationClient.requestLocationUpdates(locationRequest, locationCallback!!, Looper.getMainLooper())
    }

    override fun onCancel(arguments: Any?) {
        locationCallback?.let {
            fusedLocationClient.removeLocationUpdates(it)
            locationCallback = null
        }
    }

    private fun handleOpenAppSettings(result: MethodChannel.Result) {
        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
            data = Uri.fromParts("package", context.packageName, null)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        context.startActivity(intent)
        result.success(true)
    }

    private fun buildLocationMap(location: android.location.Location): Map<String, Any> {
        return mapOf(
            "latitude" to location.latitude,
            "longitude" to location.longitude,
            "heading" to location.bearing.toDouble(),
            "accuracy" to location.accuracy.toDouble()
        )
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        activityBinding = binding
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activityBinding?.removeRequestPermissionsResultListener(this)
        activity = null
        activityBinding = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }

    override fun onDetachedFromActivity() {
        activityBinding?.removeRequestPermissionsResultListener(this)
        activity = null
        activityBinding = null
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        locationCallback?.let {
            fusedLocationClient.removeLocationUpdates(it)
            locationCallback = null
        }
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
    }
}