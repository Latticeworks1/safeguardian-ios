import SwiftUI
import MapKit
import CoreLocation

// MARK: - Location Manager
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var userLocation: CLLocation?
    @Published var hasLocationPermission = false
    @Published var communityLocations: [CommunityLocation] = []
    @Published var emergencyServices: [EmergencyService] = []
    @Published var locationAccuracy: CLLocationAccuracy = kCLLocationAccuracyNearestTenMeters
    @Published var isMonitoringLocation = false
    
    // Battery optimization properties
    private var lastLocationUpdate: Date?
    private let minimumUpdateInterval: TimeInterval = 30 // 30 seconds minimum between updates
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    
    override init() {
        super.init()
        locationManager.delegate = self
        // Battery optimized accuracy - only use best accuracy when needed
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.distanceFilter = 50 // Only update if user moves 50 meters
        checkLocationPermission()
        loadCommunityLocations()
        loadEmergencyServices()
        setupLocationOptimization()
    }
    
    func requestLocationPermission() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            hasLocationPermission = false
        case .authorizedWhenInUse, .authorizedAlways:
            hasLocationPermission = true
            locationManager.startUpdatingLocation()
        @unknown default:
            break
        }
    }
    
    private func checkLocationPermission() {
        hasLocationPermission = locationManager.authorizationStatus == .authorizedWhenInUse ||
                               locationManager.authorizationStatus == .authorizedAlways
    }
    
    private func loadCommunityLocations() {
        // Sample community locations - in real app would load from server/mesh network
        communityLocations = [
            CommunityLocation(
                name: "Community Library",
                type: nil,
                latitude: 37.7849,
                longitude: -122.4094,
                safetyRating: 4,
                lastUpdate: Date()
            ),
            CommunityLocation(
                name: "Central Park",
                type: nil,
                latitude: 37.7649,
                longitude: -122.4294,
                safetyRating: 3,
                lastUpdate: Date()
            ),
            CommunityLocation(
                name: "Safety Hub",
                type: .safetyHub,
                latitude: 37.7749,
                longitude: -122.4194,
                safetyRating: 5,
                lastUpdate: Date()
            )
        ]
    }
    
    private func loadEmergencyServices() {
        // Emergency services locations - would be loaded from local database
        emergencyServices = [
            EmergencyService(
                name: "SF General Hospital",
                type: .hospital,
                latitude: 37.7621,
                longitude: -122.4324,
                distance: 0.5,
                isOpen: true
            ),
            EmergencyService(
                name: "Mission Police Station",
                type: .police,
                latitude: 37.7687,
                longitude: -122.4252,
                distance: 0.3,
                isOpen: true
            ),
            EmergencyService(
                name: "Fire Station 7",
                type: .fireStation,
                latitude: 37.7531,
                longitude: -122.4183,
                distance: 0.7,
                isOpen: true
            )
        ]
    }
    
    private func setupLocationOptimization() {
        // Configure for battery optimization
        locationManager.pausesLocationUpdatesAutomatically = true
        locationManager.allowsBackgroundLocationUpdates = false
        
        // Setup app lifecycle notifications for battery optimization
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // Battery optimization: throttle location updates
        if let lastUpdate = lastLocationUpdate,
           Date().timeIntervalSince(lastUpdate) < minimumUpdateInterval {
            return
        }
        
        userLocation = location
        lastLocationUpdate = Date()
        
        // Check if user is near emergency services (geofencing-like behavior)
        checkProximityToEmergencyServices(location)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        checkLocationPermission()
        if hasLocationPermission {
            startLocationUpdates()
        } else {
            stopLocationUpdates()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error.localizedDescription)")
        // Handle location errors gracefully
        if (error as? CLError)?.code == .denied {
            hasLocationPermission = false
        }
    }
    
    // MARK: - Battery Optimization Methods
    
    private func startLocationUpdates() {
        guard hasLocationPermission else { return }
        locationManager.startUpdatingLocation()
        isMonitoringLocation = true
    }
    
    private func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
        isMonitoringLocation = false
    }
    
    @objc private func appDidEnterBackground() {
        // Reduce location accuracy when app goes to background
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        locationManager.distanceFilter = 500 // Only update if user moves 500 meters
    }
    
    @objc private func appWillEnterForeground() {
        // Restore normal accuracy when app becomes active
        locationManager.desiredAccuracy = locationAccuracy
        locationManager.distanceFilter = 50
    }
    
    // MARK: - Safety Features
    
    private func checkProximityToEmergencyServices(_ location: CLLocation) {
        for service in emergencyServices {
            let serviceLocation = CLLocation(latitude: service.latitude, longitude: service.longitude)
            let distance = location.distance(from: serviceLocation)
            
            // If within 200 meters of emergency service, could trigger local notification
            if distance < 200 {
                // In a real app, this could show emergency service info
                print("Near emergency service: \(service.name)")
            }
        }
    }
    
    func requestHighAccuracyLocation() {
        // Temporarily use high accuracy for emergency situations
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationAccuracy = kCLLocationAccuracyBest
        
        // Revert to battery-optimized settings after 5 minutes
        DispatchQueue.main.asyncAfter(deadline: .now() + 300) {
            self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            self.locationManager.distanceFilter = 50
            self.locationAccuracy = kCLLocationAccuracyNearestTenMeters
        }
    }
    
    func findNearestEmergencyService(of type: EmergencyServiceType) -> EmergencyService? {
        guard let userLocation = userLocation else { return nil }
        
        return emergencyServices
            .filter { $0.type == type }
            .min { service1, service2 in
                let location1 = CLLocation(latitude: service1.latitude, longitude: service1.longitude)
                let location2 = CLLocation(latitude: service2.latitude, longitude: service2.longitude)
                return userLocation.distance(from: location1) < userLocation.distance(from: location2)
            }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Community Annotation View
struct CommunityAnnotationView: View {
    let location: CommunityLocation
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                // Safety pulse animation for safety hubs
                if location.type == .safetyHub {
                    Circle()
                        .stroke(location.type?.color ?? .gray, lineWidth: 2)
                        .frame(width: 44, height: 44)
                        .scaleEffect(isAnimating ? 1.5 : 1.0)
                        .opacity(isAnimating ? 0 : 0.8)
                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: false), value: isAnimating)
                }
                
                Image(systemName: location.type?.icon ?? "questionmark.circle")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background((location.type?.color ?? .gray).gradient, in: Circle())
                    .overlay(
                        Circle()
                            .stroke(.white, lineWidth: 2)
                    )
                    .shadow(color: (location.type?.color ?? .gray).opacity(0.3), radius: 4)
            }
            
            Text(location.name)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.primary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(.regularMaterial, in: Capsule())
                .shadow(color: .black.opacity(0.1), radius: 2)
        }
        .onAppear {
            if location.type == .safetyHub {
                isAnimating = true
            }
        }
    }
}

