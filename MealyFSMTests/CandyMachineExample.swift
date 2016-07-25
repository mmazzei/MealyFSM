//
// CandyMachineExample.swift
//
// MIT License
//
// Copyright (c) 2016 Matías Mazzei
//

import XCTest
@testable import MealyFSM

/// Based on the examples from:
/// - http://www.jflap.org/tutorial/mealy/mealyExamples.html
struct CandyMachine {
  typealias DelegateType = FSMDummyDelegate<CandyMachine.Candy>

  enum Coin: String {
    case nickel, dime, quarter
  }
  enum Candy: String {
    case candy0, candy1, candy2, candy3, candy4
  }
  enum States: String {
    case ZeroCents, FiveCents, TenCents, FifteenCents
  }

  // Creates the fsm structure
  private static func initialize() -> FSM<Coin, Any, DelegateType>{
    var fsm = FSM<Coin, Any, DelegateType>()
    fsm.addState(States.ZeroCents.rawValue)
    fsm.addState(States.FiveCents.rawValue)
    fsm.addState(States.TenCents.rawValue)
    fsm.addState(States.FifteenCents.rawValue)

    fsm.addTransition(
      from: States.ZeroCents.rawValue,
      to: States.ZeroCents.rawValue,
      condition: { $1 == .quarter },
      map: { _ in (nil, .candy1) })

    fsm.addTransition(
      from: States.ZeroCents.rawValue,
      to: States.FiveCents.rawValue,
      condition: { $1 == .nickel },
      map: { _ in (nil, nil) })

    fsm.addTransition(
      from: States.ZeroCents.rawValue,
      to: States.TenCents.rawValue,
      condition: { $1 == .dime },
      map: { _ in (nil, nil) })

    fsm.addTransition(
      from: States.FiveCents.rawValue,
      to: States.ZeroCents.rawValue,
      condition: { $1 == .quarter },
      map: { _ in (nil, .candy2) })

    fsm.addTransition(
      from: States.FiveCents.rawValue,
      to: States.TenCents.rawValue,
      condition: { $1 == .nickel },
      map: { _ in (nil, nil) })

    fsm.addTransition(
      from: States.FiveCents.rawValue,
      to: States.FifteenCents.rawValue,
      condition: { $1 == .dime },
      map: { _ in (nil, nil) })

    // This could be modeled as two transitions also
    fsm.addTransition(
      from: States.TenCents.rawValue,
      to: States.ZeroCents.rawValue,
      condition: { $1 == .dime || $1 == .quarter },
      map: {
        switch $1 {
        case .dime?: return (nil, .candy0)
        case .quarter?: return (nil, .candy3)
        default: assertionFailure(); return (nil, nil)
        }
    })

    fsm.addTransition(
      from: States.TenCents.rawValue,
      to: States.FifteenCents.rawValue,
      condition: { $1 == .nickel },
      map: { _ in (nil, nil) })

    // This could be modeled as three transitions also
    fsm.addTransition(
      from: States.FifteenCents.rawValue,
      to: States.ZeroCents.rawValue,
      condition: {
        switch $1 {
        case .nickel?: return true
        case .dime?: return true
        case .quarter?: return true
        default: return false
        }
      },
      map: {
        switch $1 {
        case .nickel?: return (nil, .candy0)
        case .dime?: return (nil, .candy1)
        case .quarter?: return (nil, .candy4)
        default: assertionFailure(); return (nil, nil)
        }
    })

    return fsm
  }
}

class CandyMachineExample: XCTestCase {
  private var fsm: FSM<CandyMachine.Coin, Any, CandyMachine.DelegateType> = CandyMachine.initialize()
  private var delegate = CandyMachine.DelegateType()

  override func setUp() {
    super.setUp()
    fsm.delegate = delegate
    fsm.start(from: CandyMachine.States.ZeroCents.rawValue)
    delegate.lastOutput = nil
  }

  func testFirstCase() {
    fsm.input(data: .nickel)
    fsm.input(data: .dime)
    fsm.input(data: .quarter)
    XCTAssertEqual(delegate.lastOutput, .candy4)
  }

  func testSecondCase() {
    fsm.input(data: .quarter)
    XCTAssertEqual(delegate.lastOutput, .candy1)
    delegate.lastOutput = nil

    fsm.input(data: .quarter)
    XCTAssertEqual(delegate.lastOutput, .candy1)
    delegate.lastOutput = nil

    fsm.input(data: .quarter)
    XCTAssertEqual(delegate.lastOutput, .candy1)
  }

  func testThirdCase() {
    fsm.input(data: .nickel)
    fsm.input(data: .quarter)
    XCTAssertEqual(delegate.lastOutput, .candy2)
  }

  func testFourthCase() {
    fsm.input(data: .dime)
    fsm.input(data: .quarter)
    XCTAssertEqual(delegate.lastOutput, .candy3)
  }

  func testFifthCase() {
    fsm.input(data: .dime)
    fsm.input(data: .dime)
    XCTAssertEqual(delegate.lastOutput, .candy0)
  }

  func testSixthCase() {
    fsm.input(data: .dime)
    fsm.input(data: .dime)
    XCTAssertEqual(delegate.lastOutput, .candy0)
    fsm.input(data: .nickel)
    XCTAssertEqual(delegate.lastOutput, nil)
    XCTAssertEqual(fsm.currentStateId, CandyMachine.States.FiveCents.rawValue)
  }
}