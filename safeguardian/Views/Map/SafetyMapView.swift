import SwiftUI
import MapKit

struct SafetyMapView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var meshManager = SafeGuardianMeshManager()
    @State private var showingPermissionCard = false
    @State private var selectedEmergencyService: EmergencyService?
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), // San Francisco
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var cameraPosition = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    )
    
    var body: some View {
        NavigationView {
            ZStack {
                // Main Map with Modern MapContentBuilder
                Map(position: $cameraPosition) {
                    // Emergency Service Annotations
                    ForEach(emergencyServiceAnnotations) { annotation in
                        Annotation(annotation.service.name, coordinate: annotation.coordinate) {
                            EmergencyServiceAnnotationView(service: annotation.service)
                                .onTapGesture {
                                    selectedEmergencyService = annotation.service
                                }
                        }
                    }
                    
                    // Community Location Annotations  
                    ForEach(communityLocationAnnotations) { annotation in
                        Annotation(annotation.location.name, coordinate: annotation.coordinate) {
                            CommunityAnnotationView(location: annotation.location)
                        }
                    }
                    
                    // User Location (built-in)
                    UserAnnotation()
                }
                .mapControlVisibility(.hidden)
                .ignoresSafeArea()
                .onAppear {
                    updateRegionForUserLocation()
                }
                .onChange(of: locationManager.userLocation) { _, location in
                    if let location = location {
                        region.center = location.coordinate
                        cameraPosition = .region(region)
                    }
                }
                
                // Overlay Controls
                VStack {
                    // Top Status Bar
                    SafetyMapStatusBar(
                        locationManager: locationManager,
                        meshManager: meshManager,
                        onLocationPermissionTap: { 
                            if !locationManager.hasLocationPermission {
                                showingPermissionCard = true
                            }
                        }
                    )
                    
                    Spacer()
                    
                    // Bottom Action Cards
                    SafetyMapBottomActions(
                        locationManager: locationManager,
                        onEmergencyAction: { serviceType in
                            if let nearestService = locationManager.findNearestEmergencyService(of: serviceType) {
                                selectedEmergencyService = nearestService
                                // Center map on service
                                let serviceCoordinate = CLLocationCoordinate2D(
                                    latitude: nearestService.latitude,
                                    longitude: nearestService.longitude
                                )
                                region.center = serviceCoordinate
                                cameraPosition = .region(region)
                            }
                        }
                    )
                }
                
                // Location Permission Overlay
                if !locationManager.hasLocationPermission && showingPermissionCard {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture {
                            showingPermissionCard = false
                        }
                    
                    LocationPermissionCard {
                        showingPermissionCard = false
                    }
                    .padding()
                }
            }
            .navigationTitle("Safety Map")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: centerOnUserLocation) {
                        Image(systemName: "location.fill")
                            .foregroundStyle(locationManager.hasLocationPermission ? .blue : .gray)
                    }
                    .disabled(!locationManager.hasLocationPermission)
                }
            }
        }
        .sheet(item: $selectedEmergencyService) { service in
            EmergencyServiceDetailView(service: service)
        }
        .onAppear {
            if !locationManager.hasLocationPermission {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    showingPermissionCard = true
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private var emergencyServiceAnnotations: [EmergencyServiceAnnotation] {
        locationManager.emergencyServices.map { service in
            EmergencyServiceAnnotation(service: service)
        }
    }
    
    private var communityLocationAnnotations: [CommunityLocationAnnotation] {
        locationManager.communityLocations.map { location in
            CommunityLocationAnnotation(location: location)
        }
    }
    
    private func updateRegionForUserLocation() {
        if let userLocation = locationManager.userLocation {
            region.center = userLocation.coordinate
            cameraPosition = .region(region)
        }
    }
    
    private func centerOnUserLocation() {
        if let userLocation = locationManager.userLocation {
            withAnimation(.easeInOut(duration: 1.0)) {
                region.center = userLocation.coordinate
                cameraPosition = .region(region)
            }
        } else {
            locationManager.requestLocationPermission()
        }
    }
}

// MARK: - Map Annotation Protocol
protocol MapAnnotationProtocol: Identifiable {
    var coordinate: CLLocationCoordinate2D { get }
}

// MARK: - Emergency Service Annotation
struct EmergencyServiceAnnotation: MapAnnotationProtocol {
    let service: EmergencyService
    
    var id: String { service.id.uuidString }
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: service.latitude, longitude: service.longitude)
    }
}

// MARK: - Community Location Annotation  
struct CommunityLocationAnnotation: MapAnnotationProtocol {
    let location: CommunityLocation
    
    var id: String { location.id.uuidString }
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
    }
}

// MARK: - Safety Map Status Bar
struct SafetyMapStatusBar: View {
    @ObservedObject var locationManager: LocationManager
    @ObservedObject var meshManager: SafeGuardianMeshManager
    let onLocationPermissionTap: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Location Status
            Button(action: onLocationPermissionTap) {
                HStack(spacing: 6) {
                    Image(systemName: locationManager.hasLocationPermission ? "location.fill" : "location.slash")
                        .font(.caption)
                        .foregroundStyle(locationManager.hasLocationPermission ? .green : .red)
                    
                    Text(locationManager.hasLocationPermission ? "Location Active" : "Location Disabled")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.primary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.regularMaterial, in: Capsule())
            }
            .buttonStyle(.plain)
            
