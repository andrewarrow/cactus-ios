//
//  WelcomeViewController.swift
//  Cactus
//
//  Created by Neil Poulin on 3/5/20.
//  Copyright © 2020 Cactus. All rights reserved.
//

import UIKit
import FirebaseFirestore
class WelcomeViewController: UIViewController {

    @IBOutlet weak var taglineLabel: UILabel!
    let logger = Logger("WelcomeViewController")
    var appSettings: AppSettings? {
        didSet {
            self.updateCopy()
        }
    }
    
    var hasLoaded = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.taglineLabel.alpha = 0
        self.updateCopy()
    }
    
    func updateCopy() {
        guard self.isViewLoaded else {
            return
        }
        let taglineText = self.appSettings?.welcome?.taglineMarkdown ?? "Your private journal for greater mental fitness."
        self.taglineLabel.attributedText = MarkdownUtil.toMarkdown(taglineText, font: CactusFont.normal, color: CactusColor.white)
        UIView.animate(withDuration: 0.2) {
            self.taglineLabel.alpha = 1
        }
    }
}
