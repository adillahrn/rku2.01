# RKU-201

RKU-201 adalah sebuah game petualangan/RPG interaktif berbasis 2D yang dikembangkan menggunakan **Godot Engine 4**. Pemain akan diajak untuk menjelajahi berbagai area kampus seperti Koridor, Lab Komputer (Labkom), dan Ruang Kuliah Umum (RKU), berinteraksi dengan berbagai karakter, dan menyelesaikan quest.

## 🌟 Fitur Utama
- **Eksplorasi Lingkungan**: Jelajahi area kampus dengan gaya visual pixel/2D.
- **Sistem Dialog & Quest**: Sistem percakapan interaktif (Dialogue Manager) dan sistem misi (Quest UI) untuk memandu pemain.
- **Interaksi Objek**: Berinteraksi dengan komputer (Computer UI) dan objek-objek lain di dalam permainan.
- **Audio & Musik**: Dilengkapi dengan AudioManager untuk pengalaman bermain yang lebih imersif.

## 📋 Persyaratan Sistem
- **Godot Engine**: Versi **4.6** (atau lebih baru, sangat disarankan menggunakan versi 4.x yang kompatibel dengan fitur Forward Plus).

## 🚀 Cara Setup dan Menjalankan Game

1. **Unduh Godot Engine**
   Pastikan Anda sudah menginstal Godot Engine versi 4.x. Anda bisa mengunduhnya secara gratis di [Situs Resmi Godot Engine](https://godotengine.org/download).

2. **Clone / Download Repository**
   Clone repository ini atau unduh sebagai file ZIP lalu ekstrak di folder komputer Anda.
   ```bash
   git clone https://github.com/adillahrn/rku2.01.git
   ```

3. **Import Project ke Godot**
   - Buka aplikasi **Godot Engine**.
   - Pada Project Manager, klik tombol **Import**.
   - Cari dan pilih file `project.godot` yang berada di dalam folder proyek ini.
   - Klik **Import & Edit** untuk membuka proyek di dalam editor.

4. **Menjalankan Game (Play)**
   - Setelah proyek terbuka, Anda dapat menekan tombol **F5** pada keyboard atau mengklik ikon **Play** (▶️) di sudut kanan atas editor.
   - Scene utama (Intro / Main Menu) akan otomatis berjalan.

## 🎮 Kontrol Permainan
- **W / A / S / D** atau **Tombol Panah**: Bergerak (Atas/Kiri/Bawah/Kanan).
- **E**: Interaksi (Berbicara dengan NPC, menggunakan komputer, dll).
- **Mouse / Klik Kiri**: Navigasi UI dan Menu.

## 📂 Struktur Folder
- `assets/` : Menyimpan aset gambar, sprite, suara, dan sumber daya visual/audio lainnya.
- `scenes/` : Menyimpan semua file `.tscn` (scene Godot) seperti Main Menu, Player, Koridor, dll.
- `scripts/` : Menyimpan semua file `.gd` (skrip GDScript) untuk logika permainan.
- `project.godot` : File konfigurasi utama proyek.

## 🛠️ Pengembangan
Game ini menggunakan GDScript. Beberapa komponen utama yang bisa dipelajari jika Anda ingin berkontribusi:
- `DialogueManager` & `AudioManager` diatur sebagai *Autoload/Singleton* sehingga dapat diakses dari scene mana saja.
- UI Khusus seperti `quest_ui.tscn` dan `computer_ui.tscn` menangani interaksi spesifik pemain.


