//
//  ViewController.swift
//  TextViewTests
//
//  Created by Alex Moffat on 6/19/17.
//  Copyright © 2017 Zanthan. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    @IBOutlet weak var text: NSTextView!
    @IBOutlet weak var textScrollView: SynchroScrollView!
    @IBOutlet weak var resultsView: NSTextView!
    @IBOutlet weak var resultsScrollView: SynchroScrollView!
    
    let calculator = ResultsCalculator()
    
    var textHasChanged = false
    var textChangeTimer: Timer? = nil
    var previousTextValue = ""
    var results: [Result]? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()

        text.delegate = self
        textChangeTimer = Timer.scheduledTimer(timeInterval: 0.5,
                                               target: self,
                                               selector: #selector(timerAction),
                                               userInfo: nil,
                                               repeats: true)
        text.lnv_setUpLineNumberView()
        
        textScrollView.setSynchronziedScrollView(view: resultsScrollView)
        resultsScrollView.setSynchronziedScrollView(view: textScrollView)
        
        text.typingAttributes = [
            NSAttributedStringKey.font: NSFont.monospacedDigitSystemFont(ofSize: 16, weight: NSFont.Weight.regular)
        ]
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
            let currentText = (text.textStorage as NSAttributedString!).string
            if currentText != previousTextValue {
                previousTextValue = currentText
                results = try! Executor(lines: Parser(tokens: Lexer(input: previousTextValue).tokenize()).parseDocument()).evaluate()
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
}

extension ViewController: NSTextViewDelegate {
    
    func textDidChange(_ notification: Notification) {
        textHasChanged = true;
    }
}

