//
//  PromptContent.swift
//  Cactus Stage
//
//  Created by Neil Poulin on 9/10/19.
//  Copyright © 2019 Cactus. All rights reserved.
//

import Foundation

enum ContentStatus: String, Codable {
    case in_progress
    case submitted
    case processing
    case needs_changes
    case published
    case unknown
    
    public init(from decoder: Decoder) {
        do {
            self = try ContentStatus(rawValue: decoder.singleValueContainer().decode(RawValue.self)) ?? .unknown
        } catch {
            self = .unknown
        }
    }
}

enum ContentType: String, Codable {
    case text
    case quote
    case video
    case photo
    case audio
    case reflect
    case share_reflection
    case elements
    case invite    
    case unknown
    public init(from decoder: Decoder) {
        do {
            self = try ContentType(rawValue: decoder.singleValueContainer().decode(RawValue.self)) ?? .unknown
        } catch {
            self = .unknown
        }
    }
}

enum ContentAction: String, Codable {
    case next
    case previous
    case complete
    case showPricing
    case coreValues
    case unknown
    
    public init(from decoder: Decoder) throws {
        self = try ContentAction(rawValue: decoder.singleValueContainer().decode(RawValue.self)) ?? .unknown
    }
}

enum LinkTarget: String, Codable {
    case _blank
    case _self
    case _parent
    case _top
    
    public init(from decoder: Decoder) throws {
        self = try LinkTarget(rawValue: decoder.singleValueContainer().decode(RawValue.self)) ?? ._blank
    }
}

enum LinkStyle: String, Codable {
    case buttonPrimary
    case buttonSecondary
    case fancyLink
    case link
    
    public init(from decoder: Decoder) throws {
        self = try LinkStyle(rawValue: decoder.singleValueContainer().decode(RawValue.self)) ?? .link
    }
}

class Quote: Codable {
    var text: String?
    var text_md: String?
    var authorName: String?
    var authorTitle: String?
    var authorAvatar: ImageFile?
    
    var isEmpty: Bool {
        isBlank(text) && isBlank(authorName) && isBlank(authorTitle) && isBlank(text_md) && (authorAvatar?.isEmpty ?? true)
    }
    
    enum QuoteCodingKey: CodingKey {
        case text
        case text_md
        case authorName
        case authorTitle
        case authorAvatar
    }
    
    public required init(from decoder: Decoder) throws {
        guard let model = ModelDecoder<QuoteCodingKey>.create(decoder: decoder, codingKeys: QuoteCodingKey.self) else {
            return
        }
        
        self.text = model.optionalString(.text, blankAsNil: true)
        self.authorName = model.optionalString(.authorName, blankAsNil: true)
        self.authorTitle = model.optionalString(.authorTitle, blankAsNil: true)
        self.text_md = model.optionalString(.text_md, blankAsNil: true)
        
        if (try? model.container.decode(String.self, forKey: .authorAvatar)) == nil {
            self.authorAvatar = try? model.container.decode(ImageFile.self, forKey: .authorAvatar)
        }
    }
    
    func getMarkdownText(quoted: Bool=true) -> String? {
        var text = self.text_md ?? self.text
        guard text != nil else {
            return nil
        }
        text = text?.preventOrphanedWords()
        if quoted {
            text = FormatUtils.wrapInDoubleQuotes(input: text)
        }
        
        return text
    }
    
}

class ContentLink: Codable {
    var linkLabel: String?
    var destinationHref: String?
    var linkTarget: LinkTarget?
    var linkStyle: LinkStyle?
    var appendMemberId: Bool = false
    
    enum ContentLinkCodingKey: CodingKey {
        case linkLabel
        case destinationHref
        case linkTarget
        case linkStyle
        case appendMemberId
    }
    
    var isEmpty: Bool {
        return isBlank(linkLabel) && isBlank(destinationHref)
    }
    
    public required init(from decoder: Decoder) throws {
            do {
                let container = try decoder.container(keyedBy: ContentLinkCodingKey.self)
                if let linkLabel = try? container.decode(String.self, forKey: .linkLabel), !isBlank(linkLabel) {
                    self.linkLabel = linkLabel
                }
                
                if let href = try? container.decode(String.self, forKey: .destinationHref), !isBlank(href) {
                    self.destinationHref = href
                }
                
                if let linkTarget = try? container.decode(LinkTarget.self, forKey: .linkTarget) {
                    self.linkTarget = linkTarget
                }
                
                if let linkStyle = try? container.decode(LinkStyle.self, forKey: .linkStyle) {
                    self.linkStyle = linkStyle
                }
                
                if let appendMemberId = try? container.decode(Bool.self, forKey: .appendMemberId) {
                    self.appendMemberId = appendMemberId
                } else {
                    self.appendMemberId = false
                }
                
            } catch {
    //            Logger.shared.error("error decoding Quote content", error)
            }
        }
    
}

