import UIKit
import Combine
import QuartzCore

class ProfileViewController: UIViewController {

    // MARK: - Properties

    private let viewModel = ProfileViewModel()
    private var cancellables = Set<AnyCancellable>()
    private var gradientLayer: CAGradientLayer!
    private var subscribeButtonGradientLayer = CAGradientLayer()

    // MARK: - UI Elements

    private let backgroundView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.alwaysBounceVertical = true
        sv.keyboardDismissMode = .interactive
        return sv
    }()

    private let contentStackView: UIStackView = {
        let sv = UIStackView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.axis = .vertical
        sv.spacing = Spacing.xl
        sv.alignment = .fill
        sv.layoutMargins = UIEdgeInsets(top: Spacing.xl, left: Spacing.lg, bottom: Spacing.xl, right: Spacing.lg)
        sv.isLayoutMarginsRelativeArrangement = true
        return sv
    }()

    // MARK: - User Section

    private lazy var userInfoStack: UIStackView = {
        let sv = UIStackView(arrangedSubviews: [avatarContainer, nicknameLabel, phoneLabel, authButton])
        sv.axis = .vertical
        sv.spacing = Spacing.md
        sv.alignment = .center
        return sv
    }()

    private let avatarContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .cardBackground
        view.layer.cornerRadius = CornerRadius.xl
        view.clipsToBounds = true
        return view
    }()

    private let avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        let config = UIImage.SymbolConfiguration(pointSize: 40, weight: .light)
        imageView.image = UIImage(systemName: "person", withConfiguration: config)
        imageView.tintColor = .textSecondary
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let nicknameLabel: UILabel = {
        let label = UILabel()
        label.font = .heading
        label.textColor = .textPrimary
        label.textAlignment = .center
        return label
    }()

    private let phoneLabel: UILabel = {
        let label = UILabel()
        label.font = .caption
        label.textColor = .textSecondary
        label.textAlignment = .center
        return label
    }()

    private let authButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.titleLabel?.font = .captionBold
        button.layer.cornerRadius = CornerRadius.sm
        button.layer.masksToBounds = true
        return button
    }()

    // MARK: - Stats Card

    private let statsCardView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .cardBackground
        view.layer.cornerRadius = CornerRadius.md
        view.clipsToBounds = true
        return view
    }()

    private lazy var statsStack: UIStackView = {
        let sv = UIStackView(arrangedSubviews: [artworkStatsView, subscriptionStatsView])
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.axis = .horizontal
        sv.alignment = .fill
        sv.distribution = .fillEqually
        return sv
    }()

    private lazy var artworkStatsView = makeStatsItemView()
    private lazy var subscriptionStatsView = makeStatsItemView()

    // MARK: - Subscription Button

    private let subscribeButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .button
        button.layer.cornerRadius = CornerRadius.md
        button.layer.masksToBounds = true
        button.layer.shadowColor = UIColor.primary.cgColor
        button.layer.shadowOpacity = 0.5
        button.layer.shadowRadius = 12
        button.layer.shadowOffset = CGSize(width: 0, height: 4)
        return button
    }()

    // MARK: - Menu Section

    private lazy var menuStack: UIStackView = {
        let sv = UIStackView(arrangedSubviews: [
            aboutMenuItem,
            helpMenuItem,
            privacyMenuItem,
            termsMenuItem,
            logoutMenuItem
        ])
        sv.axis = .vertical
        sv.spacing = Spacing.none
        sv.alignment = .fill
        return sv
    }()

    private lazy var helpMenuItem = makeMenuItem(icon: "questionmark.circle", title: "帮助与支持")
    private lazy var aboutMenuItem = makeMenuItem(icon: "info.circle", title: "关于我们")
    private lazy var privacyMenuItem = makeMenuItem(icon: "hand.raised", title: "隐私政策")
    private lazy var termsMenuItem = makeMenuItem(icon: "doc.text", title: "服务协议")
    private lazy var logoutMenuItem = makeMenuItem(icon: "log.out", title: "退出登录", isDestructive: true)

    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.color = .textSecondary
        indicator.hidesWhenStopped = true
        return indicator
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
        setupNotifications()
        updateUserInfo()
        updateSubscriptionUI()
        updateAuthUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        viewModel.loadUser()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = backgroundView.bounds
        updateSubscribeButtonGradient()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Setup UI

    private func setupUI() {
        view.backgroundColor = .appBackground

        view.addSubview(backgroundView)
        view.addSubview(scrollView)
        scrollView.addSubview(contentStackView)

        let gradient = CAGradientLayer()
        gradient.frame = view.bounds
        gradient.colors = GradientColors.backgroundGradient.map { $0.cgColor }
        gradient.startPoint = CGPoint(x: 0.5, y: 0)
        gradient.endPoint = CGPoint(x: 0.5, y: 1)
        gradientLayer = gradient
        backgroundView.layer.insertSublayer(gradientLayer, at: 0)

        contentStackView.addArrangedSubview(userInfoStack)
        contentStackView.addArrangedSubview(statsCardView)
        contentStackView.addArrangedSubview(subscribeButton)
        contentStackView.addArrangedSubview(menuStack)
        contentStackView.addArrangedSubview(loadingIndicator)

        avatarContainer.addSubview(avatarImageView)
        NSLayoutConstraint.activate([
            avatarContainer.widthAnchor.constraint(equalToConstant: 80),
            avatarContainer.heightAnchor.constraint(equalToConstant: 80),
            avatarImageView.centerXAnchor.constraint(equalTo: avatarContainer.centerXAnchor),
            avatarImageView.centerYAnchor.constraint(equalTo: avatarContainer.centerYAnchor)
        ])

        setupStatsCard()
        setupSubscribeButton()

        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentStackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentStackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentStackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            statsCardView.leadingAnchor.constraint(equalTo: contentStackView.layoutMarginsGuide.leadingAnchor),
            statsCardView.trailingAnchor.constraint(equalTo: contentStackView.layoutMarginsGuide.trailingAnchor),
            statsCardView.heightAnchor.constraint(equalToConstant: 80),

            authButton.widthAnchor.constraint(equalToConstant: 120),
            authButton.heightAnchor.constraint(equalToConstant: 36),

            subscribeButton.leadingAnchor.constraint(equalTo: contentStackView.layoutMarginsGuide.leadingAnchor),
            subscribeButton.trailingAnchor.constraint(equalTo: contentStackView.layoutMarginsGuide.trailingAnchor),
            subscribeButton.heightAnchor.constraint(equalToConstant: 52),

            menuStack.leadingAnchor.constraint(equalTo: contentStackView.layoutMarginsGuide.leadingAnchor),
            menuStack.trailingAnchor.constraint(equalTo: contentStackView.layoutMarginsGuide.trailingAnchor),

            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.topAnchor.constraint(equalTo: menuStack.bottomAnchor, constant: Spacing.lg)
        ])

        authButton.addTarget(self, action: #selector(authButtonTapped), for: .touchUpInside)
        subscribeButton.addTarget(self, action: #selector(toggleSubscription), for: .touchUpInside)
        helpMenuItem.addTarget(self, action: #selector(helpTapped), for: .touchUpInside)
        aboutMenuItem.addTarget(self, action: #selector(aboutTapped), for: .touchUpInside)
        privacyMenuItem.addTarget(self, action: #selector(privacyTapped), for: .touchUpInside)
        termsMenuItem.addTarget(self, action: #selector(termsTapped), for: .touchUpInside)
        logoutMenuItem.addTarget(self, action: #selector(logoutTapped), for: .touchUpInside)
    }

    private func setupStatsCard() {
        statsCardView.addSubview(statsStack)

        NSLayoutConstraint.activate([
            statsStack.topAnchor.constraint(equalTo: statsCardView.topAnchor, constant: Spacing.lg),
            statsStack.leadingAnchor.constraint(equalTo: statsCardView.leadingAnchor, constant: Spacing.lg),
            statsStack.trailingAnchor.constraint(equalTo: statsCardView.trailingAnchor, constant: -Spacing.lg),
            statsStack.bottomAnchor.constraint(equalTo: statsCardView.bottomAnchor, constant: -Spacing.lg)
        ])

        artworkStatsView.configure(value: "0", title: "作品数")
        subscriptionStatsView.configure(value: "0", title: "剩余次数")
    }

    private func setupSubscribeButton() {
        subscribeButtonGradientLayer.colors = GradientColors.primaryGradient.map { $0.cgColor }
        subscribeButtonGradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        subscribeButtonGradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        subscribeButton.layer.insertSublayer(subscribeButtonGradientLayer, at: 0)
    }

    private func updateSubscribeButtonGradient() {
        subscribeButtonGradientLayer.frame = subscribeButton.bounds
    }

    private func makeStatsItemView() -> StatsItemView {
        let view = StatsItemView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }

    private func makeMenuItem(icon: String, title: String, isDestructive: Bool = false) -> MenuItemButton {
        let button = MenuItemButton()
        button.configure(icon: icon, title: title, isDestructive: isDestructive)
        return button
    }

    // MARK: - Bindings

    private func setupBindings() {
        viewModel.$user
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateUserInfo()
            }
            .store(in: &cancellables)

        viewModel.$artworkCount
            .receive(on: DispatchQueue.main)
            .sink { [weak self] count in
                self?.artworkStatsView.configure(value: "\(count)", title: "作品数")
            }
            .store(in: &cancellables)

        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                if isLoading {
                    self?.loadingIndicator.startAnimating()
                } else {
                    self?.loadingIndicator.stopAnimating()
                }
            }
            .store(in: &cancellables)

        viewModel.$isSubscribed
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateSubscriptionUI()
            }
            .store(in: &cancellables)

        viewModel.$remainingCount
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateSubscriptionUI()
            }
            .store(in: &cancellables)

        viewModel.$isLoggedIn
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateAuthUI()
            }
            .store(in: &cancellables)
    }

    // MARK: - Notifications

    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleLoginSuccess),
            name: .loginSuccess,
            object: nil
        )
    }

    // MARK: - UI Updates

    private func updateUserInfo() {
        guard let user = viewModel.user, viewModel.isLoggedIn else {
            nicknameLabel.text = "未登录"
            phoneLabel.text = ""
            avatarImageView.image = UIImage(systemName: "person")
            return
        }
        nicknameLabel.text = user.nickname
        phoneLabel.text = user.maskedPhone
    }

    private func updateAuthUI() {
        if viewModel.isLoggedIn {
            authButton.setTitle("退出登录", for: .normal)
            authButton.setTitleColor(.errorColor, for: .normal)
            authButton.backgroundColor = .cardBackground
            logoutMenuItem.isHidden = false
        } else {
            authButton.setTitle("Sign In", for: .normal)
            authButton.setTitleColor(.white, for: .normal)
            authButton.backgroundColor = .secondary
            logoutMenuItem.isHidden = true
        }
    }

    private func updateSubscriptionUI() {
        if viewModel.isSubscribed {
            subscribeButton.setTitle("已订阅 · 剩余 \(viewModel.remainingCount) 次", for: .normal)
            subscribeButton.isEnabled = false
            subscribeButtonGradientLayer.isHidden = true
            subscribeButton.backgroundColor = .cardBackground
            subscribeButton.setTitleColor(.textSecondary, for: .disabled)
            subscribeButton.layer.shadowOpacity = 0
        } else {
            subscribeButton.setTitle("开通订阅", for: .normal)
            subscribeButton.isEnabled = true
            subscribeButtonGradientLayer.isHidden = false
            subscribeButton.backgroundColor = .clear
            subscribeButton.setTitleColor(.white, for: .normal)
            subscribeButton.layer.shadowOpacity = 0.5
        }

        subscriptionStatsView.configure(value: "\(viewModel.remainingCount)", title: "剩余次数")
    }

    // MARK: - Actions

    private lazy var authService = AuthService.shared

    @objc private func authButtonTapped() {
        if viewModel.isLoggedIn {
            // 退出登录
            let alert = UIAlertController(title: "确认登出", message: "确定要登出当前账号吗？", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "取消", style: .cancel))
            alert.addAction(UIAlertAction(title: "登出", style: .destructive) { [weak self] _ in
                self?.viewModel.logout()
                NotificationCenter.default.post(name: .logoutSelected, object: nil)
            })
            present(alert, animated: true)
        } else {
            showSignInOptions()
        }
    }

    private func showSignInOptions() {
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        let appleIcon = UIImage(systemName: "apple.logo")
        let emailIcon = UIImage(systemName: "envelope")
        let phoneIcon = UIImage(systemName: "iphone")

        sheet.addAction(UIAlertAction(title: "Continue with Apple", style: .default) { [weak self] _ in
            self?.authService.signInWithApple()
        })
        sheet.actions.last?.setValue(appleIcon, forKey: "image")

        sheet.addAction(UIAlertAction(title: "Continue with Email", style: .default) { [weak self] _ in
            self?.showEmailSignIn()
        })
        sheet.actions.last?.setValue(emailIcon, forKey: "image")

        sheet.addAction(UIAlertAction(title: "Continue with Phone", style: .default) { [weak self] _ in
            self?.showPhoneSignIn()
        })
        sheet.actions.last?.setValue(phoneIcon, forKey: "image")

        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let popover = sheet.popoverPresentationController {
            popover.sourceView = authButton
            popover.sourceRect = authButton.bounds
        }

        present(sheet, animated: true)
    }

    private func showEmailSignIn() {
        let alert = UIAlertController(title: "Continue with Email", message: "Please enter your email", preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "example@domain.com"
            textField.keyboardType = .emailAddress
            textField.autocapitalizationType = .none
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Sign In", style: .default) { [weak self] _ in
            guard let email = alert.textFields?.first?.text, !email.isEmpty else { return }
            let success = self?.authService.login(email: email) ?? false
            if success {
                NotificationCenter.default.post(name: .loginSuccess, object: nil)
            } else {
                let errorAlert = UIAlertController(title: "Sign In Failed", message: "Invalid email address, please try again", preferredStyle: .alert)
                errorAlert.addAction(UIAlertAction(title: "OK", style: .default))
                self?.present(errorAlert, animated: true)
            }
        })
        present(alert, animated: true)
    }

    private func showPhoneSignIn() {
        // 手机号 + 验证码走 LoginViewController 完整流程
        NotificationCenter.default.post(name: .logoutSelected, object: nil)
    }

    @objc private func toggleSubscription() {
        // 已订阅状态下按钮已被禁用，此处仅处理未订阅时的点击事件
        guard !viewModel.isSubscribed else { return }

        let subscriptionVC = SubscriptionViewController()
        subscriptionVC.modalPresentationStyle = .fullScreen
        present(subscriptionVC, animated: true)
    }

    @objc private func helpTapped() {
        if let url = URL(string: Config.helpSupportURL) {
            UIApplication.shared.open(url)
        }
    }

    @objc private func privacyTapped() {
        if let url = URL(string: Config.privacyPolicyURL) {
            UIApplication.shared.open(url)
        }
    }

    @objc private func termsTapped() {
        if let url = URL(string: Config.termsOfServiceURL) {
            UIApplication.shared.open(url)
        }
    }

    @objc private func aboutTapped() {
        let alert = UIAlertController(
            title: "关于我们",
            message: "AI图生图 v1.0\n上传图片，AI为你创作精美作品",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }

    @objc private func logoutTapped() {
        viewModel.logout()
        NotificationCenter.default.post(name: .logoutSelected, object: nil)
    }

    @objc private func handleLoginSuccess() {
        viewModel.loadUser()
    }
}

