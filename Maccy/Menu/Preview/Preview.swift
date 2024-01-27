import Cocoa
import KeyboardShortcuts

class Preview: NSViewController {
    @IBOutlet var textView: NSTextField!
    @IBOutlet var imageView: NSImageView!
    @IBOutlet var applicationValueLabel: NSTextField!
    @IBOutlet var firstCopyTimeValueLabel: NSTextField!
    @IBOutlet var lastCopyTimeValueLabel: NSTextField!
    @IBOutlet var numberOfCopiesValueLabel: NSTextField!
    @IBOutlet var deleteLabel: NSTextField!
    @IBOutlet var pinLabel: NSTextField!
    @IBOutlet var latexLabel: NSTextField!

    private let maxTextSize = 1500

    private var item: HistoryItem?

    convenience init(item: HistoryItem?) {
        self.init()
        self.item = item
    }

    override func viewDidLoad() {
        guard let item, !item.isFault else { return }

        if let image = item.image {
            textView.removeFromSuperview()
            imageView.image = image
            // Preserver image aspect ratio
            let aspect = image.size.height / image.size.width
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: aspect).isActive = true
            imageView.wantsLayer = true
            imageView.layer?.borderWidth = 1.0
            imageView.layer?.borderColor = NSColor.separatorColor.cgColor
            imageView.layer?.cornerRadius = 7.0
            imageView.layer?.masksToBounds = true
        } else if let fileURL = item.fileURL,
                  let string = fileURL.absoluteString.removingPercentEncoding {
            imageView.removeFromSuperview()
            textView.stringValue = string
        } else if let string = item.rtf?.string {
            imageView.removeFromSuperview()
            textView.stringValue = string
        } else if let string = item.html?.string {
            imageView.removeFromSuperview()
            textView.stringValue = string
        } else if let string = item.text {
            imageView.removeFromSuperview()
            textView.stringValue = string
        } else {
            imageView.removeFromSuperview()
            textView.stringValue = item.title ?? ""
        }

        loadApplication(item)

        if textView.stringValue.count > maxTextSize {
            textView.stringValue = textView.stringValue.shortened(to: maxTextSize)
        }

        firstCopyTimeValueLabel.stringValue = formatDate(item.firstCopiedAt)
        lastCopyTimeValueLabel.stringValue = formatDate(item.lastCopiedAt)
        numberOfCopiesValueLabel.stringValue = String(item.numberOfCopies)

        if let deleteKey = KeyboardShortcuts.Shortcut(name: .delete) {
            deleteLabel.stringValue = deleteLabel.stringValue
                .replacingOccurrences(of: "{deleteKey}", with: deleteKey.description)
        } else {
            deleteLabel.removeFromSuperview()
        }

        if let pinKey = KeyboardShortcuts.Shortcut(name: .pin) {
            pinLabel.stringValue = pinLabel.stringValue
                .replacingOccurrences(of: "{pinKey}", with: pinKey.description)
        } else {
            pinLabel.removeFromSuperview()
        }

        if let latexKey = KeyboardShortcuts.Shortcut(name: .latex) {
            latexLabel.stringValue = latexLabel.stringValue
                .replacingOccurrences(of: "{latexKey}", with: latexKey.description)
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, H:mm:ss"
        formatter.timeZone = TimeZone.current
        return formatter.string(from: date)
    }

    private func loadApplication(_ item: HistoryItem) {
        if item.universalClipboard {
            applicationValueLabel.stringValue = "iCloud"
            return
        }

        guard let bundle = item.application,
              let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundle) else {
            applicationValueLabel.removeFromSuperview()
            return
        }

        applicationValueLabel.stringValue = url.deletingPathExtension().lastPathComponent
    }
}
