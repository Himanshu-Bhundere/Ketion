#include "assistive_ball_window.h"

#include <cmath>
#include <algorithm>

namespace {
constexpr const wchar_t kAssistiveBallClassName[] =
    L"KETION_ASSISTIVE_BALL_WINDOW";
constexpr const wchar_t kAssistiveBallMenuClassName[] =
    L"KETION_ASSISTIVE_BALL_MENU_WINDOW";
constexpr const wchar_t kRegistrySubKey[] =
    L"Software\\Ketion\\AssistiveBall";

constexpr COLORREF kColorKey = RGB(255, 0, 255);

void DrawQuickNoteVector(HDC hdc, int cx, int cy, int size, COLORREF color) {
  HPEN pen = CreatePen(PS_SOLID, 2, color);
  HGDIOBJ oldPen = SelectObject(hdc, pen);
  HGDIOBJ oldBrush = SelectObject(hdc, GetStockObject(NULL_BRUSH));

  int w = size * 7 / 10;
  int h = size * 9 / 10;
  int left = cx - w / 2;
  int top = cy - h / 2;
  int right = left + w;
  int bottom = top + h;
  int fold = size * 3 / 10;

  POINT pts[5] = {
    {left, top},
    {right - fold, top},
    {right, top + fold},
    {right, bottom},
    {left, bottom}
  };
  Polygon(hdc, pts, 5);

  MoveToEx(hdc, right - fold, top, nullptr);
  LineTo(hdc, right - fold, top + fold);
  LineTo(hdc, right, top + fold);

  HPEN linePen = CreatePen(PS_SOLID, 1, color);
  SelectObject(hdc, linePen);
  MoveToEx(hdc, left + 3, cy - 1, nullptr);
  LineTo(hdc, right - 4, cy - 1);
  MoveToEx(hdc, left + 3, cy + 3, nullptr);
  LineTo(hdc, right - 6, cy + 3);

  SelectObject(hdc, oldBrush);
  SelectObject(hdc, oldPen);
  DeleteObject(pen);
  DeleteObject(linePen);
}

void DrawNoteSelectorVector(HDC hdc, int cx, int cy, int size, COLORREF color) {
  HPEN pen = CreatePen(PS_SOLID, 2, color);
  HGDIOBJ oldPen = SelectObject(hdc, pen);
  HGDIOBJ oldBrush = SelectObject(hdc, GetStockObject(NULL_BRUSH));

  int w = size * 6 / 10;
  int h = size * 8 / 10;

  // Back page
  int bLeft = cx - w / 2 + 3;
  int bTop = cy - h / 2 - 2;
  int bRight = bLeft + w;
  int bBottom = bTop + h;
  MoveToEx(hdc, bLeft + 3, bTop, nullptr);
  LineTo(hdc, bRight, bTop);
  LineTo(hdc, bRight, bBottom - 3);

  // Front page
  int fLeft = cx - w / 2 - 2;
  int fTop = cy - h / 2 + 2;
  int fRight = fLeft + w;
  int fBottom = fTop + h;
  Rectangle(hdc, fLeft, fTop, fRight, fBottom);

  HPEN linePen = CreatePen(PS_SOLID, 1, color);
  SelectObject(hdc, linePen);
  MoveToEx(hdc, fLeft + 3, cy + 1, nullptr);
  LineTo(hdc, fRight - 3, cy + 1);
  MoveToEx(hdc, fLeft + 3, cy + 5, nullptr);
  LineTo(hdc, fRight - 5, cy + 5);

  SelectObject(hdc, oldBrush);
  SelectObject(hdc, oldPen);
  DeleteObject(pen);
  DeleteObject(linePen);
}

void DrawHideBallVector(HDC hdc, int cx, int cy, int size, COLORREF color) {
  HPEN pen = CreatePen(PS_SOLID, 2, color);
  HGDIOBJ oldPen = SelectObject(hdc, pen);
  HGDIOBJ oldBrush = SelectObject(hdc, GetStockObject(NULL_BRUSH));

  int r = size * 45 / 100;
  Ellipse(hdc, cx - r, cy - r, cx + r, cy + r);

  HBRUSH dotBrush = CreateSolidBrush(color);
  SelectObject(hdc, dotBrush);
  int dr = size * 16 / 100;
  Ellipse(hdc, cx - dr, cy - dr, cx + dr, cy + dr);
  DeleteObject(dotBrush);

  HPEN slashPen = CreatePen(PS_SOLID, 2, color);
  SelectObject(hdc, slashPen);
  int slash = size * 6 / 10;
  MoveToEx(hdc, cx - slash, cy - slash, nullptr);
  LineTo(hdc, cx + slash, cy + slash);

  SelectObject(hdc, oldBrush);
  SelectObject(hdc, oldPen);
  DeleteObject(pen);
  DeleteObject(slashPen);
}
}  // namespace

