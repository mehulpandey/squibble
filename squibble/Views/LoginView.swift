//
//  LoginView.swift
//  squibble
//
//  Login screen with Email, Apple, and Google sign-in options
//

import SwiftUI
import AuthenticationServices
import GoogleSignIn

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var userManager: UserManager

    @State private var isSigningIn = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0
    @State private var buttonsOffset: CGFloat = 30
    @State private var buttonsOpacity: Double = 0
    @State private var showEmailAuth = false
    var body: some View {
        ZStack {
            // Dark ambient background
            AmbientBackground()

            VStack(spacing: 0) {
                Spacer()

                // Logo and branding
                VStack(spacing: 20) {
                    // App logo
                    Image("Logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 140, height: 140)
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)
                        .shadow(color: AppTheme.primaryGlow, radius: 20, x: 0, y: 8)

                    Text("Squibble")
                        .font(.custom("Avenir-Black", size: 40))
                        .foregroundColor(AppTheme.textPrimary)
                        .tracking(-0.5)
                        .opacity(logoOpacity)
                }

                Spacer()

                // Sign in buttons
                VStack(spacing: 12) {
                    // Sign in with Email - Primary CTA
                    Button(action: { showEmailAuth = true }) {
                        HStack(spacing: 12) {
                            Image(systemName: "envelope.fill")
                                .font(.system(size: 18, weight: .semibold))
                            Text("Continue with Email")
                                .font(.custom("Avenir-Heavy", size: 17))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(AppTheme.primaryGradient)
                        .cornerRadius(16)
                        .shadow(color: AppTheme.primaryGlow, radius: 12, x: 0, y: 6)
                    }
                    .disabled(isSigningIn)

                    // Divider
                    HStack(spacing: 16) {
                        Rectangle()
                            .fill(AppTheme.divider)
                            .frame(height: 1)
                        Text("or")
                            .font(.custom("Avenir-Medium", size: 14))
                            .foregroundColor(AppTheme.textSecondary)
                        Rectangle()
                            .fill(AppTheme.divider)
                            .frame(height: 1)
                    }
                    .padding(.vertical, 6)

                    // Sign in with Apple
                    SignInWithAppleButton(
                        onRequest: configureAppleSignIn,
                        onCompletion: handleAppleSignIn
                    )
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 56)
                    .cornerRadius(16)

                    // Sign in with Google
                    Button(action: handleGoogleSignIn) {
                        HStack(spacing: 12) {
                            Image(systemName: "g.circle.fill")
                                .font(.system(size: 20, weight: .semibold))
                            Text("Sign in with Google")
                                .font(.custom("Avenir-Heavy", size: 17))
                        }
                        .foregroundColor(AppTheme.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(AppTheme.glassBackgroundStrong)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(AppTheme.glassBorder, lineWidth: 1)
                        )
                        .cornerRadius(16)
                    }
                    .disabled(isSigningIn)
                }
                .padding(.horizontal, 28)
                .offset(y: buttonsOffset)
                .opacity(buttonsOpacity)

                Spacer()
                    .frame(height: 28)

                // Terms and Privacy
                VStack(spacing: 6) {
                    Text("By continuing, you agree to our")
                        .font(.custom("Avenir-Regular", size: 13))
                        .foregroundColor(AppTheme.textSecondary)

                    HStack(spacing: 4) {
                        Button("Terms of Service") {
                            if let url = URL(string: "https://mehulpandey.github.io/squibble-legal/terms-of-service") {
                                UIApplication.shared.open(url)
                            }
                        }
                        .font(.custom("Avenir-Medium", size: 13))
                        .foregroundColor(AppTheme.primaryStart)

                        Text("and")
                            .font(.custom("Avenir-Regular", size: 13))
                            .foregroundColor(AppTheme.textSecondary)

                        Button("Privacy Policy") {
                            if let url = URL(string: "https://mehulpandey.github.io/squibble-legal/privacy-policy") {
                                UIApplication.shared.open(url)
                            }
                        }
                        .font(.custom("Avenir-Medium", size: 13))
                        .foregroundColor(AppTheme.primaryStart)
                    }
                }
                .opacity(buttonsOpacity)
                .padding(.bottom, 32)
            }

            // Loading overlay
            if isSigningIn {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()

                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
            }
        }
        .alert("Sign In Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: $showEmailAuth) {
            EmailAuthView(isSigningIn: $isSigningIn)
                .environmentObject(authManager)
                .environmentObject(userManager)
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.1)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.4)) {
                buttonsOffset = 0
                buttonsOpacity = 1.0
            }
        }
    }

    // MARK: - Apple Sign-In

    private func configureAppleSignIn(_ request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.fullName, .email]
    }

    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let identityToken = credential.identityToken,
                  let tokenString = String(data: identityToken, encoding: .utf8) else {
                showError(message: "Failed to get Apple credentials")
                return
            }

            Task {
                await signInWithApple(
                    idToken: tokenString,
                    fullName: credential.fullName
                )
            }

        case .failure(let error):
            // Don't show error for user cancellation
            if (error as NSError).code != ASAuthorizationError.canceled.rawValue {
                showError(message: error.localizedDescription)
            }
        }
    }

    private func signInWithApple(idToken: String, fullName: PersonNameComponents?) async {
        isSigningIn = true
        defer { isSigningIn = false }

        do {
            // Note: nonce would be generated and verified in production
            try await authManager.signInWithApple(idToken: idToken, nonce: "")

            // Check if user profile exists, create if first time
            if let userID = authManager.currentUserID {
                if let existingUser = try await SupabaseService.shared.getUser(id: userID) {
                    userManager.currentUser = existingUser
                } else {
                    // First time user - create profile
                    let displayName = formatDisplayName(from: fullName) ?? "Squibbler"
                    try await userManager.createUserProfile(id: userID, displayName: displayName)
                }
            }
        } catch {
            showError(message: "Sign in failed. Please try again.")
        }
    }

    // MARK: - Google Sign-In

    private func handleGoogleSignIn() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            showError(message: "Unable to find root view controller")
            return
        }

        isSigningIn = true

        GIDSignIn.sharedInstance.signIn(withPresenting: rootVC) { result, error in
            if let error = error {
                isSigningIn = false
                // Don't show error for user cancellation
                if (error as NSError).code != GIDSignInError.canceled.rawValue {
                    showError(message: "Google Sign-In failed. Please try again.")
                }
                return
            }

            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
                isSigningIn = false
                showError(message: "Failed to get Google credentials")
                return
            }

            let accessToken = user.accessToken.tokenString

            Task {
                await signInWithGoogle(idToken: idToken, accessToken: accessToken, displayName: user.profile?.name)
            }
        }
    }

    private func signInWithGoogle(idToken: String, accessToken: String, displayName: String?) async {
        defer { isSigningIn = false }

        do {
            try await authManager.signInWithGoogle(idToken: idToken, accessToken: accessToken)

            // Check if user profile exists, create if first time
            if let userID = authManager.currentUserID {
                if let existingUser = try await SupabaseService.shared.getUser(id: userID) {
                    userManager.currentUser = existingUser
                } else {
                    // First time user - create profile
                    let name = displayName ?? "Squibbler"
                    try await userManager.createUserProfile(id: userID, displayName: name)
                }
            }
        } catch {
            print("[LoginView] Google sign-in error: \(error)")
            showError(message: "Sign in failed. Please try again.")
        }
    }

    // MARK: - Helpers

    private func formatDisplayName(from name: PersonNameComponents?) -> String? {
        guard let name = name else { return nil }
        var components: [String] = []
        if let givenName = name.givenName { components.append(givenName) }
        if let familyName = name.familyName { components.append(familyName) }
        return components.isEmpty ? nil : components.joined(separator: " ")
    }

    private func showError(message: String) {
        errorMessage = message
        showError = true
    }
}

