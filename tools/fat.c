#include <ctype.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include "fattypes.h"
#include <string.h> //memcmp()
//define a type boolean
typedef enum { false, true } bool;

//read @bootsector from @disk
bool readBootSector(FILE *disk, bootsector_t *bootsector);

//read sectors from @disk and save in @buffer
bool readSectors(FILE *disk, bootsector_t *bootsector, uint32_t lba,
		 uint32_t count, void *buffer);

//read FAT table from disk using @fat variable as a buffer
bool readFat(FILE *disk, bootsector_t *bootsector, uint8_t *fat);

bool readRootDirectory(FILE *disk, bootsector_t *bootsector,
		       uint32_t *rootDirEnd, dirEntry_t **rootDir);

dirEntry_t *findFile(const char *name, bootsector_t *bootsector,
		     dirEntry_t *rootDir);

bool readFile(FILE *disk, dirEntry_t *fileEntry, bootsector_t *bootsector,
	      uint32_t *rootDirEnd, uint8_t *fat, uint8_t *buffer);

int main(int argc, char *argv[])
{
	if (argc < 3) {
		fprintf(stderr, "Syntax: <diskimage> <filename>\n");
		return 1;
	}

	FILE *disk = fopen(argv[1], "rb");

	bootsector_t bootsector;
	uint8_t *fat = NULL;
	dirEntry_t *rootDir = NULL;
	uint32_t rootDirEnd;

	if (!disk) {
		fprintf(stderr, "Couldn't open disk image %s\n", argv[1]);
		return 2;
	}
	if (!readBootSector(disk, &bootsector)) {
		fprintf(stderr, "Couldn't read bootsector\n");
		return 3;
	}
	if (!readFat(disk, &bootsector, fat)) {
		fprintf(stderr, "Couldn't read FAT\n");
		free(fat);
		return 4;
	}
	if (!readRootDirectory(disk, &bootsector, &rootDirEnd, &rootDir)) {
		fprintf(stderr, "Couldn't read Root Directory\n");
		free(fat);
		free(rootDir);
		return 5;
	}

	dirEntry_t *fileEntry = findFile(argv[2], &bootsector, rootDir);
	if (!fileEntry) {
		fprintf(stderr, "Couldn't find file %s", argv[2]);
		free(fat);
		free(rootDir);
		return 6;
	}

	uint8_t *buffer = (uint8_t *)malloc(fileEntry->size +
					    bootsector.bdb_bytes_per_sector);
	if (!readFile(disk, fileEntry, &bootsector, &rootDirEnd, fat, buffer)) {
		fprintf(stderr, "Could not read file %s!\n", argv[2]);
		free(fat);
		free(rootDir);
		free(buffer);
		return 7;
	}

	for (size_t i = 0; i < fileEntry->size; i++) {
		if (isprint(buffer[i]))
			fputc(buffer[i], stdout);
		else
			printf("<%02x>", buffer[i]);
	}
	printf("\n");

	free(buffer);
	free(fat);
	free(rootDir);
	return 0;
}

bool readFile(FILE *disk, dirEntry_t *fileEntry, bootsector_t *bootsector,
	      uint32_t *rootDirEnd, uint8_t *fat, uint8_t *buffer)
{
	bool ret = true;
	uint16_t curCluster = fileEntry->firstClusterLow;
	do {
		//Fist 2 clusters are reserved
		uint32_t lba =
			*rootDirEnd +
			(curCluster - 2) * bootsector->bdb_sectors_per_cluster;

		ret = readSectors(disk, bootsector, lba,
				  bootsector->bdb_sectors_per_cluster, buffer);
		break;

		//walks in memory
		buffer += bootsector->bdb_sectors_per_cluster *
			  bootsector->bdb_bytes_per_sector;

		// converts 16bits to 12 bits wide
		uint32_t fatIndex = curCluster * 3 / 2;
		if (curCluster % 2 == 0)
			curCluster = (*(uint16_t *)(fat + fatIndex)) & 0x0FFF;
		else
			curCluster = (*(uint16_t *)(fat + fatIndex)) >> 4;
	} while (ret && curCluster < 0x0FF8);
	return ret;
}

dirEntry_t *findFile(const char *name, bootsector_t *bootsector,
		     dirEntry_t *rootDir)
{
	for (uint32_t i = 0; i < bootsector->bdb_dir_entries_count; i++)
		if (!memcmp(name, rootDir[i].name,
			    /* NAME_MAX * sizeof(uint8_t) */ 11))
			return &rootDir[i];

	return NULL;
}

bool readRootDirectory(FILE *disk, bootsector_t *bootsector,
		       uint32_t *rootDirEnd, dirEntry_t **rootDir)
{
	//set index after reserved region and fat tables region
	uint32_t lba =
		bootsector->bdb_reserved_sectors +
		(bootsector->bdb_fat_count * bootsector->bdb_sectors_per_fat);
	//find the size of Root Directory
	uint32_t size = sizeof(dirEntry_t) * bootsector->bdb_dir_entries_count;
	//find how many sectors it needs, ...
	uint32_t sectors = size / bootsector->bdb_bytes_per_sector;

	//rounding it up.
	if (size % bootsector->bdb_bytes_per_sector)
		sectors++;

	//just to not repeat the calc
	*rootDirEnd = sectors + lba;

	//here we used (@sectors * @bdb_bytes_per_sector) insead @size because it can only read full sectors
	*rootDir = malloc(sectors * bootsector->bdb_bytes_per_sector);
	return readSectors(disk, bootsector, lba, sectors, *rootDir);
}

bool readSectors(FILE *disk, bootsector_t *bootsector, uint32_t lba,
		 uint32_t count, void *buffer)
{
	//lba - index of sectors to read or write
	//jump to byte where lba is indexed to
	return !fseek(disk, lba * bootsector->bdb_bytes_per_sector, SEEK_SET) &&
	       //read @count sectors
	       fread(buffer, bootsector->bdb_bytes_per_sector, count, disk) ==
		       count;
}

bool readFat(FILE *disk, bootsector_t *bootsector, uint8_t *fat)
{
	//allocate bytes to fat table
	fat = (uint8_t *)malloc(bootsector->bdb_sectors_per_fat *
				bootsector->bdb_bytes_per_sector);
	// bdb_reserved_sectors == lba since we need to read outside reserved region
	return readSectors(disk, bootsector, bootsector->bdb_reserved_sectors,
			   bootsector->bdb_sectors_per_fat, fat);
}

bool readBootSector(FILE *disk, bootsector_t *bootsector)
{
	return fread(bootsector, sizeof(bootsector_t), 1, disk) > 0;
}
