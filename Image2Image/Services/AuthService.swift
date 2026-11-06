import Foundation
import Combine
import AuthenticationServices
import UIKit

struct AppleCredential {
    let userIdentifier: String
    let fullName: String?
    let email: String?
}

protocol AuthServiceProtocol {
    func sendVerificationCode(phone: String) -> AnyPublisher<Void, Error>
    func login(phone: String, code: String) -> AnyPublisher<User, Error>
    func getUser() -> User?
    func logout()
}

final class AuthService: NSObject, AuthServiceProtocol, ObservableObject {
    static let shared = AuthService()

    @Published var isLoggedIn = false
    @Published var phoneNumber: String = ""
    @Published var displayName: String = ""
    @Published var authProvider: String = ""

    private let userDefaults = UserDefaults.standard
    private let userKey = "Image2Image_User"
    private let loggedInKey = "Image2Image_LoggedIn"
    private let appleUserIdentifierKey = "Image2Image_AppleUserIdentifier"
    private let displayNameKey = "Image2Image_DisplayName"
    private let emailKey = "Image2Image_Email"
    private let authProviderKey = "Image2Image_AuthProvider"
    private let phoneLoginKey = "Image2Image_PhoneLogin"

    override init() {
        super.init()
        loadFromDefaults()

        // Apple 凭据被撤销时自动登出
        if authProvider == "Apple" {
            NotificationCenter.default.addObserver(
                forName: ASAuthorizationAppleIDProvider.credentialRevokedNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.logout()
            }
        }
    }

    // MARK: - Public: Phone + 验证码

