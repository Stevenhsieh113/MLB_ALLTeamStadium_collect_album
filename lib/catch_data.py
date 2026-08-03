import os
import json
import requests

# 1. 建立存放照片的資料夾（直接對應未來 Flutter 的 assets 結構）
os.makedirs("assets/stadium_photos", exist_ok=True)

# 模擬你爬蟲抓下來的 30 座球場資料（這裡以洋基和道奇示範邏輯）
scraped_data = [
    {
        "team": "New York Yankees",
        "stadium_name": "Yankee Stadium",
        "league": "AL",
        "team_color": "#0C2340",
        "latitude": 40.8296,
        "longitude": -73.9262,
        "description": "百年邪惡帝國的傳奇主場",
        "image_url": "https://upload.wikimedia.org/wikipedia/commons/e/e4/Yankee_Stadium_2021.jpg" # 爬蟲抓到的網址
    },
    {
        "team": "Los Angeles Dodgers",
        "stadium_name": "Dodger Stadium",
        "league": "NL",
        "team_color": "#005A9C",
        "latitude": 34.0739,
        "longitude": -118.2400,
        "description": "好萊塢星光閃耀的西岸棒球聖地",
        "image_url": "https://upload.wikimedia.org/wikipedia/commons/6/69/Dodger_Stadium_pano_2023.jpg"
    }
    # ... 爬蟲迴圈自動往下跑完 30 個
]

flutter_stadiums_list = []

for stadium in scraped_data:
    # 2. 自動幫圖片命名，並下載存到本地
    file_name = f"{stadium['stadium_name'].lower().replace(' ', '_')}.jpg"
    local_image_path = f"assets/stadium_photos/{file_name}"
    
    # 實際下載圖片並存檔
    try:
        img_data = requests.get(stadium["image_url"], timeout=10).content
        with open(local_image_path, 'wb') as handler:
            handler.write(img_data)
        print(f"成功下載: {file_name}")
    except Exception as e:
        print(f"圖片下載失敗: {stadium['stadium_name']}, 錯誤: {e}")

    # 3. 重新整理成 Flutter 最愛讀的乾淨 JSON 資料庫
    flutter_stadiums_list.append({
        "team": stadium["team"],
        "name": stadium["stadium_name"],
        "league": stadium["league"],
        "teamColor": stadium["team_color"],
        "latitude": stadium["latitude"],
        "longitude": stadium["longitude"],
        "description": stadium["description"],
        "localImagePath": local_image_path # 讓 Flutter 直接讀地端的這張圖！
    })

# 4. 把所有資料匯出成一份單一的文字檔案
with open("assets/stadiums_data.json", "w", encoding="utf-8") as f:
    json.dump(flutter_stadiums_list, f, ensure_ascii=False, indent=2)

print("🎉 恭喜！Python 已經把 30 座球場的文字 JSON 與高畫質圖片整包打包好了！")