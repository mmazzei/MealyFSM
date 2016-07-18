# MealyFSM

Small and simple Mealy Finite State Machine implementation written in Swift.

# Theory

In terms of: https://en.wikipedia.org/wiki/Mealy_machine

A Mealy machine is a 6-tuple (S, S0, Σ, Λ, T, G) consisting of the following:

- a finite set of states S
  - ➡️ `FSM.states`
- a start state (also called initial state) S0 which is an element of S
  - ➡️ `FSM.start`
- a finite set called the input alphabet Σ
  - ➡️ `FSM` `InputDataType` constraint
- a finite set called the output alphabet Λ
  - ➡️ `FSMDelegate.OutputDataType` constraint
- a transition function T: SxΣ -> S mapping pairs of a state and an input symbol to the corresponding next state.
  - ➡️ Transition
    - The condition closure evaluates if it can be applied given the current state and input
    - The map closure applies the transition over the current state an input, it returns the new state data
- an output function G: SxΣ -> Λ mapping pairs of a state and an input symbol to the corresponding output symbol.
  - ➡️ `FSMDelegate.stateWillChange(from: S, to: S, with: Λ)`

In some formulations, the transition and output functions are coalesced into a single function T: SxΣ => SxΛ
  - ➡️ This is true here

# Features

 - There is only a single file
 - Implemented as a value type
 - Uses the Delegate pattern to send output
 - Uses Generics for input, output and associated data
 - Very simple public interface:
   - addState(id:)
   - addTransition(from:to:condition:map:)
   - start(from:)
   - input(data:)

# Notes

In this implementation, each state can have associated data, of the type defined as the `StateDataType` generic param in `FSM`.

A change in the associated data of the current state is also considered a state change, despite the initial and final states have both the same id.

# Installation

## Simple way

Just drag and drop the MealyFSM.swift file to your project.

## Nice way

1. Drag `MealyFSM.xcodeproj` to your project in the _Project Navigator_.
2. Select your project and then your app target. Open the _Build Phases_ panel.
3. Expand the _Target Dependencies_ group, and add `MealyFSM`.
4. Click on the `+` button at the top left of the panel and select _New Copy Files Phase_. Set _Destination_ to _Frameworks_, and add `MealyFSM.framework`.
5. `import MealyFSM` whenever you want to use MealyFSM.

# Usage example

This example is based on the Candy Machine from http://www.jflap.org/tutorial/mealy/mealyExamples.html.

Suppose there are defined some constants for the state names, a Candy enum and a Coin enum somewhere.

The first step is to define the fsm states:

```
var fsm = FSM<Coin, DelegateType>()
fsm.addState(ZeroCents)
fsm.addState(FiveCents)
fsm.addState(TenCents)
fsm.addState(FifteenCents)
```

Then, we can add each supported transition for this prices list:

1. Candy 0: `$0.20`
2. Candy 1: `$0.25`
3. Candy 2: `$0.30`
4. Candy 3: `$0.35`
5. Candy 4: `$0.40`


If the machine has `$0` and you insert a `quarter`, then will give you a Candy 1, and the new state is `$0` again.

```
fsm.addTransition(
  from: ZeroCents,
  to: ZeroCents,
  condition: { $1 == .quarter },
  map: { _ in (nil, .candy1) })
```


If the machine has `$0` and you insert a `nickel`, the new state is `$0.05`.

```
fsm.addTransition(
  from: ZeroCents,
  to: FiveCents,
  condition: { $1 == .nickel },
  map: { _ in (nil, nil) })
```

If the machine has `$0` and you insert a `dime`, the new state is `$0.10`.

```
fsm.addTransition(
  from: ZeroCents,
  to: TenCents,
  condition: { $1 == .dime },
  map: { _ in (nil, nil) })
```

If the machine has `$0.05` and you insert a `quarter`, then will give you a Candy 2, and the new state is `$0`.

```
fsm.addTransition(
  from: FiveCents,
  to: ZeroCents,
  condition: { $1 == .quarter },
  map: { _ in (nil, .candy2) })
```

If the machine has `$0.05` and you insert a `nickel`, the new state is `$0.10`.

```
fsm.addTransition(
  from: FiveCents,
  to: TenCents,
  condition: { $1 == .nickel },
  map: { _ in (nil, nil) })
```

If the machine has `$0.05` and you insert a `dime`, the new state is `$0.15`.

```
fsm.addTransition(
  from: FiveCents,
  to: FifteenCents,
  condition: { $1 == .dime },
  map: { _ in (nil, nil) })
```

If the machine has `$0.10` and you insert a `dime`, it will give you a Candy 0, but if you insert a `quarter`, will give you a Candy 3. In both cases, the new state is `$0`.

```
// This could be modeled as two transitions also
fsm.addTransition(
  from: TenCents,
  to: ZeroCents,
  condition: { $1 == .dime || $1 == .quarter },
  map: {
    switch $1 {
    case .dime?: return (nil, .candy0)
    case .quarter?: return (nil, .candy3)
    default: assertionFailure(); return (nil, nil)
    }
  })
```

If the machine has `$0.10` and you insert a `nickel`, the new state is `$0.15`.

```
fsm.addTransition(
  from: TenCents,
  to: FifteenCents,
  condition: { $1 == .nickel },
  map: { _ in (nil, nil) })
```

If the machine has `$0.15` and you insert a `nickel`, will give you a Candy 0. If you insert a `dime`, will give you a Candy 1. If you insert a `quarter`, will give you a Candy 4. In each case, the new state is `$0`.

```
// This could be modeled as three transitions also
fsm.addTransition(
  from: FifteenCents,
  to: ZeroCents,
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

```

In order to be able to receive the machine output, you need to provide a delegate.

```
class MyDelegate: FSMDelegate {
  func stateWillChange(from sourceId: String, to targetId: String, with fsmOutput: Candy?) {
    if let output = fsmOutput {
      print("Output: \(output)")
    }
  }
}

let delegate = MyDelegate()
fsm.delegate = delegate
```

_In this example, the FSM output is based only on the current state and input, the machine "has not memory", so the states have not associated data. Then, the `map` and `condition` functions for the transitions will always receive `nil` as first param. But there are more complex cases where you can store anything there._

Once you've defined the machine structure, it's ready to start and receive inputs.


```
fsm.start(from: ZeroCents)
fsm.input(data: .nickel)
fsm.input(data: .dime)
fsm.input(data: .quarter) // Output: c4
fsm.printStructure()

fsm.input(data: .quarter) // Output: c1
fsm.input(data: .quarter) // Output: c1
fsm.input(data: .quarter) // Output: c1

fsm.input(data: .nickel)
fsm.input(data: .quarter) // Output: c2

fsm.input(data: .dime)
fsm.input(data: .quarter) // Output: c3

fsm.input(data: .dime)
fsm.input(data: .dime) // Output: c0
```

You can look for more examples at the MealyFSMTests directory.

# Feedback & contribution

 - You can use GitHub issues for reporting bugs or request new features.
 - Issues and pull requests are welcome.

# License

Available under MIT license. See the LICENSE file for more details.
