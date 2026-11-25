import ctypes
import subprocess
import sys
from ctypes import c_int, c_void_p, POINTER, Structure, byref

def get_amd_gpu_temp():
    try:
        adl = ctypes.CDLL("atiadlxx.dll")
        MALLOC_CB = ctypes.CFUNCTYPE(c_void_p, c_int)
        bufs = []
        @MALLOC_CB
        def adl_malloc(size):
            b = ctypes.create_string_buffer(size)
            bufs.append(b)
            return ctypes.addressof(b)

        ctx = c_void_p()
        adl.ADL2_Main_Control_Create.argtypes = [MALLOC_CB, c_int, POINTER(c_void_p)]
        adl.ADL2_Main_Control_Create.restype = c_int
        if adl.ADL2_Main_Control_Create(adl_malloc, 1, byref(ctx)) != 0:
            return None

        class ADLSingleSensorData(Structure):
            _fields_ = [("supported", c_int), ("value", c_int)]

        class ADLPMLogDataOutput(Structure):
            _fields_ = [("size", c_int), ("sensors", ADLSingleSensorData * 256)]

        adl.ADL2_New_QueryPMLogData_Get.argtypes = [c_void_p, c_int, POINTER(ADLPMLogDataOutput)]
        adl.ADL2_New_QueryPMLogData_Get.restype = c_int

        temp = None
        for i in range(8):
            pm = ADLPMLogDataOutput()
            pm.size = ctypes.sizeof(pm)
            if adl.ADL2_New_QueryPMLogData_Get(ctx, i, byref(pm)) == 0:
                if pm.sensors[8].supported and pm.sensors[8].value > 0:
                    temp = pm.sensors[8].value
                    break
                if pm.sensors[27].supported and pm.sensors[27].value > 0:
                    temp = pm.sensors[27].value
                    break

        adl.ADL2_Main_Control_Destroy(ctx)
        return str(temp) if temp is not None else None
    except Exception:
        return None

def get_nvidia_gpu_temp():
    try:
        si = subprocess.STARTUPINFO()
        si.dwFlags |= subprocess.STARTF_USESHOWWINDOW
        out = subprocess.check_output(
            ["nvidia-smi", "--query-gpu=temperature.gpu", "--format=csv,noheader"],
            startupinfo=si,
            timeout=2,
            stderr=subprocess.DEVNULL,
        ).decode("utf-8", errors="ignore").strip().splitlines()
        if out and out[0].strip().isdigit():
            return out[0].strip()
    except Exception:
        pass
    return None

if __name__ == "__main__":
    t = get_amd_gpu_temp() or get_nvidia_gpu_temp()
    sys.stdout.write(t if t is not None else "--")
