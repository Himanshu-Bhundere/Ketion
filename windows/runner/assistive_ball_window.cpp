#include "assistive_ball_window.h"

#include <cmath>
#include <algorithm>

namespace {
constexpr const wchar_t kAssistiveBallClassName[] =
    L"KETION_ASSISTIVE_BALL_WINDOW";
constexpr COLORREF kColorKey = RGB(255, 0, 255);
}  // namespace

AssistiveBallWindow::AssistiveBallWindow() = default;

AssistiveBallWindow::~AssistiveBallWindow() {
  Destroy();
}

bool AssistiveBallWindow::Create(HWND main_window) {
  Destroy();
  main_window_ = main_window;

  HINSTANCE hInstance = GetModuleHandle(nullptr);

  WNDCLASSEXW wc = {sizeof(WNDCLASSEXW)};
  wc.style = CS_HREDRAW | CS_VREDRAW;
  wc.lpfnWndProc = AssistiveBallWindow::WndProc;
  wc.hInstance = hInstance;
  wc.hCursor = LoadCursor(nullptr, IDC_HAND);
  wc.lpszClassName = kAssistiveBallClassName;
  wc.hbrBackground = nullptr;
  RegisterClassExW(&wc);

  // Compute size based on DPI if available
  UINT dpi = 96;
  HMODULE user32 = GetModuleHandleW(L"user32.dll");
  if (user32) {
    typedef UINT(WINAPI * GetDpiForWindowFn)(HWND);
    auto getDpiFn = reinterpret_cast<GetDpiForWindowFn>(
        GetProcAddress(user32, "GetDpiForWindow"));
    if (getDpiFn && main_window_) {
      dpi = getDpiFn(main_window_);
    }
  }
  ball_size_px_ = static_cast<int>(56.0 * dpi / 96.0);
  if (ball_size_px_ < 32) ball_size_px_ = 56;

  int initial_x = 0;
  int initial_y = 0;
  CalculatePixelPosition(norm_x_, norm_y_, &initial_x, &initial_y);

  // Standalone top-level window (not child, not owned by main window)
  hwnd_ = CreateWindowExW(
      WS_EX_TOPMOST | WS_EX_TOOLWINDOW | WS_EX_LAYERED,
      kAssistiveBallClassName, L"Ketion Assistive Ball", WS_POPUP,
      initial_x, initial_y, ball_size_px_, ball_size_px_,
      nullptr, nullptr, hInstance, this);

  if (!hwnd_) {
    return false;
  }

  SetLayeredWindowAttributes(hwnd_, kColorKey, 0, LWA_COLORKEY);

  HRGN rgn = CreateEllipticRgn(0, 0, ball_size_px_, ball_size_px_);
  SetWindowRgn(hwnd_, rgn, TRUE);

  return true;
}

void AssistiveBallWindow::Destroy() {
  if (hwnd_) {
    DestroyWindow(hwnd_);
    hwnd_ = nullptr;
  }
}

void AssistiveBallWindow::Show(double norm_x, double norm_y) {
  if (!hwnd_) return;
  norm_x_ = (std::max)(0.02, (std::min)(0.98, norm_x));
  norm_y_ = (std::max)(0.02, (std::min)(0.98, norm_y));

  int px = 0;
  int py = 0;
  CalculatePixelPosition(norm_x_, norm_y_, &px, &py);

  is_visible_ = true;
  ShowWindow(hwnd_, SW_SHOWNOACTIVATE);
  SetWindowPos(hwnd_, HWND_TOPMOST, px, py, ball_size_px_, ball_size_px_,
               SWP_NOACTIVATE | SWP_SHOWWINDOW);
}

void AssistiveBallWindow::Hide() {
  if (!hwnd_) return;
  is_visible_ = false;
  ShowWindow(hwnd_, SW_HIDE);
}

void AssistiveBallWindow::UpdatePosition(double norm_x, double norm_y) {
  norm_x_ = (std::max)(0.02, (std::min)(0.98, norm_x));
  norm_y_ = (std::max)(0.02, (std::min)(0.98, norm_y));

  if (!hwnd_) return;

  int px = 0;
  int py = 0;
  CalculatePixelPosition(norm_x_, norm_y_, &px, &py);

  SetWindowPos(hwnd_, HWND_TOPMOST, px, py, ball_size_px_, ball_size_px_,
               SWP_NOACTIVATE | (is_visible_ ? SWP_SHOWWINDOW : 0));
}

