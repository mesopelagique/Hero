# Recipes

Short, copy-paste patterns built on the three [`cs.hero`](Classes/) classes. Each one
assumes the standard [setup](../README.md#setup): a `Form.transition` created on
`On Load` and `Form.transition.onTimer()` called on `On Timer`.

- [Error shake — "bad password"](#error-shake)

---

## <a name="error-shake"></a>Error shake — "bad password"

The classic feedback for a rejected field or button: a quick horizontal *shake*.
The trick is that a shake is just an object **springing back to its own resting
place** — which is exactly what the `easeOutElastic` curve does (it overshoots the
target back and forth with a decaying amplitude). So there is no keyframe list and no
chaining: displace the object, then animate it back to rest with `easeOutElastic`.

```4d
  // On a bad password — shake the field
var $rest : Integer:=cs.hero.ElementState.new("password").left   // its resting left

Form.transition.animate("password") \
	.from({left: $rest+16}) \       // start shoved 16 px to the right …
	.to({left: $rest}) \            // … and spring back to where it was
	.duration(600) \
	.easing("easeOutElastic") \
	.start()
```

`from({left: …})` only overrides the left edge — the object keeps its width, so this
is a *move*, not a resize. `easeOutElastic` springs around the destination, so the
field crosses its resting position several times, each swing smaller than the last,
and stops on the spot. One tween, and it reads as a shake.

Works on any named object — a text input, a whole login card, or the **Sign in**
button itself: just pass its name.

### Tuning

| Want | Change |
|---|---|
| A bigger / smaller shake | the `16` offset in `from` |
| A snappier / lazier shake | the `duration` (≈ 400–800 ms feels right) |
| A **vertical** shake (e.g. a rejected row) | swap `left` for `top` |

### Add a red flash

A 4D form object has no opacity and only **one** animation can run on a given object
at a time (a second `animate("password")` would *replace* the shake). So do the colour
as state, not as a competing tween: paint the field red the moment it is rejected, and
clear it when the user starts fixing it.

```4d
  // On error, alongside the shake:
OBJECT SET RGB COLORS(*; "password"; 0x00000000; 0x00FFE0E0)   // red-tinted background

  // In the field's On Data Change, put it back:
OBJECT SET RGB COLORS(*; "password"; 0x00000000; 0x00FFFFFF)
```

### If you don't want the elastic feel

For a tighter, hand-tuned shake, chain a few short legs with `.then()` instead. Keep
the swing offsets and let each leg trigger the next; the last one lands on `$rest`.
Store the little bit of state on your form so the callback can read it:

```4d
  // Function shake($name : Text) on your form's helper object
This.name:=$name
This.rest:=cs.hero.ElementState.new($name).left
This.swings:=[14; -11; 8; -6; 4; -2; 0]   // ends at the resting offset, 0
This.i:=0
This._leg()

  // Function _leg()
If (This.i<This.swings.length)
	var $dx : Integer:=This.swings[This.i]
	This.i:=This.i+1
	Form.transition.animate(This.name) \
		.to({left: This.rest+$dx}) \
		.duration(55) \
		.easing("easeInOutQuad") \
		.then(Formula(Form.shaker._leg())) \
		.start()
End if
```

Same result, more control — but for most "bad password" cases the one-liner above is
all you need.
