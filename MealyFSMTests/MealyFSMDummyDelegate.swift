//
// MealyFSMDummyDelegate.swift
//
// MIT License
//
// Copyright (c) 2016 Matías Mazzei
//

import Foundation
@testable import MealyFSM

/// A dummy FSMDelegate that stores the lastOutput
class FSMDummyDelegate<Output>: FSMDelegate {
  var lastOutput: Output? = nil

  func stateWillChange(from sourceId: String, to targetId: String, with output: Output?) {
    lastOutput = output
  }
}