void AssistiveBallWindow::SetOnClickCallback(ClickCallback callback) {
  on_click_ = std::move(callback);
}

void AssistiveBallWindow::SetOnPositionCallback(PositionCallback callback) {
  on_position_changed_ = std::move(callback);
}

void AssistiveBallWindow::CalculatePixelPosition(double nx, double ny,
                                                 int* out_x, int* out_y) {
  HMONITOR hMon = MonitorFromWindow(hwnd_ ? hwnd_ : main_window_,
                                    MONITOR_DEFAULTTONEAREST);
  MONITORINFO mi = {sizeof(mi)};
  GetMonitorInfo(hMon, &mi);
  RECT workArea = mi.rcWork;
  int workWidth = (workArea.right - workArea.left) - ball_size_px_;
  int workHeight = (workArea.bottom - workArea.top) - ball_size_px_;
  if (workWidth < 1) workWidth = 1;
  if (workHeight < 1) workHeight = 1;

  *out_x = workArea.left + static_cast<int>(workWidth * nx);
  *out_y = workArea.top + static_cast<int>(workHeight * ny);
}

void AssistiveBallWindow::SnapToNearestCorner() {
  if (!hwnd_) return;
  RECT rect;
  GetWindowRect(hwnd_, &rect);
  HMONITOR hMon = MonitorFromWindow(hwnd_, MONITOR_DEFAULTTONEAREST);
  MONITORINFO mi = {sizeof(mi)};
  GetMonitorInfo(hMon, &mi);
  RECT workArea = mi.rcWork;
  int workWidth = (workArea.right - workArea.left) - ball_size_px_;
  int workHeight = (workArea.bottom - workArea.top) - ball_size_px_;
  if (workWidth < 1) workWidth = 1;
  if (workHeight < 1) workHeight = 1;

  double curX = static_cast<double>(rect.left - workArea.left) / workWidth;
  double curY = static_cast<double>(rect.top - workArea.top) / workHeight;

  norm_x_ = curX < 0.5 ? 0.02 : 0.98;
  norm_y_ = curY < 0.5 ? 0.02 : 0.98;

  int targetX = workArea.left + static_cast<int>(workWidth * norm_x_);
  int targetY = workArea.top + static_cast<int>(workHeight * norm_y_);

  SetWindowPos(hwnd_, HWND_TOPMOST, targetX, targetY, ball_size_px_,
               ball_size_px_, SWP_NOACTIVATE);

  if (on_position_changed_) {
    on_position_changed_(norm_x_, norm_y_);
  }
}

void AssistiveBallWindow::Paint(HWND hwnd) {
  PAINTSTRUCT ps;
  HDC hdc = BeginPaint(hwnd, &ps);
  RECT rect;
  GetClientRect(hwnd, &rect);

  // 1. Fill background with colorkey (fully transparent)
  HBRUSH bgBrush = CreateSolidBrush(kColorKey);
  FillRect(hdc, &rect, bgBrush);
  DeleteObject(bgBrush);

  // 2. Draw circular ball using Ketion primary color #4B68FF
  HBRUSH ballBrush = CreateSolidBrush(RGB(75, 104, 255));
  HPEN ballPen = CreatePen(PS_SOLID, 1, RGB(75, 104, 255));
  HGDIOBJ oldBrush = SelectObject(hdc, ballBrush);
  HGDIOBJ oldPen = SelectObject(hdc, ballPen);

  Ellipse(hdc, 0, 0, rect.right, rect.bottom);

  // 3. Draw Assistive Ball icon (3 bubble nodes matching Icons.bubble_chart_rounded) in white
  HBRUSH whiteBrush = CreateSolidBrush(RGB(255, 255, 255));
  HPEN nullPen = CreatePen(PS_NULL, 0, RGB(0, 0, 0));
  SelectObject(hdc, whiteBrush);
  SelectObject(hdc, nullPen);

  int cx = rect.right / 2;
  int cy = rect.bottom / 2;
  int sz = rect.right;

  // Node 1: Main bottom-left bubble
  int r1 = static_cast<int>(sz * 0.15);
  int x1 = cx - static_cast<int>(sz * 0.10);
  int y1 = cy + static_cast<int>(sz * 0.08);
  Ellipse(hdc, x1 - r1, y1 - r1, x1 + r1, y1 + r1);

  // Node 2: Top-right bubble
  int r2 = static_cast<int>(sz * 0.12);
  int x2 = cx + static_cast<int>(sz * 0.10);
  int y2 = cy - static_cast<int>(sz * 0.10);
  Ellipse(hdc, x2 - r2, y2 - r2, x2 + r2, y2 + r2);

  // Node 3: Bottom-right small bubble
  int r3 = static_cast<int>(sz * 0.08);
  int x3 = cx + static_cast<int>(sz * 0.15);
  int y3 = cy + static_cast<int>(sz * 0.14);
  Ellipse(hdc, x3 - r3, y3 - r3, x3 + r3, y3 + r3);

  SelectObject(hdc, oldPen);
  SelectObject(hdc, oldBrush);
  DeleteObject(ballBrush);
  DeleteObject(ballPen);
  DeleteObject(whiteBrush);
  DeleteObject(nullPen);

  EndPaint(hwnd, &ps);
}

