// ElementState — a snapshot of the animatable properties of a form object;
// the "keyframe" unit of the transition engine (capture / lerp / apply).
// See Documentation/Classes/ElementState.md

property name : Text
property type : Integer
property left; top; right; bottom : Real
property fontSize : Real
property foregroundColor; backgroundColor : Integer
property cornerRadius : Real
property visible : Boolean

Class constructor($name : Text)

	This.name:=$name
	This.type:=0
	This.left:=0
	This.top:=0
	This.right:=0
	This.bottom:=0
	This.fontSize:=0
	This.foregroundColor:=-1
	This.backgroundColor:=-1
	This.cornerRadius:=-1
	This.visible:=True

	If (Length($name)>0)

		This.capture()

	End if

	// === === === === === === === === === === === === === === === === === === === === === === === === === ===
	// Read the current state of the form object from the form
Function capture() : cs.ElementState

	var $left; $top; $right; $bottom : Integer
	OBJECT GET COORDINATES(*; This.name; $left; $top; $right; $bottom)

	This.type:=OBJECT Get type(*; This.name)
	This.left:=$left
	This.top:=$top
	This.right:=$right
	This.bottom:=$bottom
	This.fontSize:=OBJECT Get font size(*; This.name)
	This.visible:=OBJECT Get visible(*; This.name)

	var $foreground; $background : Integer
	OBJECT GET RGB COLORS(*; This.name; $foreground; $background)
	This.foregroundColor:=$foreground
	This.backgroundColor:=$background

	// Corner radius is only defined for rectangles
	This.cornerRadius:=(This.type=Object type rectangle) ? OBJECT Get corner radius(*; This.name) : -1

	return This

	// === === === === === === === === === === === === === === === === === === === === === === === === === ===
Function copy() : cs.ElementState

	var $state:=cs.ElementState.new()

	$state.name:=This.name
	$state.type:=This.type
	$state.left:=This.left
	$state.top:=This.top
	$state.right:=This.right
	$state.bottom:=This.bottom
	$state.fontSize:=This.fontSize
	$state.foregroundColor:=This.foregroundColor
	$state.backgroundColor:=This.backgroundColor
	$state.cornerRadius:=This.cornerRadius
	$state.visible:=This.visible

	return $state

	// <== <== <== <== <== <== <== <== <== <== <== <== <== <== <== <== <== <== <== <== <== <== <== <== <== <==
Function get width() : Real

	return This.right-This.left

	// <== <== <== <== <== <== <== <== <== <== <== <== <== <== <== <== <== <== <== <== <== <== <== <== <== <==
Function get height() : Real

	return This.bottom-This.top

	// === === === === === === === === === === === === === === === === === === === === === === === === === ===
	// Return a new state interpolated between This (t=0) and $target (t=1)
	// $colorMode: "rgb" (default, linear) or "hsv" (shortest hue path, avoids muddy in-between tones)
Function lerp($target : cs.ElementState; $t : Real; $colorMode : Text) : cs.ElementState

	var $state:=This.copy()

	$state.left:=This._lerpValue(This.left; $target.left; $t)
	$state.top:=This._lerpValue(This.top; $target.top; $t)
	$state.right:=This._lerpValue(This.right; $target.right; $t)
	$state.bottom:=This._lerpValue(This.bottom; $target.bottom; $t)

	If ((This.fontSize>0) && ($target.fontSize>0))

		$state.fontSize:=This._lerpValue(This.fontSize; $target.fontSize; $t)

	End if

	$state.foregroundColor:=This._lerpColor(This.foregroundColor; $target.foregroundColor; $t; $colorMode)
	$state.backgroundColor:=This._lerpColor(This.backgroundColor; $target.backgroundColor; $t; $colorMode)

	If ((This.cornerRadius>=0) && ($target.cornerRadius>=0))

		$state.cornerRadius:=This._lerpValue(This.cornerRadius; $target.cornerRadius; $t)

	Else

		$state.cornerRadius:=($t<1) ? This.cornerRadius : $target.cornerRadius

	End if

	return $state

	// === === === === === === === === === === === === === === === === === === === === === === === === === ===
	// Apply this state to a form object ($name defaults to the captured object)
Function apply($name : Text) : cs.ElementState

	$name:=(Length(String($name))>0) ? $name : This.name

	OBJECT SET COORDINATES(*; $name; This.left; This.top; This.right; This.bottom)

	If (This.fontSize>0)

		OBJECT SET FONT SIZE(*; $name; Round(This.fontSize; 0))

	End if

	If ((This.foregroundColor>=0) || (This.backgroundColor>=0))

		OBJECT SET RGB COLORS(*; $name; This.foregroundColor; This.backgroundColor)

	End if

	If ((This.cornerRadius>=0) && (OBJECT Get type(*; $name)=Object type rectangle))

		OBJECT SET CORNER RADIUS(*; $name; Round(This.cornerRadius; 0))

	End if

	return This

	// === === === === === === === === === === === === === === === === === === === === === === === === === ===
