import UIKit
import Combine
import QuartzCore

class GalleryViewController: UIViewController {

    // MARK: - Properties

    private let viewModel = GalleryViewModel()
    private var cancellables = Set<AnyCancellable>()
    private var gradientLayer: CAGradientLayer!

    var showFavoritesOnNextAppear = false

    private var filteredArtworks: [Artwork] = [] {
        didSet {
            applyContentState()
        }
    }

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
        sv.showsVerticalScrollIndicator = false
        return sv
    }()

    private let contentStackView: UIStackView = {
        let sv = UIStackView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.axis = .vertical
        sv.spacing = Spacing.lg
        sv.alignment = .fill
        sv.layoutMargins = UIEdgeInsets(
            top: Spacing.lg,
            left: Spacing.lg,
            bottom: Spacing.lg,
            right: Spacing.lg
        )
        sv.isLayoutMarginsRelativeArrangement = true
        return sv
    }()

    // MARK: Header Section

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "作品库"
        label.font = .heading
        label.textColor = .textPrimary
        return label
    }()

    private lazy var favoritesCloseButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("全部作品", for: .normal)
        button.titleLabel?.font = .body
        button.setTitleColor(.primary, for: .normal)
        button.addTarget(self, action: #selector(favoritesCloseTapped), for: .touchUpInside)
        button.isHidden = true
        return button
    }()

    private lazy var headerStack: UIStackView = {
        let sv = UIStackView(arrangedSubviews: [titleLabel, favoritesCloseButton])
        sv.axis = .horizontal
        sv.alignment = .center
        sv.distribution = .equalSpacing
        return sv
    }()

    private let searchTextField: UITextField = {
        let tf = UITextField()
        tf.font = .body
        tf.textColor = .textPrimary
        tf.backgroundColor = .inputBackground
        tf.layer.cornerRadius = CornerRadius.md
        tf.layer.borderWidth = 1
        tf.layer.borderColor = UIColor.borderColor.cgColor
        tf.leftViewMode = .always
        tf.attributedPlaceholder = NSAttributedString(
            string: "搜索作品...",
            attributes: [.foregroundColor: UIColor.textSecondary]
        )
        tf.returnKeyType = .search
        return tf
    }()

    // MARK: Filter Chips Section

    private let chipsScrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsHorizontalScrollIndicator = false
        sv.alwaysBounceHorizontal = true
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let chipsStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.spacing = Spacing.sm
        sv.alignment = .center
        sv.layoutMargins = UIEdgeInsets(top: 0, left: Spacing.lg, bottom: 0, right: Spacing.lg)
        sv.isLayoutMarginsRelativeArrangement = true
        return sv
    }()

    private var chipButtons: [UIButton] = []

    // MARK: Collection View

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = Spacing.sm
        layout.minimumInteritemSpacing = Spacing.sm
        layout.sectionInset = .zero

        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.backgroundColor = .clear
        cv.dataSource = self
        cv.delegate = self
        cv.isScrollEnabled = false
        cv.register(ArtworkCell.self, forCellWithReuseIdentifier: ArtworkCell.reuseIdentifier)
        return cv
    }()

    private var collectionViewHeightConstraint: NSLayoutConstraint!

    // MARK: Loading State

    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .textPrimary
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()

    // MARK: Empty State

    private let emptyStateContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()

    private let emptyIconLabel: UIImageView = {
        let config = UIImage.SymbolConfiguration(pointSize: 56, weight: .regular)
        let imageView = UIImageView(image: UIImage(systemName: "image", withConfiguration: config))
        imageView.tintColor = .textSecondary
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let emptyTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "暂无作品"
        label.font = .subheading
        label.textColor = .textPrimary
        label.textAlignment = .center
        return label
    }()

    private let emptySubtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "快去生成你的第一张图片吧"
        label.font = .caption
        label.textColor = .textSecondary
        label.textAlignment = .center
        return label
    }()

    // MARK: - Initialization

    init() {
        super.init(nibName: nil, bundle: nil)
        self.collectionViewHeightConstraint = collectionView.heightAnchor.constraint(equalToConstant: 0)
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
        setupFilterChips()
        applyContentState()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleShowFavorites),
            name: .showFavoritesOnly,
            object: nil
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        if showFavoritesOnNextAppear {
            viewModel.showFavoritesOnly = true
            showFavoritesOnNextAppear = false
        }
        viewModel.reloadArtworks()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setupOrUpdateGradient()
        updateCollectionViewHeight()
    }

    // MARK: - Setup UI

    private func setupUI() {
        view.backgroundColor = .appBackground

        view.addSubview(backgroundView)
        view.addSubview(scrollView)
        scrollView.addSubview(contentStackView)

        // Left view for search text field (padding)
        let leftPaddingView = UIView(frame: CGRect(x: 0, y: 0, width: Spacing.md, height: 20))
        searchTextField.leftView = leftPaddingView

        // Header
        contentStackView.addArrangedSubview(headerStack)
        contentStackView.addArrangedSubview(searchTextField)
        searchTextField.heightAnchor.constraint(equalToConstant: 44).isActive = true

        // Filter chips
        contentStackView.addArrangedSubview(chipsScrollView)
        chipsScrollView.heightAnchor.constraint(equalToConstant: 40).isActive = true
        chipsScrollView.addSubview(chipsStackView)

        // Collection view (will be handled by state)
        contentStackView.addArrangedSubview(collectionView)

        // Loading indicator
        view.addSubview(loadingIndicator)

        // Empty state
        emptyStateContainer.addSubview(emptyIconLabel)
        emptyStateContainer.addSubview(emptyTitleLabel)
        emptyStateContainer.addSubview(emptySubtitleLabel)
        contentStackView.addArrangedSubview(emptyStateContainer)
    }

    // MARK: - Setup Constraints

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            contentStackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentStackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentStackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentStackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            chipsStackView.topAnchor.constraint(equalTo: chipsScrollView.topAnchor),
            chipsStackView.leadingAnchor.constraint(equalTo: chipsScrollView.leadingAnchor),
            chipsStackView.trailingAnchor.constraint(equalTo: chipsScrollView.trailingAnchor),
            chipsStackView.bottomAnchor.constraint(equalTo: chipsScrollView.bottomAnchor),
            chipsStackView.heightAnchor.constraint(equalTo: chipsScrollView.heightAnchor),

            collectionViewHeightConstraint,

            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            emptyStateContainer.heightAnchor.constraint(equalToConstant: 220),

            emptyIconLabel.topAnchor.constraint(equalTo: emptyStateContainer.topAnchor),
            emptyIconLabel.centerXAnchor.constraint(equalTo: emptyStateContainer.centerXAnchor),
            emptyIconLabel.heightAnchor.constraint(equalToConstant: 64),
            emptyIconLabel.widthAnchor.constraint(equalToConstant: 64),

            emptyTitleLabel.topAnchor.constraint(equalTo: emptyIconLabel.bottomAnchor, constant: Spacing.md),
            emptyTitleLabel.leadingAnchor.constraint(equalTo: emptyStateContainer.leadingAnchor),
            emptyTitleLabel.trailingAnchor.constraint(equalTo: emptyStateContainer.trailingAnchor),

            emptySubtitleLabel.topAnchor.constraint(equalTo: emptyTitleLabel.bottomAnchor, constant: Spacing.sm),
            emptySubtitleLabel.leadingAnchor.constraint(equalTo: emptyStateContainer.leadingAnchor),
            emptySubtitleLabel.trailingAnchor.constraint(equalTo: emptyStateContainer.trailingAnchor),
        ])
    }

    // MARK: - Setup Filter Chips

    private func setupFilterChips() {
        // "全部" chip
        let allChip = makeChip(title: "全部", icon: nil, isSelected: true)
        allChip.tag = -1
        allChip.addTarget(self, action: #selector(chipTapped(_:)), for: .touchUpInside)
        chipsStackView.addArrangedSubview(allChip)
        chipButtons.append(allChip)

        for (index, style) in ArtStyle.allCases.enumerated() {
            let chip = makeChip(title: style.rawValue, icon: style.icon, isSelected: false)
            chip.tag = index
            chip.addTarget(self, action: #selector(chipTapped(_:)), for: .touchUpInside)
            chipsStackView.addArrangedSubview(chip)
            chipButtons.append(chip)
        }
    }

    private func makeChip(title: String, icon: String?, isSelected: Bool) -> UIButton {
        var config = UIButton.Configuration.plain()
        config.title = icon.map { "\($0) \(title)" } ?? title
        config.contentInsets = NSDirectionalEdgeInsets(top: Spacing.sm, leading: Spacing.md, bottom: Spacing.sm, trailing: Spacing.md)
        config.background.cornerRadius = CornerRadius.md
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .caption
            return outgoing
        }

        let button = UIButton(configuration: config)
        button.layer.cornerRadius = CornerRadius.md
        button.layer.borderWidth = 1
        button.clipsToBounds = true

        applyChipStyle(button, isSelected: isSelected)
        return button
    }

    private func applyChipStyle(_ button: UIButton, isSelected: Bool) {
        if isSelected {
            button.configuration?.background.backgroundColor = .primary
            button.configuration?.baseForegroundColor = .textPrimary
            button.layer.borderColor = UIColor.primary.cgColor
        } else {
            button.configuration?.background.backgroundColor = .cardBackground
            button.configuration?.baseForegroundColor = .textSecondary
            button.layer.borderColor = UIColor.borderColor.cgColor
        }
    }

    private func updateChipSelection(selectedStyle: ArtStyle?) {
        for button in chipButtons {
            let isSelected: Bool
            if button.tag == -1 {
                isSelected = selectedStyle == nil
            } else {
                let style = ArtStyle.allCases[button.tag]
                isSelected = selectedStyle == style
            }
            applyChipStyle(button, isSelected: isSelected)
        }
    }

    // MARK: - Setup Actions

    private func setupActions() {
        searchTextField.addTarget(self, action: #selector(searchTextChanged(_:)), for: .editingChanged)
        searchTextField.delegate = self
    }

    // MARK: - Combine Bindings

    private func setupBindings() {
        viewModel.$artworks
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.reloadFilteredArtworks()
            }
            .store(in: &cancellables)

        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                self?.handleLoading(isLoading)
            }
            .store(in: &cancellables)

        viewModel.$selectedStyle
            .receive(on: DispatchQueue.main)
            .sink { [weak self] style in
                self?.updateChipSelection(selectedStyle: style)
                self?.reloadFilteredArtworks()
            }
            .store(in: &cancellables)

        viewModel.$searchText
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.reloadFilteredArtworks()
            }
            .store(in: &cancellables)

        viewModel.$showFavoritesOnly
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isFavorites in
                self?.updateFavoritesUI(isFavorites)
                self?.reloadFilteredArtworks()
            }
            .store(in: &cancellables)
    }

    // MARK: - Content State

    private func applyContentState() {
        let isLoading = viewModel.isLoading
        let isEmpty = filteredArtworks.isEmpty

        if isLoading {
            loadingIndicator.startAnimating()
            collectionView.isHidden = true
            emptyStateContainer.isHidden = true
        } else if isEmpty {
            loadingIndicator.stopAnimating()
            collectionView.isHidden = true
            emptyStateContainer.isHidden = false
        } else {
            loadingIndicator.stopAnimating()
            emptyStateContainer.isHidden = true
            collectionView.isHidden = false
            collectionView.reloadData()
            updateCollectionViewHeight()
        }
    }

    private func handleLoading(_ isLoading: Bool) {
        applyContentState()
    }

    private func reloadFilteredArtworks() {
        filteredArtworks = viewModel.filteredArtworks
    }

    // MARK: - Favorites Mode

    @objc private func handleShowFavorites() {
        viewModel.showFavoritesOnly = true
    }

    @objc private func favoritesCloseTapped() {
        viewModel.showFavoritesOnly = false
    }

    private func updateFavoritesUI(_ isFavorites: Bool) {
        titleLabel.text = isFavorites ? "收藏作品" : "作品库"
        favoritesCloseButton.isHidden = !isFavorites
        emptyTitleLabel.text = isFavorites ? "暂无收藏作品" : "暂无作品"
        emptySubtitleLabel.text = isFavorites ? "去作品库收藏喜欢的作品吧" : "快去生成你的第一张图片吧"
    }

    private func updateCollectionViewHeight() {
        guard !collectionView.isHidden else { return }
        let width = collectionView.bounds.width > 0
            ? collectionView.bounds.width
            : view.bounds.width - Spacing.lg * 2

        let horizontalInsets: CGFloat = 0
        let spacing: CGFloat = Spacing.sm
        let cellWidth = (width - horizontalInsets - spacing * 2) / 3

        // Cells are square-ish with image + 2-line prompt + spacing
        let cellHeight = cellWidth * 1.35
        let count = filteredArtworks.count
        let rows = (count + 2) / 3
        let totalHeight = CGFloat(rows) * cellHeight + CGFloat(max(0, rows - 1)) * spacing

        collectionViewHeightConstraint.constant = max(totalHeight, 0)
        collectionView.collectionViewLayout.invalidateLayout()
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

    // MARK: - Actions

    @objc private func searchTextChanged(_ sender: UITextField) {
        viewModel.searchText = sender.text ?? ""
    }

    @objc private func chipTapped(_ sender: UIButton) {
        if sender.tag == -1 {
            viewModel.selectedStyle = nil
        } else {
            let style = ArtStyle.allCases[sender.tag]
            viewModel.selectedStyle = viewModel.selectedStyle == style ? nil : style
        }
    }

    // MARK: - Context Menu

    private func makeContextMenu(for artwork: Artwork) -> UIContextMenuConfiguration {
        UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
            guard let self = self else { return nil }

            let favoriteAction = UIAction(
                title: artwork.isFavorite ? "取消收藏" : "收藏",
                image: UIImage(systemName: artwork.isFavorite ? "heart.slash" : "heart")
            ) { _ in
                self.viewModel.toggleFavorite(id: artwork.id)
            }

            let saveAction = UIAction(
                title: "保存相册",
                image: UIImage(systemName: "square.and.arrow.down")
            ) { _ in
                self.saveArtworkToPhotos(artwork)
            }

            let shareAction = UIAction(
                title: "分享",
                image: UIImage(systemName: "square.and.arrow.up")
            ) { _ in
                self.shareArtwork(artwork)
            }

            let deleteAction = UIAction(
                title: "删除",
                image: UIImage(systemName: "trash"),
                attributes: .destructive
            ) { _ in
                self.confirmDelete(artwork: artwork)
            }

            return UIMenu(title: "", children: [favoriteAction, saveAction, shareAction, deleteAction])
        }
    }

    // MARK: - Image Helpers

    private func resolveImage(from artwork: Artwork, completion: @escaping (UIImage?) -> Void) {
        // 优先本地文件
        if let imagePath = artwork.imagePath, FileManager.default.fileExists(atPath: imagePath),
           let image = UIImage(contentsOfFile: imagePath) {
            completion(image)
            return
        }
        // 再尝试远程 URL
        let urlString = artwork.imageUrl
        if !urlString.isEmpty, let url = URL(string: urlString) {
            URLSession.shared.dataTask(with: url) { data, _, _ in
                completion(data.flatMap { UIImage(data: $0) })
            }.resume()
            return
        }
        completion(nil)
    }

    private func saveArtworkToPhotos(_ artwork: Artwork) {
        resolveImage(from: artwork) { [weak self] image in
            DispatchQueue.main.async {
                guard let self = self else { return }
                guard let image = image else {
                    self.showToast("图片加载失败")
                    return
                }
                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                self.showToast("已保存到相册")
            }
        }
    }

    private func shareArtwork(_ artwork: Artwork) {
        resolveImage(from: artwork) { [weak self] image in
            DispatchQueue.main.async {
                guard let self = self, let image = image else { return }
                let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)
                activityVC.popoverPresentationController?.sourceView = self.view
                self.present(activityVC, animated: true)
            }
        }
    }

    private func showToast(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        present(alert, animated: true) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
                self?.dismiss(animated: true)
            }
        }
    }

    private func confirmDelete(artwork: Artwork) {
        let alert = UIAlertController(
            title: "删除作品",
            message: "确定要删除这个作品吗？此操作无法撤销。",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "删除", style: .destructive) { [weak self] _ in
            self?.viewModel.deleteArtwork(id: artwork.id)
        })
        present(alert, animated: true)
    }

    // MARK: - Favorite Toggle (from cell)

    private func toggleFavoriteForCell(at indexPath: IndexPath) {
        guard indexPath.item < filteredArtworks.count else { return }
        let artwork = filteredArtworks[indexPath.item]
        viewModel.toggleFavorite(id: artwork.id)
    }
}