// static
LRESULT CALLBACK AssistiveBallWindow::WndProc(HWND hwnd, UINT message,
                                              WPARAM wparam, LPARAM lparam) {
  if (message == WM_NCCREATE) {
    auto cs = reinterpret_cast<CREATESTRUCT*>(lparam);
    SetWindowLongPtr(hwnd, GWLP_USERDATA,
                     reinterpret_cast<LONG_PTR>(cs->lpCreateParams));
    auto that = static_cast<AssistiveBallWindow*>(cs->lpCreateParams);
    that->hwnd_ = hwnd;
  } else if (auto that = reinterpret_cast<AssistiveBallWindow*>(
                 GetWindowLongPtr(hwnd, GWLP_USERDATA))) {
    return that->MessageHandler(hwnd, message, wparam, lparam);
  }
  return DefWindowProc(hwnd, message, wparam, lparam);
}

LRESULT AssistiveBallWindow::MessageHandler(HWND hwnd, UINT message,
                                           WPARAM wparam, LPARAM lparam) {
  switch (message) {
    case WM_PAINT:
      Paint(hwnd);
      return 0;

    case WM_ERASEBKGND:
      return 1;

    case WM_SETCURSOR:
      SetCursor(LoadCursor(nullptr, IDC_HAND));
      return TRUE;

    case WM_LBUTTONDOWN: {
      SetCapture(hwnd);
      is_dragging_ = false;
      GetCursorPos(&drag_start_cursor_);
      RECT rect;
      GetWindowRect(hwnd, &rect);
      drag_start_win_.x = rect.left;
      drag_start_win_.y = rect.top;
      return 0;
    }

    case WM_MOUSEMOVE: {
      if (GetCapture() == hwnd) {
        POINT pt;
        GetCursorPos(&pt);
        int dx = pt.x - drag_start_cursor_.x;
        int dy = pt.y - drag_start_cursor_.y;
        if (!is_dragging_ && (std::abs(dx) > 4 || std::abs(dy) > 4)) {
          is_dragging_ = true;
        }
        if (is_dragging_) {
          SetWindowPos(hwnd, HWND_TOPMOST, drag_start_win_.x + dx,
                       drag_start_win_.y + dy, 0, 0,
                       SWP_NOSIZE | SWP_NOACTIVATE);
        }
      }
      return 0;
    }

    case WM_LBUTTONUP: {
      if (GetCapture() == hwnd) {
        ReleaseCapture();
        if (!is_dragging_) {
          // Do not forcefully steal foreground focus with SetForegroundWindow.
          // If the main window is minimized, show it without stealing focus.
          if (main_window_ && IsWindow(main_window_)) {
            if (IsIconic(main_window_)) {
              ShowWindow(main_window_, SW_SHOWNOACTIVATE);
            }
          }
          if (on_click_) {
            on_click_();
          }
        } else {
          SnapToNearestCorner();
        }
      }
      return 0;
    }

    case WM_DESTROY:
      hwnd_ = nullptr;
      return 0;
  }

  return DefWindowProc(hwnd, message, wparam, lparam);
}

