#include "flutter_window.h"

#include <optional>
#include "flutter/generated_plugin_registrant.h"
#include "flutter/method_channel.h"
#include "flutter/standard_method_codec.h"
#include "proxy_config.h"

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);

  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());

  // Register Windows Proxy MethodChannel Handlers
  auto setupProxyChannel = [this](const std::string& channel_name) {
    auto channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
        flutter_controller_->engine()->messenger(),
        channel_name,
        &flutter::StandardMethodCodec::GetInstance());

    channel->SetMethodCallHandler(
        [](const flutter::MethodCall<flutter::EncodableValue>& call,
           std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
          const auto& method = call.method_name();
          if (method == "setProxy" || method == "setSystemProxy") {
            std::string proxy_addr = "127.0.0.1:1080";
            if (call.arguments() && std::holds_alternative<flutter::EncodableMap>(*call.arguments())) {
              const auto& args = std::get<flutter::EncodableMap>(*call.arguments());
              auto it = args.find(flutter::EncodableValue("proxyAddress"));
              if (it == args.end()) {
                it = args.find(flutter::EncodableValue("proxy_address"));
              }
              if (it != args.end() && std::holds_alternative<std::string>(it->second)) {
                proxy_addr = std::get<std::string>(it->second);
              }
            }
            bool success = airbridge::ProxyConfig::SetSystemProxy(proxy_addr);
            result->Success(flutter::EncodableValue(success));
          } else if (method == "disableProxy" || method == "clearSystemProxy") {
            bool success = airbridge::ProxyConfig::ClearSystemProxy();
            result->Success(flutter::EncodableValue(success));
          } else if (method == "isProxyActive") {
            bool active = airbridge::ProxyConfig::IsProxyActive();
            result->Success(flutter::EncodableValue(active));
          } else {
            result->NotImplemented();
          }
        });
  };

  setupProxyChannel("com.airbridge/windows_proxy");
  setupProxyChannel("com.airbridge/proxy");

  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
