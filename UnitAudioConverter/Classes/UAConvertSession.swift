//
//  UAConvertSession.swift
//  UnitAudioConverter
//
//  Created by Quang Tran on 6/29/21.
//

import Foundation
import AVFoundation

public class UAConvertSession {
    let id: UUID = UUID()
    
    public var avExportSession: AVAssetExportSession?
    var converter: ExtAudioConverter?
    
    var state = MutableState()
    
    var timer: Timer?
    
    func timer(timeInterval: TimeInterval, block: @escaping ((Timer) -> Void) ) {
        timer = Timer(timeInterval: timeInterval, repeats: true, block: block)
        timer?.fire()
    }
    
    deinit {
        timer?.invalidate()
    }
    
    //Method to be implemented latter
    @discardableResult
    private func progress(_ block: @escaping UAConvertProgressBlock) -> Self {
        state.progressBlock = block
        return self
    }
    
    @discardableResult
    public func completion(_ block: @escaping UAConvertCompletionBlock) -> Self {
        state.completionBlock = block
        return self
    }
}

extension UAConvertSession {
    struct MutableState {
        var progressBlock: UAConvertProgressBlock?
        var completionBlock: UAConvertCompletionBlock?
    }
}

extension UAConvertSession: Hashable {
    public static func == (lhs: UAConvertSession, rhs: UAConvertSession) -> Bool {
        return lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
}
