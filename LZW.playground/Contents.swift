import UIKit

class Binary {

    static let BIN_SIZE = 7

    static func stringToBinary(_ message: String) -> String {
        let asciiValues = Data(message.utf8)
        var binaries = ""
        for i in asciiValues {
            let binary = String(i, radix: 2)
            let adjustBinary = String(Array(repeating: "0", count: BIN_SIZE - binary.count))
            binaries.append("\(adjustBinary)\(binary)")
        }
        return binaries
    }

    static func binaryToString(_ binaries: String) -> String {
        let binaries = Array(binaries)
        var message = [Character]()
        for i in 0..<(binaries.count / BIN_SIZE) {
            let binary = String(binaries[(BIN_SIZE * i)..<(BIN_SIZE * i + BIN_SIZE)])
            let decimal = Int(binary, radix: 2)!
            let character = Character(UnicodeScalar(decimal)!)
            message.append(character)
        }
        return String(message)
    }
}

class LZWSender {

    let encoded: String

    init(encoded: String) {
        self.encoded = encoded
    }

    func compressMessage(sendMessage: (String) -> ()) {
        var currStr = "", database = [String: Int]()

        func storeInDB(bit: Character) {
            if currStr.count > 1 {
                currStr.popLast()
                let value = database[currStr]!
                let key = "\(value)\(bit)"
                currStr.append(bit)
                database[currStr] = database.count + 1
                sendMessage(key)
            } else {
                database[currStr] = database.count + 1
                sendMessage(currStr)
            }
            currStr.removeAll()
        }

        for i in encoded {
            currStr.append(i)
            if let _ = database[currStr] { continue }
            else { storeInDB(bit: i) }
        }
    }
}

class LZWReceiver {

    private var encoded = "", database = [String]()

    func receiveMessage(_ message: String) {
        if message.count > 1 {
            let index = Int(message.dropLast())!
            var value = database[index-1]
            value.append(String(message.last!))
            encoded.append(value)
            database.append(value)
        } else {
            database.append(message)
            encoded.append(message)
        }
    }

    func getMessage() -> String {
        return Binary.binaryToString(encoded)
    }
}

extension String {
    func split(groups: Int) -> [String] {
        let length = Int(self.count / groups)
        return stride(from: 0, to: self.count, by: length).map {
            let start = self.index(self.startIndex, offsetBy: $0)
            let end = self.index(start, offsetBy: length, limitedBy: self.endIndex) ?? self.endIndex
            return String(self[start..<end])
        }
    }
}

func getBinary(message: String, completion: @escaping (String) -> ()) {
    let NUM_THREADS = 4
    let split_msg = message.split(groups: NUM_THREADS)
    var binaries = Array(repeating: "", count: split_msg.count)
    var remaining = split_msg.count
    for (i, msg) in split_msg.enumerated() {
        DispatchQueue.global().async {
            let encoded = Binary.stringToBinary(msg)
            binaries[i] = encoded
            remaining -= 1
            if remaining == 0 {
                completion(binaries.joined())
            }
        }
    }
}

let message = "Hey, Wassup! How're you doing??"

getBinary(message: message) { encoded in
    let senderObj = LZWSender(encoded: encoded)
    let receiverObj = LZWReceiver()
    senderObj.compressMessage(sendMessage: receiverObj.receiveMessage)
    let recMsg = receiverObj.getMessage()
    print(recMsg)
}
