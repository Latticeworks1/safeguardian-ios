import SwiftUI
import LocalAuthentication

struct AuthenticationView: View {
    @StateObject private var authService = AuthenticationService()
    @State private var showingSignIn = false
    @State private var showingSignUp = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                // Logo and title
                VStack(spacing: 20) {
                    Image(systemName: "shield.checkered")
                        .font(.system(size: 80))
                        .foregroundStyle(.blue)
                    
                    VStack(spacing: 8) {
                        Text("SafeGuardian")
                            .font(.largeTitle.weight(.bold))
                        
                        Text("Community Safety Network")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.top, 60)
                
                // Features list
                VStack(spacing: 20) {
                    SafetyFeatureRow(
                        icon: "antenna.radiowaves.left.and.right",
                        title: "Mesh Network",
                        description: "Stay connected even without internet"
                    )
                    
                    SafetyFeatureRow(
                        icon: "location.circle",
                        title: "Safety Map",
                        description: "Find emergency services and safe locations"
                    )
                    
                    SafetyFeatureRow(
                        icon: "brain.head.profile",
                        title: "AI Safety Guide",
                        description: "Get intelligent emergency assistance"
                    )
                    
                    SafetyFeatureRow(
                        icon: "message.bubble",
                        title: "Community Chat",
                        description: "Coordinate with nearby neighbors"
                    )
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Authentication buttons
                VStack(spacing: 16) {
                    Button("Sign In") {
                        showingSignIn = true
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .frame(maxWidth: .infinity)
                    
                    Button("Create Account") {
                        showingSignUp = true
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingSignIn) {
            SignInView(authService: authService)
        }
        .sheet(isPresented: $showingSignUp) {
            SignUpView(authService: authService)
        }
    }
}

// MARK: - Sign In View
struct SignInView: View {
    @ObservedObject var authService: AuthenticationService
    @Environment(\.dismiss) private var dismiss
    
    @State private var email = ""
    @State private var password = ""
    @State private var showingPassword = false
    @FocusState private var emailFocused: Bool
    @FocusState private var passwordFocused: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.blue)
                    
                    VStack(spacing: 4) {
                        Text("Welcome Back")
                            .font(.title2.weight(.bold))
                        
                        Text("Sign in to access SafeGuardian")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.top, 32)
                
                // Sign in form
                VStack(spacing: 20) {
                    // Email field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.primary)
                        
                        TextField("Enter your email", text: $email)
                            .textFieldStyle(SafeGuardianTextFieldStyle())
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .autocapitalization(.none)
                            .focused($emailFocused)
                    }
                    
                    // Password field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.primary)
                        
                        HStack {
                            Group {
                                if showingPassword {
                                    TextField("Enter your password", text: $password)
                                } else {
                                    SecureField("Enter your password", text: $password)
                                }
                            }
                            .textContentType(.password)
                            .focused($passwordFocused)
                            
                            Button(action: { showingPassword.toggle() }) {
                                Image(systemName: showingPassword ? "eye.slash" : "eye")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding()
                        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(.quaternary, lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal)
                
                // Sign in button
                Button(action: signIn) {
                    HStack {
                        if authService.isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(.white)
                        } else {
                            Text("Sign In")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        canSignIn ? .blue : .gray.opacity(0.3),
                        in: RoundedRectangle(cornerRadius: 12)
                    )
                    .foregroundStyle(.white)
                }
                .disabled(!canSignIn || authService.isLoading)
                .padding(.horizontal)
                .padding(.top)
                
                // Error message
                if case .error(let errorMessage) = authService.authState {
                    Text(errorMessage)
                        .font(.callout)
                        .foregroundStyle(.red)
                        .padding(.horizontal)
                }
                
                Spacer()
                
                // Biometric sign in
                if authService.biometricAuthAvailable {
                    VStack(spacing: 16) {
                        HStack {
                            VStack { Divider() }
                            Text("or")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                            VStack { Divider() }
                        }
                        
                        BiometricSignInButton(authService: authService)
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .navigationTitle("Sign In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var canSignIn: Bool {
        !email.isEmpty && !password.isEmpty
    }
    
    private func signIn() {
        Task {
            await authService.signIn(email: email, password: password)
            if case .authenticated = authService.authState {
                dismiss()
            }
        }
    }
}

// MARK: - Sign Up View
struct SignUpView: View {
    @ObservedObject var authService: AuthenticationService
    @Environment(\.dismiss) private var dismiss
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var displayName = ""
    @State private var showingPassword = false
    @State private var agreeToTerms = false
    
    @FocusState private var focusedField: SignUpField?
    
    enum SignUpField {
        case displayName, email, password, confirmPassword
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "person.badge.plus.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.blue)
                        
                        VStack(spacing: 4) {
                            Text("Join SafeGuardian")
                                .font(.title2.weight(.bold))
                            
                            Text("Create your safety network account")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.top, 32)
                    
                    // Sign up form
                    VStack(spacing: 20) {
                        // Display name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Display Name")
                                .font(.subheadline.weight(.medium))
                            
                            TextField("Your name", text: $displayName)
                                .textFieldStyle(SafeGuardianTextFieldStyle())
                                .textContentType(.name)
                                .focused($focusedField, equals: .displayName)
                        }
                        
                        // Email
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.subheadline.weight(.medium))
                            
                            TextField("Enter your email", text: $email)
                                .textFieldStyle(SafeGuardianTextFieldStyle())
                                .keyboardType(.emailAddress)
                                .textContentType(.emailAddress)
                                .autocapitalization(.none)
                                .focused($focusedField, equals: .email)
                        }
                        
                        // Password
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.subheadline.weight(.medium))
                            
                            HStack {
                                Group {
                                    if showingPassword {
                                        TextField("Create a password", text: $password)
                                    } else {
                                        SecureField("Create a password", text: $password)
                                    }
                                }
                                .textContentType(.newPassword)
                                .focused($focusedField, equals: .password)
                                
                                Button(action: { showingPassword.toggle() }) {
                                    Image(systemName: showingPassword ? "eye.slash" : "eye")
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding()
                            .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(passwordStrengthColor, lineWidth: 1)
                            )
                            
                            // Password strength indicator
                            if !password.isEmpty {
                                PasswordStrengthIndicator(password: password)
                            }
                        }
                        
                        // Confirm password
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Confirm Password")
                                .font(.subheadline.weight(.medium))
                            
                            SecureField("Confirm your password", text: $confirmPassword)
                                .textFieldStyle(SafeGuardianTextFieldStyle())
                                .textContentType(.newPassword)
                                .focused($focusedField, equals: .confirmPassword)
                            
                            if !confirmPassword.isEmpty && password != confirmPassword {
                                Text("Passwords don't match")
                                    .font(.caption)
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Terms agreement
                    VStack(spacing: 16) {
                        HStack(alignment: .top, spacing: 12) {
                            Button(action: { agreeToTerms.toggle() }) {
                                Image(systemName: agreeToTerms ? "checkmark.square.fill" : "square")
                                    .font(.title3)
                                    .foregroundStyle(agreeToTerms ? .blue : .secondary)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("I agree to the Terms of Service and Privacy Policy")
                                    .font(.callout)
                                
                                Text("SafeGuardian uses mesh networking for emergency communication. Your safety data stays on your device.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal)
                        
                        // Create account button
                        Button(action: signUp) {
                            HStack {
                                if authService.isLoading {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .tint(.white)
                                } else {
                                    Text("Create Account")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                canSignUp ? .blue : .gray.opacity(0.3),
                                in: RoundedRectangle(cornerRadius: 12)
                            )
                            .foregroundStyle(.white)
                        }
                        .disabled(!canSignUp || authService.isLoading)
                        .padding(.horizontal)
                    }
                    
                    // Error message
                    if case .error(let errorMessage) = authService.authState {
                        Text(errorMessage)
                            .font(.callout)
                            .foregroundStyle(.red)
                            .padding(.horizontal)
                    }
                    
                    Spacer(minLength: 40)
                }
            }
            .navigationTitle("Sign Up")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var canSignUp: Bool {
        !email.isEmpty && 
        !password.isEmpty && 
        !displayName.isEmpty && 
        password == confirmPassword && 
        password.count >= 8 && 
        agreeToTerms
    }
    
    private var passwordStrengthColor: Color {
        let strength = passwordStrength(password)
        switch strength {
        case .weak: return .red
        case .medium: return .orange
        case .strong: return .green
        }
    }
    
    private func signUp() {
        Task {
            await authService.signUp(email: email, password: password, displayName: displayName)
            if case .authenticated = authService.authState {
                dismiss()
            }
        }
    }
}

// MARK: - Supporting Views

struct SafetyFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
    }
}

struct BiometricSignInButton: View {
    @ObservedObject var authService: AuthenticationService
    
    var body: some View {
        Button(action: { 
            Task {
                await authService.signInWithBiometrics()
            }
        }) {
            HStack {
                Image(systemName: authService.biometricType.icon)
                    .font(.title3)
                Text("Sign in with \(authService.biometricType.displayName)")
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(.quaternary.opacity(0.6), in: RoundedRectangle(cornerRadius: 12))
            .foregroundStyle(.primary)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.blue.opacity(0.3), lineWidth: 1)
            )
        }
        .disabled(authService.isLoading)
    }
}

struct SafeGuardianTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.quaternary, lineWidth: 1)
            )
    }
}

