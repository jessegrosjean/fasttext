//
//  FastTextTests.swift
//  FastTextTests
//
//  Created by Jesse Grosjean on 10/17/20.
//

import XCTest
@testable import FastText

class FastTextTests: XCTestCase {
    func testBuildLineLayers() throws {
        measure {
            _ = buildLineLayers().map({ each in
                each.display()
            })
        }
    }
    
    func testBuildWordLayersUsingCache() throws {
        let _ = wordLayersCache
        measure {
            _ = buildWordLayersUsingCache(fixDuplicates: false)
        }
    }
    
    func testCachedWordFixingDuplicates() throws {
        let _ = wordLayersCache
        measure {
            _ = buildWordLayersUsingCache(fixDuplicates: true)
        }
    }

}