    func sendVerificationCode(phone: String) -> AnyPublisher<Void, Error> {
        return Future { promise in
            DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
                promise(.success(()))
            }
        }.eraseToAnyPublisher()
    }

    func login(phone: String, code: String) -> AnyPublisher<User, Error> {
        return Future { promise in
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
                let user = User(
                    id: UUID().uuidString,
                    phone: phone,
                    nickname: "AI艺术家",
                    avatar: nil,
                    createdAt: Date(),
                    lastLoginAt: Date()
                )

                if let data = try? JSONEncoder().encode(user) {
                    self.userDefaults.set(data, forKey: self.userKey)
                }

                self.userDefaults.set(true, forKey: self.phoneLoginKey)
                self.userDefaults.set("Phone", forKey: self.authProviderKey)
                self.userDefaults.set(user.nickname, forKey: self.displayNameKey)
                self.userDefaults.synchronize()

                DispatchQueue.main.async {
                    self.isLoggedIn = true
                    self.phoneNumber = phone
                    self.authProvider = "Phone"
                    self.displayName = user.nickname
                }

                promise(.success(user))
            }
        }.eraseToAnyPublisher()
    }

    // MARK: - Public: Sign in with Apple

    func signInWithApple() {
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }

    // MARK: - Public: Email login（mock）

    @discardableResult
    func login(email: String) -> Bool {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isValidEmail(trimmed) else { return false }

        userDefaults.set(true, forKey: self.phoneLoginKey) // 标记为非 phone 登录
        userDefaults.set(true, forKey: self.loggedInKey)
        userDefaults.set("Email", forKey: self.authProviderKey)
        userDefaults.set(trimmed, forKey: self.emailKey)
        userDefaults.set(trimmed, forKey: self.displayNameKey)
        userDefaults.removeObject(forKey: self.userKey)
        userDefaults.synchronize()

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.isLoggedIn = true
            self.authProvider = "Email"
            self.displayName = trimmed
            self.phoneNumber = ""
        }
        return true
    }

    // MARK: - Public: Query

    func getUser() -> User? {
        // 优先返回 phone 登录持久化的完整 User 模型
        if let data = userDefaults.data(forKey: userKey),
           let user = try? JSONDecoder().decode(User.self, from: data) {
            return user
        }
        // 兜底：Apple / Email 登录合成一个临时 User（没有手机号）
        guard isLoggedIn else { return nil }
        let fallbackName = displayName.isEmpty ? authProvider + " User" : displayName
        return User(
            id: authProviderKey + "_" + fallbackName,
            phone: "",
            nickname: fallbackName,
            avatar: nil,
            createdAt: Date(),
            lastLoginAt: Date()
        )
    }

    // MARK: - Public: Logout

    func logout() {
        userDefaults.removeObject(forKey: userKey)
        userDefaults.set(false, forKey: phoneLoginKey)
        userDefaults.removeObject(forKey: appleUserIdentifierKey)
        userDefaults.removeObject(forKey: displayNameKey)
        userDefaults.removeObject(forKey: emailKey)
        userDefaults.removeObject(forKey: authProviderKey)
        userDefaults.removeObject(forKey: loggedInKey)
        userDefaults.synchronize()

        isLoggedIn = false
        phoneNumber = ""
        displayName = ""
        authProvider = ""
    }

    // MARK: - Persistence

    private func loadFromDefaults() {
        let hadPhoneLogin = userDefaults.bool(forKey: phoneLoginKey)
        isLoggedIn = hadPhoneLogin || userDefaults.bool(forKey: loggedInKey)
        authProvider = userDefaults.string(forKey: authProviderKey) ?? ""
        displayName = userDefaults.string(forKey: displayNameKey) ?? ""
        phoneNumber = (try? JSONDecoder().decode(User.self, from: userDefaults.data(forKey: userKey) ?? Data()))?.phone ?? ""

        // Apple 登录：启动时验证凭据状态
        if authProvider == "Apple",
           let userIdentifier = userDefaults.string(forKey: appleUserIdentifierKey) {
            verifyAppleCredentialState(userIdentifier: userIdentifier)
        }
    }

    private func saveAppleCredential(_ credential: AppleCredential) {
        userDefaults.set(true, forKey: phoneLoginKey)
        userDefaults.set(true, forKey: loggedInKey)
        userDefaults.set(credential.userIdentifier, forKey: appleUserIdentifierKey)
        userDefaults.set("Apple", forKey: authProviderKey)

        // Apple 只在首次授权返回 fullName / email，保留之前保存的值
        let savedName = credential.fullName ?? userDefaults.string(forKey: displayNameKey)
        let savedEmail = credential.email ?? userDefaults.string(forKey: emailKey)
        userDefaults.set(savedName, forKey: displayNameKey)
        userDefaults.set(savedEmail, forKey: emailKey)
        userDefaults.removeObject(forKey: userKey)
        userDefaults.synchronize()

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.isLoggedIn = true
            self.authProvider = "Apple"
            if let savedName, !savedName.isEmpty {
                self.displayName = savedName
            } else if let savedEmail, !savedEmail.isEmpty {
                self.displayName = savedEmail
            } else {
                self.displayName = "Apple User"
            }
            self.phoneNumber = ""
            // 发通知让 SceneDelegate 切换到 TabBar
            NotificationCenter.default.post(name: .loginSuccess, object: nil)
        }
    }

    private func verifyAppleCredentialState(userIdentifier: String) {
        ASAuthorizationAppleIDProvider().getCredentialState(forUserID: userIdentifier) { [weak self] state, _ in
            DispatchQueue.main.async {
                switch state {
                case .revoked, .notFound:
                    self?.logout()
                default:
                    break
                }
            }
        }
    }

    // MARK: - Helpers

    private func isValidEmail(_ email: String) -> Bool {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        return trimmed.range(of: emailRegex, options: .regularExpression) != nil
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension AuthService: ASAuthorizationControllerDelegate {

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            assertionFailure("Unexpected authorization credential type")
            return
        }

        let credential = AppleCredential(
            userIdentifier: appleIDCredential.user,
            fullName: appleIDCredential.fullName?.formatted(),
            email: appleIDCredential.email
        )
        saveAppleCredential(credential)
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        let nsError = error as NSError
        let errorCode = ASAuthorizationError.Code(rawValue: nsError.code)
        if errorCode == .canceled { return }
        print("[Auth] Sign in with Apple failed: \(error.localizedDescription)")
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding

extension AuthService: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        for scene in UIApplication.shared.connectedScenes {
            if let windowScene = scene as? UIWindowScene,
               let window = windowScene.windows.first(where: { $0.isKeyWindow }) {
                return window
            }
        }
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            return UIWindow(windowScene: scene)
        }
        fatalError("Unable to resolve presentation anchor for Sign in with Apple")
    }
}

// MARK: - PersonNameComponents convenience

extension PersonNameComponents {
    func formatted() -> String? {
        let name = PersonNameComponentsFormatter().string(from: self)
        return name.isEmpty ? nil : name
    }
}