Function _lerpValue($from : Real; $to : Real; $t : Real) : Real

	return $from+(($to-$from)*$t)

	// === === === === === === === === === === === === === === === === === === === === === === === === === ===
	// Color interpolation; automatic/system colors (<0) snap at mid-course.
	// "rgb" (default) interpolates each component linearly — correct but the in-between
	// tones of two distant hues (e.g. blue → orange) are desaturated/muddy.
	// "hsv" travels the shortest hue path and keeps the in-between colors vivid.
Function _lerpColor($from : Integer; $to : Integer; $t : Real; $mode : Text) : Integer

	If (($from<0) || ($to<0))

		return ($t<0.5) ? $from : $to

	End if

	If ($mode="hsv")

		return This._lerpColorHsv($from; $to; $t)

	End if

	var $red; $green; $blue : Integer
	$red:=Round(This._lerpValue(Mod($from\65536; 256); Mod($to\65536; 256); $t); 0)
	$green:=Round(This._lerpValue(Mod($from\256; 256); Mod($to\256; 256); $t); 0)
	$blue:=Round(This._lerpValue(Mod($from; 256); Mod($to; 256); $t); 0)

	return ($red*65536)+($green*256)+$blue

	// === === === === === === === === === === === === === === === === === === === === === === === === === ===
Function _lerpColorHsv($from : Integer; $to : Integer; $t : Real) : Integer

	var $a:=This._rgbToHsv($from)
	var $b:=This._rgbToHsv($to)

	// A gray endpoint has no hue of its own: adopt the other's hue
	If ($a.s=0)
		$a.h:=$b.h
	End if

	If ($b.s=0)
		$b.h:=$a.h
	End if

	// Shortest way around the hue circle
	var $delta : Real:=$b.h-$a.h

	If ($delta>180)
		$delta:=$delta-360
	End if

	If ($delta<-180)
		$delta:=$delta+360
	End if

	var $hue : Real:=$a.h+($delta*$t)

	If ($hue<0)
		$hue:=$hue+360
	End if

	If ($hue>=360)
		$hue:=$hue-360
	End if

	return This._hsvToRgb($hue; This._lerpValue($a.s; $b.s; $t); This._lerpValue($a.v; $b.v; $t))

	// === === === === === === === === === === === === === === === === === === === === === === === === === ===
	// 0x00RRGGBB -> {h: 0-360; s: 0-1; v: 0-1}
Function _rgbToHsv($color : Integer) : Object

	var $red : Real:=Mod($color\65536; 256)/255
	var $green : Real:=Mod($color\256; 256)/255
	var $blue : Real:=Mod($color; 256)/255

	var $max : Real:=($red>$green) ? (($red>$blue) ? $red : $blue) : (($green>$blue) ? $green : $blue)
	var $min : Real:=($red<$green) ? (($red<$blue) ? $red : $blue) : (($green<$blue) ? $green : $blue)
	var $delta : Real:=$max-$min

	var $hue : Real:=0

	Case of

			//______________________________________________________
		: ($delta=0)

			$hue:=0

			//______________________________________________________
		: ($max=$red)

			$hue:=60*(($green-$blue)/$delta)

			//______________________________________________________
		: ($max=$green)

			$hue:=60*((($blue-$red)/$delta)+2)

			//______________________________________________________
		Else

			$hue:=60*((($red-$green)/$delta)+4)

			//______________________________________________________
	End case

	If ($hue<0)
		$hue:=$hue+360
	End if

	return {h: $hue; s: ($max=0) ? 0 : ($delta/$max); v: $max}

	// === === === === === === === === === === === === === === === === === === === === === === === === === ===
	// {h: 0-360; s: 0-1; v: 0-1} -> 0x00RRGGBB
Function _hsvToRgb($hue : Real; $saturation : Real; $value : Real) : Integer

	var $c : Real:=$value*$saturation
	var $sector : Real:=$hue/60
	var $mod2 : Real:=$sector-(Int($sector/2)*2)
	var $x : Real:=$c*(1-Abs($mod2-1))
	var $m : Real:=$value-$c

	var $red; $green; $blue : Real

	Case of

			//______________________________________________________
		: ($sector<1)

			$red:=$c
			$green:=$x
			$blue:=0

			//______________________________________________________
		: ($sector<2)

			$red:=$x
			$green:=$c
			$blue:=0

			//______________________________________________________
		: ($sector<3)

			$red:=0
			$green:=$c
			$blue:=$x

			//______________________________________________________
		: ($sector<4)

			$red:=0
			$green:=$x
			$blue:=$c

			//______________________________________________________
		: ($sector<5)

			$red:=$x
			$green:=0
			$blue:=$c

			//______________________________________________________
		Else

			$red:=$c
			$green:=0
			$blue:=$x

			//______________________________________________________
	End case

	var $r; $g; $b : Integer
	$r:=Round(($red+$m)*255; 0)
	$g:=Round(($green+$m)*255; 0)
	$b:=Round(($blue+$m)*255; 0)

	return ($r*65536)+($g*256)+$b
