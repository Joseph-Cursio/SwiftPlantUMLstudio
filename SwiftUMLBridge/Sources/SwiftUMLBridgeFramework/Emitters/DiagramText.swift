import Compression
import Foundation

struct DiagramText: RawRepresentable {
    var rawValue: String

    var encodedValue: String {
        let compressedData = deflate(rawValue)
        let encodedText = base64plantuml(compressedData)
        return encodedText
    }
}

private extension DiagramText {
    func deflate(_ text: String) -> NSData {
        let sourceString = text
        let sourceBuffer = Array(sourceString.utf8)
        let destinationBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: sourceString.count)
        let algorithm = COMPRESSION_ZLIB
        let compressedSize = compression_encode_buffer(destinationBuffer, sourceString.count,
                                                       sourceBuffer, sourceString.count,
                                                       nil,
                                                       algorithm)
        return NSData(bytesNoCopy: destinationBuffer, length: compressedSize)
    }
}

internal extension DiagramText {
    func base64plantuml(_ compressedData: NSData) -> String {
        let bytes = [UInt8](compressedData)

        let encodingAlphabetTable: [UInt8] = [
            48, 49, 50, 51, 52, 53, 54, 55, 56, 57,
            65, 66, 67, 68, 69, 70, 71, 72, 73, 74,
            75, 76, 77, 78, 79, 80, 81, 82, 83, 84,
            85, 86, 87, 88, 89, 90, 97, 98, 99, 100,
            101, 102, 103, 104, 105, 106, 107, 108, 109, 110,
            111, 112, 113, 114, 115, 116, 117, 118, 119, 120,
            121, 122, 45, 95,
            61 // padding
        ]

        var encodedBytes: [UInt8] = []
        let padding = encodingAlphabetTable[64]

        var byteIndex = 0
        let count = bytes.count

        while byteIndex + 3 <= count {
            let one = bytes[byteIndex] >> 2
            let two = ((bytes[byteIndex] & 0b11) << 4) | ((bytes[byteIndex + 1] & 0b1111_0000) >> 4)
            let three = ((bytes[byteIndex + 1] & 0b0000_1111) << 2) | ((bytes[byteIndex + 2] & 0b1100_0000) >> 6)
            let four = bytes[byteIndex + 2] & 0b0011_1111
            encodedBytes.append(encodingAlphabetTable[Int(one)])
            encodedBytes.append(encodingAlphabetTable[Int(two)])
            encodedBytes.append(encodingAlphabetTable[Int(three)])
            encodedBytes.append(encodingAlphabetTable[Int(four)])
            byteIndex += 3
        }

        if byteIndex + 2 == count {
            let one = bytes[byteIndex] >> 2
            let two = ((bytes[byteIndex] & 0b11) << 4) | ((bytes[byteIndex + 1] & 0b1111_0000) >> 4)
            let three = ((bytes[byteIndex + 1] & 0b0000_1111) << 2)
            encodedBytes.append(encodingAlphabetTable[Int(one)])
            encodedBytes.append(encodingAlphabetTable[Int(two)])
            encodedBytes.append(encodingAlphabetTable[Int(three)])
            encodedBytes.append(padding)
        } else if byteIndex + 1 == count {
            let one = bytes[byteIndex] >> 2
            let two = ((bytes[byteIndex] & 0b11) << 4)
            encodedBytes.append(encodingAlphabetTable[Int(one)])
            encodedBytes.append(encodingAlphabetTable[Int(two)])
            encodedBytes.append(padding)
            encodedBytes.append(padding)
        } else {
            assert(byteIndex == count)
        }

        return String(decoding: encodedBytes, as: Unicode.UTF8.self)
    }
}

extension DiagramText: CustomStringConvertible {
    var description: String { encodedValue }
}

extension DiagramText: CustomDebugStringConvertible {
    var debugDescription: String { "\(rawValue) encoded is \(encodedValue)" }
}
