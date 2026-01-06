import AppKit

extension String {
    /// 将 emoji 字符串转换为 NSImage
    func toImage() -> NSImage? {
        let image = NSImage(size: NSSize(width: 32, height: 32))
        image.lockFocus()

        let attributedString = NSAttributedString(
            string: self,
            attributes: [
                .font: NSFont.systemFont(ofSize: 24)
            ]
        )

        let rect = NSRect(
            origin: .zero,
            size: attributedString.size()
        )
        attributedString.draw(in: rect)

        image.unlockFocus()
        return image
    }
}
