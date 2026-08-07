#include "proxy_config.h"

#include <windows.h>
#include <wininet.h>
#include <iostream>

#pragma comment(lib, "wininet.lib")

namespace airbridge {

std::string ProxyConfig::original_proxy_server_ = "";
bool ProxyConfig::original_proxy_enabled_ = false;
bool ProxyConfig::has_backup_ = false;

bool ProxyConfig::SetSystemProxy(const std::string& proxy_address) {
  INTERNET_PER_CONN_OPTION_LIST list;
  INTERNET_PER_CONN_OPTION options[3];
  DWORD dwBufSize = sizeof(list);

  list.dwSize = sizeof(list);
  list.pszConnection = NULL; // Default LAN connection
  list.dwOptionCount = 3;
  list.pOptions = options;

  // Backup existing settings if not already backed up
  if (!has_backup_) {
    INTERNET_PER_CONN_OPTION_LIST query_list;
    INTERNET_PER_CONN_OPTION query_options[2];
    query_list.dwSize = sizeof(query_list);
    query_list.pszConnection = NULL;
    query_list.dwOptionCount = 2;
    query_list.pOptions = query_options;

    query_options[0].dwOption = INTERNET_PER_CONN_FLAGS;
    query_options[1].dwOption = INTERNET_PER_CONN_PROXY_SERVER;

    if (InternetQueryOption(NULL, INTERNET_OPTION_PER_CONNECTION_OPTION, &query_list, &dwBufSize)) {
      original_proxy_enabled_ = (query_options[0].Value.dwValue & PROXY_TYPE_PROXY) != 0;
      if (query_options[1].Value.pszValue != NULL) {
        std::wstring ws(query_options[1].Value.pszValue);
        original_proxy_server_ = std::string(ws.begin(), ws.end());
        GlobalFree(query_options[1].Value.pszValue);
      }
      has_backup_ = true;
    }
  }

  // Format proxy server string (e.g., "socks=127.0.0.1:1080")
  std::string formatted_proxy = proxy_address;
  if (formatted_proxy.find("socks=") != 0 && formatted_proxy.find("http=") != 0) {
    formatted_proxy = "socks=" + formatted_proxy;
  }

  std::wstring w_proxy(formatted_proxy.begin(), formatted_proxy.end());

  options[0].dwOption = INTERNET_PER_CONN_FLAGS;
  options[0].Value.dwValue = PROXY_TYPE_PROXY | PROXY_TYPE_DIRECT;

  options[1].dwOption = INTERNET_PER_CONN_PROXY_SERVER;
  options[1].Value.pszValue = const_cast<wchar_t*>(w_proxy.c_str());

  options[2].dwOption = INTERNET_PER_CONN_PROXY_BYPASS;
  options[2].Value.pszValue = const_cast<wchar_t*>(L"<local>");

  BOOL result = InternetSetOption(NULL, INTERNET_OPTION_PER_CONNECTION_OPTION, &list, dwBufSize);

  // Refresh settings immediately
  InternetSetOption(NULL, INTERNET_OPTION_SETTINGS_CHANGED, NULL, 0);
  InternetSetOption(NULL, INTERNET_OPTION_REFRESH, NULL, 0);

  return result == TRUE;
}

bool ProxyConfig::ClearSystemProxy() {
  INTERNET_PER_CONN_OPTION_LIST list;
  INTERNET_PER_CONN_OPTION options[2];
  DWORD dwBufSize = sizeof(list);

  list.dwSize = sizeof(list);
  list.pszConnection = NULL;
  list.dwOptionCount = has_backup_ && original_proxy_enabled_ ? 2 : 1;
  list.pOptions = options;

  if (has_backup_ && original_proxy_enabled_) {
    std::wstring w_orig(original_proxy_server_.begin(), original_proxy_server_.end());
    options[0].dwOption = INTERNET_PER_CONN_FLAGS;
    options[0].Value.dwValue = PROXY_TYPE_PROXY | PROXY_TYPE_DIRECT;

    options[1].dwOption = INTERNET_PER_CONN_PROXY_SERVER;
    options[1].Value.pszValue = const_cast<wchar_t*>(w_orig.c_str());
  } else {
    options[0].dwOption = INTERNET_PER_CONN_FLAGS;
    options[0].Value.dwValue = PROXY_TYPE_DIRECT;
  }

  BOOL result = InternetSetOption(NULL, INTERNET_OPTION_PER_CONNECTION_OPTION, &list, dwBufSize);

  InternetSetOption(NULL, INTERNET_OPTION_SETTINGS_CHANGED, NULL, 0);
  InternetSetOption(NULL, INTERNET_OPTION_REFRESH, NULL, 0);

  has_backup_ = false;
  return result == TRUE;
}

bool ProxyConfig::IsProxyActive() {
  INTERNET_PER_CONN_OPTION_LIST query_list;
  INTERNET_PER_CONN_OPTION query_options[1];
  DWORD dwBufSize = sizeof(query_list);

  query_list.dwSize = sizeof(query_list);
  query_list.pszConnection = NULL;
  query_list.dwOptionCount = 1;
  query_list.pOptions = query_options;
  query_options[0].dwOption = INTERNET_PER_CONN_FLAGS;

  if (InternetQueryOption(NULL, INTERNET_OPTION_PER_CONNECTION_OPTION, &query_list, &dwBufSize)) {
    return (query_options[0].Value.dwValue & PROXY_TYPE_PROXY) != 0;
  }
  return false;
}

}  // namespace airbridge
