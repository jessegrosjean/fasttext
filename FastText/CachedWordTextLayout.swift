import Cocoa
import CoreText

let wordLayersCache: [String: TextLayer] = {
    let attributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.userFont(ofSize: 16)!,
        .backgroundColor: NSColor.white,
        .foregroundColor: NSColor.black,
    ]

    var wordsCache: [String: TextLayer] = [:]
    for words in wordsByLine {
        for each in words {
            if wordsCache[each] == nil {
                let attributedWord = NSMutableAttributedString(string: each, attributes: attributes)
                let typesetter = CTTypesetterCreateWithAttributedString(attributedWord as CFAttributedString)
                let wordLayout = typesetter.createLine(from: CFRange(location: 0, length: 0))
                let wordLayer = TextLayer(text: attributedWord, origin: .zero, layout: wordLayout)
                wordLayer.display()
                wordsCache[each] = wordLayer
                
            }
        }
    }
    
    return wordsCache
}()

let wordsByLine: [[String]] = {
    var lines: [String] = []
    text.enumerateLines { line, _ in
        lines.append(line)
    }
    
    var count = 0
    return lines.map { line in
        //var words: [String] = []
        
        return line.components(separatedBy: " ")
        
        /*line.enumerateSubstrings(in: line.startIndex..<line.endIndex, options: .byWords) { (word, range, enclosingRange, _) in
            words.append(word!)
            //words.append("\(count)\(word!)")
            //count += 1
        }
        return words*/
    }
}()

func buildWordLayersUsingCache(fixDuplicates: Bool) -> [CALayer] {
    return wordsByLine.map { words -> CALayer in
        let paragraphLayer = CALayer()

        paragraphLayer.isOpaque = true
        paragraphLayer.masksToBounds = false
        paragraphLayer.anchorPoint = CGPoint(x: 0, y: 0)
        paragraphLayer.contentsGravity = CALayerContentsGravity.topLeft
        
        var xOffset: CGFloat = 0
        var yOffset: CGFloat = 0
        for each in words {
            var wordLayer = wordLayersCache[each]!
            
            if fixDuplicates {
                if wordLayer.superlayer != nil {
                    wordLayer = TextLayer(layer: wordLayer)
                }
            }
            
            let size = wordLayer.bounds.size
            if xOffset == 0 || xOffset + size.width < layoutWidth {
                wordLayer.position = CGPoint(x: xOffset, y: yOffset)
                xOffset += size.width
            } else {
                yOffset += size.height
                xOffset = 0
                wordLayer.position = CGPoint(x: xOffset, y: yOffset)
            }
            paragraphLayer.addSublayer(wordLayer)
        }
        
        if let first = paragraphLayer.sublayers?.first {
            let last = paragraphLayer.sublayers!.last!
            paragraphLayer.bounds = first.frame.union(last.frame)
        }

        return paragraphLayer
    }
}

