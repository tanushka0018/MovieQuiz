//
//  MovieQuizViewControllerMock.swift
//  MovieQuiz
//
//  Created by Tatiana on 1/5/26.
//

import Foundation
@testable import MovieQuiz

final class MovieQuizViewControllerMock: MovieQuizViewControllerProtocol {
    
    func show(quiz step: QuizStepViewModel) { }
    
    func show(quiz result: QuizResultsViewModel) { }
    
    func highlightImageBorder(isCorrectAnswer: Bool) { }
    
    func showLoadingIndicator() { }
    
    func hideLoadingIndicator() { }
    
    func showNetworkError(message: String) { }
}
