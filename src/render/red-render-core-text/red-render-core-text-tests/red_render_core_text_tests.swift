//
//  red_render_core_text_tests.swift
//  red-render-core-text-tests
//
//  Created by Nathaniel W Griswold on 7/14/20.
//  Copyright © 2020 ManicMind. All rights reserved.
//

import XCTest

class red_render_core_text_tests: XCTestCase {
    class override func setUp() {
        super.setUp()
        red_render_init();
    }
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testHeight() throws {
        var info = red_render_line_info_t()
        let testText = "Something";
        let bytes = testText.cString(using: .utf8)!
        let length = Int32(bytes.count)
        red_render_get_line_info(
            bytes,
            length,
            &info
        );
        
        XCTAssert((info.ascent + info.descent) == 14.0)
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }

}
