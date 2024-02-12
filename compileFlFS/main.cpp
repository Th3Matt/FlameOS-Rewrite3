#include <iostream>
#include <fstream>
#include <string>

#define FILE_NAME_LENGTH 15
#define KERNEL_SIZE 0x40
#define DESCRIPTOR_SIZE 0x1A
#define STARTUP_FILE 0x1

struct File
{
  char flags;
  std::string name;
  char terminator = 0;
  char userID;
};

std::string executable;

void printLog(std::string string)
{
  std::cout << executable << ": " << string << "\n";
}

int main(int argc, char* argv[])
{
  executable = argv[0];
  std::ifstream configFile;
  configFile.open("FlFS.conf", std::ios::in);

  int lines = 0;
  std::string readString;

  while (!configFile.eof())
  {
      char a;
      configFile.get(a);
      //std::cout << (int)a << " ";
      if (a == '\n') lines++;
  }

  lines--;
  configFile.clear();
  configFile.seekg(0);

  File files[lines];

  for (int i=0;i<lines;i++)
  {
    std::getline(configFile, files[i].name, ' ');

    char flags = 1;
    configFile >> readString;
    if (readString[0] == 'e') flags |= 0b100;

    files[i].flags = flags;

    int userID;
    configFile >> userID;
    files[i].userID = (char)userID;

    configFile.get(flags); // discarding newline

    printLog((std::string)"Found entry " + files[i].name + ".");
  }

  configFile.close();

  printLog("Config read.");

  std::ofstream FSBinFile;
  FSBinFile.open("Builds/FS.bin", std::ios::out|std::ios::binary);

  char dword[4];
  *((int*)dword) = 0x41045015;
  FSBinFile.write(dword, 4);         // Correct FlFS 0.2 signature

  FSBinFile << (char)STARTUP_FILE;                       // Autorun file index
  int descriptorSectorSize = (int)((float)(DESCRIPTOR_SIZE*(lines+1))/0x200)+1;
  FSBinFile << (char)descriptorSectorSize;    // Ammount of file descriptor sectors
  ((int*)dword)[0] = 1024*2-1;
  FSBinFile.write(dword, 4);           // FS size in sectors

  for (int i=0;i<(512-4-1-1-4);i++)
  {
    FSBinFile << (char)0;
  }

  printLog("Info sector formed.");

  FSBinFile << (char)5;
  FSBinFile.write("64Boot.sb\0\0\0\0\0\0", FILE_NAME_LENGTH);
  FSBinFile << (char)0;
  FSBinFile << (char)0;

  *(int*)dword = KERNEL_SIZE;
  FSBinFile.write(dword, 4);

  *(int*)dword = 0x1;
  FSBinFile.write(dword, 4);

  std::ifstream binaries[lines];
  int currentSector = KERNEL_SIZE+1+1+descriptorSectorSize;

  for (int i=0;i<lines;i++)
  {
    binaries[i].open(*(new std::string("Builds/")) + files[i].name, std::ios::in);
    if (!binaries[i].is_open())
    {
      printLog((std::string)"Couldn't open file: Builds/" + files[i].name + ".");
      continue;
    }
    FSBinFile << files[i].flags;
    FSBinFile << files[i].name.append(FILE_NAME_LENGTH-files[i].name.length(), '\0');
    FSBinFile << (char)0;
    FSBinFile << files[i].userID;

    binaries[i].seekg(0, std::ios::end);

    *(int*)dword = binaries[i].tellg()/0x200;
    FSBinFile.write(dword, 4);

    *(int*)dword = currentSector;
    FSBinFile.write(dword, 4);
    currentSector += binaries[i].tellg()/0x200;
  }

  for (int i=0;i<(0x200*descriptorSectorSize-(DESCRIPTOR_SIZE*(lines+1)));i++)
  {
    FSBinFile << (char)0;
  }

  printLog((std::string)"Descriptor sectors created with " + std::to_string(lines+1) + " descriptors.");

  for (int i=0;i<lines;i++)
  {
    if (!binaries[i].is_open()) continue;
    int size = binaries[i].tellg();
    char buffer[size];

    binaries[i].seekg(0);

    binaries[i].read(buffer, size);
    FSBinFile.write(buffer, size);
    binaries[i].close();
  }

  FSBinFile.close();
}
