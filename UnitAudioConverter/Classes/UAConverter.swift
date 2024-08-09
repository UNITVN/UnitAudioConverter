//
//  UAConverter.swift
//  UnitAudioConverter
//
//  Created by Quang Tran on 6/29/21.
//

import Foundation
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
    public func convert(source: URL, destination: URL, audioFormat:AudioFormatID, audioFileType: AudioFileTypeID) -> UAConvertSession {
        let session = UAConvertSession()
        let converter = ExtAudioConverter()
        session.converter = converter
        session.avExportSession = Self.convertToM4a(file: source) { [weak self] convertedFile in
            converter.outputFile = destination.path
            converter.inputFile = convertedFile != nil ? convertedFile!.path : source.path
            converter.outputFormatID = audioFormat
            converter.outputFileType = audioFileType
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
        case cannotConvert
        case cancelled
    }
}

extension UAConverter {
    static func convertToM4a(file: URL, completion: @escaping ((URL?) -> Void)) -> AVAssetExportSession? {
//        AVAssetExportSession.determineCompatibility(ofExportPreset: AVAssetExportPresetPassthrough, with: AVURLAsset(url: file), outputFileType: AVFileType.m4a) { isCompatible in
//            if !isCompatible {
//                print("Format not compatible.")
//            } else {
//                print("Format compatible.")
//            }
//        }
        let convertSession = AVAssetExportSession(asset: AVURLAsset(url: file), presetName: AVAssetExportPresetPassthrough)
        let outputURL = file.deletingPathExtension().appendingPathExtension("m4a")
        convertSession?.outputURL = outputURL
        convertSession?.outputFileType = .m4a
        convertSession?.exportAsynchronously {
            if let error = convertSession?.error {
                debugPrint("convertToM4a Error: \(error)");
                completion(nil)
            } else {
                completion(outputURL)
            }
        }
        return convertSession
    }
    
//    func convertAACtoWAV(inputURL: URL, outputURL: URL) {
//        var error: OSStatus = noErr
//
//        var destinationFile: ExtAudioFileRef? = nil
//
//        var sourceFile: ExtAudioFileRef? = nil
//
//        var srcFormat: AudioStreamBasicDescription = AudioStreamBasicDescription()
//        var dstFormat: AudioStreamBasicDescription = AudioStreamBasicDescription()
//
//        print("6 About to open \(inputURL) which has a status of \(fileExists(at: inputURL)) which looks like this: \(inputURL as CFURL) as a CFURL")
//        
//        ExtAudioFileOpenURL(inputURL as CFURL, &sourceFile) //**Line where error comes from**
//        print("7")
//
//        var thePropertySize: UInt32 = UInt32(MemoryLayout.stride(ofValue: srcFormat))
//
//        ExtAudioFileGetProperty(sourceFile!,
//                                kExtAudioFileProperty_FileDataFormat,
//                                &thePropertySize, &srcFormat)
//
//        dstFormat.mSampleRate = 44100 // Set sample rate
//        dstFormat.mFormatID = kAudioFormatLinearPCM
//        dstFormat.mChannelsPerFrame = 1
//        dstFormat.mBitsPerChannel = 16
//        dstFormat.mBytesPerPacket = 2 * dstFormat.mChannelsPerFrame
//        dstFormat.mBytesPerFrame = 2 * dstFormat.mChannelsPerFrame
//        dstFormat.mFramesPerPacket = 1
//        dstFormat.mFormatFlags = kLinearPCMFormatFlagIsPacked | kAudioFormatFlagIsSignedInteger
//
//        // Create destination file
//        error = ExtAudioFileCreateWithURL(
//            outputURL as CFURL,
//            kAudioFileWAVEType,
//            &dstFormat,
//            nil,
//            AudioFileFlags.eraseFile.rawValue,
//            &destinationFile)
//        print("Error 1 in convertAACtoWAV: \(error.description)")
//
//        error = ExtAudioFileSetProperty(sourceFile!,
//                                        kExtAudioFileProperty_ClientDataFormat,
//                                        thePropertySize,
//                                        &dstFormat)
//        print("Error 2 in convertAACtoWAV: \(error.description)")
//
//        error = ExtAudioFileSetProperty(destinationFile!,
//                                        kExtAudioFileProperty_ClientDataFormat,
//                                        thePropertySize,
//                                        &dstFormat)
//        print("Error 3 in convertAACtoWAV: \(error.description)")
//
//        let bufferByteSize: UInt32 = 32768
//        var srcBuffer = [UInt8](repeating: 0, count: Int(bufferByteSize))
//        var sourceFrameOffset: ULONG = 0
//
//        while true {
//            var fillBufList = AudioBufferList(
//                mNumberBuffers: 1,
//                mBuffers: AudioBuffer(
//                    mNumberChannels: 2,
//                    mDataByteSize: bufferByteSize,
//                    mData: &srcBuffer
//                )
//            )
//            var numFrames: UInt32 = 0
//
//            if dstFormat.mBytesPerFrame > 0 {
//                numFrames = bufferByteSize / dstFormat.mBytesPerFrame
//            }
//
//            error = ExtAudioFileRead(sourceFile!, &numFrames, &fillBufList)
//            print("Error 4 in convertAACtoWAV: \(error.description)")
//
//            if numFrames == 0 {
//                error = noErr
//                break
//            }
//
//            sourceFrameOffset += numFrames
//            error = ExtAudioFileWrite(destinationFile!, numFrames, &fillBufList)
//            print("Error 5 in convertAACtoWAV: \(error.description)")
//        }
//
//        error = ExtAudioFileDispose(destinationFile!)
//        print("Error 6 in convertAACtoWAV: \(error.description)")
//        error = ExtAudioFileDispose(sourceFile!)
//        print("Error 7 in convertAACtoWAV: \(error.description)")
//    }
//    func fileExists(at url: URL) -> Bool {
//        let fileManager = FileManager.default
//        return fileManager.fileExists(atPath: url.path)
//    }

}
