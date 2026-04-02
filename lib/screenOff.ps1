; Posted by riahc3
; Retrieved 2026-01-23, License - CC BY-SA 4.0

(Add-Type '[DllImport("user32.dll")]public static extern int SendMessage(int hWnd, int hMsg, int wParam, int lParam);' -Name a -Pas)::SendMessage(-1,0x0112,0xF170,2)
