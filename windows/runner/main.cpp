#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>
#include <shlobj.h>
#include <propkey.h>
#include <propvarutil.h>
#include <string>

#include "flutter_window.h"
#include "utils.h"

constexpr wchar_t kKetionAppUserModelId[] = L"com.ketion.app";

void RegisterKetionToastIdentity() {
  HRESULT identityResult =
      ::SetCurrentProcessExplicitAppUserModelID(kKetionAppUserModelId);
  if (FAILED(identityResult)) {
    ::OutputDebugStringW(
        L"Ketion: Failed to register Windows toast identity.\n");
    return;
  }

  PWSTR programsPath = nullptr;
  if (FAILED(::SHGetKnownFolderPath(
          FOLDERID_Programs, KF_FLAG_CREATE, nullptr, &programsPath))) {
    ::OutputDebugStringW(
        L"Ketion: Failed to retrieve Start Menu programs folder path.\n");
    return;
  }

  std::wstring shortcutPath(programsPath);
  ::CoTaskMemFree(programsPath);
  shortcutPath += L"\\Ketion.lnk";

  wchar_t exePath[MAX_PATH];
  DWORD pathLen = ::GetModuleFileNameW(nullptr, exePath, MAX_PATH);
  if (pathLen == 0 || pathLen >= MAX_PATH) {
    ::OutputDebugStringW(
        L"Ketion: Failed to retrieve executable module file name.\n");
    return;
  }

  IShellLinkW* shellLink = nullptr;
  HRESULT hr = ::CoCreateInstance(CLSID_ShellLink, nullptr, CLSCTX_INPROC_SERVER,
                                  IID_PPV_ARGS(&shellLink));
  if (FAILED(hr)) {
    ::OutputDebugStringW(
        L"Ketion: Failed to create ShellLink instance.\n");
    return;
  }

  shellLink->SetPath(exePath);

  std::wstring exeDir(exePath);
  size_t lastSlash = exeDir.find_last_of(L"\\/");
  if (lastSlash != std::wstring::npos) {
    shellLink->SetWorkingDirectory(exeDir.substr(0, lastSlash).c_str());
  }

  IPropertyStore* propStore = nullptr;
  hr = shellLink->QueryInterface(IID_PPV_ARGS(&propStore));
  if (SUCCEEDED(hr)) {
    PROPVARIANT pv;
    hr = ::InitPropVariantFromString(kKetionAppUserModelId, &pv);
    if (SUCCEEDED(hr)) {
      hr = propStore->SetValue(PKEY_AppUserModel_ID, pv);
      if (FAILED(hr)) {
        ::OutputDebugStringW(
            L"Ketion: Failed to set AppUserModelID property on shortcut.\n");
      }
      hr = propStore->Commit();
      if (FAILED(hr)) {
        ::OutputDebugStringW(
            L"Ketion: Failed to commit property store on shortcut.\n");
      }
      ::PropVariantClear(&pv);
    } else {
      ::OutputDebugStringW(
          L"Ketion: Failed to initialize PropVariant from AppUserModelId string.\n");
    }
    propStore->Release();
  } else {
    ::OutputDebugStringW(
        L"Ketion: Failed to query IPropertyStore on shortcut.\n");
  }

  IPersistFile* persistFile = nullptr;
  hr = shellLink->QueryInterface(IID_PPV_ARGS(&persistFile));
  if (SUCCEEDED(hr)) {
    hr = persistFile->Save(shortcutPath.c_str(), TRUE);
    if (FAILED(hr)) {
      ::OutputDebugStringW(
          L"Ketion: Failed to save shortcut to Start Menu.\n");
    }
    persistFile->Release();
  } else {
    ::OutputDebugStringW(
        L"Ketion: Failed to query IPersistFile on shortcut.\n");
  }

  shellLink->Release();
}

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  RegisterKetionToastIdentity();

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"ketion", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
