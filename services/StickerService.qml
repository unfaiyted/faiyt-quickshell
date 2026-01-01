pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: stickerService

    // State
    property var stickerPacks: []           // [{id, key, name, manifest}]
    property var loadedStickers: ({})       // {packId: [StickerData]}
    property string selectedPackId: ""
    property bool isLoading: false
    property var loadingPacks: ({})         // {packId: true} - tracks which packs are loading
    property bool isDownloading: false      // True when stickers are being downloaded

    // Paths
    readonly property string scriptPath: Qt.resolvedUrl("../scripts/sticker-decrypt.sh").toString().replace("file://", "")
    readonly property string parseScriptPath: Qt.resolvedUrl("../scripts/parse-sticker-manifest.py").toString().replace("file://", "")
    readonly property string cacheDir: (Quickshell.env("XDG_CACHE_HOME") || Quickshell.env("HOME") + "/.cache") + "/faiyt-qs/stickers"

    // Emoji search keywords mapping - comprehensive list for sticker search
    property var emojiKeywords: ({
        // Smileys & Emotion - Happy/Positive
        "😀": ["happy", "smile", "grin", "face", "joy"],
        "😃": ["happy", "smile", "grin", "joy", "excited"],
        "😄": ["happy", "smile", "grin", "laugh", "joy"],
        "😁": ["happy", "smile", "grin", "beam", "teeth"],
        "😆": ["happy", "laugh", "lol", "xd", "haha"],
        "😅": ["happy", "smile", "sweat", "nervous", "relief"],
        "🤣": ["laugh", "lol", "rofl", "funny", "hilarious"],
        "😂": ["laugh", "lol", "crying", "funny", "tears", "haha"],
        "🙂": ["smile", "happy", "slight", "ok", "fine"],
        "🙃": ["smile", "upside", "sarcasm", "irony", "silly"],
        "😉": ["wink", "flirt", "playful", "hint"],
        "😊": ["blush", "happy", "smile", "shy", "sweet"],
        "😇": ["angel", "innocent", "halo", "good", "pure"],
        "🥰": ["love", "hearts", "adore", "cute", "smitten"],
        "😍": ["love", "heart", "eyes", "crush", "adore"],
        "🤩": ["star", "eyes", "excited", "amazed", "wow"],
        "😘": ["kiss", "love", "flirt", "blow", "mwah"],
        "😗": ["kiss", "whistle", "smooch"],
        "☺️": ["smile", "happy", "blush", "content"],
        "😚": ["kiss", "blush", "smooch", "love"],
        "😙": ["kiss", "whistle", "happy"],
        "🥲": ["happy", "cry", "tears", "joy", "touched"],

        // Smileys - Playful/Silly
        "😋": ["yum", "delicious", "tasty", "food", "tongue"],
        "😛": ["tongue", "playful", "silly", "tease"],
        "😜": ["wink", "tongue", "crazy", "silly", "goofy"],
        "🤪": ["crazy", "wild", "zany", "silly", "goofy"],
        "😝": ["tongue", "silly", "bleh", "playful"],
        "🤑": ["money", "rich", "dollar", "greedy"],
        "🤗": ["hug", "embrace", "warm", "welcome"],
        "🤭": ["giggle", "oops", "cover", "shy", "tee-hee"],
        "🤫": ["shh", "quiet", "secret", "hush", "silent"],
        "🤐": ["zip", "quiet", "secret", "mum", "silent"],

        // Smileys - Thinking/Neutral
        "🤔": ["think", "hmm", "wondering", "confused", "consider"],
        "🤨": ["skeptical", "suspicious", "eyebrow", "doubt"],
        "😐": ["neutral", "meh", "straight", "blank"],
        "😑": ["expressionless", "annoyed", "meh", "blank"],
        "😶": ["silent", "speechless", "quiet", "mute"],
        "😏": ["smirk", "smug", "flirt", "sly"],
        "😒": ["unamused", "meh", "side", "bored", "annoyed"],
        "🙄": ["eyeroll", "whatever", "annoyed", "duh", "please"],
        "😬": ["grimace", "awkward", "nervous", "yikes", "oops"],
        "🤥": ["lie", "pinocchio", "fib", "false"],

        // Smileys - Sleepy/Unwell
        "😌": ["relieved", "peaceful", "calm", "content", "zen"],
        "😔": ["sad", "pensive", "down", "disappointed"],
        "😪": ["sleepy", "tired", "tear", "drowsy"],
        "🤤": ["drool", "hungry", "yum", "want", "desire"],
        "😴": ["sleep", "zzz", "tired", "snore", "nap"],
        "💤": ["sleep", "zzz", "tired", "nap", "snore"],
        "😷": ["sick", "mask", "ill", "covid", "doctor"],
        "🤒": ["sick", "fever", "ill", "thermometer"],
        "🤕": ["hurt", "injured", "bandage", "ouch"],
        "🤢": ["sick", "nauseous", "green", "gross", "ew"],
        "🤮": ["vomit", "sick", "puke", "gross", "ew"],
        "🤧": ["sneeze", "sick", "cold", "tissue", "achoo"],
        "🥵": ["hot", "sweating", "heat", "thirsty"],
        "🥶": ["cold", "freezing", "ice", "frozen", "brr"],
        "🥴": ["drunk", "woozy", "dizzy", "tipsy"],
        "😵": ["dizzy", "dead", "spiral", "knocked"],
        "🤯": ["mind", "blown", "explode", "shock", "wow"],

        // Smileys - Negative emotions
        "😕": ["confused", "sad", "disappointed", "unsure"],
        "😟": ["worried", "concerned", "sad", "anxious"],
        "🙁": ["sad", "frown", "disappointed", "unhappy"],
        "☹️": ["sad", "frown", "unhappy", "down"],
        "😮": ["surprised", "wow", "oh", "gasp"],
        "😯": ["surprised", "hushed", "wow"],
        "😲": ["astonished", "shocked", "wow", "omg"],
        "😳": ["flushed", "embarrassed", "blush", "shocked"],
        "🥺": ["pleading", "puppy", "please", "cute", "beg"],
        "😦": ["frown", "sad", "worried"],
        "😧": ["anguished", "worried", "stressed"],
        "😨": ["fear", "scared", "worried", "anxious"],
        "😰": ["anxious", "sweat", "nervous", "worried"],
        "😥": ["sad", "disappointed", "relieved", "sweat"],
        "😢": ["cry", "sad", "tear", "upset"],
        "😭": ["cry", "sad", "tears", "sob", "wail", "bawl"],
        "😱": ["scream", "fear", "scared", "horror", "omg"],
        "😖": ["confounded", "frustrated", "ugh"],
        "😣": ["persevere", "struggling", "ugh"],
        "😞": ["disappointed", "sad", "down", "dejected"],
        "😓": ["sweat", "tired", "hard", "work"],
        "😩": ["weary", "tired", "frustrated", "ugh"],
        "😫": ["tired", "exhausted", "frustrated"],
        "🥱": ["yawn", "tired", "bored", "sleepy"],

        // Smileys - Angry
        "😤": ["angry", "frustrated", "huff", "mad", "steam"],
        "😡": ["angry", "mad", "rage", "furious", "pout"],
        "😠": ["angry", "mad", "grumpy", "annoyed"],
        "🤬": ["swear", "angry", "curse", "mad", "symbols"],
        "👿": ["devil", "evil", "angry", "imp"],
        "😈": ["devil", "mischief", "evil", "naughty", "imp"],

        // Smileys - Other faces
        "💀": ["skull", "dead", "dying", "lmao", "death"],
        "☠️": ["skull", "death", "danger", "poison"],
        "💩": ["poop", "crap", "shit", "funny"],
        "🤡": ["clown", "silly", "joke", "circus"],
        "👹": ["ogre", "monster", "demon", "scary"],
        "👺": ["goblin", "tengu", "monster", "angry"],
        "👻": ["ghost", "boo", "spooky", "halloween"],
        "👽": ["alien", "ufo", "space", "extraterrestrial"],
        "👾": ["alien", "game", "space", "invader"],
        "🤖": ["robot", "bot", "machine", "ai"],
        "🎃": ["pumpkin", "halloween", "jack", "spooky"],

        // Hearts & Love
        "❤️": ["love", "heart", "red", "like"],
        "🧡": ["love", "heart", "orange"],
        "💛": ["love", "heart", "yellow", "friend"],
        "💚": ["love", "heart", "green", "envy"],
        "💙": ["love", "heart", "blue", "trust"],
        "💜": ["love", "heart", "purple"],
        "🖤": ["love", "heart", "black", "dark"],
        "🤍": ["love", "heart", "white", "pure"],
        "🤎": ["love", "heart", "brown"],
        "💔": ["broken", "heart", "sad", "heartbreak"],
        "❣️": ["love", "heart", "exclamation"],
        "💕": ["hearts", "love", "pink", "two"],
        "💞": ["hearts", "love", "revolving"],
        "💓": ["heart", "love", "beating"],
        "💗": ["heart", "love", "growing"],
        "💖": ["heart", "love", "sparkle"],
        "💘": ["heart", "love", "arrow", "cupid"],
        "💝": ["heart", "love", "ribbon", "gift"],

        // Gestures & Body
        "👍": ["thumbs", "up", "good", "ok", "yes", "approve", "like"],
        "👎": ["thumbs", "down", "bad", "no", "disapprove", "dislike"],
        "👌": ["ok", "perfect", "good", "nice", "chef"],
        "🤌": ["pinch", "italian", "chef", "perfection"],
        "✌️": ["peace", "victory", "two", "v"],
        "🤞": ["fingers", "crossed", "luck", "hope"],
        "🤟": ["love", "rock", "sign"],
        "🤘": ["rock", "metal", "horns"],
        "🤙": ["call", "shaka", "hang", "loose"],
        "👋": ["wave", "hi", "hello", "bye", "goodbye"],
        "🖐️": ["hand", "five", "high", "stop"],
        "✋": ["hand", "stop", "high", "five"],
        "🖖": ["vulcan", "spock", "trek", "live"],
        "👏": ["clap", "applause", "bravo", "congrats"],
        "🙌": ["raise", "hands", "celebration", "praise", "yay"],
        "👐": ["open", "hands", "hug"],
        "🤲": ["palms", "together", "receive"],
        "🤝": ["handshake", "deal", "agree", "partner"],
        "🙏": ["pray", "please", "thanks", "hope", "namaste"],
        "✍️": ["write", "pen", "sign"],
        "💅": ["nail", "polish", "sassy", "fabulous"],
        "🤳": ["selfie", "phone", "photo"],
        "💪": ["strong", "muscle", "flex", "power", "gym"],
        "🦾": ["robot", "arm", "prosthetic", "strong"],
        "🦿": ["leg", "prosthetic", "robot"],
        "🦵": ["leg", "kick"],
        "🦶": ["foot", "kick"],
        "👂": ["ear", "listen", "hear"],
        "👃": ["nose", "smell"],
        "🧠": ["brain", "think", "smart", "mind"],
        "👀": ["eyes", "look", "see", "watch", "stare"],
        "👁️": ["eye", "look", "see"],
        "👅": ["tongue", "lick", "taste"],
        "👄": ["lips", "mouth", "kiss"],
        "🫀": ["heart", "anatomical", "organ"],
        "🫁": ["lungs", "breathe"],
        "🦷": ["tooth", "dentist"],
        "🦴": ["bone", "skeleton"],

        // People & Expressions
        "🙈": ["monkey", "see", "no", "shy", "hide"],
        "🙉": ["monkey", "hear", "no"],
        "🙊": ["monkey", "speak", "no", "oops", "secret"],
        "💋": ["kiss", "lips", "love", "lipstick"],
        "💌": ["love", "letter", "mail", "heart"],
        "💘": ["heart", "arrow", "cupid", "love"],
        "💝": ["heart", "gift", "ribbon", "love"],
        "💖": ["sparkle", "heart", "love"],
        "💗": ["growing", "heart", "love"],
        "💓": ["beating", "heart", "love"],
        "💞": ["revolving", "hearts", "love"],
        "💕": ["two", "hearts", "love"],
        "💟": ["heart", "decoration", "love"],
        "❣️": ["heart", "exclamation", "love"],
        "💔": ["broken", "heart", "sad"],
        "🔥": ["fire", "hot", "lit", "flame", "burn"],
        "✨": ["sparkle", "magic", "shine", "star", "glitter"],
        "⭐": ["star", "favorite", "awesome", "gold"],
        "🌟": ["star", "glow", "shine", "bright"],
        "💫": ["dizzy", "star", "shooting"],
        "💥": ["boom", "explosion", "bang", "collision"],
        "💢": ["angry", "symbol", "mad"],
        "💦": ["sweat", "water", "splash", "droplets"],
        "💨": ["dash", "wind", "fast", "running"],
        "🕳️": ["hole", "void"],
        "💣": ["bomb", "boom", "explosion"],
        "💬": ["speech", "bubble", "chat", "talk"],
        "👁️‍🗨️": ["eye", "speech", "witness"],
        "🗨️": ["speech", "bubble", "left"],
        "🗯️": ["angry", "speech", "bubble"],
        "💭": ["thought", "bubble", "thinking"],
        "💤": ["sleep", "zzz", "snore", "tired"],

        // Animals
        "🐱": ["cat", "kitty", "meow", "feline"],
        "🐈": ["cat", "kitty", "feline"],
        "🐈‍⬛": ["cat", "black", "kitty"],
        "🐶": ["dog", "puppy", "woof", "canine"],
        "🐕": ["dog", "puppy", "canine"],
        "🐕‍🦺": ["service", "dog"],
        "🦮": ["guide", "dog"],
        "🐩": ["poodle", "dog", "fancy"],
        "🐺": ["wolf", "howl"],
        "🦊": ["fox", "cunning"],
        "🦝": ["raccoon", "trash", "panda"],
        "🐻": ["bear", "teddy"],
        "🐻‍❄️": ["polar", "bear", "arctic"],
        "🐼": ["panda", "bear", "cute"],
        "🐨": ["koala", "australia", "cute"],
        "🐯": ["tiger", "roar", "cat"],
        "🦁": ["lion", "king", "roar"],
        "🐮": ["cow", "moo"],
        "🐷": ["pig", "oink"],
        "🐸": ["frog", "ribbit", "kermit"],
        "🐵": ["monkey", "ape"],
        "🐔": ["chicken", "hen", "cluck"],
        "🐧": ["penguin", "cold", "cute"],
        "🐦": ["bird", "tweet"],
        "🐤": ["chick", "baby", "bird", "cute"],
        "🦆": ["duck", "quack"],
        "🦅": ["eagle", "bird", "america"],
        "🦉": ["owl", "night", "wise"],
        "🦇": ["bat", "night", "halloween"],
        "🐺": ["wolf", "howl"],
        "🐗": ["boar", "pig"],
        "🐴": ["horse", "neigh"],
        "🦄": ["unicorn", "magic", "horse", "rainbow"],
        "🐝": ["bee", "honey", "buzz"],
        "🐛": ["bug", "caterpillar"],
        "🦋": ["butterfly", "pretty"],
        "🐌": ["snail", "slow"],
        "🐞": ["ladybug", "lucky"],
        "🐜": ["ant", "bug"],
        "🦟": ["mosquito", "bug", "bite"],
        "🦗": ["cricket", "bug"],
        "🕷️": ["spider", "web", "scary"],
        "🦂": ["scorpion", "sting"],
        "🐢": ["turtle", "slow", "shell"],
        "🐍": ["snake", "hiss"],
        "🦎": ["lizard", "gecko"],
        "🦖": ["dinosaur", "trex", "rawr"],
        "🦕": ["dinosaur", "dino", "long"],
        "🐙": ["octopus", "tentacle"],
        "🦑": ["squid", "tentacle"],
        "🦐": ["shrimp", "seafood"],
        "🦞": ["lobster", "seafood"],
        "🦀": ["crab", "seafood", "pinch"],
        "🐡": ["blowfish", "fish"],
        "🐠": ["fish", "tropical"],
        "🐟": ["fish"],
        "🐬": ["dolphin", "ocean", "smart"],
        "🐳": ["whale", "ocean", "spout"],
        "🐋": ["whale", "ocean", "big"],
        "🦈": ["shark", "ocean", "jaws"],
        "🐊": ["crocodile", "gator", "reptile"],
        "🐅": ["tiger"],
        "🐆": ["leopard", "spots"],
        "🦓": ["zebra", "stripes"],
        "🦍": ["gorilla", "ape"],
        "🦧": ["orangutan", "ape"],
        "🦣": ["mammoth", "extinct"],
        "🐘": ["elephant", "trunk", "big"],
        "🦛": ["hippo", "hippopotamus"],
        "🦏": ["rhino", "horn"],
        "🐪": ["camel", "desert", "hump"],
        "🐫": ["camel", "desert", "humps"],
        "🦒": ["giraffe", "tall", "spots"],
        "🦘": ["kangaroo", "australia", "hop"],
        "🦬": ["bison", "buffalo"],
        "🐃": ["buffalo", "water"],
        "🐂": ["ox", "bull"],
        "🐄": ["cow", "moo", "milk"],
        "🐎": ["horse", "race"],
        "🐖": ["pig", "oink"],
        "🐏": ["ram", "sheep"],
        "🐑": ["sheep", "lamb", "wool"],
        "🦙": ["llama", "alpaca"],
        "🐐": ["goat"],
        "🦌": ["deer", "buck", "antlers"],
        "🐕": ["dog"],
        "🐩": ["poodle"],
        "🦮": ["guide", "dog"],
        "🐕‍🦺": ["service", "dog"],
        "🐈": ["cat"],
        "🐓": ["rooster", "cock"],
        "🦃": ["turkey", "thanksgiving"],
        "🦚": ["peacock", "feathers"],
        "🦜": ["parrot", "bird", "colorful"],
        "🦢": ["swan", "bird", "elegant"],
        "🦩": ["flamingo", "pink", "bird"],
        "🕊️": ["dove", "peace", "bird"],
        "🐇": ["rabbit", "bunny", "hop"],
        "🦔": ["hedgehog", "spiky", "cute"],
        "🦦": ["otter", "cute", "water"],
        "🦥": ["sloth", "slow", "lazy"],
        "🐁": ["mouse", "small"],
        "🐀": ["rat"],
        "🐿️": ["chipmunk", "squirrel"],
        "🦫": ["beaver", "dam"],

        // Food & Drink
        "🍏": ["apple", "green", "fruit"],
        "🍎": ["apple", "red", "fruit"],
        "🍐": ["pear", "fruit"],
        "🍊": ["orange", "fruit", "citrus"],
        "🍋": ["lemon", "yellow", "citrus", "sour"],
        "🍌": ["banana", "fruit", "yellow"],
        "🍉": ["watermelon", "fruit", "summer"],
        "🍇": ["grapes", "fruit", "wine"],
        "🍓": ["strawberry", "fruit", "red", "berry"],
        "🫐": ["blueberry", "fruit", "berry"],
        "🍈": ["melon", "fruit"],
        "🍒": ["cherry", "fruit", "red"],
        "🍑": ["peach", "fruit", "butt"],
        "🥭": ["mango", "fruit", "tropical"],
        "🍍": ["pineapple", "fruit", "tropical"],
        "🥥": ["coconut", "tropical"],
        "🥝": ["kiwi", "fruit"],
        "🍅": ["tomato", "red", "vegetable"],
        "🍆": ["eggplant", "purple", "aubergine"],
        "🥑": ["avocado", "green", "guac"],
        "🥦": ["broccoli", "vegetable", "green"],
        "🥬": ["lettuce", "vegetable", "green", "leafy"],
        "🥒": ["cucumber", "vegetable", "green"],
        "🌶️": ["pepper", "hot", "spicy", "chili"],
        "🫑": ["pepper", "bell"],
        "🌽": ["corn", "vegetable", "cob"],
        "🥕": ["carrot", "vegetable", "orange"],
        "🫒": ["olive", "green"],
        "🧄": ["garlic", "vampire"],
        "🧅": ["onion", "cry"],
        "🥔": ["potato", "vegetable"],
        "🍠": ["sweet", "potato", "yam"],
        "🥐": ["croissant", "bread", "french", "pastry"],
        "🥯": ["bagel", "bread"],
        "🍞": ["bread", "loaf", "toast"],
        "🥖": ["baguette", "bread", "french"],
        "🥨": ["pretzel", "snack"],
        "🧀": ["cheese", "yellow"],
        "🥚": ["egg"],
        "🍳": ["egg", "frying", "breakfast", "cook"],
        "🧈": ["butter"],
        "🥞": ["pancake", "breakfast", "stack"],
        "🧇": ["waffle", "breakfast"],
        "🥓": ["bacon", "breakfast", "meat"],
        "🥩": ["steak", "meat", "beef"],
        "🍗": ["chicken", "leg", "drumstick", "meat"],
        "🍖": ["meat", "bone", "rib"],
        "🦴": ["bone"],
        "🌭": ["hotdog", "sausage", "food"],
        "🍔": ["burger", "hamburger", "food", "hungry"],
        "🍟": ["fries", "french", "food", "potato"],
        "🍕": ["pizza", "food", "hungry", "slice"],
        "🫓": ["flatbread", "pita"],
        "🥪": ["sandwich", "food", "lunch"],
        "🥙": ["pita", "falafel", "wrap"],
        "🧆": ["falafel", "food"],
        "🌮": ["taco", "mexican", "food"],
        "🌯": ["burrito", "mexican", "wrap", "food"],
        "🫔": ["tamale", "mexican"],
        "🥗": ["salad", "healthy", "vegetable"],
        "🥘": ["paella", "pan", "food"],
        "🫕": ["fondue", "cheese"],
        "🍝": ["pasta", "spaghetti", "italian", "noodle"],
        "🍜": ["noodles", "ramen", "asian", "soup"],
        "🍲": ["stew", "pot", "soup"],
        "🍛": ["curry", "rice", "indian"],
        "🍣": ["sushi", "japanese", "fish"],
        "🍱": ["bento", "japanese", "box"],
        "🥟": ["dumpling", "asian", "food"],
        "🦪": ["oyster", "seafood"],
        "🍤": ["shrimp", "fried", "tempura", "seafood"],
        "🍙": ["rice", "ball", "onigiri", "japanese"],
        "🍚": ["rice", "bowl"],
        "🍘": ["rice", "cracker"],
        "🍥": ["fish", "cake", "narutomaki"],
        "🥠": ["fortune", "cookie"],
        "🥮": ["mooncake"],
        "🍢": ["oden", "skewer"],
        "🍡": ["dango", "japanese", "sweet"],
        "🍧": ["shaved", "ice", "dessert"],
        "🍨": ["ice", "cream", "dessert", "sundae"],
        "🍦": ["ice", "cream", "cone", "dessert"],
        "🥧": ["pie", "dessert"],
        "🧁": ["cupcake", "dessert", "sweet"],
        "🍰": ["cake", "dessert", "sweet", "slice"],
        "🎂": ["birthday", "cake", "celebration"],
        "🍮": ["pudding", "flan", "custard", "dessert"],
        "🍭": ["lollipop", "candy", "sweet"],
        "🍬": ["candy", "sweet"],
        "🍫": ["chocolate", "candy", "sweet"],
        "🍿": ["popcorn", "movie", "snack"],
        "🍩": ["donut", "doughnut", "sweet"],
        "🍪": ["cookie", "sweet", "biscuit"],
        "🌰": ["chestnut", "nut"],
        "🥜": ["peanut", "nut"],
        "🍯": ["honey", "sweet", "bee"],
        "🥛": ["milk", "glass", "drink"],
        "🍼": ["baby", "bottle", "milk"],
        "☕": ["coffee", "morning", "drink", "cafe", "hot"],
        "🫖": ["teapot", "tea"],
        "🍵": ["tea", "green", "drink", "matcha"],
        "🧃": ["juice", "box", "drink"],
        "🥤": ["cup", "soda", "drink", "straw"],
        "🧋": ["boba", "bubble", "tea", "milk"],
        "🍶": ["sake", "japanese", "drink"],
        "🍺": ["beer", "drink", "alcohol", "mug"],
        "🍻": ["beer", "cheers", "drink", "alcohol"],
        "🥂": ["champagne", "cheers", "celebrate", "toast"],
        "🍷": ["wine", "drink", "alcohol", "red"],
        "🥃": ["whiskey", "drink", "alcohol"],
        "🍸": ["cocktail", "martini", "drink", "alcohol"],
        "🍹": ["tropical", "drink", "cocktail"],
        "🧉": ["mate", "drink"],
        "🍾": ["champagne", "bottle", "celebrate", "pop"],
        "🧊": ["ice", "cube", "cold"],

        // Nature & Weather
        "🌸": ["flower", "cherry", "blossom", "spring", "sakura"],
        "💮": ["flower", "white"],
        "🏵️": ["rosette", "flower"],
        "🌹": ["rose", "flower", "red", "love"],
        "🥀": ["wilted", "flower", "dead", "sad"],
        "🌺": ["hibiscus", "flower"],
        "🌻": ["sunflower", "flower", "yellow"],
        "🌼": ["blossom", "flower"],
        "🌷": ["tulip", "flower"],
        "🌱": ["seedling", "plant", "grow", "sprout"],
        "🪴": ["plant", "potted"],
        "🌲": ["tree", "evergreen", "pine"],
        "🌳": ["tree", "deciduous"],
        "🌴": ["palm", "tree", "tropical", "beach"],
        "🌵": ["cactus", "desert", "plant"],
        "🌾": ["rice", "plant", "grain"],
        "🌿": ["herb", "plant", "green", "leaf"],
        "☘️": ["shamrock", "clover", "irish"],
        "🍀": ["clover", "lucky", "four", "leaf"],
        "🍁": ["maple", "leaf", "fall", "autumn", "canada"],
        "🍂": ["fallen", "leaf", "autumn", "fall"],
        "🍃": ["leaf", "wind", "blowing"],
        "🌍": ["earth", "world", "globe", "europe", "africa"],
        "🌎": ["earth", "world", "globe", "americas"],
        "🌏": ["earth", "world", "globe", "asia"],
        "🌑": ["moon", "new", "dark"],
        "🌒": ["moon", "waxing", "crescent"],
        "🌓": ["moon", "first", "quarter"],
        "🌔": ["moon", "waxing", "gibbous"],
        "🌕": ["moon", "full"],
        "🌖": ["moon", "waning", "gibbous"],
        "🌗": ["moon", "last", "quarter"],
        "🌘": ["moon", "waning", "crescent"],
        "🌙": ["moon", "crescent", "night", "sleep"],
        "🌚": ["moon", "new", "face"],
        "🌛": ["moon", "first", "quarter", "face"],
        "🌜": ["moon", "last", "quarter", "face"],
        "🌡️": ["thermometer", "temperature"],
        "☀️": ["sun", "sunny", "bright", "day", "hot"],
        "🌝": ["moon", "full", "face"],
        "🌞": ["sun", "face", "bright"],
        "🪐": ["planet", "saturn", "ring", "space"],
        "⭐": ["star", "favorite", "gold"],
        "🌟": ["star", "glowing", "shine"],
        "🌠": ["shooting", "star", "wish"],
        "🌌": ["milky", "way", "galaxy", "space", "stars"],
        "☁️": ["cloud", "weather"],
        "⛅": ["cloud", "sun", "partly"],
        "⛈️": ["cloud", "storm", "thunder", "lightning"],
        "🌤️": ["sun", "cloud", "small"],
        "🌥️": ["sun", "cloud", "large"],
        "🌦️": ["sun", "rain", "cloud"],
        "🌧️": ["cloud", "rain"],
        "🌨️": ["cloud", "snow"],
        "🌩️": ["cloud", "lightning"],
        "🌪️": ["tornado", "wind", "storm"],
        "🌫️": ["fog", "cloud"],
        "🌬️": ["wind", "blow", "face"],
        "🌀": ["cyclone", "dizzy", "spiral", "hurricane"],
        "🌈": ["rainbow", "pride", "colorful", "weather"],
        "🌂": ["umbrella", "closed", "rain"],
        "☂️": ["umbrella", "open", "rain"],
        "☔": ["umbrella", "rain", "drops"],
        "⛱️": ["umbrella", "beach", "sun"],
        "⚡": ["lightning", "bolt", "electric", "power", "zap"],
        "❄️": ["snowflake", "cold", "winter", "snow"],
        "☃️": ["snowman", "winter", "cold", "snow"],
        "⛄": ["snowman", "winter", "snow"],
        "🔥": ["fire", "hot", "lit", "flame", "burn"],
        "💧": ["droplet", "water", "tear"],
        "🌊": ["wave", "ocean", "water", "sea", "surf"],

        // Activities & Celebrations
        "🎉": ["party", "celebrate", "congrats", "tada", "confetti"],
        "🎊": ["confetti", "ball", "party", "celebrate"],
        "🎈": ["balloon", "party", "birthday"],
        "🎁": ["gift", "present", "birthday", "christmas"],
        "🎀": ["ribbon", "bow", "gift", "pink"],
        "🎄": ["christmas", "tree", "holiday"],
        "🎃": ["pumpkin", "halloween", "jack", "lantern"],
        "🎅": ["santa", "christmas", "claus"],
        "🤶": ["mrs", "claus", "christmas"],
        "🧑‍🎄": ["santa", "christmas"],
        "🎆": ["fireworks", "celebration", "new", "year"],
        "🎇": ["sparkler", "fireworks", "celebration"],
        "🧨": ["firecracker", "boom"],
        "✨": ["sparkle", "magic", "shine", "star", "glitter"],
        "🎎": ["dolls", "japanese", "festival"],
        "🎏": ["carp", "streamer", "japanese"],
        "🎐": ["wind", "chime", "japanese"],
        "🧧": ["red", "envelope", "lucky"],
        "🎑": ["moon", "ceremony"],
        "🎗️": ["ribbon", "awareness"],
        "🎟️": ["ticket", "admission"],
        "🎫": ["ticket"],

        // Sports & Games
        "⚽": ["soccer", "football", "ball", "sport"],
        "🏀": ["basketball", "ball", "sport"],
        "🏈": ["football", "american", "ball", "sport"],
        "⚾": ["baseball", "ball", "sport"],
        "🥎": ["softball", "ball", "sport"],
        "🎾": ["tennis", "ball", "sport"],
        "🏐": ["volleyball", "ball", "sport"],
        "🏉": ["rugby", "ball", "sport"],
        "🥏": ["frisbee", "disc"],
        "🎱": ["pool", "billiards", "8ball"],
        "🪀": ["yo-yo"],
        "🏓": ["ping", "pong", "table", "tennis"],
        "🏸": ["badminton", "shuttlecock"],
        "🏒": ["hockey", "ice"],
        "🏑": ["hockey", "field"],
        "🥍": ["lacrosse"],
        "🏏": ["cricket", "bat"],
        "🪃": ["boomerang"],
        "🥅": ["goal", "net"],
        "⛳": ["golf", "flag"],
        "🪁": ["kite", "fly"],
        "🏹": ["archery", "bow", "arrow"],
        "🎣": ["fishing", "pole", "rod"],
        "🤿": ["diving", "mask", "snorkel"],
        "🥊": ["boxing", "glove"],
        "🥋": ["martial", "arts", "uniform"],
        "🎽": ["running", "shirt"],
        "🛹": ["skateboard", "skate"],
        "🛼": ["roller", "skate"],
        "🛷": ["sled", "snow"],
        "⛸️": ["ice", "skate"],
        "🥌": ["curling", "stone"],
        "🎿": ["ski", "skiing", "snow"],
        "⛷️": ["skier", "skiing"],
        "🏂": ["snowboard", "snow"],
        "🪂": ["parachute", "skydive"],
        "🏋️": ["weightlifting", "gym", "lift"],
        "🤼": ["wrestling"],
        "🤸": ["cartwheel", "gymnastics"],
        "🤺": ["fencing", "sword"],
        "🏇": ["horse", "racing", "jockey"],
        "⛹️": ["basketball", "bounce"],
        "🏊": ["swimming", "swim"],
        "🚣": ["rowing", "boat"],
        "🧗": ["climbing", "rock"],
        "🚵": ["mountain", "bike", "cycling"],
        "🚴": ["bike", "cycling", "bicycle"],
        "🏆": ["trophy", "winner", "champion", "first"],
        "🥇": ["gold", "medal", "first", "winner"],
        "🥈": ["silver", "medal", "second"],
        "🥉": ["bronze", "medal", "third"],
        "🏅": ["medal", "sports"],
        "🎖️": ["medal", "military"],
        "🎮": ["game", "controller", "video", "gaming"],
        "🕹️": ["joystick", "game", "arcade"],
        "🎰": ["slot", "machine", "gambling", "casino"],
        "🎲": ["dice", "game", "roll"],
        "🧩": ["puzzle", "piece", "jigsaw"],
        "🧸": ["teddy", "bear", "toy", "cute"],
        "🪆": ["nesting", "dolls", "matryoshka"],
        "♠️": ["spade", "cards"],
        "♥️": ["heart", "cards"],
        "♦️": ["diamond", "cards"],
        "♣️": ["club", "cards"],
        "♟️": ["chess", "pawn"],
        "🎯": ["target", "bullseye", "dart"],
        "🎳": ["bowling", "pins"],
        "🎪": ["circus", "tent"],
        "🎭": ["theater", "drama", "masks", "performing"],
        "🎨": ["art", "palette", "painting", "creative"],
        "🎼": ["music", "score", "notes"],
        "🎵": ["music", "note", "song"],
        "🎶": ["music", "notes", "melody", "song"],
        "🎹": ["piano", "keyboard", "music"],
        "🥁": ["drum", "music"],
        "🎷": ["saxophone", "jazz", "music"],
        "🎺": ["trumpet", "music", "horn"],
        "🎸": ["guitar", "music", "rock"],
        "🪕": ["banjo", "music"],
        "🎻": ["violin", "music", "classical"],
        "🎤": ["microphone", "sing", "karaoke", "music"],
        "🎧": ["headphones", "music", "listen"],
        "📻": ["radio", "music"],
        "🎬": ["movie", "film", "clapper", "action"],
        "🎥": ["camera", "movie", "film"],
        "📽️": ["projector", "movie", "film"],
        "📺": ["tv", "television", "watch"],
        "📷": ["camera", "photo"],
        "📸": ["camera", "flash", "photo"],
        "📹": ["video", "camera", "record"],
        "📼": ["vhs", "tape", "video"],

        // Objects & Symbols
        "💯": ["100", "perfect", "score", "hundred"],
        "✅": ["check", "done", "complete", "yes", "correct"],
        "❌": ["x", "no", "wrong", "cancel", "cross"],
        "❓": ["question", "mark", "what"],
        "❗": ["exclamation", "alert", "important"],
        "💡": ["idea", "light", "bulb", "bright"],
        "🔔": ["bell", "notification", "alert", "ring"],
        "🔕": ["bell", "mute", "silent", "no"],
        "📢": ["loudspeaker", "announcement"],
        "📣": ["megaphone", "cheer"],
        "💬": ["speech", "bubble", "chat", "message", "talk"],
        "💭": ["thought", "bubble", "thinking"],
        "🗯️": ["angry", "speech", "shout"],
        "♨️": ["hot", "springs", "steam"],
        "💈": ["barber", "pole"],
        "🛑": ["stop", "sign", "halt"],
        "🕛": ["clock", "twelve", "noon", "midnight"],
        "⏰": ["alarm", "clock", "time", "wake"],
        "⏱️": ["stopwatch", "timer"],
        "⏲️": ["timer", "clock"],
        "🕰️": ["mantel", "clock"],
        "⌛": ["hourglass", "time", "wait"],
        "⏳": ["hourglass", "flowing", "time"],
        "📅": ["calendar", "date"],
        "📆": ["calendar", "tear"],
        "🗓️": ["calendar", "spiral"],
        "📇": ["index", "card"],
        "📈": ["chart", "up", "increase", "growth"],
        "📉": ["chart", "down", "decrease"],
        "📊": ["bar", "chart", "graph", "stats"],
        "📋": ["clipboard", "list"],
        "📌": ["pin", "pushpin", "location"],
        "📍": ["pin", "location", "map"],
        "📎": ["paperclip", "attachment"],
        "🖇️": ["paperclips", "linked"],
        "📏": ["ruler", "straight"],
        "📐": ["ruler", "triangle"],
        "✂️": ["scissors", "cut"],
        "🗃️": ["card", "file", "box"],
        "🗄️": ["file", "cabinet"],
        "🗑️": ["trash", "waste", "bin", "delete"],
        "🔒": ["lock", "locked", "secure", "private"],
        "🔓": ["unlock", "open"],
        "🔐": ["lock", "key", "secure"],
        "🔑": ["key", "unlock", "password"],
        "🗝️": ["key", "old"],
        "🔨": ["hammer", "tool", "build"],
        "🪓": ["axe", "tool", "chop"],
        "⛏️": ["pick", "mine", "tool"],
        "🔧": ["wrench", "tool", "fix"],
        "🔩": ["nut", "bolt", "screw"],
        "🪛": ["screwdriver", "tool"],
        "🔗": ["link", "chain", "connect"],
        "⛓️": ["chain", "link"],
        "🪝": ["hook"],
        "🧰": ["toolbox", "tools"],
        "🧲": ["magnet", "attract"],
        "🧪": ["test", "tube", "science", "lab"],
        "🧫": ["petri", "dish", "science"],
        "🧬": ["dna", "genetics", "science"],
        "🔬": ["microscope", "science", "lab"],
        "🔭": ["telescope", "space", "stars"],
        "📡": ["satellite", "dish", "signal"],
        "💉": ["syringe", "needle", "vaccine", "shot"],
        "🩸": ["blood", "drop"],
        "💊": ["pill", "medicine", "drug"],
        "🩹": ["bandage", "adhesive"],
        "🩺": ["stethoscope", "doctor"],
        "🚪": ["door", "entrance", "exit"],
        "🛏️": ["bed", "sleep"],
        "🛋️": ["couch", "sofa"],
        "🪑": ["chair", "seat"],
        "🚽": ["toilet", "bathroom", "wc"],
        "🚿": ["shower", "bathroom"],
        "🛁": ["bathtub", "bath"],
        "🪤": ["mouse", "trap"],
        "🪒": ["razor", "shave"],
        "🧴": ["lotion", "bottle"],
        "🧷": ["safety", "pin"],
        "🧹": ["broom", "clean", "sweep"],
        "🧺": ["basket", "laundry"],
        "🧻": ["toilet", "paper", "roll"],
        "🧼": ["soap", "clean", "wash"],
        "🪥": ["toothbrush", "brush", "teeth"],
        "🧽": ["sponge", "clean"],
        "🧯": ["fire", "extinguisher"],
        "🛒": ["shopping", "cart", "groceries"],
        "🚬": ["cigarette", "smoking"],
        "⚰️": ["coffin", "death", "funeral"],
        "⚱️": ["urn", "funeral"],
        "🏺": ["amphora", "vase"],
        "🔮": ["crystal", "ball", "fortune", "magic"],
        "📿": ["beads", "prayer"],
        "🧿": ["evil", "eye", "nazar"],
        "💎": ["gem", "diamond", "jewel", "precious"],
        "🎀": ["ribbon", "bow", "gift", "pink"],
        "💰": ["money", "bag", "rich", "cash"],
        "💵": ["money", "dollar", "cash", "bills"],
        "💸": ["money", "flying", "spending"],
        "💳": ["credit", "card", "payment"],
        "🧾": ["receipt"],
        "✉️": ["envelope", "mail", "letter", "email"],
        "📧": ["email", "mail", "message"],
        "📨": ["envelope", "incoming"],
        "📩": ["envelope", "arrow"],
        "📤": ["outbox", "send"],
        "📥": ["inbox", "receive"],
        "📦": ["package", "box", "delivery"],
        "📫": ["mailbox", "closed"],
        "📪": ["mailbox", "empty"],
        "📬": ["mailbox", "full"],
        "📭": ["mailbox", "open"],
        "📮": ["postbox", "mail"],
        "📯": ["postal", "horn"],
        "📜": ["scroll", "paper", "document"],
        "📃": ["page", "curl", "document"],
        "📄": ["page", "document", "file"],
        "📑": ["bookmark", "tabs"],
        "🧾": ["receipt"],
        "📰": ["newspaper", "news"],
        "🗞️": ["rolled", "newspaper"],
        "📁": ["folder", "file"],
        "📂": ["folder", "open"],
        "🗂️": ["dividers", "index"],
        "🗒️": ["spiral", "notepad"],
        "🗓️": ["spiral", "calendar"],
        "📓": ["notebook"],
        "📔": ["notebook", "decorative"],
        "📒": ["ledger"],
        "📕": ["book", "closed", "red"],
        "📗": ["book", "green"],
        "📘": ["book", "blue"],
        "📙": ["book", "orange"],
        "📚": ["books", "stack", "reading", "library"],
        "📖": ["book", "open", "reading"],
        "🔖": ["bookmark"],
        "🏷️": ["label", "tag"],
        "✏️": ["pencil", "write", "edit"],
        "✒️": ["pen", "nib", "write"],
        "🖊️": ["pen", "write"],
        "🖋️": ["fountain", "pen"],
        "🖌️": ["paintbrush", "art"],
        "🖍️": ["crayon", "draw"],
        "📝": ["memo", "note", "write", "edit"],
        "💻": ["laptop", "computer", "work", "tech"],
        "🖥️": ["desktop", "computer", "monitor"],
        "🖨️": ["printer"],
        "⌨️": ["keyboard", "type"],
        "🖱️": ["mouse", "computer", "click"],
        "🖲️": ["trackball"],
        "💽": ["disc", "minidisc"],
        "💾": ["floppy", "disk", "save"],
        "💿": ["cd", "disc"],
        "📀": ["dvd", "disc"],
        "🧮": ["abacus", "calculate"],
        "🎞️": ["film", "frames"],
        "📞": ["phone", "telephone", "call"],
        "☎️": ["telephone", "call"],
        "📟": ["pager"],
        "📠": ["fax", "machine"],
        "📱": ["phone", "mobile", "cell", "smartphone"],
        "📲": ["phone", "arrow", "mobile"],
        "🔋": ["battery", "power", "charge"],
        "🔌": ["plug", "electric", "power"],
        "💡": ["light", "bulb", "idea", "bright"],
        "🔦": ["flashlight", "torch", "light"],
        "🕯️": ["candle", "light"],
        "🪔": ["lamp", "diya", "oil"],
        "🧯": ["fire", "extinguisher"],
        "🛢️": ["oil", "drum", "barrel"],
        "💸": ["money", "wings", "flying", "spending"],
        "⚙️": ["gear", "settings", "cog"],
        "🛠️": ["tools", "hammer", "wrench"],
        "⚖️": ["scale", "balance", "justice", "law"],
        "🦯": ["cane", "blind", "accessibility"],
        "🔗": ["link", "chain", "url"],
        "⛓️": ["chains"],
        "🧲": ["magnet"],
        "⚗️": ["alembic", "chemistry"],
        "🔬": ["microscope", "science"],
        "🔭": ["telescope", "space"],
        "📈": ["chart", "increasing", "growth", "up"],
        "📉": ["chart", "decreasing", "down"],
        "📊": ["bar", "chart", "stats", "data"],
        "🔍": ["magnifying", "glass", "search", "zoom"],
        "🔎": ["magnifying", "glass", "right", "search"],
        "🔴": ["red", "circle", "record"],
        "🟠": ["orange", "circle"],
        "🟡": ["yellow", "circle"],
        "🟢": ["green", "circle", "go"],
        "🔵": ["blue", "circle"],
        "🟣": ["purple", "circle"],
        "🟤": ["brown", "circle"],
        "⚫": ["black", "circle"],
        "⚪": ["white", "circle"],
        "🟥": ["red", "square"],
        "🟧": ["orange", "square"],
        "🟨": ["yellow", "square"],
        "🟩": ["green", "square"],
        "🟦": ["blue", "square"],
        "🟪": ["purple", "square"],
        "⬛": ["black", "square"],
        "⬜": ["white", "square"],
        "◼️": ["black", "square", "medium"],
        "◻️": ["white", "square", "medium"],
        "▪️": ["black", "square", "small"],
        "▫️": ["white", "square", "small"],
        "🔶": ["orange", "diamond", "large"],
        "🔷": ["blue", "diamond", "large"],
        "🔸": ["orange", "diamond", "small"],
        "🔹": ["blue", "diamond", "small"],
        "🔺": ["red", "triangle", "up"],
        "🔻": ["red", "triangle", "down"],
        "💠": ["diamond", "cute"],
        "🔘": ["radio", "button"],
        "🔳": ["white", "square", "button"],
        "🔲": ["black", "square", "button"]
    })

    // Initialize
    Component.onCompleted: {
        ensureCacheDir()
        console.log("StickerService: Component.onCompleted, ConfigService.configLoaded =", ConfigService.configLoaded)
        // Wait for config to be loaded before loading packs
        if (ConfigService.configLoaded) {
            loadPacksFromConfig()
        }
    }

    // Watch for config loaded
    Connections {
        target: ConfigService
        function onConfigLoadedChanged() {
            console.log("StickerService: onConfigLoadedChanged, configLoaded =", ConfigService.configLoaded)
            if (ConfigService.configLoaded) {
                loadPacksFromConfig()
            }
        }
        // Also watch for config changes directly
        function onConfigChanged() {
            console.log("StickerService: onConfigChanged triggered")
            if (ConfigService.configLoaded && stickerPacks.length === 0) {
                loadPacksFromConfig()
            }
        }
    }

    // Fallback timer in case signals are missed
    Timer {
        id: loadFallbackTimer
        interval: 500
        running: true
        repeat: false
        onTriggered: {
            console.log("StickerService: Fallback timer triggered, packs loaded:", stickerPacks.length)
            if (stickerPacks.length === 0 && ConfigService.configLoaded) {
                loadPacksFromConfig()
            }
        }
    }

    // Ensure cache directory exists
    function ensureCacheDir() {
        mkdirProcess.running = true
    }

    Process {
        id: mkdirProcess
        command: ["mkdir", "-p", cacheDir]
    }

    // Load packs from ConfigService
    function loadPacksFromConfig() {
        // Read directly from config object to avoid binding issues
        const packs = ConfigService.config?.stickers?.packs || []
        console.log("StickerService: loadPacksFromConfig called")
        console.log("  - ConfigService.configLoaded:", ConfigService.configLoaded)
        console.log("  - Packs found:", packs.length)
        if (packs.length > 0) {
            console.log("  - Pack IDs:", packs.map(p => p.id).join(", "))
            loadStickerPacks(packs)
        } else {
            console.log("  - No packs to load")
        }
    }

    // Queue for loading packs sequentially
    property var packLoadQueue: []

    // Load sticker packs metadata
    function loadStickerPacks(packConfigs) {
        console.log("StickerService: Loading", packConfigs.length, "sticker packs")
        isLoading = true
        stickerPacks = []
        packLoadQueue = []

        for (let config of packConfigs) {
            const pack = {
                id: config.id,
                key: config.key,
                name: config.name || "Sticker Pack",
                manifest: null,
                coverEmoji: "📦"
            }
            stickerPacks.push(pack)
            packLoadQueue.push({ id: config.id, key: config.key })
        }

        // Trigger reactive update
        stickerPacks = stickerPacks.slice()

        // Start loading first pack in queue
        processNextPackInQueue()
    }

    // Process next pack in the queue
    function processNextPackInQueue() {
        if (packLoadQueue.length === 0) {
            console.log("StickerService: Finished loading all packs")
            isLoading = false
            return
        }

        const next = packLoadQueue.shift()
        packLoadQueue = packLoadQueue.slice()  // Trigger update

        const manifestPath = cacheDir + "/" + next.id + "/manifest.json"
        checkManifestProcess.packId = next.id
        checkManifestProcess.packKey = next.key
        checkManifestProcess.outputBuffer = ""
        checkManifestProcess.command = ["cat", manifestPath]
        checkManifestProcess.running = true
    }

    // Process to check for cached manifest
    Process {
        id: checkManifestProcess
        property string packId: ""
        property string packKey: ""
        property string outputBuffer: ""

        stdout: SplitParser {
            onRead: data => {
                checkManifestProcess.outputBuffer += data
            }
        }

        onRunningChanged: {
            if (!running) {
                if (outputBuffer) {
                    try {
                        const manifest = JSON.parse(outputBuffer)
                        updatePackManifest(packId, manifest)
                        // Also load stickers from cache
                        loadStickersFromCache(packId, packKey, manifest)
                        // Process next pack in queue (manifest was cached)
                        processNextPackInQueue()
                    } catch (e) {
                        // No cached manifest, will need to fetch
                        // Don't call processNextPackInQueue here - fetchManifest chain will do it
                        console.log("StickerService: No cached manifest for", packId, "- fetching...")
                        fetchManifest(packId, packKey)
                    }
                } else {
                    // No manifest file exists, fetch it
                    // Don't call processNextPackInQueue here - fetchManifest chain will do it
                    console.log("StickerService: No cached manifest for", packId, "- fetching...")
                    fetchManifest(packId, packKey)
                }
                outputBuffer = ""
            }
        }
    }

    // Update pack with manifest data
    function updatePackManifest(packId, manifest) {
        for (let i = 0; i < stickerPacks.length; i++) {
            if (stickerPacks[i].id === packId) {
                stickerPacks[i].manifest = manifest
                stickerPacks[i].name = manifest.title || stickerPacks[i].name
                stickerPacks[i].coverEmoji = manifest.cover?.emoji || manifest.stickers?.[0]?.emoji || "📦"
                break
            }
        }
        stickerPacks = stickerPacks.slice()  // Trigger reactive update
    }

    // Load pack details (manifest + stickers) - called when pack is selected
    function loadPackDetails(packId) {
        if (loadingPacks[packId]) {
            console.log("StickerService: Pack", packId, "is already loading")
            return
        }

        if (loadedStickers[packId] && loadedStickers[packId].length > 0) {
            console.log("StickerService: Pack", packId, "already loaded with", loadedStickers[packId].length, "stickers")
            return
        }

        // Find pack config
        const pack = stickerPacks.find(p => p.id === packId)
        if (!pack) {
            console.log("StickerService: Pack", packId, "not found")
            return
        }

        loadingPacks[packId] = true
        loadingPacks = Object.assign({}, loadingPacks)

        // Check if manifest exists, if not fetch it
        if (!pack.manifest) {
            fetchManifest(packId, pack.key)
        } else {
            // Manifest exists, load stickers
            loadStickersForPack(packId, pack.key, pack.manifest)
        }
    }

    // Fetch and decrypt manifest from Signal CDN
    function fetchManifest(packId, key) {
        console.log("StickerService: Fetching manifest for", packId)
        const packDir = cacheDir + "/" + packId
        const encryptedPath = packDir + "/manifest.proto.enc"
        const decryptedPath = packDir + "/manifest.proto"
        const manifestPath = packDir + "/manifest.json"

        // Create pack directory and fetch manifest
        fetchManifestProcess.packId = packId
        fetchManifestProcess.packKey = key
        fetchManifestProcess.command = ["bash", "-c",
            "mkdir -p '" + packDir + "' && " +
            "curl -s 'https://cdn-ca.signal.org/stickers/" + packId + "/manifest.proto' -o '" + encryptedPath + "' && " +
            "'" + scriptPath + "' '" + key + "' '" + encryptedPath + "' '" + decryptedPath + "'"
        ]
        fetchManifestProcess.running = true
    }

    Process {
        id: fetchManifestProcess
        property string packId: ""
        property string packKey: ""

        stderr: SplitParser {
            onRead: data => console.log("StickerService fetch stderr:", data)
        }

        onRunningChanged: {
            if (!running) {
                // Parse the decrypted protobuf manifest
                parseManifest(packId, packKey)
            }
        }
    }

    // Parse decrypted protobuf manifest
    function parseManifest(packId, key) {
        const decryptedPath = cacheDir + "/" + packId + "/manifest.proto"
        parseManifestProcess.packId = packId
        parseManifestProcess.packKey = key
        parseManifestProcess.command = ["python3", parseScriptPath, decryptedPath]
        parseManifestProcess.running = true
    }

    Process {
        id: parseManifestProcess
        property string packId: ""
        property string packKey: ""
        property string outputBuffer: ""

        stdout: SplitParser {
            onRead: data => {
                parseManifestProcess.outputBuffer += data
            }
        }

        stderr: SplitParser {
            onRead: data => console.log("StickerService parse stderr:", data)
        }

        onRunningChanged: {
            if (!running) {
                if (outputBuffer) {
                    try {
                        const manifest = JSON.parse(outputBuffer.trim())
                        console.log("StickerService: Parsed manifest for", packId, "-", manifest.title, "with", manifest.stickers.length, "stickers")

                        // Save manifest to cache
                        const manifestPath = cacheDir + "/" + packId + "/manifest.json"
                        saveManifestProcess.command = ["bash", "-c", "echo '" + JSON.stringify(manifest).replace(/'/g, "'\\''") + "' > '" + manifestPath + "'"]
                        saveManifestProcess.running = true

                        // Update pack
                        updatePackManifest(packId, manifest)

                        // Load stickers
                        loadStickersForPack(packId, packKey, manifest)
                    } catch (e) {
                        console.log("StickerService: Failed to parse manifest:", e)
                        loadingPacks[packId] = false
                        loadingPacks = Object.assign({}, loadingPacks)
                    }
                }
                outputBuffer = ""
                // Process next pack in queue (manifest fetch complete)
                processNextPackInQueue()
            }
        }
    }

    Process {
        id: saveManifestProcess
    }

    // Load stickers from cache when manifest already exists
    function loadStickersFromCache(packId, key, manifest) {
        if (!manifest || !manifest.stickers) {
            console.log("StickerService: No stickers in cached manifest for", packId)
            return
        }

        console.log("StickerService: Loading", manifest.stickers.length, "stickers from cache for", packId)

        const stickers = []
        const packDir = cacheDir + "/" + packId

        for (const stickerMeta of manifest.stickers) {
            const stickerPath = packDir + "/" + stickerMeta.id + ".png"
            stickers.push({
                packId: packId,
                packTitle: manifest.title,
                packAuthor: manifest.author,
                stickerId: stickerMeta.id,
                emoji: stickerMeta.emoji,
                imagePath: stickerPath,
                format: 'png'
            })
        }

        // Store stickers
        loadedStickers[packId] = stickers
        loadedStickers = Object.assign({}, loadedStickers)

        // Check if any stickers need downloading
        checkAndDownloadMissingStickers(packId, key, stickers)
    }

    // Check for missing stickers and download them if needed
    function checkAndDownloadMissingStickers(packId, key, stickers) {
        const packDir = cacheDir + "/" + packId

        // Build script to check if any stickers are missing
        let checkScript = "cd '" + packDir + "'\nmissing=0\n"
        for (const sticker of stickers) {
            checkScript += "[ ! -f '" + sticker.stickerId + ".png' ] && missing=$((missing+1))\n"
        }
        checkScript += "echo $missing"

        checkMissingProcess.packId = packId
        checkMissingProcess.packKey = key
        checkMissingProcess.stickers = stickers
        checkMissingProcess.command = ["bash", "-c", checkScript]
        checkMissingProcess.running = true
    }

    Process {
        id: checkMissingProcess
        property string packId: ""
        property string packKey: ""
        property var stickers: []
        property string outputBuffer: ""

        stdout: SplitParser {
            onRead: data => {
                checkMissingProcess.outputBuffer += data.trim()
            }
        }

        onRunningChanged: {
            if (!running) {
                const missingCount = parseInt(outputBuffer) || 0
                if (missingCount > 0) {
                    console.log("StickerService:", missingCount, "stickers missing for", packId, "- downloading...")
                    downloadStickers(packId, packKey, stickers)
                } else {
                    console.log("StickerService: All stickers cached for", packId)
                }
                outputBuffer = ""
            }
        }
    }

    // Load individual stickers for a pack
    function loadStickersForPack(packId, key, manifest) {
        if (!manifest || !manifest.stickers) {
            console.log("StickerService: No stickers in manifest for", packId)
            loadingPacks[packId] = false
            loadingPacks = Object.assign({}, loadingPacks)
            return
        }

        console.log("StickerService: Loading", manifest.stickers.length, "stickers for", packId)

        const stickers = []
        const packDir = cacheDir + "/" + packId

        for (const stickerMeta of manifest.stickers) {
            const stickerPath = packDir + "/" + stickerMeta.id + ".png"
            stickers.push({
                packId: packId,
                packTitle: manifest.title,
                packAuthor: manifest.author,
                stickerId: stickerMeta.id,
                emoji: stickerMeta.emoji,
                imagePath: stickerPath,
                format: 'png'
            })
        }

        // Store stickers
        loadedStickers[packId] = stickers
        loadedStickers = Object.assign({}, loadedStickers)

        // Download stickers that don't exist
        downloadStickers(packId, key, stickers)
    }

    // Download stickers that aren't cached
    function downloadStickers(packId, key, stickers) {
        isDownloading = true
        const packDir = cacheDir + "/" + packId
        let downloadScript = "cd '" + packDir + "'\n"

        for (const sticker of stickers) {
            const encPath = sticker.stickerId + ".enc"
            const webpPath = sticker.stickerId + ".webp"
            const pngPath = sticker.stickerId + ".png"

            // Download, decrypt, convert to PNG (Qt doesn't support WebP natively)
            downloadScript += "if [ ! -f '" + pngPath + "' ]; then\n"
            downloadScript += "  curl -s 'https://cdn-ca.signal.org/stickers/" + packId + "/full/" + sticker.stickerId + "' -o '" + encPath + "' && \\\n"
            downloadScript += "  '" + scriptPath + "' '" + key + "' '" + encPath + "' '" + webpPath + "' 2>/dev/null && \\\n"
            downloadScript += "  (magick '" + webpPath + "' '" + pngPath + "' 2>/dev/null || convert '" + webpPath + "' '" + pngPath + "' 2>/dev/null || ffmpeg -i '" + webpPath + "' '" + pngPath + "' -y 2>/dev/null) && \\\n"
            downloadScript += "  rm -f '" + encPath + "' '" + webpPath + "'\n"
            downloadScript += "fi\n"
        }

        downloadStickersProcess.packId = packId
        downloadStickersProcess.command = ["bash", "-c", downloadScript]
        downloadStickersProcess.running = true
    }

    Process {
        id: downloadStickersProcess
        property string packId: ""

        stderr: SplitParser {
            onRead: data => {
                if (data.trim()) console.log("StickerService download:", data)
            }
        }

        onRunningChanged: {
            if (!running) {
                console.log("StickerService: Finished downloading stickers for", packId)
                loadingPacks[packId] = false
                loadingPacks = Object.assign({}, loadingPacks)
                isDownloading = false

                // Trigger update
                loadedStickers = Object.assign({}, loadedStickers)
            }
        }
    }

    // Search stickers by emoji or keywords
    function searchStickers(query) {
        if (!query) return getAllStickers()

        const results = []
        const searchLower = query.toLowerCase()

        for (const packId in loadedStickers) {
            const stickers = loadedStickers[packId]
            for (const sticker of stickers) {
                // Direct emoji match
                if (sticker.emoji.includes(query)) {
                    results.push(sticker)
                    continue
                }

                // Keyword match
                const keywords = emojiKeywords[sticker.emoji] || []
                for (const kw of keywords) {
                    if (kw.includes(searchLower) || searchLower.includes(kw)) {
                        results.push(sticker)
                        break
                    }
                }

                // Pack title match
                if (sticker.packTitle.toLowerCase().includes(searchLower)) {
                    results.push(sticker)
                }
            }
        }

        return results
    }

    // Get all loaded stickers
    function getAllStickers() {
        let all = []
        for (const packId in loadedStickers) {
            all = all.concat(loadedStickers[packId])
        }
        return all
    }

    // Get stickers for a specific pack
    function getPackStickers(packId) {
        return loadedStickers[packId] || []
    }

    // Select a pack
    function selectPack(packId) {
        selectedPackId = packId
        if (packId) {
            loadPackDetails(packId)
        }
    }

    // Add a sticker pack from URL
    function addPackFromUrl(url) {
        // Parse Signal sticker URL
        // Example: https://signal.art/addstickers/#pack_id=xxx&pack_key=yyy
        const match = url.match(/pack_id=([a-f0-9]+).*pack_key=([a-f0-9]+)/i)
        if (!match) {
            console.log("StickerService: Invalid sticker URL:", url)
            return null
        }

        const packId = match[1]
        const packKey = match[2]

        console.log("StickerService: Adding pack from URL:", packId)

        // Check if already exists
        if (stickerPacks.some(p => p.id === packId)) {
            console.log("StickerService: Pack already exists")
            return { id: packId, key: packKey, name: "Already Added", exists: true }
        }

        // Add to packs
        const newPack = {
            id: packId,
            key: packKey,
            name: "Loading...",
            manifest: null,
            coverEmoji: "📦"
        }

        // Add to stickerPacks array immediately
        stickerPacks = stickerPacks.concat([newPack])
        console.log("StickerService: Added pack to stickerPacks, now have", stickerPacks.length, "packs")

        // Fetch manifest to get name
        fetchManifest(packId, packKey)

        return newPack
    }

    // Remove a sticker pack
    function removePack(packId) {
        stickerPacks = stickerPacks.filter(p => p.id !== packId)
        delete loadedStickers[packId]
        loadedStickers = Object.assign({}, loadedStickers)

        // Update config
        ConfigService.setValue("stickers.packs", stickerPacks.map(p => ({
            id: p.id,
            key: p.key,
            name: p.name
        })))
        ConfigService.saveConfig()

        // Clear cache
        clearPackCacheProcess.command = ["rm", "-rf", cacheDir + "/" + packId]
        clearPackCacheProcess.running = true
    }

    Process {
        id: clearPackCacheProcess
    }

    // Copy sticker to clipboard
    function copySticker(sticker) {
        console.log("StickerService: Copying sticker to clipboard:", sticker.imagePath)
        copyStickerProcess.command = ["bash", "-c",
            "if command -v convert &> /dev/null; then " +
            "convert '" + sticker.imagePath + "' png:- | wl-copy -t image/png; " +
            "elif command -v ffmpeg &> /dev/null; then " +
            "ffmpeg -i '" + sticker.imagePath + "' -f image2pipe -vcodec png - 2>/dev/null | wl-copy -t image/png; " +
            "else " +
            "cat '" + sticker.imagePath + "' | wl-copy -t image/webp; " +
            "fi"
        ]
        copyStickerProcess.running = true
    }

    Process {
        id: copyStickerProcess
        onRunningChanged: {
            if (!running) {
                console.log("StickerService: Sticker copied to clipboard")
            }
        }
    }
}
