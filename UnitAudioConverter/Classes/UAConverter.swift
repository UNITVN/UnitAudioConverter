//
//  UAConverter.swift
//  UnitAudioConverter
//
//  Created by Quang Tran on 6/29/21.
//

import Foundation
import AVFoundation
import AudioKit

public typealias UAConvertProgressBlock = (Float) -> Void
public typealias UAConvertCompletionBlock = (Error?) -> Void

public class UAConverter {
    public static let shared = UAConverter()
    
    var activeSessions: Set<UAConvertSession> = []
    
    private init() {
        
    }
    
    @discardableResult
    public func convert(fileInfo: UAConvertFileInfo) -> UAConvertSession {
        let session = UAConvertSession()
        let converter = ExtAudioConverter()
        session.converter = converter
        Self.convertToM4a(file: fileInfo.source) {[weak self] convertedFile in
            converter.outputFile = fileInfo.destination.path
            converter.inputFile = convertedFile != nil ? convertedFile!.path : fileInfo.source.path
            converter.outputFormatID = fileInfo.outputType.audioFormatID
            converter.outputFileType = fileInfo.outputType.audioFileTypeID
            
            DispatchQueue(label: "ExtAudioConverter").async {[weak self] in
                let success = converter.convert()
                if success {
                    self?.finish(session: session, error: nil)
                } else {
                    self?.finish(session: session, error: ConvertError.cannotConvert)
                }
            }
        }
        
        activeSessions.insert(session)
        return session
    }

    @discardableResult
    public func convert(source: URL, destination: URL, fileType:UAFileType) -> UAConvertSession {
        let session = UAConvertSession()
        if fileType == .alac //m4a
            || fileType == .flac
        {
            do {
                var options = FormatConverter.Options()
                // any options left nil will assume the value of the input file
                options.format = fileType.extf
                if self.checkAudioFileAccessibility(fileURL: source) {
                    debugPrint("Warning: removing existing file at", source.path)
                }
                session.akConverter = FormatConverter(inputURL: source, outputURL: destination, options: options)
                session.akConverter!.start(completionHandler: { error in
                    DispatchQueue.main.async {
                        if let _error = error {
                            print("Error during convertion: \(_error)")
                            self.finish(session: session, error: session.isCancelled ? ConvertError.cancelled : ConvertError.cannotConvert)
                        } else {
                            print("Conversion Complete!")
                            self.finish(session: session, error: nil)
                        }
                    }
                })
            } catch {
                debugPrint("Error converting: \(error)")
                self.finish(session: session, error: ConvertError.cannotConvert)
            }
        } else if fileType == .wav || fileType == .caf || fileType == .au || fileType == .aifc || fileType == .aiff{
            let workItem = DispatchWorkItem {
                if self.checkAudioFileAccessibility(fileURL: source) {
                    debugPrint("Warning: removing existing file at", source.path)
                }
                try? FileManager.default.removeItem(at: destination)
                self.convertAudio(inputURL: source, outputURL: destination, audioType: fileType.audioFileTypeID, audioFormat: fileType.audioFormatID) { outputURL, error in
                    if let url = outputURL {
                        print("Conversion Complete!")
                        self.finish(session: session, error: nil)
                    } else {
                        print("Error during convertion \(error)")
                        self.finish(session: session, error: session.isCancelled ? ConvertError.cancelled : ConvertError.cannotConvert)
                    }
                }
            }
            DispatchQueue(label: "ExtAudioConverter").async(execute: workItem)
            session.workItem = workItem
        } else {
            let converter = ExtAudioConverter()
            session.converter = converter
            session.avExportSession = Self.convertToM4a(file: source) { [weak self] convertedFile in
                converter.outputFile = destination.path
                converter.inputFile = convertedFile != nil ? convertedFile!.path : source.path
                converter.outputFormatID = fileType.audioFormatID
                converter.outputFileType = fileType.audioFileTypeID
                let workItem = DispatchWorkItem {
                    do {
                        let success = session.converter?.convert()
                        if success == true, session.isCancelled == false {
                            self?.finish(session: session, error: nil)
                        } else {
                            self?.finish(session: session, error: session.isCancelled ? ConvertError.cancelled : ConvertError.cannotConvert)
                        }
                    } catch {
                        debugPrint("workItem convert: \(error)")
                    }
                }
                DispatchQueue(label: "ExtAudioConverter").async(execute: workItem)
                session.workItem = workItem
            }
        }
        activeSessions.insert(session)
        return session
    }
    
    func finish(session: UAConvertSession, error: Error?) {
        session.state.completionBlock?(error)
        activeSessions.remove(session)
    }
}

