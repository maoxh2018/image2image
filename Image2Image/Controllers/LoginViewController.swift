import UIKit
import Combine
import QuartzCore

class LoginViewController: UIViewController, UITextFieldDelegate {

    // MARK: - Properties

    private let viewModel = AuthViewModel()
    private var cancellables = Set<AnyCancellable>()
    private var gradientLayer: CAGradientLayer!

    // MARK: - UI Elements

    private let backgroundView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let backgroundScrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.alwaysBounceVertical = true
        sv.keyboardDismissMode = .interactive
        return sv
    }()

    private let stackView: UIStackView = {
        let sv = UIStackView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.axis = .vertical
        sv.spacing = Spacing.xl
        sv.alignment = .fill
        sv.layoutMargins = UIEdgeInsets(top: 0, left: Spacing.lg, bottom: 0, right: Spacing.lg)
        sv.isLayoutMarginsRelativeArrangement = true
        return sv
    }()

    // MARK: Title Section

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "AI图生图"
        label.font = .appTitle
        label.textColor = .textPrimary
        label.textAlignment = .center
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "上传图片，让AI为你创作"
        label.font = .body
        label.textColor = .textSecondary
        label.textAlignment = .center
        return label
    }()

    private lazy var titleStack: UIStackView = {
        let sv = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        sv.axis = .vertical
        sv.spacing = Spacing.sm
        sv.alignment = .center
        return sv
    }()

    // MARK: Phone Section

    private let phoneLabel: UILabel = {
        let label = UILabel()
        label.text = "手机号码"
        label.font = .caption
        label.textColor = .textSecondary
        return label
    }()

    private let phoneTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "请输入手机号"
        tf.font = .body
        tf.textColor = .textPrimary
        tf.backgroundColor = .inputBackground
        tf.layer.cornerRadius = CornerRadius.md
        tf.layer.borderWidth = 1
        tf.layer.borderColor = UIColor.borderColor.cgColor
        tf.keyboardType = .phonePad
        tf.textAlignment = .left
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: Spacing.md, height: 0))
        tf.leftView = paddingView
        tf.leftViewMode = .always
        tf.clearButtonMode = .whileEditing
        tf.autocorrectionType = .no
        tf.autocapitalizationType = .none
        return tf
    }()

    private lazy var phoneSectionStack: UIStackView = {
        let sv = UIStackView(arrangedSubviews: [phoneLabel, phoneTextField])
        sv.axis = .vertical
        sv.spacing = Spacing.sm
        return sv
    }()

    // MARK: Code Section

    private let codeLabel: UILabel = {
        let label = UILabel()
        label.text = "验证码"
        label.font = .caption
        label.textColor = .textSecondary
        return label
    }()

    private let codeTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "请输入验证码"
        tf.font = .body
        tf.textColor = .textPrimary
        tf.backgroundColor = .inputBackground
        tf.layer.cornerRadius = CornerRadius.md
        tf.layer.borderWidth = 1
        tf.layer.borderColor = UIColor.borderColor.cgColor
        tf.keyboardType = .numberPad
        tf.textAlignment = .left
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: Spacing.md, height: 0))
        tf.leftView = paddingView
        tf.leftViewMode = .always
        tf.clearButtonMode = .whileEditing
        tf.autocorrectionType = .no
        tf.autocapitalizationType = .none
        return tf
    }()

    private let sendCodeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("获取验证码", for: .normal)
        button.titleLabel?.font = .caption
        button.setTitleColor(.textPrimary, for: .normal)
        button.layer.cornerRadius = CornerRadius.md
        let gradient = CAGradientLayer()
        gradient.frame = CGRect(x: 0, y: 0, width: 100, height: 40)
        gradient.colors = GradientColors.primaryGradient.map { $0.cgColor }
        gradient.startPoint = CGPoint(x: 0, y: 0.5)
        gradient.endPoint = CGPoint(x: 1, y: 0.5)
        let tempView = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 40))
        tempView.layer.insertSublayer(gradient, at: 0)
        button.backgroundColor = .clear
        button.isEnabled = false
        button.alpha = 0.5
        return button
    }()

    private lazy var codeRowStack: UIStackView = {
        let sv = UIStackView(arrangedSubviews: [codeTextField, sendCodeButton])
        sv.axis = .horizontal
        sv.spacing = Spacing.sm
        sv.alignment = .center
        return sv
    }()

    private lazy var codeSectionStack: UIStackView = {
        let sv = UIStackView(arrangedSubviews: [codeLabel, codeRowStack])
        sv.axis = .vertical
        sv.spacing = Spacing.sm
        sv.isHidden = true
        return sv
    }()

    // MARK: Error Label

    private let errorLabel: UILabel = {
        let label = UILabel()
        label.font = .caption
        label.textColor = .errorColor
        label.textAlignment = .center
        label.numberOfLines = 0
        label.isHidden = true
        return label
    }()

    // MARK: Action Button

    private let actionButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("获取验证码", for: .normal)
        button.titleLabel?.font = .button
        button.setTitleColor(.textPrimary, for: .normal)
        button.layer.cornerRadius = CornerRadius.md
        button.clipsToBounds = true
        button.isEnabled = false
        button.alpha = 0.5
        return button
    }()

    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.color = .textPrimary
        indicator.hidesWhenStopped = true
        return indicator
    }()

    private lazy var buttonContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // MARK: Agreement Label

    private let agreementLabel: UILabel = {
        let label = UILabel()
        label.text = "登录即表示同意用户协议和隐私政策"
        label.font = .small
        label.textColor = .textSecondary
        label.textAlignment = .center
        return label
    }()

    // MARK: Guest Button

    private let guestButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("游客访问", for: .normal)
        button.titleLabel?.font = .body
        button.setTitleColor(.textSecondary, for: .normal)
        button.setUnderline()
        return button
    }()

    // MARK: Login Button (same row as guest)

    private var loginButtonGradientLayer: CAGradientLayer?

    private let loginButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.title = "登录"
        config.baseForegroundColor = .white
        // 背景保持透明，渐变由 CAGradientLayer 子层提供
        config.contentInsets = NSDirectionalEdgeInsets(
            top: Spacing.md,
            leading: Spacing.xl + Spacing.md,
            bottom: Spacing.md,
            trailing: Spacing.xl + Spacing.md
        )
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .bodyBold
            return outgoing
        }

        let button = UIButton(configuration: config)
        button.layer.cornerRadius = CornerRadius.md
        button.clipsToBounds = true
        button.isEnabled = false
        button.alpha = 0.5
        return button
    }()

    private lazy var bottomButtonStack: UIView = {
        let buttonRow = UIStackView(arrangedSubviews: [loginButton, guestButton])
        buttonRow.axis = .horizontal
        buttonRow.spacing = Spacing.xl
        buttonRow.alignment = .center
        buttonRow.distribution = .fill
        buttonRow.translatesAutoresizingMaskIntoConstraints = false

        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(buttonRow)
        NSLayoutConstraint.activate([
            buttonRow.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            buttonRow.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            buttonRow.topAnchor.constraint(greaterThanOrEqualTo: container.topAnchor),
            buttonRow.bottomAnchor.constraint(lessThanOrEqualTo: container.bottomAnchor)
        ])
        return container
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupBindings()
        setupKeyboardObservers()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Setup UI

    private func setupUI() {
        view.backgroundColor = .appBackground

        view.addSubview(backgroundView)
        view.addSubview(backgroundScrollView)
        backgroundScrollView.addSubview(stackView)

        stackView.addArrangedSubview(titleStack)
        stackView.addArrangedSubview(phoneSectionStack)
        stackView.addArrangedSubview(codeSectionStack)
        stackView.addArrangedSubview(errorLabel)
        stackView.addArrangedSubview(buttonContainer)
        stackView.addArrangedSubview(agreementLabel)
        stackView.addArrangedSubview(bottomButtonStack)

        titleStack.setCustomSpacing(Spacing.xxl, after: titleStack)

        phoneTextField.addTarget(self, action: #selector(phoneTextFieldDidChange), for: .editingChanged)
        codeTextField.addTarget(self, action: #selector(codeTextFieldDidChange), for: .editingChanged)
        sendCodeButton.addTarget(self, action: #selector(sendCodeButtonTapped), for: .touchUpInside)
        actionButton.addTarget(self, action: #selector(actionButtonTapped), for: .touchUpInside)
        loginButton.addTarget(self, action: #selector(actionButtonTapped), for: .touchUpInside)
        guestButton.addTarget(self, action: #selector(guestButtonTapped), for: .touchUpInside)

        phoneTextField.delegate = self
        codeTextField.delegate = self

        setupActionButtonGradient()
        setupSendCodeButtonGradient()
        setupLoginButtonGradient()

        buttonContainer.addSubview(actionButton)
        buttonContainer.addSubview(loadingIndicator)

        NSLayoutConstraint.activate([
            actionButton.topAnchor.constraint(equalTo: buttonContainer.topAnchor),
            actionButton.leadingAnchor.constraint(equalTo: buttonContainer.leadingAnchor),
            actionButton.trailingAnchor.constraint(equalTo: buttonContainer.trailingAnchor),
            actionButton.heightAnchor.constraint(equalToConstant: Spacing.xl * 2),
            actionButton.bottomAnchor.constraint(equalTo: buttonContainer.bottomAnchor),

            loadingIndicator.centerXAnchor.constraint(equalTo: actionButton.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: actionButton.centerYAnchor)
        ])

        codeTextField.heightAnchor.constraint(equalToConstant: Spacing.xl * 2).isActive = true
        phoneTextField.heightAnchor.constraint(equalToConstant: Spacing.xl * 2).isActive = true

        codeTextField.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.6).isActive = true

        let sendCodeWidthConstraint = sendCodeButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 80)
        sendCodeWidthConstraint.isActive = true
        sendCodeButton.heightAnchor.constraint(equalToConstant: Spacing.xl * 2).isActive = true
    }

    private func setupActionButtonGradient() {
        let gradient = CAGradientLayer()
        gradient.frame = CGRect(x: 0, y: 0, width: 400, height: Spacing.xl * 2)
        gradient.colors = GradientColors.primaryGradient.map { $0.cgColor }
        gradient.startPoint = CGPoint(x: 0, y: 0.5)
        gradient.endPoint = CGPoint(x: 1, y: 0.5)
        gradient.cornerRadius = CornerRadius.md
        actionButton.layer.insertSublayer(gradient, at: 0)
    }

    private func setupSendCodeButtonGradient() {
        let gradient = CAGradientLayer()
        gradient.frame = CGRect(x: 0, y: 0, width: 100, height: Spacing.xl * 2)
        gradient.colors = GradientColors.primaryGradient.map { $0.cgColor }
        gradient.startPoint = CGPoint(x: 0, y: 0.5)
        gradient.endPoint = CGPoint(x: 1, y: 0.5)
        gradient.cornerRadius = CornerRadius.md
        sendCodeButton.layer.insertSublayer(gradient, at: 0)
    }

    private func setupLoginButtonGradient() {
        let gradient = CAGradientLayer()
        gradient.frame = CGRect(x: 0, y: 0, width: 120, height: 44)
        gradient.colors = GradientColors.primaryGradient.map { $0.cgColor }
        gradient.startPoint = CGPoint(x: 0, y: 0.5)
        gradient.endPoint = CGPoint(x: 1, y: 0.5)
        gradient.cornerRadius = CornerRadius.md
        loginButton.layer.insertSublayer(gradient, at: 0)
        loginButtonGradientLayer = gradient
    }

    // MARK: - Constraints

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            backgroundScrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            backgroundScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundScrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            stackView.topAnchor.constraint(equalTo: backgroundScrollView.topAnchor, constant: Spacing.xxl),
            stackView.leadingAnchor.constraint(equalTo: backgroundScrollView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: backgroundScrollView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: backgroundScrollView.bottomAnchor, constant: -Spacing.xl),
            stackView.widthAnchor.constraint(equalTo: backgroundScrollView.widthAnchor)
        ])
    }

    // MARK: - Combine Bindings

    private func setupBindings() {
        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                self?.updateLoadingState(isLoading)
                self?.updateButtonState()
                self?.updateSendCodeButtonState()
            }
            .store(in: &cancellables)

        viewModel.$isCodeSent
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isCodeSent in
                self?.updateCodeSectionVisibility(isCodeSent)
                self?.updateActionButtonTitle(isCodeSent)
                self?.updateButtonState()
            }
            .store(in: &cancellables)

        viewModel.$errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] errorMessage in
                self?.updateErrorMessage(errorMessage)
            }
            .store(in: &cancellables)

        viewModel.$phone
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateButtonState()
                self?.updateSendCodeButtonState()
            }
            .store(in: &cancellables)

        viewModel.$code
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateButtonState()
            }
            .store(in: &cancellables)
    }

    // MARK: - UI State Updates

    private func updateLoadingState(_ isLoading: Bool) {
        if isLoading {
            loadingIndicator.startAnimating()
            actionButton.setTitle("", for: .normal)
            actionButton.isEnabled = false
            loginButton.isEnabled = false
        } else {
            loadingIndicator.stopAnimating()
            actionButton.isEnabled = true
            updateButtonState()
        }
    }

    private func updateCodeSectionVisibility(_ isCodeSent: Bool) {
        codeSectionStack.isHidden = !isCodeSent
        if isCodeSent {
            DispatchQueue.main.async { [weak self] in
                self?.codeTextField.becomeFirstResponder()
            }
        }
    }

    private func updateActionButtonTitle(_ isCodeSent: Bool) {
        actionButton.setTitle(isCodeSent ? "登录" : "获取验证码", for: .normal)
    }

    private func updateErrorMessage(_ errorMessage: String?) {
        if let errorMessage = errorMessage, !errorMessage.isEmpty {
            errorLabel.text = errorMessage
            errorLabel.isHidden = false
        } else {
            errorLabel.isHidden = true
        }
    }

    private func updateButtonState() {
        let enabled: Bool
        if viewModel.isCodeSent {
            enabled = viewModel.canLogin
        } else {
            enabled = viewModel.canSendCode
        }
        actionButton.isEnabled = enabled
        actionButton.alpha = enabled ? 1.0 : 0.5

        loginButton.isEnabled = enabled
        loginButton.alpha = enabled ? 1.0 : 0.5
    }

    private func updateSendCodeButtonState() {
        let enabled = !viewModel.isLoading && viewModel.phone.count == 11
        sendCodeButton.isEnabled = enabled
        sendCodeButton.alpha = enabled ? 1.0 : 0.5
    }

    // MARK: - Text Field Actions

    @objc private func phoneTextFieldDidChange() {
        guard let text = phoneTextField.text else { return }
        viewModel.phone = String(text.prefix(11))
        phoneTextField.text = viewModel.phone
    }

    @objc private func codeTextFieldDidChange() {
        guard let text = codeTextField.text else { return }
        viewModel.code = String(text.prefix(6))
        codeTextField.text = viewModel.code
    }

    // MARK: - Button Actions

    @objc private func sendCodeButtonTapped() {
        viewModel.sendVerificationCode()
    }

    @objc private func actionButtonTapped() {
        if viewModel.isCodeSent {
            login()
        } else {
            viewModel.sendVerificationCode()
        }
    }

    private func login() {
        viewModel.login { success in
            if success {
                NotificationCenter.default.post(name: .loginSuccess, object: nil)
            }
        }
    }

    @objc private func guestButtonTapped() {
        NotificationCenter.default.post(name: .loginSuccess, object: nil)
    }

    // MARK: - UITextFieldDelegate

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentText = textField.text ?? ""
        guard let stringRange = Range(range, in: currentText) else { return false }
        let newText = currentText.replacingCharacters(in: stringRange, with: string)

        if textField === phoneTextField {
            return newText.count <= 11
        } else if textField === codeTextField {
            return newText.count <= 6
        }
        return true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    // MARK: - Keyboard Handling

    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleKeyboardShow(notification)
        }

        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleKeyboardHide(notification)
        }
    }

    private func handleKeyboardShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        let keyboardHeight = keyboardFrame.height
        backgroundScrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardHeight, right: 0)
        backgroundScrollView.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardHeight, right: 0)
    }

    private func handleKeyboardHide(_ notification: Notification) {
        backgroundScrollView.contentInset = .zero
        backgroundScrollView.scrollIndicatorInsets = .zero
    }

    // MARK: - Layout

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if gradientLayer == nil {
            gradientLayer = CAGradientLayer()
            gradientLayer.frame = backgroundView.bounds
            gradientLayer.colors = GradientColors.backgroundGradient.map { $0.cgColor }
            gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
            gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
            backgroundView.layer.insertSublayer(gradientLayer, at: 0)
        } else {
            gradientLayer.frame = backgroundView.bounds
        }

        if let actionGradient = actionButton.layer.sublayers?.first as? CAGradientLayer {
            actionGradient.frame = actionButton.bounds
        }
        if let sendCodeGradient = sendCodeButton.layer.sublayers?.first as? CAGradientLayer {
            sendCodeGradient.frame = sendCodeButton.bounds
        }
        loginButtonGradientLayer?.frame = loginButton.bounds
    }
}

// MARK: - UIButton Extension

private extension UIButton {
    func setUnderline(color: UIColor = .textSecondary) {
        guard let title = title(for: .normal) else { return }
        let attributed = NSAttributedString(
            string: title,
            attributes: [
                .underlineStyle: NSUnderlineStyle.single.rawValue,
                .foregroundColor: color
            ]
        )
        setAttributedTitle(attributed, for: .normal)
    }
}