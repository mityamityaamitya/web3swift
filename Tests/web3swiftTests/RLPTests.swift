//
//  web3swiftRLPTests.swift
//  web3swift-iOS_Tests
//
//  Created by Георгий Фесенко on 02/07/2018.
//  Copyright © 2018 Bankex Foundation. All rights reserved.
//

import BigInt
import XCTest
@testable import web3swift

class RLPTests: XCTestCase {
    func testNewRlp() throws {
        let data = try SolidityFunction(function: "doSome(uint256,uint256)").encode(0x123,0x456)
        
        let address: Address = "0x6a6a0b4aaa60E97386F94c5414522159b45DEdE8"
        var transaction = EthereumTransaction(gasPrice: 0x12345, gasLimit: 0x123123, to: address, value: 0, data: data)
        transaction.chainID = .mainnet
        
        let keystore = try! EthereumKeystoreV3(password: "")!
        let privateKey = try! keystore.UNSAFE_getPrivateKeyData(password: "", account: keystore.address!)
        
        let transaction2 = Transaction(gasPrice: 0x12345, gasLimit: 0x123123, to: address, value: 0, data: data)
        let dataWriter = TransactionDataWriter()
        transaction2.write(to: dataWriter)
        transaction2.write(networkId: .mainnet, to: dataWriter)
        
        
        let unsigned1 = transaction.encode(forSignature: false, chainId: .mainnet)!.hex
        let unsigned2 = dataWriter.done().hex
        XCTAssertEqual(unsigned1, unsigned2)
        
        try! Web3Signer.signTX(transaction: &transaction, keystore: keystore, account: keystore.address!, password: "")
        
        let signed1 = transaction.encode(forSignature: false, chainId: .mainnet)!.hex
        let signed2 = try! transaction2.sign(using: PrivateKey(privateKey), networkId: .mainnet).data().hex
        XCTAssertEqual(signed1, signed2)
    }
    
    func testRLPencodeShortString() {
        let testString = "dog"
        let encoded = RLP.encode(testString)
        var expected = Data([UInt8(0x83)])
        expected.append(testString.data(using: .ascii)!)
        XCTAssert(encoded == expected, "Failed to RLP encode short string")
    }

    func testRLPencodeListOfShortStrings() {
        let testInput = ["cat", "dog"]
        let encoded = RLP.encode(testInput)
        var expected = Data()
        expected.append(Data([UInt8(0xC8)]))
        expected.append(Data([UInt8(0x83)]))
        expected.append("cat".data(using: .ascii)!)
        expected.append(Data([UInt8(0x83)]))
        expected.append("dog".data(using: .ascii)!)
        XCTAssert(encoded == expected, "Failed to RLP encode list of short strings")
    }

    func testRLPdecodeListOfShortStrings() {
        let testInput = ["cat", "dog"]
        var expected = Data()
        expected.append(Data([UInt8(0xC8)]))
        expected.append(Data([UInt8(0x83)]))
        expected.append("cat".data(using: .ascii)!)
        expected.append(Data([UInt8(0x83)]))
        expected.append("dog".data(using: .ascii)!)
        var result = RLP.decode(expected)!
        XCTAssert(result.isList, "Failed to RLP decode list of short strings") // we got something non-empty
        XCTAssert(result.count == 1, "Failed to RLP decode list of short strings") // we got something non-empty
        result = result[0]!
        XCTAssert(result.isList, "Failed to RLP decode list of short strings") // we got something non-empty
        XCTAssert(result.count == 2, "Failed to RLP decode list of short strings") // we got something non-empty
        XCTAssert(result[0]!.data == testInput[0].data(using: .ascii), "Failed to RLP decode list of short strings")
        XCTAssert(result[1]!.data == testInput[1].data(using: .ascii), "Failed to RLP decode list of short strings")
    }

    func testRLPencodeLongString() {
        let testInput = "Lorem ipsum dolor sit amet, consectetur adipisicing elit"
        let encoded = RLP.encode(testInput)
        var expected = Data()
        expected.append(Data([UInt8(0xB8)]))
        expected.append(Data([UInt8(0x38)]))
        expected.append("Lorem ipsum dolor sit amet, consectetur adipisicing elit".data(using: .ascii)!)
        XCTAssert(encoded == expected, "Failed to RLP encode long string")
    }

    func testRLPdecodeLongString() {
        let testInput = "Lorem ipsum dolor sit amet, consectetur adipisicing elit"
        var expected = Data()
        expected.append(Data([UInt8(0xB8)]))
        expected.append(Data([UInt8(0x38)]))
        expected.append(testInput.data(using: .ascii)!)
        let result = RLP.decode(expected)!
        XCTAssert(result.count == 1, "Failed to RLP decode long string")
        XCTAssert(result[0]!.data == testInput.data(using: .ascii), "Failed to RLP decode long string")
    }

    func testRLPencodeEmptyString() {
        let testInput = ""
        let encoded = RLP.encode(testInput)
        var expected = Data()
        expected.append(Data([UInt8(0x80)]))
        XCTAssert(encoded == expected, "Failed to RLP encode empty string")
    }

    func testRLPdecodeEmptyString() {
        let testInput = ""
        var expected = Data()
        expected.append(Data([UInt8(0x80)]))
        let result = RLP.decode(expected)!
        XCTAssert(result.count == 1, "Failed to RLP decode empty string")
        XCTAssert(result[0]!.data == testInput.data(using: .ascii), "Failed to RLP decode empty string")
    }

    func testRLPencodeEmptyArray() {
        let testInput = [Data]()
        let encoded = RLP.encode(testInput)
        var expected = Data()
        expected.append(Data([UInt8(0xC0)]))
        XCTAssert(encoded == expected, "Failed to RLP encode empty array")
    }

