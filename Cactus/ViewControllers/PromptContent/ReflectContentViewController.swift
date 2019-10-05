//
//  ReflectContentViewController.swift
//  Cactus
//
//  Created by Neil Poulin on 9/17/19.
//  Copyright © 2019 Cactus. All rights reserved.
//

import UIKit
import AVKit

class ReflectContentViewController: UIViewController {

    let padding: CGFloat = 8
    @IBOutlet weak var videoView: UIView!
    
    var content: Content!
    var promptContent: PromptContent!
    var player: AVPlayer!
    
    var doneButton: RoundedButton!
    var reflectionResponse: ReflectionResponse?
    
//    @IBOutlet weak var inputToolbar: UIView!
    @IBOutlet weak var questionTextView: UITextView!
    var inputToolbar: UIView!
    var textView: GrowingTextView!
    private var textViewBottomConstraint: NSLayoutConstraint!
    private var doneButtonBottomConstraint: NSLayoutConstraint!
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //TODO: Get the reflection response, either here or in the parent
        
        self.createInputView()
        self.configureView()
        self.createCactusGrowingVideo()
        if let response = self.reflectionResponse {
            self.textView.text = response.content.text
        } else {
            self.textView.text = nil
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        if let video = self.player {
            video.seek(to: CMTime.zero)
            video.play()
            
        }
    }
    
    func createCactusGrowingVideo() {
        
        guard let path = Bundle.main.path(forResource: "cactus-growing", ofType: "mp4") else {
            print("Video not found")
            return
        }
        
        player = AVPlayer(url: URL(fileURLWithPath: path))
        player.play()
        player.playImmediately(atRate: 1.0)
        
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.player?.play()
        
        let videoFrame = AVMakeRect(aspectRatio: CGSize(width: 1, height: 1), insideRect: self.videoView.bounds)
        playerLayer.frame = videoFrame
        
        self.videoView.clipsToBounds = true
        self.videoView.layer.addSublayer(playerLayer)
    }
    
    func configureDoneButton() {
        self.doneButton = RoundedButton()
        self.doneButton.borderRadius = 18
        self.doneButton.contentEdgeInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)

        doneButton.backgroundColor = CactusColor.darkGreen
        
        doneButton.translatesAutoresizingMaskIntoConstraints = false
        doneButton.showsTouchWhenHighlighted = true
        doneButton.addTarget(self, action: #selector(self.doneAction(_:)), for: .primaryActionTriggered)
        doneButton.setTitle("Done", for: .normal)
        doneButton.setTitleColor(.white, for: .normal)
        doneButton.backgroundColor = CactusColor.green
        doneButton.isEnabled = true
        doneButton.isUserInteractionEnabled = true
        
        self.view.addSubview(doneButton)

        self.doneButtonBottomConstraint = doneButton.bottomAnchor.constraint(equalTo: inputToolbar.safeAreaLayoutGuide.topAnchor, constant: -padding)
        let doneButtonRightConstraint = doneButton.rightAnchor.constraint(equalTo: inputToolbar.safeAreaLayoutGuide.rightAnchor, constant: -2 * padding)
        let doneButtonLeftConstraint = doneButton.leftAnchor.constraint(greaterThanOrEqualTo: inputToolbar.safeAreaLayoutGuide.leftAnchor, constant: padding)
        NSLayoutConstraint.activate([
            doneButtonBottomConstraint,
            doneButtonRightConstraint,
            doneButtonLeftConstraint,
            ])
        
    }
    @objc func doneAction(_ sender: Any) {
        print("Done button tapped")
        self.saveResponse()
        view.endEditing(true)
        
    }
    
    func setSaving(_ isSaving: Bool) {
        if isSaving {
            doneButton.setTitle("Saving...", for: .disabled)
            doneButton.backgroundColor = CactusColor.lightGray
            doneButton.isEnabled = false
        } else {
            doneButton.backgroundColor = CactusColor.green
            doneButton.isEnabled = true
        }
    }
    
