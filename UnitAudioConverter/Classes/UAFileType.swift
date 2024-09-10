//
//  UAFileType.swift
//  UnitAudioConverter
//
//  Created by Quang Tran on 6/29/21.
//

import Foundation
import AVFoundation

public enum UAFileType: String, CaseIterable {
    case mp3
    case m4a
    case wav
    case wma
    case flac
    case alac
    case aac
    case aiff
    case aifc
    case ogg
    case caf
    case au
    case m4r
    
    public static var allAudios: [UAFileType] {
        return [.m4a, .aac, .caf, .mp3, .wav, .flac, .alac, .aiff, .aifc, .au] //[.mp3, .m4a, .wav, .wma, .flac, .aac, .aiff, .ogg]
    }
    
    public static var allRingtones: [UAFileType] {
        return [.m4r, .aac]
    }
    
    public static var allRecorder: [UAFileType] {
        return [.m4a]
    }
    
    public static var useAVExporter: [UAFileType] {
        return [.m4a, .aac, .caf, .flac, .alac]
    }
    
    public var fileExtension: String {
        return "\(self)"
    }
    
    public var extf: String {
        switch self {
        case .alac:
            return "m4a"
        default:
            return "\(self)"
        }
    }
    
    public var avFileType: AVFileType {
        switch self {
        case .mp3:
            return .mp3
        case .m4a:
            return .m4a
        case .wav:
            return .wav
        case .wma:
            return AVFileType(rawValue: "public.wma-audio")
        case .flac:
            return AVFileType(rawValue: "public.flac-audio")
        case .aac:
            return AVFileType(rawValue: "public.aac-audio")
        case .aiff:
            return .aiff
        case .ogg:
            return AVFileType(rawValue: "public.ogg-audio")
        default:
            return AVFileType(rawValue: "public.audio")
        }
    }
    
    public var audioFormatID: AudioFormatID {
        switch self {
        case .mp3:
            return kAudioFormatMPEGLayer3
        case .m4a, .caf, .aac, .m4r:
            return kAudioFormatMPEG4AAC
        case .wav:
            return kAudioFormatLinearPCM
        case .wma:
            return kAudioFormatLinearPCM
        case .flac:
            return kAudioFormatFLAC
        case .alac:
            return kAudioFormatAppleLossless
        case .aac:
            return kAudioFormatMPEG4AAC
        case .aiff, .aifc:
            return kAudioFormatLinearPCM
        case .ogg:
            return kAudioFormatFLAC
        case .au:
            return kAudioFormatAC3
        }
    }
    
    public var audioFileTypeID: AudioFileTypeID {
        switch self {
        case .mp3:
            return kAudioFileMP3Type
        case .m4a, .m4r:
            return kAudioFileM4AType
        case .caf:
            return kAudioFileCAFType
        case .wav:
            return kAudioFileWAVEType
        case .wma:
            return kAudioFileAIFFType
        case .flac, .alac:
            return kAudioFileFLACType
        case .aac:
            return kAudioFileAAC_ADTSType
        case .aiff:
            return kAudioFileAIFFType
        case .aifc:
            return kAudioFileAIFCType
        case .ogg:
            return kAudioFileFLACType
        case .au:
            return kAudioFileNextType
        }
    }
}
