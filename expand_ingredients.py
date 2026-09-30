import json
import uuid
from pypinyin import lazy_pinyin, Style
import os

def create_ingredient(standard_name, aliases, category, functional=False):
    pinyin = ''.join(lazy_pinyin(standard_name))
    pinyin_initials = ''.join(lazy_pinyin(standard_name, style=Style.FIRST_LETTER))
    entry = {
        "id": str(uuid.uuid4()),
        "standard_name": standard_name,
        "aliases": aliases,
        "pinyin": pinyin,
        "pinyin_initials": pinyin_initials,
        "category": category
    }
    if functional:
        entry["attributes"] = {
            "functional": {
                "value": True,
                "source": "人工填写",
                "status": "verified"
            }
        }
    return entry

# Map category names to actual file names
category_files = {}
for f in os.listdir('server/data/ingredients/'):
    if f.endswith('.json') and f != 'manifest.json':
        category_name = f.replace('.json', '')
        category_files[category_name] = f

print("Available categories:", list(category_files.keys()))

# New ingredients to add - about 30-40 more
new_ingredients = {
    "菌菇": [
        ("黑木耳", ["木耳"], False),
        ("银耳", ["白木耳"], False),
        ("茶树菇", ["茶薪菇"], False),
        ("杏鲍菇", ["刺芹侧耳"], False),
        ("猴头菇", ["猴头蘑"], False),
        ("牛肝菌", ["美味牛肝菌"], False),
    ],
    "坚果干货": [
        ("腰果", ["鸡腰果"], False),
        ("开心果", ["阿月浑子"], False),
        ("松子", ["松子仁"], False),
        ("夏威夷果", ["澳洲坚果"], False),
    ],
    "蛋奶": [
        ("奶酪", ["芝士", "起司"], False),
        ("黄油", ["牛油", "butter"], False),
        ("奶油", ["淡奶油", "鲜奶油"], False),
        ("酸奶", ["酸牛奶", "优格"], False),
    ],
    "豆制品": [
        ("豆腐皮", ["腐竹", "千张"], False),
    ],
    "调料": [
        ("酵母", ["干酵母", "活性干酵母", "酵母粉"], True),
        ("泡打粉", ["发酵粉", "baking powder"], True),
        ("小苏打", ["碳酸氢钠", "食用碱"], True),
        ("白砂糖", ["白糖", "砂糖"], False),
        ("冰糖", ["单晶冰糖", "多晶冰糖"], False),
        ("红糖", ["赤砂糖"], False),
        ("蜂蜜", ["洋槐蜜", "百花蜜"], False),
        ("白醋", ["米醋"], False),
        ("黄酒", ["料酒", "绍兴黄酒"], False),
        ("豆瓣酱", ["郫县豆瓣酱"], False),
        ("甜面酱", ["面酱"], False),
        ("蚝油", ["oyster sauce"], False),
        ("鱼露", ["fish sauce"], False),
        ("番茄酱", ["茄汁"], False),
        ("沙拉酱", ["蛋黄酱", "美乃滋"], False),
        ("芝麻酱", ["麻酱", "花生酱"], False),
    ],
    "蔬菜": [
        ("菠菜", ["波菜"], False),
        ("油麦菜", ["莜麦菜"], False),
        ("生菜", ["球生菜", "叶生菜"], False),
        ("空心菜", ["通菜", "蕹菜"], False),
        ("茼蒿", ["蓬蒿"], False),
        ("芹菜", ["西芹", "中国芹"], False),
        ("韭菜", ["韭黄"], False),
        ("豆芽", ["黄豆芽", "绿豆芽"], False),
        ("莴笋", ["莴苣", "青笋"], False),
        ("苦瓜", ["凉瓜"], False),
        ("丝瓜", ["胜瓜"], False),
        ("冬瓜", ["白瓜"], False),
        ("南瓜", ["倭瓜"], False),
        ("西葫芦", ["角瓜"], False),
        ("豇豆", ["长豆角"], False),
    ],
    "主食粮面": [
        ("糯米", ["江米"], False),
        ("黑米", ["紫米", "紫黑米"], False),
        ("小米", ["粟米"], False),
        ("燕麦", ["莜麦"], False),
        ("荞麦", ["荞麦面"], False),
        ("薏米", ["薏仁", "苡米"], False),
        ("红豆", ["赤小豆"], False),
        ("绿豆", ["青豆"], False),
        ("黑豆", ["乌豆"], False),
        ("黄豆", ["大豆"], False),
    ],
    "水果": [
        ("榴莲", ["金枕榴莲"], False),
        ("火龙果", ["红龙果", "白龙果"], False),
        ("猕猴桃", ["奇异果"], False),
        ("山竹", ["莽吉柿"], False),
        ("杨梅", ["乌梅"], False),
        ("荔枝", ["妃子笑"], False),
        ("龙眼", ["桂圆", "圆肉"], False),
        ("枇杷", ["芦橘"], False),
        ("柿子", ["柿饼"], False),
        ("石榴", ["安石榴"], False),
        ("无花果", ["映日果"], False),
    ],
    "肉禽": [
        ("牛腩", ["牛肋条肉"], False),
        ("牛腱子", ["牛键子肉"], False),
        ("鸡翅中", ["翅中"], False),
        ("鸡腿", ["琵琶腿"], False),
        ("鸭腿", ["鸭全腿"], False),
        ("羊排", ["羊肋排"], False),
        ("猪蹄", ["猪脚"], False),
        ("猪肚", ["猪胃"], False),
        ("鸡胗", ["鸡肫"], False),
    ],
    "水产": [
        ("带鱼", ["刀鱼", "鞭鱼"], False),
        ("鲳鱼", ["平鱼"], False),
        ("黄鱼", ["大黄鱼", "小黄鱼"], False),
        ("鲈鱼", ["花鲈"], False),
        ("鳕鱼", ["银鳕鱼"], False),
        ("秋刀鱼", ["竹刀鱼"], False),
        ("鱿鱼", ["枪乌贼"], False),
        ("墨鱼", ["乌贼", "花枝"], False),
        ("章鱼", ["八爪鱼"], False),
    ],
}

data_by_category = {}
for category, filename in category_files.items():
    filepath = f"server/data/ingredients/{filename}"
    with open(filepath, 'r', encoding='utf-8') as f:
        data_by_category[category] = json.load(f)

added_count = 0
for category, ingredients_list in new_ingredients.items():
    if category in data_by_category:
        for standard_name, aliases, functional in ingredients_list:
            exists = any(item['standard_name'] == standard_name for item in data_by_category[category])
            if not exists:
                new_item = create_ingredient(standard_name, aliases, category, functional)
                data_by_category[category].append(new_item)
                added_count += 1
                print(f"Added: {standard_name} to {category} (functional={functional})")
    else:
        print(f"Warning: category {category} not found in files")

for category, data in data_by_category.items():
    filename = category_files[category]
    filepath = f"server/data/ingredients/{filename}"
    with open(filepath, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        f.write('\n')

print(f"\nTotal new ingredients added: {added_count}")
total = sum(len(data) for data in data_by_category.values())
print(f"Total ingredients after expansion: {total}")
