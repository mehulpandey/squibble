//
//  AuthManager.swift
//  squibble
//
//  Manages authentication state using Supabase Auth
//

import Foundation
import Combine
import Supabase
import Auth

@MainActor
final class AuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading = true
    @Published var currentUserID: UUID?

    private let supabase = SupabaseService.shared.client

    init() {
        Task {
            await checkSession()
        }
    }

    func checkSession() async {
        isLoading = true
        do {
            let session = try await supabase.auth.session
            currentUserID = session.user.id
            isAuthenticated = true
        } catch {
            currentUserID = nil
            isAuthenticated = false
        }
        isLoading = false
    }

    func signOut() async throws {
        try await supabase.auth.signOut()
        currentUserID = nil
        isAuthenticated = false
    }

    // MARK: - Email/Password Authentication

    func signUpWithEmail(email: String, password: String) async throws {
        let response = try await supabase.auth.signUp(
            email: email,
            password: password
        )
        // User needs to verify email before they can sign in
        // The session may be nil until email is confirmed
        if let session = response.session {
            currentUserID = session.user.id
            isAuthenticated = true
        }
    }

    func signInWithEmail(email: String, password: String) async throws {
        let session = try await supabase.auth.signIn(
            email: email,
            password: password
        )
        currentUserID = session.user.id
        isAuthenticated = true
    }

    func resendVerificationEmail(email: String) async throws {
        try await supabase.auth.resend(
            email: email,
            type: .signup
        )
    }

    func sendPasswordReset(email: String) async throws {
        // Send password reset email - Supabase will include OTP token in the email
        try await supabase.auth.resetPasswordForEmail(email)
    }

    func updatePassword(newPassword: String) async throws {
        try await supabase.auth.update(user: .init(password: newPassword))
    }

    /// Verify OTP token from password reset email and update password
    func verifyOTPAndResetPassword(email: String, token: String, newPassword: String) async throws {
        // Verify the OTP token - this creates a session if valid
        _ = try await supabase.auth.verifyOTP(
            email: email,
            token: token,
            type: .recovery
        )

        // Now update the password (user is authenticated via OTP)
        try await supabase.auth.update(user: .init(password: newPassword))

        // Sign out after password reset so user can login with new password
        try await supabase.auth.signOut()
        currentUserID = nil
        isAuthenticated = false
    }

    // MARK: - Apple Sign-In (to be implemented when credentials are ready)

    func signInWithApple(idToken: String, nonce: String) async throws {
        let session = try await supabase.auth.signInWithIdToken(
            credentials: .init(provider: .apple, idToken: idToken, nonce: nonce)
        )
        currentUserID = session.user.id
        isAuthenticated = true
    }

    // MARK: - Google Sign-In (to be implemented when credentials are ready)

    func signInWithGoogle(idToken: String, accessToken: String) async throws {
        let session = try await supabase.auth.signInWithIdToken(
            credentials: .init(provider: .google, idToken: idToken, accessToken: accessToken)
        )
        currentUserID = session.user.id
        isAuthenticated = true
    }
}
