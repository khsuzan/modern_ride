import Flutter
import UIKit
import CoreLocation

public class ModernLocatePlugin: NSObject, FlutterPlugin, FlutterStreamHandler, CLLocationManagerDelegate {

    // MARK: - Constants
    private static let methodChannelName = "modern_locate/control"
    private static let eventChannelName = "modern_locate/stream"
    private static let temporaryAccuracyPurposeKey = "PreciseLocation"
    private static let locationTimeoutSeconds: TimeInterval = 10.0
    private static let streamInitialFixTimeoutSeconds: TimeInterval = 8.0
    private static let freshLocationThresholdSeconds: TimeInterval = 15.0

    // MARK: - CoreLocation Managers
    private let locationManager = CLLocationManager()
    private var isStreaming = false
    private var eventSink: FlutterEventSink?

    // MARK: - State Management
    private var pendingPermissionResult: FlutterResult?
    private var pendingLocationRequests: [([String: Any]?, FlutterError?) -> Void] = []
    private var singleLocationTimeoutTimer: Timer?
    private var streamInitialFixTimer: Timer?
    private var currentHeading: CLHeading?

    // MARK: - Plugin Registration
    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = ModernLocatePlugin()

        let methodChannel = FlutterMethodChannel(name: methodChannelName, binaryMessenger: registrar.messenger())
        registrar.addMethodCallDelegate(instance, channel: methodChannel)

