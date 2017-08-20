//
//  ResultsView.swift
//  TextViewTests
//
//  Created by Alex Moffat on 7/2/17.
//  Copyright © 2017 Zanthan. All rights reserved.
//

import Cocoa
import Foundation

class ResultsCalculator {
    
    let resultStyle = [
        NSFontAttributeName: NSFont.monospacedDigitSystemFont(ofSize: 16, weight: NSFontWeightRegular),
        NSForegroundColorAttributeName: NSColor.gray
    ]
    let errorStyle = [
        NSFontAttributeName: NSFont.systemFont(ofSize: 16),
        NSForegroundColorAttributeName: NSColor.magenta
    ]
    let newLineRegex = try! NSRegularExpression(pattern: "\r?\n", options: [])
    
    func calculateText(textView: NSTextView, results: [Result]) -> NSAttributedString {
        let text = NSMutableAttributedString()
        
        if let layoutManager = textView.layoutManager {
            
            // The range of glyphs that will be / have been drawn for the complete text view
            let glyphRange = layoutManager.glyphRange(for: textView.textContainer!)
            // Line number of line being displayed
            var lineNumber = 0
            // Index of the glyph at the start of the current line of characters (which may be displayed as more than one line of glyphs)
            var glyphIndexAtStartOfStringLine = glyphRange.location
            
            // While the glyph at the beginning of the line is still visible.
            while glyphIndexAtStartOfStringLine < NSMaxRange(glyphRange) {
                
                // Range of characters for the line that includes the character that is used for the glyph at the start of the current line.
                let rangeOfCharactersForStringLine = (textView.string! as NSString).lineRange(for: NSMakeRange(layoutManager.characterIndexForGlyph(at: glyphIndexAtStartOfStringLine), 0))
                
                // Range of glyphs used to display characters in the current line.
                let rangeOfGlyphsForStringLine = layoutManager.glyphRange(forCharacterRange: rangeOfCharactersForStringLine, actualCharacterRange: nil)
                
                var glyphIndexAtStartOfGlyphLine = glyphIndexAtStartOfStringLine
                var glyphLineCount = 0
                
                // Process all of the glyphs making up the current string line, which may be multiple lines of glyphs.
                while glyphIndexAtStartOfGlyphLine < NSMaxRange(rangeOfGlyphsForStringLine) {
                    
                    // This will be the glyphs in the current glyph line.
                    var rangeOfGlyphsForGlyphLine = NSMakeRange(0, 0)
                    
                    // Bounds of the line of glyphs that includes the glyph at the start of the current line of glyphs.
                    _ = layoutManager.lineFragmentRect(forGlyphAt: glyphIndexAtStartOfGlyphLine, effectiveRange: &rangeOfGlyphsForGlyphLine, withoutAdditionalLayout: true)
                    
                    if glyphLineCount == 0 && lineNumber < results.count {
                        switch results[lineNumber].value {
                        case let .Left(e):
                            text.append(NSAttributedString(string: e, attributes: errorStyle))
                        case let .Right(s):
                            switch s {
                            case let .StringValue(v):
                                text.append(NSAttributedString(string: v, attributes: resultStyle))
                            default:
                                text.append(NSAttributedString(string: "", attributes: resultStyle))
                            }
                        }
                    } else {
                        text.append(NSAttributedString(string: "", attributes: resultStyle))
                    }
                    text.append(NSAttributedString(string: "\n", attributes: resultStyle))
                    
                    
                    glyphLineCount += 1
                    glyphIndexAtStartOfGlyphLine = NSMaxRange(rangeOfGlyphsForGlyphLine)
                }
                
                lineNumber += 1
                glyphIndexAtStartOfStringLine = NSMaxRange(rangeOfGlyphsForStringLine)
            }
        }
        return text
    }
}
