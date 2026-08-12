import hashlib
import os
import shutil
import subprocess
import threading
import tkinter as tk
from pathlib import Path
from tkinter import messagebox, ttk


ROOT = Path(__file__).resolve().parent


def sha256(path):
    if not path.is_file():
        return None
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


class Setup(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title("env4BC 环境安装器")
        self.geometry("780x500")
        self.replace = tk.BooleanVar(value=False)
        self.status = tk.StringVar(value="正在扫描环境组件...")
        self._build()
        self.after(100, self.scan)

    def _build(self):
        frame = ttk.Frame(self, padding=24)
        frame.pack(fill="both", expand=True)
        ttk.Label(frame, text="env4BC", font=("Segoe UI", 24, "bold")).pack(anchor="w")
        ttk.Label(frame, text="只管理环境组件，不读取或修改任何配音/视频素材", font=("Segoe UI", 10)).pack(anchor="w", pady=(2, 16))
        self.tree = ttk.Treeview(frame, columns=("state", "component", "path"), show="headings", height=11)
        for key, label, width in (("state", "状态", 130), ("component", "组件", 180), ("path", "位置", 400)):
            self.tree.heading(key, text=label)
            self.tree.column(key, width=width, anchor="w")
        self.tree.pack(fill="both", expand=True)
        ttk.Checkbutton(frame, text="允许备份并替换已有不同版本的环境程序", variable=self.replace).pack(anchor="w", pady=(12, 4))
        ttk.Label(frame, text="未勾选时：已有不同版本默认保留。无论是否勾选，都不会触碰素材和项目目录。", foreground="#8a3f00").pack(anchor="w")
        ttk.Label(frame, textvariable=self.status).pack(anchor="w", pady=(10, 0))
        buttons = ttk.Frame(frame)
        buttons.pack(fill="x", pady=(12, 0))
        ttk.Button(buttons, text="重新扫描", command=self.scan).pack(side="left")
        ttk.Button(buttons, text="安装缺失组件", command=self.install).pack(side="right")

    def scan(self):
        for item in self.tree.get_children():
            self.tree.delete(item)
        local = Path(os.environ["LOCALAPPDATA"])
        checks = [
            ("Python", Path(shutil.which("py") or ""), None),
            ("ffmpeg", Path(shutil.which("ffmpeg") or ""), None),
            ("CC Switch", local / "Programs" / "CC Switch" / "cc-switch.exe", ROOT / "program" / "cc-switch" / "cc-switch.exe"),
            ("Seedance API配置工具", local / "env4BC" / "tools" / "Seedance API配置工具.exe", ROOT / "program" / "Seedance API配置工具.exe"),
        ]
        for name, target, source in checks:
            exists = bool(str(target)) and target.is_file()
            if not exists:
                state = "缺失"
            elif source and source.is_file() and sha256(target) != sha256(source):
                state = "已有不同版本"
            else:
                state = "已存在，跳过"
            self.tree.insert("", "end", values=(state, name, str(target) if str(target) else "未找到"))
        self.status.set("扫描完成。只检查声明的环境组件，没有扫描业务工作区。")

    def install(self):
        self.status.set("正在安装缺失的环境组件...")
        threading.Thread(target=self._install, daemon=True).start()

    def _install(self):
        command = ["powershell.exe", "-NoProfile", "-ExecutionPolicy", "Bypass", "-WindowStyle", "Hidden", "-File", str(ROOT / "install.ps1")]
        if self.replace.get():
            command.append("-ReplaceExisting")
        result = subprocess.run(command, capture_output=True, text=True, encoding="utf-8", errors="replace")
        if result.returncode == 0:
            self.after(0, lambda: (self.scan(), messagebox.showinfo("完成", "env4BC 已完成缺失修复。未修改任何素材目录。")))
        else:
            detail = (result.stderr or result.stdout or "未知错误")[-3000:]
            self.after(0, lambda: messagebox.showerror("失败", detail))


if __name__ == "__main__":
    Setup().mainloop()