// MARK: - Email Auth View

struct EmailAuthView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var userManager: UserManager
    @Environment(\.dismiss) var dismiss

    @Binding var isSigningIn: Bool

    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var displayName = ""
    @State private var isSignUpMode = false
    @State private var showVerificationSent = false
    @State private var showPasswordReset = false
    @State private var showError = false
    @State private var errorMessage = ""
    @FocusState private var focusedField: Field?

    enum Field {
        case email, password, confirmPassword, displayName
    }

    var body: some View {
        NavigationView {
            ZStack {
                AmbientBackground()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 8) {
                            Text(isSignUpMode ? "Create Account" : "Welcome Back")
                                .font(.custom("Avenir-Heavy", size: 28))
                                .foregroundColor(AppTheme.textPrimary)

                            Text(isSignUpMode ? "Sign up to start doodling" : "Sign in to continue")
                                .font(.custom("Avenir-Regular", size: 16))
                                .foregroundColor(AppTheme.textSecondary)
                        }
                        .padding(.top, 20)

                        // Form fields
                        VStack(spacing: 16) {
                            if isSignUpMode {
                                DarkTextField(
                                    icon: "person.fill",
                                    placeholder: "Display Name",
                                    text: $displayName
                                )
                                .focused($focusedField, equals: .displayName)
                                .textContentType(.name)
                                .submitLabel(.next)
                            }

                            DarkTextField(
                                icon: "envelope.fill",
                                placeholder: "Email",
                                text: $email
                            )
                            .focused($focusedField, equals: .email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .submitLabel(.next)

                            // Email validation error
                            if isSignUpMode && !email.isEmpty && !isValidEmail(email) {
                                Text("Please enter a valid email address")
                                    .font(.custom("Avenir-Regular", size: 13))
                                    .foregroundColor(Color(hex: "FF6B54"))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.top, -8)
                            }

                            DarkSecureField(
                                icon: "lock.fill",
                                placeholder: "Password",
                                text: $password
                            )
                            .focused($focusedField, equals: .password)
                            .textContentType(isSignUpMode ? .newPassword : .password)
                            .submitLabel(isSignUpMode ? .next : .done)

                            if isSignUpMode {
                                DarkSecureField(
                                    icon: "lock.fill",
                                    placeholder: "Confirm Password",
                                    text: $confirmPassword
                                )
                                .focused($focusedField, equals: .confirmPassword)
                                .textContentType(.newPassword)
                                .submitLabel(.done)
                            }
                        }

                        // Forgot password (sign in mode only)
                        if !isSignUpMode {
                            HStack {
                                Spacer()
                                Button("Forgot Password?") {
                                    showPasswordReset = true
                                }
                                .font(.custom("Avenir-Medium", size: 14))
                                .foregroundColor(AppTheme.primaryStart)
                            }
                        }

                        // Submit button
                        Button(action: handleSubmit) {
                            HStack {
                                if isSigningIn {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text(isSignUpMode ? "Create Account" : "Sign In")
                                        .font(.custom("Avenir-Heavy", size: 17))
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(AppTheme.primaryGradient)
                            .cornerRadius(16)
                            .shadow(color: AppTheme.primaryGlow, radius: 10, x: 0, y: 4)
                        }
                        .disabled(isSigningIn || !isFormValid)
                        .opacity(isFormValid ? 1 : 0.6)

                        // Toggle sign up / sign in
                        HStack(spacing: 4) {
                            Text(isSignUpMode ? "Already have an account?" : "Don't have an account?")
                                .font(.custom("Avenir-Regular", size: 15))
                                .foregroundColor(AppTheme.textSecondary)

                            Button(isSignUpMode ? "Sign In" : "Sign Up") {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    isSignUpMode.toggle()
                                    clearForm()
                                }
                            }
                            .font(.custom("Avenir-Heavy", size: 15))
                            .foregroundColor(AppTheme.primaryStart)
                        }
                        .padding(.top, 8)

                        Spacer()
                    }
                    .padding(.horizontal, 24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppTheme.textPrimary)
                    }
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .alert("Check Your Email", isPresented: $showVerificationSent) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("We've sent a verification link to \(email). Please check your inbox and verify your email to continue.")
        }
        .sheet(isPresented: $showPasswordReset) {
            PasswordResetView()
                .environmentObject(authManager)
        }
    }

    private var isFormValid: Bool {
        if isSignUpMode {
            return !email.isEmpty &&
                   isValidEmail(email) &&
                   !password.isEmpty &&
                   !confirmPassword.isEmpty &&
                   !displayName.isEmpty &&
                   password == confirmPassword &&
                   password.count >= 6
        } else {
            return !email.isEmpty && !password.isEmpty
        }
    }

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return email.range(of: emailRegex, options: .regularExpression) != nil
    }

    private func handleSubmit() {
        focusedField = nil
        isSigningIn = true

        Task {
            do {
                if isSignUpMode {
                    try await authManager.signUpWithEmail(email: email, password: password)

                    // Create user profile if we got a session (email verification might be disabled)
                    if let userID = authManager.currentUserID {
                        try await userManager.createUserProfile(id: userID, displayName: displayName)
                        dismiss()
                    } else {
                        // Email verification required
                        showVerificationSent = true
                    }
                } else {
                    try await authManager.signInWithEmail(email: email, password: password)

                    // Load or create user profile
                    if let userID = authManager.currentUserID {
                        if let existingUser = try await SupabaseService.shared.getUser(id: userID) {
                            userManager.currentUser = existingUser
                        } else {
                            // User exists in auth but not in users table
                            try await userManager.createUserProfile(id: userID, displayName: email.components(separatedBy: "@").first ?? "Squibbler")
                        }
                    }
                    dismiss()
                }
            } catch {
                errorMessage = parseAuthError(error)
                showError = true
            }
            isSigningIn = false
        }
    }

    private func clearForm() {
        password = ""
        confirmPassword = ""
    }

    private func parseAuthError(_ error: Error) -> String {
        let message = error.localizedDescription.lowercased()
        if message.contains("invalid") || message.contains("credentials") {
            return "Invalid email or password. Please try again."
        } else if message.contains("email") && message.contains("confirm") {
            return "Please verify your email before signing in."
        } else if message.contains("already") || message.contains("exists") {
            return "An account with this email already exists."
        } else if message.contains("weak") {
            return "Password is too weak. Use at least 6 characters."
        }
        return "Something went wrong. Please try again."
    }
}

