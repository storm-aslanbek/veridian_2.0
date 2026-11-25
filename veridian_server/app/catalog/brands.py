BRANDS_BY_CATEGORY = {
    "entertainment": [
        "Kinopark", "Chaplin Cinemas", "Arman Cinema", "Ticketon", "Kassir.kz",
        "Steam", "PlayStation Store", "Xbox Store", "Nintendo eShop", "Epic Games",
        "Riot Games", "Wargaming", "Blizzard", "Roblox", "Mega Bowling",
        "Sky Zone", "Lasertag Arena", "Aqualand", "Duman Aquapark", "Astana Opera",
        "Almaty Zoo", "Fun Park", "Karaoke Box", "Quest Room", "Lumiere Cinema",
        "Tengri Park", "Billiard Club", "Mega Karting", "Cinemax", "Kinoplex",
    ],
    "food": [
        "Burger King", "KFC", "McDonald's", "Subway", "Dodo Pizza",
        "Papa Johns", "Domino's", "Starbucks", "Coffee Boom", "Gloria Jeans",
        "Salam Bro", "Del Papa", "Line Brew", "Sushi Master", "Yaposhka",
        "Hardee's", "Carl's Jr.", "Wolt", "Glovo", "Yandex Eats",
        "Chaihana Navat", "Tanuki", "Sbarro", "Bahandi", "Paul",
        "Cinnabon", "Baskin Robbins", "Coffeedelia", "Tokyo City", "Teremok",
    ],
    "groceries": [
        "Magnum", "Small", "Galmart", "Arzan", "Metro",
        "Ramstore", "Anvar", "Green", "Interfood", "Korzinka",
        "Dastarkhan", "Fix Price", "Ecomarket", "Kaspi Magazin", "Wildberries",
        "Ozon", "Lenta", "Pyaterochka", "Perekrestok", "Auchan",
        "Carrefour", "Lidl", "Spar", "Billa", "Globus",
        "Maxima", "Rimi", "VkusVill", "Azbuka Vkusa", "Mix Market",
    ],
    "services": [
        "Kazakhtelecom", "Beeline", "Kcell", "Tele2", "Altel",
        "Activ", "Yandex Go", "inDrive", "Uber", "Almaty Su",
        "Alatau Zharyk", "Astana Su Arnasy", "Astana Energosbyt", "Qazaq Gaz", "Alseco",
        "KazPost", "DHL", "CDEK", "Air Astana", "SCAT Airlines",
        "FlyArystan", "Kazakhstan Temir Zholy", "Aviata", "Chocotravel", "World Class",
        "Alem Fitness", "Invivo", "Olymp Clinic", "Europharma", "Helios Pharmacy",
    ],
    "subscriptions": [
        "Netflix", "Spotify", "YouTube Premium", "Apple Music", "iCloud",
        "Google One", "Disney+", "HBO Max", "Prime Video", "Apple TV+",
        "Okko", "Kinopoisk", "Ivi", "Megogo", "Yandex Plus",
        "Telegram Premium", "ChatGPT Plus", "Microsoft 365", "Adobe Creative Cloud", "Dropbox",
        "Notion", "Duolingo", "Coursera", "Udemy", "Canva",
        "LinkedIn Premium", "Xbox Game Pass", "PlayStation Plus", "EA Play", "Nintendo Switch Online",
    ],
}

BRANDS = [
    {"name": name, "category": category}
    for category, names in BRANDS_BY_CATEGORY.items()
    for name in names
]

CATEGORY_BY_BRAND = {brand["name"]: brand["category"] for brand in BRANDS}
