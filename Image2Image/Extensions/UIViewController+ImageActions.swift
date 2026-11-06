import UIKit

// MARK: - ImageSaveHelper

/// 持有 `UIImageWriteToSavedPhotosAlbum` 的回调 target。
/// 该 API 要求 target 是 NSObject 且在回调完成前存活。
final class ImageSaveHelper: NSObject {
    static let shared = ImageSaveHelper()

    private var completion: ((Error?) -> Void)?

    func save(_ image: UIImage, completion: @escaping (Error?) -> Void) {
        self.completion = completion
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(saveCompleted(_:didFinishSavingWithError:contextInfo:)), nil)
    }

    @objc private func saveCompleted(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        completion?(error)
        completion = nil
    }
}

// MARK: - UIViewController + ImageActions

extension UIViewController {

    /// 唤起系统分享面板。
    /// - Parameters:
    ///   - image: 要分享的图片。
    ///   - sourceView: iPad 弹窗锚点；传 nil 时锚点到 self.view 中心。
    func shareImage(_ image: UIImage, sourceView: UIView? = nil) {
        let activityViewController = UIActivityViewController(activityItems: [image], applicationActivities: nil)

        if let popover = activityViewController.popoverPresentationController {
            if let sourceView {
                popover.sourceView = sourceView
                popover.sourceRect = sourceView.bounds
            } else {
                popover.sourceView = view
                popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
        }

        present(activityViewController, animated: true)
    }

    /// 保存图片到相册，并展示结果提示。
    func saveImageToPhotos(_ image: UIImage) {
        ImageSaveHelper.shared.save(image) { [weak self] error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if let error = error {
                    let message = error.localizedDescription.isEmpty
                        ? "请在系统设置中开启相册权限后重试"
                        : "\(error.localizedDescription)\n请在系统设置中开启相册权限后重试"
                    self.presentImageActionAlert(title: "保存失败", message: message)
                } else {
                    self.presentImageActionAlert(title: "保存成功", message: "图片已保存到相册")
                }
            }
        }
    }

    private func presentImageActionAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
}
