#include <windows.h>
#include <wininet.h>
#include <iostream>
#include <string>

#pragma comment(lib, "wininet.lib")

// Sets Windows system SOCKS5 proxy via WinINet API.
bool SetWindowsSystemProxy(const std::wstring& proxyAddr) {
    INTERNET_PER_CONN_OPTION_LIST list;
    INTERNET_PER_CONN_OPTION options[3];
    DWORD dwBufSize = sizeof(list);

    list.dwSize = sizeof(list);
    list.pszConnection = NULL; // Default connection (LAN / Dial-up)
    list.dwOptionCount = 3;
    list.pOptions = options;

    // Option 1: Enable proxy
    options[0].dwOption = INTERNET_PER_CONN_FLAGS;
    options[0].Value.dwValue = PROXY_TYPE_PROXY | PROXY_TYPE_DIRECT;

    // Option 2: Proxy server address (e.g. "socks=127.0.0.1:1080")
    std::wstring fullProxyString = L"socks=" + proxyAddr;
    options[1].dwOption = INTERNET_PER_CONN_PROXY_SERVER;
    options[1].Value.pszValue = const_cast<wchar_t*>(fullProxyString.c_str());

    // Option 3: Proxy bypass list
    options[2].dwOption = INTERNET_PER_CONN_PROXY_BYPASS;
    options[2].Value.pszValue = const_cast<wchar_t*>(L"<local>");

    if (!InternetSetOption(NULL, INTERNET_OPTION_PER_CONNECTION_OPTION, &list, dwBufSize)) {
        return false;
    }

    // Refresh WinHTTP and IE settings
    InternetSetOption(NULL, INTERNET_OPTION_SETTINGS_CHANGED, NULL, 0);
    InternetSetOption(NULL, INTERNET_OPTION_REFRESH, NULL, 0);
    return true;
}

// Disables Windows system proxy and restores direct network access.
bool DisableWindowsSystemProxy() {
    INTERNET_PER_CONN_OPTION_LIST list;
    INTERNET_PER_CONN_OPTION options[1];
    DWORD dwBufSize = sizeof(list);

    list.dwSize = sizeof(list);
    list.pszConnection = NULL;
    list.dwOptionCount = 1;
    list.pOptions = options;

    options[0].dwOption = INTERNET_PER_CONN_FLAGS;
    options[0].Value.dwValue = PROXY_TYPE_DIRECT; // Direct connection, no proxy

    if (!InternetSetOption(NULL, INTERNET_OPTION_PER_CONNECTION_OPTION, &list, dwBufSize)) {
        return false;
    }

    InternetSetOption(NULL, INTERNET_OPTION_SETTINGS_CHANGED, NULL, 0);
    InternetSetOption(NULL, INTERNET_OPTION_REFRESH, NULL, 0);
    return true;
}
