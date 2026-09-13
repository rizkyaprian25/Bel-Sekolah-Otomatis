import asyncio
import os
import edge_tts
import numpy as np
import soundfile as sf

VOICE = "id-ID-GadisNeural"

ITEMS = [
    {
        "filename": "ai_masuk_jp1.mp3",
        "text": "Memasuki jam ke 1, diharapkan seluruh siswa memasuki kelasnya masing-masing.",
        "label": "AI - Masuk Jam Ke-1",
    },
    {
        "filename": "ai_jam_ke_2.mp3",
        "text": "Memasuki jam ke 2.",
        "label": "AI - Memasuki Jam Ke-2",
    },
    {
        "filename": "ai_jam_ke_3.mp3",
        "text": "Memasuki jam ke 3.",
        "label": "AI - Memasuki Jam Ke-3",
    },
    {
        "filename": "ai_jam_ke_4.mp3",
        "text": "Memasuki jam ke 4.",
        "label": "AI - Memasuki Jam Ke-4",
    },
    {
        "filename": "ai_jam_ke_5.mp3",
        "text": "Memasuki jam ke 5.",
        "label": "AI - Memasuki Jam Ke-5",
    },
    {
        "filename": "ai_jam_ke_6.mp3",
        "text": "Memasuki jam ke 6.",
        "label": "AI - Memasuki Jam Ke-6",
    },
    {
        "filename": "ai_jam_ke_7.mp3",
        "text": "Memasuki jam ke 7.",
        "label": "AI - Memasuki Jam Ke-7",
    },
    {
        "filename": "ai_jam_ke_8.mp3",
        "text": "Memasuki jam ke 8.",
        "label": "AI - Memasuki Jam Ke-8",
    },
    {
        "filename": "ai_jam_ke_9.mp3",
        "text": "Memasuki jam ke 9.",
        "label": "AI - Memasuki Jam Ke-9",
    },
    {
        "filename": "ai_jam_ke_10.mp3",
        "text": "Memasuki jam ke 10.",
        "label": "AI - Memasuki Jam Ke-10",
    },
    {
        "filename": "ai_istirahat.mp3",
        "text": "Waktunya istirahat.",
        "label": "AI - Waktunya Istirahat",
    },
    {
        "filename": "ai_istirahat2_mbg.mp3",
        "text": "Waktunya istirahat kedua. Diharapkan perwakilan masing-masing kelas untuk mengambil M B G.",
        "label": "AI - Istirahat 2 (Pengambilan MBG)",
    },
    {
        "filename": "ai_mbg_jumat.mp3",
        "text": "Pukul 11 tepat. Diharapkan perwakilan masing-masing kelas untuk mengambil M B G.",
        "label": "AI - Pengambilan MBG Hari Jumat (Jam 11)",
    },
    {
        "filename": "ai_selesai_istirahat_jp5.mp3",
        "text": "Waktu istirahat telah selesai. Memasuki jam ke 5, diharapkan seluruh siswa memasuki kelasnya masing-masing.",
        "label": "AI - Selesai Istirahat (Masuk JP 5)",
    },
    {
        "filename": "ai_selesai_istirahat_umum.mp3",
        "text": "Waktu istirahat telah selesai, diharapkan seluruh siswa memasuki kelasnya masing-masing.",
        "label": "AI - Selesai Istirahat (Masuk Kelas)",
    },
    {
        "filename": "ai_pulang.mp3",
        "text": "Waktunya pulang.",
        "label": "AI - Waktunya Pulang",
    },
    {
        "filename": "ai_upacara.mp3",
        "text": "Jam menunjukkan pukul 7, seluruh siswa diharapkan menuju ke lapangan untuk melaksanakan upacara bendera merah putih.",
        "label": "AI - Upacara Bendera Merah Putih",
    },
    {
        "filename": "ai_senam.mp3",
        "text": "Jam menunjukkan pukul 7, seluruh siswa diharapkan menuju ke lapangan untuk melaksanakan senam pagi.",
        "label": "AI - Senam Pagi",
    },
    {
        "filename": "ai_literasi.mp3",
        "text": "Jam menunjukkan pukul 7, seluruh siswa diharapkan menuju ke lapangan untuk melaksanakan literasi atau numerasi.",
        "label": "AI - Literasi atau Numerasi",
    },
    {
        "filename": "ai_solat_dhuha.mp3",
        "text": "Jam menunjukkan pukul 7, seluruh siswa diharapkan menuju ke lapangan untuk melaksanakan solat duha bersama.",
        "label": "AI - Solat Duha Bersama",
    },
]

def maximize_audio_volume(file_path):
    data, sr = sf.read(file_path)
    peak = np.max(np.abs(data))
    if peak > 0:
        data = data / peak
    # Dynamic compression boost for clear loud PA speech
    gain = 2.4
    boosted = np.tanh(data * gain)
    boosted = boosted / np.max(np.abs(boosted)) * 0.98
    sf.write(file_path, boosted, sr)
    rms = np.sqrt(np.mean(boosted**2))
    print(f"  -> Volume maximized: Peak 0.98, RMS {rms:.3f}")

async def main():
    out_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), "assets", "sounds")
    os.makedirs(out_dir, exist_ok=True)

    for item in ITEMS:
        out_path = os.path.join(out_dir, item["filename"])
        print(f"Generating: {item['filename']} -> '{item['text']}'")
        communicate = edge_tts.Communicate(item["text"], VOICE, rate="+0%", pitch="+0Hz", volume="+100%")
        await communicate.save(out_path)
        maximize_audio_volume(out_path)
        print(f"Saved {out_path} ({os.path.getsize(out_path)} bytes)")

if __name__ == "__main__":
    asyncio.run(main())
