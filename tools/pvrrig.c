/* pvrrig.exe poke ADDR=VALUE... : write dwords into the running vonpvr.exe
   pvrrig.exe post MSG WPARAM     : post a message to its window
   The helper tools/pvrrig.py runs under Wine. */
#include <windows.h>
#include <tlhelp32.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static HWND found;

static BOOL CALLBACK each(HWND h, LPARAM l)
{
    char c[128] = "";
    (void) l;
    GetClassNameA(h, c, 127);
    if (IsWindowVisible(h) && strcmp(c, "Shell_TrayWnd") && !found)
        found = h;
    return TRUE;
}

static DWORD game(void)
{
    PROCESSENTRY32 e;
    HANDLE s = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
    DWORD pid = 0;

    e.dwSize = sizeof e;
    if (Process32First(s, &e))
        do
            if (!lstrcmpiA(e.szExeFile, "vonpvr.exe"))
                pid = e.th32ProcessID;
        while (Process32Next(s, &e));
    return pid;
}

int main(int n, char **a)
{
    if (n > 3 && !strcmp(a[1], "post")) {
        EnumWindows(each, 0);
        if (!found)
            return 1;
        PostMessageA(found, strtoul(a[2], 0, 0), strtoul(a[3], 0, 0), 0);
        return 0;
    }
    if (n > 2 && !strcmp(a[1], "poke")) {
        HANDLE p = OpenProcess(PROCESS_ALL_ACCESS, 0, game());
        int i;

        if (!p)
            return 1;
        for (i = 2; i < n; i++) {
            char *eq = strchr(a[i], '=');
            DWORD v = strtoul(eq + 1, 0, 0);
            SIZE_T done = 0;

            *eq = 0;
            WriteProcessMemory(p, (void *) strtoul(a[i], 0, 0), &v, 4, &done);
        }
        return 0;
    }
    return 2;
}
