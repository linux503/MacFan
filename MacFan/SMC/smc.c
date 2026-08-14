#include "smc.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

static UInt32 _strtoul(const char *str, int size, int base) {
    UInt32 total = 0;
    for (int i = 0; i < size; i++) {
        if (base == 16)
            total += (UInt32)str[i] << (size - 1 - i) * 8;
        else
            total += ((unsigned char)str[i]) << (size - 1 - i) * 8;
    }
    return total;
}

static void _ultostr(char *str, UInt32 val) {
    snprintf(str, 5, "%c%c%c%c",
             (unsigned int)(val >> 24),
             (unsigned int)(val >> 16),
             (unsigned int)(val >> 8),
             (unsigned int)val);
}

static float _strtof_fpe2(unsigned char *str, int size, int e) {
    float total = 0;
    for (int i = 0; i < size; i++) {
        if (i == (size - 1))
            total += (str[i] & 0xff) >> e;
        else
            total += str[i] << (size - 1 - i) * (8 - e);
    }
    total += (str[size - 1] & 0x03) * 0.25f;
    return total;
}

static float getFloatFromVal(SMCVal_t val) {
    float fval = -1.0f;
    if (val.dataSize > 0) {
        if (strcmp(val.dataType, DATATYPE_FLT) == 0 && val.dataSize == 4) {
            memcpy(&fval, val.bytes, sizeof(float));
        } else if (strcmp(val.dataType, DATATYPE_FPE2) == 0 && val.dataSize == 2) {
            fval = _strtof_fpe2(val.bytes, val.dataSize, 2);
        } else if (strncmp(val.dataType, "fp", 2) == 0 && val.dataSize == 2) {
            fval = _strtof_fpe2(val.bytes, val.dataSize, 2);
        } else if (strncmp(val.dataType, "sp", 2) == 0 && val.dataSize == 2) {
            int16_t raw = (int16_t)((val.bytes[0] << 8) | val.bytes[1]);
            fval = raw / 256.0f;
        } else if (val.dataSize == 4) {
            memcpy(&fval, val.bytes, sizeof(float));
        } else if (val.dataSize == 2) {
            fval = _strtof_fpe2(val.bytes, val.dataSize, 2);
        } else if (val.dataSize == 1) {
            fval = (float)val.bytes[0];
        }
    }
    return fval;
}

static kern_return_t SMCCall(io_connect_t conn, int index, SMCKeyData_t *inputStructure, SMCKeyData_t *outputStructure) {
    size_t structureInputSize = sizeof(SMCKeyData_t);
    size_t structureOutputSize = sizeof(SMCKeyData_t);
    return IOConnectCallStructMethod(conn, index, inputStructure, structureInputSize, outputStructure, &structureOutputSize);
}

static kern_return_t SMCGetKeyInfo(io_connect_t conn, UInt32 key, SMCKeyData_keyInfo_t *keyInfo) {
    SMCKeyData_t inputStructure;
    SMCKeyData_t outputStructure;
    memset(&inputStructure, 0, sizeof(inputStructure));
    memset(&outputStructure, 0, sizeof(outputStructure));
    inputStructure.key = key;
    inputStructure.data8 = SMC_CMD_READ_KEYINFO;
    kern_return_t result = SMCCall(conn, KERNEL_INDEX_SMC, &inputStructure, &outputStructure);
    if (result == kIOReturnSuccess) {
        *keyInfo = outputStructure.keyInfo;
    }
    return result;
}

static kern_return_t SMCReadKey(io_connect_t conn, const char *key, SMCVal_t *val) {
    SMCKeyData_t inputStructure;
    SMCKeyData_t outputStructure;
    memset(&inputStructure, 0, sizeof(inputStructure));
    memset(&outputStructure, 0, sizeof(outputStructure));
    memset(val, 0, sizeof(SMCVal_t));

    inputStructure.key = _strtoul(key, 4, 16);
    snprintf(val->key, sizeof(val->key), "%s", key);

    kern_return_t result = SMCGetKeyInfo(conn, inputStructure.key, &outputStructure.keyInfo);
    if (result != kIOReturnSuccess) return result;

    val->dataSize = outputStructure.keyInfo.dataSize;
    _ultostr(val->dataType, outputStructure.keyInfo.dataType);
    inputStructure.keyInfo.dataSize = val->dataSize;
    inputStructure.data8 = SMC_CMD_READ_BYTES;

    result = SMCCall(conn, KERNEL_INDEX_SMC, &inputStructure, &outputStructure);
    if (result != kIOReturnSuccess) return result;

    memcpy(val->bytes, outputStructure.bytes, sizeof(outputStructure.bytes));
    return kIOReturnSuccess;
}

