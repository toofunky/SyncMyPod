import SwiftUI

enum TagEditorTab: String, CaseIterable, Hashable {
    case details
    case sorting
    case lyrics

    var title: LocalizedStringKey {
        switch self {
        case .details: "Details"
        case .sorting: "Sorting"
        case .lyrics: "Lyrics"
        }
    }
}
