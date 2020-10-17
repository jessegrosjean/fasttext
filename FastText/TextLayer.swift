import Foundation
import CoreText
import Quartz

final class TextLayer: CALayer {
    let text: NSAttributedString
    let origin: CGPoint
    let layout: CTLine
    
    public init(text: NSAttributedString, origin: CGPoint, layout: CTLine) {
        self.text = text
        self.origin = origin
        self.layout = layout
        super.init()
        commonInit()
    }
    
    override init(layer: Any) {
        let textLayer = layer as! TextLayer
        text = textLayer.text
        origin = textLayer.origin
        layout = textLayer.layout
        super.init()
        contents = textLayer.contents
        commonInit()
    }
    
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func commonInit() {
        isOpaque = true
        masksToBounds = false
        anchorPoint = CGPoint(x: 0, y: 0)
        contentsGravity = CALayerContentsGravity.topLeft
        backgroundColor = .white
        contentsScale = 2
        let b = layout.typographicBounds
        bounds = CGRect(origin: .zero, size: CGSize(width: b.width.rounded(.awayFromZero), height: b.height.rounded(.awayFromZero)))
    }
    
    override func draw(in ctx: CGContext) {
        let flipped = ctx.ctm.d < 0
        
        if flipped {
            ctx.saveGState()
            ctx.translateBy(x: 0, y: bounds.height)
            ctx.scaleBy(x: 1, y: -1)
        }
        
        if let backgroundColor = self.backgroundColor {
            ctx.setShouldSmoothFonts(true)
            ctx.setFillColor(backgroundColor)
            ctx.fill(bounds)
        } else {
            ctx.setShouldSmoothFonts(false)
        }
                
        ctx.textMatrix = .identity
        ctx.textPosition = CGPoint(x: origin.x, y: origin.y)        
        CTLineDraw(layout, ctx)

        if flipped {
            ctx.restoreGState()
        }
    }

    override func action(forKey _: String) -> CAAction? {
        return nil
    }
}
