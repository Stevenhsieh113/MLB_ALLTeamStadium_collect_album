import os
import json
import time
import requests
import urllib.parse

os.makedirs("assets/stadium_photos", exist_ok=True)

with open('assets/stadiums_data.json', 'r', encoding='utf-8') as f:
    stadiums = json.load(f)

print("🚀 開始執行 MLB 球場圖片自動爬蟲 (突破 429 限制版)...\n")

# 偽裝成超標準的 Google Chrome 瀏覽器
headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8'
}

NAME_MAPPING = {
    "loanDepot park": "LoanDepot Park",
    "Angel Stadium": "Angel Stadium",
    "Great American Ball Park": "Great American Ball Park"
}

success_count = 0
skip_count = 0

for stadium in stadiums:
    stadium_name = stadium['name']
    local_path = stadium['localImagePath']
    
    if os.path.exists(local_path):
        print(f"✅ [{stadium_name}] 圖片已存在，跳過。")
        skip_count += 1
        continue

    search_title = NAME_MAPPING.get(stadium_name, stadium_name)
    encoded_title = urllib.parse.quote(search_title)
    
    api_url = f"https://en.wikipedia.org/w/api.php?action=query&titles={encoded_title}&prop=pageimages&format=json&pithumbsize=1000&redirects=1"

    try:
        res = requests.get(api_url, headers=headers)
        
        # 🛡️ 遇到 429 封鎖時的自動退避機制
        while res.status_code == 429:
            print(f"⏳ 遇到 API 流量限制 (429)！暫停 10 秒後自動重試...")
            time.sleep(10)
            res = requests.get(api_url, headers=headers)

        if res.status_code == 200:
            data = res.json()
            pages = data['query']['pages']
            page_id = list(pages.keys())[0]

            if page_id == '-1':
                print(f"❌ 找不到 [{stadium_name}] 的頁面。")
                continue

            if 'thumbnail' in pages[page_id]:
                img_url = pages[page_id]['thumbnail']['source']
                print(f"⬇️ 正在下載 [{stadium_name}] ...")
                
                img_res = requests.get(img_url, headers=headers)
                
                # 🛡️ 圖片下載也可能遇到 429，同樣進行退避
                while img_res.status_code == 429:
                    print(f"⏳ 圖片下載遇到流量限制 (429)！暫停 10 秒後自動重試...")
                    time.sleep(10)
                    img_res = requests.get(img_url, headers=headers)

                content_type = img_res.headers.get('Content-Type', '')
                if img_res.status_code == 200 and 'image' in content_type:
                    with open(local_path, 'wb') as img_file:
                        img_file.write(img_res.content)
                    success_count += 1
                else:
                    print(f"⚠️ [{stadium_name}] 下載失敗，檔案非圖片 (可能仍被封鎖)。")
            else:
                print(f"⚠️ [{stadium_name}] 找不到高畫質圖片。")
        else:
            print(f"❌ API 請求失敗，狀態碼: {res.status_code}")
            
    except Exception as e:
        print(f"🚨 爬取 [{stadium_name}] 時發生錯誤: {e}")
    
    # 💤 關鍵修改：強迫休息 2 秒！避免再次激怒維基百科伺服器
    time.sleep(2)

total_ok = success_count + skip_count
print("="*40)
print(f"🎉 爬蟲執行完畢！共成功備妥 {total_ok}/30 張球場照片！")
print("="*40)