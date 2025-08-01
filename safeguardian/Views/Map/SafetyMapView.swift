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
    
    var body: some View {
        NavigationView {
            ZStack {
                // Main Map
                ZStack {
                    Map(coordinateRegion: $region, showsUserLocation: true, annotationItems: emergencyServiceAnnotations) { annotation in
                        MapAnnotation(coordinate: annotation.coordinate) {
                            EmergencyServiceAnnotationView(service: annotation.service)
                                .onTapGesture {
                                    selectedEmergencyService = annotation.service
                                }
                        }
                    }
                    
                    Map(coordinateRegion: $region, showsUserLocation: false, annotationItems: communityLocationAnnotations) { annotation in
                        MapAnnotation(coordinate: annotation.coordinate) {
                            CommunityAnnotationView(location: annotation.location)
                        }
                    }
                    .allowsHitTesting(false) // Allow touches to pass through to emergency services
                }
                .ignoresSafeArea()
                .onAppear {
                    updateRegionForUserLocation()
                }
                .onChange(of: locationManager.userLocation) { _, location in
                    if let location = location {
                        region.center = location.coordinate
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
                                region.center = CLLocationCoordinate2D(
                                    latitude: nearestService.latitude,
                                    longitude: nearestService.longitude
                                )
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
        }
    }
    
    private func centerOnUserLocation() {
        if let userLocation = locationManager.userLocation {
            withAnimation(.easeInOut(duration: 1.0)) {
                region.center = userLocation.coordinate
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
            
            // Emergency Call Button
            Button(action: {
                if let url = URL(string: "tel://911") {
                    UIApplication.shared.open(url)
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "phone.fill")
                        .font(.system(size: 16, weight: .semibold))
                    
                    Text("Emergency Call 911")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(.red, in: RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
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
                    
                    ServiceDetailRow(
                        icon: "phone.fill",
                        title: "Emergency",
                        value: "911"
                    )
                }
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button("Call 911") {
                        if let url = URL(string: "tel://911") {
                            UIApplication.shared.open(url)
                        }
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(.red, in: RoundedRectangle(cornerRadius: 12))
                    
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