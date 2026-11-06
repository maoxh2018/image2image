import UIKit

// MARK: - MainTabBarController

class MainTabBarController: UITabBarController {

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabBar()
        setupViewControllers()
    }

    // MARK: - Setup Tab Bar

    private func setupTabBar() {
        // 浅色主题：柔和浅灰底 + 中灰未选中 + 紫色选中
        let tabBarBackground = UIColor.fromHex("#f5f5f7")
        let unselectedColor = UIColor.fromHex("#9ca3af")

        tabBar.tintColor = .primary
        tabBar.unselectedItemTintColor = unselectedColor
        tabBar.barTintColor = tabBarBackground
        tabBar.backgroundColor = tabBarBackground
        tabBar.isTranslucent = false

        // 顶部细分隔线，与深色页面背景做衔接
        tabBar.layer.borderWidth = 1
        tabBar.layer.borderColor = UIColor.fromHex("#e5e7eb").cgColor
        // 只显示顶部 1px 线
        tabBar.layer.borderWidth = 0
        let separator = UIView()
        separator.backgroundColor = UIColor.fromHex("#e5e7eb")
        separator.translatesAutoresizingMaskIntoConstraints = false
        tabBar.addSubview(separator)
        NSLayoutConstraint.activate([
            separator.topAnchor.constraint(equalTo: tabBar.topAnchor),
            separator.leadingAnchor.constraint(equalTo: tabBar.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: tabBar.trailingAnchor),
            separator.heightAnchor.constraint(equalToConstant: 1.0 / view.traitCollection.displayScale)
        ])

        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = tabBarBackground
        appearance.stackedLayoutAppearance.normal.iconColor = unselectedColor
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: unselectedColor
        ]
        appearance.stackedLayoutAppearance.selected.iconColor = .primary
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor.primary
        ]
        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
    }

    // MARK: - Setup View Controllers

    private func setupViewControllers() {
        let homeNav = UINavigationController(rootViewController: HomeViewController())
        homeNav.tabBarItem = UITabBarItem(
            title: "首页",
            image: UIImage(systemName: "house"),
            selectedImage: UIImage(systemName: "house.fill")
        )

        let galleryNav = UINavigationController(rootViewController: GalleryViewController())
        galleryNav.tabBarItem = UITabBarItem(
            title: "作品库",
            image: UIImage(systemName: "photo"),
            selectedImage: UIImage(systemName: "photo.fill")
        )

        let profileNav = UINavigationController(rootViewController: ProfileViewController())
        profileNav.tabBarItem = UITabBarItem(
            title: "个人中心",
            image: UIImage(systemName: "person"),
            selectedImage: UIImage(systemName: "person.fill")
        )

        viewControllers = [homeNav, galleryNav, profileNav]
    }
}