extension UAConverter {
    public enum ConvertError: Error {
        case notCompatible
        case cannotConvert
        case cancelled
    }
}

extension UAConverter {

    func checkAudioFileAccessibility(fileURL: URL) -> Bool {
        let asset = AVAsset(url: fileURL)
        return asset.isPlayable
    }

    
    public static func convertToM4a(file: URL, completion: @escaping ((URL?) -> Void)) -> AVAssetExportSession? {
        guard let exportSession = AVAssetExportSession(asset: AVURLAsset(url: file), presetName: AVAssetExportPresetAppleM4A) else {
            completion(nil)
            return nil
        }
        let dispatchGroup = DispatchGroup()
        var isCompatible = false
        
        // Kiểm tra tính tương thích trước khi tiếp tục
        dispatchGroup.enter()
        exportSession.determineCompatibleFileTypes { compatibleTypes in
            isCompatible = compatibleTypes.contains(.m4a)
            dispatchGroup.leave()
        }
        dispatchGroup.wait()
        if !isCompatible {
            print("Format not compatible.")
            completion(nil)
            return nil
        }
        let tmp_name = file.deletingPathExtension().appendingPathExtension("m4a").lastPathComponent
        let temp = FileManager.default.temporaryDirectory.appendingPathComponent(tmp_name)
        try? FileManager.default.removeItem(at: temp)
        exportSession.outputURL = temp
        exportSession.outputFileType = .m4a
        exportSession.exportAsynchronously {
            if let error = exportSession.error {
                debugPrint("convertToM4a Error: \(error)");
                completion(nil)
            } else {
                completion(temp)
            }
        }
        return exportSession
    }
    
    public static func convertToType(source: URL, destination: URL, type:AVFileType, completion: @escaping ((URL?) -> Void)) -> AVAssetExportSession? {
        guard let exportSession = AVAssetExportSession(asset: AVURLAsset(url: source), presetName: (type == .aiff || type == .aifc) ? AVAssetExportPresetHighestQuality : AVAssetExportPresetAppleM4A) else {
            completion(nil)
            return nil
        }
        let dispatchGroup = DispatchGroup()
        var isCompatible = false
        // Kiểm tra tính tương thích trước khi tiếp tục
        dispatchGroup.enter()
        exportSession.determineCompatibleFileTypes { compatibleTypes in
            isCompatible = compatibleTypes.contains(where: { $0 == type})
            dispatchGroup.leave()
        }
        dispatchGroup.wait()
        if !isCompatible {
            print("Format not compatible.")
            completion(nil)
            return nil
        }
        try? FileManager.default.removeItem(at: destination)
        exportSession.outputURL = destination
        exportSession.outputFileType = type
        exportSession.exportAsynchronously {
            if let error = exportSession.error {
                debugPrint("convertToType Error: \(error)");
                completion(nil)
            } else {
                completion(destination)
            }
        }
        return exportSession
    }

