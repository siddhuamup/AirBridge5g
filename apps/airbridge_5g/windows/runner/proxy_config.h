#ifndef PROXY_CONFIG_H_
#define PROXY_CONFIG_H_

#include <string>

namespace airbridge {

class ProxyConfig {
 public:
  static bool SetSystemProxy(const std::string& proxy_address);
  static bool ClearSystemProxy();
  static bool IsProxyActive();

 private:
  static std::string original_proxy_server_;
  static bool original_proxy_enabled_;
  static bool has_backup_;
};

}  // namespace airbridge

#endif  // PROXY_CONFIG_H_
