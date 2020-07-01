import Cocoa
import PlaygroundSupport

let subviewFrame = CGRect(origin: .zero,
                          size: CGSize(width: 320, height: 640 * 4))
let gradient = CAGradientLayer()
gradient.colors = [
  NSColor.blue.withAlphaComponent(0.2).cgColor,
  NSColor.blue.withAlphaComponent(0.4).cgColor
]
gradient.frame = subviewFrame

let documentView = NSView(frame: subviewFrame)
documentView.wantsLayer = true
documentView.layer?.addSublayer(gradient)

let scrollViewFrame = CGRect(origin: .zero,
                   size: CGSize(width: 320, height: 640))
let scrollView = NSScrollView(frame: scrollViewFrame)
scrollView.backgroundColor = NSColor.green.withAlphaComponent(0.2)
scrollView.documentView = documentView
scrollView.contentView.scroll(to: CGPoint(x: 0, y: subviewFrame.size.height))

PlaygroundPage.current.liveView = scrollView
