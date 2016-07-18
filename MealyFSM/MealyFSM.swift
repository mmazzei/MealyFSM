//
// MealyFSM.swift
//
// MIT License
//
// Copyright (c) 2016 Matías Mazzei
//

import Foundation


// MARK: - Helper structures

private struct State<StateDataType> {
  var id: String
  var data: StateDataType?
}

private struct Transition<InputDataType, OutputDataType, StateDataType> {
  let sourceId: String
  let targetId: String

  /// Evaluates if this transition can be applied given the current state and input
  let condition: (data: StateDataType?, input: InputDataType?) -> Bool

  /// Applies the transition from the source state, whose data is `data`, using the
  /// last input to get to a new state.
  ///
  /// Returns:
  /// - newData: the data to initialize the new state
  /// - output: the transition output, if any
  let map: (data: StateDataType?, input: InputDataType?) -> (newData: StateDataType?, output: OutputDataType?)
}



public protocol FSMDelegate: class {
  // It's weird the output type is defined in the delegate
  // but I didn't found a better way to constraint the type for
  // stateWillChange output param.
  // Because protocols don't allow generic parameters...
  associatedtype OutputDataType

  /// Notifies the delegate a transition is going to be executed
  /// from one state to another, with the given output.
  func stateWillChange(from sourceId: String, to targetId: String, with output: OutputDataType?)
}

/// In terms of: https://en.wikipedia.org/wiki/Mealy_machine
///
/// A Mealy machine is a 6-tuple (S, S0, Σ, Λ, T, G) consisting of the following:
///
/// - a finite set of states S
///    - ➡️ `FSM.states`
///
/// - a start state (also called initial state) S0 which is an element of S
///    - ➡️ `FSM.start`
///
/// - a finite set called the input alphabet Σ
///    - ➡️ `FSM` `InputDataType` constraint
///
/// - a finite set called the output alphabet Λ
///    - ➡️ `FSMDelegate.OutputDataType` constraint
///
/// - a transition function T: SxΣ -> S mapping pairs of a state and an input symbol to the corresponding next state.
///    - ➡️ Transition
///      - The condition closure evaluates if it can be applied given the current state and input
///      - The map closure applies the transition over the current state an input, it returns the new state data
///
/// - an output function G: SxΣ -> Λ mapping pairs of a state and an input symbol to the corresponding output symbol.
///    - ➡️ `FSMDelegate.stateWillChange(from: S, to: S, with: Λ)`
///
/// In some formulations, the transition and output functions are coalesced into a single function T: SxΣ => SxΛ
///    - ➡️ This is true here
///
/// Type parameters:
/// - InputDataType: the type of data received as input
/// - StateDataType: the type of the states associated data
/// - Delegate: the type of delegate to use
public struct FSM<InputDataType, StateDataType, Delegate: FSMDelegate> {
  private typealias OutputDataType = Delegate.OutputDataType
  private typealias FSMState = State<StateDataType>
  private typealias FSMTransition = Transition<InputDataType, OutputDataType, StateDataType>

  // Just the ID of each included state
  private var states: Set<String> = []

  // Indexed by state ID
  private var transitions: [String:[FSMTransition]] = [:]

  // The current state including associated data
  private var currentState: FSMState? = nil

  public weak var delegate: Delegate?

  public var isRunning: Bool {
    return currentState != nil
  }
  public var currentStateId: String? {
    return currentState?.id
  }

  // MARK: - Config machine structure

  public init() {}

  /// Adds a new state to the FSM, with the unique identifier.
  ///
  /// If the machine is already running, will fail.
  public mutating func addState(id: String) {
    assert(!self.states.contains(id))
    assert(!isRunning)

    states.insert(id)
    transitions[id] = []
  }

  /// Adds a new transition between two states to the FSM.
  ///
  /// Params:
  /// - sourceId: The unique identifier of the state where the transition starts.
  /// - condition: A function to determine if the transition is valid in the current state. Params:
  ///   - data: The current state associated data
  ///   - input: The input being processed
  /// - map: A function that, applied given the current conditions, returns the new state this machine will be. Params:
  ///   - data: The current state associated data
  ///   - input: The input being processed
  ///
  /// Map function returns:
  ///   - the associated data for the new state
  ///   - the output of the FSM
  ///
  /// Usage example:
  /// ```
  /// fsm.addTransition(
  ///     from: "Insert Coins Screen",
  ///     to: "Start Game Menu",
  ///     condition: { (currentMoney, newMoney) in
  ///        // you need to insert $1 to start
  ///        return currentMoney + newMoney > 1.0
  ///     },
  ///     map: { (currentMoney, newMoney) in
  ///        // pass the remainder money to next state
  ///        let dataForNextState = currentMoney - 1.0
  ///        let fsmOutput = ... // anything you want to tell the fsm delegate
  ///        return (dataForNextState, fsmOutput)
  ///     })
  /// ```
  ///
  /// **Important:** at most one transition condition should be true at any
  ///                moment. So, if any state have more than one transitions,
  ///                check no one could apply with the same condition as other.
  ///
  /// If the machine is already running, will fail.
  public mutating func addTransition(from sourceId: String, to targetId: String, condition: (data: StateDataType?, input: InputDataType?) -> Bool, map: (data: StateDataType?, input: InputDataType?) -> (StateDataType?, OutputDataType?)) {
    assert(self.states.contains(sourceId))
    assert(!isRunning)

    transitions[sourceId]?.append(Transition(sourceId: sourceId, targetId: targetId,  condition: condition, map: map))
  }

  // MARK: - Machine runtime

  /// Sets the FSM current state and its initialData.
  ///
  /// If the machine is already running, will discard current data, this is
  /// always a "fresh" start.
  public mutating func start(from initialStateId: String, with initialData: StateDataType? = nil) {
    assert(self.states.contains(initialStateId))
    currentState = State(id: initialStateId, data: nil)

    if let initialData = initialData {
      currentState!.data = initialData
    }
  }

  /// Process the next available input.
  ///
  /// The result is one of:
  /// - The FSM remains in the same state, with the associated data updated.
  /// - The FSM changes to the new state, determined by the executed transition.
  ///
  /// If the machine is not running, will fail
  public mutating func input(data inputData: InputDataType) {
    assert(isRunning)

    if let transition = validTransition(on: inputData) {
      let (nextStateData, outputData) = transition.map(data: currentState!.data, input: inputData)

      delegate?.stateWillChange(from: currentState!.id, to: transition.targetId, with: outputData)
      currentState = FSMState(id: transition.targetId, data: nextStateData)
    }
  }

  /// Just prints some debug info about the machine:
  ///  - states
  ///  - transitions for each state
  ///  - current state, tagged as [💠]
  public func printStructure() {
    print("FSM structure:")
    states.sort().forEach {
      if currentState?.id == $0 {
        print("    \($0) [💠]")
      }
      else {
        print("    \($0)")
      }
      transitions[$0]?.forEach {
        print("        => \($0.targetId)")
      }
    }
    print("====")
  }

  // MARK: - Private

  /// Returns the unique valid transition, given the current state and input
  private func validTransition(on inputData: InputDataType) -> FSMTransition? {
    guard let transitions = transitions[currentState!.id] else { return nil }

    let matchingTransitions = transitions.filter { $0.condition(data: currentState!.data, input: inputData) }

    // Is a requirement to have at most one transition for each (state, input)
    assert(matchingTransitions.count <= 1,
           "The following transitions are competing for apply because their coditions match: \(matchingTransitions)")
    
    return matchingTransitions.first
  }
  
}
