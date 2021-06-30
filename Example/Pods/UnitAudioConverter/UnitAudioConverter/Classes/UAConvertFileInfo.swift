//
//  UAConvertFileInfo.swift
//  UnitAudioConverter
//
//  Created by Quang Tran on 6/29/21.
//

import Foundation
import AVKit

public struct UAConvertFileInfo {
    
    public var outputType: UAFileType = .m4a
    public var timeRange: CMTimeRange = .zero
    public var source: URL
    public var destination: URL
    
    public init(outputType: UAFileType = .m4a, timeRange: CMTimeRange = .zero, source: URL, destination: URL) {
        self.outputType = outputType
        self.timeRange = timeRange
        self.source = source
        self.destination = destination
    }
}
