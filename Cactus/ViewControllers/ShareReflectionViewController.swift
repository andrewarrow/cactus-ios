//
//  ShareReflectionViewController.swift
//  Cactus
//
//  Created by Neil Poulin on 11/11/19.
//  Copyright © 2019 Cactus. All rights reserved.
//

import UIKit

class ShareReflectionViewController: UIViewController {
    
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var sharedMemberNameTextView: UITextView!
    @IBOutlet weak var sharedAtTextView: UITextView!
    @IBOutlet weak var questionTextView: UITextView!
    @IBOutlet weak var reflectionTextView: UITextView!
    var promptContent: PromptContent?
    var reflectionResponse: ReflectionResponse?
    
    override func viewDidLoad() {
        super.viewDidLoad()
   
        self.configureDateView()
        self.configureNameView()
        self.configureAvatarView()
        self.configureQuestionView()
        self.configureResponseView()
    }
    
    func configureAvatarView() {
        //nothing to do yet
    }
    
    func configureNameView() {
        if let email = self.reflectionResponse?.memberEmail, !FormatUtils.isBlank(email) {
            self.sharedMemberNameTextView.text = email
            self.sharedMemberNameTextView.isHidden = false
        } else {
            self.sharedMemberNameTextView.isHidden = true
        }
    }
    
    func configureDateView() {
        if let sharedAt = self.reflectionResponse?.sharedAt {
            self.sharedAtTextView.text = "Shared on \(FormatUtils.formatDate(sharedAt) ?? "")"
            self.sharedAtTextView.isHidden = false
        } else {
            self.sharedAtTextView.isHidden = true
        }
    }
    
    func configureQuestionView() {
        if let question = self.promptContent?.getQuestionMarkdown(), !FormatUtils.isBlank(question) {
            self.questionTextView.attributedText = MarkdownUtil.toMarkdown(question, font: CactusFont.bold(FontSize.normal), color: CactusColor.darkestGreen)
            self.questionTextView.isHidden = false
        } else {
            self.questionTextView.isHidden = true
        }
    }
    
    func configureResponseView() {
        if let response = self.reflectionResponse?.content.text, !FormatUtils.isBlank(response) {
            self.reflectionTextView.text = response
            self.reflectionTextView.isHidden = false
        } else {
            self.reflectionTextView.isHidden = true
        }
    }
}