static kern_return_t SMCWriteKey(io_connect_t conn, SMCVal_t writeVal) {
    SMCVal_t readVal;
    kern_return_t result = SMCReadKey(conn, writeVal.key, &readVal);
    if (result != kIOReturnSuccess) return result;
    if (readVal.dataSize != writeVal.dataSize) return kIOReturnError;

    SMCKeyData_t inputStructure;
    SMCKeyData_t outputStructure;
    memset(&inputStructure, 0, sizeof(inputStructure));
    memset(&outputStructure, 0, sizeof(outputStructure));
    inputStructure.key = _strtoul(writeVal.key, 4, 16);
    inputStructure.data8 = SMC_CMD_WRITE_BYTES;
    inputStructure.keyInfo.dataSize = writeVal.dataSize;
    memcpy(inputStructure.bytes, writeVal.bytes, sizeof(writeVal.bytes));
    return SMCCall(conn, KERNEL_INDEX_SMC, &inputStructure, &outputStructure);
}

kern_return_t MacFanSMCOpen(io_connect_t *conn) {
    mach_port_t masterPort = 0;
    io_iterator_t iterator = 0;
    io_object_t device = 0;

    IOMainPort(MACH_PORT_NULL, &masterPort);
    CFMutableDictionaryRef matchingDictionary = IOServiceMatching("AppleSMC");
    kern_return_t result = IOServiceGetMatchingServices(masterPort, matchingDictionary, &iterator);
    if (result != kIOReturnSuccess) return result;

    device = IOIteratorNext(iterator);
    IOObjectRelease(iterator);
    if (device == 0) return kIOReturnNotFound;

    result = IOServiceOpen(device, mach_task_self(), 0, conn);
    IOObjectRelease(device);
    return result;
}

kern_return_t MacFanSMCClose(io_connect_t conn) {
    return IOServiceClose(conn);
}

int MacFanSMCFanCount(io_connect_t conn) {
    SMCVal_t val;
    if (SMCReadKey(conn, "FNum", &val) != kIOReturnSuccess) return 0;
    return (int)_strtoul((char *)val.bytes, (int)val.dataSize, 10);
}

float MacFanSMCFanSpeed(io_connect_t conn, int fanNum) {
    SMCVal_t val;
    char key[8];
    snprintf(key, sizeof(key), "F%dAc", fanNum);
    if (SMCReadKey(conn, key, &val) != kIOReturnSuccess) return -1;
    return getFloatFromVal(val);
}

float MacFanSMCFanMin(io_connect_t conn, int fanNum) {
    SMCVal_t val;
    char key[8];
    snprintf(key, sizeof(key), "F%dMn", fanNum);
    if (SMCReadKey(conn, key, &val) != kIOReturnSuccess) return -1;
    return getFloatFromVal(val);
}

float MacFanSMCFanMax(io_connect_t conn, int fanNum) {
    SMCVal_t val;
    char key[8];
    snprintf(key, sizeof(key), "F%dMx", fanNum);
    if (SMCReadKey(conn, key, &val) != kIOReturnSuccess) return -1;
    return getFloatFromVal(val);
}

float MacFanSMCFanTarget(io_connect_t conn, int fanNum) {
    SMCVal_t val;
    char key[8];
    snprintf(key, sizeof(key), "F%dTg", fanNum);
    if (SMCReadKey(conn, key, &val) != kIOReturnSuccess) return -1;
    return getFloatFromVal(val);
}

int MacFanSMCReadFanName(io_connect_t conn, int fanNum, char *out, int outLen) {
    if (!out || outLen < 2) return -1;
    out[0] = '\0';

    SMCVal_t val;
    char key[8];
    snprintf(key, sizeof(key), "F%dID", fanNum);
    if (SMCReadKey(conn, key, &val) != kIOReturnSuccess) return -1;
    if (val.dataSize < 2 || val.dataSize > 32) return -1;

    int len = (unsigned char)val.bytes[0];
    if (len <= 0) return -1;
    if (len > (int)val.dataSize - 1) len = (int)val.dataSize - 1;
    if (len > outLen - 1) len = outLen - 1;
    if (len <= 0) return -1;

    memcpy(out, &val.bytes[1], (size_t)len);
    out[len] = '\0';
    return 0;
}

float MacFanSMCReadTemp(io_connect_t conn, const char *key) {
    SMCVal_t val;
    if (SMCReadKey(conn, key, &val) != kIOReturnSuccess) return -1;
    return getFloatFromVal(val);
}

static const char *fanModeTemplate(io_connect_t conn) {
    static char tmpl[8] = "";
    if (tmpl[0] == '\0') {
        SMCKeyData_keyInfo_t ki;
        if (SMCGetKeyInfo(conn, _strtoul("F0Md", 4, 16), &ki) == kIOReturnSuccess && ki.dataSize > 0)
            strcpy(tmpl, "F%dMd");
        else
            strcpy(tmpl, "F%dmd");
    }
    return tmpl;
}

static void fanModeKey(char *buf, size_t buflen, int fanNum, io_connect_t conn) {
    snprintf(buf, buflen, fanModeTemplate(conn), fanNum);
}

