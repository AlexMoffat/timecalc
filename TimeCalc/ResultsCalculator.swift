/*
 * Copyright (c) 2017 Alex Moffat
 *
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of mosquitto nor the names of its
 *    contributors may be used to endorse or promote products derived from
 *    this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

import Cocoa
import Foundation

@available(OSX 10.13, *)
class ResultsCalculator {
    
    let resultStyle = [
        NSAttributedStringKey.font: NSFont.monospacedDigitSystemFont(ofSize: ViewController.FONT_SIZE, weight: NSFont.Weight.regular),
        NSAttributedStringKey.foregroundColor: NSColor.black
    ]
    let commentStyle = [
        NSAttributedStringKey.font: NSFont.monospacedDigitSystemFont(ofSize: ViewController.FONT_SIZE, weight: NSFont.Weight.regular),
        NSAttributedStringKey.obliqueness: NSNumber(value: 0.20),
        NSAttributedStringKey.foregroundColor: NSColor.gray
    ]
    let errorStyle = [
        NSAttributedStringKey.font: NSFont.monospacedDigitSystemFont(ofSize: ViewController.FONT_SIZE, weight: NSFont.Weight.regular),
        NSAttributedStringKey.foregroundColor: NSColor(red: (251/255), green: (128/255), blue: (114/255), alpha: 1.0)
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
                let rangeOfCharactersForStringLine = (textView.string as NSString).lineRange(for: NSMakeRange(layoutManager.characterIndexForGlyph(at: glyphIndexAtStartOfStringLine), 0))
                
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
                            case let .CommentValue(v):
                                text.append(NSAttributedString(string: v, attributes: commentStyle))
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
