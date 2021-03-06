// Takes a file name on the command line to a set of binary bytes formatted as follows
//
//11110000 00001111 00000000 ...
//00000000 11111111 11111111 ...
//
// and writes them out to file as byte sized hex values that can be used by dasm assembler
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


	ofstream out;
	out.open("out", ios::out | ios::binary);

	out << "\t.byte\t";

	int bytesProcessed = 0;
	int i = 0;
	bool byteStart = true;
	while (i < nBytes - 3)
	{
		string byteStr = "";

		while (data[i] != '1' && data[i] != '0')
		{
			if (data[i] == '\n')
				out << "\n\t.byte\t";

			i++;
		}

		if (byteStart)
			out << '$';

		for (int j = 0; j < 4; j++)
		{
			byteStr += data[i + j];
		}

		byteStart = !byteStart;

//		cout << byteStr.c_str() << endl;


		if (byteStr == "0000")
			out << '0';
		else if (byteStr == "0001")
			out << '1';
		else if (byteStr == "0010")
			out << '2';
		else if (byteStr == "0011")
			out << '3';
		else if (byteStr == "0100")
			out << '4';
		else if (byteStr == "0101")
			out << '5';
		else if (byteStr == "0110")
			out << '6';
		else if (byteStr == "0111")
			out << '7';
		else if (byteStr == "1000")
			out << '8';
		else if (byteStr == "1001")
			out << '9';
		else if (byteStr == "1010")
			out << 'a';
		else if (byteStr == "1011")
			out << 'b';
		else if (byteStr == "1100")
			out << 'c';
		else if (byteStr == "1101")
			out << 'd';
		else if (byteStr == "1110")
			out << 'e';
		else if (byteStr == "1111")
			out << 'f';

		i += 4;

		if (byteStart)
		{
			if (data[i] != '\n' && data[i+1] != '\n')
				out << ", ";
		}



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
