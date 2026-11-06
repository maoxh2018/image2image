import UIKit
import StoreKit
import Combine
import QuartzCore

class SubscriptionViewController: UIViewController {

    // MARK: - Properties

    private let backgroundGradientLayer = CAGradientLayer()
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let monthlyButton = UIButton(type: .system)
    private let monthlyButtonGradientLayer = CAGradientLayer()
    private let yearlyButton = UIButton(type: .system)
    private let yearlyButtonGradientLayer = CAGradientLayer()
    private let restoreButton = UIButton(type: .system)
    private let cancelButton = UIButton(type: .system)

    private let subscriptionManager = SubscriptionManager.shared
    private var products: [Product] = []
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()

        Task {
            await loadProducts()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        backgroundGradientLayer.frame = view.bounds
        monthlyButtonGradientLayer.frame = monthlyButton.bounds
        yearlyButtonGradientLayer.frame = yearlyButton.bounds
    }

    // MARK: - Bindings

    private func setupBindings() {
        subscriptionManager.$isSubscribed
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateSubscriptionState()
            }
            .store(in: &cancellables)

        subscriptionManager.$remainingCount
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateSubscriptionState()
            }
            .store(in: &cancellables)
    }

    // MARK: - Load Products

    private func loadProducts() async {
        do {
            products = try await subscriptionManager.loadProducts()
            updateProductButtons()
        } catch {
            print("加载产品失败: \(error)")
        }
        updateSubscriptionState()
    }

    private func updateProductButtons() {
        guard !subscriptionManager.isSubscribed else {
            updateSubscriptionState()
            return
        }

        for product in products {
            if product.id == Config.monthlyProductId {
                monthlyButton.setTitle("月度订阅 - \(product.displayPrice)", for: .normal)
            } else if product.id == Config.yearlyProductId {
                yearlyButton.setTitle("年度订阅 - \(product.displayPrice)", for: .normal)
            }
        }
    }

    /// 根据订阅状态更新 UI：已订阅则禁用按钮并显示“已订阅”
    private func updateSubscriptionState() {
        if subscriptionManager.isSubscribed {
            titleLabel.text = "订阅生效中"
            descriptionLabel.text = "您当前已订阅，剩余生成次数：\(subscriptionManager.remainingCount)"

            monthlyButton.setTitle("已订阅", for: .normal)
            monthlyButton.isEnabled = false
            monthlyButtonGradientLayer.isHidden = true
            monthlyButton.backgroundColor = .cardBackground
            monthlyButton.setTitleColor(.textSecondary, for: .disabled)
            monthlyButton.layer.shadowOpacity = 0

            yearlyButton.setTitle("已订阅", for: .normal)
            yearlyButton.isEnabled = false
            yearlyButtonGradientLayer.isHidden = true
            yearlyButton.backgroundColor = .cardBackground
            yearlyButton.setTitleColor(.textSecondary, for: .disabled)
            yearlyButton.layer.shadowOpacity = 0
        } else {
            titleLabel.text = "选择订阅方案"
            descriptionLabel.text = "订阅后即可使用图生图功能，每月 \(Config.maxGenerationCount) 次生成额度"

            monthlyButton.isEnabled = true
            monthlyButtonGradientLayer.isHidden = false
            monthlyButton.backgroundColor = .clear
            monthlyButton.setTitleColor(.white, for: .normal)
            monthlyButton.layer.shadowOpacity = 0.5

            yearlyButton.isEnabled = true
            yearlyButtonGradientLayer.isHidden = false
            yearlyButton.backgroundColor = .clear
            yearlyButton.setTitleColor(.white, for: .normal)
            yearlyButton.layer.shadowOpacity = 0.5

            updateProductButtons()
        }
    }

    // MARK: - Setup UI

    private func setupUI() {
        setupBackgroundGradient()
        setupTitleLabel()
        setupDescriptionLabel()
        setupMonthlyButton()
        setupYearlyButton()
        setupRestoreButton()
        setupCancelButton()
        setupConstraints()
    }

    private func setupBackgroundGradient() {
        backgroundGradientLayer.colors = GradientColors.backgroundGradient.map { $0.cgColor }
        backgroundGradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        backgroundGradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        view.layer.insertSublayer(backgroundGradientLayer, at: 0)
    }

    private func setupTitleLabel() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .heading
        titleLabel.textColor = .textPrimary
        titleLabel.textAlignment = .center
        view.addSubview(titleLabel)
    }

    private func setupDescriptionLabel() {
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.textAlignment = .center
        descriptionLabel.textColor = .textSecondary
        descriptionLabel.font = .body
        descriptionLabel.numberOfLines = 0
        view.addSubview(descriptionLabel)
    }

    private func setupMonthlyButton() {
        monthlyButton.translatesAutoresizingMaskIntoConstraints = false
        monthlyButton.setTitle("月度订阅 - 加载中...", for: .normal)
        monthlyButton.setTitleColor(.white, for: .normal)
        monthlyButton.titleLabel?.font = .button
        monthlyButton.layer.cornerRadius = CornerRadius.md
        monthlyButton.layer.masksToBounds = true
        monthlyButton.layer.shadowColor = UIColor.primary.cgColor
        monthlyButton.layer.shadowOpacity = 0.5
        monthlyButton.layer.shadowRadius = 12
        monthlyButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        monthlyButton.addTarget(self, action: #selector(monthlySubscriptionTapped), for: .touchUpInside)

        monthlyButtonGradientLayer.colors = GradientColors.primaryGradient.map { $0.cgColor }
        monthlyButtonGradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        monthlyButtonGradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        monthlyButton.layer.insertSublayer(monthlyButtonGradientLayer, at: 0)

        view.addSubview(monthlyButton)
    }

    private func setupYearlyButton() {
        yearlyButton.translatesAutoresizingMaskIntoConstraints = false
        yearlyButton.setTitle("年度订阅 - 加载中...", for: .normal)
        yearlyButton.setTitleColor(.white, for: .normal)
        yearlyButton.titleLabel?.font = .button
        yearlyButton.layer.cornerRadius = CornerRadius.md
        yearlyButton.layer.masksToBounds = true
        yearlyButton.layer.shadowColor = UIColor.primary.cgColor
        yearlyButton.layer.shadowOpacity = 0.5
        yearlyButton.layer.shadowRadius = 12
        yearlyButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        yearlyButton.addTarget(self, action: #selector(yearlySubscriptionTapped), for: .touchUpInside)

        yearlyButtonGradientLayer.colors = GradientColors.accentGradient.map { $0.cgColor }
        yearlyButtonGradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        yearlyButtonGradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        yearlyButton.layer.insertSublayer(yearlyButtonGradientLayer, at: 0)

        view.addSubview(yearlyButton)
    }

    private func setupRestoreButton() {
        restoreButton.translatesAutoresizingMaskIntoConstraints = false
        restoreButton.setTitle("恢复购买", for: .normal)
        restoreButton.setTitleColor(.textSecondary, for: .normal)
        restoreButton.titleLabel?.font = .body
        restoreButton.addTarget(self, action: #selector(restorePurchaseTapped), for: .touchUpInside)
        view.addSubview(restoreButton)
    }

    private func setupCancelButton() {
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.setTitle("取消", for: .normal)
        cancelButton.setTitleColor(.errorColor, for: .normal)
        cancelButton.titleLabel?.font = .body
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        view.addSubview(cancelButton)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: Spacing.xxl),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Spacing.lg),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Spacing.lg),

            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: Spacing.md),
            descriptionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Spacing.xl),
            descriptionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Spacing.xl)
        ])

        NSLayoutConstraint.activate([
            monthlyButton.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: Spacing.xxl),
            monthlyButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Spacing.xl),
            monthlyButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Spacing.xl),
            monthlyButton.heightAnchor.constraint(equalToConstant: 52),

            yearlyButton.topAnchor.constraint(equalTo: monthlyButton.bottomAnchor, constant: Spacing.lg),
            yearlyButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Spacing.xl),
            yearlyButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Spacing.xl),
            yearlyButton.heightAnchor.constraint(equalToConstant: 52)
        ])

        NSLayoutConstraint.activate([
            restoreButton.topAnchor.constraint(equalTo: yearlyButton.bottomAnchor, constant: Spacing.xl),
            restoreButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            cancelButton.topAnchor.constraint(equalTo: restoreButton.bottomAnchor, constant: Spacing.md),
            cancelButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            cancelButton.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -Spacing.xxl)
        ])
    }

    // MARK: - Actions

    @objc private func monthlySubscriptionTapped() {
        if let product = products.first(where: { $0.id == Config.monthlyProductId }) {
            Task {
                await performPurchase(product: product)
            }
        } else {
            // 未配置真实内购产品，使用模拟订阅
            subscriptionManager.subscribe()
            showAlert(title: "订阅成功", message: "您已成功订阅，可以开始使用图生图功能了！") { [weak self] in
                self?.dismiss(animated: true)
            }
        }
    }

    @objc private func yearlySubscriptionTapped() {
        if let product = products.first(where: { $0.id == Config.yearlyProductId }) {
            Task {
                await performPurchase(product: product)
            }
        } else {
            // 未配置真实内购产品，使用模拟订阅
            subscriptionManager.subscribe()
            showAlert(title: "订阅成功", message: "您已成功订阅，可以开始使用图生图功能了！") { [weak self] in
                self?.dismiss(animated: true)
            }
        }
    }

    @objc private func restorePurchaseTapped() {
        Task {
            do {
                try await subscriptionManager.restorePurchase()
                showAlert(title: "恢复成功", message: "您的订阅已成功恢复") { [weak self] in
                    self?.dismiss(animated: true)
                }
            } catch {
                showAlert(title: "恢复失败", message: "无法恢复购买，请稍后重试。")
            }
        }
    }

    @objc private func cancelTapped() {
        dismiss(animated: true, completion: nil)
    }

    // MARK: - Purchase

    private func performPurchase(product: Product) async {
        do {
            let result = try await subscriptionManager.purchaseProduct(product)

            switch result {
            case .success:
                showAlert(title: "订阅成功", message: "您已成功订阅，可以开始使用图生图功能了！") { [weak self] in
                    self?.dismiss(animated: true)
                }

            case .cancelled:
                print("用户取消购买")

            case .pending:
                print("购买待处理")
            }
        } catch {
            showAlert(title: "订阅失败", message: "订阅处理失败，请稍后重试。")
        }
    }

    // MARK: - Alert

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }

    private func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default) { _ in
            completion?()
        })
        present(alert, animated: true)
    }
}