// MARK: - StatsItemView

private class StatsItemView: UIView {

    private lazy var stackView: UIStackView = {
        let sv = UIStackView(arrangedSubviews: [valueLabel, titleLabel])
        sv.axis = .vertical
        sv.spacing = Spacing.xs
        sv.alignment = .center
        return sv
    }()

    private let valueLabel: UILabel = {
        let label = UILabel()
        label.font = .heading
        label.textColor = .textPrimary
        label.textAlignment = .center
        return label
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .caption
        label.textColor = .textSecondary
        label.textAlignment = .center
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor)
        ])
    }

    func configure(value: String, title: String) {
        valueLabel.text = value
        titleLabel.text = title
    }
}

// MARK: - MenuItemButton

private class MenuItemButton: UIButton {

    private lazy var contentStack: UIStackView = {
        let sv = UIStackView(arrangedSubviews: [iconImageView, menuTitleLabel, chevronImageView])
        sv.axis = .horizontal
        sv.spacing = Spacing.md
        sv.alignment = .center
        sv.isUserInteractionEnabled = false
        return sv
    }()

    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let menuTitleLabel: UILabel = {
        let label = UILabel()
        label.font = .body
        return label
    }()

    private let chevronImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .regular)
        imageView.image = UIImage(systemName: "chevron.right", withConfiguration: config)
        imageView.tintColor = .textSecondary
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        backgroundColor = .cardBackground
        layer.cornerRadius = CornerRadius.sm
        clipsToBounds = true

        addSubview(contentStack)
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 48),

            contentStack.topAnchor.constraint(equalTo: topAnchor, constant: Spacing.md),
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Spacing.md),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Spacing.md),
            contentStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Spacing.md),

            iconImageView.widthAnchor.constraint(equalToConstant: 20),
            iconImageView.heightAnchor.constraint(equalToConstant: 20),
            chevronImageView.widthAnchor.constraint(equalToConstant: 14),
            chevronImageView.heightAnchor.constraint(equalToConstant: 14)
        ])

        menuTitleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        menuTitleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    }

    func configure(icon: String, title: String, isDestructive: Bool) {
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .regular)
        iconImageView.image = UIImage(systemName: icon, withConfiguration: config)

        menuTitleLabel.text = title

        if isDestructive {
            iconImageView.tintColor = .errorColor
            menuTitleLabel.textColor = .errorColor
        } else {
            iconImageView.tintColor = .textSecondary
            menuTitleLabel.textColor = .textPrimary
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        alpha = 0.7
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        alpha = 1.0
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        alpha = 1.0
    }
}
