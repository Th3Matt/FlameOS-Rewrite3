#include <iostream>
#include <fstream>
#include <string.h>

#define FILE_NAME_LENGTH 15
#define KERNEL_SIZE 0x40
#define DESCRIPTOR_SIZE 0x1A
#define STARTUP_FILE 0x1

struct File
{
    char flags;
    char name[FILE_NAME_LENGTH] = {0};
    char terminator = 0;
    char userID;
};

int main()
{
    std::ifstream configFile;
    configFile.open("FlFS.conf", std::ios::in);

    int lines = 0;
    char readString[FILE_NAME_LENGTH];

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

        {
            int k = 0;
            std::string string(files[i].name);
            std::getline(configFile, string, ' ');
            strcpy(files[i].name, string.c_str());
        }

        char flags = 1;
        configFile >> readString[0];
        if (readString[0] == 'e') flags |= 0b100;

        files[i].flags = flags;

        int userID;
        configFile >> userID;
        files[i].userID = (char)userID;

        configFile.get(flags); // discarding newline

        //std::cout << files[i].name << "\n";
    }

    configFile.close();

    std::cout << "Config read.\n";

    std::ofstream FSBinFile;
    FSBinFile.open("Builds/FS.bin", std::ios::out|std::ios::binary);

    ((int*)readString)[0] = 0x41045015;
    FSBinFile.write(readString, 4);         // Correct FlFS 0.2 signature

    FSBinFile << (char)STARTUP_FILE;                       // Autorun file index
    int descriptorSectorSize = (int)((float)(DESCRIPTOR_SIZE*(lines+1))/0x200)+1;
    FSBinFile << (char)descriptorSectorSize;    // Ammount of file descriptor sectors
    ((int*)readString)[0] = 1024*2-1;
    FSBinFile.write(readString, 4);           // FS size in sectors

    for (int i=0;i<(512-4-1-1-4);i++)
    {
        FSBinFile << (char)0;
    }

    std::cout << "Info sector formed.\n";

    FSBinFile << (char)5;
    FSBinFile.write("64Boot.sb\0\0\0\0\0\0", FILE_NAME_LENGTH);
    FSBinFile << (char)0;
    FSBinFile << (char)0;

    char dword[4] = {0};

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
            std::cout << "Couldn't open file: Builds/" << files[i].name << ".\n";
            continue;
        }
        FSBinFile << files[i].flags;
        FSBinFile.write(files[i].name, FILE_NAME_LENGTH);
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

    std::cout << "Descriptor sectors created with " << lines+1 << " descriptors.\n";

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