struct PasswordStrengthIndicator: View {
    let password: String
    
    private var strength: PasswordStrength {
        passwordStrength(password)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Rectangle()
                        .frame(height: 4)
                        .foregroundStyle(
                            index < strength.rawValue ? strength.color : .quaternary
                        )
                }
            }
            
            Text(strength.description)
                .font(.caption)
                .foregroundStyle(strength.color)
        }
    }
}

enum PasswordStrength: Int, CaseIterable {
    case weak = 1
    case medium = 2
    case strong = 3
    
    var color: Color {
        switch self {
        case .weak: return .red
        case .medium: return .orange
        case .strong: return .green
        }
    }
    
    var description: String {
        switch self {
        case .weak: return "Weak password"
        case .medium: return "Medium strength"
        case .strong: return "Strong password"
        }
    }
}

func passwordStrength(_ password: String) -> PasswordStrength {
    var score = 0
    
    if password.count >= 8 { score += 1 }
    if password.rangeOfCharacter(from: .uppercaseLetters) != nil { score += 1 }
    if password.rangeOfCharacter(from: .lowercaseLetters) != nil { score += 1 }
    if password.rangeOfCharacter(from: .decimalDigits) != nil { score += 1 }
    if password.rangeOfCharacter(from: CharacterSet(charactersIn: "!@#$%^&*")) != nil { score += 1 }
    
    switch score {
    case 0...2: return .weak
    case 3...4: return .medium
    default: return .strong
    }
}

#Preview {
    AuthenticationView()
}