    func convertToALAC(source: URL, destination: URL, completion: @escaping ((URL?) -> Void)) -> DispatchWorkItem? {
        guard let inputFile = try? AVAudioFile(forReading: source) else {
            debugPrint("Error reading into input/output files for reading")
            return nil
        }
        if FileManager.default.fileExists(atPath: destination.path) {
            try? FileManager.default.removeItem(at: destination)
        }
        
        let workItem = DispatchWorkItem {
            do {
                let outputFormat = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: inputFile.fileFormat.sampleRate, channels: inputFile.fileFormat.channelCount, interleaved: false)!
                let outputFile = try AVAudioFile(forWriting: destination, settings: [
                    AVFormatIDKey: kAudioFormatAppleLossless,
                    AVSampleRateKey: inputFile.fileFormat.sampleRate,
                    AVNumberOfChannelsKey: inputFile.fileFormat.channelCount,
                    AVEncoderAudioQualityKey: AVAudioQuality.max.rawValue
                ])

                let buffer = AVAudioPCMBuffer(pcmFormat: inputFile.processingFormat, frameCapacity: AVAudioFrameCount(inputFile.length))!
                try inputFile.read(into: buffer)

                let converter = AVAudioConverter(from: inputFile.processingFormat, to: outputFormat)!
//                converter.convert(to: bu, from: <#T##AVAudioPCMBuffer#>)(to: outputFile, error: nil) { _ in
//                    completion(nil)
//                }
            } catch {
                debugPrint("workItem convert: \(error)")
            }
        }
        DispatchQueue(label: "ExtAudioConverter").async(execute: workItem)
        return workItem
    }
    
    func convertAudio(inputURL: URL, outputURL: URL, audioType: AudioFileTypeID, audioFormat: AudioFormatID, completion: @escaping ((URL?, Error?) -> Void)) {
        var error: OSStatus = noErr

        var destinationFile: ExtAudioFileRef? = nil
        var sourceFile: ExtAudioFileRef? = nil

        var srcFormat: AudioStreamBasicDescription = AudioStreamBasicDescription()
        var dstFormat: AudioStreamBasicDescription = AudioStreamBasicDescription()

        print("About to open \(inputURL) which has a status of \(FileManager.default.fileExists(atPath: inputURL.path)) which looks like this: \(inputURL as CFURL) as a CFURL")
        
        error = ExtAudioFileOpenURL(inputURL as CFURL, &sourceFile)
        if error != noErr {
            completion(nil, NSError(domain: NSOSStatusErrorDomain, code: Int(error), userInfo: nil))
            return
        }
        print("Opened source file")

        var thePropertySize: UInt32 = UInt32(MemoryLayout.stride(ofValue: srcFormat))

        error = ExtAudioFileGetProperty(sourceFile!,
                                        kExtAudioFileProperty_FileDataFormat,
                                        &thePropertySize, &srcFormat)
        if error != noErr {
            completion(nil, NSError(domain: NSOSStatusErrorDomain, code: Int(error), userInfo: nil))
            return
        }

        dstFormat.mSampleRate = 44100
        dstFormat.mFormatID = audioFormat
        dstFormat.mChannelsPerFrame = srcFormat.mChannelsPerFrame
        dstFormat.mBitsPerChannel = 16
        dstFormat.mBytesPerPacket = 2 * dstFormat.mChannelsPerFrame
        dstFormat.mBytesPerFrame = 2 * dstFormat.mChannelsPerFrame
        dstFormat.mFramesPerPacket = 1
        dstFormat.mFormatFlags = kLinearPCMFormatFlagIsPacked | kAudioFormatFlagIsSignedInteger

        error = ExtAudioFileCreateWithURL(
            outputURL as CFURL,
            audioType,
            &dstFormat,
            nil,
            AudioFileFlags.eraseFile.rawValue,
            &destinationFile)
        if error != noErr {
            completion(nil, NSError(domain: NSOSStatusErrorDomain, code: Int(error), userInfo: nil))
            return
        }
        print("Created destination file")

        error = ExtAudioFileSetProperty(sourceFile!,
                                        kExtAudioFileProperty_ClientDataFormat,
                                        thePropertySize,
                                        &dstFormat)
        if error != noErr {
            completion(nil, NSError(domain: NSOSStatusErrorDomain, code: Int(error), userInfo: nil))
            return
        }
        print("Set source file client format")

        error = ExtAudioFileSetProperty(destinationFile!,
                                        kExtAudioFileProperty_ClientDataFormat,
                                        thePropertySize,
                                        &dstFormat)
        if error != noErr {
            completion(nil, NSError(domain: NSOSStatusErrorDomain, code: Int(error), userInfo: nil))
            return
        }
        print("Set destination file client format")

        let bufferByteSize: UInt32 = 32768
        var srcBuffer = [UInt8](repeating: 0, count: Int(bufferByteSize))
        var sourceFrameOffset: ULONG = 0

        while true {
            var fillBufList = AudioBufferList(
                mNumberBuffers: 1,
                mBuffers: AudioBuffer(
                    mNumberChannels: 2,
                    mDataByteSize: bufferByteSize,
                    mData: &srcBuffer
                )
            )
            var numFrames: UInt32 = 0

            if dstFormat.mBytesPerFrame > 0 {
                numFrames = bufferByteSize / dstFormat.mBytesPerFrame
            }

            error = ExtAudioFileRead(sourceFile!, &numFrames, &fillBufList)
            if error != noErr {
                completion(nil, NSError(domain: NSOSStatusErrorDomain, code: Int(error), userInfo: nil))
                return
            }
            print("Read from source file")

            if numFrames == 0 {
                error = noErr
                break
            }

            sourceFrameOffset += numFrames
            error = ExtAudioFileWrite(destinationFile!, numFrames, &fillBufList)
            if error != noErr {
                completion(nil, NSError(domain: NSOSStatusErrorDomain, code: Int(error), userInfo: nil))
                return
            }
            print("Wrote to destination file")
        }

        error = ExtAudioFileDispose(destinationFile!)
        if error != noErr {
            completion(nil, NSError(domain: NSOSStatusErrorDomain, code: Int(error), userInfo: nil))
            return
        }
        print("Disposed destination file")

        error = ExtAudioFileDispose(sourceFile!)
        if error != noErr {
            completion(nil, NSError(domain: NSOSStatusErrorDomain, code: Int(error), userInfo: nil))
            return
        }
        print("Disposed source file")

        completion(outputURL, nil)
    }
}