    func saveResponse() {
        print("saving response...")
        guard let response = self.reflectionResponse else {
            return
        }
        
        let text = self.textView.text
        response.content.text = text
        self.setSaving(true)
        ReflectionResponseService.sharedInstance.save(response) { (_, error) in
            if let error = error {
                print("Error saving reflection response", error)
            }
            
            self.setSaving(false)
            
        }
    }
    
    func createInputView() {
        // *** Create Toolbar
        self.inputToolbar = UIView()
        inputToolbar.backgroundColor = .clear
        inputToolbar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(inputToolbar)
        
        // *** Create GrowingTextView ***
        textView = GrowingTextView()
        textView.delegate = self
        textView.layer.cornerRadius = 12.0
//        textView.maxLength = 200
        textView.maxHeight = 200
        textView.trimWhiteSpaceWhenEndEditing = true
        textView.placeholder = "Say something..."
        textView.placeholderColor = UIColor(white: 0.8, alpha: 1.0)
        textView.font = CactusFont.normal
        textView.translatesAutoresizingMaskIntoConstraints = false
        inputToolbar.addSubview(textView)
        
        self.configureDoneButton()
        
        // *** Autolayout ***
        let topConstraint = textView.topAnchor.constraint(equalTo: inputToolbar.topAnchor, constant: padding)
        topConstraint.priority = UILayoutPriority(999)
        NSLayoutConstraint.activate([
            inputToolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            inputToolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            inputToolbar.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0),
            topConstraint,
            ])
        
        if #available(iOS 11, *) {
            textViewBottomConstraint = textView.bottomAnchor.constraint(equalTo: inputToolbar.safeAreaLayoutGuide.bottomAnchor, constant: -8)
            NSLayoutConstraint.activate([
                textView.leadingAnchor.constraint(equalTo: inputToolbar.safeAreaLayoutGuide.leadingAnchor, constant: padding),
                textView.trailingAnchor.constraint(equalTo: inputToolbar.safeAreaLayoutGuide.trailingAnchor, constant: -padding),
                textViewBottomConstraint,
                ])
        } else {
            textViewBottomConstraint = textView.bottomAnchor.constraint(equalTo: inputToolbar.bottomAnchor, constant: -padding)
            NSLayoutConstraint.activate([
                textView.leadingAnchor.constraint(equalTo: inputToolbar.leadingAnchor, constant: padding),
                textView.trailingAnchor.constraint(equalTo: inputToolbar.trailingAnchor, constant: -padding),
                textViewBottomConstraint,
                ])
        }
        
        // *** Listen to keyboard show / hide ***
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillChangeFrame), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        
        // *** Hide keyboard when tapping outside ***
//        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.tapGestureHandler))
//        tapGesture.end
//        view.addGestureRecognizer(tapGesture)
    }
    
    func configureView() {
        let questionText = !FormatUtils.isBlank(content.text_md) ? content.text_md : content.text
        self.questionTextView.attributedText = MarkdownUtil.centeredMarkdown(questionText, font: CactusFont.large)
    }

    @objc private func keyboardWillChangeFrame(_ notification: Notification) {
        if let endFrame = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            var keyboardHeight = UIScreen.main.bounds.height - endFrame.origin.y
            if #available(iOS 11, *) {
                if keyboardHeight > 0 {
                    keyboardHeight -= view.safeAreaInsets.bottom
                }
            }
            textViewBottomConstraint.constant = -keyboardHeight - padding
//            doneButtonBottomConstraint.constant = -keyboardHeight - padding
            view.layoutIfNeeded()
        }
    }
    
    @objc private func tapGestureHandler() {
        view.endEditing(true)
    }
    
}

extension ReflectContentViewController: GrowingTextViewDelegate {
    func textViewDidChangeHeight(_ textView: GrowingTextView, height: CGFloat) {
        print("text view did change height")
        UIView.animate(withDuration: 0.3, delay: 0.0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.7, options: [.curveLinear], animations: { () -> Void in
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
}
