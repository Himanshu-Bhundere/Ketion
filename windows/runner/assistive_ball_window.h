#ifndef RUNNER_ASSISTIVE_BALL_WINDOW_H_
#define RUNNER_ASSISTIVE_BALL_WINDOW_H_

#include <windows.h>
#include <functional>

class AssistiveBallWindow {
 public:
  using ClickCallback = std::function<void()>;
  using PositionCallback = std::function<void(double norm_x, double norm_y)>;

  AssistiveBallWindow();
  ~AssistiveBallWindow();

  bool Create(HWND main_window);
  void Destroy();

  void Show(double norm_x = 0.98, double norm_y = 0.02);
  void Hide();
  void UpdatePosition(double norm_x, double norm_y);

  void SetOnClickCallback(ClickCallback callback);
  void SetOnPositionCallback(PositionCallback callback);

  HWND GetHandle() const { return hwnd_; }
  bool IsVisible() const { return is_visible_; }

 private:
  static LRESULT CALLBACK WndProc(HWND hwnd, UINT message, WPARAM wparam,
                                  LPARAM lparam);
  LRESULT MessageHandler(HWND hwnd, UINT message, WPARAM wparam, LPARAM lparam);

  void Paint(HWND hwnd);
  void SnapToNearestCorner();
  void CalculatePixelPosition(double nx, double ny, int* out_x, int* out_y);

  HWND hwnd_ = nullptr;
  HWND main_window_ = nullptr;
  bool is_visible_ = false;

  int ball_size_px_ = 56;
  double norm_x_ = 0.98;
  double norm_y_ = 0.02;

  bool is_dragging_ = false;
  POINT drag_start_cursor_ = {0, 0};
  POINT drag_start_win_ = {0, 0};

  ClickCallback on_click_;
  PositionCallback on_position_changed_;
};

#endif  // RUNNER_ASSISTIVE_BALL_WINDOW_H_