// MARK: - UICollectionViewDataSource

extension GalleryViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filteredArtworks.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: ArtworkCell.reuseIdentifier,
            for: indexPath
        ) as? ArtworkCell else {
            return UICollectionViewCell()
        }

        let artwork = filteredArtworks[indexPath.item]
        cell.configure(with: artwork)
        cell.onFavorite = { [weak self] in
            self?.toggleFavoriteForCell(at: indexPath)
        }

        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension GalleryViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let width = collectionView.bounds.width > 0
            ? collectionView.bounds.width
            : view.bounds.width - Spacing.lg * 2

        let spacing: CGFloat = Spacing.sm
        let cellWidth = (width - spacing * 2) / 3
        let cellHeight = cellWidth * 1.35
        return CGSize(width: cellWidth, height: cellHeight)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        let artwork = filteredArtworks[indexPath.item]
        let detail = ArtworkDetailViewController(artwork: artwork)
        detail.modalPresentationStyle = .fullScreen
        present(detail, animated: true)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        contextMenuConfigurationForItemsAt indexPaths: [IndexPath],
        point: CGPoint
    ) -> UIContextMenuConfiguration? {
        guard let indexPath = indexPaths.first else { return nil }
        let artwork = filteredArtworks[indexPath.item]
        return makeContextMenu(for: artwork)
    }
}

