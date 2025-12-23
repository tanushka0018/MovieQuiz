//
//  StatisticServiceProtocol.swift
//  MovieQuiz
//
//  Created by Tatiana on 12/22/25.
//

protocol StatisticServiceProtocol {
    var gamesCount: Int { get }
    var bestGame: GameResult { get }
    var totalAccuracy: Double { get }
    
    func store(correct count: Int, total amount: Int)
}