AssistiveBallWindow::AssistiveBallWindow() = default;

AssistiveBallWindow::~AssistiveBallWindow() {
  Destroy();
}

void AssistiveBallWindow::LoadPersistedCorner() {
  HKEY hKey;
  if (RegOpenKeyExW(HKEY_CURRENT_USER, kRegistrySubKey, 0, KEY_READ, &hKey) == ERROR_SUCCESS) {
    DWORD xVal = 0, yVal = 0;
    DWORD size = sizeof(DWORD);
    if (RegQueryValueExW(hKey, L"CornerX", nullptr, nullptr, reinterpret_cast<LPBYTE>(&xVal), &size) == ERROR_SUCCESS) {
      norm_x_ = static_cast<double>(xVal) / 1000.0;
    }
    size = sizeof(DWORD);
    if (RegQueryValueExW(hKey, L"CornerY", nullptr, nullptr, reinterpret_cast<LPBYTE>(&yVal), &size) == ERROR_SUCCESS) {
      norm_y_ = static_cast<double>(yVal) / 1000.0;
    }
    RegCloseKey(hKey);
  } else {
    // Default to Bottom-Right corner
    norm_x_ = 1.0;
    norm_y_ = 1.0;
  }
}

void AssistiveBallWindow::SavePersistedCorner(double nx, double ny) {
  HKEY hKey;
  if (RegCreateKeyExW(HKEY_CURRENT_USER, kRegistrySubKey, 0, nullptr,
                      REG_OPTION_NON_VOLATILE, KEY_WRITE, nullptr, &hKey, nullptr) == ERROR_SUCCESS) {
    DWORD xVal = static_cast<DWORD>(nx * 1000.0);
    DWORD yVal = static_cast<DWORD>(ny * 1000.0);
    RegSetValueExW(hKey, L"CornerX", 0, REG_DWORD, reinterpret_cast<const BYTE*>(&xVal), sizeof(DWORD));
    RegSetValueExW(hKey, L"CornerY", 0, REG_DWORD, reinterpret_cast<const BYTE*>(&yVal), sizeof(DWORD));
    RegCloseKey(hKey);
  }
}

bool AssistiveBallWindow::Create(HWND main_window) {
  Destroy();
  main_window_ = main_window;
  HINSTANCE hInstance = GetModuleHandle(nullptr);

  LoadPersistedCorner();

  // Register Ball Window Class
  WNDCLASSEXW wc = {sizeof(WNDCLASSEXW)};
  wc.style = CS_HREDRAW | CS_VREDRAW;
  wc.lpfnWndProc = AssistiveBallWindow::WndProc;
  wc.hInstance = hInstance;
  wc.hCursor = LoadCursor(nullptr, IDC_HAND);
  wc.lpszClassName = kAssistiveBallClassName;
  RegisterClassExW(&wc);

  // Register Themed Popup Menu Class
  WNDCLASSEXW mwc = {sizeof(WNDCLASSEXW)};
  mwc.style = CS_HREDRAW | CS_VREDRAW | CS_DROPSHADOW;
  mwc.lpfnWndProc = AssistiveBallWindow::MenuWndProc;
  mwc.hInstance = hInstance;
  mwc.hCursor = LoadCursor(nullptr, IDC_ARROW);
  mwc.lpszClassName = kAssistiveBallMenuClassName;
  RegisterClassExW(&mwc);

  UINT dpi = 96;
  HMODULE user32 = GetModuleHandleW(L"user32.dll");
  if (user32) {
    typedef UINT(WINAPI * GetDpiForWindowFn)(HWND);
    auto getDpiFn = reinterpret_cast<GetDpiForWindowFn>(GetProcAddress(user32, "GetDpiForWindow"));
    if (getDpiFn && main_window_) {
      dpi = getDpiFn(main_window_);
    }
  }

  ball_size_px_ = MulDiv(56, dpi, 96);
  menu_width_px_ = MulDiv(210, dpi, 96);
  menu_height_px_ = MulDiv(156, dpi, 96);

  int initial_x = 0;
  int initial_y = 0;
  CalculatePixelPosition(norm_x_, norm_y_, &initial_x, &initial_y);

  hwnd_ = CreateWindowExW(
      WS_EX_TOPMOST | WS_EX_TOOLWINDOW | WS_EX_LAYERED | WS_EX_NOACTIVATE,
      kAssistiveBallClassName, L"Ketion Assistive Ball", WS_POPUP,
      initial_x, initial_y, ball_size_px_, ball_size_px_,
      nullptr, nullptr, hInstance, this);

  if (!hwnd_) return false;

  SetLayeredWindowAttributes(hwnd_, kColorKey, 0, LWA_COLORKEY);
  HRGN rgn = CreateEllipticRgn(0, 0, ball_size_px_, ball_size_px_);
  SetWindowRgn(hwnd_, rgn, TRUE);

  return true;
}

