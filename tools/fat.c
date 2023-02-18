#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include "fattypes.h"
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
		       dirEntry_t *rootDir);

//TODO read file - 18:10

int main(int argc, char *argv[])
{
	if (argc < 3) {
		fprintf(stderr, "Syntax: <diskimage> <filename>\n");
		return 1;
	}

	FILE *disk = fopen(argv[1], "rb");

	bootsector_t bootsector;
	uint8_t *fat;
	dirEntry_t *rootDir;

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
	if (!readRootDirectory(disk, &bootsector, rootDir)) {
		fprintf(stderr, "Couldn't read Root Directory\n");
		free(fat);
		free(rootDir);
		return 5;
	}

	free(fat);
	free(rootDir);
	return 0;
}

bool readRootDirectory(FILE *disk, bootsector_t *bootsector,
		       dirEntry_t *rootDir)
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

	//here we used (@sectors * @bdb_bytes_per_sector) insead @size because it can only read full sectors
	rootDir = malloc(sectors * bootsector->bdb_bytes_per_sector);
	return readSectors(disk, bootsector, lba, sectors, rootDir);
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
	return fread(bootsector, 1, sizeof(bootsector_t), disk) > 0;
}