        let eventChannel = FlutterEventChannel(name: eventChannelName, binaryMessenger: registrar.messenger())
        eventChannel.setStreamHandler(instance)
    }

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.activityType = .automotiveNavigation
    }

    // MARK: - Method Channel Handling
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "checkPermission":
            handleCheckPermission(result: result)
        case "requestPermission":
            handleRequestPermission(result: result)
        case "getCurrentLocation":
            handleGetCurrentLocation(result: result)
        case "openAppSettings":
            handleOpenAppSettings(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Permissions Logic
    private var currentAuthStatus: CLAuthorizationStatus {
        if #available(iOS 14.0, *) {
            return locationManager.authorizationStatus
        } else {
            return CLLocationManager.authorizationStatus()
        }
    }

    private var isLocationAuthorized: Bool {
        let status = currentAuthStatus
        return status == .authorizedWhenInUse || status == .authorizedAlways
    }

    private var isGpsEnabled: Bool {
        return CLLocationManager.locationServicesEnabled()
    }

    private func handleCheckPermission(result: @escaping FlutterResult) {
        if !isGpsEnabled {
            result("denied")
            return
        }

        switch currentAuthStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            result("granted")
        case .denied, .restricted:
            result("permanently_denied")
        case .notDetermined:
            result("denied")
        @unknown default:
            result("denied")
        }
    }

    private func handleRequestPermission(result: @escaping FlutterResult) {
        if !isGpsEnabled {
            result("denied")
            return
        }

        switch currentAuthStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            handleApproximateLocationCheck(result: result)
        case .denied, .restricted:
            result("permanently_denied")
        case .notDetermined:
            pendingPermissionResult = result
            locationManager.requestWhenInUseAuthorization()
        @unknown default:
            result("denied")
        }
    }

    /// Sensibly handle iOS 14+ Approximate Location (Reduced Accuracy).
    /// If user granted Approximate Location, the permission is still considered "granted".
    /// If the host app configured a precise location dictionary key in Info.plist, we offer
    /// a 1-time escalation prompt. Even if declined or kept as approximate, permission remains granted.
    private func handleApproximateLocationCheck(result: @escaping FlutterResult) {
        if #available(iOS 14.0, *), locationManager.accuracyAuthorization == .reducedAccuracy {
            let infoDict = Bundle.main.infoDictionary
            let tempUsageDict = infoDict?["NSLocationTemporaryUsageDescriptionDictionary"] as? [String: Any]

            if tempUsageDict?[Self.temporaryAccuracyPurposeKey] != nil {
                locationManager.requestTemporaryFullAccuracyAuthorization(withPurposeKey: Self.temporaryAccuracyPurposeKey) { [weak self] _ in
                    guard self != nil else { return }
                    result("granted")
                }
                return
            }
        }
        result("granted")
    }

    // MARK: - CLLocationManagerDelegate (Permissions)
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        handleAuthorizationChange(manager.authorizationStatus)
    }

    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        handleAuthorizationChange(status)
    }

    private func handleAuthorizationChange(_ status: CLAuthorizationStatus) {
        guard let result = pendingPermissionResult else { return }
        pendingPermissionResult = nil

        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            handleApproximateLocationCheck(result: result)
        case .denied, .restricted:
            result("permanently_denied")
        case .notDetermined:
            result("denied")
        @unknown default:
            result("denied")
        }
    }

    // MARK: - One-Shot Location Fix
    private func handleGetCurrentLocation(result: @escaping FlutterResult) {
        guard isLocationAuthorized else {
            result(FlutterError(code: "PERMISSION_DENIED", message: "Location permission not granted", details: nil))
            return
        }
        guard isGpsEnabled else {
            result(FlutterError(code: "SERVICES_DISABLED", message: "Device GPS is disabled", details: nil))
            return
        }

        // Return cached location if it is fresh (< 15 seconds) and valid
        if let cachedLocation = locationManager.location,
           cachedLocation.horizontalAccuracy >= 0,
           abs(cachedLocation.timestamp.timeIntervalSinceNow) < Self.freshLocationThresholdSeconds {
            result(buildLocationMap(from: cachedLocation))
            return
        }

        // Enqueue single location request
        pendingLocationRequests.append { [weak self] map, error in
            guard self != nil else { return }
            if let error = error {
                result(error)
            } else if let map = map {
                result(map)
            } else {
                result(FlutterError(code: "LOCATION_ERROR", message: "Unknown location error", details: nil))
            }
        }

        startSingleLocationRequestIfNeeded()
    }

    private func startSingleLocationRequestIfNeeded() {
        if singleLocationTimeoutTimer == nil {
            singleLocationTimeoutTimer = Timer.scheduledTimer(
                withTimeInterval: Self.locationTimeoutSeconds,
                repeats: false
            ) { [weak self] _ in
                self?.completePendingLocationRequests(
                    map: nil,
                    error: FlutterError(code: "TIMEOUT", message: "Location fix timed out", details: nil)
                )
            }

            locationManager.startUpdatingLocation()
            if CLLocationManager.headingAvailable() {
                locationManager.startUpdatingHeading()
            }
        }
    }

    private func completePendingLocationRequests(map: [String: Any]?, error: FlutterError?) {
        singleLocationTimeoutTimer?.invalidate()
        singleLocationTimeoutTimer = nil

        let requests = pendingLocationRequests
        pendingLocationRequests.removeAll()

        for request in requests {
            request(map, error)
        }

        if !isStreaming {
            locationManager.stopUpdatingLocation()
            if CLLocationManager.headingAvailable() {
                locationManager.stopUpdatingHeading()
            }
        }
    }

    // MARK: - Event Channel (Location Streaming)
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        guard isLocationAuthorized else {
            return FlutterError(code: "PERMISSION_DENIED", message: "Location permission not granted", details: nil)
        }
        guard isGpsEnabled else {
            return FlutterError(code: "SERVICES_DISABLED", message: "Device GPS is disabled", details: nil)
        }

        self.eventSink = events
        self.isStreaming = true

        // Emit cached location immediately if available
        if let cachedLocation = locationManager.location, cachedLocation.horizontalAccuracy >= 0 {
            events(buildLocationMap(from: cachedLocation))
        } else {
            // Start timeout timer for initial GPS fix acquisition.
            // If GPS is disabled or unavailable, emits an error after the timeout so the Flutter UI
            // transitions out of loading state and displays the manual pickup fallback panel.
            streamInitialFixTimer?.invalidate()
            streamInitialFixTimer = Timer.scheduledTimer(
                withTimeInterval: Self.streamInitialFixTimeoutSeconds,
                repeats: false
            ) { [weak self] _ in
                guard let self = self, self.isStreaming else { return }
                self.streamInitialFixTimer = nil
                self.eventSink?(FlutterError(
                    code: "SERVICES_DISABLED",
                    message: "Unable to acquire GPS fix. Tap map to select pickup manually.",
                    details: nil
                ))
            }
        }

        locationManager.startUpdatingLocation()
        if CLLocationManager.headingAvailable() {
            locationManager.startUpdatingHeading()
        }

        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        isStreaming = false
        eventSink = nil
        streamInitialFixTimer?.invalidate()
        streamInitialFixTimer = nil

        if pendingLocationRequests.isEmpty {
            locationManager.stopUpdatingLocation()
            if CLLocationManager.headingAvailable() {
                locationManager.stopUpdatingHeading()
            }
        }

        return nil
    }

    // MARK: - CLLocationManagerDelegate (Updates & Errors)
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Discard fixes with negative accuracy (indicates invalid fix)
        guard let validLocation = locations.last(where: { $0.horizontalAccuracy >= 0 }) else {
            return
        }

        streamInitialFixTimer?.invalidate()
        streamInitialFixTimer = nil

        let map = buildLocationMap(from: validLocation)

        // Complete pending one-shot requests
        if !pendingLocationRequests.isEmpty {
            completePendingLocationRequests(map: map, error: nil)
        }

        // Stream to EventChannel subscribers
        if isStreaming {
            eventSink?(map)
        }
    }

    public func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        currentHeading = newHeading
    }

    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let clError = error as? CLError
        if clError?.code == .denied {
            let flutterError = FlutterError(code: "PERMISSION_DENIED", message: "Location permission denied", details: nil)
            if !pendingLocationRequests.isEmpty {
                completePendingLocationRequests(map: nil, error: flutterError)
            }
            if isStreaming {
                eventSink?(flutterError)
            }
            return
        }

        // CoreLocation transiently reports kCLErrorLocationUnknown (error 0) while acquiring a fix.
        // Apple documentation explicitly advises ignoring this error because CoreLocation will keep trying:
        // "When this error occurs, you can simply wait for new events because the location manager continues trying."
        if clError?.code == .locationUnknown {
            return
        }

        let flutterError = FlutterError(code: "LOCATION_ERROR", message: error.localizedDescription, details: nil)
        if !pendingLocationRequests.isEmpty {
            completePendingLocationRequests(map: nil, error: flutterError)
        }
        if isStreaming {
            eventSink?(flutterError)
        }
    }

    // MARK: - App Settings
    private func handleOpenAppSettings(result: @escaping FlutterResult) {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString),
              UIApplication.shared.canOpenURL(settingsUrl) else {
            result(false)
            return
        }

        UIApplication.shared.open(settingsUrl, options: [:]) { success in
            result(success)
        }
    }

    // MARK: - Location Map Serialization
    /// Serializes CLLocation into the contract map expected by ModernLocate:
    /// - latitude: Double
    /// - longitude: Double
    /// - heading: Double (uses GPS course when moving, compass heading when stationary, or 0.0)
    /// - accuracy: Double (horizontalAccuracy in meters. If reducedAccuracy is active, iOS sets this
    ///   to ~1000m-5000m, which sensibly communicates the approximate boundary).
    private func buildLocationMap(from location: CLLocation) -> [String: Any] {
        var heading: Double = 0.0
        if location.course >= 0 {
            heading = location.course
        } else if let headingData = currentHeading {
            if headingData.trueHeading >= 0 {
                heading = headingData.trueHeading
            } else if headingData.magneticHeading >= 0 {
                heading = headingData.magneticHeading
            }
        }

        let accuracy = max(0.0, location.horizontalAccuracy)

        return [
            "latitude": location.coordinate.latitude,
            "longitude": location.coordinate.longitude,
            "heading": heading,
            "accuracy": accuracy
        ]
    }
}
