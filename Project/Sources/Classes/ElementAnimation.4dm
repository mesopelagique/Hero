// ElementAnimation — a single tween of one form object between two ElementState
// keyframes, created through cs.ElementTransition and configured with a fluent API.
// See Documentation/Classes/ElementAnimation.md

property target : Text
property fromState : cs.ElementState
property toState : cs.ElementState
property durationMs : Real:=300
property delayMs : Real:=0
property easingName : Text:="easeInOutCubic"

// Color interpolation space: "rgb" (linear) or "hsv" (shortest hue path, keeps in-between tones vivid)
property colorMode : Text:="rgb"
property animateColors : Boolean:=True
property animateFontSize : Boolean:=True
property animateCornerRadius : Boolean:=True
property onComplete : 4D.Function

property _manager : cs.ElementTransition
property _startTime : Real:=-1
property _done : Boolean:=False

// Visibility swap & state restoration performed when the animation completes (used by share/morph)
property _swapShow : Text:=""
property _swapHide : Text:=""
property _restoreState : cs.ElementState

Class constructor($manager : cs.ElementTransition; $target : Text)

	This._manager:=$manager
	This.target:=$target

	// MARK:- [Fluent builder]
	// === === === === === === === === === === === === === === === === === === === === === === === === === ===
	// Starting keyframe: an ElementState, an object name, or {left; top; right; bottom; width; height; …}
	// If omitted, the current state of the target is captured when the animation starts.
Function from($source) : cs.ElementAnimation

	This.fromState:=This._resolveState($source)

	return This

	// === === === === === === === === === === === === === === === === === === === === === === === === === ===
	// Ending keyframe: an ElementState, an object name, or {left; top; right; bottom; width; height; …}
Function to($destination) : cs.ElementAnimation

	This.toState:=This._resolveState($destination)

	return This

	// === === === === === === === === === === === === === === === === === === === === === === === === === ===
	// Relative move: the target travels by ($dx; $dy) from its current position
Function by($dx : Real; $dy : Real) : cs.ElementAnimation

	If (This.fromState=Null)

		This.fromState:=cs.ElementState.new(This.target)

	End if

	var $state:=This.fromState.copy()
	$state.left:=$state.left+$dx
	$state.right:=$state.right+$dx
	$state.top:=$state.top+$dy
	$state.bottom:=$state.bottom+$dy
	This.toState:=$state

	return This

	// === === === === === === === === === === === === === === === === === === === === === === === === === ===
Function duration($ms : Real) : cs.ElementAnimation

	This.durationMs:=$ms

	return This

	// === === === === === === === === === === === === === === === === === === === === === === === === === ===
Function delay($ms : Real) : cs.ElementAnimation

	This.delayMs:=$ms

	return This

	// === === === === === === === === === === === === === === === === === === === === === === === === === ===
	// See the README for the list of supported easing names
Function easing($name : Text) : cs.ElementAnimation

	This.easingName:=$name

	return This

	// === === === === === === === === === === === === === === === === === === === === === === === === === ===
	// Callback executed when the animation completes; receives the animation as $1
Function then($callback : 4D.Function) : cs.ElementAnimation

	This.onComplete:=$callback

	return This

	// === === === === === === === === === === === === === === === === === === === === === === === === === ===
	// Register the animation with its manager and start the form timer
Function start() : cs.ElementAnimation

	This._manager._begin(This)

	return This

	// MARK:- [Engine]
	// === === === === === === === === === === === === === === === === === === === === === === === === === ===
Function _resolveState($source) : cs.ElementState

	Case of

			//______________________________________________________
		: (Value type($source)=Is text)  // Another object name

			return cs.ElementState.new(String($source))

			//______________________________________________________
		: (Value type($source)=Is object)

			If (OB Instance of($source; cs.ElementState))

				return $source

			End if

			// Plain object: current state of the target overridden by the given properties
			var $state:=cs.ElementState.new(This.target)

			If (Not(Undefined($source.left)))
				$state.left:=Num($source.left)
			End if

			If (Not(Undefined($source.top)))
				$state.top:=Num($source.top)
			End if

			If (Not(Undefined($source.right)))
				$state.right:=Num($source.right)
			End if

			If (Not(Undefined($source.bottom)))
				$state.bottom:=Num($source.bottom)
			End if

			If (Not(Undefined($source.width)))
				$state.right:=$state.left+Num($source.width)
			End if

			If (Not(Undefined($source.height)))
				$state.bottom:=$state.top+Num($source.height)
			End if

			If (Not(Undefined($source.fontSize)))
				$state.fontSize:=Num($source.fontSize)
			End if

			If (Not(Undefined($source.foregroundColor)))
				$state.foregroundColor:=Num($source.foregroundColor)
			End if

			If (Not(Undefined($source.backgroundColor)))
				$state.backgroundColor:=Num($source.backgroundColor)
			End if

			If (Not(Undefined($source.cornerRadius)))
				$state.cornerRadius:=Num($source.cornerRadius)
			End if

			return $state

			//______________________________________________________
		Else

			ASSERT(False; Current method name+": keyframe must be an ElementState, an object name or an object")
			return Null

			//______________________________________________________
	End case

	// === === === === === === === === === === === === === === === === === === === === === === === === === ===
	// Called by the manager when the animation is scheduled
