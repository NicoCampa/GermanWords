//
//  aWordaDayTests.swift
//  aWordaDayTests
//
//  Created by Nicolò Campagnoli on 18.07.25.
//

import Foundation
@testable import aWordaDay
import Testing

struct aWordaDayTests {

    @Test func bundledExportDecodes() throws {
        let testFileURL = URL(fileURLWithPath: #filePath)
        let projectRoot = testFileURL
            .deletingLastPathComponent() // aWordaDayTests
            .deletingLastPathComponent() // project root
        let jsonURL = projectRoot.appendingPathComponent("aWordaDay/wordy_words_export_german.json")

        let data = try Data(contentsOf: jsonURL)
        let decoder = JSONDecoder()
        let exportFile = try decoder.decode(WordExportFile.self, from: data)

        #expect(exportFile.words.count == exportFile.metadata.totalWords)
    }

}
