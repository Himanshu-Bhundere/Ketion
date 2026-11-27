#include "flutter_window.h"

#include <dwmapi.h>
#include <algorithm>
#include <cctype>
#include <optional>
#include <sstream>
#include <variant>

#include "flutter/generated_plugin_registrant.h"
#include "utils.h"

namespace {

constexpr ULONG_PTR kShareCopyDataTag = 0x4B455449;  // 'KETI'

std::string InferMimeTypeFromFilename(const std::string& filename) {
  auto dot_pos = filename.find_last_of('.');
  if (dot_pos == std::string::npos || dot_pos + 1 >= filename.size()) {
    return "application/octet-stream";
  }
  std::string ext = filename.substr(dot_pos + 1);
  std::transform(ext.begin(), ext.end(), ext.begin(), [](unsigned char c) {
    return static_cast<char>(std::tolower(c));
  });

  if (ext == "jpg" || ext == "jpeg") return "image/jpeg";
  if (ext == "png") return "image/png";
  if (ext == "gif") return "image/gif";
  if (ext == "webp") return "image/webp";
  if (ext == "bmp") return "image/bmp";
  if (ext == "svg") return "image/svg+xml";
  if (ext == "heic") return "image/heic";
  if (ext == "mp4") return "video/mp4";
  if (ext == "mov") return "video/quicktime";
  if (ext == "m4v") return "video/x-m4v";
  if (ext == "avi") return "video/x-msvideo";
  if (ext == "mkv") return "video/x-matroska";
  if (ext == "webm") return "video/webm";
  if (ext == "mp3") return "audio/mpeg";
  if (ext == "wav") return "audio/wav";
  if (ext == "m4a") return "audio/mp4";
  if (ext == "aac") return "audio/aac";
  if (ext == "ogg") return "audio/ogg";
  if (ext == "flac") return "audio/flac";
  if (ext == "pdf") return "application/pdf";
  if (ext == "md" || ext == "markdown") return "text/markdown";
  if (ext == "txt") return "text/plain";
  if (ext == "csv") return "text/csv";
  if (ext == "html" || ext == "htm") return "text/html";
  if (ext == "json") return "application/json";
  if (ext == "xml") return "application/xml";
  if (ext == "zip") return "application/zip";
  return "application/octet-stream";
}

std::string ExtractBasename(const std::string& path) {
  size_t pos = path.find_last_of("\\/");
  if (pos == std::string::npos) return path;
  return path.substr(pos + 1);
}

std::wstring Utf16FromUtf8(const std::string& utf8) {
  if (utf8.empty()) return std::wstring();
  int len = ::MultiByteToWideChar(CP_UTF8, 0, utf8.c_str(),
                                  static_cast<int>(utf8.size()), nullptr, 0);
  if (len <= 0) return std::wstring();
  std::wstring wide(static_cast<size_t>(len), L'\0');
  ::MultiByteToWideChar(CP_UTF8, 0, utf8.c_str(),
                        static_cast<int>(utf8.size()), &wide[0], len);
  return wide;
}

}  // namespace

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

void FlutterWindow::SetInitialArguments(std::vector<std::string> args) {
  initial_args_ = std::move(args);
}

