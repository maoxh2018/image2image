import UIKit
import Combine
import QuartzCore

class GenerateViewController: UIViewController {

    // MARK: - Properties

    private let request: GenerationRequest
    private let viewModel = GenerateViewModel()
    private var cancellables = Set<AnyCancellable>()
    private var gradientLayer: CAGradientLayer!

    private var progressRingLayer: CAShapeLayer!
    private var progressTrackLayer: CAShapeLayer!

    private var particleLayers: [CALayer] = []

    // MARK: - UI Elements

    private let backgroundView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let contentStackView: UIStackView = {
        let sv = UIStackView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.axis = .vertical
        sv.spacing = Spacing.xl
        sv.alignment = .fill
        sv.layoutMargins = UIEdgeInsets(top: 0, left: Spacing.lg, bottom: 0, right: Spacing.lg)
        sv.isLayoutMarginsRelativeArrangement = true
        return sv
    }()

    // MARK: Header Section

    private let headerStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.alignment = .center
        sv.distribution = .fill
        return sv
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .subheading
        label.textColor = .textPrimary
        return label
    }()

    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .regular)
        button.setImage(UIImage(systemName: "xmark", withConfiguration: config), for: .normal)
        button.tintColor = .textSecondary
        button.isHidden = true
        return button
    }()

    // MARK: Generating Section

    private let generatingContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let progressContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let progressRingView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let progressPercentageLabel: UILabel = {
        let label = UILabel()
        label.font = .heading
        label.textColor = .textPrimary
        label.textAlignment = .center
        return label
    }()

    private let particleContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        return view
    }()

    private let generatingHintLabel: UILabel = {
        let label = UILabel()
        label.text = "AI正在创作中，请稍候..."
        label.font = .body
        label.textColor = .textSecondary
        label.textAlignment = .center
        return label
    }()

    // MARK: Completed Section

    private let completedContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()

    private let imageScrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.decelerationRate = .fast
        sv.minimumZoomScale = 1.0
        sv.maximumZoomScale = 4.0
        sv.showsHorizontalScrollIndicator = false
        sv.showsVerticalScrollIndicator = false
        return sv
    }()

    private let generatedImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.layer.cornerRadius = CornerRadius.lg
        iv.layer.masksToBounds = true
        iv.backgroundColor = .cardBackground
        return iv
    }()

    private let imageLoadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .textPrimary
        indicator.hidesWhenStopped = true
        return indicator
    }()

    private let actionButtonRow: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.spacing = Spacing.md
        sv.distribution = .fillEqually
        return sv
    }()

    private let regenerateButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("重新生成", for: .normal)
        button.titleLabel?.font = .button
        button.setTitleColor(.textPrimary, for: .normal)
        button.backgroundColor = .cardBackground
        button.layer.cornerRadius = CornerRadius.md
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.borderColor.cgColor
        return button
    }()

    private let saveButton: UIButton = {
        let button = UIButton(type: .system)
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "square.and.arrow.down", withConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .medium))
        config.title = "保存相册"
        config.imagePadding = 6
        config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: Spacing.md, bottom: 0, trailing: Spacing.md)
        config.baseForegroundColor = .textPrimary
        config.background.backgroundColor = .cardBackground
        config.background.cornerRadius = CornerRadius.md
        config.background.strokeWidth = 1
        config.background.strokeColor = .borderColor
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .button
            return outgoing
        }
        button.configuration = config
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let shareButton: UIButton = {
        let button = UIButton(type: .system)
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "square.and.arrow.up", withConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .medium))
        config.title = "分享"
        config.imagePadding = 6
        config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: Spacing.md, bottom: 0, trailing: Spacing.md)
        config.baseForegroundColor = .textPrimary
        config.background.backgroundColor = .cardBackground
        config.background.cornerRadius = CornerRadius.md
        config.background.strokeWidth = 1
        config.background.strokeColor = .borderColor
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .button
            return outgoing
        }
        button.configuration = config
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let copyPromptButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("复制Prompt", for: .normal)
        button.titleLabel?.font = .caption
        button.setTitleColor(.textSecondary, for: .normal)
        return button
    }()

    // MARK: Error Section

    private let errorContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()

    private let errorIconLabel: UIImageView = {
        let config = UIImage.SymbolConfiguration(pointSize: 40, weight: .regular)
        let imageView = UIImageView(image: UIImage(systemName: "exclamationmark.triangle", withConfiguration: config))
        imageView.tintColor = .errorColor
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let errorMessageLabel: UILabel = {
        let label = UILabel()
        label.font = .body
        label.textColor = .textSecondary
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let retryButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("重新生成", for: .normal)
        button.titleLabel?.font = .button
        button.setTitleColor(.textPrimary, for: .normal)
        button.layer.cornerRadius = CornerRadius.md
        button.clipsToBounds = true
        return button
    }()

    // MARK: Toast

    private let toastContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .cardBackground
        view.layer.cornerRadius = CornerRadius.md
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.3
        view.layer.shadowRadius = 10
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.isHidden = true
        view.alpha = 0
        return view
    }()

    private let toastIconLabel: UIImageView = {
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .regular)
        let imageView = UIImageView(image: UIImage(systemName: "checkmark", withConfiguration: config))
        imageView.tintColor = .success
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let toastMessageLabel: UILabel = {
        let label = UILabel()
        label.text = "保存成功"
        label.font = .body
        label.textColor = .textPrimary
        return label
    }()

    // MARK: - Initialization

    init(request: GenerationRequest) {
        self.request = request
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupBindings()
        setupActions()
        setupProgressRing()
        setupParticles()
        setupImageZoom()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewModel.startGeneration(request: request)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setupOrUpdateGradient()
        updateProgressRingPath()
        setupRetryButtonGradient()
    }

    // MARK: - Setup UI

    private func setupUI() {
        view.backgroundColor = .appBackground

        view.addSubview(backgroundView)
        view.addSubview(contentStackView)

        // Header
        headerStack.addArrangedSubview(titleLabel)
        headerStack.addArrangedSubview(closeButton)
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        closeButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        closeButton.setContentCompressionResistancePriority(.required, for: .horizontal)

        contentStackView.addArrangedSubview(headerStack)

        // Generating container
        setupGeneratingContainer()
        contentStackView.addArrangedSubview(generatingContainer)

        // Completed container
        setupCompletedContainer()
        contentStackView.addArrangedSubview(completedContainer)

        // Error container
        setupErrorContainer()
        contentStackView.addArrangedSubview(errorContainer)

        // Toast
        setupToast()
        view.addSubview(toastContainer)

        titleLabel.text = "生成中..."
    }

    private func setupGeneratingContainer() {
        generatingContainer.addSubview(progressContainer)
        generatingContainer.addSubview(particleContainerView)
        generatingContainer.addSubview(generatingHintLabel)

        progressContainer.addSubview(progressRingView)
        progressContainer.addSubview(progressPercentageLabel)

        NSLayoutConstraint.activate([
            progressContainer.topAnchor.constraint(equalTo: generatingContainer.topAnchor),
            progressContainer.centerXAnchor.constraint(equalTo: generatingContainer.centerXAnchor),
            progressContainer.widthAnchor.constraint(equalToConstant: 160),
            progressContainer.heightAnchor.constraint(equalToConstant: 160),

            progressRingView.centerXAnchor.constraint(equalTo: progressContainer.centerXAnchor),
            progressRingView.centerYAnchor.constraint(equalTo: progressContainer.centerYAnchor),
            progressRingView.widthAnchor.constraint(equalToConstant: 120),
            progressRingView.heightAnchor.constraint(equalToConstant: 120),

            progressPercentageLabel.centerXAnchor.constraint(equalTo: progressContainer.centerXAnchor),
            progressPercentageLabel.centerYAnchor.constraint(equalTo: progressContainer.centerYAnchor),

            particleContainerView.topAnchor.constraint(equalTo: progressContainer.bottomAnchor, constant: Spacing.xl),
            particleContainerView.centerXAnchor.constraint(equalTo: generatingContainer.centerXAnchor),
            particleContainerView.widthAnchor.constraint(equalToConstant: 200),
            particleContainerView.heightAnchor.constraint(equalToConstant: 200),

            generatingHintLabel.topAnchor.constraint(equalTo: particleContainerView.bottomAnchor, constant: Spacing.xl),
            generatingHintLabel.centerXAnchor.constraint(equalTo: generatingContainer.centerXAnchor),
            generatingHintLabel.bottomAnchor.constraint(equalTo: generatingContainer.bottomAnchor)
        ])
    }

    private func setupCompletedContainer() {
        completedContainer.addSubview(imageScrollView)
        imageScrollView.addSubview(generatedImageView)
        completedContainer.addSubview(imageLoadingIndicator)
        completedContainer.addSubview(actionButtonRow)
        completedContainer.addSubview(copyPromptButton)

        actionButtonRow.addArrangedSubview(regenerateButton)
        actionButtonRow.addArrangedSubview(saveButton)
        actionButtonRow.addArrangedSubview(shareButton)

        NSLayoutConstraint.activate([
            imageScrollView.topAnchor.constraint(equalTo: completedContainer.topAnchor),
            imageScrollView.leadingAnchor.constraint(equalTo: completedContainer.leadingAnchor),
            imageScrollView.trailingAnchor.constraint(equalTo: completedContainer.trailingAnchor),
            imageScrollView.heightAnchor.constraint(equalToConstant: 350),

            generatedImageView.topAnchor.constraint(equalTo: imageScrollView.topAnchor),
            generatedImageView.leadingAnchor.constraint(equalTo: imageScrollView.leadingAnchor),
            generatedImageView.trailingAnchor.constraint(equalTo: imageScrollView.trailingAnchor),
            generatedImageView.bottomAnchor.constraint(equalTo: imageScrollView.bottomAnchor),

            imageLoadingIndicator.centerXAnchor.constraint(equalTo: imageScrollView.centerXAnchor),
            imageLoadingIndicator.centerYAnchor.constraint(equalTo: imageScrollView.centerYAnchor),

            actionButtonRow.topAnchor.constraint(equalTo: imageScrollView.bottomAnchor, constant: Spacing.xl),
            actionButtonRow.leadingAnchor.constraint(equalTo: completedContainer.leadingAnchor),
            actionButtonRow.trailingAnchor.constraint(equalTo: completedContainer.trailingAnchor),
            actionButtonRow.heightAnchor.constraint(equalToConstant: Spacing.xl * 2),

            copyPromptButton.topAnchor.constraint(equalTo: actionButtonRow.bottomAnchor, constant: Spacing.md),
            copyPromptButton.centerXAnchor.constraint(equalTo: completedContainer.centerXAnchor),
            copyPromptButton.bottomAnchor.constraint(equalTo: completedContainer.bottomAnchor)
        ])
    }

    private func setupErrorContainer() {
        errorContainer.addSubview(errorIconLabel)
        errorContainer.addSubview(errorMessageLabel)
        errorContainer.addSubview(retryButton)

        NSLayoutConstraint.activate([
            errorIconLabel.topAnchor.constraint(equalTo: errorContainer.topAnchor),
            errorIconLabel.centerXAnchor.constraint(equalTo: errorContainer.centerXAnchor),
            errorIconLabel.heightAnchor.constraint(equalToConstant: 40),
            errorIconLabel.widthAnchor.constraint(equalToConstant: 40),

            errorMessageLabel.topAnchor.constraint(equalTo: errorIconLabel.bottomAnchor, constant: Spacing.lg),
            errorMessageLabel.leadingAnchor.constraint(equalTo: errorContainer.leadingAnchor),
            errorMessageLabel.trailingAnchor.constraint(equalTo: errorContainer.trailingAnchor),

            retryButton.topAnchor.constraint(equalTo: errorMessageLabel.bottomAnchor, constant: Spacing.lg),
            retryButton.centerXAnchor.constraint(equalTo: errorContainer.centerXAnchor),
            retryButton.widthAnchor.constraint(equalToConstant: 160),
            retryButton.heightAnchor.constraint(equalToConstant: Spacing.xl * 2),
            retryButton.bottomAnchor.constraint(equalTo: errorContainer.bottomAnchor)
        ])
    }

    private func setupToast() {
        toastContainer.addSubview(toastIconLabel)
        toastContainer.addSubview(toastMessageLabel)

        NSLayoutConstraint.activate([
            toastContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toastContainer.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            toastIconLabel.leadingAnchor.constraint(equalTo: toastContainer.leadingAnchor, constant: Spacing.lg),
            toastIconLabel.centerYAnchor.constraint(equalTo: toastContainer.centerYAnchor),
            toastIconLabel.widthAnchor.constraint(equalToConstant: 24),
            toastIconLabel.heightAnchor.constraint(equalToConstant: 24),

            toastMessageLabel.leadingAnchor.constraint(equalTo: toastIconLabel.trailingAnchor, constant: Spacing.sm),
            toastMessageLabel.trailingAnchor.constraint(equalTo: toastContainer.trailingAnchor, constant: -Spacing.lg),
            toastMessageLabel.topAnchor.constraint(equalTo: toastContainer.topAnchor, constant: Spacing.lg),
            toastMessageLabel.bottomAnchor.constraint(equalTo: toastContainer.bottomAnchor, constant: -Spacing.lg)
        ])
    }

    // MARK: - Constraints

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: Spacing.lg),
            contentStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -Spacing.lg)
        ])
    }

    // MARK: - Progress Ring

    private func setupProgressRing() {
        progressTrackLayer = CAShapeLayer()
        progressTrackLayer.strokeColor = UIColor.borderColor.cgColor
        progressTrackLayer.lineWidth = 8
        progressTrackLayer.fillColor = .none
        progressTrackLayer.lineCap = .round

        progressRingLayer = CAShapeLayer()
        progressRingLayer.strokeColor = UIColor.primary.cgColor
        progressRingLayer.lineWidth = 8
        progressRingLayer.fillColor = .none
        progressRingLayer.lineCap = .round
        progressRingLayer.strokeStart = 0
        progressRingLayer.strokeEnd = 0
        progressRingLayer.transform = CATransform3DMakeRotation(-CGFloat.pi / 2, 0, 0, 1)

        progressRingView.layer.addSublayer(progressTrackLayer)
        progressRingView.layer.addSublayer(progressRingLayer)
    }

    private func updateProgressRingPath() {
        let boundingRect = progressRingView.bounds
        let center = CGPoint(x: boundingRect.midX, y: boundingRect.midY)
        let radius = min(boundingRect.width, boundingRect.height) / 2 - 4
        let path = UIBezierPath(arcCenter: center, radius: radius, startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: true)

        progressTrackLayer.path = path.cgPath
        progressRingLayer.path = path.cgPath
    }

    private func updateProgressRing(_ progress: Int) {
        let fraction = min(max(CGFloat(progress) / 100.0, 0), 1)
        progressRingLayer.strokeEnd = fraction
        progressPercentageLabel.text = "\(progress)%"
    }

    // MARK: - Particle Animation

    private func setupParticles() {
        for layer in particleLayers {
            layer.removeFromSuperlayer()
        }
        particleLayers.removeAll()

        let particleCount = 20
        for i in 0..<particleCount {
            let particle = CALayer()
            let size = CGFloat.random(in: 2...8)
            let xPos = CGFloat.random(in: 0...200)
            let yPos = CGFloat.random(in: 0...200)
            let opacity = Float.random(in: 0.3...0.8)

            particle.frame = CGRect(x: xPos - size / 2, y: yPos - size / 2, width: size, height: size)
            particle.cornerRadius = size / 2
            particle.backgroundColor = UIColor.primary.cgColor
            particle.opacity = opacity

            particleContainerView.layer.addSublayer(particle)
            particleLayers.append(particle)

            let duration = CFTimeInterval.random(in: 2...4)
            let delay = CFTimeInterval.random(in: 0...duration)

            let fadeIn = CABasicAnimation(keyPath: "opacity")
            fadeIn.fromValue = 0
            fadeIn.toValue = opacity
            fadeIn.duration = duration / 2
            fadeIn.fillMode = .backwards
            fadeIn.beginTime = CACurrentMediaTime() + delay

            let pulse = CABasicAnimation(keyPath: "transform.scale")
            pulse.fromValue = 0.8
            pulse.toValue = 1.2
            pulse.duration = duration
            pulse.autoreverses = true
            pulse.repeatCount = .infinity
            pulse.beginTime = CACurrentMediaTime() + delay

            let group = CAAnimationGroup()
            group.animations = [fadeIn, pulse]
            group.duration = duration
            group.repeatCount = .infinity
            group.autoreverses = true

            particle.add(group, forKey: "particleAnim_\(i)")
        }
    }

    private func stopParticleAnimation() {
        for layer in particleLayers {
            layer.removeAllAnimations()
            layer.removeFromSuperlayer()
        }
        particleLayers.removeAll()
    }

    // MARK: - Image Zoom

    private func setupImageZoom() {
        imageScrollView.delegate = self

        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        imageScrollView.addGestureRecognizer(doubleTapGesture)
    }

    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        if imageScrollView.zoomScale > 1.01 {
            imageScrollView.setZoomScale(1.0, animated: true)
        } else {
            let location = gesture.location(in: generatedImageView)
            let zoomRect = zoomRectForScale(2.0, center: location)
            imageScrollView.zoom(to: zoomRect, animated: true)
        }
    }

    private func zoomRectForScale(_ scale: CGFloat, center: CGPoint) -> CGRect {
        let size = CGSize(width: imageScrollView.bounds.width / scale, height: imageScrollView.bounds.height / scale)
        return CGRect(x: center.x - size.width / 2, y: center.y - size.height / 2, width: size.width, height: size.height)
    }

    // MARK: - Actions

    private func setupActions() {
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        regenerateButton.addTarget(self, action: #selector(regenerateButtonTapped), for: .touchUpInside)
        saveButton.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
        shareButton.addTarget(self, action: #selector(shareButtonTapped), for: .touchUpInside)
        copyPromptButton.addTarget(self, action: #selector(copyPromptButtonTapped), for: .touchUpInside)
        retryButton.addTarget(self, action: #selector(retryButtonTapped), for: .touchUpInside)
    }

    @objc private func closeButtonTapped() {
        dismiss(animated: true)
    }

    @objc private func regenerateButtonTapped() {
        showGeneratingState()
        viewModel.regenerate(request: request)
    }

    @objc private func saveButtonTapped() {
        viewModel.saveToGallery()
    }

    @objc private func shareButtonTapped() {
        guard let image = generatedImageView.image else { return }
        shareImage(image, sourceView: shareButton)
    }

    @objc private func copyPromptButtonTapped() {
        UIPasteboard.general.string = request.prompt
        copyPromptButton.setTitle("已复制!", for: .normal)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.copyPromptButton.setTitle("复制Prompt", for: .normal)
        }
    }

    @objc private func retryButtonTapped() {
        showGeneratingState()
        viewModel.startGeneration(request: request)
    }

    // MARK: - Combine Bindings

    private func setupBindings() {
        viewModel.$status
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.updateUIForStatus(status)
            }
            .store(in: &cancellables)

        viewModel.$progress
            .receive(on: DispatchQueue.main)
            .sink { [weak self] progress in
                self?.updateProgressRing(progress)
            }
            .store(in: &cancellables)

        viewModel.$imageUrl
            .receive(on: DispatchQueue.main)
            .sink { [weak self] imageUrl in
                guard let self = self, !imageUrl.isEmpty else { return }
                self.loadImage(from: imageUrl)
            }
            .store(in: &cancellables)

        viewModel.$errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] errorMessage in
                guard let self = self, !errorMessage.isEmpty else { return }
                self.errorMessageLabel.text = errorMessage
            }
            .store(in: &cancellables)

        viewModel.$showSaveSuccess
            .receive(on: DispatchQueue.main)
            .sink { [weak self] show in
                self?.toggleToast(show)
            }
            .store(in: &cancellables)
    }

    // MARK: - UI State Management

    private func updateUIForStatus(_ status: GenerationStatus) {
        switch status {
        case .pending, .generating:
            showGeneratingState()
        case .completed:
            showCompletedState()
        case .failed:
            showFailedState()
        }
    }

    private func showGeneratingState() {
        titleLabel.text = "生成中..."
        closeButton.isHidden = true
        generatingContainer.isHidden = false
        completedContainer.isHidden = true
        errorContainer.isHidden = true
        progressPercentageLabel.text = "0%"
        progressRingLayer.strokeEnd = 0
        imageLoadingIndicator.stopAnimating()
        generatedImageView.image = nil
        generatedImageView.transform = .identity
        imageScrollView.zoomScale = 1.0
        setupParticles()
    }

    private func showCompletedState() {
        titleLabel.text = "生成完成"
        closeButton.isHidden = false
        generatingContainer.isHidden = true
        completedContainer.isHidden = false
        errorContainer.isHidden = true
        stopParticleAnimation()
    }

    private func showFailedState() {
        titleLabel.text = "生成中..."
        closeButton.isHidden = true
        generatingContainer.isHidden = true
        completedContainer.isHidden = true
        errorContainer.isHidden = false
        stopParticleAnimation()
    }

    // MARK: - Image Loading

    private func loadImage(from urlString: String) {
        guard let url = URL(string: urlString) else { return }
        imageLoadingIndicator.startAnimating()

        ImageLoader.shared.loadImage(from: url) { [weak self] image in
            guard let self = self else { return }
            self.imageLoadingIndicator.stopAnimating()
            if let image = image {
                self.generatedImageView.image = image
                self.updateImageLayout(for: image)
            }
        }
    }

    private func updateImageLayout(for image: UIImage) {
        let scrollViewSize = imageScrollView.bounds.size
        let aspectRatio = image.size.width / image.size.height

        var fitSize: CGSize
        if aspectRatio > scrollViewSize.width / scrollViewSize.height {
            fitSize = CGSize(width: scrollViewSize.width, height: scrollViewSize.width / aspectRatio)
        } else {
            fitSize = CGSize(width: scrollViewSize.height * aspectRatio, height: scrollViewSize.height)
        }

        generatedImageView.frame = CGRect(origin: .zero, size: fitSize)
        imageScrollView.contentSize = fitSize

        let horizontalInset = max(0, (scrollViewSize.width - fitSize.width) / 2)
        let verticalInset = max(0, (scrollViewSize.height - fitSize.height) / 2)
        imageScrollView.contentInset = UIEdgeInsets(top: verticalInset, left: horizontalInset, bottom: verticalInset, right: horizontalInset)
    }

    // MARK: - Toast

    private func toggleToast(_ show: Bool) {
        if show {
            toastContainer.isHidden = false
            toastContainer.alpha = 0
            UIView.animate(withDuration: 0.3) { [weak self] in
                self?.toastContainer.alpha = 1
            }
        } else {
            UIView.animate(withDuration: 0.3, animations: { [weak self] in
                self?.toastContainer.alpha = 0
            }) { [weak self] _ in
                self?.toastContainer.isHidden = true
            }
        }
    }

    // MARK: - Gradients

    private func setupOrUpdateGradient() {
        if gradientLayer == nil {
            let gradient = CAGradientLayer()
            gradient.frame = backgroundView.bounds
            gradient.colors = GradientColors.backgroundGradient.map { $0.cgColor }
            gradient.startPoint = CGPoint(x: 0.5, y: 0)
            gradient.endPoint = CGPoint(x: 0.5, y: 1)
            gradientLayer = gradient
            backgroundView.layer.insertSublayer(gradientLayer, at: 0)
        } else {
            gradientLayer.frame = backgroundView.bounds
        }
    }

    private func setupRetryButtonGradient() {
        guard let gradient = retryButton.layer.sublayers?.first as? CAGradientLayer else {
            let gradient = CAGradientLayer()
            gradient.frame = retryButton.bounds
            gradient.colors = GradientColors.primaryGradient.map { $0.cgColor }
            gradient.startPoint = CGPoint(x: 0, y: 0.5)
            gradient.endPoint = CGPoint(x: 1, y: 0.5)
            gradient.cornerRadius = CornerRadius.md
            retryButton.layer.insertSublayer(gradient, at: 0)
            return
        }
        gradient.frame = retryButton.bounds
    }
}

// MARK: - Image Loader

final class ImageLoader {
    static let shared = ImageLoader()
    private let session: URLSession

    private init(session: URLSession = .shared) {
        self.session = session
    }

    func loadImage(from url: URL, completion: @escaping (UIImage?) -> Void) {
        session.dataTask(with: url) { data, response, error in
            if let data = data, error == nil,
               let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    completion(image)
                }
            } else {
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }.resume()
    }
}

// MARK: - UIScrollViewDelegate

extension GenerateViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return generatedImageView
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        let boundsSize = scrollView.bounds.size
        let imageViewSize = generatedImageView.frame.size

        let horizontalInset = max(0, (boundsSize.width - imageViewSize.width) / 2)
        let verticalInset = max(0, (boundsSize.height - imageViewSize.height) / 2)
        scrollView.contentInset = UIEdgeInsets(top: verticalInset, left: horizontalInset, bottom: verticalInset, right: horizontalInset)
    }
}