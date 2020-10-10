//
//  Pin+Extensions.swift
//  Virtual Tourist
//
//  Created by Diego on 10/10/2020.
//

import Foundation
import CoreData

extension Pin {
  public override func awakeFromInsert() {
    super.awakeFromInsert()
    createDate = Date()
  }
}