void FlutterWindow::ProcessIncomingArguments(
    const std::vector<std::string>& args, bool emit_if_ready) {
  std::vector<flutter::EncodableMap> items;

  for (const auto& raw_arg : args) {
    if (raw_arg.empty() || raw_arg[0] == '-' || raw_arg[0] == '/') {
      continue;
    }

    std::string arg = raw_arg;
    if (arg.size() >= 2 && arg.front() == '"' && arg.back() == '"') {
      arg = arg.substr(1, arg.size() - 2);
    }
    if (arg.empty()) continue;

    if (arg.rfind("http://", 0) == 0 || arg.rfind("https://", 0) == 0) {
      flutter::EncodableMap item;
      item[flutter::EncodableValue("type")] = flutter::EncodableValue("link");
      item[flutter::EncodableValue("name")] = flutter::EncodableValue(arg);
      item[flutter::EncodableValue("url")] = flutter::EncodableValue(arg);
      items.push_back(std::move(item));
      continue;
    }

    std::wstring wide_path = Utf16FromUtf8(arg);
    if (wide_path.empty()) continue;

    WIN32_FILE_ATTRIBUTE_DATA file_data{};
    if (::GetFileAttributesExW(wide_path.c_str(), GetFileExInfoStandard,
                               &file_data) &&
        !(file_data.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY)) {
      LARGE_INTEGER size_li{};
      size_li.LowPart = file_data.nFileSizeLow;
      size_li.HighPart = static_cast<LONG>(file_data.nFileSizeHigh);

      std::string name = ExtractBasename(arg);
      flutter::EncodableMap item;
      item[flutter::EncodableValue("type")] = flutter::EncodableValue("file");
      item[flutter::EncodableValue("name")] = flutter::EncodableValue(name);
      item[flutter::EncodableValue("localPath")] =
          flutter::EncodableValue(arg);
      item[flutter::EncodableValue("mimeType")] =
          flutter::EncodableValue(InferMimeTypeFromFilename(name));
      item[flutter::EncodableValue("size")] =
          flutter::EncodableValue(static_cast<int64_t>(size_li.QuadPart));
      items.push_back(std::move(item));
    }
  }

  if (items.empty()) return;

  if (emit_if_ready && share_channel_) {
    flutter::EncodableList encoded_list;
    for (const auto& item : items) {
      encoded_list.push_back(flutter::EncodableValue(item));
    }
    share_channel_->InvokeMethod(
        "onShareReceived",
        std::make_unique<flutter::EncodableValue>(std::move(encoded_list)));
  } else {
    pending_shares_.insert(pending_shares_.end(), items.begin(), items.end());
  }
}

void FlutterWindow::EnterOverlayMode(int width, int height) {
  HWND hwnd = GetHandle();
  if (!hwnd) return;

  if (!is_overlay_mode_) {
    normal_placement_.length = sizeof(WINDOWPLACEMENT);
    ::GetWindowPlacement(hwnd, &normal_placement_);
    ::GetWindowRect(hwnd, &normal_rect_);
    was_iconic_before_overlay_ = ::IsIconic(hwnd) || (normal_placement_.showCmd == SW_SHOWMINIMIZED);
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
    ::SetFocus(child);
    saved_child_imc_ = ::ImmAssociateContext(child, nullptr);
  }
  saved_window_imc_ = ::ImmAssociateContext(hwnd, nullptr);

  ::SetForegroundWindow(hwnd);
}

