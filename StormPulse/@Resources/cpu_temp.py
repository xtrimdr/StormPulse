import ctypes
import os
import sys
from ctypes import c_uint32, c_uint64, c_size_t, c_void_p, c_float, c_ubyte, c_char, Structure, byref

RES_DIR = os.path.dirname(os.path.abspath(__file__))

def get_pawnio_ryzen_temp():
    """Reads AMD Ryzen Tctl directly via PawnIO (SMN 0x59800). Requires Rainmeter as admin."""
    dll_path = os.path.expandvars(r"%ProgramFiles%\PawnIO\PawnIOLib.dll")
    bin_path = os.path.join(RES_DIR, "AMDFamily17.bin")
    if not os.path.exists(dll_path) or not os.path.exists(bin_path):
        return None
    try:
        lib = ctypes.WinDLL(dll_path)
        h = c_void_p()
        if lib.pawnio_open(byref(h)) != 0:
            return None
        try:
            with open(bin_path, "rb") as f:
                blob = f.read()
            if lib.pawnio_load(h, blob, len(blob)) != 0:
                return None
            inp = (c_uint64 * 1)(0x00059800)
            out = (c_uint64 * 1)(0)
            n = c_size_t(0)
            if lib.pawnio_execute(h, b"ioctl_read_smn", inp, 1, out, 1, byref(n)) != 0 or n.value == 0:
                return None
            v = out[0] & 0xFFFFFFFF
            milli = (v >> 21) * 125
            if v & (1 << 19):
                milli -= 49000
            return str((milli + 500) // 1000)
        finally:
            ctypes.windll.kernel32.CloseHandle(h)
    except Exception:
        return None

class CoreTempSharedData(Structure):
    _fields_ = [
        ("uiLoad", c_uint32 * 256),
        ("uiTjMax", c_uint32 * 128),
        ("uiCoreCnt", c_uint32),
        ("uiCPUCnt", c_uint32),
        ("fTemp", c_float * 256),
        ("fVID", c_float),
        ("fCPUSpeed", c_float),
        ("fFSBSpeed", c_float),
        ("fMultiplier", c_float),
        ("sCPUName", c_char * 100),
        ("ucFahrenheit", c_ubyte),
        ("ucDeltaToTjMax", c_ubyte),
    ]

def get_coretemp():
    """Reads Core Temp shared memory if Core Temp is running."""
    try:
        k32 = ctypes.windll.kernel32
        FILE_MAP_READ = 0x0004
        h = k32.OpenFileMappingW(FILE_MAP_READ, False, "CoreTempMappingObject")
        if not h:
            return None
        try:
            ptr = k32.MapViewOfFile(h, FILE_MAP_READ, 0, 0, ctypes.sizeof(CoreTempSharedData))
            if not ptr:
                return None
            try:
                ct = ctypes.cast(ptr, ctypes.POINTER(CoreTempSharedData)).contents
                cnt = min(ct.uiCoreCnt * (ct.uiCPUCnt or 1), 256)
                if cnt == 0:
                    return None
                best = -1000.0
                for i in range(cnt):
                    t = ct.fTemp[i]
                    if ct.ucDeltaToTjMax:
                        t = float(ct.uiTjMax[i // max(ct.uiCoreCnt, 1)]) - t
                    if t > best:
                        best = t
                if ct.ucFahrenheit:
                    best = (best - 32.0) * 5.0 / 9.0
                if best > -100.0:
                    return str(int(best + 0.5))
            finally:
                k32.UnmapViewOfFile(ptr)
        finally:
            k32.CloseHandle(h)
    except Exception:
        return None
    return None

if __name__ == "__main__":
    t = get_pawnio_ryzen_temp() or get_coretemp()
    sys.stdout.write(t if t is not None else "--")
