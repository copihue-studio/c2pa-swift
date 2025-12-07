# c2pa-swift

A lean Swift wrapper for C2PA (Coalition for Content Provenance and Authenticity) on iOS.

## Overview

This package provides a minimal Swift interface for signing and verifying C2PA manifests on iOS, using the latest [c2pa-rs](https://github.com/contentauth/c2pa-rs) v0.72.1 binaries.

## Requirements

- iOS 15.0+
- Swift 5.9+

## Installation

Add the package to your Xcode project:

```
https://github.com/copihue-studio/c2pa-swift.git
```

Or add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/copihue-studio/c2pa-swift.git", from: "0.72.1")
]
```

## Usage

### Signing a Photo

```swift
import C2PA

// Create signer with PEM credentials
let signer = try Signer(
    certsPEM: certificateChainPEM,
    privateKeyPEM: privateKeyPEM,
    algorithm: .ps256,
    tsaURL: "http://timestamp.digicert.com"
)

// Create manifest builder
let manifestJSON = """
{
    "claim_generator": "MyApp/1.0",
    "title": "My Photo"
}
"""
let builder = try Builder(manifestJSON: manifestJSON)

// Sign the photo
let sourceStream = try Stream(fileURL: sourceURL, truncate: false)
let destStream = try Stream(fileURL: destURL)
try builder.sign(
    format: "image/jpeg",
    source: sourceStream,
    destination: destStream,
    signer: signer
)
```

### Verifying a Photo

```swift
import C2PA

let stream = try Stream(fileURL: photoURL, truncate: false)
let reader = try Reader(format: "image/jpeg", stream: stream)
let manifestJSON = try reader.json()
print(manifestJSON)
```

## License

Licensed under either of:

- Apache License, Version 2.0 ([LICENSE-APACHE](LICENSE-APACHE))
- MIT license ([LICENSE-MIT](LICENSE-MIT))

at your option.

## Credits

This package uses pre-built iOS binaries from [c2pa-rs](https://github.com/contentauth/c2pa-rs) by the Content Authenticity Initiative.
