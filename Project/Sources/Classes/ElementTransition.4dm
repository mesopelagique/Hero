// ElementTransition — the shared element transition engine for 4D forms
// (hero / magic-move animations driven by the form timer). One instance per form:
// create it on "On Load", call .onTimer() on "On Timer".
// See Documentation/Classes/ElementTransition.md

property animations : Collection

// Timer granularity in ticks (1 tick = 1/60 s, so 1 ≈ 60 fps)
property timerTicks : Integer:=1

Class constructor()

	This.animations:=[]

	// MARK:- [Building animations]
	// === === === === === === === === === === === === === === === === === === === === === === === === === ===
	// Create a tween for a form object; configure it with the fluent API, then call .start()
Function animate($target : Text) : cs.ElementAnimation

	return cs.ElementAnimation.new(This; $target)

	// === === === === === === === === === === === === === === === === === === === === === === === === === ===
	// Hero transition, started immediately: the destination takes the source's place
	// and look, the source hides, the destination flies to its natural state.
	// Reverse it with share($toName; $fromName).
Function share($fromName : Text; $toName : Text; $options : Object) : cs.ElementAnimation

	var $fromState:=cs.ElementState.new($fromName)
	var $toState:=cs.ElementState.new($toName)

	// The destination starts where — and how — the source is…
	$fromState.apply($toName)
	OBJECT SET VISIBLE(*; $fromName; False)
	OBJECT SET VISIBLE(*; $toName; True)

	// …and flies to its natural place
	var $animation:=This.animate($toName).from($fromState).to($toState)
	This._applyOptions($animation; $options)

	return $animation.start()

	// === === === === === === === === === === === === === === === === === === === === === === === === === ===
	// Morph (container transform), started immediately: the source itself travels and
	// reshapes to the destination's place, then the visibility is swapped and the
	// source restored.
Function morph($fromName : Text; $toName : Text; $options : Object) : cs.ElementAnimation

	var $fromState:=cs.ElementState.new($fromName)
	var $toState:=cs.ElementState.new($toName)

	OBJECT SET VISIBLE(*; $toName; False)
	OBJECT SET VISIBLE(*; $fromName; True)

	var $animation:=This.animate($fromName).from($fromState).to($toState)
	$animation._swapShow:=$toName
	$animation._swapHide:=$fromName
	$animation._restoreState:=$fromState
	This._applyOptions($animation; $options)

	return $animation.start()

	// MARK:- [Between two forms]
	// === === === === === === === === === === === === === === === === === === === === === === === === === ===
	// Snapshot the visual state of form objects (every object of the current page when
	// $names is omitted), to hand over to the NEXT form — see heroFrom().
Function capture($names : Collection) : Collection

	If ($names=Null)

		ARRAY TEXT($objectNames; 0)
		FORM GET OBJECTS($objectNames; Form current page)

		$names:=[]
		var $i : Integer

		For ($i; 1; Size of array($objectNames))

			$names.push($objectNames{$i})

		End for

	End if

	var $states : Collection:=[]
	var $name : Text

	For each ($name; $names)

		$states.push(cs.ElementState.new($name))

	End for each

	return $states

	// === === === === === === === === === === === === === === === === === === === === === === === === === ===
	// Hero transitions from a snapshot taken in ANOTHER form (see capture()): every
	// object whose name matches a captured state flies from it to its natural place.
	// Call it from the On Load event of the destination form.
Function heroFrom($snapshot : Collection; $options : Object) : Collection

	var $animations : Collection:=[]
	var $stored : Object

	For each ($stored; $snapshot)

		var $name:=String($stored.name)

		If ((Length($name)>0) && (OBJECT Get type(*; $name)#Object type unknown))

			var $natural:=cs.ElementState.new($name)

			// Rebuild the starting keyframe from the stored state (plain object or ElementState)
			var $from:=$natural.copy()
			$from.left:=Num($stored.left)
			$from.top:=Num($stored.top)
			$from.right:=Num($stored.right)
			$from.bottom:=Num($stored.bottom)
			$from.fontSize:=Num($stored.fontSize)
			$from.foregroundColor:=Undefined($stored.foregroundColor) ? -1 : Num($stored.foregroundColor)
			$from.backgroundColor:=Undefined($stored.backgroundColor) ? -1 : Num($stored.backgroundColor)
			$from.cornerRadius:=Undefined($stored.cornerRadius) ? -1 : Num($stored.cornerRadius)

			var $animation:=This.animate($name).from($from).to($natural)
			This._applyOptions($animation; $options)
			$animations.push($animation.start())

		End if

	End for each

	return $animations

	// MARK:- [Engine]
	// === === === === === === === === === === === === === === === === === === === === === === === === === ===
	// Call from the form method on the On Timer event
Function onTimer()

	var $now : Real:=Milliseconds
	var $animation : cs.ElementAnimation

	// Iterate on a snapshot: completion callbacks may start new animations
	For each ($animation; This.animations.slice(0))

		$animation._tick($now)

	End for each

	var $running : Collection:=[]

	For each ($animation; This.animations)

		If (Not($animation._done))

			$running.push($animation)

		End if

	End for each

	This.animations:=$running

	If (This.animations.length=0)

		SET TIMER(0)

	End if

	// <== <== <== <== <== <== <== <== <== <== <== <== <== <== <== <== <== <== <== <== <== <== <== <== <== <==
Function get isRunning() : Boolean

	return This.animations.length>0

	// === === === === === === === === === === === === === === === === === === === === === === === === === ===
	// Stop everything; if $jumpToEnd, every animation snaps to its final state and callbacks run
Function stop($jumpToEnd : Boolean)

	var $animation : cs.ElementAnimation

	For each ($animation; This.animations.slice(0))

		If ($jumpToEnd)

			$animation._tick($animation._startTime+$animation.delayMs+$animation.durationMs+1)

		Else

			$animation._done:=True

		End if

	End for each

	This.animations:=[]
	SET TIMER(0)

	// === === === === === === === === === === === === === === === === === === === === === === === === === ===
	// Called by ElementAnimation.start(): schedule the animation and arm the form timer
Function _begin($animation : cs.ElementAnimation)

	// A new animation on an object replaces the running one
	var $i : Integer

	For ($i; This.animations.length-1; 0; -1)

		If (This.animations[$i].target=$animation.target)

			This.animations.remove($i)

		End if

	End for

	$animation._start(Milliseconds)
	This.animations.push($animation)

	SET TIMER(This.timerTicks)

	// === === === === === === === === === === === === === === === === === === === === === === === === === ===
Function _applyOptions($animation : cs.ElementAnimation; $options : Object)

	If ($options=Null)

		return

	End if

	If (Not(Undefined($options.duration)))
		$animation.durationMs:=Num($options.duration)
	End if

	If (Not(Undefined($options.delay)))
		$animation.delayMs:=Num($options.delay)
	End if

	If (Not(Undefined($options.easing)))
		$animation.easingName:=String($options.easing)
	End if

	If (Not(Undefined($options.colorMode)))
		$animation.colorMode:=String($options.colorMode)
	End if

	If (Not(Undefined($options.then)))
		$animation.onComplete:=$options.then
	End if

	If (Not(Undefined($options.animateColors)))
		$animation.animateColors:=Bool($options.animateColors)
	End if

	If (Not(Undefined($options.animateFontSize)))
		$animation.animateFontSize:=Bool($options.animateFontSize)
	End if

	If (Not(Undefined($options.animateCornerRadius)))
		$animation.animateCornerRadius:=Bool($options.animateCornerRadius)
	End if
