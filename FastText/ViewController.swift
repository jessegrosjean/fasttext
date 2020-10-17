//
//  ViewController.swift
//  FastText
//
//  Created by Jesse Grosjean on 10/17/20.
//

import Cocoa

class EditorViewController: NSViewController {
    
    @IBOutlet var scrollView: NSScrollView!
    @IBOutlet var editorView: EditorView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

