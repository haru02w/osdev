#include <inttypes.h>

/*
 * Define structure of header data of FAT12
 */
typedef struct {
#define JMP_SIZE 3
	//JMP SHORT instruction
	uint8_t jmp[JMP_SIZE];
#define OEM_SIZE 8
	//name of bootsector
	uint8_t bdb_oem[OEM_SIZE];
	//sector - pizza slices of disk
	uint16_t bdb_bytes_per_sector;
	// cluster - unit of allocation. Define the minimum size of a file in disk
	uint8_t bdb_sectors_per_cluster;
	// reserved_sectors - includes boot sector
	uint16_t bdb_reserved_sectors;
	//number of file allocation tables
	uint8_t bdb_fat_count;
	// define numbers of fat entries in tables (maximum number of files)
	uint16_t bdb_dir_entries_count;
	// define the size of disk
	uint16_t bdb_total_sectors;
	// define type of disk
	uint8_t bdb_media_descriptor_type;
	// size of fat tables
	uint16_t bdb_sectors_per_fat;
	// size of a track (height)
	uint16_t bdb_sectors_per_track;
	// how many heads the disk have
	uint16_t bdb_heads;
	//
	uint32_t bdb_hidden_sectors;
	uint32_t bdb_large_sector_count;

	//Extended Boot Record

	uint8_t ebr_drive_number; // BIOS will give it
	uint8_t ebr_reserved;

	uint8_t ebr_signature; // MUST BE 0x28 or 0x29 - reserved

	uint32_t ebr_volume_id; // serial number - can be anything

#define VOLUME_LABEL_SIZE 11
	uint8_t ebr_volume_label[VOLUME_LABEL_SIZE];
#define SYS_ID_SIZE 8
	uint8_t ebr_system_id[SYS_ID_SIZE];
} __attribute__((packed)) bootsector_t;

//__attribute__((packed)) is used to disable compiler padding

typedef struct {
#define NAME_MAX 11
	uint8_t name[NAME_MAX];

	//possible attributes:
	//READ_ONLY=0x01 HIDDEN=0x02 SYSTEM=0x04 VOLUME_ID=0x08 DIRECTORY=0x10 ARCHIVE=0x20 LFN=READ_ONLY|HIDDEN|SYSTEM|VOLUME_ID
	uint8_t attributes;
	uint8_t reserved;
	uint8_t creationTimeInTenths;

	//hour - 5 bits | min - 6 bits | sec - 5 bits
	uint16_t createdTime;

	//Year - 7 bits | month - 4 bits | day - 5 bits
	uint16_t createdDate;
	//Year - 7 bits | month - 4 bits | day - 5 bits
	uint16_t lastAccessedDate;

	// as we are using FAT12, it's always 0
	uint16_t firstClusterHigh;
	//hour - 5 bits | min - 6 bits | sec - 5 bits
	uint16_t lastModTime;
	//Year - 7 bits | month - 4 bits | day - 5 bits
	uint16_t lastModDate;

	uint16_t firstClusterLow;
	uint32_t size;
} __attribute__((packed)) dirEntry_t;