// MARK: - Password Reset View (OTP-based flow)

struct PasswordResetView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) var dismiss

    enum ResetStep {
        case enterEmail
        case enterCode
    }

    @State private var step: ResetStep = .enterEmail
    @State private var email = ""
    @State private var otpCode = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var showSuccess = false
    @State private var showError = false
    @State private var errorMessage = ""
    @FocusState private var focusedField: String?

    var body: some View {
        NavigationView {
            ZStack {
                AmbientBackground()

                ScrollView {
                    VStack(spacing: 24) {
                        if step == .enterEmail {
                            emailStepView
                        } else {
                            codeStepView
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: handleBack) {
                        Image(systemName: step == .enterEmail ? "xmark" : "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppTheme.textPrimary)
                    }
                }
            }
        }
        .alert("Password Updated", isPresented: $showSuccess) {
            Button("OK") { dismiss() }
        } message: {
            Text("Your password has been updated successfully. You can now sign in with your new password.")
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Step 1: Enter Email

    private var emailStepView: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Reset Password")
                    .font(.custom("Avenir-Heavy", size: 28))
                    .foregroundColor(AppTheme.textPrimary)

                Text("Enter your email and we'll send you a code")
                    .font(.custom("Avenir-Regular", size: 16))
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 20)

            DarkTextField(
                icon: "envelope.fill",
                placeholder: "Email",
                text: $email
            )
            .textContentType(.emailAddress)
            .keyboardType(.emailAddress)
            .textInputAutocapitalization(.never)
            .focused($focusedField, equals: "email")

            Button(action: handleSendCode) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Send Code")
                            .font(.custom("Avenir-Heavy", size: 17))
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(AppTheme.primaryGradient)
                .cornerRadius(16)
                .shadow(color: AppTheme.primaryGlow, radius: 10, x: 0, y: 4)
            }
            .disabled(isLoading || email.isEmpty)
            .opacity(email.isEmpty ? 0.6 : 1)
        }
    }

    // MARK: - Step 2: Enter Code + New Password

    private var codeStepView: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Enter Code")
                    .font(.custom("Avenir-Heavy", size: 28))
                    .foregroundColor(AppTheme.textPrimary)

                Text("We sent a code to \(email)")
                    .font(.custom("Avenir-Regular", size: 16))
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 20)

            // OTP Code Field
            DarkTextField(
                icon: "number",
                placeholder: "Enter code",
                text: $otpCode
            )
            .keyboardType(.numberPad)
            .focused($focusedField, equals: "otp")

            // New Password
            DarkSecureField(
                icon: "lock.fill",
                placeholder: "New Password",
                text: $newPassword
            )
            .textContentType(.newPassword)
            .focused($focusedField, equals: "password")

            // Confirm Password
            DarkSecureField(
                icon: "lock.fill",
                placeholder: "Confirm Password",
                text: $confirmPassword
            )
            .textContentType(.newPassword)
            .focused($focusedField, equals: "confirm")

            // Validation Messages
            if !newPassword.isEmpty && newPassword.count < 6 {
                Text("Password must be at least 6 characters")
                    .font(.custom("Avenir-Regular", size: 13))
                    .foregroundColor(Color(hex: "FF6B54"))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if !confirmPassword.isEmpty && newPassword != confirmPassword {
                Text("Passwords don't match")
                    .font(.custom("Avenir-Regular", size: 13))
                    .foregroundColor(Color(hex: "FF6B54"))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button(action: handleVerifyAndReset) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Reset Password")
                            .font(.custom("Avenir-Heavy", size: 17))
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(AppTheme.primaryGradient)
                .cornerRadius(16)
                .shadow(color: AppTheme.primaryGlow, radius: 10, x: 0, y: 4)
            }
            .disabled(isLoading || !isCodeStepValid)
            .opacity(isCodeStepValid ? 1 : 0.6)

            // Resend code button
            Button(action: handleSendCode) {
                Text("Resend Code")
                    .font(.custom("Avenir-Medium", size: 14))
                    .foregroundColor(AppTheme.primaryStart)
            }
            .disabled(isLoading)
        }
    }

    private var isCodeStepValid: Bool {
        otpCode.count >= 6 &&
        newPassword.count >= 6 &&
        newPassword == confirmPassword
    }

    // MARK: - Actions

    private func handleBack() {
        if step == .enterCode {
            withAnimation {
                step = .enterEmail
            }
        } else {
            dismiss()
        }
    }

    private func handleSendCode() {
        focusedField = nil
        isLoading = true
        Task {
            do {
                try await authManager.sendPasswordReset(email: email)
                withAnimation {
                    step = .enterCode
                }
            } catch {
                errorMessage = "Failed to send reset code. Please try again."
                showError = true
            }
            isLoading = false
        }
    }

    private func handleVerifyAndReset() {
        focusedField = nil
        isLoading = true
        Task {
            do {
                // Verify OTP and get session
                try await authManager.verifyOTPAndResetPassword(
                    email: email,
                    token: otpCode,
                    newPassword: newPassword
                )
                showSuccess = true
            } catch {
                let errorDesc = error.localizedDescription.lowercased()
                if errorDesc.contains("invalid") || errorDesc.contains("expired") {
                    errorMessage = "Invalid or expired code. Please try again."
                } else {
                    errorMessage = "Failed to reset password. Please try again."
                }
                showError = true
            }
            isLoading = false
        }
    }
}

