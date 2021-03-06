// Takes a file name on the command line to a set of binary bytes formatted as follows
//
//11110000 00001111 00000000 ...
//00000000 11111111 11111111 ...
//
// and writes them out to std out with '*' in place of 1s and ' ' in place of 0s
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

#include "pch.h"
#include <fstream>
#include <iostream>

using namespace std;
int main(int argc, char** argv)
{
	size_t nBytes;
	unsigned char* data;


	if (argc != 2)
	{
		cout << "\n\nUsage: ./programName [binaryFile]\n\n\n";
		return 0;
	}


	ifstream in;
	in.open(argv[1], ios::in | ios::binary);

	if (!in.is_open())
	{
		cout << "Failed to open file to fetch data chunk.\n";
		in.close();
		return 0;
	}

	in.seekg(0, in.end);
	nBytes = in.tellg();
	in.seekg(0, in.beg);

	data = new unsigned char[nBytes];
	in.read((char*)data, nBytes);
	in.close();

	//******************** CONVERT BINARY TO HEX ********************


	int bytesProcessed = 0;
	int i = 0;

	while (i < nBytes)
	{

		while (data[i] != '1' && data[i] != '0')
		{
			if (data[i] == '\n' && i < nBytes - 1  && data[i+1] != '\n')
				cout << "\n";

			i++;
		}

		if (data[i] == '1')
			cout << '*';
		else
			cout << ' ';


		i++;
	}


	delete[] data;


	return 0;
}

// Run program: Ctrl + F5 or Debug > Start Without Debugging menu
// Debug program: F5 or Debug > Start Debugging menu

// Tips for Getting Started: 
//   1. Use the Solution Explorer window to add/manage files
//   2. Use the Team Explorer window to connect to source control
//   3. Use the Output window to see build output and other messages
//   4. Use the Error List window to view errors
//   5. Go to Project > Add New Item to create new code files, or Project > Add Existing Item to add existing code files to the project
//   6. In the future, to open this project again, go to File > Open > Project and select the .sln file
