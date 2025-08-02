import SwiftUI

struct ContentView: View {
    @State private var isInitializing = true
    @StateObject private var globalMeshManager = SafeGuardianMeshManager()
    
    var body: some View {
        Group {
            if isInitializing {
                InitialLoadingState()
            } else {
                TabView {
                    MinimalHomeView(meshManager: globalMeshManager)
                        .tabItem {
                            Image(systemName: "house")
                            Text("Home")
                        }
                    
                    MinimalChatView(meshManager: globalMeshManager)
                        .tabItem {
                            Image(systemName: "message")
                            Text("Chat")
                        }
                    
                    MinimalAIView(meshManager: globalMeshManager)
                        .tabItem {
                            Image(systemName: "brain")
                            Text("AI")
                        }
                    
                    MinimalMapView(meshManager: globalMeshManager)
                        .tabItem {
                            Image(systemName: "map")
                            Text("Map")
                        }
                    
                    MinimalProfileView(meshManager: globalMeshManager)
                        .tabItem {
                            Image(systemName: "person")
                            Text("Profile")
                        }
                }
                .accentColor(.blue)
            }
        }
        .onAppear {
            // Simulate app initialization
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.2) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    isInitializing = false
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
