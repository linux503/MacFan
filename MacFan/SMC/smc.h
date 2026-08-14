#ifndef MACFAN_SMC_H
#define MACFAN_SMC_H

#include <IOKit/IOKitLib.h>
#include <stdint.h>

#define KERNEL_INDEX_SMC 2
#define SMC_CMD_READ_BYTES 5
#define SMC_CMD_WRITE_BYTES 6
#define SMC_CMD_READ_KEYINFO 9

#define DATATYPE_FLT  "flt "
#define DATATYPE_FPE2 "fpe2"
#define DATATYPE_UINT8 "ui8 "
#define DATATYPE_UINT16 "ui16"

typedef char UInt32Char_t[5];

typedef struct {
    UInt32Char_t key;
    UInt32 dataSize;
    UInt32Char_t dataType;
    UInt8 bytes[32];
} SMCVal_t;

typedef struct {
    UInt16 major;
    UInt16 minor;
    UInt8 build;
    UInt8 reserved[1];
    UInt16 release;
} SMCKeyData_vers_t;

typedef struct {
    UInt16 version;
    UInt16 length;
    UInt32 cpuPLimit;
    UInt32 gpuPLimit;
    UInt32 memPLimit;
} SMCKeyData_pLimitData_t;

typedef struct {
    UInt32 dataSize;
    UInt32 dataType;
    UInt8 dataAttributes;
} SMCKeyData_keyInfo_t;

typedef struct {
    UInt32 key;
    SMCKeyData_vers_t vers;
    SMCKeyData_pLimitData_t pLimitData;
    SMCKeyData_keyInfo_t keyInfo;
    UInt8 result;
    UInt8 status;
    UInt8 data8;
    UInt32 data32;
    UInt8 bytes[32];
} SMCKeyData_t;

kern_return_t MacFanSMCOpen(io_connect_t *conn);
kern_return_t MacFanSMCClose(io_connect_t conn);
int MacFanSMCFanCount(io_connect_t conn);
float MacFanSMCFanSpeed(io_connect_t conn, int fanNum);
float MacFanSMCFanMin(io_connect_t conn, int fanNum);
float MacFanSMCFanMax(io_connect_t conn, int fanNum);
float MacFanSMCFanTarget(io_connect_t conn, int fanNum);
int MacFanSMCReadFanName(io_connect_t conn, int fanNum, char *out, int outLen);
float MacFanSMCReadTemp(io_connect_t conn, const char *key);
kern_return_t MacFanSMCSetFanRPM(io_connect_t conn, int fanNum, int rpm);
kern_return_t MacFanSMCSetFanAuto(io_connect_t conn, int fanNum);

#endif
