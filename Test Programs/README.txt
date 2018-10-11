

TEST PROGRAMS: 

Test 1:		Hello World
    - It uses the kernel routines "chrin" and "chrout" to print "HELLO WORLD" to screen. 

	
Test 2:		Clear Screen
    - This program iterates through screen memory 7680 - 8186 locations, displaying spaces
	  in each location which, in essence, clears the screen.
	  
Test 3:		Timer Routine
	- This program uses one of the Vic timers to delay execution while printing characters to screen

	  
Test 4:		Character Color Change
    - This program displays a series of ball graphics to screen, changing their color each step,
	  iterating through every possible color.


Test 5:     Screen Effects Test (Crazy Screen)
    - This Program changes all colors on the screen, all character codes, and character/background/border colors 
      each iteration. It was created to see if there are callenges in making such drastic screen changes simultaneously.


Test 6:     Multi-Color Mode

    - This program prints a series of identical graphics at the top of the screen that use multi color mode
      It then cycles through the range of auxillary colors available when in multi color mode and each character
	  uses a different character color from the others.


Test 7:     SOUND 
    - This program outputs a fun and engaging background sound
	  It tests the ability of the Vic to play different sounds and on different speakers simultaneously.


Test 8:		Background and Border Color Effects
	- This program further explores the ability of the Vic to create effects that rely on background and border colors. 
      It changes these colors in ways that create a static-like effect on screen.


Test 9:		Move Sprite
	- This program uses a kernel routine to extract key presses from the input buffer.
	  It uses this information to move a ball graphic throughout the screen spaces
	  It tests the use of the keyboard buffer to gather user input to use in a meaningful way.


Test 10:	Large Custom Sprite
	- This program draws a large custom sprite to screen. It alters the memory locations which the
	  Vic identifies with screen graphic codes to enable us to use screen codes to display custom graphics.
	  This tests the ability of the Vic to render custom graphics.


Test 11:    Interrupt Handling
	- This routine enables timer 2 interrupts, starts a countdown on timer 2, and changes the character at
	  the top left of the screen each time the interrupt occurs. Notice that you can still use the Vic
	  as the interrupt handler services IRQs intermittently. It tests the ability to use timer 2 to trigger
	  interrupts as well as the interrupt handling scheme in general.

	  
Test 12:    Custom Sprite Animation
	- This program explores the ability of the Vic to render simple animations. Specifically it is looking for
	  visual artifacts resultant of animating medium to large amounts of graphics at one time.
	  Use the left and right keys to walk across the screen and initiate the step animation.