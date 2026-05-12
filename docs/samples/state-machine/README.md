# Sample: State Machine

Classic three-state traffic light. The enum has no associated values, the host class holds a property of that enum type, and the `advance()` method mutates it via a `switch` — the three signals the detector needs for HIGH confidence.

## List the candidates first

```bash
cd docs/samples/state-machine
swiftumlbridge state Sources/ --list
```

You should see one HIGH-confidence candidate: `TrafficLight.TrafficLightColor`.

## Render the machine

```bash
swiftumlbridge state Sources/ --state TrafficLight.TrafficLightColor --output consoleOnly
```

## What you'll see

Three nodes (`red`, `yellow`, `green`) and three transition edges — `red → green`, `green → yellow`, `yellow → red`.

## Try next

- Add a case to the enum but don't add a matching switch arm — re-running `--list` should downgrade the confidence.
- Add a guard like `case .red where someCondition` — the transition picks up a `[someCondition]` label on the edge.

See the [state-machine chapter of the User Guide](../../user/user-guide.md#generating-state-machine-diagrams) for the detection rules.
