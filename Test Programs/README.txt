

TEST PROGRAMS: 

Test 1:    Hello World
    - This is the first test, 
    - It used Kernal routines to print a screen into the screen 
        - chrin & chrout
    - prints Hello World

Test 2:   Clear Screen
    - This program iterates through screen memory 7680 - 8186 locations, displaying spaces
	  in each location which, in essence, clears the screen.

Test 3:     Character Color Change
    - This program displays a series of ball graphics to screen, changing their color each step,
	  iterating through every possible color.

    - It also first test program to use ACR, to created a wait function,
      this function places the program to wait for a certain time, to allow
      the user to see the changes of the colors

Test 4:     Screen Effects Test
    - This Program changes all colors on the screen, all character codes, and character/background/border colors 
      each iteration. It was created to see if there are callenges in making such drastic screen changes simultaneously.
    


Test 5:     Multi-Color Mode

    - This program prints a series of identical graphics at the top of the screen that use multi color mode
      It then cycles through the range of auxillary colors available when in multi color mode and each character
	  uses a different character color from the others.



Test 6:     SOUND 
    - This program outputs a fun and engaging background sound
	  It tests the ability of the Vic to play different sounds and on different speakers simultaneously.



Test 7:     Screen and Background Color Effect


Test 8:		Move Sprite
	- This program uses a kernel routine to extract key presses from the input buffer.
	  It uses this information to move a ball graphic throughout the screen spaces
	  It tests the use of the keyboard buffer to gather user input to use in a meaningful way.


Test 9:    Large Custom Sprite
	- This program draws a large custom sprite to screen. It alters the memory locations which the
	  Vic identifies with screen graphic codes to enable us to use screen codes to display custom graphics.
	  This tests the ability of the Vic to render custom graphics.


Test 10:    Interrupt Handling
	- This routine enables timer 2 interrupts, starts a countdown on timer 2, and changes the character at
	  the top left of the screen each time the interrupt occurs. Notice that you can still use the Vic
	  as the interrupt handler services IRQs intermittently. It tests the ability to use timer 2 to trigger
	  interrupts as well as the interrupt handling scheme in general.

Test 11:    Custom Sprite Animation
	- This program explores the ability of the Vic to render simple animations. Specifically it is looking for
	  visual artifacts resultant of animating medium to large amounts of graphics at one time.
	  Use the left and right keys to walk across the screen and initiate the step animation.