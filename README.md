# FormElementTransition

**Shared Element Transitions for 4D forms.**

Animate a form object from one visual state to another — position, size, colors, font size, corner radius — the way *Hero animations* (Flutter/iOS), *Magic Move* (Keynote), *matchedGeometryEffect* (SwiftUI) or *Container Transform* (Material Design) do: the same conceptual element exists in two states of your UI, and the library animates the transition between them automatically.

![demo](https://img.shields.io/badge/4D-v21%2B-blue)

## Classes

A **4D component** exposing three classes under the `cs.hero` namespace, driven by the **form timer** (`SET TIMER` / `On Timer`, ~60 fps). Each one has its full reference in [`Documentation/Classes/`](Documentation/Classes/), also shown by the 4D code editor:

| Class | Role |
|---|---|
| [`cs.hero.ElementTransition`](Documentation/Classes/ElementTransition.md) | The engine. One instance per form: `animate()`, `share()`, `morph()`, `capture()`/`heroFrom()`, `onTimer()`. |
| [`cs.hero.ElementAnimation`](Documentation/Classes/ElementAnimation.md) | One tween, configured with a fluent API: keyframes, duration, delay, [easing curves](Documentation/Classes/ElementAnimation.md#easing), callback. |
| [`cs.hero.ElementState`](Documentation/Classes/ElementState.md) | A keyframe: snapshot of an object's visual state — capture, interpolate ([RGB or HSV colors](Documentation/Classes/ElementState.md#colors)), apply. |

## Setup

1. Add **FormElementTransition** to your project's dependencies (it is a component); its classes are exposed under the `cs.hero` namespace.
2. Enable the **On Timer** event on your form.
3. In the form method:

```4d
Case of
	: (Form event code=On Load)
		Form.transition:=cs.hero.ElementTransition.new()

	: (Form event code=On Timer)
		Form.transition.onTimer()
End case
```

## Usage

**[Hero transition](Documentation/Classes/ElementTransition.md#share)** — two objects represent the same element in two states, only one visible at a time; the destination flies out of the source's place. Reverse by swapping the names:

```4d
Form.transition.share("cardSmall"; "cardLarge"; {duration: 450; easing: "easeOutBack"; colorMode: "hsv"})
```

**[Morph](Documentation/Classes/ElementTransition.md#morph)** — the source itself travels and reshapes to the destination's place, then visibility is swapped:

```4d
Form.transition.morph("chip"; "panel"; {duration: 400; easing: "easeInOutCubic"})
```

**[Free-form tween](Documentation/Classes/ElementAnimation.md)** — fluent builder; a keyframe is an object name, an `ElementState`, or a plain object of properties:

```4d
Form.transition.animate("badge").by(0; 80).duration(400).easing("easeOutBounce").start()
Form.transition.animate("title").to({fontSize: 24}).duration(450).easing("easeOutBack").then(Formula(ALERT("done"))).start()
```

**[Between two forms](Documentation/Classes/ElementTransition.md#capture)** — the realistic case: a form is validated and a second form replaces it in the same window. Elements are matched **by object name**: the closing form snapshots them with `capture()`, the next form makes them fly with `heroFrom()` on load:

```4d
// Form A, in the event that closes the form:
Form.hero:=Form.transition.capture(["avatar"; "userName"; "header"])
ACCEPT

// Form B, On Load:
If (Form.hero#Null)
	Form.transition.heroFrom(Form.hero; {duration: 450; easing: "easeOutCubic"})
End if
```

## Demos

- **`DEMO`** — single form: each click on **Toggle** plays a hero transition between a small blue card and a large orange one (position, size, corner radius and colors interpolated), while the title's font size tweens along.
- **`DEMO_TwoForms`** — two real forms in the same window: **Sign in** captures the avatar / user name / header states and the home form makes them fly to their new place on load; **Log out** plays the reverse flight.

## Notes & limitations

- One `ElementTransition` instance per form; all calls must be made **from that form's context** (the engine uses `SET TIMER`, which targets the current form), and the `On Timer` event must be enabled.
- Colors are interpolated in RGB by default; pass `colorMode: "hsv"` to keep in-between tones of distant hues vivid ([details](Documentation/Classes/ElementState.md#colors)).
- Corner radius only animates between two **rectangle** objects; 4D form objects have no opacity property, so cross-fades are approximated by color interpolation plus a visibility swap.

