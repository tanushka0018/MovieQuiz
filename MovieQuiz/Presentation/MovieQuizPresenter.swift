//
//  MovieQuizPresenter.swift
//  MovieQuiz
//
//  Created by Tatiana on 1/3/26.
//

import UIKit

final class MovieQuizPresenter {
    // MARK: - Properties
    
    let questionsAmount: Int = 10
    private var currentQuestionIndex: Int = 0
    var correctAnswers = 0
    
    var currentQuestion: QuizQuestion?
    weak var viewController: MovieQuizViewController?
    var questionFactory: QuestionFactoryProtocol?
    let statisticService: StatisticServiceProtocol
    
    private var isAnswerInProgress = false
    
    // MARK: - Initialization
    
    init(statisticService: StatisticServiceProtocol = StatisticService()) {
        self.statisticService = statisticService
    }
    
    // MARK: - Question Management
    
    func isLastQuestion() -> Bool {
        currentQuestionIndex == questionsAmount - 1
    }
    
    func resetQuestionIndex() {
        currentQuestionIndex = 0
    }
    
    func resetGame() {
        resetQuestionIndex()
        correctAnswers = 0
    }
    
    func switchToNextQuestion() {
        currentQuestionIndex += 1
    }
    
    func convert(model: QuizQuestion) -> QuizStepViewModel {
        QuizStepViewModel(
            image: UIImage(data: model.imageData) ?? UIImage(),
            question: model.text,
            questionNumber: "\(currentQuestionIndex + 1)/\(questionsAmount)")
    }
    
    // MARK: - Answer Handling
    
    func yesButtonClicked() {
        didAnswer(isYes: true)
    }
    
    func noButtonClicked() {
        didAnswer(isYes: false)
    }
    
    private func didAnswer(isYes: Bool) {
        guard let currentQuestion = currentQuestion else {
            return
        }
        
        guard !isAnswerInProgress else { return }
        isAnswerInProgress = true
        
        let isCorrect = isYes == currentQuestion.correctAnswer
        
        viewController?.setAnswerButtonsEnabled(false)
        
        if isCorrect {
            correctAnswers += 1
        }
        
        viewController?.highlightAnswer(isCorrect)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            self.isAnswerInProgress = false
            self.showNextQuestionOrResults()
        }
    }
    
    // MARK: - Game Flow
    
    func showNextQuestionOrResults() {
        if isLastQuestion() {
            let resultText = makeResultsMessage()
            let viewModel = QuizResultsViewModel(
                title: "Этот раунд окончен!",
                text: resultText,
                buttonText: "Сыграть ещё раз"
            )
            
            viewController?.show(quiz: viewModel)
        } else {
            switchToNextQuestion()
            questionFactory?.requestNextQuestion()
        }
    }
    
    // MARK: - Results
    
    func makeResultsMessage() -> String {
        statisticService.store(correct: correctAnswers, total: questionsAmount)
        
        let currentResult = "Ваш результат: \(correctAnswers)/\(questionsAmount)"
        let gamesCount = "Количество сыгранных квизов: \(statisticService.gamesCount)"
        
        let bestGame = statisticService.bestGame
        let bestGameText: String
        if bestGame.correct > 0 {
            bestGameText = "Рекорд: \(bestGame.correct)/\(bestGame.total) (\(bestGame.date.dateTimeString))"
        } else {
            bestGameText = "Нет истории"
        }
        
        let accuracy = String(format: "%.2f", statisticService.totalAccuracy)
        let accuracyText = "Средняя точность: \(accuracy)%"
        
        return [currentResult, gamesCount, bestGameText, accuracyText]
            .joined(separator: "\n")
    }
    
    // MARK: - QuestionFactoryDelegate
    
    func didReceiveNextQuestion(question: QuizQuestion?) {
        guard let question = question else { return }
        
        currentQuestion = question
        let viewModel = convert(model: question)
        
        DispatchQueue.main.async { [weak self] in
            self?.viewController?.show(quiz: viewModel)
        }
    }
}
