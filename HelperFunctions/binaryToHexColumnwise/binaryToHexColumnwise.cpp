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



char getHex(string byteStr)
{
	if (byteStr == "0000")
		return '0';
	else if (byteStr == "0001")
		return '1';
	else if (byteStr == "0010")
		return '2';
	else if (byteStr == "0011")
		return '3';
	else if (byteStr == "0100")
		return '4';
	else if (byteStr == "0101")
		return '5';
	else if (byteStr == "0110")
		return '6';
	else if (byteStr == "0111")
		return '7';
	else if (byteStr == "1000")
		return '8';
	else if (byteStr == "1001")
		return '9';
	else if (byteStr == "1010")
		return 'a';
	else if (byteStr == "1011")
		return 'b';
	else if (byteStr == "1100")
		return 'c';
	else if (byteStr == "1101")
		return 'd';
	else if (byteStr == "1110")
		return 'e';
	else if (byteStr == "1111")
		return 'f';
}




int main(int argc, char** argv)
{
	size_t nBytes;
	unsigned char* data;


	if (argc != 4)
	{
		cout << "\n\nUsage: ./programName [binaryFile] [rows] [columns]\n\n\n";
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

	//******************** CONVERT BINARY TO HEX ********************

	

	int nColumns = argv[3];
	int nRows = argv[2];
	char bytes[nRows][nColumns][8];

	in.seekg(0, in.beg);

	for (int i = 0; i < nRows; i++)
	{
		int result;

		for (int j = 0; j < nColumns; j++)
		{
			in.read(bytes[i][j], 8);
			
			result = in.peek();
			while (result != '1' && result != '0' && result != EOF)
			{
				in.get();
				result = in.peek();
			}
		}
	}


	in.close();

	
	string outName = string(argv[1]);
	outName += ".hex";

	ofstream out;
	out.open(outName, ios::out | ios::binary);
	char hexVal;

	for (int j = 0; j < nColumns; j++)
	{
		out << "\t.byte\t";

		for (int i = 0; i < nRows; i++)
		{
			string byteStr;
			char hexVal;

			byteStr = "";
			for (int k = 0; k < 4; k++)
			{
				byteStr += bytes[i][j][k];
			}
			out << "$";
			hexVal = getHex(byteStr);
			out << hexVal;

			byteStr = "";
			for (int k = 4; k < 8; k++)
			{
				byteStr += bytes[i][j][k];
			}
			hexVal = getHex(byteStr);
			out << hexVal;
			out << ", ";

			
		}

		out << '\n';
	}

	out.close();

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
