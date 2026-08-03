import os

# 設定你的照片資料夾路徑
folder_path = r"C:\product\tickets_album\flutter_application_1\mlb_spot"
# 這是我幫你根據截圖對應出來的「完美字典」
rename_map = {
    "Angelstadiummarch2019.jpg": "angel_stadium.jpg",
    "ATT_Sunset_Panorama_Giants.jpg": "oracle_park.jpg",        # 巨人隊 (舊稱 AT&T Park)
    "Busch_Stadium_III_Cardinal.jpg": "busch_stadium.jpg",
    "Camden_Yards_Oriole.jpg": "oriole_park_at_camden_yards.jpg",
    "Chase_Field_-_2011-07-11_-_Interior_North_Upper.jpg": "chase_field.jpg",
    "Citi_Field,_New_York_Mets.jpg": "citi_field.jpg",
    "Coors_Field_panorama_2022.jpg": "coors_field.jpg",
    "Detroit_Tigers_opening_game_at_Comerica_Parkjpg.jpg": "comerica_park.jpg",
    "dodger_stadium.jpg": "dodger_stadium.jpg",
    "Fenway_from_Legend's_Box.jpg": "fenway_park.jpg",
    "Fieldatthepark_Philly.jpg": "citizens_bank_park.jpg",      # 費城人隊
    "Globelifefield_Texas_Rangers.jpg": "globe_life_field.jpg",
    "Great_American_Ball_Park_Reds.jpg": "great_american_ball_park.jpg",
    "Guardians.jpg": "progressive_field.jpg",                   # 守護者隊
    "KC.jpg": "kauffman_stadium.jpg",                           # 皇家隊 (Kansas City)
    "Marlins_First_Pitch_at_Marlins_Park.jpg": "loandepot_park.jpg", # 馬林魚隊
    "McAfee_Coliseum_Athletics.jpg": "oakland_coliseum.jpg",    # 運動家隊 (舊稱 McAfee)
    "Milwaukee.jpg": "american_family_field.jpg",               # 釀酒人隊
    "Minute_Maid_Park_Houston.JPG": "minute_maid_park.jpg",
    "Nationals_Park.jpg": "nationals_park.jpg",
    "Petco_Park_Padres_Game.jpg": "petco_park.jpg",
    "Pittsburgh_Pirates_park.jpg": "pnc_park.jpg",              # 海盜隊
    "Rogers_Centre_2017_from_upper_deck_Blue_Jays.jpg": "rogers_centre.jpg",
    "SafecoFieldTop_Seattle.jpg": "t-mobile_park.jpg",          # 水手隊 (舊稱 Safeco)
    "SunTrust_Park_Opening_Day_Braves.jpg": "truist_park.jpg",  # 勇士隊 (舊稱 SunTrust)
    "target_field.jpg": "target_field.jpg",
    "Tropicana_Field_Playing_Field_Opening_Day_TB.JPG": "tropicana_field.jpg",
    "White_Sox.jpg": "guaranteed_rate_field.jpg",               # 白襪隊
    "Wrigley_Field_in_line_with_Chicago_Cubs.jpg": "wrigley_field.jpg",
    "yankee_stadium.jpg": "yankee_stadium.jpg"
}

print("🚀 開始執行魔法改名作業...\n")

success_count = 0

for old_name, new_name in rename_map.items():
    old_path = os.path.join(folder_path, old_name)
    new_path = os.path.join(folder_path, new_name)
    
    # 如果舊檔案存在，而且新名字不一樣，就幫它改名
    if os.path.exists(old_path) and old_name != new_name:
        os.rename(old_path, new_path)
        print(f"✅ 成功改名: {old_name[:15]}... ➔ {new_name}")
        success_count += 1
    elif not os.path.exists(old_path) and not os.path.exists(new_path):
        print(f"⚠️ 找不到檔案: {old_name}")

print(f"\n🎉 任務完成！共修改了 {success_count} 個檔案名稱。")