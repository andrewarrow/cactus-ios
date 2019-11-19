//
//  LoadableSharedReflectionViewController.swift
//  Cactus
//
//  Created by Neil Poulin on 11/15/19.
//  Copyright © 2019 Cactus. All rights reserved.
//

import UIKit

class LoadableSharedReflectionViewController: UIViewController {
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var loadingStackView: UIStackView!
    @IBOutlet weak var errorStackView: UIStackView!
    @IBOutlet weak var errorTitleLabel: UILabel!
    @IBOutlet weak var errorMessageLabel: UILabel!
    @IBOutlet weak var errorActionsStackView: UIStackView!
    @IBOutlet weak var openBrowserButton: SecondaryButton!
    @IBOutlet weak var goHomeButton: PrimaryButton!
    @IBOutlet weak var mainStackView: UIStackView!
    
    var originalLink: String?
    var reflectionId: String?
    var logger = Logger(fileName: "LoadableSharedReflectionViewController")
    var sharedReflection: ReflectionResponse?
    var currentVc: UIViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.loadReflectionResponse()
    }
    
    func loadReflectionResponse() {
        guard let reflectionId = self.reflectionId else {
            self.showError("Invalid URL. Unable to load a reflection response", title: "Whoops! Something isn't right.")
            return
        }
        ReflectionResponseService.sharedInstance.getById(reflectionId) { (response, error) in
            if let error = error {
                self.logger.error("Failed to get reflection response", error)
                self.showError("Unable to load the reflection")
                return
            }
            
            if let promptEntryId = response?.promptContentEntryId {
                PromptContentService.sharedInstance.getByEntryId(id: promptEntryId) { (promptContent, error) in
                    self.handlePromptContent(promptContent, error: error)
                }
            } else if let promptId = response?.promptId {
                PromptContentService.sharedInstance.getByPromptId(promptId: promptId) { (promptContent, error) in
                    self.handlePromptContent(promptContent, error: error)
                }
            } else {
                //todo load the prompt content....
                let vc = ViewSharedReflectionViewController.loadFromNib()
                vc.reflectionResponse = response
                self.addTakeover(vc)
                self.hideError()
                self.stopLoading()
            }
        }
    }
    
    func handlePromptContent(_ promptContent: PromptContent?, error: Any?) {
        if let error = error {
            self.logger.error("Failded to load prompt conent", error)
        }
        if let promptContent = promptContent {
            let vc = ViewSharedReflectionViewController.loadFromNib()
            vc.reflectionResponse = self.sharedReflection
            vc.promptContent = promptContent
            self.addTakeover(vc)
            self.hideError()
            self.stopLoading()
        }
    }
    
    func addTakeover(_ vc: UIViewController) {
        self.currentVc = vc
        vc.willMove(toParent: self)
        self.addChild(vc)
        self.view.addSubview(vc.view)        
        vc.didMove(toParent: self)
        vc.view.translatesAutoresizingMaskIntoConstraints = false
        vc.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        vc.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        vc.view.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        vc.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
    }
    
    func startLoading() {
        self.hideError()
        self.loadingStackView.isHidden = false
        self.activityIndicator.startAnimating()
    }
    
    func stopLoading() {
        self.loadingStackView.isHidden = true
        self.activityIndicator.stopAnimating()
    }
    
    func hideError() {
        self.errorStackView.isHidden = true
    }
    
    func showError(_ message: String, title: String?=nil) {
        self.stopLoading()
        self.errorStackView.isHidden = false
        self.errorMessageLabel.text = message
        if let title = title {
            self.errorTitleLabel.isHidden = false
            self.errorTitleLabel.text = title
        }
        
        if self.canOpenLink() {
            self.openBrowserButton.isHidden = false
        } else {
            self.openBrowserButton.isHidden = true
        }
    }
    
    func canOpenLink() -> Bool {
       guard let originalLink = self.originalLink, let url = URL(string: originalLink) else {
           return false
       }
       return UIApplication.shared.canOpenURL(url)
   }
   
    @IBAction func openBrowserTapped(_ sender: Any) {
        guard let originalLink = self.originalLink, let url = URL(string: originalLink) else {
            return
        }
        UIApplication.shared.open(url)
    }
    
    @IBAction func goHomeTapped(_ sender: Any) {
        self.dismiss(animated: true)
    }
}