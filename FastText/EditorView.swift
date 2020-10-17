import Cocoa
import os.log


enum DrawMode {
    case line
    case word
    case wordFixDuplicates
}

let layoutWidth: CGFloat = 2000

class EditorView: NSView {
    
    var mode: DrawMode = .line {
        didSet {
            layer?.setNeedsDisplay()
        }
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
        layer = CALayer()
        layer?.backgroundColor = NSColor.red.cgColor
        layerContentsRedrawPolicy = .never
        layer?.delegate = self
    }
    
    override func viewWillMove(toWindow newWindow: NSWindow?) {
        let scrollView = self.enclosingScrollView!
        let contentView = scrollView.contentView
        
        contentView.postsBoundsChangedNotifications = true
        NotificationCenter.default.addObserver(forName: NSView.boundsDidChangeNotification, object: contentView, queue: nil) { [weak self] _ in
            self?.layer?.setNeedsDisplay()
        }
    }
}

extension EditorView: CALayerDelegate {
    func display(_ layer: CALayer) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        let layer = self.layer!
        
        for each in layer.sublayers ?? [] {
            each.removeFromSuperlayer()
            each.position = .zero
        }
        
        var top: CGFloat = visibleRect.minY
        for each in generateBlockLayers() {
            each.position = CGPoint(x: 0, y: top)
            layer.addSublayer(each)
            top += each.frame.height
        }
        
        CATransaction.commit()
    }
    
    func generateBlockLayers() -> [CALayer] {
        switch mode {
        case .line:
            return buildLineLayers()
        case .word:
            return buildWordLayersUsingCache(fixDuplicates: false)
        case .wordFixDuplicates:
            return buildWordLayersUsingCache(fixDuplicates: true)
        }
    }
    
    override func layout() {
        layer?.setNeedsDisplay()
    }
}
