//
//  misc.swift
//  b2t80sTests
//
//  Created by German Laullon on 19/10/23.
//

import XCTest

@testable import b2t80s


final class misc: XCTestCase {

//    override func setUpWithError() throws {
//        // Put setup code here. This method is called before the invocation of each test method in the class.
//    }
//
//    override func tearDownWithError() throws {
//        // Put teardown code here. This method is called after the invocation of each test method in the class.
//    }

    func testAddrStr() throws {
        let tests = [
            ("1", "0x1"),
            ("1a", "0x1a"),
            ("1a2", "0x1a2"),
            ("1a2b", "0x1a2b"),
            ("1a2bc", "0x1a2b c"),
            ("1ag", "0x1a g"),
            ("1a ", "0x1a"),
            ("1ag zxy", "0x1a g zxy"),
        ]
        for test in tests {
            let res = try String.AddrFormatStyle().parseStrategy.parse(test.0)
            XCTAssertEqual(res, test.1)
        }
    }

//    func testPerformanceExample() throws {
//        // This is an example of a performance test case.
//        self.measure {
//            // Put the code you want to measure the time of here.
//        }
//    }

}
