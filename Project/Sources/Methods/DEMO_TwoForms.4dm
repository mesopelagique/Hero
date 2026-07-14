/*
Shared element transition between two REAL forms, displayed one after the
other in the same window.

Elements are matched by object name: each form snapshots its shared elements
on exit (ElementTransition.capture) and the next form makes the matching
objects fly from that snapshot when it loads (ElementTransition.heroFrom).

Sign in <-> Log out toggles between the two forms; close the window to quit.
*/
#DECLARE

var $window : Integer
$window:=Open form window("LoginForm"; Plain form window; Horizontally centered; Vertically centered)

var $form : Text:="LoginForm"
var $hero : Collection
var $data : Object

Repeat

	$data:={hero: $hero}
	DIALOG($form; $data)

	// Hand the snapshot captured by the closing form over to the next one
	$hero:=$data.hero
	$form:=($form="LoginForm") ? "HomeForm" : "LoginForm"

Until (OK=0)

CLOSE WINDOW($window)
