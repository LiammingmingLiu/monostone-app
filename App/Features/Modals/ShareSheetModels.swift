import SwiftUI

// MARK: - ShareFormat

/// 分享内容的格式选项.
enum ShareFormat: String, Hashable, CaseIterable, Identifiable {
    case markdown
    case pdf
    case plainText

    var id: Self { self }

    var label: String {
        switch self {
        case .markdown:  "Markdown"
        case .pdf:       "PDF"
        case .plainText: "纯文本"
        }
    }

    var systemImage: String {
        switch self {
        case .markdown:  "text.alignleft"
        case .pdf:       "doc.richtext"
        case .plainText: "text.quote"
        }
    }
}

// MARK: - ShareTarget

/// 分享目标（渠道）. 真实实现 iOS 会用 `UIActivityViewController`, 这里是 demo.
enum ShareTarget: String, Hashable, CaseIterable, Identifiable {
    case copy
    case email
    case iMessage
    case notion
    case slack
    case weChat
    case airDrop
    case files

    var id: Self { self }

    var label: String {
        switch self {
        case .copy:      "复制"
        case .email:     "邮件"
        case .iMessage:  "iMessage"
        case .notion:    "Notion"
        case .slack:     "Slack"
        case .weChat:    "微信"
        case .airDrop:   "AirDrop"
        case .files:     "文件 App"
        }
    }

    var systemImage: String {
        switch self {
        case .copy:      "doc.on.doc"
        case .email:     "envelope"
        case .iMessage:  "message"
        case .notion:    "doc.text"
        case .slack:     "rectangle.3.group"
        case .weChat:    "bubble.left.and.bubble.right"
        case .airDrop:   "airplayaudio"
        case .files:     "folder"
        }
    }

    var tint: Color {
        switch self {
        case .copy:      Theme.textDim
        case .email:     .blue
        case .iMessage:  .green
        case .notion:    Theme.text
        case .slack:     .purple
        case .weChat:    .green
        case .airDrop:   Theme.accent
        case .files:     .yellow
        }
    }
}
