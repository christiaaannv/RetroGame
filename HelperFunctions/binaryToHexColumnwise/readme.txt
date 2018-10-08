// Takes a file name on the command line to a set of binary bytes formatted as follows
//
//11110000 00001111 00000000 ...
//00000000 11111111 11111111 ...
//
// and writes them out to file as byte sized hex values that can be used by dasm assembler
//
// This program will operate columnwise - it will print the values of the first column, then the second column, and so on
// Each column will be printed on a new line prefixed by .byte and each byte will be separated by commas.
//
//
//
// The input above would result in the output file..
//
//	.byte	$f0, $0f, $00
//	.byte	$00, $ff, $ff
//
//
// Note that the input file must contain 1s, 0s, spaces and newlines only and each string of binary
// must be 8 digits long with no preceeding spaces. The input file should end with one new line at the end.
//