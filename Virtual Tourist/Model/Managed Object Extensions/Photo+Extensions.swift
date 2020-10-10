//
//  Photo+Extensions.swift
//  Virtual Tourist
//
//  Created by Diego on 10/10/2020.
//


import Foundation
import CoreData

extension Photo {
  public override func awakeFromInsert() {
    super.awakeFromInsert()
    createDate = Date()
  }
}