void FlutterWindow::ExitOverlayMode() {
  HWND hwnd = GetHandle();
  if (!hwnd || !is_overlay_mode_) return;

  is_overlay_mode_ = false;

  // 1. Explicitly clear HWND_TOPMOST before modifying window styles
  ::SetWindowPos(hwnd, HWND_NOTOPMOST, 0, 0, 0, 0,
                 SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE | SWP_FRAMECHANGED);

  // 2. Restore standard overlapped window styles and strip topmost/toolwindow
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

  // 3. Restore geometry without topmost
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
                 normalW, normalH, SWP_FRAMECHANGED | SWP_NOACTIVATE);

  HWND child = flutter_controller_ && flutter_controller_->view()
                   ? flutter_controller_->view()->GetNativeWindow()
                   : ::GetWindow(hwnd, GW_CHILD);
  if (child != nullptr) {
    RECT client;
    ::GetClientRect(hwnd, &client);
    ::MoveWindow(child, 0, 0, client.right - client.left, client.bottom - client.top, TRUE);
  }

  // 4. Restore IME contexts if previously disassociated
  if (saved_child_imc_ != nullptr) {
    if (child != nullptr) {
      ::ImmAssociateContext(child, saved_child_imc_);
    }
    saved_child_imc_ = nullptr;
  }
  if (saved_window_imc_ != nullptr) {
    ::ImmAssociateContext(hwnd, saved_window_imc_);
    saved_window_imc_ = nullptr;
  }

  // 5. Since overlay mode was opened while the user was working in another app,
  // closing it must NOT pop up the main app over the user's active application.
  // We minimize the window cleanly so focus returns to the previous app,
  // and clicking Ketion on the taskbar will restore it as a regular, non-topmost window.
  ::ShowWindow(hwnd, SW_MINIMIZE);

  // 6. Ensure assistive ball stays topmost above normal windows
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
  share_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          messenger, "com.example.ketion/share_target",
          &flutter::StandardMethodCodec::GetInstance());

  share_channel_->SetMethodCallHandler(
      [this](const flutter::MethodCall<flutter::EncodableValue>& call,
             std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
        const std::string& method = call.method_name();
        if (method == "getPendingShares") {
          flutter::EncodableList list;
          for (const auto& item : pending_shares_) {
            list.push_back(flutter::EncodableValue(item));
          }
          pending_shares_.clear();
          result->Success(flutter::EncodableValue(std::move(list)));
        } else if (method == "clearPendingShares") {
          pending_shares_.clear();
          result->Success();
        } else if (method == "setActiveNoteId") {
          const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
          if (args) {
            auto it = args->find(flutter::EncodableValue("noteId"));
            if (it != args->end() && std::holds_alternative<std::string>(it->second)) {
              last_opened_note_id_ = std::get<std::string>(it->second);
            } else {
              last_opened_note_id_.clear();
            }
          }
          result->Success();
        } else if (method == "getLastOpenedNoteId") {
          if (last_opened_note_id_.empty()) {
            result->Success();
          } else {
            result->Success(flutter::EncodableValue(last_opened_note_id_));
          }
        } else {
          result->NotImplemented();
        }
      });

  if (!initial_args_.empty()) {
    ProcessIncomingArguments(initial_args_, false);
    initial_args_.clear();
  }

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
  if (share_channel_) {
    share_channel_ = nullptr;
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
  if (message == WM_COPYDATA) {
    const auto* cds = reinterpret_cast<const COPYDATASTRUCT*>(lparam);
    if (cds && cds->dwData == kShareCopyDataTag && cds->lpData && cds->cbData > 0) {
      std::string payload(static_cast<const char*>(cds->lpData), cds->cbData);
      std::vector<std::string> forwarded_args;
      std::istringstream stream(payload);
      std::string line;
      while (std::getline(stream, line)) {
        if (!line.empty() && line.back() == '\r') {
          line.pop_back();
        }
        if (!line.empty()) {
          forwarded_args.push_back(std::move(line));
        }
      }
      if (!forwarded_args.empty()) {
        ProcessIncomingArguments(forwarded_args, true);
      }
      if (::IsIconic(hwnd)) {
        ::ShowWindow(hwnd, SW_RESTORE);
      }
      ::SetForegroundWindow(hwnd);
      return 1;
    }
  }

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
    case WM_KEYDOWN:
    case WM_SYSKEYDOWN: {
      if (wparam == VK_BACK || wparam == VK_DELETE) {
        HWND child = flutter_controller_ && flutter_controller_->view()
                         ? flutter_controller_->view()->GetNativeWindow()
                         : nullptr;
        if (child != nullptr) {
          HIMC hImc = ::ImmGetContext(child);
          if (hImc) {
            ::ImmNotifyIME(hImc, NI_COMPOSITIONSTR, CPS_CANCEL, 0);
            ::ImmReleaseContext(child, hImc);
          }
        }
      }
      break;
    }
    case WM_SETFOCUS: {
      HWND child = flutter_controller_ && flutter_controller_->view()
                       ? flutter_controller_->view()->GetNativeWindow()
                       : nullptr;
      if (child != nullptr) {
        ::SetFocus(child);
      }
      if (assistive_ball_window_ && assistive_ball_window_->IsVisible() && !is_overlay_mode_) {
        ::SetWindowPos(assistive_ball_window_->GetHandle(), HWND_TOPMOST, 0, 0, 0, 0,
                       SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE | SWP_SHOWWINDOW);
      }
      break;
    }
    case WM_ACTIVATE:
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
