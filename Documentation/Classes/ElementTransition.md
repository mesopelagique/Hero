# ElementTransition

The `ElementTransition` class is the **shared element transition engine** for 4D forms. It animates form objects between two visual states — position, size, colors, font size, corner radius — in the spirit of *Hero animations* (Flutter/iOS), *Magic Move* (Keynote), *matchedGeometryEffect* (SwiftUI) or *Container Transform* (Material Design).

One instance drives all the animations of **one** form, using the form timer (`SET TIMER` / `On Timer`, ~60 fps).

<hr>
📌 <b>Important</b>

Every call must be made **from the form's own context** (a form or object event of that form), because the engine relies on `SET TIMER`, which targets the current form. The `On Timer` event must be enabled on the form.

<hr>

## Setup

```4d
Case of
	: (Form event code=On Load)
		Form.transition:=cs.hero.ElementTransition.new()

	: (Form event code=On Timer)
		Form.transition.onTimer()
End case
```

## <a name="Constructor">cs.hero.ElementTransition.new()</a>

**cs.hero.ElementTransition.new**( ) : `cs.hero.ElementTransition`

Creates the engine for the current form. Store it in `Form` on the `On Load` event.

# Summary

## <a name="Properties">Properties</a>

|Properties|Description|Type|Writable|
|:----------|:-----------|:-----------|:-----------:|
|**.animations**| The currently running animations | `Collection` of [`cs.hero.ElementAnimation`](ElementAnimation.md) |<font color="red">x</font>
|**.isRunning**| `True` while at least one animation is running | `Boolean` |<font color="red">x</font>
|**.timerTicks**| Timer granularity in ticks (1 tick = 1/60 s; default `1` ≈ 60 fps) | `Integer` |<font color="green">✓</font>

## <a name="Functions">Functions</a>

