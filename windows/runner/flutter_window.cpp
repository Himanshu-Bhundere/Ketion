#include "flutter_window.h"

#include <optional>
#include <variant>

#include "flutter/generated_plugin_registrant.h"

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
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  // Setup native Assistive Ball overlay and method channel
  assistive_ball_window_ = std::make_unique<AssistiveBallWindow>();
  assistive_ball_window_->Create(GetHandle());

  auto messenger = flutter_controller_->engine()->messenger();
  assistive_ball_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          messenger, "com.example.ketion/assistive_ball",
          &flutter::StandardMethodCodec::GetInstance());

  assistive_ball_window_->SetOnClickCallback([this]() {
    if (assistive_ball_channel_) {
      assistive_ball_channel_->InvokeMethod("onBallClicked", nullptr);
    }
  });

  assistive_ball_window_->SetOnPositionCallback(
      [this](double norm_x, double norm_y) {
        if (assistive_ball_channel_) {
          flutter::EncodableMap args;
          args[flutter::EncodableValue("x")] = flutter::EncodableValue(norm_x);
          args[flutter::EncodableValue("y")] = flutter::EncodableValue(norm_y);
          assistive_ball_channel_->InvokeMethod(
              "onPositionChanged",
              std::make_unique<flutter::EncodableValue>(args));
        }
      });

  assistive_ball_channel_->SetMethodCallHandler(
      [this](const flutter::MethodCall<flutter::EncodableValue>& call,
             std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>
                 result) {
        const std::string& method = call.method_name();
        if (method == "checkOverlayPermission" ||
            method == "requestOverlayPermission") {
          result->Success(flutter::EncodableValue(true));
        } else if (method == "showOverlay") {
          double x = 0.98;
          double y = 0.02;
          const auto* args =
              std::get_if<flutter::EncodableMap>(call.arguments());
          if (args) {
            auto it_x = args->find(flutter::EncodableValue("x"));
            if (it_x != args->end()) {
              if (std::holds_alternative<double>(it_x->second)) {
                x = std::get<double>(it_x->second);
              }
            }
            auto it_y = args->find(flutter::EncodableValue("y"));
            if (it_y != args->end()) {
              if (std::holds_alternative<double>(it_y->second)) {
                y = std::get<double>(it_y->second);
              }
            }
          }
          if (assistive_ball_window_) {
            assistive_ball_window_->Show(x, y);
          }
          result->Success();
        } else if (method == "hideOverlay") {
          if (assistive_ball_window_) {
            assistive_ball_window_->Hide();
          }
          result->Success();
        } else if (method == "updatePosition") {
          double x = 0.98;
          double y = 0.02;
          const auto* args =
              std::get_if<flutter::EncodableMap>(call.arguments());
          if (args) {
            auto it_x = args->find(flutter::EncodableValue("x"));
            if (it_x != args->end()) {
              if (std::holds_alternative<double>(it_x->second)) {
                x = std::get<double>(it_x->second);
              }
            }
            auto it_y = args->find(flutter::EncodableValue("y"));
            if (it_y != args->end()) {
              if (std::holds_alternative<double>(it_y->second)) {
                y = std::get<double>(it_y->second);
              }
            }
          }
          if (assistive_ball_window_) {
            assistive_ball_window_->UpdatePosition(x, y);
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
  // Give Flutter, including plugins, an opportunity to handle window messages.
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