// MARK: - Emergency Service Annotation View
struct EmergencyServiceAnnotationView: View {
    let service: EmergencyService
    @State private var isPulsing = false
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                // Emergency pulse animation
                Circle()
                    .stroke(service.type.color, lineWidth: 3)
                    .frame(width: 50, height: 50)
                    .scaleEffect(isPulsing ? 1.8 : 1.0)
                    .opacity(isPulsing ? 0 : 1.0)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false), value: isPulsing)
                
                Image(systemName: service.type.icon)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(service.type.color.gradient, in: Circle())
                    .overlay(
                        Circle()
                            .stroke(.white, lineWidth: 3)
                    )
                    .shadow(color: service.type.color.opacity(0.5), radius: 6)
            }
            
            VStack(spacing: 2) {
                Text(service.type.displayName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
                
                if service.distance != nil {
                    Text(service.distanceString())
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                if service.isOpen {
                    Text("24/7")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.green)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(.green.opacity(0.2), in: Capsule())
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
            .shadow(color: .black.opacity(0.1), radius: 3)
        }
        .onAppear {
            isPulsing = true
        }
    }
}

// MARK: - Location Permission Card
struct LocationPermissionCard: View {
    let onDismiss: () -> Void
    @State private var showingPrivacyDetails = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Header with safety-focused icon
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(.blue.opacity(0.2))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "shield.lefthalf.filled.badge.checkmark")
                        .font(.system(size: 28))
                        .foregroundStyle(.blue)
                }
                
                VStack(spacing: 8) {
                    Text("Enable Safe Navigation")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)
                    
                    Text("SafeGuardian uses your location to:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            // Safety benefits list
            VStack(spacing: 12) {
                SafetyFeatureRow(
                    icon: "cross.case.fill",
                    title: "Find Emergency Services",
                    description: "Locate nearby hospitals, police, and fire stations"
                )
                
                SafetyFeatureRow(
                    icon: "person.3.fill", 
                    title: "Connect with Community",
                    description: "Discover safe spaces and community hubs"
                )
                
                SafetyFeatureRow(
                    icon: "shield.checkered",
                    title: "Privacy-First Design",
                    description: "Your location is never shared without permission"
                )
            }
            .padding(.vertical, 8)
            
            // Privacy toggle
            Button(action: { showingPrivacyDetails.toggle() }) {
                HStack {
                    Image(systemName: "info.circle")
                        .font(.caption)
                    Text("Privacy Details")
                        .font(.caption.weight(.medium))
                    Image(systemName: showingPrivacyDetails ? "chevron.up" : "chevron.down")
                        .font(.caption2)
                }
                .foregroundStyle(.secondary)
            }
            
            if showingPrivacyDetails {
                VStack(spacing: 8) {
                    Text("Your Privacy Matters")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.primary)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        PrivacyBulletPoint("Location data stays on your device")
                        PrivacyBulletPoint("No tracking or data collection")
                        PrivacyBulletPoint("Only used for safety features")
                        PrivacyBulletPoint("Can be disabled anytime in Settings")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(12)
                .background(.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            // Action buttons
            HStack(spacing: 12) {
                Button("Not Now", action: onDismiss)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(.secondary.opacity(0.2), in: Capsule())
                
                Button("Enable Location") {
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsUrl)
                    }
                    onDismiss()
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [.blue, .blue.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: Capsule()
                )
                .shadow(color: .blue.opacity(0.3), radius: 4, y: 2)
            }
        }
        .padding(24)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.1), radius: 20, y: 10)
        .animation(.easeInOut(duration: 0.3), value: showingPrivacyDetails)
    }
}

// MARK: - Supporting Views for Permission Card

struct SafetyFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
        }
    }
}

struct PrivacyBulletPoint: View {
    let text: String
    
    init(_ text: String) {
        self.text = text
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: "checkmark.circle.fill")
                .font(.caption2)
                .foregroundStyle(.green)
                .offset(y: 1)
            
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        // Community location preview
        CommunityAnnotationView(location: CommunityLocation(
            name: "Community Center",
            type: .safetyHub,
            latitude: 37.7749,
            longitude: -122.4194,
            safetyRating: 5,
            lastUpdate: Date()
        ))
        
        // Emergency service preview
        EmergencyServiceAnnotationView(service: EmergencyService(
            name: "General Hospital",
            type: .hospital,
            latitude: 37.7749,
            longitude: -122.4194,
            distance: 0.2,
            isOpen: true
        ))
        
        // Permission card preview
        LocationPermissionCard(onDismiss: {})
    }
    .padding()
}