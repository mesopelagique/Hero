// Login screen: captures its shared elements before handing over to HomeForm

Case of

		//______________________________________________________
	: (Form event code=On Load)

		Form.transition:=cs.ElementTransition.new()

		// Coming back from another form: matched elements fly from their previous state
		If (Form.hero#Null)

			Form.transition.heroFrom(Form.hero; {duration: 400; easing: "easeInOutCubic"; colorMode: "hsv"})

		End if

		//______________________________________________________
	: (Form event code=On Timer)

		Form.transition.onTimer()

		//______________________________________________________
	: (Form event code=On Clicked)

		If (FORM Event.objectName="buttonSignIn")

			// Snapshot the shared elements for the next form, then leave
			Form.hero:=Form.transition.capture(["avatar"; "userName"; "header"])
			ACCEPT

		End if

		//______________________________________________________
End case