void AssistiveBallWindow::Destroy() {
  HideThemedMenu();
  if (hwnd_) {
    DestroyWindow(hwnd_);
    hwnd_ = nullptr;
  }
}

void AssistiveBallWindow::Show(double norm_x, double norm_y) {
  if (!hwnd_) return;
  norm_x_ = (std::max)(0.0, (std::min)(1.0, norm_x));
  norm_y_ = (std::max)(0.0, (std::min)(1.0, norm_y));

  int px = 0;
  int py = 0;
  CalculatePixelPosition(norm_x_, norm_y_, &px, &py);

  is_visible_ = true;
  ShowWindow(hwnd_, SW_SHOWNOACTIVATE);
  SetWindowPos(hwnd_, HWND_TOPMOST, px, py, ball_size_px_, ball_size_px_,
               SWP_NOACTIVATE | SWP_SHOWWINDOW);
}

void AssistiveBallWindow::Hide() {
  HideThemedMenu();
  if (!hwnd_) return;
  is_visible_ = false;
  ShowWindow(hwnd_, SW_HIDE);
}

void AssistiveBallWindow::UpdatePosition(double norm_x, double norm_y) {
  norm_x_ = (std::max)(0.0, (std::min)(1.0, norm_x));
  norm_y_ = (std::max)(0.0, (std::min)(1.0, norm_y));
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

void AssistiveBallWindow::SetOnActionCallback(ActionCallback callback) {
  on_action_ = std::move(callback);
}

void AssistiveBallWindow::SetOnPositionCallback(PositionCallback callback) {
  on_position_changed_ = std::move(callback);
}

void AssistiveBallWindow::CalculatePixelPosition(double nx, double ny, int* out_x, int* out_y) {
  HMONITOR hMon = MonitorFromWindow(hwnd_ ? hwnd_ : main_window_, MONITOR_DEFAULTTONEAREST);
  MONITORINFO mi = {sizeof(mi)};
  GetMonitorInfo(hMon, &mi);
  RECT workArea = mi.rcWork;

  UINT dpi = 96;
  HMODULE user32 = GetModuleHandleW(L"user32.dll");
  if (user32) {
    typedef UINT(WINAPI * GetDpiForWindowFn)(HWND);
    auto getDpiFn = reinterpret_cast<GetDpiForWindowFn>(GetProcAddress(user32, "GetDpiForWindow"));
    if (getDpiFn && hwnd_) {
      dpi = getDpiFn(hwnd_);
    } else if (getDpiFn && main_window_) {
      dpi = getDpiFn(main_window_);
    }
  }

  int totalW = workArea.right - workArea.left;
  int totalH = workArea.bottom - workArea.top;

  // Responsive spacing from screen corner based on monitor resolution and DPI
  int spacingX = (std::max)(MulDiv(16, dpi, 96), static_cast<int>(totalW * 0.016));
  int spacingY = (std::max)(MulDiv(16, dpi, 96), static_cast<int>(totalH * 0.022));

  int minX = workArea.left + spacingX;
  int maxX = workArea.right - ball_size_px_ - spacingX;
  int minY = workArea.top + spacingY;
  int maxY = workArea.bottom - ball_size_px_ - spacingY;

  double clampedX = (std::max)(0.0, (std::min)(1.0, nx));
  double clampedY = (std::max)(0.0, (std::min)(1.0, ny));

  *out_x = minX + static_cast<int>((maxX - minX) * clampedX);
  *out_y = minY + static_cast<int>((maxY - minY) * clampedY);
}

void AssistiveBallWindow::SnapToNearestCorner() {
  if (!hwnd_) return;
  RECT rect;
  GetWindowRect(hwnd_, &rect);
  HMONITOR hMon = MonitorFromWindow(hwnd_, MONITOR_DEFAULTTONEAREST);
  MONITORINFO mi = {sizeof(mi)};
  GetMonitorInfo(hMon, &mi);
  RECT workArea = mi.rcWork;

  UINT dpi = 96;
  HMODULE user32 = GetModuleHandleW(L"user32.dll");
  if (user32) {
    typedef UINT(WINAPI * GetDpiForWindowFn)(HWND);
    auto getDpiFn = reinterpret_cast<GetDpiForWindowFn>(GetProcAddress(user32, "GetDpiForWindow"));
    if (getDpiFn) {
      dpi = getDpiFn(hwnd_);
    }
  }

  int totalW = workArea.right - workArea.left;
  int totalH = workArea.bottom - workArea.top;

  int spacingX = (std::max)(MulDiv(16, dpi, 96), static_cast<int>(totalW * 0.016));
  int spacingY = (std::max)(MulDiv(16, dpi, 96), static_cast<int>(totalH * 0.022));

  int minX = workArea.left + spacingX;
  int maxX = workArea.right - ball_size_px_ - spacingX;
  int minY = workArea.top + spacingY;
  int maxY = workArea.bottom - ball_size_px_ - spacingY;

  double curX = maxX > minX ? static_cast<double>(rect.left - minX) / (maxX - minX) : 0.0;
  double curY = maxY > minY ? static_cast<double>(rect.top - minY) / (maxY - minY) : 0.0;

  // Discrete corner snap: 0.0 (left/top) or 1.0 (right/bottom)
  norm_x_ = curX < 0.5 ? 0.0 : 1.0;
  norm_y_ = curY < 0.5 ? 0.0 : 1.0;

  int targetX = norm_x_ == 0.0 ? minX : maxX;
  int targetY = norm_y_ == 0.0 ? minY : maxY;

  SetWindowPos(hwnd_, HWND_TOPMOST, targetX, targetY, ball_size_px_, ball_size_px_, SWP_NOACTIVATE);

  SavePersistedCorner(norm_x_, norm_y_);

  if (on_position_changed_) {
    on_position_changed_(norm_x_, norm_y_);
  }
}

void AssistiveBallWindow::ShowThemedMenu() {
  if (menu_hwnd_) {
    HideThemedMenu();
    return;
  }

  RECT ballRect;
  GetWindowRect(hwnd_, &ballRect);

  HMONITOR hMon = MonitorFromWindow(hwnd_, MONITOR_DEFAULTTONEAREST);
  MONITORINFO mi = {sizeof(mi)};
  GetMonitorInfo(hMon, &mi);
  RECT workArea = mi.rcWork;

  bool isLeft = (ballRect.left - workArea.left) < ((workArea.right - workArea.left) / 2);
  bool isTop = (ballRect.top - workArea.top) < ((workArea.bottom - workArea.top) / 2);

  int menuX = isLeft ? ballRect.right + 12 : ballRect.left - menu_width_px_ - 12;
  int menuY = isTop ? ballRect.top : ballRect.bottom - menu_height_px_;

  menuX = (std::max)(static_cast<int>(workArea.left + 8),
                     (std::min)(menuX, static_cast<int>(workArea.right - menu_width_px_ - 8)));
  menuY = (std::max)(static_cast<int>(workArea.top + 8),
                     (std::min)(menuY, static_cast<int>(workArea.bottom - menu_height_px_ - 8)));

  HINSTANCE hInstance = GetModuleHandle(nullptr);
  menu_hwnd_ = CreateWindowExW(
      WS_EX_TOPMOST | WS_EX_TOOLWINDOW | WS_EX_LAYERED,
      kAssistiveBallMenuClassName, L"Ketion Overlay Menu", WS_POPUP,
      menuX, menuY, menu_width_px_, menu_height_px_,
      hwnd_, nullptr, hInstance, this);

  if (!menu_hwnd_) return;

  SetLayeredWindowAttributes(menu_hwnd_, RGB(0, 0, 0), 250, LWA_ALPHA);
  HRGN rgn = CreateRoundRectRgn(0, 0, menu_width_px_, menu_height_px_, 14, 14);
  SetWindowRgn(menu_hwnd_, rgn, TRUE);

  ShowWindow(menu_hwnd_, SW_SHOW);
  SetForegroundWindow(menu_hwnd_);
}

void AssistiveBallWindow::HideThemedMenu() {
  if (menu_hwnd_) {
    DestroyWindow(menu_hwnd_);
    menu_hwnd_ = nullptr;
    hovered_menu_item_ = -1;
  }
}

void AssistiveBallWindow::Paint(HWND hwnd) {
  PAINTSTRUCT ps;
  HDC hdc = BeginPaint(hwnd, &ps);
  RECT rect;
  GetClientRect(hwnd, &rect);

  HBRUSH bgBrush = CreateSolidBrush(kColorKey);
  FillRect(hdc, &rect, bgBrush);
  DeleteObject(bgBrush);

  // Ketion Accent Purple
  HBRUSH ballBrush = CreateSolidBrush(RGB(98, 0, 238));
  HPEN ballPen = CreatePen(PS_SOLID, 1, RGB(98, 0, 238));
  HGDIOBJ oldBrush = SelectObject(hdc, ballBrush);
  HGDIOBJ oldPen = SelectObject(hdc, ballPen);
  Ellipse(hdc, 0, 0, rect.right, rect.bottom);

  // White multi-node bubble icon matching Flutter bubble_chart_rounded
  HBRUSH whiteBrush = CreateSolidBrush(RGB(255, 255, 255));
  HPEN nullPen = CreatePen(PS_NULL, 0, RGB(0, 0, 0));
  SelectObject(hdc, whiteBrush);
  SelectObject(hdc, nullPen);

  int cx = rect.right / 2;
  int cy = rect.bottom / 2;
  int sz = rect.right;

  int r1 = static_cast<int>(sz * 0.15);
  int x1 = cx - static_cast<int>(sz * 0.10);
  int y1 = cy + static_cast<int>(sz * 0.08);
  Ellipse(hdc, x1 - r1, y1 - r1, x1 + r1, y1 + r1);

  int r2 = static_cast<int>(sz * 0.12);
  int x2 = cx + static_cast<int>(sz * 0.10);
  int y2 = cy - static_cast<int>(sz * 0.10);
  Ellipse(hdc, x2 - r2, y2 - r2, x2 + r2, y2 + r2);

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

void AssistiveBallWindow::PaintMenu(HWND hwnd) {
  PAINTSTRUCT ps;
  HDC hdc = BeginPaint(hwnd, &ps);
  RECT rect;
  GetClientRect(hwnd, &rect);

  UINT dpi = 96;
  HMODULE user32 = GetModuleHandleW(L"user32.dll");
  if (user32) {
    typedef UINT(WINAPI * GetDpiForWindowFn)(HWND);
    auto getDpiFn = reinterpret_cast<GetDpiForWindowFn>(GetProcAddress(user32, "GetDpiForWindow"));
    if (getDpiFn) {
      dpi = getDpiFn(hwnd);
    }
  }

  // Background matching Ketion Dark Theme Surface (#2A2D32)
  HBRUSH bgBrush = CreateSolidBrush(RGB(42, 45, 50));
  HPEN borderPen = CreatePen(PS_SOLID, 1, RGB(62, 65, 72));
  HGDIOBJ oldBrush = SelectObject(hdc, bgBrush);
  HGDIOBJ oldPen = SelectObject(hdc, borderPen);
  RoundRect(hdc, rect.left, rect.top, rect.right, rect.bottom, MulDiv(14, dpi, 96), MulDiv(14, dpi, 96));

  SetBkMode(hdc, TRANSPARENT);

  int textFontSize = MulDiv(14, dpi, 96);
  int iconSize = MulDiv(18, dpi, 96);

  HFONT hFontText = CreateFontW(textFontSize, 0, 0, 0, FW_SEMIBOLD, FALSE, FALSE, FALSE,
                                DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,
                                CLEARTYPE_QUALITY, DEFAULT_PITCH | FF_DONTCARE, L"Segoe UI");

  int padX = MulDiv(6, dpi, 96);
  int padY = MulDiv(6, dpi, 96);
  int itemH = MulDiv(40, dpi, 96);
  int itemRad = MulDiv(8, dpi, 96);

  // Material 3 Dark theme colors
  COLORREF textNormal = RGB(226, 226, 230);      // onSurface
  COLORREF textHover = RGB(255, 255, 255);
  COLORREF iconNormal = RGB(196, 199, 207);      // onSurfaceVariant
  COLORREF iconHover = RGB(187, 134, 252);       // Ketion purple accent

  auto drawItem = [&](int index, int topY, const wchar_t* text, void (*drawIconFn)(HDC, int, int, int, COLORREF)) {
    int bottomY = topY + itemH;
    RECT itemRect = {padX, topY, rect.right - padX, bottomY};
    bool isHover = (hovered_menu_item_ == index);

    if (isHover) {
      HRGN hoverRgn = CreateRoundRectRgn(itemRect.left, itemRect.top, itemRect.right, itemRect.bottom, itemRad, itemRad);
      HBRUSH hHover = CreateSolidBrush(RGB(58, 55, 75));
      FillRgn(hdc, hoverRgn, hHover);
      DeleteObject(hHover);
      DeleteObject(hoverRgn);
    }

    COLORREF curIconColor = isHover ? iconHover : iconNormal;
    COLORREF curTextColor = isHover ? textHover : textNormal;

    // Draw Vector Icon
    int iconCenterX = itemRect.left + MulDiv(20, dpi, 96);
    int iconCenterY = topY + itemH / 2;
    drawIconFn(hdc, iconCenterX, iconCenterY, iconSize, curIconColor);

    // Draw Label Text
    SelectObject(hdc, hFontText);
    SetTextColor(hdc, curTextColor);
    RECT textRect = {itemRect.left + MulDiv(38, dpi, 96), itemRect.top, itemRect.right - MulDiv(8, dpi, 96), itemRect.bottom};
    DrawTextW(hdc, text, -1, &textRect, DT_LEFT | DT_VCENTER | DT_SINGLELINE);
  };

  int y0 = padY;
  drawItem(0, y0, L"Quick Note", DrawQuickNoteVector);

  int y1 = y0 + itemH + MulDiv(2, dpi, 96);
  drawItem(1, y1, L"Note Selector", DrawNoteSelectorVector);

  // Subtle Divider line
  int divY = y1 + itemH + MulDiv(4, dpi, 96);
  HPEN divPen = CreatePen(PS_SOLID, 1, RGB(55, 58, 65));
  SelectObject(hdc, divPen);
  MoveToEx(hdc, MulDiv(12, dpi, 96), divY, nullptr);
  LineTo(hdc, rect.right - MulDiv(12, dpi, 96), divY);
  DeleteObject(divPen);

  int y2 = divY + MulDiv(4, dpi, 96);
  drawItem(2, y2, L"Hide Ball", DrawHideBallVector);

  DeleteObject(hFontText);

  SelectObject(hdc, oldBrush);
  SelectObject(hdc, oldPen);
  DeleteObject(bgBrush);
  DeleteObject(borderPen);

  EndPaint(hwnd, &ps);
}

// static
LRESULT CALLBACK AssistiveBallWindow::WndProc(HWND hwnd, UINT message,
                                              WPARAM wparam, LPARAM lparam) {
  if (message == WM_NCCREATE) {
    auto cs = reinterpret_cast<CREATESTRUCT*>(lparam);
    SetWindowLongPtr(hwnd, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(cs->lpCreateParams));
    auto that = static_cast<AssistiveBallWindow*>(cs->lpCreateParams);
    that->hwnd_ = hwnd;
  } else if (auto that = reinterpret_cast<AssistiveBallWindow*>(GetWindowLongPtr(hwnd, GWLP_USERDATA))) {
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
    case WM_MOUSEACTIVATE:
      return MA_NOACTIVATE;
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

      HWND fg = ::GetForegroundWindow();
      was_in_app_ = (fg == main_window_ || ::GetAncestor(fg, GA_ROOT) == main_window_) &&
                    ::IsWindowVisible(main_window_) && !::IsIconic(main_window_);
      return 0;
    }
    case WM_RBUTTONDOWN: {
      HWND fg = ::GetForegroundWindow();
      was_in_app_ = (fg == main_window_ || ::GetAncestor(fg, GA_ROOT) == main_window_) &&
                    ::IsWindowVisible(main_window_) && !::IsIconic(main_window_);
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
          HideThemedMenu();
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
          ShowThemedMenu();
        } else {
          SnapToNearestCorner();
        }
      }
      return 0;
    }
    case WM_RBUTTONUP:
      ShowThemedMenu();
      return 0;
    case WM_DESTROY:
      hwnd_ = nullptr;
      return 0;
  }
  return DefWindowProc(hwnd, message, wparam, lparam);
}

