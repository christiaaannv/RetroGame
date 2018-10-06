#include <iostream>
#include <fstream>
#include <unistd.h>


using namespace std;

int main(int argc, char** argv) 
{
	size_t nBytes;
	unsigned char* data;
	char lvl1[78][20], lvl2[78][20];
	
	char nRows = 78;
	char nColumns = 20;
	
	
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

	in.seekg (0, in.end);
    nBytes = in.tellg();
    in.seekg (0, in.beg);

	data = new unsigned char[nBytes];
	in.read((char*)data, nBytes);
	in.close();

	//******************** CONVERT BINARY TO HEX ********************
	

	cout << "\t.byte\t\t";
	
	int i = 0;
	while (i < nBytes)
	{
		string byteStr = "";

		for (int j = 0; j < 4; j++)
		{
			byteStr += data[i+j];
		}
		
		switch (string)
		{
			case "0000":
				cout << '0';
				break;
			case "0001":
				cout << '1';
				break;
			case "0010":
				cout << '2';
				break;
			case "0011":
				cout << '3';
				break;
			case "0100":
				cout << '4';
				break;
			case "0101":
				cout << '5';
				break;
			case "0110":
				cout << '6';
				break;
			case "0111":
				cout << '7';
				break;
			case "1000":
				cout << '8';
				break;
			case "1001":
				cout << '9';
				break;
			case "1010":
				cout << 'a';
				break;
			case "1011":
				cout << 'b';
				break;
			case "1100":
				cout << 'c';
				break;
			case "1101":
				cout << 'd';
				break;
			case "1110":
				cout << 'e';
				break;
			case "1111":
				cout << 'f';
				break;
			default:
				break;
		}
		
		i = j;
		
		if (i%8 == 0)
		{
			cout << ", ";
		}
		
		i++;							// skip spaces and newlines
	}
	
	
	delete[] data;


	return 0;
}




