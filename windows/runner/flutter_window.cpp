#include "flutter_window.h"

#include <dwmapi.h>
#include <optional>
#include <variant>

#include "flutter/generated_plugin_registrant.h"

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

void FlutterWindow::EnterOverlayMode(int width, int height) {
  HWND hwnd = GetHandle();
  if (!hwnd) return;

  if (!is_overlay_mode_) {
    normal_placement_.length = sizeof(WINDOWPLACEMENT);
    ::GetWindowPlacement(hwnd, &normal_placement_);
    ::GetWindowRect(hwnd, &normal_rect_);
  }
  is_overlay_mode_ = true;

  // Restore from minimized (iconic) or maximized (zoomed) state before altering styles
  if (::IsIconic(hwnd) || ::IsZoomed(hwnd)) {
    ::ShowWindow(hwnd, SW_RESTORE);
  } else if (!::IsWindowVisible(hwnd)) {
    ::ShowWindow(hwnd, SW_SHOWNOACTIVATE);
  }

  HMONITOR hMon = MonitorFromWindow(hwnd, MONITOR_DEFAULTTONEAREST);
  MONITORINFO mi = {sizeof(mi)};
  GetMonitorInfo(hMon, &mi);
  RECT workArea = mi.rcWork;

  int x = workArea.right - width - 24;
  int y = workArea.bottom - height - 24;

  // Clear all caption and sizing border styles so no native titlebar is rendered
  LONG_PTR style = ::GetWindowLongPtr(hwnd, GWL_STYLE);
  style &= ~(WS_CAPTION | WS_THICKFRAME | WS_MINIMIZEBOX | WS_MAXIMIZEBOX | WS_SYSMENU | WS_MINIMIZE | WS_MAXIMIZE);
  style |= WS_POPUP | WS_VISIBLE | WS_CLIPCHILDREN | WS_CLIPSIBLINGS;
  ::SetWindowLongPtr(hwnd, GWL_STYLE, style);

  LONG_PTR exStyle = ::GetWindowLongPtr(hwnd, GWL_EXSTYLE);
  exStyle |= WS_EX_TOPMOST | WS_EX_APPWINDOW;
  exStyle &= ~(WS_EX_TOOLWINDOW);
  ::SetWindowLongPtr(hwnd, GWL_EXSTYLE, exStyle);

  // Modern rounded corners for Windows 11 DWM
  DWM_WINDOW_CORNER_PREFERENCE preference = DWMWCP_ROUND;
  DwmSetWindowAttribute(hwnd, DWMWA_WINDOW_CORNER_PREFERENCE, &preference, sizeof(preference));

  ::SetWindowPos(hwnd, HWND_TOPMOST, x, y, width, height,
                 SWP_FRAMECHANGED | SWP_SHOWWINDOW | SWP_NOCOPYBITS);

  HWND child = flutter_controller_ && flutter_controller_->view()
                   ? flutter_controller_->view()->GetNativeWindow()
                   : ::GetWindow(hwnd, GW_CHILD);
  if (child != nullptr) {
    ::MoveWindow(child, 0, 0, width, height, TRUE);
  }

  ::SetForegroundWindow(hwnd);
}

