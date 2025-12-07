// Copyright 2025 Copihue Studio. All rights reserved.
// Licensed under MIT or Apache-2.0, at your option.

import C2PAC
import Foundation

/// A cryptographic signer for creating C2PA signatures.
public final class Signer {
    let ptr: UnsafeMutablePointer<C2paSigner>

    private init(ptr: UnsafeMutablePointer<C2paSigner>) {
        self.ptr = ptr
    }

    /// Creates a signer with PEM-encoded certificates and private key.
    public convenience init(
        certsPEM: String,
        privateKeyPEM: String,
        algorithm: SigningAlgorithm,
        tsaURL: String? = nil
    ) throws {
        var raw: UnsafeMutablePointer<C2paSigner>!
        try withSignerInfo(
            alg: algorithm.description,
            cert: certsPEM,
            key: privateKeyPEM,
            tsa: tsaURL
        ) { algPtr, certPtr, keyPtr, tsaPtr in
            var info = C2paSignerInfo(
                alg: algPtr,
                sign_cert: certPtr,
                private_key: keyPtr,
                ta_url: tsaPtr
            )
            raw = try guardNotNull(c2pa_signer_from_info(&info))
        }
        self.init(ptr: raw)
    }

    /// Creates a signer from a SignerInfo struct.
    public convenience init(info: SignerInfo) throws {
        try self.init(
            certsPEM: info.certificatePEM,
            privateKeyPEM: info.privateKeyPEM,
            algorithm: info.algorithm,
            tsaURL: info.tsaURL
        )
    }

    deinit {
        c2pa_signer_free(ptr)
    }

    /// Returns the expected signature size in bytes for this signer.
    public func reserveSize() throws -> Int {
        try Int(guardNonNegative(c2pa_signer_reserve_size(ptr)))
    }
}
