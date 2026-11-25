import json
import os
import sys
import tkinter as tk
import urllib.parse
import urllib.request

RES_DIR = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, RES_DIR)
import weather

BG = "#0e1720"
CARD = "#14222f"
FG = "#ecf4f8"
DIM = "#9ec0d4"
ACCENT = "#40e6f5"
ACCENT_BG = "#163d4a"

class CityPicker(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title("Buscar ciudad · Clima")
        self.configure(bg=BG)
        self.resizable(False, False)
        self.attributes("-topmost", True)

        w, h = 380, 310
        sw, sh = self.winfo_screenwidth(), self.winfo_screenheight()
        self.geometry(f"{w}x{h}+{(sw-w)//2}+{(sh-h)//2}")

        self.results = []

        tk.Label(self, text="Buscar ciudad", bg=BG, fg=FG,
                 font=("Segoe UI", 12, "bold")).pack(anchor="w", padx=16, pady=(14, 2))
        tk.Label(self, text="Escribí el nombre de una ciudad y presioná Enter", bg=BG, fg=DIM,
                 font=("Segoe UI", 9)).pack(anchor="w", padx=16, pady=(0, 10))

        row = tk.Frame(self, bg=BG)
        row.pack(fill="x", padx=16)

        self.entry = tk.Entry(row, bg=CARD, fg=FG, insertbackground=ACCENT,
                              relief="flat", font=("Segoe UI", 10),
                              highlightthickness=1, highlightbackground="#254257",
                              highlightcolor=ACCENT)
        self.entry.pack(side="left", fill="x", expand=True, ipady=5, padx=(0, 8))
        self.entry.bind("<Return>", lambda e: self.do_search())
        self.entry.bind("<Escape>", lambda e: self.destroy())

        self.btn_search = tk.Button(row, text="Buscar", command=self.do_search,
                                    bg=ACCENT_BG, fg=FG, activebackground="#1f5363",
                                    activeforeground=FG, relief="flat",
                                    font=("Segoe UI", 9, "bold"), padx=12, pady=4,
                                    cursor="hand2")
        self.btn_search.pack(side="right")

        self.status = tk.Label(self, text="", bg=BG, fg=DIM, font=("Segoe UI", 9))
        self.status.pack(anchor="w", padx=16, pady=(8, 4))

        self.listbox = tk.Listbox(self, bg=CARD, fg=FG, selectbackground=ACCENT_BG,
                                  selectforeground=ACCENT, relief="flat",
                                  highlightthickness=1, highlightbackground="#223b4e",
                                  font=("Segoe UI", 10), height=6, activestyle="none")
        self.listbox.pack(fill="both", expand=True, padx=16, pady=(0, 10))
        self.listbox.bind("<Double-Button-1>", lambda e: self.apply_selected())
        self.listbox.bind("<Return>", lambda e: self.apply_selected())

        foot = tk.Frame(self, bg=BG)
        foot.pack(fill="x", padx=16, pady=(0, 14))

        tk.Button(foot, text="Cancelar", command=self.destroy,
                  bg=CARD, fg=DIM, activebackground="#1c2f40", activeforeground=FG,
                  relief="flat", font=("Segoe UI", 9), padx=12, pady=4,
                  cursor="hand2").pack(side="left")

        self.btn_ok = tk.Button(foot, text="Usar seleccionada", command=self.apply_selected,
                                bg=ACCENT_BG, fg=ACCENT, activebackground="#1f5363",
                                activeforeground=FG, relief="flat",
                                font=("Segoe UI", 9, "bold"), padx=14, pady=4,
                                cursor="hand2")
        self.btn_ok.pack(side="right")

        _, data = weather.read_vars()
        cur = data.get("WeatherCity", "")
        if cur:
            self.entry.insert(0, cur)
            self.entry.select_range(0, tk.END)
        self.entry.focus_set()
        self.after(50, self._bring_front)

    def _bring_front(self):
        self.lift()
        self.attributes("-topmost", True)
        self.focus_force()
        self.entry.focus_set()

    def do_search(self):
        q = self.entry.get().strip()
        if not q:
            return
        self.status.config(text="Buscando...", fg=ACCENT)
        self.update_idletasks()
        url = (
            f"https://geocoding-api.open-meteo.com/v1/search?"
            f"name={urllib.parse.quote(q)}&count=8&language=es&format=json"
        )
        try:
            j = weather.http_json(url)
            self.results = j.get("results") or []
            self.listbox.delete(0, tk.END)
            if not self.results:
                self.status.config(text=f"No se encontraron ciudades para \"{q}\".", fg="#ff6982")
                return
            for r in self.results:
                name = r.get("name", "")
                admin = r.get("admin1", "")
                country = r.get("country", "")
                parts = [p for p in (name, admin, country) if p]
                self.listbox.insert(tk.END, " · ".join(parts))
            self.listbox.selection_set(0)
            self.status.config(text=f"{len(self.results)} resultados (doble clic o 'Usar seleccionada')", fg=DIM)
        except Exception as e:
            self.status.config(text=f"Error de conexión: {e}", fg="#ff6982")

    def apply_selected(self):
        sel = self.listbox.curselection()
        if not sel or sel[0] >= len(self.results):
            if self.entry.get().strip():
                self.do_search()
            return
        r = self.results[sel[0]]
        name = r.get("name", "")
        cc = r.get("country_code", "")
        lat = f"{r['latitude']:.5f}"
        lon = f"{r['longitude']:.5f}"
        label = f"{name}, {cc}" if cc else name
        _, data = weather.read_vars()
        unit = data.get("WeatherUnit", "C")
        self.status.config(text=f"Actualizando clima de {label}...", fg=ACCENT)
        self.update_idletasks()
        weather.write_vars({
            "WeatherCity": name,
            "WeatherQuery": name,
            "WeatherLat": lat,
            "WeatherLon": lon,
            "WeatherLabel": label,
        })
        weather.fetch_weather(lat, lon, label, unit)
        weather.refresh_skins()
        self.destroy()

if __name__ == "__main__":
    app = CityPicker()
    app.mainloop()