void FlutterWindow::ExitOverlayMode() {
  HWND hwnd = GetHandle();
  if (!hwnd || !is_overlay_mode_) return;

  is_overlay_mode_ = false;

  LONG_PTR style = ::GetWindowLongPtr(hwnd, GWL_STYLE);
  style &= ~(WS_POPUP);
  style |= WS_OVERLAPPEDWINDOW;
  ::SetWindowLongPtr(hwnd, GWL_STYLE, style);

  LONG_PTR exStyle = ::GetWindowLongPtr(hwnd, GWL_EXSTYLE);
  exStyle &= ~(WS_EX_TOOLWINDOW | WS_EX_TOPMOST);
  exStyle |= WS_EX_APPWINDOW;
  ::SetWindowLongPtr(hwnd, GWL_EXSTYLE, exStyle);

  DWM_WINDOW_CORNER_PREFERENCE preference = DWMWCP_DEFAULT;
  DwmSetWindowAttribute(hwnd, DWMWA_WINDOW_CORNER_PREFERENCE, &preference, sizeof(preference));

  if (normal_placement_.showCmd == SW_SHOWMAXIMIZED || normal_placement_.showCmd == SW_SHOWMINIMIZED) {
    ::SetWindowPlacement(hwnd, &normal_placement_);
  } else {
    int normalW = normal_rect_.right - normal_rect_.left;
    int normalH = normal_rect_.bottom - normal_rect_.top;
    if (normalW < 400 || normalH < 300) {
      normalW = 1280;
      normalH = 720;
      normal_rect_.left = 100;
      normal_rect_.top = 100;
      normal_rect_.right = normal_rect_.left + normalW;
      normal_rect_.bottom = normal_rect_.top + normalH;
    }
    ::SetWindowPos(hwnd, HWND_NOTOPMOST, normal_rect_.left, normal_rect_.top,
                   normalW, normalH, SWP_FRAMECHANGED | SWP_NOACTIVATE | SWP_SHOWWINDOW);
  }

  HWND child = flutter_controller_ && flutter_controller_->view()
                   ? flutter_controller_->view()->GetNativeWindow()
                   : ::GetWindow(hwnd, GW_CHILD);
  if (child != nullptr) {
    RECT client;
    ::GetClientRect(hwnd, &client);
    ::MoveWindow(child, 0, 0, client.right - client.left, client.bottom - client.top, TRUE);
  }

  // Ensure assistive ball stays topmost above the restored main window
  if (assistive_ball_window_ && assistive_ball_window_->IsVisible()) {
    ::SetWindowPos(assistive_ball_window_->GetHandle(), HWND_TOPMOST, 0, 0, 0, 0,
                   SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE | SWP_SHOWWINDOW);
  }
}

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
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  auto messenger = flutter_controller_->engine()->messenger();
  assistive_ball_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          messenger, "com.example.ketion/assistive_ball",
          &flutter::StandardMethodCodec::GetInstance());

  assistive_ball_window_ = std::make_unique<AssistiveBallWindow>();

  assistive_ball_window_->SetOnClickCallback([this]() {
    if (assistive_ball_channel_) {
      assistive_ball_channel_->InvokeMethod("onBallClicked", nullptr);
    }
  });

  assistive_ball_window_->SetOnActionCallback([this](const std::string& action, bool is_in_app) {
    HWND hwnd = GetHandle();
    UINT dpi = 96;
    HMODULE user32 = GetModuleHandleW(L"user32.dll");
    if (user32) {
      typedef UINT(WINAPI * GetDpiForWindowFn)(HWND);
      auto getDpiFn = reinterpret_cast<GetDpiForWindowFn>(GetProcAddress(user32, "GetDpiForWindow"));
      if (getDpiFn && hwnd) {
        dpi = getDpiFn(hwnd);
      }
    }

    if (action == "openQuickNote") {
      if (is_in_app) {
        if (assistive_ball_channel_) {
          flutter::EncodableMap args;
          args[flutter::EncodableValue("isStandalone")] = flutter::EncodableValue(false);
          assistive_ball_channel_->InvokeMethod("openQuickNote", std::make_unique<flutter::EncodableValue>(args));
        }
      } else {
        EnterOverlayMode(MulDiv(420, dpi, 96), MulDiv(560, dpi, 96));
        if (assistive_ball_channel_) {
          flutter::EncodableMap args;
          args[flutter::EncodableValue("isStandalone")] = flutter::EncodableValue(true);
          assistive_ball_channel_->InvokeMethod("openQuickNote", std::make_unique<flutter::EncodableValue>(args));
        }
      }
    } else if (action == "openNoteSelector") {
      if (is_in_app) {
        if (assistive_ball_channel_) {
          flutter::EncodableMap args;
          args[flutter::EncodableValue("isStandalone")] = flutter::EncodableValue(false);
          assistive_ball_channel_->InvokeMethod("openNoteSelector", std::make_unique<flutter::EncodableValue>(args));
        }
      } else {
        EnterOverlayMode(MulDiv(440, dpi, 96), MulDiv(580, dpi, 96));
        if (assistive_ball_channel_) {
          flutter::EncodableMap args;
          args[flutter::EncodableValue("isStandalone")] = flutter::EncodableValue(true);
          assistive_ball_channel_->InvokeMethod("openNoteSelector", std::make_unique<flutter::EncodableValue>(args));
        }
      }
    } else if (action == "hideOverlay") {
      if (assistive_ball_channel_) {
        assistive_ball_channel_->InvokeMethod("hideOverlay", nullptr);
      }
    }
  });

  assistive_ball_window_->SetOnPositionCallback([this](double nx, double ny) {
    if (assistive_ball_channel_) {
      auto args = std::make_unique<flutter::EncodableValue>(
          flutter::EncodableMap{
              {flutter::EncodableValue("x"), flutter::EncodableValue(nx)},
              {flutter::EncodableValue("y"), flutter::EncodableValue(ny)},
          });
      assistive_ball_channel_->InvokeMethod("onPositionChanged", std::move(args));
    }
  });

  assistive_ball_channel_->SetMethodCallHandler(
      [this](const flutter::MethodCall<flutter::EncodableValue>& call,
             std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
        const std::string& method = call.method_name();
        if (method == "checkOverlayPermission" || method == "requestOverlayPermission") {
          result->Success(flutter::EncodableValue(true));
        } else if (method == "showOverlay") {
          if (!assistive_ball_window_->GetHandle()) {
            assistive_ball_window_->Create(GetHandle());
          }
          const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
          if (args) {
            auto it_x = args->find(flutter::EncodableValue("x"));
            auto it_y = args->find(flutter::EncodableValue("y"));
            if (it_x != args->end() && it_y != args->end()) {
              double x = std::holds_alternative<double>(it_x->second)
                             ? std::get<double>(it_x->second)
                             : 1.0;
              double y = std::holds_alternative<double>(it_y->second)
                             ? std::get<double>(it_y->second)
                             : 1.0;
              assistive_ball_window_->UpdatePosition(x, y);
            }
          }
          assistive_ball_window_->Show();
          result->Success();
        } else if (method == "hideOverlay") {
          if (assistive_ball_window_) {
            assistive_ball_window_->Hide();
          }
          result->Success();
        } else if (method == "updatePosition") {
          const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
          if (args && assistive_ball_window_) {
            auto it_x = args->find(flutter::EncodableValue("x"));
            auto it_y = args->find(flutter::EncodableValue("y"));
            if (it_x != args->end() && it_y != args->end()) {
              double x = std::holds_alternative<double>(it_x->second)
                             ? std::get<double>(it_x->second)
                             : 1.0;
              double y = std::holds_alternative<double>(it_y->second)
                             ? std::get<double>(it_y->second)
                             : 1.0;
              assistive_ball_window_->UpdatePosition(x, y);
            }
          }
          result->Success();
        } else if (method == "setOverlayWindowMode") {
          const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
          bool enable = false;
          int width = 440;
          int height = 580;
          if (args) {
            auto it_en = args->find(flutter::EncodableValue("enable"));
            if (it_en != args->end() && std::holds_alternative<bool>(it_en->second)) {
              enable = std::get<bool>(it_en->second);
            }
            auto it_w = args->find(flutter::EncodableValue("width"));
            if (it_w != args->end()) {
              if (std::holds_alternative<int>(it_w->second)) width = std::get<int>(it_w->second);
              else if (std::holds_alternative<double>(it_w->second)) width = static_cast<int>(std::get<double>(it_w->second));
            }
            auto it_h = args->find(flutter::EncodableValue("height"));
            if (it_h != args->end()) {
              if (std::holds_alternative<int>(it_h->second)) height = std::get<int>(it_h->second);
              else if (std::holds_alternative<double>(it_h->second)) height = static_cast<int>(std::get<double>(it_h->second));
            }
          }

          UINT dpi = 96;
          HMODULE user32 = GetModuleHandleW(L"user32.dll");
          if (user32) {
            typedef UINT(WINAPI * GetDpiForWindowFn)(HWND);
            auto getDpiFn = reinterpret_cast<GetDpiForWindowFn>(GetProcAddress(user32, "GetDpiForWindow"));
            if (getDpiFn) dpi = getDpiFn(GetHandle());
          }
          int scaledW = MulDiv(width, dpi, 96);
          int scaledH = MulDiv(height, dpi, 96);

          if (enable) {
            EnterOverlayMode(scaledW, scaledH);
          } else {
            ExitOverlayMode();
          }
          result->Success();
        } else {
          result->NotImplemented();
        }
      });

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  flutter_controller_->ForceRedraw();
  return true;
}

void FlutterWindow::OnDestroy() {
  if (assistive_ball_window_) {
    assistive_ball_window_->Destroy();
    assistive_ball_window_ = nullptr;
  }
  if (assistive_ball_channel_) {
    assistive_ball_channel_ = nullptr;
  }
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  if (message == WM_CLOSE && is_overlay_mode_) {
    if (assistive_ball_channel_) {
      assistive_ball_channel_->InvokeMethod("closeFloatingNote", nullptr);
    }
    ExitOverlayMode();
    return 0;
  }

  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam, lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_ACTIVATE:
    case WM_SETFOCUS:
    case WM_WINDOWPOSCHANGED:
    case WM_SHOWWINDOW: {
      if (assistive_ball_window_ && assistive_ball_window_->IsVisible() && !is_overlay_mode_) {
        ::SetWindowPos(assistive_ball_window_->GetHandle(), HWND_TOPMOST, 0, 0, 0, 0,
                       SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE | SWP_SHOWWINDOW);
      }
      break;
    }
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
