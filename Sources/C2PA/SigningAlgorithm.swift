// Copyright 2025 Copihue Studio. All rights reserved.
// Licensed under MIT or Apache-2.0, at your option.

import C2PAC
import Foundation

/// Cryptographic algorithms supported for C2PA signing.
public enum SigningAlgorithm: Sendable {
    /// ECDSA with SHA-256 using the P-256 curve.
    case es256

    /// RSA-PSS with SHA-256 (used by Neat Photo).
    case ps256

    var cValue: C2paSigningAlg {
        switch self {
        case .es256: return Es256
        case .ps256: return Ps256
        }
    }

    public var description: String {
        switch self {
        case .es256: return "es256"
        case .ps256: return "ps256"
        }
    }
}

/// A container for signing credentials and configuration.
public struct SignerInfo: Sendable {
    /// The signing algorithm to use.
    public let algorithm: SigningAlgorithm

    /// The certificate chain in PEM format.
    public let certificatePEM: String

    /// The private key in PEM format.
    public let privateKeyPEM: String

    /// Optional URL of a timestamp authority for trusted timestamps.
    public let tsaURL: String?

    public init(
        algorithm: SigningAlgorithm,
        certificatePEM: String,
        privateKeyPEM: String,
        tsaURL: String? = nil
    ) {
        self.algorithm = algorithm
        self.certificatePEM = certificatePEM
        self.privateKeyPEM = privateKeyPEM
        self.tsaURL = tsaURL
    }
}
