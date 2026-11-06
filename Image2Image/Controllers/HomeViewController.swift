import UIKit
import Combine
import QuartzCore

class HomeViewController: UIViewController, UITextViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    // MARK: - Properties

    private let viewModel = HomeViewModel()
    private var cancellables = Set<AnyCancellable>()
    private var gradientLayer: CAGradientLayer!

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

    private let stackView: UIStackView = {
        let sv = UIStackView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.axis = .vertical
        sv.spacing = Spacing.lg
        sv.alignment = .fill
        sv.layoutMargins = UIEdgeInsets(top: 0, left: Spacing.lg, bottom: 0, right: Spacing.lg)
        sv.isLayoutMarginsRelativeArrangement = true
        return sv
    }()

    // MARK: Title Section

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "AI图生图"
        label.font = .heading
        label.textColor = .textPrimary
        label.textAlignment = .center
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "选择图片，让AI为你创作新风格"
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

    // MARK: Image Upload Section

    private let imageUploadContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .inputBackground
        view.layer.cornerRadius = CornerRadius.md
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.borderColor.cgColor
        view.clipsToBounds = true
        return view
    }()

    private let placeholderView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let photoIconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        let config = UIImage.SymbolConfiguration(pointSize: 40, weight: .light)
        imageView.image = UIImage(systemName: "photo", withConfiguration: config)
        imageView.tintColor = .textSecondary
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let placeholderLabel: UILabel = {
        let label = UILabel()
        label.text = "点击选择图片"
        label.font = .body
        label.textColor = .textSecondary
        label.textAlignment = .center
        return label
    }()

    private lazy var placeholderStack: UIStackView = {
        let sv = UIStackView(arrangedSubviews: [photoIconImageView, placeholderLabel])
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.axis = .vertical
        sv.spacing = Spacing.md
        sv.alignment = .center
        return sv
    }()

    private let selectedImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = CornerRadius.md
        imageView.isHidden = true
        return imageView
    }()

    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .bold)
        button.setImage(UIImage(systemName: "xmark", withConfiguration: config), for: .normal)
        button.tintColor = .white
        button.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        button.layer.cornerRadius = CornerRadius.sm
        button.isHidden = true
        return button
    }()

    // MARK: Prompt Section

    private let promptLabel: UILabel = {
        let label = UILabel()
        label.text = "Prompt"
        label.font = .caption
        label.textColor = .textSecondary
        return label
    }()

    private let promptTextView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.font = .body
        textView.textColor = .textPrimary
        textView.backgroundColor = .inputBackground
        textView.layer.cornerRadius = CornerRadius.md
        textView.layer.borderWidth = 1
        textView.layer.borderColor = UIColor.borderColor.cgColor
        textView.textContainerInset = UIEdgeInsets(top: Spacing.md, left: Spacing.md, bottom: Spacing.md, right: Spacing.md)
        textView.textContainer.lineFragmentPadding = 0
        textView.isScrollEnabled = false
        return textView
    }()

    private let promptPlaceholderLabel: UILabel = {
        let label = UILabel()
        label.text = "描述你想要的效果，例如：转换为油画风格"
        label.font = .body
        label.textColor = .textSecondary
        label.numberOfLines = 0
        return label
    }()

    private let characterCountLabel: UILabel = {
        let label = UILabel()
        label.font = .small
        label.textColor = .textSecondary
        label.textAlignment = .right
        label.text = "0/500"
        return label
    }()

    private lazy var promptSectionStack: UIStackView = {
        let sv = UIStackView(arrangedSubviews: [promptLabel, promptTextView, characterCountLabel])
        sv.axis = .vertical
        sv.spacing = Spacing.xs
        sv.alignment = .fill
        return sv
    }()

    // MARK: Options Section

    private lazy var modelOptionButton: UIButton = {
        let button = createIconOptionButton(icon: "cpu", action: #selector(modelOptionTapped))
        return button
    }()

    private lazy var aspectRatioOptionButton: UIButton = {
        let button = createIconOptionButton(icon: "aspectratio", action: #selector(aspectRatioOptionTapped))
        return button
    }()

    private lazy var styleOptionButton: UIButton = {
        let button = createIconOptionButton(icon: "paintpalette", action: #selector(styleOptionTapped))
        return button
    }()

    private func createIconOptionButton(icon: String, action: Selector) -> UIButton {
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        let image = UIImage(systemName: icon, withConfiguration: config)

        var buttonConfig = UIButton.Configuration.plain()
        buttonConfig.image = image
        buttonConfig.contentInsets = NSDirectionalEdgeInsets(top: Spacing.sm, leading: Spacing.sm, bottom: Spacing.sm, trailing: Spacing.sm)
        buttonConfig.baseForegroundColor = .textPrimary
        buttonConfig.background.backgroundColor = .inputBackground
        buttonConfig.background.cornerRadius = CornerRadius.sm
        buttonConfig.background.strokeWidth = 1
        buttonConfig.background.strokeColor = .borderColor

        let button = UIButton(configuration: buttonConfig)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: action, for: .touchUpInside)

        let size: CGFloat = 36
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: size),
            button.heightAnchor.constraint(equalToConstant: size)
        ])
        return button
    }

    private lazy var optionsStack: UIStackView = {
        let sv = UIStackView(arrangedSubviews: [modelOptionButton, aspectRatioOptionButton, styleOptionButton])
        sv.axis = .horizontal
        sv.spacing = Spacing.sm
        sv.distribution = .fill
        sv.alignment = .center
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

    private let generateButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("生成图像", for: .normal)
        button.titleLabel?.font = .button
        button.setTitleColor(.textPrimary, for: .normal)
        button.layer.cornerRadius = CornerRadius.md
        button.clipsToBounds = true
        button.alpha = 0.5
        return button
    }()

    // MARK: Direct Generate Button

    private let directGenerateButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("生成图片", for: .normal)
        button.titleLabel?.font = .button
        button.setTitleColor(.textPrimary, for: .normal)
        button.layer.cornerRadius = CornerRadius.md
        button.layer.borderWidth = 0
        button.alpha = 0.5
        return button
    }()

    // MARK: Result Section

    private let resultContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .cardBackground
        view.layer.cornerRadius = CornerRadius.md
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.borderColor.cgColor
        view.clipsToBounds = true
        return view
    }()

    private let resultImageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFit
        iv.clipsToBounds = true
        iv.isHidden = true
        iv.isUserInteractionEnabled = true
        return iv
    }()

    // 图片上悬浮的保存 / 分享图标按钮
    private lazy var resultSaveButton: UIButton = makeFloatingActionButton(icon: "square.and.arrow.down", action: #selector(resultSaveTapped))
    private lazy var resultShareButton: UIButton = makeFloatingActionButton(icon: "square.and.arrow.up", action: #selector(resultShareTapped))

    private func makeFloatingActionButton(icon: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        button.setImage(UIImage(systemName: icon, withConfiguration: config), for: .normal)
        button.tintColor = .white
        button.backgroundColor = UIColor.black.withAlphaComponent(0.55)
        button.layer.cornerRadius = 18
        button.clipsToBounds = true
        button.isHidden = true
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    private let resultPlaceholderLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "生成结果将显示在这里"
        label.font = .body
        label.textColor = .textSecondary
        label.textAlignment = .center
        return label
    }()

    private let resultLoadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.color = .textPrimary
        indicator.hidesWhenStopped = true
        return indicator
    }()

    // MARK: - Properties

    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.color = .white
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()

    private lazy var buttonContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupBindings()
        setupKeyboardObservers()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Setup UI

    private func setupUI() {
        view.backgroundColor = .appBackground

        view.addSubview(backgroundView)
        view.addSubview(scrollView)
        scrollView.addSubview(stackView)

        stackView.addArrangedSubview(titleStack)
        stackView.addArrangedSubview(imageUploadContainer)
        stackView.addArrangedSubview(promptSectionStack)
        stackView.addArrangedSubview(optionsStack)
        stackView.addArrangedSubview(buttonContainer)
        stackView.addArrangedSubview(directGenerateButton)
        stackView.addArrangedSubview(errorLabel)
        stackView.addArrangedSubview(resultContainerView)

        titleStack.setCustomSpacing(Spacing.xl, after: titleStack)
        stackView.setCustomSpacing(0, after: promptSectionStack)
        // 紧贴 prompt 区域的所有元素整体上移 5px（customSpacing 最小为 0，用 transform 补偿）
        let up5 = CGAffineTransform(translationX: 0, y: -5)
        optionsStack.transform = up5
        buttonContainer.transform = up5
        directGenerateButton.transform = up5
        errorLabel.transform = up5
        resultContainerView.transform = up5
        stackView.setCustomSpacing(Spacing.sm, after: optionsStack)
        stackView.setCustomSpacing(Spacing.sm, after: buttonContainer)

        // Result container subviews
        resultContainerView.addSubview(resultPlaceholderLabel)
        resultContainerView.addSubview(resultImageView)
        resultContainerView.addSubview(resultLoadingIndicator)
        resultContainerView.addSubview(resultSaveButton)
        resultContainerView.addSubview(resultShareButton)

        let resultLongPress = UILongPressGestureRecognizer(target: self, action: #selector(resultImageLongPressed(_:)))
        resultImageView.addGestureRecognizer(resultLongPress)

        NSLayoutConstraint.activate([
            directGenerateButton.heightAnchor.constraint(equalToConstant: Spacing.xl * 2),

            resultContainerView.heightAnchor.constraint(equalToConstant: 200),

            resultPlaceholderLabel.centerXAnchor.constraint(equalTo: resultContainerView.centerXAnchor),
            resultPlaceholderLabel.centerYAnchor.constraint(equalTo: resultContainerView.centerYAnchor),

            resultImageView.topAnchor.constraint(equalTo: resultContainerView.topAnchor, constant: Spacing.sm - 10),
            resultImageView.leadingAnchor.constraint(equalTo: resultContainerView.leadingAnchor, constant: Spacing.sm),
            resultImageView.trailingAnchor.constraint(equalTo: resultContainerView.trailingAnchor, constant: -Spacing.sm),
            resultImageView.bottomAnchor.constraint(equalTo: resultContainerView.bottomAnchor, constant: -Spacing.sm),

            resultShareButton.trailingAnchor.constraint(equalTo: resultContainerView.trailingAnchor, constant: -Spacing.sm),
            resultShareButton.topAnchor.constraint(equalTo: resultContainerView.topAnchor, constant: Spacing.sm),
            resultShareButton.widthAnchor.constraint(equalToConstant: 36),
            resultShareButton.heightAnchor.constraint(equalToConstant: 36),

            resultSaveButton.trailingAnchor.constraint(equalTo: resultShareButton.leadingAnchor, constant: -Spacing.xs),
            resultSaveButton.centerYAnchor.constraint(equalTo: resultShareButton.centerYAnchor),
            resultSaveButton.widthAnchor.constraint(equalToConstant: 36),
            resultSaveButton.heightAnchor.constraint(equalToConstant: 36),

            resultLoadingIndicator.centerXAnchor.constraint(equalTo: resultContainerView.centerXAnchor),
            resultLoadingIndicator.centerYAnchor.constraint(equalTo: resultContainerView.centerYAnchor)
        ])

        // Image upload container subviews
        imageUploadContainer.addSubview(placeholderView)
        imageUploadContainer.addSubview(selectedImageView)
        imageUploadContainer.addSubview(closeButton)

        placeholderView.addSubview(placeholderStack)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(imageUploadTapped))
        placeholderView.addGestureRecognizer(tapGesture)
        placeholderView.isUserInteractionEnabled = true

        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        generateButton.addTarget(self, action: #selector(generateButtonTapped), for: .touchUpInside)
        directGenerateButton.addTarget(self, action: #selector(directGenerateButtonTapped), for: .touchUpInside)

        promptTextView.delegate = self

        promptTextView.addSubview(promptPlaceholderLabel)
        promptPlaceholderLabel.isUserInteractionEnabled = false

        setupGenerateButtonGradient()
        setupDirectGenerateButtonGradient()

        buttonContainer.addSubview(generateButton)

        directGenerateButton.addSubview(loadingIndicator)
        directGenerateButton.clipsToBounds = false

        NSLayoutConstraint.activate([
            generateButton.topAnchor.constraint(equalTo: buttonContainer.topAnchor),
            generateButton.leadingAnchor.constraint(equalTo: buttonContainer.leadingAnchor),
            generateButton.trailingAnchor.constraint(equalTo: buttonContainer.trailingAnchor),
            generateButton.heightAnchor.constraint(equalToConstant: Spacing.xl * 2),
            generateButton.bottomAnchor.constraint(equalTo: buttonContainer.bottomAnchor),

            loadingIndicator.centerXAnchor.constraint(equalTo: directGenerateButton.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: directGenerateButton.centerYAnchor),
            loadingIndicator.widthAnchor.constraint(equalToConstant: 20),
            loadingIndicator.heightAnchor.constraint(equalToConstant: 20)
        ])

        NSLayoutConstraint.activate([
            imageUploadContainer.heightAnchor.constraint(equalToConstant: 200),

            placeholderView.topAnchor.constraint(equalTo: imageUploadContainer.topAnchor),
            placeholderView.leadingAnchor.constraint(equalTo: imageUploadContainer.leadingAnchor),
            placeholderView.trailingAnchor.constraint(equalTo: imageUploadContainer.trailingAnchor),
            placeholderView.bottomAnchor.constraint(equalTo: imageUploadContainer.bottomAnchor),

            placeholderStack.centerXAnchor.constraint(equalTo: placeholderView.centerXAnchor),
            placeholderStack.centerYAnchor.constraint(equalTo: placeholderView.centerYAnchor),

            photoIconImageView.widthAnchor.constraint(equalToConstant: 48),
            photoIconImageView.heightAnchor.constraint(equalToConstant: 48),

            selectedImageView.topAnchor.constraint(equalTo: imageUploadContainer.topAnchor),
            selectedImageView.leadingAnchor.constraint(equalTo: imageUploadContainer.leadingAnchor),
            selectedImageView.trailingAnchor.constraint(equalTo: imageUploadContainer.trailingAnchor),
            selectedImageView.bottomAnchor.constraint(equalTo: imageUploadContainer.bottomAnchor),

            closeButton.topAnchor.constraint(equalTo: imageUploadContainer.topAnchor, constant: Spacing.sm),
            closeButton.trailingAnchor.constraint(equalTo: imageUploadContainer.trailingAnchor, constant: -Spacing.sm),
            closeButton.widthAnchor.constraint(equalToConstant: 28),
            closeButton.heightAnchor.constraint(equalToConstant: 28),

            promptTextView.heightAnchor.constraint(equalToConstant: 100),

            promptPlaceholderLabel.topAnchor.constraint(equalTo: promptTextView.topAnchor, constant: Spacing.md),
            promptPlaceholderLabel.leadingAnchor.constraint(equalTo: promptTextView.leadingAnchor, constant: Spacing.md + 4),
            promptPlaceholderLabel.trailingAnchor.constraint(lessThanOrEqualTo: promptTextView.trailingAnchor, constant: -Spacing.md)
        ])
    }

    private func setupGenerateButtonGradient() {
        let gradient = CAGradientLayer()
        gradient.frame = CGRect(x: 0, y: 0, width: 400, height: Spacing.xl * 2)
        gradient.colors = GradientColors.primaryGradient.map { $0.cgColor }
        gradient.startPoint = CGPoint(x: 0, y: 0.5)
        gradient.endPoint = CGPoint(x: 1, y: 0.5)
        gradient.cornerRadius = CornerRadius.md
        generateButton.layer.insertSublayer(gradient, at: 0)
    }

    private func setupDirectGenerateButtonGradient() {
        let gradient = CAGradientLayer()
        gradient.frame = CGRect(x: 0, y: 0, width: 400, height: Spacing.xl * 2)
        gradient.colors = GradientColors.primaryGradient.map { $0.cgColor }
        gradient.startPoint = CGPoint(x: 0, y: 0.5)
        gradient.endPoint = CGPoint(x: 1, y: 0.5)
        gradient.cornerRadius = CornerRadius.md
        directGenerateButton.layer.insertSublayer(gradient, at: 0)
    }

    // MARK: - Constraints

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: Spacing.xl),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -Spacing.lg),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }

    // MARK: - Combine Bindings

    private func setupBindings() {
        viewModel.$selectedImage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] image in
                self?.updateImageState(image)
            }
            .store(in: &cancellables)

        viewModel.$prompt
            .receive(on: DispatchQueue.main)
            .sink { [weak self] text in
                self?.updatePromptState(text)
                self?.updateGenerateButtonState()
            }
            .store(in: &cancellables)

        viewModel.$model
            .receive(on: DispatchQueue.main)
            .sink { [weak self] model in
                self?.updateModelState(model)
            }
            .store(in: &cancellables)

        viewModel.$aspectRatio
            .receive(on: DispatchQueue.main)
            .sink { [weak self] ratio in
                self?.updateAspectRatioState(ratio)
            }
            .store(in: &cancellables)

        viewModel.$style
            .receive(on: DispatchQueue.main)
            .sink { [weak self] style in
                self?.updateStyleState(style)
            }
            .store(in: &cancellables)

        viewModel.$isGenerating
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isGenerating in
                self?.updateGeneratingState(isGenerating)
            }
            .store(in: &cancellables)

        viewModel.$errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] errorMessage in
                self?.updateErrorMessage(errorMessage)
            }
            .store(in: &cancellables)
        
        // Initial state
        updateModelState(viewModel.model)
        updateAspectRatioState(viewModel.aspectRatio)
        updateStyleState(viewModel.style)
    }

    // MARK: - UI State Updates

    private func updateImageState(_ image: UIImage?) {
        if let image = image {
            selectedImageView.image = image
            selectedImageView.isHidden = false
            placeholderView.isHidden = true
            closeButton.isHidden = false
        } else {
            selectedImageView.image = nil
            selectedImageView.isHidden = true
            placeholderView.isHidden = false
            closeButton.isHidden = true
        }
        updateGenerateButtonState()
    }

    private func updatePromptState(_ text: String) {
        if promptTextView.text != text {
            promptTextView.text = text
        }
        promptPlaceholderLabel.isHidden = !text.isEmpty
        characterCountLabel.text = "\(text.count)/500"
    }

    private func updateModelState(_ model: ImageModel) {
        // style 只有在增强型模型下才生效
        let styleEnabled = model == .enhanced
        styleOptionButton.isEnabled = styleEnabled
        styleOptionButton.alpha = styleEnabled ? 1.0 : 0.4
    }

    private func updateAspectRatioState(_ ratio: AspectRatio) {
        // 纯图标按钮，无标题需更新
    }

    private func updateStyleState(_ style: ImageStyle) {
        // 纯图标按钮，无标题需更新
    }

    private func updateGeneratingState(_ isGenerating: Bool) {
        if isGenerating {
            loadingIndicator.startAnimating()
            directGenerateButton.setTitle("", for: .normal)
            generateButton.alpha = 0.5
        } else {
            loadingIndicator.stopAnimating()
            directGenerateButton.setTitle("生成图片", for: .normal)
            updateGenerateButtonState()
        }
    }

    private func updateErrorMessage(_ errorMessage: String?) {
        if let errorMessage = errorMessage, !errorMessage.isEmpty {
            errorLabel.text = errorMessage
            errorLabel.isHidden = false
        } else {
            errorLabel.isHidden = true
        }
    }

    private func updateGenerateButtonState() {
        let enabled = viewModel.canGenerate
        generateButton.alpha = enabled ? 1.0 : 0.5
        directGenerateButton.alpha = enabled ? 1.0 : 0.5
    }

    // MARK: - Button Actions

    @objc private func imageUploadTapped() {
        presentImagePicker()
    }

    @objc private func closeButtonTapped() {
        viewModel.clearImage()
    }

    @objc private func modelOptionTapped() {
        presentModelPicker()
    }

    @objc private func aspectRatioOptionTapped() {
        presentAspectRatioPicker()
    }

    @objc private func styleOptionTapped() {
        presentStylePicker()
    }

    private func presentModelPicker() {
        let alert = UIAlertController(title: "选择模型", message: nil, preferredStyle: .actionSheet)
        
        for model in ImageModel.allCases {
            let isSelected = viewModel.model == model
            let title = isSelected ? "\(model.displayName) ✓" : model.displayName
            alert.addAction(UIAlertAction(title: title, style: .default) { [weak self] _ in
                self?.viewModel.model = model
            })
        }
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        present(alert, animated: true)
    }

    private func presentAspectRatioPicker() {
        let alert = UIAlertController(title: "选择宽高比", message: nil, preferredStyle: .actionSheet)
        
        for ratio in AspectRatio.allCases {
            let isSelected = viewModel.aspectRatio == ratio
            let title = isSelected ? "\(ratio.displayName) (\(ratio.apiValue)) ✓" : "\(ratio.displayName) (\(ratio.apiValue))"
            alert.addAction(UIAlertAction(title: title, style: .default) { [weak self] _ in
                self?.viewModel.aspectRatio = ratio
            })
        }
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        present(alert, animated: true)
    }

    private func presentStylePicker() {
        let alert = UIAlertController(title: "选择风格（仅增强版模型生效）", message: nil, preferredStyle: .actionSheet)
        
        for style in ImageStyle.allCases {
            let isSelected = viewModel.style == style
            let title = isSelected ? "\(style.rawValue) ✓" : style.rawValue
            alert.addAction(UIAlertAction(title: title, style: .default) { [weak self] _ in
                self?.viewModel.style = style
            })
        }
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        present(alert, animated: true)
    }

    @objc private func directGenerateButtonTapped() {
        guard viewModel.canGenerate else {
            showCannotGenerateAlert()
            return
        }

        updateGeneratingState(true)
        resultLoadingIndicator.startAnimating()
        resultPlaceholderLabel.isHidden = true
        resultImageView.isHidden = true
        updateResultActionsVisibility()

        viewModel.generateImage { [weak self] _, result in
            guard let self = self else { return }
            self.updateGeneratingState(false)
            self.resultLoadingIndicator.stopAnimating()

            if let result = result, !result.imageUrl.isEmpty {
                self.downloadAndDisplayImage(from: result.imageUrl)
            } else if let errorMessage = self.viewModel.errorMessage, !errorMessage.isEmpty {
                self.showGenerationError(message: errorMessage)
            } else {
                self.showGenerationError(message: "生成图片失败，请重试")
            }
        }
    }

    @objc private func generateButtonTapped() {
        guard viewModel.canGenerate else {
            showCannotGenerateAlert()
            return
        }

        viewModel.generateImage { [weak self] request, result in
            guard let self = self else { return }
            if let request = request, result != nil {
                self.navigateToGenerateView(with: request)
            }
        }
    }

    private func showCannotGenerateAlert() {
        let message: String
        if viewModel.selectedImage == nil {
            message = "请先选择一张图片"
        } else if viewModel.prompt.trimmingCharacters(in: .whitespaces).isEmpty {
            message = "请输入描述文字（Prompt）"
        } else {
            message = "无法生成图片，请重试"
        }
        let alert = UIAlertController(title: "提示", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }

    private func showGenerationError(message: String) {
        let alert = UIAlertController(title: "生成失败", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }

    private func downloadAndDisplayImage(from urlString: String) {
        guard let url = URL(string: urlString) else { return }
        resultLoadingIndicator.startAnimating()

        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.resultLoadingIndicator.stopAnimating()

                if let data = data, let image = UIImage(data: data) {
                    self.resultImageView.image = image
                    self.resultImageView.isHidden = false
                    self.resultPlaceholderLabel.isHidden = true
                    self.updateResultActionsVisibility()
                } else {
                    self.resultPlaceholderLabel.text = "图片加载失败"
                    self.resultPlaceholderLabel.isHidden = false
                    self.resultImageView.isHidden = true
                    self.updateResultActionsVisibility()
                }
            }
        }.resume()
    }

    // MARK: - Image Actions

    private func updateResultActionsVisibility() {
        let shown = !resultImageView.isHidden && resultImageView.image != nil
        resultSaveButton.isHidden = !shown
        resultShareButton.isHidden = !shown
    }

    @objc private func resultSaveTapped() {
        guard let image = resultImageView.image else { return }
        saveImageToPhotos(image)
    }

    @objc private func resultShareTapped() {
        guard let image = resultImageView.image else { return }
        shareImage(image, sourceView: resultShareButton)
    }

    @objc private func resultImageLongPressed(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began, let image = resultImageView.image else { return }

        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        let saveAction = UIAlertAction(title: "保存到相册", style: .default) { [weak self] _ in
            self?.saveImageToPhotos(image)
        }
        let shareAction = UIAlertAction(title: "分享", style: .default) { [weak self] _ in
            self?.shareImage(image, sourceView: self?.resultImageView)
        }
        let cancelAction = UIAlertAction(title: "取消", style: .cancel)

        alert.addAction(saveAction)
        alert.addAction(shareAction)
        alert.addAction(cancelAction)

        alert.popoverPresentationController?.sourceView = resultImageView
        alert.popoverPresentationController?.sourceRect = resultImageView.bounds

        present(alert, animated: true)
    }

    // MARK: - Image Picker

    private func presentImagePicker() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        picker.modalPresentationStyle = .fullScreen
        present(picker, animated: true)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if let uiImage = info[.originalImage] as? UIImage {
            // 保留原图分辨率，预览由 UIImageView 自行缩放；上传前会限制最长边 1024px
            viewModel.selectedImage = uiImage
        }
        picker.dismiss(animated: true)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }

    // MARK: - Navigation

    private func navigateToGenerateView(with request: GenerationRequest) {
        let generateVC = GenerateViewController(request: request)
        generateVC.modalPresentationStyle = .fullScreen
        present(generateVC, animated: true)
    }

    // MARK: - UITextViewDelegate

    func textViewDidChange(_ textView: UITextView) {
        let text = textView.text ?? ""
        if text.count > 500 {
            textView.text = String(text.prefix(500))
        }
        viewModel.prompt = textView.text ?? ""
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

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        scrollView.addGestureRecognizer(tap)
    }

    private func handleKeyboardShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        let keyboardHeight = keyboardFrame.height
        scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardHeight, right: 0)
        scrollView.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardHeight, right: 0)
    }

    private func handleKeyboardHide(_ notification: Notification) {
        scrollView.contentInset = .zero
        scrollView.scrollIndicatorInsets = .zero
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
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

        if let generateGradient = generateButton.layer.sublayers?.first as? CAGradientLayer {
            generateGradient.frame = generateButton.bounds
        }

        if let directGenerateGradient = directGenerateButton.layer.sublayers?.first as? CAGradientLayer {
            directGenerateGradient.frame = directGenerateButton.bounds
        }
    }
}