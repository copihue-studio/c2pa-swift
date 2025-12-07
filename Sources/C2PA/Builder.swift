// Copyright 2025 Copihue Studio. All rights reserved.
// Licensed under MIT or Apache-2.0, at your option.

import C2PAC
import Foundation

/// A builder for constructing and signing C2PA manifests.
public final class Builder {
    private let ptr: UnsafeMutablePointer<C2paBuilder>

    /// Creates a new builder from a manifest JSON definition.
    public init(manifestJSON: String) throws {
        ptr = try guardNotNull(c2pa_builder_from_json(manifestJSON))
    }

    deinit { c2pa_builder_free(ptr) }

    /// Signs the source file and writes the signed result with an embedded manifest.
    ///
    /// - Parameters:
    ///   - format: The MIME type of the media file (e.g., "image/jpeg").
    ///   - source: A Stream containing the source media file.
    ///   - destination: A Stream where the signed file will be written.
    ///   - signer: A Signer instance configured with signing credentials.
    /// - Returns: The raw manifest bytes as Data.
    @discardableResult
    public func sign(
        format: String,
        source: Stream,
        destination: Stream,
        signer: Signer
    ) throws -> Data {
        var manifestPtr: UnsafePointer<UInt8>?
        let size = try guardNonNegative(
            c2pa_builder_sign(
                ptr,
                format,
                source.rawPtr,
                destination.rawPtr,
                signer.ptr,
                &manifestPtr
            )
        )
        guard let mp = manifestPtr else { return Data() }
        let data = Data(bytes: mp, count: Int(size))
        c2pa_manifest_bytes_free(mp)
        return data
    }
}
