import Cocoa

class EditorViewController: NSViewController {
    
    @IBOutlet var scrollView: NSScrollView!
    @IBOutlet var editorView: EditorView!

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func drawByLine(_: Any) {
        editorView.mode = .line
    }
    
    @IBAction func drawByWord(_: Any) {
        editorView.mode = .word
    }
    
    @IBAction func drawByWordFixingDuplicates(_: Any) {
        editorView.mode = .wordFixDuplicates
    }

}

