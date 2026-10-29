//
//  SnapshotTests.swift
//  Temporary harness: captures the main window for visual review.
//

import XCTest

final class SnapshotTests: XCTestCase {

    @MainActor
    func testCaptureMainWindow() throws {
        let app = XCUIApplication()
        app.launch()

        // Give SwiftUI a beat to settle before capturing.
        Thread.sleep(forTimeInterval: 3)

        let shot = XCUIScreen.main.screenshot()
        let outDir = "/private/tmp/claude-501/-Users-erikwerner-swiftDev-Racc/0a330de8-bd45-4adb-a7f4-03495555b1e2/scratchpad"
        try? shot.pngRepresentation.write(
            to: URL(fileURLWithPath: outDir).appendingPathComponent("racc-window.png")
        )

        let attachment = XCTAttachment(screenshot: shot)
        attachment.name = "racc-window"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
