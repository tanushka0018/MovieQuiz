//
//  AlertModel.swift
//  MovieQuiz
//
//  Created by Tatiana on 12/15/25.
//

import Foundation

struct AlertModel {
    let title: String
    let message: String
    let buttonText: String
    let completion: () -> Void
}