// MARK: - Set New Password View

struct SetNewPasswordView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var navigationManager: NavigationManager
    @Environment(\.dismiss) var dismiss

    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var showSuccess = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationView {
            ZStack {
                AmbientBackground()

                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Text("Set New Password")
                            .font(.custom("Avenir-Heavy", size: 28))
                            .foregroundColor(AppTheme.textPrimary)

                        Text("Enter your new password below")
                            .font(.custom("Avenir-Regular", size: 16))
                            .foregroundColor(AppTheme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)

                    DarkSecureField(
                        icon: "lock.fill",
                        placeholder: "New Password",
                        text: $newPassword
                    )
                    .textContentType(.newPassword)

                    DarkSecureField(
                        icon: "lock.fill",
                        placeholder: "Confirm Password",
                        text: $confirmPassword
                    )
                    .textContentType(.newPassword)

                    if !newPassword.isEmpty && newPassword.count < 6 {
                        Text("Password must be at least 6 characters")
                            .font(.custom("Avenir-Regular", size: 13))
                            .foregroundColor(Color(hex: "FF6B54"))
                    }

                    if !confirmPassword.isEmpty && newPassword != confirmPassword {
                        Text("Passwords don't match")
                            .font(.custom("Avenir-Regular", size: 13))
                            .foregroundColor(Color(hex: "FF6B54"))
                    }

                    Button(action: handleUpdatePassword) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Update Password")
                                    .font(.custom("Avenir-Heavy", size: 17))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(AppTheme.primaryGradient)
                        .cornerRadius(16)
                        .shadow(color: AppTheme.primaryGlow, radius: 10, x: 0, y: 4)
                    }
                    .disabled(isLoading || !isFormValid)
                    .opacity(isFormValid ? 1 : 0.6)

                    Spacer()
                }
                .padding(.horizontal, 24)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        navigationManager.showPasswordReset = false
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppTheme.textPrimary)
                    }
                }
            }
        }
        .alert("Password Updated", isPresented: $showSuccess) {
            Button("OK") {
                navigationManager.showPasswordReset = false
                dismiss()
            }
        } message: {
            Text("Your password has been updated successfully. You can now sign in with your new password.")
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    private var isFormValid: Bool {
        !newPassword.isEmpty &&
        newPassword.count >= 6 &&
        newPassword == confirmPassword
    }

    private func handleUpdatePassword() {
        isLoading = true
        Task {
            do {
                try await authManager.updatePassword(newPassword: newPassword)
                showSuccess = true
            } catch {
                errorMessage = "Failed to update password. Please try again."
                showError = true
            }
            isLoading = false
        }
    }
}

// MARK: - Dark Text Fields

struct DarkTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(AppTheme.textSecondary)
                .frame(width: 24)

            TextField(placeholder, text: $text)
                .font(.custom("Avenir-Regular", size: 16))
                .foregroundColor(AppTheme.textPrimary)
        }
        .padding(.horizontal, 16)
        .frame(height: 56)
        .background(AppTheme.glassBackgroundStrong)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppTheme.glassBorder, lineWidth: 1)
        )
        .cornerRadius(12)
    }
}

struct DarkSecureField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    @State private var showPassword = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(AppTheme.textSecondary)
                .frame(width: 24)

            if showPassword {
                TextField(placeholder, text: $text)
                    .font(.custom("Avenir-Regular", size: 16))
                    .foregroundColor(AppTheme.textPrimary)
            } else {
                SecureField(placeholder, text: $text)
                    .font(.custom("Avenir-Regular", size: 16))
                    .foregroundColor(AppTheme.textPrimary)
            }

            Button(action: { showPassword.toggle() }) {
                Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppTheme.textSecondary)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 56)
        .background(AppTheme.glassBackgroundStrong)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppTheme.glassBorder, lineWidth: 1)
        )
        .cornerRadius(12)
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthManager())
        .environmentObject(UserManager())
}
