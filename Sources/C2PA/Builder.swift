// Copyright 2025 Copihue Studio. All rights reserved.
// Licensed under MIT or Apache-2.0, at your option.

import C2PAC
import Foundation

/// Builder intent specifying what kind of manifest to create.
public enum BuilderIntent: UInt32 {
    /// New digital creation with specified digital source type.
    /// The manifest must not have a parent ingredient.
    case create = 0
    /// Edit of a pre-existing parent asset.
    /// The manifest must have a parent ingredient.
    case edit = 1
    /// Restricted version of Edit for non-editorial changes.
    case update = 2
}

/// Digital source type for content provenance.
public enum DigitalSourceType: UInt32 {
    case empty = 0
    case trainedAlgorithmicData = 1
    case digitalCapture = 2
    case computationalCapture = 3
    case negativeFilm = 4
    case positiveFilm = 5
    case print = 6
    case humanEdits = 7
    case compositeWithTrainedAlgorithmicMedia = 8
    case algorithmicallyEnhanced = 9
    case digitalCreation = 10
    case dataDrivenMedia = 11
    case trainedAlgorithmicMedia = 12
    case algorithmicMedia = 13
    case screenCapture = 14
}

/// A builder for constructing and signing C2PA manifests.
public final class Builder {
    private let ptr: UnsafeMutablePointer<C2paBuilder>

    /// Creates a new builder from a manifest JSON definition.
    public init(manifestJSON: String) throws {
        ptr = try guardNotNull(c2pa_builder_from_json(manifestJSON))
    }

    deinit { c2pa_builder_free(ptr) }

    /// Sets the intent and digital source type for this builder.
    ///
    /// This MUST be called before signing to produce a valid manifest.
    ///
    /// - Parameters:
    ///   - intent: The builder intent (create, edit, update).
    ///   - sourceType: The digital source type of the content.
    public func setIntent(_ intent: BuilderIntent, sourceType: DigitalSourceType) throws {
        let result = c2pa_builder_set_intent(
            ptr,
            C2paBuilderIntent(rawValue: intent.rawValue),
            C2paDigitalSourceType(rawValue: sourceType.rawValue)
        )
        if result != 0 {
            throw C2PAError.builderError("Failed to set intent")
        }
    }

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
