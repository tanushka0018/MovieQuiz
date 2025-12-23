//
//  QuestionFactoryDelegate.swift
//  MovieQuiz
//
//  Created by Tatiana on 12/15/25.
//

protocol QuestionFactoryDelegate: AnyObject {
    func didReceiveNextQuestion(question: QuizQuestion?)  
}
