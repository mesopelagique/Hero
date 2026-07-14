// Home screen: plays the hero transition on load, captures back on logout

Case of

		//______________________________________________________
	: (Form event code=On Load)

		Form.transition:=cs.ElementTransition.new()

		// Matched elements (avatar, userName, header) fly from the login form state
		If (Form.hero#Null)

			Form.transition.heroFrom(Form.hero; {duration: 450; easing: "easeOutCubic"; colorMode: "hsv"})

		End if

		//______________________________________________________
	: (Form event code=On Timer)

		Form.transition.onTimer()

		//______________________________________________________
	: (Form event code=On Clicked)

		If (FORM Event.objectName="buttonLogout")

			// Snapshot the shared elements so the login form can play the reverse flight
			Form.hero:=Form.transition.capture(["avatar"; "userName"; "header"])
			ACCEPT

		End if

		//______________________________________________________
End case