Function _start($now : Real)

	If (This.fromState=Null)

		This.fromState:=cs.ElementState.new(This.target)

	End if

	If (This.toState=Null)

		This.toState:=cs.ElementState.new(This.target)

	End if

	This._startTime:=$now
	This._done:=False

	If (This.delayMs<=0)

		This._applyProgress(0)  // Avoid a one-tick flash at the previous position

	End if

	// === === === === === === === === === === === === === === === === === === === === === === === === === ===
	// Advance the animation; returns True when finished
Function _tick($now : Real) : Boolean

	If (This._done)

		return True

	End if

	var $elapsed:=$now-This._startTime-This.delayMs

	If ($elapsed<0)  // Still in the delay phase

		return False

	End if

	var $t:=(This.durationMs<=0) ? 1 : ($elapsed/This.durationMs)
	$t:=($t>1) ? 1 : $t

	This._applyProgress($t)

	If ($t>=1)

		This._finish()

	End if

	return This._done

	// === === === === === === === === === === === === === === === === === === === === === === === === === ===
Function _applyProgress($t : Real)

	var $state:=This.fromState.lerp(This.toState; This._ease($t); This.colorMode)

	If (Not(This.animateColors))

		$state.foregroundColor:=This.fromState.foregroundColor
		$state.backgroundColor:=This.fromState.backgroundColor

	End if

	If (Not(This.animateFontSize))

		$state.fontSize:=This.fromState.fontSize

	End if

	If (Not(This.animateCornerRadius))

		$state.cornerRadius:=This.fromState.cornerRadius

	End if

	$state.apply(This.target)

	// === === === === === === === === === === === === === === === === === === === === === === === === === ===
Function _finish()

	If (This._done)

		return

	End if

	This._done:=True

	If (Length(This._swapShow)>0)

		OBJECT SET VISIBLE(*; This._swapShow; True)

	End if

	If (Length(This._swapHide)>0)

		OBJECT SET VISIBLE(*; This._swapHide; False)

	End if

	If (This._restoreState#Null)

		This._restoreState.apply()

	End if

	If (This.onComplete#Null)

		This.onComplete.call(Null; This)

	End if

	// MARK:- [Easing]
	// === === === === === === === === === === === === === === === === === === === === === === === === === ===
Function _ease($t : Real) : Real

	Case of

			//______________________________________________________
		: (This.easingName="linear")

			return $t

			//______________________________________________________
		: (This.easingName="easeInQuad")

			return $t*$t

			//______________________________________________________
		: (This.easingName="easeOutQuad")

			return 1-((1-$t)*(1-$t))

			//______________________________________________________
		: (This.easingName="easeInOutQuad")

			return ($t<0.5) ? (2*$t*$t) : (1-((((-2*$t)+2)^2)/2))

			//______________________________________________________
		: (This.easingName="easeInCubic")

			return $t*$t*$t

			//______________________________________________________
		: (This.easingName="easeOutCubic")

			return 1-((1-$t)^3)

			//______________________________________________________
		: (This.easingName="easeInOutCubic")

			return ($t<0.5) ? (4*$t*$t*$t) : (1-((((-2*$t)+2)^3)/2))

			//______________________________________________________
		: (This.easingName="easeOutBack")

			return 1+((1.70158+1)*(($t-1)^3))+(1.70158*(($t-1)^2))

			//______________________________________________________
		: (This.easingName="easeInOutBack")

			var $c2 : Real:=1.70158*1.525

			return ($t<0.5)\
				 ? ((((2*$t)^2)*((($c2+1)*2*$t)-$c2))/2)\
				 : ((((((2*$t)-2)^2)*((($c2+1)*(($t*2)-2))+$c2))+2)/2)

			//______________________________________________________
		: (This.easingName="easeOutElastic")

			If ($t<=0)
				return 0
			End if

			If ($t>=1)
				return 1
			End if

			return ((2^(-10*$t))*Sin((($t*10)-0.75)*((2*3.14159265358979)/3)))+1

			//______________________________________________________
		: (This.easingName="easeOutBounce")

			return This._bounce($t)

			//______________________________________________________
		Else  // Unknown easing name: fall back to linear

			return $t

			//______________________________________________________
	End case

	// === === === === === === === === === === === === === === === === === === === === === === === === === ===
Function _bounce($t : Real) : Real

	var $n1 : Real:=7.5625
	var $d1 : Real:=2.75

	Case of

			//______________________________________________________
		: ($t<(1/$d1))

			return $n1*$t*$t

			//______________________________________________________
		: ($t<(2/$d1))

			$t:=$t-(1.5/$d1)
			return ($n1*$t*$t)+0.75

			//______________________________________________________
		: ($t<(2.5/$d1))

			$t:=$t-(2.25/$d1)
			return ($n1*$t*$t)+0.9375

			//______________________________________________________
		Else

			$t:=$t-(2.625/$d1)
			return ($n1*$t*$t)+0.984375

			//______________________________________________________
	End case
