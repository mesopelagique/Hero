// Demo form: shared element transition between two cards + a font tween on the title

Case of 
		
		//______________________________________________________
	: (Form event code:C388=On Load:K2:1)
		
		Form:C1466.transition:=cs:C1710.ElementTransition.new()
		Form:C1466.expanded:=False:C215
		
		//______________________________________________________
	: (Form event code:C388=On Timer:K2:25)
		
		// The engine drives every running animation from here
		Form:C1466.transition.onTimer()
		
		//______________________________________________________
	: (Form event code:C388=On Clicked:K2:4)
		
		Case of 
				
				//______________________________________________________
			: (FORM Event:C1606.objectName="buttonToggle")
				
				If (Bool:C1537(Form:C1466.expanded))
					
					// Collapse: the small card flies out of the large one
					// colorMode "hsv" keeps the blue -> orange in-between tones vivid (plain RGB looks muddy/greenish)
					Form:C1466.transition.share("cardLarge"; "cardSmall"; {duration: 350; easing: "easeInOutCubic"; colorMode: "hsv"})
					Form:C1466.transition.animate("title").to({fontSize: 13}).duration(350).easing("easeInOutCubic").start()
					
				Else 
					
					// Expand: the large card flies out of the small one
					Form:C1466.transition.share("cardSmall"; "cardLarge"; {duration: 450; easing: "easeOutBack"; colorMode: "hsv"})
					Form:C1466.transition.animate("title").to({fontSize: 24}).duration(450).easing("easeOutBack").start()
					
				End if 
				
				Form:C1466.expanded:=Not:C34(Bool:C1537(Form:C1466.expanded))
				
				//______________________________________________________
		End case 
		
		//______________________________________________________
End case 
