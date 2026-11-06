import UIKit

extension UITextView {
    @IBInspectable var placeholder: String {
        get {
            return (self.viewWithTag(100) as? UILabel)?.text ?? ""
        }
        set {
            if let placeholderLabel = self.viewWithTag(100) as? UILabel {
                placeholderLabel.text = newValue
                return
            }

            let placeholderLabel = UILabel()
            placeholderLabel.text = newValue
            placeholderLabel.textColor = UIColor(white: 0.5, alpha: 1.0)
            placeholderLabel.tag = 100
            placeholderLabel.font = font
            placeholderLabel.translatesAutoresizingMaskIntoConstraints = false

            addSubview(placeholderLabel)
            NSLayoutConstraint.activate([
                placeholderLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
                placeholderLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
                placeholderLabel.topAnchor.constraint(equalTo: topAnchor, constant: 8),
                placeholderLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
            ])

            NotificationCenter.default.addObserver(forName: UITextView.textDidChangeNotification, object: self, queue: nil) { [weak self] _ in
                guard let self = self else { return }
                placeholderLabel.isHidden = !self.text.isEmpty
            }
        }
    }
}