// static
LRESULT CALLBACK AssistiveBallWindow::MenuWndProc(HWND hwnd, UINT message,
                                                  WPARAM wparam, LPARAM lparam) {
  if (message == WM_NCCREATE) {
    auto cs = reinterpret_cast<CREATESTRUCT*>(lparam);
    SetWindowLongPtr(hwnd, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(cs->lpCreateParams));
    auto that = static_cast<AssistiveBallWindow*>(cs->lpCreateParams);
    that->menu_hwnd_ = hwnd;
  } else if (auto that = reinterpret_cast<AssistiveBallWindow*>(GetWindowLongPtr(hwnd, GWLP_USERDATA))) {
    return that->MenuMessageHandler(hwnd, message, wparam, lparam);
  }
  return DefWindowProc(hwnd, message, wparam, lparam);
}

LRESULT AssistiveBallWindow::MenuMessageHandler(HWND hwnd, UINT message,
                                                WPARAM wparam, LPARAM lparam) {
  switch (message) {
    case WM_PAINT:
      PaintMenu(hwnd);
      return 0;
    case WM_ERASEBKGND:
      return 1;
    case WM_KILLFOCUS:
      HideThemedMenu();
      return 0;
    case WM_MOUSEMOVE: {
      int y = HIWORD(lparam);
      UINT dpi = 96;
      HMODULE user32 = GetModuleHandleW(L"user32.dll");
      if (user32) {
        typedef UINT(WINAPI * GetDpiForWindowFn)(HWND);
        auto getDpiFn = reinterpret_cast<GetDpiForWindowFn>(GetProcAddress(user32, "GetDpiForWindow"));
        if (getDpiFn) dpi = getDpiFn(hwnd);
      }
      int padY = MulDiv(6, dpi, 96);
      int itemH = MulDiv(40, dpi, 96);
      int gap = MulDiv(2, dpi, 96);
      int divH = MulDiv(8, dpi, 96);

      int y0 = padY;
      int y1 = y0 + itemH + gap;
      int y2 = y1 + itemH + divH;

      int newHover = -1;
      if (y >= y0 && y < y0 + itemH) newHover = 0;
      else if (y >= y1 && y < y1 + itemH) newHover = 1;
      else if (y >= y2 && y < y2 + itemH) newHover = 2;

      if (newHover != hovered_menu_item_) {
        hovered_menu_item_ = newHover;
        InvalidateRect(hwnd, nullptr, FALSE);
      }

      TRACKMOUSEEVENT tme = {sizeof(TRACKMOUSEEVENT), TME_LEAVE, hwnd, 0};
      TrackMouseEvent(&tme);
      return 0;
    }
    case WM_MOUSELEAVE:
      hovered_menu_item_ = -1;
      InvalidateRect(hwnd, nullptr, FALSE);
      return 0;
    case WM_LBUTTONUP: {
      int clickedItem = hovered_menu_item_;
      bool in_app = was_in_app_;
      HideThemedMenu();
      if (clickedItem == 0) {
        if (on_action_) on_action_("openQuickNote", in_app);
      } else if (clickedItem == 1) {
        if (on_action_) on_action_("openNoteSelector", in_app);
      } else if (clickedItem == 2) {
        Hide();
        if (on_action_) on_action_("hideOverlay", in_app);
      }
      return 0;
    }
    case WM_DESTROY:
      menu_hwnd_ = nullptr;
      return 0;
  }
  return DefWindowProc(hwnd, message, wparam, lparam);
}
