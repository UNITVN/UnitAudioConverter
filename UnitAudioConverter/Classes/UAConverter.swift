//
//  UAConverter.swift
//  UnitAudioConverter
//
//  Created by Quang Tran on 6/29/21.
//

import Foundation
import AVFoundation
import AudioToolbox
import AVFoundation

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
        if fileType == .wav || fileType == .caf || fileType == .aac || fileType == .au || fileType == .flac || fileType == .alac || fileType == .aifc || fileType == .aiff{
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
                //                let audioConverter = ExtendedAudioFileConvertOperation(sourceURL: source, destinationURL: destination, sampleRate: 44100, outputFormat: fileType.audioFormatID)
                //                audioConverter!.delegate = self;
                //                audioConverter?.start()
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

    @discardableResult
    public func compress(source: URL, destination: URL, fileType:UAFileType, isHigh:Bool = false) -> UAConvertSession {
        let session = UAConvertSession()
        if fileType == .aac {
            let presetName = isHigh ? AVAssetExportPresetAppleM4A : AVAssetExportPresetMediumQuality
            session.avExportSession = Self.convertToType(source: source, destination: destination, outputFileType: .m4a, presetName: presetName) { [weak self] outputURL in
                if let url = outputURL, session.isCancelled == false {
                    self?.finish(session: session, error: nil)
                } else {
                    self?.finish(session: session, error: session.isCancelled ? ConvertError.cancelled : ConvertError.cannotConvert)
                }
            }
        }
        else if fileType == .aac || fileType == .m4a || fileType == .m4r || fileType == .flac || fileType == .aifc {
            let workItem = DispatchWorkItem {
                if self.checkAudioFileAccessibility(fileURL: source) {
                    debugPrint("Warning: removing existing file at", source.path)
                }
                try? FileManager.default.removeItem(at: destination)
                self.convertToTypeUsingReaderWriter(source: source, destination: destination, fileType: fileType, isHigh: isHigh) { [weak self] outputURL in
                    if let url = outputURL, session.isCancelled == false {
                        self?.finish(session: session, error: nil)
                    } else {
                        self?.finish(session: session, error: session.isCancelled ? ConvertError.cancelled : ConvertError.cannotConvert)
                    }
                }
            }
            DispatchQueue(label: "ExtAudioConverter").async(execute: workItem)
            session.workItem = workItem
        }
//        else if fileType == .alac {
//        }
        // mp3 m4a wma flac alac aac ogg m4r 
        //wav aiff aifc caf au
        else {
            let converter = ExtAudioConverter()
            session.converter = converter
            converter.outputFile = destination.path
            converter.inputFile = source.path
            converter.outputFormatID = fileType.audioFormatID
            converter.outputFileType = fileType.audioFileTypeID
            let workItem = DispatchWorkItem {
                do {
                    let success = session.converter?.convert()
                    if success == true, session.isCancelled == false {
                        self.finish(session: session, error: nil)
                    } else {
                        self.finish(session: session, error: session.isCancelled ? ConvertError.cancelled : ConvertError.cannotConvert)
                    }
                } catch {
                    debugPrint("workItem convert: \(error)")
                }
            }
            DispatchQueue(label: "ExtAudioConverter").async(execute: workItem)
            session.workItem = workItem
//            session.avExportSession = Self.convertToM4a(file: source) { [weak self] convertedFile in
//                converter.outputFile = destination.path
//                converter.inputFile = convertedFile != nil ? convertedFile!.path : source.path
//                converter.outputFormatID = fileType.audioFormatID
//                converter.outputFileType = fileType.audioFileTypeID
//                let workItem = DispatchWorkItem {
//                    do {
//                        let success = session.converter?.convert()
//                        if success == true, session.isCancelled == false {
//                            self?.finish(session: session, error: nil)
//                        } else {
//                            self?.finish(session: session, error: session.isCancelled ? ConvertError.cancelled : ConvertError.cannotConvert)
//                        }
//                    } catch {
//                        debugPrint("workItem convert: \(error)")
//                    }
//                }
//                DispatchQueue(label: "ExtAudioConverter").async(execute: workItem)
//                session.workItem = workItem
//            }
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
    
    func convertToTypeUsingReaderWriter(source: URL, destination: URL, fileType: UAFileType, isHigh: Bool, completion: @escaping ((URL?) -> Void)) {
        let asset = AVAsset(url: source)
        guard let assetReader = try? AVAssetReader(asset: asset) else {
            completion(nil)
            return
        }
        
        let outputSettings: [String: Any]
        switch fileType {
        case .m4a, .aac, .m4r:
            outputSettings = [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVEncoderBitRateKey: isHigh ? 96000 : 128000,
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 2
            ]
        case .flac:
            outputSettings = [
                AVFormatIDKey: kAudioFormatFLAC,
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 2
            ]
        case .aifc:
            outputSettings = [
                AVFormatIDKey: kAudioFormatAppleIMA4,
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 2
            ]
        default:
            completion(nil)
            return
        }
        
        guard let assetWriter = try? AVAssetWriter(outputURL: destination, fileType: .caf) else {
            completion(nil)
            return
        }
        
        let readerOutput = AVAssetReaderAudioMixOutput(audioTracks: asset.tracks(withMediaType: .audio), audioSettings: nil)
        assetReader.add(readerOutput)
        
        let writerInput = AVAssetWriterInput(mediaType: .audio, outputSettings: outputSettings)
        assetWriter.add(writerInput)
        
        assetWriter.startWriting()
        assetReader.startReading()
        assetWriter.startSession(atSourceTime: .zero)
        
        let processingQueue = DispatchQueue(label: "audioProcessingQueue")
        writerInput.requestMediaDataWhenReady(on: processingQueue) {
            while writerInput.isReadyForMoreMediaData {
                if let sampleBuffer = readerOutput.copyNextSampleBuffer() {
                    writerInput.append(sampleBuffer)
                } else {
                    writerInput.markAsFinished()
                    assetWriter.finishWriting {
                        if assetWriter.status == .completed {
                            completion(destination)
                        } else {
                            completion(nil)
                        }
                    }
                    break
                }
            }
        }
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
    
    public static func convertToType(source: URL, destination: URL, outputFileType:AVFileType, presetName: String = AVAssetExportPresetPassthrough, completion: @escaping ((URL?) -> Void)) -> AVAssetExportSession? {
        guard let exportSession = AVAssetExportSession(asset: AVURLAsset(url: source), presetName: presetName) else {
            completion(nil)
            return nil
        }
        let dispatchGroup = DispatchGroup()
        var isCompatible = false
        // Kiểm tra tính tương thích trước khi tiếp tục
        dispatchGroup.enter()
        exportSession.determineCompatibleFileTypes { compatibleTypes in
            isCompatible = compatibleTypes.contains(where: { $0 == outputFileType})
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
        exportSession.outputFileType = outputFileType
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
//                converter.convert(to: bu, from: )(to: outputFile, error: nil) { _ in
//                    completion(nil)
//                }
            } catch {
                debugPrint("workItem convert: \(error)")
            }
        }
        DispatchQueue(label: "ExtAudioConverter").async(execute: workItem)
        return workItem
    }


    /*
     // WAV CAF AU AAC ALAC FLAC AIFF AIFC
     
        AAC (Advanced Audio Coding)
        Định dạng đích: kAudioFormatMPEG4AAC
        Định dạng tệp: kAudioFileM4AType, kAudioFileAAC_ADTSType, kAudioFileAAC_ADTSType

        ALAC (Apple Lossless Audio Codec)
        Định dạng đích: kAudioFormatAppleLossless
        Định dạng tệp: kAudioFileM4AType

        FLAC (Free Lossless Audio Codec)
        Định dạng đích: kAudioFormatFLAC
        Định dạng tệp: kAudioFileFLACType

        AIFF (Audio Interchange File Format)
        Định dạng đích: kAudioFormatLinearPCM
        Định dạng tệp: kAudioFileAIFFType

        AIFC (Audio Interchange File Compressed)
        Định dạng đích: kAudioFormatAppleIMA4
        Định dạng tệp: kAudioFileAIFCType

        Linear PCM (Pulse Code Modulation)
        Định dạng đích: kAudioFormatLinearPCM
        Định dạng tệp: kAudioFileWAVEType, kAudioFileCAFType, kAudioFileAIFFType
        
        Chi tiết các định dạng:
        AAC (Advanced Audio Coding)
        Định dạng đích: kAudioFormatMPEG4AAC
        Định dạng tệp: kAudioFileM4AType, kAudioFileAAC_ADTSType, kAudioFileAAC_ADTSType
        Các thuộc tính:
        mSampleRate: Tốc độ mẫu của tệp nguồn
        mFormatID: kAudioFormatMPEG4AAC
        mChannelsPerFrame: Số kênh của tệp nguồn
        mFramesPerPacket: 1024
        mFormatFlags: AudioFormatFlags(MPEG4ObjectID.AAC_LC.rawValue)

        ALAC (Apple Lossless Audio Codec)
        Định dạng đích: kAudioFormatAppleLossless
        Định dạng tệp: kAudioFileM4AType
        Các thuộc tính:
        mSampleRate: Tốc độ mẫu của tệp nguồn
        mFormatID: kAudioFormatAppleLossless
        mChannelsPerFrame: Số kênh của tệp nguồn
        mFramesPerPacket: 4096
        mFormatFlags: 0

        FLAC (Free Lossless Audio Codec)
        Định dạng đích: kAudioFormatFLAC
        Định dạng tệp: kAudioFileFLACType
        Các thuộc tính:
        mSampleRate: Tốc độ mẫu của tệp nguồn
        mFormatID: kAudioFormatFLAC
        mChannelsPerFrame: Số kênh của tệp nguồn
        mBitsPerChannel: 16
        mBytesPerPacket: 0 (biến đổi)
        mBytesPerFrame: 0 (biến đổi)
        mFramesPerPacket: 0 (biến đổi)
        mFormatFlags: 0

        AIFF (Audio Interchange File Format)
        Định dạng đích: kAudioFormatLinearPCM
        Định dạng tệp: kAudioFileAIFFType
        Các thuộc tính:
        mSampleRate: Tốc độ mẫu của tệp nguồn
        mFormatID: kAudioFormatLinearPCM
        mChannelsPerFrame: Số kênh của tệp nguồn
        mBitsPerChannel: 16
        mBytesPerPacket: 2 * mChannelsPerFrame
        mBytesPerFrame: 2 * mChannelsPerFrame
        mFramesPerPacket: 1
        mFormatFlags: kLinearPCMFormatFlagIsPacked | kAudioFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsBigEndian

        AIFC (Audio Interchange File Compressed)
        Định dạng đích: kAudioFormatAppleIMA4
        Định dạng tệp: kAudioFileAIFCType
        Các thuộc tính:
        mSampleRate: Tốc độ mẫu của tệp nguồn
        mFormatID: kAudioFormatAppleIMA4
        mChannelsPerFrame: Số kênh của tệp nguồn
        mBitsPerChannel: 16
        mBytesPerPacket: 34
        mBytesPerFrame: 2
        mFramesPerPacket: 64
        mFormatFlags: 0

        Linear PCM (Pulse Code Modulation)
        Định dạng đích: kAudioFormatLinearPCM
        Định dạng tệp: kAudioFileWAVEType, kAudioFileCAFType, kAudioFileAIFFType
        Các thuộc tính:
        mSampleRate: 44100
        mFormatID: audioFormat
        mChannelsPerFrame: Số kênh của tệp nguồn
        mBitsPerChannel: 16
        mBytesPerPacket: 2 * mChannelsPerFrame
        mBytesPerFrame: 2 * mChannelsPerFrame
        mFramesPerPacket: 1
        mFormatFlags: kLinearPCMFormatFlagIsPacked | kAudioFormatFlagIsSignedInteger
    */
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

        print("Source format: \(srcFormat)")

        if audioFormat == kAudioFormatMPEG4AAC {
            // Set the destination format to AAC
            dstFormat.mSampleRate = srcFormat.mSampleRate
            dstFormat.mFormatID = kAudioFormatMPEG4AAC
            dstFormat.mChannelsPerFrame = srcFormat.mChannelsPerFrame
            dstFormat.mFramesPerPacket = 1024
            dstFormat.mFormatFlags = AudioFormatFlags(MPEG4ObjectID.AAC_LC.rawValue)
            
            var dstFormatSize: UInt32 = UInt32(MemoryLayout.size(ofValue: dstFormat))
            error = AudioFormatGetProperty(kAudioFormatProperty_FormatInfo, 0, nil, &dstFormatSize, &dstFormat)
            if error != noErr {
                completion(nil, NSError(domain: NSOSStatusErrorDomain, code: Int(error), userInfo: nil))
                return
            }
        } else if audioFormat == kAudioFormatAppleLossless {
            // Set the destination format to ALAC
            dstFormat.mSampleRate = srcFormat.mSampleRate
            dstFormat.mFormatID = kAudioFormatAppleLossless
            dstFormat.mChannelsPerFrame = srcFormat.mChannelsPerFrame
            dstFormat.mFramesPerPacket = 4096
            dstFormat.mFormatFlags = 0
            
            var dstFormatSize: UInt32 = UInt32(MemoryLayout.size(ofValue: dstFormat))
            error = AudioFormatGetProperty(kAudioFormatProperty_FormatInfo, 0, nil, &dstFormatSize, &dstFormat)
            if error != noErr {
                completion(nil, NSError(domain: NSOSStatusErrorDomain, code: Int(error), userInfo: nil))
                return
            }
        } else if audioFormat == kAudioFormatFLAC {
            // Set the destination format for FLAC
            dstFormat.mSampleRate = srcFormat.mSampleRate
            dstFormat.mFormatID = kAudioFormatFLAC
            dstFormat.mChannelsPerFrame = srcFormat.mChannelsPerFrame
            dstFormat.mBitsPerChannel = 16  // 16-bit is a common choice for FLAC, but it can be adjusted based on the source
            dstFormat.mBytesPerPacket = 0    // FLAC is compressed, so byte size per packet is variable
            dstFormat.mBytesPerFrame = 0     // Byte size per frame is also variable
            dstFormat.mFramesPerPacket = 0   // Variable, let the encoder decide this
            dstFormat.mFormatFlags = 0       // No need for format flags for FLAC
        } else if audioFormat == kAudioFormatLinearPCM && audioType == kAudioFileAIFFType {
            // Set the destination format for AIFF
            dstFormat.mSampleRate = srcFormat.mSampleRate
            dstFormat.mFormatID = kAudioFormatLinearPCM
            dstFormat.mChannelsPerFrame = srcFormat.mChannelsPerFrame
            dstFormat.mBitsPerChannel = 16
            dstFormat.mBytesPerPacket = 2 * dstFormat.mChannelsPerFrame
            dstFormat.mBytesPerFrame = 2 * dstFormat.mChannelsPerFrame
            dstFormat.mFramesPerPacket = 1
            dstFormat.mFormatFlags = kLinearPCMFormatFlagIsPacked | kAudioFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsBigEndian
        } else if audioFormat == kAudioFormatAppleIMA4 && audioType == kAudioFileAIFCType {
            // Set the destination format for AIFC
            dstFormat.mSampleRate = srcFormat.mSampleRate
            dstFormat.mFormatID = kAudioFormatAppleIMA4
            dstFormat.mChannelsPerFrame = srcFormat.mChannelsPerFrame
            dstFormat.mBitsPerChannel = 16
            dstFormat.mBytesPerPacket = 34
            dstFormat.mBytesPerFrame = 2
            dstFormat.mFramesPerPacket = 64
            dstFormat.mFormatFlags = 0
        }  else {
            // Set the destination format for other formats
            dstFormat.mSampleRate = 44100
            dstFormat.mFormatID = audioFormat
            dstFormat.mChannelsPerFrame = srcFormat.mChannelsPerFrame
            dstFormat.mBitsPerChannel = 16
            dstFormat.mBytesPerPacket = 2 * dstFormat.mChannelsPerFrame
            dstFormat.mBytesPerFrame = 2 * dstFormat.mChannelsPerFrame
            dstFormat.mFramesPerPacket = 1
            dstFormat.mFormatFlags = kLinearPCMFormatFlagIsPacked | kAudioFormatFlagIsSignedInteger
        }

        print("Destination format: \(dstFormat)")

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

        var clientFormat = AudioStreamBasicDescription(mSampleRate: srcFormat.mSampleRate,
                                                       mFormatID: kAudioFormatLinearPCM,
                                                       mFormatFlags: kAudioFormatFlagIsFloat | kAudioFormatFlagIsPacked,
                                                       mBytesPerPacket: 4 * srcFormat.mChannelsPerFrame,
                                                       mFramesPerPacket: 1,
                                                       mBytesPerFrame: 4 * srcFormat.mChannelsPerFrame,
                                                       mChannelsPerFrame: srcFormat.mChannelsPerFrame,
                                                       mBitsPerChannel: 32,
                                                       mReserved: 0)

        error = ExtAudioFileSetProperty(sourceFile!,
                                        kExtAudioFileProperty_ClientDataFormat,
                                        UInt32(MemoryLayout.size(ofValue: clientFormat)),
                                        &clientFormat)
        if error != noErr {
            print("Error setting source file client format: \(error)")
            print("clientFormat: \(clientFormat)")
            completion(nil, NSError(domain: NSOSStatusErrorDomain, code: Int(error), userInfo: nil))
            return
        }
        print("Set source file client format")

        error = ExtAudioFileSetProperty(destinationFile!,
                                        kExtAudioFileProperty_ClientDataFormat,
                                        UInt32(MemoryLayout.size(ofValue: clientFormat)),
                                        &clientFormat)
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
                    mNumberChannels: clientFormat.mChannelsPerFrame,
                    mDataByteSize: bufferByteSize,
                    mData: &srcBuffer
                )
            )
            var numFrames: UInt32 = 0

            if clientFormat.mBytesPerFrame > 0 {
                numFrames = bufferByteSize / clientFormat.mBytesPerFrame
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
