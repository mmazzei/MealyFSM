//
// SignalProcessingMachineExample.swift
//
// MIT License
//
// Copyright (c) 2016 Matías Mazzei
//


import XCTest
@testable import MealyFSM

/// Based on the example from:
/// - http://www.tutorialspoint.com/automata_theory/moore_and_mealy_machines.htm
struct SignalProcessingMachine {
  typealias DelegateType = FSMDummyDelegate<Int>


  // Creates the fsm structure
  private static func initialize() -> FSM<Int, Any, DelegateType>{
    var fsm = FSM<Int, Any, DelegateType>()
    fsm.addState("a")
    fsm.addState("b")
    fsm.addState("c")
    fsm.addState("d")

    // FROM A
    fsm.addTransition(
      from: "a", to: "d",
      condition: { (_, input) -> Bool in input == 0 },
      map: { (_, input) in (nil, 1)})

    fsm.addTransition(
      from: "a", to: "b",
      condition: { (_, input) -> Bool in input == 1 },
      map: { (_, input) in (nil, 0)})


    // FROM B
    fsm.addTransition(
      from: "b", to: "a",
      condition: { (_, input) -> Bool in input == 0 },
      map: { (_, input) in (nil, 1)})

    fsm.addTransition(
      from: "b", to: "d",
      condition: { (_, input) -> Bool in input == 1 },
      map: { (_, input) in (nil, 1)})

    // FROM C
    fsm.addTransition(
      from: "c", to: "c",
      condition: { (_, input) -> Bool in input == 0 },
      map: { (_, input) in (nil, 0)})

    fsm.addTransition(
      from: "c", to: "c",
      condition: { (_, input) -> Bool in input == 1 },
      map: { (_, input) in (nil, 0)})

    // FROM D
    fsm.addTransition(
      from: "d", to: "b",
      condition: { (_, input) -> Bool in input == 0 },
      map: { (_, input) in (nil, 0)})

    fsm.addTransition(
      from: "d", to: "a",
      condition: { (_, input) -> Bool in input == 1 },
      map: { (_, input) in (nil, 1)})

    return fsm
  }
}

class SignalProcessingMachineExample: XCTestCase {
  private var fsm: FSM<Int, Any, SignalProcessingMachine.DelegateType> = SignalProcessingMachine.initialize()
  private var delegate = SignalProcessingMachine.DelegateType()

  override func setUp() {
    super.setUp()
    fsm.delegate = delegate
    fsm.start(from: "a")
    delegate.lastOutput = nil
  }

  func testSingleRunCase() {
    fsm.input(data: 0)
    XCTAssertEqual(delegate.lastOutput, 1)
    XCTAssertEqual(fsm.currentStateId, "d")

    fsm.input(data: 1)
    XCTAssertEqual(delegate.lastOutput, 1)
    XCTAssertEqual(fsm.currentStateId, "a")

    fsm.input(data: 0)
    XCTAssertEqual(delegate.lastOutput, 1)
    XCTAssertEqual(fsm.currentStateId, "d")

    fsm.input(data: 0)
    XCTAssertEqual(delegate.lastOutput, 0)
    XCTAssertEqual(fsm.currentStateId, "b")

    fsm.input(data: 0)
    XCTAssertEqual(delegate.lastOutput, 1)
    XCTAssertEqual(fsm.currentStateId, "a")
  }

  func testLongRunLoopingBetweenTwoStates() {
    // So, now I'm in "a".
    //  "a" + 0 -> "d" + 1
    //  "d" + 1 -> "a" + 1
    // Will check if that is valid despite how many times is repeated
    for i in 0..<100 {
      fsm.input(data: i % 2)
      XCTAssertEqual(delegate.lastOutput, 1)
      XCTAssertEqual(fsm.currentStateId, (i % 2) == 0 ? "d" : "a")
    }
  }
}