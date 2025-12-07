// Copyright 2025 Copihue Studio. All rights reserved.
// Licensed under MIT or Apache-2.0, at your option.

import Foundation

/// Errors that can occur during C2PA operations.
public enum C2PAError: Error, CustomStringConvertible {
    /// An error from the C2PA library with a descriptive message.
    case api(String)

    /// Invalid UTF-8 encoding encountered.
    case utf8

    public var description: String {
        switch self {
        case .api(let msg): return "C2PA: \(msg)"
        case .utf8: return "C2PA: Invalid UTF-8 encoding"
        }
    }
}
