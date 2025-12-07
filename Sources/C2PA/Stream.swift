// Copyright 2025 Copihue Studio. All rights reserved.
// Licensed under MIT or Apache-2.0, at your option.

import C2PAC
import Foundation

/// A stream abstraction for reading and writing C2PA data.
public final class Stream {
    public typealias Reader = (_ buffer: UnsafeMutableRawPointer, _ count: Int) -> Int
    public typealias Seeker = (_ offset: Int, _ origin: C2paSeekMode) -> Int
    public typealias Writer = (_ buffer: UnsafeRawPointer, _ count: Int) -> Int
    public typealias Flusher = () -> Int

    private final class StreamProvider {
        let r: Reader?
        let s: Seeker?
        let w: Writer?
        let f: Flusher?
        var fileHandleBox: AnyObject?

        init(r: Reader?, s: Seeker?, w: Writer?, f: Flusher?, fileHandleBox: AnyObject? = nil) {
            self.r = r; self.s = s; self.w = w; self.f = f
            self.fileHandleBox = fileHandleBox
        }
    }

    private static let cRead: ReadCallback = { ctx, data, len in
        guard let ctx, let data else { return -1 }
        let b = Unmanaged<StreamProvider>.fromOpaque(ctx).takeUnretainedValue()
        guard let r = b.r else { return -1 }
        return r(data, Int(len))
    }

    private static let cSeek: SeekCallback = { ctx, off, mode in
        guard let ctx else { return -1 }
        let b = Unmanaged<StreamProvider>.fromOpaque(ctx).takeUnretainedValue()
        guard let s = b.s else { return -1 }
        return s(Int(off), mode)
    }

    private static let cWrite: WriteCallback = { ctx, data, len in
        guard let ctx, let data else { return -1 }
        let b = Unmanaged<StreamProvider>.fromOpaque(ctx).takeUnretainedValue()
        guard let w = b.w else { return -1 }
        return w(data, Int(len))
    }

    private static let cFlush: FlushCallback = { ctx in
        guard let ctx else { return -1 }
        let b = Unmanaged<StreamProvider>.fromOpaque(ctx).takeUnretainedValue()
        return b.f?() ?? 0
    }

    private let streamProviderRef: Unmanaged<StreamProvider>
    private let streamPtr: UnsafeMutablePointer<C2paStream>

    private init(streamProvider: StreamProvider) {
        streamProviderRef = .passRetained(streamProvider)
        let contextPtr = asStreamCtx(streamProviderRef.toOpaque())
        streamPtr = c2pa_create_stream(
            contextPtr,
            streamProvider.r != nil ? Stream.cRead : nil,
            streamProvider.s != nil ? Stream.cSeek : nil,
            streamProvider.w != nil ? Stream.cWrite : nil,
            streamProvider.f != nil ? Stream.cFlush : nil
        )
    }

    /// Creates a read-only stream from in-memory data.
    public convenience init(data: Data) throws {
        var cursor = 0
        let streamProvider = StreamProvider(
            r: { buffer, count in
                let remain = data.count - cursor
                guard remain > 0 else { return 0 }
                let n = Swift.min(remain, count)
                _ = data.withUnsafeBytes {
                    memcpy(buffer, $0.baseAddress!.advanced(by: cursor), n)
                }
                cursor += n
                return n
            },
            s: { offset, mode in
                switch mode {
                case Start: cursor = max(0, offset)
                case Current: cursor = max(0, cursor + offset)
                case End: cursor = max(0, data.count + offset)
                default: return -1
                }
                return cursor
            },
            w: nil, f: nil
        )
        self.init(streamProvider: streamProvider)
    }

    /// Creates a file-based stream for reading and writing.
    public convenience init(
        fileURL url: URL,
        truncate: Bool = true,
        createIfNeeded: Bool = true
    ) throws {
        if createIfNeeded, !FileManager.default.fileExists(atPath: url.path) {
            FileManager.default.createFile(atPath: url.path, contents: nil)
        }

        let fh = try FileHandle(forUpdating: url)
        if truncate { try fh.truncate(atOffset: 0) }

        final class FileHandleBox {
            let fh: FileHandle
            init(_ fh: FileHandle) { self.fh = fh }
            deinit { try? fh.close() }
        }
        let fhBox = FileHandleBox(fh)

        let streamProvider = StreamProvider(
            r: { buffer, count in
                let data = (try? fhBox.fh.read(upToCount: count)) ?? Data()
                data.copyBytes(to: buffer.assumingMemoryBound(to: UInt8.self), count: data.count)
                return data.count
            },
            s: { offset, mode in
                do {
                    let off = Int64(offset)
                    let newPos: UInt64
                    switch mode {
                    case Start:
                        newPos = UInt64(max(0, off))
                    case Current:
                        let currentOffset = Int64(fhBox.fh.offsetInFile)
                        var targetOffset = currentOffset + off
                        if targetOffset < 0 { targetOffset = 0 }
                        newPos = UInt64(targetOffset)
                    case End:
                        let end = try fhBox.fh.seekToEnd()
                        var targetOffset = Int64(end) + off
                        if targetOffset < 0 { targetOffset = 0 }
                        newPos = UInt64(targetOffset)
                    default:
                        return -1
                    }
                    try fhBox.fh.seek(toOffset: newPos)
                    return Int(newPos)
                } catch { return -1 }
            },
            w: { buffer, count in
                try? fhBox.fh.write(contentsOf: Data(bytes: buffer, count: count))
                return count
            },
            f: {
                try? fhBox.fh.synchronize()
                return 0
            },
            fileHandleBox: fhBox
        )
        self.init(streamProvider: streamProvider)
    }

    deinit {
        c2pa_release_stream(streamPtr)
        streamProviderRef.release()
    }

    var rawPtr: UnsafeMutablePointer<C2paStream> { streamPtr }
}
