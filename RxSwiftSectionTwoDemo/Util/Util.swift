//
//  Util.swift
//  RxSwiftSectionTwoDemo
//
//  Created by Hiroki Minami on 2023-02-10.
//

import Foundation

struct Util {
  static private let badword = "bad"
  
  static func checkBadWords(_ post: Post) -> Bool {
    return !post.text.contains(badword)
  }
}
