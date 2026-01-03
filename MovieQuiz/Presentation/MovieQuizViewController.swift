import UIKit

final class MovieQuizViewController: UIViewController, QuestionFactoryDelegate {
    // MARK: - IBOutlets
    
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var textLabel: UILabel!
    @IBOutlet private weak var counterLabel: UILabel!
    @IBOutlet private weak var yesButton: UIButton!
    @IBOutlet private weak var noButton: UIButton!
    @IBOutlet private var activityIndicator: UIActivityIndicatorView!
    
    // MARK: - Private properties
    
    private var currentQuestionIndex = 0
    private var correctAnswers = 0
    private let questionsAmount = 10
    
    private var currentQuestion: QuizQuestion?
    private var isAnswerInProgress = false
    
    private var questionFactory: QuestionFactoryProtocol?
    private let alertPresenter = AlertPresenter()
    private let statisticService: StatisticServiceProtocol = StatisticService()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = 20
        questionFactory = QuestionFactory(moviesLoader: MoviesLoader(), delegate: self)

        showLoadingIndicator()
        questionFactory?.loadData()
    }
    
    // MARK: - QuestionFactoryDelegate
    
    func didReceiveNextQuestion(question: QuizQuestion?) {
        guard let question = question else { return }
        
        currentQuestion = question
        let viewModel = convert(model: question)
        
        DispatchQueue.main.async { [weak self] in
            self?.show(quiz: viewModel)
        }
    }
    
    func didLoadDataFromServer() {
        hideLoadingIndicator()
        questionFactory?.requestNextQuestion()
    }
    
    func didFailToLoadData(with error: Error) {
        DispatchQueue.main.async { [weak self] in
            self?.showNetworkError(message: error.localizedDescription)
        }
    }
    
    // MARK: - Quiz presentation
    
    private func convert(model: QuizQuestion) -> QuizStepViewModel {
        return QuizStepViewModel(
            image: UIImage(data: model.image) ?? UIImage(),
            question: model.text,
            questionNumber: "\(currentQuestionIndex + 1)/\(questionsAmount)")
    }
    
    private func show(quiz step: QuizStepViewModel) {
        imageView.image = step.image
        textLabel.text = step.question
        counterLabel.text = step.questionNumber
        imageView.layer.borderWidth = 0
        setAnswerButtonsEnabled(true)
    }
    
    private func show(quiz result: QuizResultsViewModel) {
        let alertModel = AlertModel(
            title: result.title,
            message: result.text,
            buttonText: result.buttonText
        ) { [weak self] in
            guard let self = self else { return }
            self.resetGame()
            self.requestFirstQuestion()
        }
        
        alertPresenter.show(in: self, model: alertModel)
    }
    
    // MARK: - Answer handling
    
    // MARK: Answer processing
    
    private func showAnswerResult(isCorrect: Bool) {
        guard !isAnswerInProgress else { return }
        isAnswerInProgress = true
        
        setAnswerButtonsEnabled(false)
        updateScoreIfNeeded(isCorrect)
        highlightAnswer(isCorrect)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            self.isAnswerInProgress = false
            self.showNextQuestionOrResults()
        }
    }
    
    private func highlightAnswer(_ isCorrect: Bool) {
        imageView.layer.borderWidth = 8
        imageView.layer.borderColor = isCorrect
            ? UIColor.ypGreen.cgColor
            : UIColor.ypRed.cgColor
    }
    
    private func updateScoreIfNeeded(_ isCorrect: Bool) {
        if isCorrect {
            correctAnswers += 1
        }
    }
    
    private func setAnswerButtonsEnabled(_ isEnabled: Bool) {
        yesButton.isEnabled = isEnabled
        noButton.isEnabled = isEnabled
    }
    
    // MARK: Game flow
    
    private func showNextQuestionOrResults() {
        if currentQuestionIndex == questionsAmount - 1 {
            finishRound()
        } else {
            currentQuestionIndex += 1
            requestFirstQuestion()
        }
    }
    
    private func finishRound() {
        statisticService.store(correct: correctAnswers, total: questionsAmount)
        
        let resultText = makeResultText()
        let viewModel = QuizResultsViewModel(
            title: "Этот раунд окончен!",
            text: resultText,
            buttonText: "Сыграть ещё раз"
        )
        
        show(quiz: viewModel)
    }
    
    // MARK: Result
    
    private func makeResultText() -> String {
        let currentResult = "Ваш результат: \(correctAnswers)/\(questionsAmount)"
        let gamesCount = "Количество сыгранных квизов: \(statisticService.gamesCount)"
        
        let bestGame = statisticService.bestGame
        let bestGameText =
            "Рекорд: \(bestGame.correct)/\(bestGame.total) (\(bestGame.date.dateTimeString))"
        
        let accuracy =
            "Средняя точность: \(String(format: "%.2f", statisticService.totalAccuracy))%"
        
        return [currentResult, gamesCount, bestGameText, accuracy]
            .joined(separator: "\n")
    }
    
    // MARK: Reset
    
    private func resetGame() {
        currentQuestionIndex = 0
        correctAnswers = 0
    }
    
    // MARK: - IBActions
    
    @IBAction private func yesButtonClicked(_ sender: UIButton) {
        handleAnswer(true)
    }
    
    @IBAction private func noButtonClicked(_ sender: UIButton) {
        handleAnswer(false)
    }
    
    // MARK: LoadingIndicator
    
    private func showLoadingIndicator() {
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
    }
    
    private func hideLoadingIndicator() {
        activityIndicator.isHidden = true
        activityIndicator.stopAnimating()
    }
    
    // MARK: Question flow
    
    private func handleAnswer(_ answer: Bool) {
        guard let question = currentQuestion else { return }
        showAnswerResult(isCorrect: answer == question.correctAnswer)
    }
    
    private func requestFirstQuestion() {
        questionFactory?.requestNextQuestion()
    }
    
    // MARK: Error handling
    
    private func showNetworkError(message: String) {
        hideLoadingIndicator()
        
        let model = AlertModel(title: "Ошибка",
                               message: message,
                               buttonText: "Попробовать еще раз") { [weak self] in
            guard let self = self else { return }
            
            self.currentQuestionIndex = 0
            self.correctAnswers = 0
            
            self.showLoadingIndicator()
            self.questionFactory?.loadData()
        }
        
        alertPresenter.show(in: self, model: model)
    }
}