class ActionButton: Codable {
    var action: ContentAction?
    var label: String?
    var linkStyle: LinkStyle?
    var isEmpty: Bool {
        return isBlank(label)
    }
}

enum ImagePosition: String, Codable {
    case top
    case bottom
    case center
}

class ContentBackgroundImage: ImageFile {
    var position: ImagePosition?
}

let CORE_VALUE_REPLACE_TOKEN_DEFAULT = "{{CORE_VALUE}}"

class ContentCoreValues: Codable {
    var textTemplateMd: String?
    var valueReplaceToken: String? = CORE_VALUE_REPLACE_TOKEN_DEFAULT
    
    func getMemberCoreValue(member: CactusMember?, preferredIndex: Int?=0) -> String? {
        return member?.getCoreValue(at: preferredIndex ?? 0)
    }
}

class Content: Codable {
    var contentType: ContentType = .text
    var quote: Quote?
    var text: String?
    var text_md: String?
    var backgroundImage: ContentBackgroundImage?
    var label: String?
    var title: String?
    var video: VideoFile?
    var photo: ImageFile?
    var audio: AudioFile?
    var link: ContentLink?
    var actionButton: ActionButton?
    var showElementIcon: Bool?
    var coreValues: ContentCoreValues?
    
    enum ContentCodingKeys: CodingKey {
        case contentType
        case quote
        case text
        case text_md
        case backgroundImage
        case label
        case title
        case video
        case photo
        case audio
        case link
        case actionButton
        case showElementIcon
        case coreValues
    }
    
    public required init(from decoder: Decoder) throws {
        guard let model = ModelDecoder<ContentCodingKeys>.create(decoder: decoder, codingKeys: ContentCodingKeys.self) else {
            return
        }
        let container = model.container
        
        self.contentType = (try? container.decode(ContentType.self, forKey: ContentCodingKeys.contentType)) ?? ContentType.text
        self.quote = try? container.decode(Quote.self, forKey: ContentCodingKeys.quote)
        if self.quote?.isEmpty == true {
            self.quote = nil
        }
        
        self.text = model.optionalString(.text, blankAsNil: true)
        self.text_md = model.optionalString(.text_md, blankAsNil: true)
        self.backgroundImage = try? container.decode(ContentBackgroundImage.self, forKey: ContentCodingKeys.backgroundImage)
        self.label = model.optionalString(.label, blankAsNil: true)
        self.title = model.optionalString(.title, blankAsNil: true)
        
        self.video = try? container.decode(VideoFile.self, forKey: ContentCodingKeys.video)
        if video?.isEmpty == true {
            self.video = nil
        }
        
        self.photo = try? container.decode(ImageFile.self, forKey: ContentCodingKeys.photo)
        if self.photo?.isEmpty == true {
            self.photo = nil
        }
        
        self.audio = try? container.decode(AudioFile.self, forKey: ContentCodingKeys.audio)
        if self.audio?.isEmpty == true {
            self.audio = nil
        }
        
        self.link = try? container.decode(ContentLink.self, forKey: ContentCodingKeys.link)
        if self.link?.isEmpty == true {
            self.link = nil
        }
        
        self.actionButton = try? container.decode(ActionButton.self, forKey: ContentCodingKeys.actionButton)
        if self.actionButton?.isEmpty == true {
            self.actionButton = nil
        }
        
        self.coreValues = try? container.decode(ContentCoreValues.self, forKey: ContentCodingKeys.coreValues)
        
        self.showElementIcon = try? container.decode(Bool.self, forKey: ContentCodingKeys.showElementIcon)
    }
    