| Functions | Action |
|:-------- |:------ |
|[.**animate** (*target*)](#animate) | Creates a free-form tween for a form object (fluent builder, not started) |
|[.**share** (*from*; *to* {; *options*})](#share) | Hero transition between two objects of the form, started immediately |
|[.**morph** (*from*; *to* {; *options*})](#morph) | Container transform between two objects of the form, started immediately |
|[.**capture** ({*names*})](#capture) | Snapshots the visual state of form objects, to hand over to another form |
|[.**heroFrom** (*snapshot* {; *options*})](#heroFrom) | Makes every object matching a captured state fly from it (cross-form hero) |
|[.**onTimer** ()](#onTimer) | Drives the running animations; call on the `On Timer` event |
|[.**stop** ({*jumpToEnd*})](#stop) | Stops everything |

## <a name="options">The *options* object</a>

Accepted by `share()`, `morph()` and `heroFrom()`:

|Property|Type|Description|
|---|---|---|
| duration | Real | Duration in ms (default 300) |
| delay | Real | Delay before starting, in ms (default 0) |
| easing | Text | Easing curve name (default `"easeInOutCubic"`) — see [ElementAnimation](ElementAnimation.md#easing) |
| colorMode | Text | `"rgb"` (default) or `"hsv"` color interpolation — see [ElementState](ElementState.md#colors) |
| then | 4D.Function | Callback executed on completion; receives the animation as `$1` |
| animateColors<br>animateFontSize<br>animateCornerRadius | Boolean | Per-property opt-out flags (default `True`) |

# <a name="animate">.animate()</a>

**.animate**( *target* : Text ) : `cs.hero.ElementAnimation`

|Parameter|Type||Description|
|---|---|---|---|
| target | Text | → | Name of the form object to animate |
| result | [cs.hero.ElementAnimation](ElementAnimation.md) | ← | A new tween, configured with the fluent API |

### Description

Creates a tween for a form object. Configure it with the fluent API, then call `.start()`:

```4d
Form.transition.animate("badge").by(0; 80).duration(400).easing("easeOutBounce").start()
Form.transition.animate("title").to({fontSize: 24}).duration(450).easing("easeOutBack").start()
```

Starting a new animation on an object that is already animating replaces the running one.

# <a name="share">.share()</a>

**.share**( *fromName* : Text; *toName* : Text {; *options* : Object} ) : `cs.hero.ElementAnimation`

|Parameter|Type||Description|
|---|---|---|---|
| fromName | Text | → | Name of the source object (currently visible) |
| toName | Text | → | Name of the destination object |
| options | Object | → | See [the options object](#options) |
| result | [cs.hero.ElementAnimation](ElementAnimation.md) | ← | The started animation |

### Description

Hero / shared element transition, **started immediately**: the destination object takes the source's place and look, the source is hidden, then the destination flies to its natural state.

Both objects represent the same conceptual element in two states of the UI; only one of them is visible at a time. Play the reverse transition by swapping the names:

```4d
Form.transition.share("cardSmall"; "cardLarge"; {duration: 450; easing: "easeOutBack"; colorMode: "hsv"})
// and back:
Form.transition.share("cardLarge"; "cardSmall"; {duration: 350; easing: "easeInOutCubic"; colorMode: "hsv"})
```

# <a name="morph">.morph()</a>

**.morph**( *fromName* : Text; *toName* : Text {; *options* : Object} ) : `cs.hero.ElementAnimation`

|Parameter|Type||Description|
|---|---|---|---|
| fromName | Text | → | Name of the source object (currently visible) |
| toName | Text | → | Name of the destination object |
| options | Object | → | See [the options object](#options) |
| result | [cs.hero.ElementAnimation](ElementAnimation.md) | ← | The started animation |

### Description

Container transform, **started immediately**: the source object itself travels and reshapes to the destination's place; on arrival the destination is shown, and the source is hidden and restored to its original geometry.

```4d
Form.transition.morph("chip"; "panel"; {duration: 400; easing: "easeInOutCubic"})
```

# <a name="capture">.capture()</a>

**.capture**( {*names* : Collection} ) : `Collection`

|Parameter|Type||Description|
|---|---|---|---|
| names | Collection | → | Names of the objects to snapshot; omit to capture every object of the current form page |
| result | Collection | ← | Collection of [cs.hero.ElementState](ElementState.md) |

### Description

Snapshots the visual state of form objects, to hand over to the **next** form (see [heroFrom](#heroFrom)). The snapshot is JSON-serializable, so it can also be persisted to a file.

Typical use, in the event that closes the form:

```4d
Form.hero:=Form.transition.capture(["avatar"; "userName"; "header"])
ACCEPT
```

# <a name="heroFrom">.heroFrom()</a>

**.heroFrom**( *snapshot* : Collection {; *options* : Object} ) : `Collection`

|Parameter|Type||Description|
|---|---|---|---|
| snapshot | Collection | → | A snapshot taken in another form with [capture()](#capture) (states or plain objects) |
| options | Object | → | See [the options object](#options) |
| result | Collection | ← | The started [cs.hero.ElementAnimation](ElementAnimation.md) instances |

### Description

Cross-form hero transition. Every object of the current form whose **name matches** a captured state flies from that state to its natural place; objects with no match are untouched. Call it from the `On Load` event of the destination form:

```4d
If (Form.hero#Null)
	Form.transition.heroFrom(Form.hero; {duration: 450; easing: "easeOutCubic"; colorMode: "hsv"})
End if
```

See the `DEMO_TwoForms` method for a complete two-form flow (the snapshot travels through the `DIALOG` form data).

# <a name="onTimer">.onTimer()</a>

**.onTimer**( )

### Description

Advances every running animation. Call it from the form method on the `On Timer` event. The engine arms the timer when an animation starts and stops it (`SET TIMER(0)`) when the last animation completes.

# <a name="stop">.stop()</a>

**.stop**( {*jumpToEnd* : Boolean} )

|Parameter|Type||Description|
|---|---|---|---|
| jumpToEnd | Boolean | → | If `True`, every animation snaps to its final state and completion callbacks run |

### Description

Stops all running animations and releases the form timer.