static int ftstAvailable(io_connect_t conn) {
    static int checked = 0, avail = 0;
    if (!checked) {
        SMCKeyData_keyInfo_t ki;
        avail = (SMCGetKeyInfo(conn, _strtoul("Ftst", 4, 16), &ki) == kIOReturnSuccess && ki.dataSize > 0);
        checked = 1;
    }
    return avail;
}

static void writeFtst(io_connect_t conn, int value) {
    SMCKeyData_keyInfo_t ki;
    UInt32 key = _strtoul("Ftst", 4, 16);
    if (SMCGetKeyInfo(conn, key, &ki) != kIOReturnSuccess || ki.dataSize < 1) return;
    SMCKeyData_t in, out;
    memset(&in, 0, sizeof(in));
    memset(&out, 0, sizeof(out));
    in.key = key;
    in.data8 = SMC_CMD_WRITE_BYTES;
    in.keyInfo.dataSize = ki.dataSize;
    in.bytes[0] = (UInt8)value;
    SMCCall(conn, KERNEL_INDEX_SMC, &in, &out);
}

static int writeFanModeRaw(io_connect_t conn, int fanNum, int mode) {
    char keyStr[8];
    fanModeKey(keyStr, sizeof(keyStr), fanNum, conn);
    UInt32 key = _strtoul(keyStr, 4, 16);
    SMCKeyData_keyInfo_t ki;
    if (SMCGetKeyInfo(conn, key, &ki) != kIOReturnSuccess || ki.dataSize != 1) return -1;
    SMCKeyData_t in, out;
    memset(&in, 0, sizeof(in));
    memset(&out, 0, sizeof(out));
    in.key = key;
    in.data8 = SMC_CMD_WRITE_BYTES;
    in.keyInfo.dataSize = 1;
    in.bytes[0] = (UInt8)mode;
    if (SMCCall(conn, KERNEL_INDEX_SMC, &in, &out) != kIOReturnSuccess) return -1;
    return out.result;
}

static int readFanModeRaw(io_connect_t conn, int fanNum) {
    char key[8];
    fanModeKey(key, sizeof(key), fanNum, conn);
    SMCVal_t val;
    if (SMCReadKey(conn, key, &val) != kIOReturnSuccess || val.dataSize != 1) return -1;
    return val.bytes[0];
}

static kern_return_t unlockFanManual(io_connect_t conn, int fanNum) {
    writeFanModeRaw(conn, fanNum, 1);
    usleep(200000);
    if (readFanModeRaw(conn, fanNum) == 1) return kIOReturnSuccess;

    if (ftstAvailable(conn)) {
        writeFtst(conn, 1);
        usleep(500000);
        for (int i = 0; i < 100; i++) {
            writeFanModeRaw(conn, fanNum, 1);
            usleep(100000);
            if (readFanModeRaw(conn, fanNum) == 1) return kIOReturnSuccess;
        }
    }
    return kIOReturnError;
}

kern_return_t MacFanSMCSetFanRPM(io_connect_t conn, int fanNum, int rpm) {
    if (rpm < 0) rpm = 0;
    float fmax = MacFanSMCFanMax(conn, fanNum);
    if (fmax > 0 && rpm > (int)fmax) rpm = (int)fmax;

    if (unlockFanManual(conn, fanNum) != kIOReturnSuccess) return kIOReturnError;

    SMCVal_t val;
    char key[8];
    snprintf(key, sizeof(key), "F%dTg", fanNum);
    kern_return_t result = SMCReadKey(conn, key, &val);
    if (result != kIOReturnSuccess) return result;

    if (strcmp(val.dataType, DATATYPE_FLT) == 0 && val.dataSize == 4) {
        float fspeed = (float)rpm;
        memcpy(val.bytes, &fspeed, sizeof(float));
    } else if ((strcmp(val.dataType, DATATYPE_FPE2) == 0 || strncmp(val.dataType, "fp", 2) == 0) && val.dataSize == 2) {
        UInt16 encoded = (UInt16)(rpm << 2);
        val.bytes[0] = (encoded >> 8) & 0xFF;
        val.bytes[1] = encoded & 0xFF;
    } else if (val.dataSize == 4) {
        float fspeed = (float)rpm;
        memcpy(val.bytes, &fspeed, sizeof(float));
    } else {
        return kIOReturnError;
    }

    snprintf(val.key, sizeof(val.key), "%s", key);
    return SMCWriteKey(conn, val);
}

kern_return_t MacFanSMCSetFanAuto(io_connect_t conn, int fanNum) {
    SMCVal_t val;
    char key[8];
    fanModeKey(key, sizeof(key), fanNum, conn);
    kern_return_t result = SMCReadKey(conn, key, &val);
    if (result == kIOReturnSuccess && val.dataSize == 1) {
        val.bytes[0] = 0;
        snprintf(val.key, sizeof(val.key), "%s", key);
        result = SMCWriteKey(conn, val);
    }
    if (ftstAvailable(conn)) writeFtst(conn, 0);
    return result;
}
