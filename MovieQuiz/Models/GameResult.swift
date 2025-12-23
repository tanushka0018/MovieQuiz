//
//  GameResult.swift
//  MovieQuiz
//
//  Created by Tatiana on 12/22/25.
//

import Foundation

struct GameResult {
    let correct: Int
    let total: Int
    let date: Date
    
    func isBetterThan(_ another: GameResult) -> Bool {
        correct > another.correct
    }
}
