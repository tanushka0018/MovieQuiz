import UIKit

final class MovieQuizViewController: UIViewController, QuestionFactoryDelegate {
    // MARK: - IBOutlets
    
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var textLabel: UILabel!
    @IBOutlet private weak var counterLabel: UILabel!
    @IBOutlet private weak var yesButton: UIButton!
    @IBOutlet private weak var noButton: UIButton!
    
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
        setupUI()
        setupQuestionFactory()
        requestFirstQuestion()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        setupImageView()
    }
    
    private func setupImageView() {
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = 20
    }
    
    private func setupQuestionFactory() {
        let factory = QuestionFactory()
        factory.setup(delegate: self)
        questionFactory = factory
    }
    
    private func requestFirstQuestion() {
        questionFactory?.requestNextQuestion()
    }
    
    // MARK: - QuestionFactoryDelegate
    
    func didReceiveNextQuestion(question: QuizQuestion?) {
        guard let question = question else { return }
        
        currentQuestion = question
        let viewModel = makeStepViewModel(from: question)
        
        DispatchQueue.main.async { [weak self] in
            self?.show(quiz: viewModel)
        }
    }
    
    // MARK: - Quiz presentation
    
    private func makeStepViewModel(from question: QuizQuestion) -> QuizStepViewModel {
        QuizStepViewModel(
            image: UIImage(named: question.image) ?? UIImage(),
            question: question.text,
            questionNumber: "\(currentQuestionIndex + 1)/\(questionsAmount)"
        )
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
    
    private func resetGame() {
        currentQuestionIndex = 0
        correctAnswers = 0
    }
    
    private func setAnswerButtonsEnabled(_ isEnabled: Bool) {
        yesButton.isEnabled = isEnabled
        noButton.isEnabled = isEnabled
    }
    
    private func updateScoreIfNeeded(_ isCorrect: Bool) {
        if isCorrect {
            correctAnswers += 1
        }
    }
    
    private func highlightAnswer(_ isCorrect: Bool) {
        imageView.layer.borderWidth = 8
        imageView.layer.borderColor = isCorrect
            ? UIColor.ypGreen.cgColor
            : UIColor.ypRed.cgColor
    }
    
    // MARK: - IBActions
    
    @IBAction private func yesButtonClicked(_ sender: UIButton) {
        handleAnswer(true)
    }
    
    @IBAction private func noButtonClicked(_ sender: UIButton) {
        handleAnswer(false)
    }
    
    private func handleAnswer(_ answer: Bool) {
        guard let question = currentQuestion else { return }
        showAnswerResult(isCorrect: answer == question.correctAnswer)
    }
}
