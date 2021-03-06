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

@available(OSX 10.13, *)
class ViewController: NSViewController {
    
    @IBOutlet weak var text: NSTextView!
    @IBOutlet weak var textScrollView: SynchroScrollView!
    @IBOutlet weak var resultsView: NSTextView!
    @IBOutlet weak var resultsScrollView: SynchroScrollView!
    
    static let FONT_SIZE: CGFloat = 16
    
    let calculator = ResultsCalculator()
    
    let typingAttributes = [
        NSAttributedString.Key.font: NSFont.monospacedDigitSystemFont(ofSize: ViewController.FONT_SIZE, weight: NSFont.Weight.regular),
        NSAttributedString.Key.foregroundColor: NSColor.textColor
    ]
    
    var textHasChanged = false
    var textChangeTimer: Timer? = nil
    var previousTextValue = ""
    var results: [Result]? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()

        text.delegate = self
        text.isAutomaticQuoteSubstitutionEnabled = false
        text.isAutomaticDashSubstitutionEnabled = false
        textChangeTimer = Timer.scheduledTimer(timeInterval: 0.5,
                                               target: self,
                                               selector: #selector(timerAction),
                                               userInfo: nil,
                                               repeats: true)
        text.lnv_setUpLineNumberView()
        
        textScrollView.setSynchronziedScrollView(view: resultsScrollView)
        resultsScrollView.setSynchronziedScrollView(view: textScrollView)
        
        text.typingAttributes = typingAttributes
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    @objc dynamic func timerAction() {
        if textHasChanged {
            textHasChanged = false
        } else {
            let currentText = text.string
            if currentText != previousTextValue {
                previousTextValue = currentText
                results = try! Executor(lines: Parser(tokens: Lexer().tokenize(previousTextValue)).parseDocument()).evaluate()
                displayResult()
            }
        }
    }
    
    func displayResult() {
        textScrollView.paused = true
        resultsScrollView.paused = true
        if let validResults = results {
            let result = calculator.calculateText(textView: text, results: validResults)
            resultsView.textStorage!.setAttributedString(result)
        }
        textScrollView.paused = false
        resultsScrollView.paused = false
        resultsScrollView.synchroViewContentBoundsDidChange(notifyingView: textScrollView.contentView)
    }
    
    func insertFromService(_ s: NSString) {
        guard let storage = text.textStorage else {
            return
        }
        text.moveToEndOfDocument(self)
        let len = storage.length
        if  len != 0 {
            if let lastChar = Unicode.Scalar(storage.mutableString.character(at: len - 1)) {
                if !NSCharacterSet.newlines.contains(lastChar) {
                    text.insertNewline(self)
                }
            }
        }
        storage.append(NSAttributedString(string: s as String, attributes: typingAttributes))
    }
}

@available(OSX 10.13, *)
extension ViewController: NSTextViewDelegate {
    
    func textDidChange(_ notification: Notification) {
        textHasChanged = true;
    }
}

