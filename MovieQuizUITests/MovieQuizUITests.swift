//
//  MovieQuizUITests.swift
//  MovieQuizUITests
//
//  Created by Tatiana on 1/2/26.
//

import XCTest

final class MovieQuizUITests: XCTestCase {
    // swiftlint:disable:next implicitly_unwrapped_optional
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        app = XCUIApplication()
        app.launch()
        
        continueAfterFailure = false
    }
    
    override func tearDownWithError() throws {
        try super.tearDownWithError()
        
        app.terminate()
        app = nil
    }
    
    func testScreenCast() throws {
        app.buttons["Нет"].tap()
    }
    
    
    func testYesButton() {
        // Given
        _ = app.wait(for: .notRunning, timeout: 3)
        let firstPoster = app.images["Poster"]
        let firstPosterData = firstPoster.screenshot().pngRepresentation

        // When
        app.buttons["Yes"].tap()
        _ = app.wait(for: .notRunning, timeout: 3)

        // Then
        let secondPoster = app.images["Poster"]
        let secondPosterData = secondPoster.screenshot().pngRepresentation
        let indexLabel = app.staticTexts["Index"]

        XCTAssertNotEqual(firstPosterData, secondPosterData)
        XCTAssertEqual(indexLabel.label, "2/10")
    }
    
    func testNoButton() {
        // Given
        _ = app.wait(for: .notRunning, timeout: 3)
        
        let firstPoster = app.images["Poster"]
        let firstPosterData = firstPoster.screenshot().pngRepresentation
        
        // When
        app.buttons["No"].tap()
        _ = app.wait(for: .notRunning, timeout: 3)
        
        // Then
        let secondPoster = app.images["Poster"]
        let secondPosterData = secondPoster.screenshot().pngRepresentation

        let indexLabel = app.staticTexts["Index"]
       
        XCTAssertNotEqual(firstPosterData, secondPosterData)
        XCTAssertEqual(indexLabel.label, "2/10")
    }
    
    func testGameFinish() {
        // Given
        _ = app.wait(for: .notRunning, timeout: 2)
        for _ in 1...10 {
            let buttonName = Bool.random() ? "Yes" : "No"
            
            // When
            app.buttons[buttonName].tap()
            _ = app.wait(for: .notRunning, timeout: 3)
        }

        // Then
        let alert = app.alerts.firstMatch
        _ = alert.waitForExistence(timeout: 3)
        
        XCTAssertTrue(alert.exists)
        XCTAssertTrue(alert.label == "Этот раунд окончен!")
        XCTAssertTrue(alert.buttons.firstMatch.label == "Сыграть ещё раз")
    }

    func testAlertDismiss() {
        // Given
        _ = app.wait(for: .notRunning, timeout: 2)
        for _ in 1...10 {
            let buttonName = Bool.random() ? "Yes" : "No"
            
            // When
            app.buttons[buttonName].tap()
            _ = app.wait(for: .notRunning, timeout: 3)
        }
        
        // Then
        let alert = app.alerts.firstMatch
        _ = alert.waitForExistence(timeout: 5)
        alert.buttons.firstMatch.tap()
        
        _ = app.wait(for: .notRunning, timeout: 2)
        
        let indexLabel = app.staticTexts["Index"]
        
        XCTAssertFalse(alert.exists)
        XCTAssertTrue(indexLabel.label == "1/10")
    }
}
