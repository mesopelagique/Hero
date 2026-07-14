# ElementAnimation

The `ElementAnimation` class is a single tween of one form object between two [`ElementState`](ElementState.md) keyframes.

Instances are created through [`cs.hero.ElementTransition`](ElementTransition.md) — `animate()`, `share()`, `morph()`, `heroFrom()` — and configured with a fluent API:

```4d
Form.transition.animate("myCard")\
	.to("myTargetSlot")\
	.duration(400)\
	.easing("easeOutBack")\
	.then(Formula(ALERT("done")))\
	.start()
```

The animation is driven by `ElementTransition.onTimer()`; it interpolates geometry, font size, colors and corner radius each tick.

## <a name="keyframe">Keyframes</a>

`.from()` and `.to()` accept, indifferently:

* a [`cs.hero.ElementState`](ElementState.md) instance,
* the **name** of another form object (its current state is captured),
* a plain object with any of `left`, `top`, `right`, `bottom`, `width`, `height`, `fontSize`, `foregroundColor`, `backgroundColor`, `cornerRadius` — missing properties keep the target's current values.

If `.from()` is omitted, the current state of the target is captured when the animation starts.

# Summary

## <a name="Properties">Properties</a>

|Properties|Description|Type|Writable|
|:----------|:-----------|:-----------|:-----------:|
|**.target**| Name of the animated form object | `Text` |<font color="red">x</font>
|**.fromState**<br>**.toState**| The two keyframes | [`cs.hero.ElementState`](ElementState.md) |<font color="green">✓</font>
|**.durationMs**| Duration in ms (default `300`) | `Real` |<font color="green">✓</font>
|**.delayMs**| Delay before starting, in ms (default `0`) | `Real` |<font color="green">✓</font>
|**.easingName**| Easing curve (default `"easeInOutCubic"`) — see [below](#easing) | `Text` |<font color="green">✓</font>
|**.colorMode**| Color interpolation space: `"rgb"` (default) or `"hsv"` — see [ElementState](ElementState.md#colors) | `Text` |<font color="green">✓</font>
|**.animateColors**<br>**.animateFontSize**<br>**.animateCornerRadius**| Per-property opt-out flags (default `True`) | `Boolean` |<font color="green">✓</font>
|**.onComplete**| Callback executed on completion; receives the animation as `$1` | `4D.Function` |<font color="green">✓</font>

## <a name="Functions">Functions (fluent builder)</a>

Every function returns the animation itself, so calls can be chained.

| Functions | Action |
|:-------- |:------ |
|.**from** (*keyframe*) | Sets the starting [keyframe](#keyframe) (defaults to the target's current state at start) |
|.**to** (*keyframe*) | Sets the ending [keyframe](#keyframe) |
|.**by** (*dx*; *dy*) | Relative move: the target travels by (*dx*; *dy*) from its current position |
|.**duration** (*ms*) | Sets the duration |
|.**delay** (*ms*) | Sets the start delay |
|.**easing** (*name*) | Sets the [easing curve](#easing) |
|.**then** (*callback*) | Sets the completion callback (`4D.Function`, receives the animation as `$1`) |
|.**start** () | Registers the animation with its engine and arms the form timer |

## <a name="easing">Easing curves</a>

|Name|Feel|
|---|---|
| `linear` | Constant speed |
| `easeInQuad` / `easeOutQuad` / `easeInOutQuad` | Gentle acceleration / deceleration |
| `easeInCubic` / `easeOutCubic` / `easeInOutCubic` | Stronger acceleration / deceleration (default: `easeInOutCubic`) |
| `easeOutBack` / `easeInOutBack` | Overshoots slightly past the target, then settles |
| `easeOutElastic` | Springs around the target |
| `easeOutBounce` | Bounces on arrival |

An unknown name falls back to `linear`.
