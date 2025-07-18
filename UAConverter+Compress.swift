//
//  UAConverter+Compress.swift
//  UnitAudioConverter
//
//  Created by Tam Nguyen on 18/7/25.
//

import UIKit
import AVFoundation

public extension UAConverter {
    
    @discardableResult
    public func compress(source: URL, destination: URL, fileType:UAFileType, isHigh:Bool = false) -> UAConvertSession {
        let session = UAConvertSession()
        if fileType == .aac {
            session.avExportSession = Self.convertToType(source: source, destination: destination, outputFileType: .m4a, presetName: AVAssetExportPresetAppleM4A) { [weak self] outputURL in
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
                self.compressUsingReaderWriter(source: source, destination: destination, fileType: fileType, isHigh: isHigh) { [weak self] outputURL in
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
        // mp3 m4a wma flac alac aac ogg m4r
        // wav aiff aifc caf au ==> mp3
        activeSessions.insert(session)
        return session
    }
    
    func compressUsingReaderWriter(source: URL, destination: URL, fileType: UAFileType, isHigh: Bool, completion: @escaping ((URL?) -> Void)) {
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
}
