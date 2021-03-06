//
//  MarkdownUtil.swift
//  Cactus Stage
//
//  Created by Neil Poulin on 9/17/19.
//  Copyright © 2019 Cactus. All rights reserved.
//

import Foundation
import MarkdownKit
import UIKit

public class MarkdownUtil {
    static func centered(_ aText: NSAttributedString?, color: UIColor?=CactusColor.textDefault) -> NSAttributedString? {
        guard let aText = aText else {
            return nil
        }
        
        let mText = NSMutableAttributedString.init(attributedString: aText)
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        let range = NSRange(location: 0, length: aText.length)
        mText.addAttributes([NSAttributedString.Key.paragraphStyle: paragraph], range: range)
        
        let aString = mText.attributedSubstring(from: NSRange(location: 0, length: mText.length))
        return aString
    }
    
    static func centeredMarkdown(_ input: String?, font: UIFont = CactusFont.normal, color: UIColor?=CactusColor.textDefault, boldColor: UIColor?=nil) -> NSAttributedString? {
        guard let md = MarkdownUtil.toMarkdown(input, font: font, color: color, boldColor: boldColor)  else {
            return nil
        }        
        let aString = MarkdownUtil.centered(md)
        return aString
        
    }
    
    static func toMarkdown(_ input: String?, font: UIFont = CactusFont.normal, color: UIColor? = CactusColor.textDefault, boldColor: UIColor?=nil) -> NSAttributedString? {
        guard let input = input, !input.isEmpty else {
            return nil
        }
        
        let markdownParser = MarkdownParser(font: font, color: color ?? CactusColor.textDefault, customElements: [CactusMarkdownLink()])
        markdownParser.enabledElements.remove( .link)
        markdownParser.bold.color = boldColor ?? color
        markdownParser.bold.font = CactusFont.bold(font.pointSize)
        let aString = markdownParser.parse(input)
                
        return aString
    }
}

class CactusMarkdownLink: MarkdownLink {
    override func formatText(_ attributedString: NSMutableAttributedString, range: NSRange, link: String) {
        super.formatText(attributedString, range: range, link: link)
        attributedString.addAttribute(NSAttributedString.Key.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: range)
    }
}
