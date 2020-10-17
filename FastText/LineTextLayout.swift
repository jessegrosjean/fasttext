import Cocoa
import CoreText

func buildLineLayers() -> [TextLayer] {
    let lineLayers = buildLineLayouts().flatMap { (paragraphText, lines) in
        return lines.map { line in
            return TextLayer(text: paragraphText, origin: .zero, layout: line)
        }
    }

    for each in lineLayers {
        each.setNeedsDisplay()
    }
    //DispatchQueue.concurrentPerform(iterations: lineLayers.count) { index in
    //    lineLayers[index].display()
    //}
    
    return lineLayers
}

func buildLineLayouts() -> [(NSAttributedString, [CTLine])] {
    var paragraphs: [(NSAttributedString, [CTLine])] = []
    
    let attributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.userFont(ofSize: 16)!,
        .backgroundColor: NSColor.white,
        .foregroundColor: NSColor.black,
    ]
    
    text.enumerateLines { paragraph, _ in
        let paragraphText = NSMutableAttributedString(string: paragraph, attributes: attributes)
        let typesetter = CTTypesetterCreateWithAttributedString(paragraphText as CFAttributedString)
        let stringLength = paragraphText.length
        let width = Double(layoutWidth)
        var characterIndex = 0
        var lines = [CTLine]()
        
        while characterIndex < stringLength {
            let lineLength = typesetter.suggestedLineBreak(startIndex: characterIndex, width: width)
            let lineRange = CFRange(location: characterIndex, length: lineLength)
            let lineLayout = typesetter.createLine(from: lineRange)
            characterIndex += lineLength
            lines.append(lineLayout)
        }
        
        paragraphs.append((paragraphText, lines))
    }
    
    return paragraphs
}
