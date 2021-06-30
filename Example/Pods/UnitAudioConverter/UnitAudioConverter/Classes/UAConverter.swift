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
        converter.outputFile = fileInfo.destination.path
        converter.inputFile = fileInfo.source.path
        converter.outputFormatID = fileInfo.outputType.audioFormatID
        converter.outputFileType = fileInfo.outputType.audioFileTypeID
        
        session.converter = converter
        DispatchQueue(label: "ExtAudioConverter").async {[weak self] in
            let success = converter.convert()
            if success {
                self?.finish(session: session, error: nil)
            } else {
                self?.finish(session: session, error: ConvertError.cannotConvert)
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
    enum ConvertError: Error {
        case cannotConvert
    }
}