    /**
        Get the `text` of the content, with possible Core Values overrides. Resulting text should be considered in markdown format.
        - Parameter member: The member that the content is displayed for.
         This is typically the currently logged in member. If present, member specific core values overrides will be applied, if avilable.
        - Parameter coreValue: The core value to use for the string replacement, if applicable.
         This lets us use a pre-set value rather than the member's core value list.
        - Returns: The string to be displayed in any `text` fields.
     */
    func getDisplayText(member: CactusMember?=nil, preferredIndex: Int?=0, coreValue: String?=nil) -> String? {
        var textString: String? = self.text_md
        if textString == nil || textString?.isEmpty ?? true {
            textString = self.text
        }
                        
        if let coreValue = coreValue ?? self.coreValues?.getMemberCoreValue(member: member, preferredIndex: preferredIndex),
            let coreValuesTemplate = self.coreValues?.textTemplateMd {
            let token = self.coreValues?.valueReplaceToken ?? CORE_VALUE_REPLACE_TOKEN_DEFAULT
            textString = coreValuesTemplate.replacingOccurrences(of: token, with: coreValue)
        }
        
        return textString
    }
}

struct PromptContentField {
    static let scheduledSendAt = "scheduledSendAt"
    static let entryId = "entryId"
    static let promptId = "promptId"
    static let contentStatus = "contentStatus"
    static let subscriptionTiers = "subscriptionTiers"
    static let cactusElement = "cactusElement"
}

class PromptContent: FlamelinkIdentifiable {
    static var schema = FlamelinkSchema.promptContent
    var _fl_meta_: FlamelinkMeta?
    var documentId: String?
    var entryId: String?
    var order: Int?
    var content: [Content] = []
    
    var promptId: String?
    var subjectLine: String?
    var topic: String?
    var shareReflectionCopy_md: String?
    var cactusElement: CactusElement?
    var contentStatus: ContentStatus = .unknown
    var subscriptionTiers: [SubscriptionTier] = []
    
    var preferredCoreValueIndex: Int? = 0
    
    enum CodingKeys: String, CodingKey {
        case _fl_meta_
        case documentId
        case entryId
        case order
        case content
        case promptId
        case subjectLine
        case topic
        case shareReflectionCopy_md
        case cactusElement
        case contentStatus
        case subscriptionTiers
        case preferredCoreValueIndex
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self._fl_meta_ = try? values.decode(FlamelinkMeta.self, forKey: ._fl_meta_)
        self.documentId = try? values.decode(String.self, forKey: .documentId)
        self.entryId = self._fl_meta_?.fl_id
        self.order = try? values.decode(Int.self, forKey: .order)
        
        self.content = (try? values.decode([Content].self, forKey: .content)) ?? []
        self.promptId = try? values.decode(String.self, forKey: .promptId)
        self.subjectLine = try? values.decode(String.self, forKey: .subjectLine)
        self.topic = try? values.decode(String.self, forKey: .topic)
        self.shareReflectionCopy_md = try? values.decode(String.self, forKey: .shareReflectionCopy_md)
        self.cactusElement = try? values.decode(CactusElement.self, forKey: .cactusElement)
        self.contentStatus = (try? values.decode(ContentStatus.self, forKey: .contentStatus)) ?? .unknown
        self.subscriptionTiers = (try? values.decode([SubscriptionTier].self, forKey: .subscriptionTiers)) ?? []
        self.preferredCoreValueIndex = try? values.decode(Int.self, forKey: .preferredCoreValueIndex)
    }
    
    func getIntroText() -> String? {
        return self.content.first?.text
    }
    
    func getIntroTextMarkdown() -> String? {
        return self.content.first?.text_md ?? self.content.first?.text
    }
    
    func getMainImageFile() -> ImageFile? {
        let imageContent = self.content.first { (content) -> Bool in
            content.backgroundImage != nil && (content.backgroundImage?.isEmpty ?? false) == false
        }
        return imageContent?.backgroundImage
    }
    
    func getDisplayableQuestion(member: CactusMember?=nil, coreValue: String?=nil) -> String? {
        let content = self.getReflectContent()
        return content?.getDisplayText(member: member, preferredIndex: self.preferredCoreValueIndex ?? 0, coreValue: coreValue)
    }
    
    func getReflectContent() -> Content? {
        return self.content.first {$0.contentType == .reflect}
    }
    
    func getQuestion() -> String? {
        self.content.first {$0.contentType == .reflect}?.text
    }
        
    func getQuestionMarkdown() -> String? {
        let content = self.content.first {$0.contentType == .reflect}
        return FormatUtils.isBlank(content?.text_md) ? content?.text : content?.text_md
    }
}
