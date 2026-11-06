import Foundation
import Combine

class AuthViewModel: ObservableObject {
    @Published var phone: String = ""
    @Published var code: String = ""
    @Published var isLoading: Bool = false
    @Published var isCodeSent: Bool = false
    @Published var errorMessage: String?
    
    private let authService: AuthServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(authService: AuthServiceProtocol = AuthService()) {
        self.authService = authService
    }
    
    var canSendCode: Bool {
        phone.count == 11 && !isLoading && !isCodeSent
    }
    
    var canLogin: Bool {
        phone.count == 11 && code.count == 6 && !isLoading
    }
    
    func sendVerificationCode() {
        guard canSendCode else { return }
        
        isLoading = true
        errorMessage = nil
        
        authService.sendVerificationCode(phone: phone)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                switch completion {
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                case .finished:
                    break
                }
            } receiveValue: { [weak self] _ in
                self?.isCodeSent = true
                self?.code = "123456"
            }
            .store(in: &cancellables)
    }
    
    func login(completion: @escaping (Bool) -> Void) {
        guard canLogin else {
            completion(false)
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        authService.login(phone: phone, code: code)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completionResult in
                self?.isLoading = false
                switch completionResult {
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                    completion(false)
                case .finished:
                    break
                }
            } receiveValue: { [weak self] _ in
                self?.isCodeSent = false
                completion(true)
            }
            .store(in: &cancellables)
    }
    
    func clear() {
        phone = ""
        code = ""
        isCodeSent = false
        errorMessage = nil
    }
}