// MARK: - ArtworkDetailViewController

/// 作品详情：全屏预览，支持缩放 / 双击隐藏顶部工具栏 / 保存 / 分享。
final class ArtworkDetailViewController: UIViewController {

    private let artwork: Artwork

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.minimumZoomScale = 1.0
        sv.maximumZoomScale = 4.0
        sv.alwaysBounceVertical = false
        sv.alwaysBounceHorizontal = false
        return sv
    }()

    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .white
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()

    private let topBar: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.black.withAlphaComponent(0.45)
        return view
    }()

    private lazy var closeButton: UIButton = makeTopBarButton(icon: "xmark", action: #selector(closeTapped))
    private lazy var saveButton: UIButton = makeTopBarButton(icon: "square.and.arrow.down", action: #selector(saveTapped))
    private lazy var shareButton: UIButton = makeTopBarButton(icon: "square.and.arrow.up", action: #selector(shareTapped))

    private func makeTopBarButton(icon: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        button.setImage(UIImage(systemName: icon, withConfiguration: config), for: .normal)
        button.tintColor = .white
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    init(artwork: Artwork) {
        self.artwork = artwork
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        scrollView.delegate = self
        scrollView.addSubview(imageView)
        view.addSubview(scrollView)
        view.addSubview(loadingIndicator)
        view.addSubview(topBar)
        topBar.addSubview(closeButton)
        topBar.addSubview(saveButton)
        topBar.addSubview(shareButton)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            imageView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            imageView.centerXAnchor.constraint(equalTo: scrollView.frameLayoutGuide.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: scrollView.frameLayoutGuide.centerYAnchor),

            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            topBar.topAnchor.constraint(equalTo: view.topAnchor),
            topBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topBar.heightAnchor.constraint(equalToConstant: 90),

            closeButton.leadingAnchor.constraint(equalTo: topBar.leadingAnchor, constant: 16),
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            closeButton.widthAnchor.constraint(equalToConstant: 36),
            closeButton.heightAnchor.constraint(equalToConstant: 36),

            shareButton.trailingAnchor.constraint(equalTo: topBar.trailingAnchor, constant: -16),
            shareButton.centerYAnchor.constraint(equalTo: closeButton.centerYAnchor),
            shareButton.widthAnchor.constraint(equalToConstant: 36),
            shareButton.heightAnchor.constraint(equalToConstant: 36),

            saveButton.trailingAnchor.constraint(equalTo: shareButton.leadingAnchor, constant: -8),
            saveButton.centerYAnchor.constraint(equalTo: closeButton.centerYAnchor),
            saveButton.widthAnchor.constraint(equalToConstant: 36),
            saveButton.heightAnchor.constraint(equalToConstant: 36),
        ])

        loadImage()

        let tap = UITapGestureRecognizer(target: self, action: #selector(toggleTopBar))
        tap.numberOfTapsRequired = 1
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    private func loadImage() {
        loadingIndicator.startAnimating()

        if let imagePath = artwork.imagePath, FileManager.default.fileExists(atPath: imagePath),
           let image = UIImage(contentsOfFile: imagePath) {
            apply(image)
            return
        }
        let urlString = artwork.imageUrl
        if !urlString.isEmpty, let url = URL(string: urlString) {
            URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
                let image = data.flatMap { UIImage(data: $0) }
                DispatchQueue.main.async { self?.apply(image) }
            }.resume()
            return
        }
        loadingIndicator.stopAnimating()
    }

    private func apply(_ image: UIImage?) {
        loadingIndicator.stopAnimating()
        guard let image = image else { return }
        imageView.image = image
        // 给 imageView 真实尺寸，scrollView 才能正确缩放
        imageView.removeConstraint(imageView.widthAnchor.constraint(equalToConstant: image.size.width))
        imageView.removeConstraint(imageView.heightAnchor.constraint(equalToConstant: image.size.height))
        let w = imageView.widthAnchor.constraint(equalToConstant: image.size.width)
        let h = imageView.heightAnchor.constraint(equalToConstant: image.size.height)
        w.isActive = true
        h.isActive = true
    }

    @objc private func closeTapped() { dismiss(animated: true) }

    @objc private func toggleTopBar() {
        UIView.animate(withDuration: 0.2) {
            self.topBar.alpha = self.topBar.alpha < 0.5 ? 1.0 : 0.0
        }
    }

    @objc private func saveTapped() {
        guard let image = imageView.image else { return }
        saveImageToPhotos(image)
    }

    @objc private func shareTapped() {
        guard let image = imageView.image else { return }
        shareImage(image, sourceView: shareButton)
    }
}

// MARK: - ArtworkDetailViewController + UIScrollViewDelegate

extension ArtworkDetailViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? { imageView }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        guard let image = imageView.image else { return }
        let horizontal = max(0, (scrollView.bounds.width - imageView.frame.width) / 2)
        let vertical = max(0, (scrollView.bounds.height - imageView.frame.height) / 2)
        scrollView.contentInset = UIEdgeInsets(top: vertical, left: horizontal, bottom: vertical, right: horizontal)
        _ = image
    }
}

