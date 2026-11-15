#ifndef RUNNER_ASSISTIVE_BALL_WINDOW_H_
#define RUNNER_ASSISTIVE_BALL_WINDOW_H_

#include <windows.h>
#include <functional>
#include <string>

class AssistiveBallWindow {
 public:
  using ClickCallback = std::function<void()>;
  using ActionCallback = std::function<void(const std::string& action, bool is_in_app)>;
  using PositionCallback = std::function<void(double norm_x, double norm_y)>;

  AssistiveBallWindow();
  ~AssistiveBallWindow();

  bool Create(HWND main_window);
  void Destroy();

  void Show(double norm_x = 1.0, double norm_y = 1.0);
  void Hide();
  void UpdatePosition(double norm_x, double norm_y);

  void SetOnClickCallback(ClickCallback callback);
  void SetOnActionCallback(ActionCallback callback);
  void SetOnPositionCallback(PositionCallback callback);

  HWND GetHandle() const { return hwnd_; }
  bool IsVisible() const { return is_visible_; }

  void ShowThemedMenu();
  void HideThemedMenu();

 private:
  static LRESULT CALLBACK WndProc(HWND hwnd, UINT message, WPARAM wparam,
                                  LPARAM lparam);
  LRESULT MessageHandler(HWND hwnd, UINT message, WPARAM wparam, LPARAM lparam);

  static LRESULT CALLBACK MenuWndProc(HWND hwnd, UINT message, WPARAM wparam,
                                      LPARAM lparam);
  LRESULT MenuMessageHandler(HWND hwnd, UINT message, WPARAM wparam, LPARAM lparam);

  void Paint(HWND hwnd);
  void PaintMenu(HWND hwnd);

  void SnapToNearestCorner();
  void CalculatePixelPosition(double nx, double ny, int* out_x, int* out_y);
  void LoadPersistedCorner();
  void SavePersistedCorner(double nx, double ny);

  HWND hwnd_ = nullptr;
  HWND menu_hwnd_ = nullptr;
  HWND main_window_ = nullptr;
  bool is_visible_ = false;
  bool was_in_app_ = false;

  int ball_size_px_ = 56;
  int menu_width_px_ = 210;
  int menu_height_px_ = 160;
  int hovered_menu_item_ = -1;  // 0: Quick Note, 1: Note Selector, 2: Hide Ball

  double norm_x_ = 1.0;
  double norm_y_ = 1.0;

  bool is_dragging_ = false;
  POINT drag_start_cursor_ = {0, 0};
  POINT drag_start_win_ = {0, 0};

  ClickCallback on_click_;
  ActionCallback on_action_;
  PositionCallback on_position_changed_;
};

#endif  // RUNNER_ASSISTIVE_BALL_WINDOW_H_