            // Mesh Network Status
            HStack(spacing: 6) {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.caption)
                    .foregroundStyle(meshManager.isConnected ? .blue : .orange)
                
                Text(meshManager.isConnected ? "\(meshManager.connectedPeers.count) nearby" : "Searching")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.primary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.regularMaterial, in: Capsule())
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - Safety Map Bottom Actions
struct SafetyMapBottomActions: View {
    @ObservedObject var locationManager: LocationManager
    let onEmergencyAction: (EmergencyServiceType) -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // Emergency Service Quick Access
            HStack(spacing: 12) {
                EmergencyQuickActionButton(
                    serviceType: .hospital,
                    icon: "cross.fill",
                    title: "Hospital",
                    color: .red,
                    onTap: { onEmergencyAction(.hospital) }
                )
                
                EmergencyQuickActionButton(
                    serviceType: .police,
                    icon: "person.badge.shield.checkmark",
                    title: "Police",
                    color: .blue,
                    onTap: { onEmergencyAction(.police) }
                )
                
                EmergencyQuickActionButton(
                    serviceType: .fireStation,
                    icon: "flame.fill",
                    title: "Fire Dept",
                    color: .orange,
                    onTap: { onEmergencyAction(.fireStation) }
                )
            }
        }
        .padding()
    }
}

// MARK: - Emergency Quick Action Button
struct EmergencyQuickActionButton: View {
    let serviceType: EmergencyServiceType
    let icon: String
    let title: String
    let color: Color
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(color.gradient, in: Circle())
                
                Text(title)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Emergency Service Detail View
struct EmergencyServiceDetailView: View {
    let service: EmergencyService
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Service Header
                VStack(spacing: 12) {
                    Image(systemName: service.type.icon)
                        .font(.system(size: 50))
                        .foregroundStyle(.white)
                        .frame(width: 80, height: 80)
                        .background(service.type.color.gradient, in: Circle())
                    
                    Text(service.name)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)
                    
                    Text(service.type.displayName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                // Service Details
                VStack(spacing: 16) {
                    ServiceDetailRow(
                        icon: "location.fill",
                        title: "Distance",
                        value: service.distanceString()
                    )
                    
                    ServiceDetailRow(
                        icon: "clock.fill",
                        title: "Status",
                        value: service.isOpen ? "Open 24/7" : "Closed"
                    )
                    
                }
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button("Get Directions") {
                        let coordinate = CLLocationCoordinate2D(latitude: service.latitude, longitude: service.longitude)
                        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
                        mapItem.name = service.name
                        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding()
            .navigationTitle("Emergency Service")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Minimal Map View
struct MinimalMapView: View {
    @ObservedObject var meshManager: SafeGuardianMeshManager
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    var body: some View {
        VStack(spacing: 0) {
            // Minimal header
            MinimalTopHeader(title: "Map", meshManager: meshManager)
            
            // Simple map with modern syntax
            Map(position: .constant(MapCameraPosition.region(region))) {
                UserAnnotation()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color(.systemBackground))
    }
}

// MARK: - Minimal Profile View  
struct MinimalProfileView: View {
    @ObservedObject var meshManager: SafeGuardianMeshManager
    @State private var userProfile = UserProfile.sample
    
    var body: some View {
        VStack(spacing: 0) {
            // Minimal header
            MinimalTopHeader(title: "Profile", meshManager: meshManager)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Profile info
                    MinimalProfileCard(profile: userProfile)
                    
                    // Connection status
                    MinimalConnectionCard(meshManager: meshManager)
                    
                    // Settings
                    MinimalSettingsSection()
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
        }
        .background(Color(.systemBackground))
    }
}

// MARK: - Minimal Profile Card
struct MinimalProfileCard: View {
    let profile: UserProfile
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(.blue.opacity(0.1))
                .frame(width: 50, height: 50)
                .overlay {
                    Text(String(profile.nickname.prefix(1)))
                        .font(.system(size: 20, weight: .medium, design: .rounded))
                        .foregroundStyle(.blue)
                }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(profile.nickname)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(.primary)
                
                Text("SafeGuardian User")
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(16)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - Minimal Connection Card
struct MinimalConnectionCard: View {
    @ObservedObject var meshManager: SafeGuardianMeshManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Connection")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
            
            HStack {
                Circle()
                    .fill(meshManager.isConnected ? .blue : .gray.opacity(0.5))
                    .frame(width: 8, height: 8)
                
                Text(meshManager.isConnected ? "Connected" : "Offline")
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundStyle(.primary)
                
                Spacer()
                
                if meshManager.isConnected {
                    Text("\(meshManager.connectedPeers.count) peers")
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(16)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - Minimal Settings Section
struct MinimalSettingsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Settings")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
            
            VStack(spacing: 0) {
                MinimalSettingRow(title: "Notifications", icon: "bell")
                MinimalSettingRow(title: "Privacy", icon: "lock")
                MinimalSettingRow(title: "About", icon: "info.circle")
            }
        }
        .padding(16)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - Minimal Setting Row
struct MinimalSettingRow: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
                .frame(width: 20)
            
            Text(title)
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundStyle(.primary)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .onTapGesture {
            // Handle setting tap
        }
    }
}

// MARK: - Service Detail Row
struct ServiceDetailRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(.blue)
                .frame(width: 20)
            
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.primary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    SafetyMapView()
}