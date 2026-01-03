//
//  MoviesLoader.swift
//  MovieQuiz
//
//  Created by Tatiana on 1/2/26.
//

import Foundation

protocol MoviesLoading {
    func loadMovies(handler: @escaping (Result<MostPopularMovies, Error>) -> Void)
}

struct MoviesLoader: MoviesLoading {
    // MARK: - NetworkClient
    private let networkClient = NetworkClient()
    private let jsonDecoder = JSONDecoder()
    
    // MARK: - URL
    private var mostPopularMoviesUrl: URL {
        guard let url = URL(string: "https://tv-api.com/en/API/Top250Movies/k_zcuw1ytf") else {
            preconditionFailure("Unable to construct mostPopularMoviesUrl")
        }
        return url
    }
    
    // MARK: - MoviesLoading
    
    func loadMovies(handler: @escaping (Result<MostPopularMovies, Error>) -> Void) {
        networkClient.fetch(url: mostPopularMoviesUrl) { result in
            switch result {
            case .success(let data):
                do {
                    let mostPopularMovies = try self.jsonDecoder.decode(MostPopularMovies.self, from: data)
                    
                    // Check for error message in response
                    if !mostPopularMovies.errorMessage.isEmpty {
                        let error = NSError(
                            domain: "MoviesLoader",
                            code: -1,
                            userInfo: [NSLocalizedDescriptionKey: mostPopularMovies.errorMessage]
                        )
                        handler(.failure(error))
                        return
                    }
                    
                    handler(.success(mostPopularMovies))
                } catch {
                    handler(.failure(error))
                }
            case .failure(let error):
                handler(.failure(error))
            }
        }
    }
}