// MARK: - UITextFieldDelegate

extension GalleryViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

// MARK: - Artwork Cell

final class ArtworkCell: UICollectionViewCell {

    static let reuseIdentifier = "ArtworkCell"

    var onFavorite: (() -> Void)?

    private let artworkImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = .cardBackground
        iv.layer.cornerRadius = CornerRadius.sm
        iv.layer.masksToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let favoriteButton: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = .white
        button.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        button.layer.cornerRadius = CornerRadius.sm
        button.clipsToBounds = true
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let promptLabel: UILabel = {
        let label = UILabel()
        label.font = .small
        label.textColor = .textSecondary
        label.numberOfLines = 2
        label.lineBreakMode = .byTruncatingTail
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.color = .textSecondary
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()

    private var currentImageUrl: String?
    private var imageLoadTask: URLSessionDataTask?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCell()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageLoadTask?.cancel()
        artworkImageView.image = nil
        promptLabel.text = nil
        currentImageUrl = nil
        onFavorite = nil
        loadingIndicator.stopAnimating()
    }

    private func setupCell() {
        contentView.addSubview(artworkImageView)
        contentView.addSubview(favoriteButton)
        contentView.addSubview(promptLabel)
        artworkImageView.addSubview(loadingIndicator)

        favoriteButton.addTarget(self, action: #selector(favoriteTapped), for: .touchUpInside)

        NSLayoutConstraint.activate([
            artworkImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            artworkImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            artworkImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            artworkImageView.heightAnchor.constraint(equalTo: artworkImageView.widthAnchor),

            favoriteButton.topAnchor.constraint(equalTo: artworkImageView.topAnchor, constant: Spacing.xs),
            favoriteButton.trailingAnchor.constraint(equalTo: artworkImageView.trailingAnchor, constant: -Spacing.xs),
            favoriteButton.widthAnchor.constraint(equalToConstant: 24),
            favoriteButton.heightAnchor.constraint(equalToConstant: 24),

            loadingIndicator.centerXAnchor.constraint(equalTo: artworkImageView.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: artworkImageView.centerYAnchor),

            promptLabel.topAnchor.constraint(equalTo: artworkImageView.bottomAnchor, constant: Spacing.xs),
            promptLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            promptLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            promptLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor),
        ])
    }

