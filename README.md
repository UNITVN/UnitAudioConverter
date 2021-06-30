# UnitAudioConverter

[![CI Status](https://img.shields.io/travis/Quang Tran/UnitAudioConverter.svg?style=flat)](https://travis-ci.org/Quang Tran/UnitAudioConverter)
[![Version](https://img.shields.io/cocoapods/v/UnitAudioConverter.svg?style=flat)](https://cocoapods.org/pods/UnitAudioConverter)
[![License](https://img.shields.io/cocoapods/l/UnitAudioConverter.svg?style=flat)](https://cocoapods.org/pods/UnitAudioConverter)
[![Platform](https://img.shields.io/cocoapods/p/UnitAudioConverter.svg?style=flat)](https://cocoapods.org/pods/UnitAudioConverter)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

UnitAudioConverter is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'UnitAudioConverter'
```

## Author

Quang Tran, trmquang3103@gmail.com

## License

UnitAudioConverter is available under the MIT license. See the LICENSE file for more info.
# UnitAudioConverter

```swift
let outputType: UAFileType = .mp3
let fileInfo = UAConvertFileInfo(outputType: outputType, source: filePath, destination: fileDestination)
            
UAConverter.shared.convert(fileInfo: fileInfo)
    .completion { [weak self] error in
        print("finished: \(outputType.name)")
        print(error as Any)
    }
```
