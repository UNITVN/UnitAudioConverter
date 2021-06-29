//
//  UAFileType.swift
//  UnitAudioConverter
//
//  Created by Quang Tran on 6/29/21.
//

import Foundation
import AVFoundation

public enum UAFileType: Int, CaseIterable {
    case mp3
    case m4a
    case wav
    case wma
    case flac
    case aac
    case aiff
    case ogg
    
    var avFileType: AVFileType {
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
        }
    }
    
    var audioFormatID: AudioFormatID {
        switch self {
        case .mp3:
            return kAudioFormatMPEGLayer3
        case .m4a:
            return kAudioFormatMPEG4AAC
        case .wav:
            return kAudioFormatLinearPCM
        case .wma:
            return kAudioFormatLinearPCM
        case .flac:
            return kAudioFormatFLAC
        case .aac:
            return kAudioFormatMPEG4AAC
        case .aiff:
            return kAudioFormatLinearPCM
        case .ogg:
            return kAudioFormatFLAC
        }
    }
    
    var audioFileTypeID: AudioFileTypeID {
        switch self {
        case .mp3:
            return kAudioFileMP3Type
        case .m4a:
            return kAudioFileM4AType
        case .wav:
            return kAudioFileWAVEType
        case .wma:
            return kAudioFileAIFFType
        case .flac:
            return kAudioFileFLACType
        case .aac:
            return kAudioFileAAC_ADTSType
        case .aiff:
            return kAudioFileAIFFType
        case .ogg:
            return kAudioFileFLACType
        }
    }
}