    func configure(with artwork: Artwork) {
        promptLabel.text = artwork.prompt

        let heartImage = artwork.isFavorite
            ? UIImage(systemName: "heart.fill")
            : UIImage(systemName: "heart")
        favoriteButton.setImage(heartImage, for: .normal)
        favoriteButton.tintColor = artwork.isFavorite ? .accent : .white

        if let imagePath = artwork.imagePath, FileManager.default.fileExists(atPath: imagePath) {
            loadLocalImage(from: imagePath)
        } else {
            loadImage(from: artwork.imageUrl)
        }
    }

    private func loadLocalImage(from path: String) {
        artworkImageView.image = nil
        loadingIndicator.startAnimating()

        if let image = UIImage(contentsOfFile: path) {
            artworkImageView.image = image
            loadingIndicator.stopAnimating()
        } else {
            loadingIndicator.stopAnimating()
        }
    }

    private func loadImage(from urlString: String) {
        guard urlString != currentImageUrl else { return }
        currentImageUrl = urlString
        imageLoadTask?.cancel()

        artworkImageView.image = nil
        loadingIndicator.startAnimating()

        guard let url = URL(string: urlString) else {
            loadingIndicator.stopAnimating()
            return
        }

        imageLoadTask = URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let self = self else { return }

            if error == nil, let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    guard self.currentImageUrl == urlString else { return }
                    self.artworkImageView.image = image
                    self.loadingIndicator.stopAnimating()
                }
            } else {
                DispatchQueue.main.async {
                    guard self.currentImageUrl == urlString else { return }
                    self.loadingIndicator.stopAnimating()
                    let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .regular)
                    self.artworkImageView.image = UIImage(systemName: "photo", withConfiguration: config)
                    self.artworkImageView.tintColor = .textSecondary
                    self.artworkImageView.contentMode = .center
                }
            }
        }
        imageLoadTask?.resume()
    }

    @objc private func favoriteTapped() {
        onFavorite?()
    }
}