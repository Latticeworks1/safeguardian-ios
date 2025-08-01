import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
            
            MeshChatView()
                .tabItem {
                    Image(systemName: "message.fill")
                    Text("Mesh Chat")
                }
            
            AIGuideView()
                .tabItem {
                    Image(systemName: "brain.head.profile.fill")
                    Text("AI Guide")
                }
            
            SafetyMapView()
                .tabItem {
                    Image(systemName: "map.fill")
                    Text("Safety Map")
                }
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
        }
        .accentColor(.blue)
    }
}

#Preview {
    ContentView()
}
