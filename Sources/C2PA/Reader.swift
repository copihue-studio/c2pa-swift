// Copyright 2025 Copihue Studio. All rights reserved.
// Licensed under MIT or Apache-2.0, at your option.

import C2PAC
import Foundation

/// A reader for extracting C2PA manifest data from media files.
public final class Reader {
    private let ptr: UnsafeMutablePointer<C2paReader>

    /// Creates a reader for a media file stream.
    public init(format: String, stream: Stream) throws {
        ptr = try guardNotNull(c2pa_reader_from_stream(format, stream.rawPtr))
    }

    deinit { c2pa_reader_free(ptr) }

    /// Returns the manifest data as a JSON string.
    public func json() throws -> String {
        try stringFromC(c2pa_reader_json(ptr))
    }
}
