//
//  Model.swift
//  RxSwiftSectionTwoDemo
//
//  Created by Hiroki Minami on 2023-02-09.
//

import Foundation

class Post: Hashable {
  var id: UUID
  var text: String
  var poster: Poster
  var date: Date
  
  init(text: String, poster: Poster) {
    self.id = UUID()
    self.text = text
    self.poster = poster
    self.date = Date()
  }
  
  var identifier: String {
    return id.uuidString
  }
  
  public func hash(into hasher: inout Hasher) {
    return hasher.combine(identifier)
  }
  
  static func == (lhs: Post, rhs: Post) -> Bool {
    lhs.text == rhs.text
  }
}

class Poster: Hashable, Identifiable {
  var id: UUID
  var name: String
  
  static let limitNumberOfBadWords = 5
  static let loginUser = Poster(name: "You")
  static var badWordsCount: [Poster: Int] = [:]
  
  init(name: String) {
    self.id = UUID()
    self.name = name
  }
  
  var identifier: String {
    return id.uuidString
  }
  
  public func hash(into hasher: inout Hasher) {
    return hasher.combine(identifier)
  }
  
  static func == (lhs: Poster, rhs: Poster) -> Bool {
    lhs.id == rhs.id
  }
  
  static func makeFiveRandomPosters() -> [Poster] {
    return [
      Poster(name: "user1"),
      Poster(name: "user2"),
      Poster(name: "user3"),
      Poster(name: "user4"),
      Poster(name: "user5"),
    ]
  }
  
  public func validation() -> Bool {
    guard let count = Poster.badWordsCount[self] else { return true }
    return count < Poster.limitNumberOfBadWords
  }
}
