#ifndef RUNNER_FLUTTER_WINDOW_H_
#define RUNNER_FLUTTER_WINDOW_H_

#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <string>

#include "assistive_ball_window.h"
#include "win32_window.h"

class FlutterWindow : public Win32Window {
 public:
  explicit FlutterWindow(const flutter::DartProject& project);
  virtual ~FlutterWindow();

 protected:
  bool OnCreate() override;
  void OnDestroy() override;
  LRESULT MessageHandler(HWND window, UINT const message, WPARAM const wparam,
                         LPARAM const lparam) noexcept override;

 private:
  flutter::DartProject project_;
  std::unique_ptr<flutter::FlutterViewController> flutter_controller_;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>>
      assistive_ball_channel_;
  std::unique_ptr<AssistiveBallWindow> assistive_ball_window_;

  void EnterOverlayMode(int width, int height);
  void ExitOverlayMode();

  bool is_overlay_mode_ = false;
  RECT normal_rect_ = {0, 0, 0, 0};
  WINDOWPLACEMENT normal_placement_ = {sizeof(WINDOWPLACEMENT)};
};

#endif  // RUNNER_FLUTTER_WINDOW_H_