    func testRLPdecodeEmptyArray() {
        //        let testInput = [Data]()
        var expected = Data()
        expected.append(Data([UInt8(0xC0)]))
        var result = RLP.decode(expected)!
        XCTAssert(result.count == 1, "Failed to RLP decode empty array")
        result = result[0]!
        guard case .noItem = result.content else { return XCTFail() }
    }

    func testRLPencodeShortInt() {
        let testInput = 15
        let encoded = RLP.encode(testInput)
        let expected = Data([UInt8(0x0F)])
        XCTAssert(encoded == expected, "Failed to RLP encode short int")
    }

    func testRLPdecodeShortInt() {
        let testInput = 15
        let expected = Data([UInt8(0x0F)])
        let result = RLP.decode(expected)!

        XCTAssert(result.count == 1, "Failed to RLP decode short int")
        XCTAssert(BigUInt(result[0]!.data!) == testInput, "Failed to RLP decode short int")
    }

    func testRLPencodeLargeInt() {
        let testInput = 1024
        let encoded = RLP.encode(testInput)
        var expected = Data()
        expected.append(Data([UInt8(0x82)]))
        expected.append(Data([UInt8(0x04)]))
        expected.append(Data([UInt8(0x00)]))
        XCTAssert(encoded == expected, "Failed to RLP encode large int")
    }

    func testRLPdecodeLargeInt() {
        let testInput = 1024
        var expected = Data()
        expected.append(Data([UInt8(0x82)]))
        expected.append(Data([UInt8(0x04)]))
        expected.append(Data([UInt8(0x00)]))
        let result = RLP.decode(expected)!

        XCTAssert(result.count == 1, "Failed to RLP decode large int")
        XCTAssert(BigUInt(result[0]!.data!) == testInput, "Failed to RLP decode large int")
    }

    func testRLPdecodeTransaction() {
        let input = Data.fromHex("0xf90890558504e3b292008309153a8080b9083d6060604052336000806101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff160217905550341561004f57600080fd5b60405160208061081d83398101604052808051906020019091905050600073ffffffffffffffffffffffffffffffffffffffff168173ffffffffffffffffffffffffffffffffffffffff16141515156100a757600080fd5b80600160006101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff16021790555050610725806100f86000396000f300606060405260043610610062576000357c0100000000000000000000000000000000000000000000000000000000900463ffffffff1680638da5cb5b14610067578063b2b2c008146100bc578063d59ba0df146101eb578063d8ffdcc414610247575b600080fd5b341561007257600080fd5b61007a61029c565b604051808273ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200191505060405180910390f35b34156100c757600080fd5b61019460048080359060200190820180359060200190808060200260200160405190810160405280939291908181526020018383602002808284378201915050505050509190803590602001908201803590602001908080602002602001604051908101604052809392919081815260200183836020028082843782019150505050505091908035906020019082018035906020019080806020026020016040519081016040528093929190818152602001838360200280828437820191505050505050919050506102c1565b6040518080602001828103825283818151815260200191508051906020019060200280838360005b838110156101d75780820151818401526020810190506101bc565b505050509050019250505060405180910390f35b34156101f657600080fd5b61022d600480803573ffffffffffffffffffffffffffffffffffffffff169060200190919080351515906020019091905050610601565b604051808215151515815260200191505060405180910390f35b341561025257600080fd5b61025a6106bf565b604051808273ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200191505060405180910390f35b6000809054906101000a900473ffffffffffffffffffffffffffffffffffffffff1681565b6102c96106e5565b6102d16106e5565b6000806000600260003373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060009054906101000a900460ff16151561032e57600080fd5b8651885114151561033e57600080fd5b875160405180591061034d5750595b9080825280602002602001820160405250935060009250600091505b87518210156105f357600160009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff166323b872dd87848151811015156103be57fe5b906020019060200201518a858151811015156103d657fe5b906020019060200201518a868151811015156103ee57fe5b906020019060200201516000604051602001526040518463ffffffff167c0100000000000000000000000000000000000000000000000000000000028152600401808473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020018373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020018281526020019350505050602060405180830381600087803b15156104b857600080fd5b6102c65a03f115156104c957600080fd5b50505060405180519050905080156105e65787828151811015156104e957fe5b90602001906020020151848481518110151561050157fe5b9060200190602002019073ffffffffffffffffffffffffffffffffffffffff16908173ffffffffffffffffffffffffffffffffffffffff16815250508280600101935050868281518110151561055357fe5b90602001906020020151888381518110151561056b57fe5b9060200190602002015173ffffffffffffffffffffffffffffffffffffffff16878481518110151561059957fe5b9060200190602002015173ffffffffffffffffffffffffffffffffffffffff167f334b3b1d4ad406523ee8e24beb689f5adbe99883a662c37d43275de52389da1460405160405180910390a45b8180600101925050610369565b839450505050509392505050565b60008060009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff163373ffffffffffffffffffffffffffffffffffffffff1614151561065e57600080fd5b81600260008573ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060006101000a81548160ff0219169083151502179055506001905092915050565b600160009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1681565b6020604051908101604052806000815250905600a165627a7a723058200618093d895b780d4616f24638637da0e0f9767e6d3675a9525fee1d6ed7f431002900000000000000000000000045245bc59219eeaaf6cd3f382e078a461ff9de7b25a0d1efc3c97d1aa9053aa0f59bf148d73f59764343bf3cae576c8769a14866948da0613d0265634fddd436397bc858e2672653833b57a05cfc8b93c14a6c05166e4a")!
        _ = EthereumTransaction.fromRaw(input)
    }
}
