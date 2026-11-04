"""Builds assets/content/*.json: the Swahili-first curriculum following the four Foundations Guides.
Item:  I(text, reading, english, swahili, note="")  | Drill: D(question, options, answer_index, explanation="")
Edit and re-run to add lessons. A native-speaker review of the Swahili is recommended before release."""
import json, pathlib
OUT = pathlib.Path(__file__).resolve().parent.parent / "assets" / "content"

def I(t, r, m, ms, n="", alt=None, s=1, w=None, k=0, tone=None):
    d = {"t": t, "r": r, "m": m, "ms": ms}
    if n: d["n"] = n
    if alt: d["alt"] = alt
    if s == 0: d["s"] = 0
    if w: d["w"] = w
    if k: d["k"] = k
    if tone: d["tone"] = tone
    return d
def D(q, o, a, e=""): return {"q": q, "o": o, "a": a, "e": e}
def U(id, title, emoji, intro, items, drills): return {"id": id, "title": title, "emoji": emoji, "intro": intro, "items": items, "drills": drills}
def L(t, r, m, ms, alt=None):
    d = {"t": t, "r": r, "m": m, "ms": ms}
    if alt: d["alt"] = alt
    return d
def ST(id, title, emoji, lines, quiz): return {"id": id, "title": title, "emoji": emoji, "lines": lines, "quiz": quiz}
def SG(id, title, emoji, lines): return {"id": id, "title": title, "emoji": emoji, "lines": lines}

# ------------------------------------------------------------------ SPANISH
es = dict(code="es", name="Spanish", native="Español", flag="🇪🇸", tts="es-ES", whisper="es", ink="es", color=0xFFE5484D, units=[
 U("es1", "Sauti na Herufi", "🔤",
   "Kihispania karibu kinasomwa kama kinavyoandikwa. Vokali A, E, I, O, U ni fupi na wazi, kama za Kiswahili, na hazibadiliki kamwe. Ñ inasomwa 'nya' (kama 'nyama'). R moja ni mgongo mwepesi wa ulimi; rr (au r mwanzoni mwa neno) ni mvumo wa ulimi. Herufi H haisomwi kamwe.",
   [I("hola", "OH-lah", "hello", "habari", "H haisomwi!"), I("niño", "NEE-nyo", "boy / child", "mtoto", "ñ inasomwa 'nya', kama 'nyama'"),
    I("pero", "PEH-ro", "but", "lakini", "r moja = mgongo mwepesi wa ulimi"), I("perro", "PEH-rro", "dog", "mbwa", "rr = mvumo wa ulimi. Linganisha na 'pero'!"),
    I("uno", "OO-no", "one", "moja"), I("agua", "AH-gwa", "water", "maji"), I("casa", "KAH-sa", "house", "nyumba"),
    I("gracias", "GRAH-syas", "thank you", "asante"), I("adiós", "ah-DYOHS", "goodbye", "kwaheri")],
   [D("H inasomwaje katika 'hola'?", ["Kama h ya Kiingereza", "Haisomwi", "Kama 'j'", "Kama 'ch'"], 1, "H haisomwi kamwe katika Kihispania."),
    D("Herufi Ñ inatoa sauti gani?", ["'nya' kama katika 'nyama'", "'n' kama katika 'nani'", "'ng' kama katika 'ng'ombe'", "'nn' ndefu"], 0),
    D("Neno gani linahitaji mvumo wa ulimi?", ["pero", "perro", "caro", "pera"], 1, "rr ni mvumo.")]),
 U("es2", "Jinsia na Mwafaka", "🚹",
   "Nomino ni za kiume (mara nyingi huishia -o) au za kike (mara nyingi huishia -a, -ción, -sión, -dad). Vibainishi na vivumishi lazima vilingane na nomino kwa jinsia na wingi. Kwa wingi, ongeza -s (au -es).",
   [I("el libro nuevo", "el LEE-bro NWEH-vo", "the new book", "kitabu kipya"), I("la casa nueva", "la KAH-sa NWEH-va", "the new house", "nyumba mpya"),
    I("los libros nuevos", "los LEE-bros NWEH-vos", "the new books", "vitabu vipya"), I("las casas nuevas", "las KAH-sas NWEH-vas", "the new houses", "nyumba mpya (wingi)"),
    I("la canción", "la kan-SYOHN", "the song", "wimbo", "-ción = kike"), I("la ciudad", "la syoo-DAHD", "the city", "mji", "-dad = kike"),
    I("el gato negro", "el GAH-to NEH-gro", "the black cat", "paka mweusi (dume)"), I("la gata negra", "la GAH-ta NEH-gra", "the black (female) cat", "paka mweusi (jike)")],
   [D("Chagua kibainishi: ___ casa", ["el", "la", "los", "lo"], 1), D("Wingi wa 'la casa nueva'?", ["las casas nuevas", "los casas nuevos", "la casas nueva", "las casa nueva"], 0),
    D("Nomino ipi ni ya kike?", ["la ciudad", "el libro", "el gato", "el niño"], 0, "Nomino za -dad ni za kike.")]),
 U("es3", "Vitenzi vya Wakati Uliopo", "⚙️",
   "Vitenzi vina makundi matatu kwa kiishio cha mwisho: -AR (hablar), -ER (comer), -IR (vivir). Viishio: yo -o | tú -as/-es | él -a/-e | nosotros -amos/-emos/-imos | vosotros -áis/-éis/-ís | ellos -an/-en.",
   [I("hablo", "AH-blo", "I speak", "ninaongea"), I("hablas", "AH-blas", "you speak", "unaongea"), I("hablamos", "ah-BLAH-mos", "we speak", "tunaongea"),
    I("como", "KOH-mo", "I eat", "ninakula"), I("vivimos", "vee-VEE-mos", "we live", "tunaishi"),
    I("Yo hablo español", "yo AH-blo es-pa-NYOL", "I speak Spanish", "Ninaongea Kihispania"), I("Nosotros comemos pan", "no-SO-tros ko-MEH-mos pan", "We eat bread", "Tunakula mkate"),
    I("Ellos viven aquí", "EH-yos VEE-ven ah-KEE", "They live here", "Wanaishi hapa")],
   [D("Yo ___ (comer)", ["como", "comes", "come", "comen"], 0), D("Nosotros ___ (vivir)", ["vivo", "vivimos", "vive", "viven"], 1),
    D("Ellos ___ (hablar)", ["hablan", "habla", "hablamos", "hablas"], 0), D("'vivir' ni la kundi gani?", ["-AR", "-ER", "-IR", "-OR"], 2)]),
 U("es4", "Ser na Estar, na Wakati Uliopita", "🌓",
   "Ser = sifa za kudumu, utambulisho, asili (Soy alto). Estar = hali za muda, hisia, mahali (Estoy cansado). Wakati uliopita: Preterite = tendo lililokamilika (Comí) na Imperfect = tendo lililoendelea au la mazoea (Comía).",
   [I("Soy alto", "soy AL-to", "I am tall", "Mimi ni mrefu", "ser: sifa ya kudumu"), I("Estoy cansado", "es-TOY kan-SAH-do", "I am tired", "Nimechoka", "estar: hali ya muda"),
    I("Soy de México", "soy deh MEH-hee-ko", "I am from Mexico", "Natoka Meksiko", "ser: asili"), I("Estoy en casa", "es-TOY en KAH-sa", "I am at home", "Niko nyumbani", "estar: mahali"),
    I("Comí una manzana", "ko-MEE OO-na man-SAH-na", "I ate an apple", "Nilikula tufaha", "preterite: limekwisha"), I("Comía mucho", "ko-MEE-ah MOO-cho", "I used to eat a lot", "Nilikuwa nakula sana", "imperfect: mazoea"),
    I("Ella es doctora", "EH-ya es dok-TOH-ra", "She is a doctor", "Yeye ni daktari"), I("Ellos están felices", "EH-yos es-TAN feh-LEE-ses", "They are happy", "Wana furaha")],
   [D("'Nimechoka' (hali ya muda): Yo ___ cansado", ["soy", "estoy", "es", "están"], 1), D("Kitenzi gani kwa utambulisho na asili?", ["Ser", "Estar", "Vyote viwili", "Hakuna"], 0),
    D("Ayer ___ pizza. (tendo limekwisha)", ["comí", "comía", "como", "comeré"], 0), D("De niño ___ mucho. (mazoea)", ["comí", "comía", "como", "comes"], 1)]),
], stories=[
 ST("es_s1", "Nyumba Yangu", "🏠", [L("Hola, soy Lola.", "OH-la, soy LOH-la", "Hi, I'm Lola.", "Habari, mimi ni Lola."), L("Vivo en una casa nueva.", "VEE-vo en OO-na KAH-sa NWEH-va", "I live in a new house.", "Ninaishi katika nyumba mpya."),
    L("En la casa hay un gato negro.", "en la KAH-sa ai oon GAH-to NEH-gro", "In the house there is a black cat.", "Ndani ya nyumba kuna paka mweusi."), L("El gato come pescado.", "el GAH-to KOH-meh pes-KAH-do", "The cat eats fish.", "Paka anakula samaki."),
    L("¡Adiós!", "ah-DYOHS", "Goodbye!", "Kwaheri!")],
   [D("Lola anaishi wapi?", ["Katika nyumba mpya", "Shuleni", "Garini", "Mtumbwi"], 0), D("Paka ana rangi gani?", ["Nyeusi", "Nyeupe", "Nyekundu", "Buluu"], 0), D("Paka anakula nini?", ["Samaki", "Mkate", "Tufaha", "Wali"], 0)])],
 songs=[SG("es_g1", "Vitenzi Vinaimba", "🎵", [L("Yo hablo, tú hablas, él habla también,", "yo AH-blo, too AH-blas, el AH-bla tam-BYEN", "I speak, you speak, he speaks too,", "Mimi naongea, wewe unaongea, yeye anaongea pia,"),
    L("Nosotros hablamos, ellos hablan bien.", "no-SO-tros ah-BLAH-mos, EH-yos AH-blan byen", "We speak, they speak well.", "Sisi tunaongea, wao wanaongea vizuri."),
    L("Yo como, tú comes, vivimos aquí,", "yo KOH-mo, too KOH-mes, vee-VEE-mos ah-KEE", "I eat, you eat, we live here,", "Mimi nakula, wewe unakula, tunaishi hapa,"),
    L("¡Hablar, comer, vivir, y reír!", "ah-BLAR, ko-MER, vee-VEER, ee reh-EER", "To speak, to eat, to live, and to laugh!", "Kuongea, kula, kuishi, na kucheka!")])])

# ------------------------------------------------------------------ JAPANESE
kana = [("あ", "a"), ("い", "i"), ("う", "u"), ("え", "e"), ("お", "o"), ("か", "ka"), ("き", "ki"), ("く", "ku"), ("け", "ke"), ("こ", "ko")]
ja = dict(code="ja", name="Japanese", native="日本語", flag="🇯🇵", tts="ja-JP", whisper="ja", ink="ja", color=0xFFF76B8A, units=[
 U("ja1", "Hiragana: Sauti za Kwanza", "🔤",
   "Kijapani kinatumia mifumo mitatu ya uandishi. Hiragana (herufi 46) ni ya maneno ya asili, viambishi na viishio vya vitenzi. Katakana (herufi 46) ni ya maneno ya kigeni na msisitizo. Kanji ni herufi zilizotoka Kichina zinazobeba maana kuu ya nomino na shina la vitenzi. Habari njema: vokali a, i, u, e, o ni sawa kabisa na za Kiswahili!",
   [I(k, r, f"sound '{r}'", f"sauti '{r}'", "sawa na ya Kiswahili" if r in "aiueo" else "", s=0, w=k) for k, r in kana] +
   [I("あい", "ai", "love", "upendo", alt=["愛"]), I("いえ", "ie", "house", "nyumba", alt=["家"]), I("あお", "ao", "blue", "samawati", alt=["青"])],
   [D("Mfumo gani unatumika kwa maneno ya kigeni?", ["Katakana", "Hiragana", "Kanji", "Pinyin"], 0), D("Hiragana ina herufi ngapi?", ["46", "26", "33", "100"], 0),
    D("Mfumo gani unabeba maana kuu ya nomino na shina la vitenzi?", ["Kanji", "Katakana", "Hiragana", "Romaji"], 0)]),
 U("ja2", "Katakana na Kanji", "🈴",
   "Katakana ina sauti zile zile za hiragana lakini kwa pembe kali zaidi. Kanji hubeba maana nzima katika herufi moja na husomwa kwa njia zaidi ya moja, kwa hiyo tunazijifunza ndani ya maneno.",
   [I("コーヒー", "koohii", "coffee", "kahawa", "neno la kigeni kwa katakana", alt=["こーひー"], w="コーヒー"), I("テレビ", "terebi", "TV", "televisheni", "neno la kigeni kwa katakana", alt=["てれび"], w="テレビ"),
    I("日本", "nihon", "Japan", "Japani", alt=["にほん"], w="日本"), I("学生", "gakusei", "student", "mwanafunzi", alt=["がくせい"]),
    I("水", "mizu", "water", "maji", alt=["みず"], w="水"), I("本", "hon", "book", "kitabu", alt=["ほん"], w="本"),
    I("私", "watashi", "I / me", "mimi", alt=["わたし"], w="私"), I("車", "kuruma", "car", "gari", alt=["くるま"], w="車")],
   [D("テレビ imeandikwa kwa mfumo gani?", ["Katakana", "Hiragana", "Kanji", "Herufi za Kilatini"], 0), D("水 inabeba maana 'maji'. Ni...?", ["Kanji", "Hiragana", "Katakana", "Kiambishi"], 0)]),
 U("ja3", "Viambishi (Particles)", "🔗",
   "Viambishi huungana na mwisho wa nomino na kuonyesha kazi yake. は (wa) = mada. が (ga) = kiima. を (o) = shamirisho. に (ni) = lengo au mahali ('kwenda', 'katika'). で (de) = mahali pa tendo au njia ('kwa', 'katika').",
   [I("私は学生です", "watashi wa gakusei desu", "As for me, I am a student", "Mimi ni mwanafunzi", "は inasomwa 'wa'", alt=["わたしはがくせいです"]),
    I("水が冷たい", "mizu ga tsumetai", "The water is cold", "Maji ni baridi", alt=["みずがつめたい"]), I("本を読んだ", "hon o yonda", "I read a book", "Nilisoma kitabu", "を inasomwa 'o'", alt=["ほんをよんだ"]),
    I("日本に行く", "nihon ni iku", "I go to Japan", "Naenda Japani", alt=["にほんにいく"]), I("車で行く", "kuruma de iku", "I go by car", "Naenda kwa gari", alt=["くるまでいく"]),
    I("これは本です", "kore wa hon desu", "This is a book", "Hiki ni kitabu", alt=["これはほんです"]), I("学校に行く", "gakkou ni iku", "I go to school", "Naenda shuleni", alt=["がっこうにいく"])],
   [D("Kiambishi gani kinaonyesha mada?", ["は (wa)", "が (ga)", "を (o)", "で (de)"], 0), D("車__行く (naenda kwa gari)", ["で", "に", "を", "は"], 0),
    D("日本__行く (naenda Japani)", ["に", "で", "を", "が"], 0), D("Kiambishi gani kinaonyesha shamirisho?", ["を", "に", "で", "は"], 0)]),
 U("ja4", "Vitenzi vya Heshima", "🙇",
   "Vitenzi havibadiliki kwa nafsi, wingi wala jinsia. Hubadilika tu kwa heshima na wakati: ます (wakati uliopo) · ません (kukanusha) · ました (uliopita) · ませんでした (uliopita kukanusha).",
   [I("食べます", "tabemasu", "I eat / will eat", "Ninakula / Nitakula", alt=["たべます"]), I("食べません", "tabemasen", "I don't eat", "Sili", alt=["たべません"]),
    I("食べました", "tabemashita", "I ate", "Nilikula", alt=["たべました"]), I("食べませんでした", "tabemasendeshita", "I didn't eat", "Sikula", alt=["たべませんでした"]),
    I("行きます", "ikimasu", "I go", "Naenda", alt=["いきます"]), I("飲みます", "nomimasu", "I drink", "Ninakunywa", alt=["のみます"]),
    I("水を飲みます", "mizu o nomimasu", "I drink water", "Ninakunywa maji", alt=["みずをのみます"]), I("日本に行きました", "nihon ni ikimashita", "I went to Japan", "Nilienda Japani", alt=["にほんにいきました"])],
   [D("Umbo la heshima la kukanusha wakati uliopita la 食べる?", ["食べませんでした", "食べました", "食べません", "食べます"], 0), D("Kiishio gani ni wakati uliopita wa kawaida (heshima)?", ["〜ました", "〜ます", "〜ません", "〜ませんでした"], 0),
    D("Vitenzi vya Kijapani hubadilika kwa mimi / wewe / yeye?", ["Hapana, vinabaki vilevile", "Ndiyo, kuna maumbo sita", "Kwa 'yeye' tu", "Wakati uliopita tu"], 0)]),
], stories=[
 ST("ja_s1", "Kifungua Kinywa", "🍙", [L("私は学生です。", "watashi wa gakusei desu", "I am a student.", "Mimi ni mwanafunzi.", ["わたしはがくせいです"]),
    L("朝、パンを食べます。", "asa, pan o tabemasu", "In the morning I eat bread.", "Asubuhi, ninakula mkate.", ["あさぱんをたべます"]), L("水を飲みます。", "mizu o nomimasu", "I drink water.", "Ninakunywa maji.", ["みずをのみます"]),
    L("学校に行きます。", "gakkou ni ikimasu", "I go to school.", "Naenda shuleni.", ["がっこうにいきます"]), L("車で行きません。", "kuruma de ikimasen", "I don't go by car.", "Siendi kwa gari.", ["くるまでいきません"])],
   [D("Mwanafunzi anakunywa nini?", ["Maji", "Kahawa", "Maziwa", "Juisi"], 0), D("Je, mwanafunzi anaenda kwa gari?", ["Hapana", "Ndiyo", "Jumapili tu", "Haijulikani"], 0), D("Mwanafunzi anaenda wapi?", ["Shuleni", "Japani", "Nyumbani", "Dukani"], 0)])],
 songs=[SG("ja_g1", "Wimbo wa ます", "🎵", [L("たべます たべます おいしいごはん", "tabemasu tabemasu oishii gohan", "I eat, I eat, tasty rice", "Nakula, nakula, wali mtamu"),
    L("のみます のみます つめたいみず", "nomimasu nomimasu tsumetai mizu", "I drink, I drink, cold water", "Nakunywa, nakunywa, maji baridi"),
    L("いきます いきます がっこうに", "ikimasu ikimasu gakkou ni", "I go, I go, to school", "Naenda, naenda, shuleni"), L("ます ます ます うたいます", "masu masu masu utaimasu", "Masu masu masu, I sing!", "Masu masu masu, naimba!")])])

# ------------------------------------------------------------------ MANDARIN
tones = [("妈", "mā", "mom", "mama", "1"), ("麻", "má", "hemp", "katani", "2"), ("马", "mǎ", "horse", "farasi", "3"), ("骂", "mà", "to scold", "kukemea", "4"),
         ("八", "bā", "eight", "nane", "1"), ("拔", "bá", "to pull up", "kung'oa", "2"), ("把", "bǎ", "to hold", "kushika", "3"), ("爸", "bà", "dad", "baba", "4")]
tn = {"1": "toni ya 1: juu na tambarare", "2": "toni ya 2: kupanda", "3": "toni ya 3: kushuka kisha kupanda", "4": "toni ya 4: kushuka kwa kasi"}
zh = dict(code="zh", name="Mandarin", native="中文", flag="🇨🇳", tts="zh-CN", whisper="zh", ink="zh-Hani", color=0xFFF5A623, units=[
 U("zh1", "Pinyin na Toni", "🎚️",
   "Pinyin huandika sauti za Kichina kwa herufi za Kilatini, na alama za toni (ā á ǎ à) ni lazima: toni hubadilisha neno. Toni ya 1 = juu na tambarare, ya 2 = kupanda (kama 'Nini?'), ya 3 = kushuka chini kisha kupanda, ya 4 = kushuka kwa kasi kama amri. Tumia Mazoezi ya Toni kufundisha sauti yako!",
   [I(c, p, f"{m} ({tn[t]})", f"{sw} ({tn[t]})", s=0, tone=t) for c, p, m, sw, t in tones],
   [D("Toni ipi ni ya juu na tambarare?", ["ya 1", "ya 2", "ya 3", "ya 4"], 0), D("Toni ipi inashuka kwa kasi kama amri?", ["ya 1", "ya 2", "ya 3", "ya 4"], 3),
    D("Toni ipi inashuka chini kisha inapanda?", ["ya 1", "ya 2", "ya 3", "ya 4"], 2), D("Pinyin ni nini?", ["Uandishi wa sauti za Kichina kwa herufi za Kilatini", "Aina ya herufi za Kichina", "Alama ya toni", "Lahaja"], 0),
    D("Herufi Rahisi (Simplified) zinatumika wapi?", ["China bara", "Taiwan", "Hong Kong", "Macau"], 0)]),
 U("zh2", "Misemo ya Kwanza", "👋", "Misemo mifupi ya kusema mara moja. Kumbuka: tamka kila silabi pamoja na toni yake!",
   [I("你好", "nǐ hǎo", "hello", "habari", alt=["你好吗"], w="你好"), I("谢谢", "xièxie", "thank you", "asante", alt=["謝謝"]), I("再见", "zàijiàn", "goodbye", "kwaheri", alt=["再見"]),
    I("我是学生", "wǒ shì xuésheng", "I am a student", "Mimi ni mwanafunzi", alt=["我是學生"]), I("对不起", "duìbuqǐ", "sorry", "samahani", alt=["對不起"]),
    I("没关系", "méi guānxi", "it's okay", "haina shida", alt=["沒關係"]), I("我叫小明", "wǒ jiào Xiǎomíng", "my name is Xiaoming", "Jina langu ni Xiaoming"), I("苹果", "píngguǒ", "apple", "tufaha", alt=["蘋果"])],
   [D("Msemo gani ni 'asante'?", ["谢谢", "再见", "你好", "对不起"], 0), D("'hǎo' (好) ina toni gani?", ["ya 3", "ya 1", "ya 2", "ya 4"], 0), D("再见 inamaanisha...?", ["kwaheri", "habari", "samahani", "tufaha"], 0)]),
 U("zh3", "Viashiria vya Wakati", "⏱️",
   "Vitenzi vya Kichina havibadiliki kamwe. Wakati unaonyeshwa kwa maneno ya wakati au viashiria: 了 (le) = tendo lililokamilika · 过 (guò) = uzoefu wa zamani ('nimewahi') · 正在 (zhèngzài) = tendo linaloendelea.",
   [I("我吃了苹果", "wǒ chī le píngguǒ", "I ate the apple", "Nilikula tufaha", "了 = limekamilika", alt=["我吃了蘋果"]), I("我去过日本", "wǒ qù guo Rìběn", "I have been to Japan", "Nimewahi kwenda Japani", "过 = uzoefu", alt=["我去過日本"]),
    I("我正在吃饭", "wǒ zhèngzài chīfàn", "I am eating", "Ninakula sasa hivi", "正在 = linaendelea", alt=["我正在吃飯"]), I("他看了书", "tā kàn le shū", "He read the book", "Alisoma kitabu", alt=["他看了書"]),
    I("她去过北京", "tā qù guo Běijīng", "She has been to Beijing", "Amewahi kwenda Beijing", alt=["她去過北京"]), I("我们正在学习", "wǒmen zhèngzài xuéxí", "We are studying", "Tunasoma sasa hivi", alt=["我們正在學習"]),
    I("我喝了水", "wǒ hē le shuǐ", "I drank water", "Nilikunywa maji")],
   [D("Kiashiria gani kinaonyesha tendo lililokamilika?", ["了 (le)", "过 (guò)", "正在 (zhèngzài)", "吗 (ma)"], 0), D("Kipi kinaonyesha uzoefu wa zamani ('nimewahi')?", ["过", "了", "正在", "的"], 0),
    D("Kipi kinaonyesha tendo linaloendelea?", ["正在", "了", "过", "吗"], 0), D("Vitenzi vya Kichina hubadilika kwa wakati?", ["Hapana: viashiria na maneno ya wakati huonyesha wakati", "Ndiyo, kama Kihispania", "Wakati uliopita tu", "Wakati ujao tu"], 0)]),
 U("zh4", "Kuandika Hanzi", "✍️",
   "Wakati wa kuandika! Herufi hujengwa kwa mistari kwa mpangilio maalum (kushoto kwenda kulia, juu kwenda chini). Zingatia idadi ya mistari: programu inaikagua. Herufi za Jadi (Taiwan, Hong Kong, Macau) zimebaki na maumbo ya zamani, kamili zaidi.",
   [I("一", "yī", "one", "moja", s=0, w="一", k=1), I("二", "èr", "two", "mbili", s=0, w="二", k=2), I("三", "sān", "three", "tatu", s=0, w="三", k=3), I("人", "rén", "person", "mtu", s=0, w="人", k=2),
    I("大", "dà", "big", "kubwa", s=0, w="大", k=3), I("小", "xiǎo", "small", "ndogo", s=0, w="小", k=3), I("水", "shuǐ", "water", "maji", s=0, w="水", k=4), I("火", "huǒ", "fire", "moto", s=0, w="火", k=4),
    I("山", "shān", "mountain", "mlima", s=0, w="山", k=3), I("口", "kǒu", "mouth", "mdomo", s=0, w="口", k=3), I("日", "rì", "sun / day", "jua / siku", s=0, w="日", k=4), I("月", "yuè", "moon / month", "mwezi", s=0, w="月", k=4),
    I("火山", "huǒshān", "volcano", "volkeno", w="火山"), I("大人", "dàrén", "adult", "mtu mzima", w="大人"), I("山水", "shānshuǐ", "landscape", "mandhari", w="山水"), I("人口", "rénkǒu", "population", "idadi ya watu", w="人口")],
   [D("Herufi 三 ina mistari mingapi?", ["3", "2", "4", "5"], 0), D("水 inamaanisha...?", ["maji", "moto", "mlima", "mwezi"], 0), D("Herufi ipi ina mistari 2?", ["人", "大", "小", "水"], 0),
    D("Herufi za Jadi zinatumika wapi?", ["Taiwan", "China bara", "Hakuna", "Vitabuni tu"], 0)]),
], stories=[
 ST("zh_s1", "Siku ya Xiaoming", "☀️", [L("你好！我是小明。", "nǐ hǎo! wǒ shì Xiǎomíng", "Hello! I am Xiaoming.", "Habari! Mimi ni Xiaoming."), L("我是学生。", "wǒ shì xuésheng", "I am a student.", "Mimi ni mwanafunzi.", ["我是學生"]),
    L("我吃了苹果。", "wǒ chī le píngguǒ", "I ate an apple.", "Nilikula tufaha.", ["我吃了蘋果"]), L("我去过日本。", "wǒ qù guo Rìběn", "I have been to Japan.", "Nimewahi kwenda Japani.", ["我去過日本"]),
    L("我正在吃饭。", "wǒ zhèngzài chīfàn", "I am eating a meal right now.", "Ninakula chakula sasa hivi.", ["我正在吃飯"]), L("再见！", "zàijiàn", "Goodbye!", "Kwaheri!", ["再見"])],
   [D("Xiaoming alikula nini (kimekwisha)?", ["Tufaha", "Wali", "Maji", "Mkate"], 0), D("Je, amewahi kwenda Japani?", ["Ndiyo", "Hapana", "Anapanga tu", "Haijulikani"], 0), D("Anafanya nini sasa?", ["Anakula chakula", "Analala", "Anasoma", "Anakimbia"], 0)])],
 songs=[SG("zh_g1", "Wimbo wa Hanzi", "🎵", [L("一二三，人大小", "yī èr sān, rén dà xiǎo", "One two three, person, big, small", "Moja mbili tatu, mtu, kubwa, ndogo"), L("水和火，山和口", "shuǐ hé huǒ, shān hé kǒu", "Water and fire, mountain and mouth", "Maji na moto, mlima na mdomo"),
    L("日和月，一起走", "rì hé yuè, yìqǐ zǒu", "Sun and moon, walk together", "Jua na mwezi, tembeeni pamoja"), L("你好再见，我们唱歌", "nǐ hǎo zàijiàn, wǒmen chànggē", "Hello, goodbye, we sing!", "Habari, kwaheri, tunaimba!", ["你好再見，我們唱歌"])])])

# ------------------------------------------------------------------ RUSSIAN
def letters(rows):
    out = []
    for pair, w, r, n in rows:
        nm = {"ъ": "Alama ngumu", "ь": "Alama laini"}.get(w, w.upper())
        out.append(I(pair, r, nm, nm, n, s=0, w=(None if w in "ъь" else w)))
    return out
ru1 = [("А а", "а", "ah", "kama 'a' ya 'baba'"), ("Б б", "б", "b", "kama 'b' ya 'bata'"), ("В в", "в", "v", "kama 'v' ya 'vita'"), ("Г г", "г", "g", "'g' ngumu kama katika 'gari'"),
       ("Д д", "д", "d", "kama 'd' ya 'daraja'"), ("Е е", "е", "ye", "kama 'ye' ya 'yeye'"), ("Ё ё", "ё", "yo", "kama 'yo' ya 'yoyo'. Hubeba mkazo daima!"),
       ("Ж ж", "ж", "zh", "kama 's' katika 'measure': sauti ya mvumo"), ("З з", "з", "z", "kama 'z' ya 'zawadi'"), ("И и", "и", "ee", "kama 'ii' ndefu ya 'kiti'"), ("Й й", "й", "y", "'i' fupi, kama 'y' ya 'yai'")]
ru2 = [("К к", "к", "k", "kama 'k' ya 'kamba'"), ("Л л", "л", "l", "kama 'l' ya 'lala'"), ("М м", "м", "m", "kama 'm' ya 'mama'"), ("Н н", "н", "n", "kama 'n' ya 'nani'"),
       ("О о", "о", "o", "'o' ya 'moto' ikiwa na mkazo; kama 'a' fupi isipokuwa na mkazo"), ("П п", "п", "p", "kama 'p' ya 'papa'"), ("Р р", "р", "rr", "mvumo wa ulimi, kama rr ya Kihispania"),
       ("С с", "с", "s", "kama 's' ya 'sasa', kamwe si 'z'"), ("Т т", "т", "t", "kama 't' ya 'tatu'"), ("У у", "у", "oo", "kama 'u' ya 'kuku'"), ("Ф ф", "ф", "f", "kama 'f' ya 'faida'")]
ru3 = [("Х х", "х", "kh", "mvumo wa kooni, kama 'kh' ya 'khamsini'"), ("Ц ц", "ц", "ts", "kama 'ts' katika 'tsetse'"), ("Ч ч", "ч", "ch", "kama 'ch' ya 'chai'"), ("Ш ш", "ш", "sh", "kama 'sh' ya 'shule': ngumu na bapa"),
       ("Щ щ", "щ", "shch", "'sh' laini na ndefu zaidi"), ("Ъ ъ", "ъ", "-", "alama ngumu: haisomwi, inaweka konsonanti ngumu"), ("Ы ы", "ы", "y", "'i' ya kooni: vuta ulimi nyuma"),
       ("Ь ь", "ь", "-", "alama laini: haisomwi, inalainisha konsonanti kabla yake"), ("Э э", "э", "e", "kama 'e' ya 'eneo'"), ("Ю ю", "ю", "yoo", "kama 'yu' ya 'yuko'"), ("Я я", "я", "ya", "kama 'ya' ya 'yaya'")]
ru = dict(code="ru", name="Russian", native="Русский", flag="🇷🇺", tts="ru-RU", whisper="ru", ink="ru", color=0xFF3E7BFA, units=[
 U("ru1", "Alfabeti I", "🔤", "Alfabeti ya Kisirili ina herufi 33, na nyingi ni rahisi! Jifunze sauti, kisha andika kila herufi. Gusa 🔊 kuisikia, kisha ichore.", letters(ru1),
   [D("Herufi gani hubeba mkazo daima na husomwa 'yo'?", ["Ё", "Е", "Ю", "Я"], 0), D("Ж inasomwaje?", ["Kama 's' katika 'measure'", "Kama 'sh' katika 'shule'", "Kama 'ch' katika 'chai'", "Kama 'z' katika 'zawadi'"], 0),
    D("Й inasomwa kama...?", ["'y' fupi kama katika 'yai'", "'ii' ndefu", "'ya'", "'yo'"], 0)]),
 U("ru2", "Alfabeti II", "🔤", "Herufi zaidi. Angalia: Р inavuma, С si kamwe Z, na О hubadilika isipokuwa na mkazo.", letters(ru2),
   [D("Р inasomwaje?", ["Inavuma, kama rr ya Kihispania", "Kama r ya Kiingereza", "'g' ngumu", "Haisomwi"], 0), D("У inasomwa kama...?", ["'u' ya 'kuku'", "'a' ya 'baba'", "'o' ya 'moto'", "'i' ya 'kiti'"], 0),
    D("О isiyo na mkazo husomwa kama...?", ["'a' fupi", "'o' ndefu", "'e'", "'i'"], 0)]),
 U("ru3", "Alfabeti III", "🔤", "Herufi za mwisho, pamoja na alama mbili zisizosomwa na Ы ngumu.", letters(ru3),
   [D("Herufi zipi hazisomwi (ni alama)?", ["Ъ na Ь", "Ы na Э", "Ч na Щ", "Ю na Я"], 0), D("Х inasomwa kama...?", ["mvumo wa kooni (kh)", "'h' laini", "'k'", "'sh'"], 0),
    D("Ы ni...?", ["'i' ya kooni, ulimi nyuma", "sawa na И", "haisomwi", "'ya'"], 0)]),
 U("ru4", "Maneno ya Kwanza", "🗣️", "Sema na uandike maneno yako ya kwanza. Mkazo katika Kirusi husogea, kwa hiyo jifunze mkazo pamoja na neno (silabi yenye mkazo kwa HERUFI KUBWA).",
   [I("мама", "MAH-ma", "mom", "mama", w="мама"), I("дом", "dom", "house", "nyumba", "kiume: huishia konsonanti", w="дом"), I("вода", "va-DAH", "water", "maji", "kike: huishia -а", w="вода"),
    I("окно", "ak-NOH", "window", "dirisha", "kati: huishia -о", w="окно"), I("море", "MOH-rye", "sea", "bahari", "kati: huishia -е"), I("песня", "PYES-nya", "song", "wimbo", "kike: huishia -я"),
    I("книга", "KNEE-ga", "book", "kitabu", "kike", w="книга"), I("музей", "moo-ZYAY", "museum", "jumba la makumbusho", "kiume: huishia -й")],
   [D("Jinsia ya дом?", ["Kiume", "Kike", "Kati", "Haijulikani"], 0), D("Jinsia ya вода?", ["Kiume", "Kike", "Kati", "Wingi"], 1), D("Jinsia ya окно?", ["Kiume", "Kike", "Kati", "Wingi"], 2),
    D("Maneno yanayoishia alama laini (ночь) yakoje?", ["Jinsia lazima ikariri", "Daima kiume", "Daima kati", "Daima wingi"], 0)]),
 U("ru5", "Jinsia, Wingi na Mkazo", "⚖️",
   "Vivumishi huiga nomino: новый дом, новая книга, новое окно. Wingi: -ы / -и kwa nomino nyingi za kiume na kike, -а / -я kwa za kati. Mkazo unaweza kubadilisha maana: за́мок = ngome, замо́к = kufuli.",
   [I("новый дом", "NO-vyy dom", "new house", "nyumba mpya"), I("новая книга", "NO-va-ya KNEE-ga", "new book", "kitabu kipya"), I("новое окно", "NO-vo-ye ak-NOH", "new window", "dirisha jipya"),
    I("дома", "DOH-ma", "houses", "nyumba (wingi)"), I("книги", "KNEE-gee", "books", "vitabu"), I("окна", "OK-na", "windows", "madirisha"), I("моря", "mar-YAH", "seas", "bahari (wingi)"),
    I("за́мок", "ZAH-mok", "castle", "ngome", "mkazo kwenye silabi YA KWANZA", s=0), I("замо́к", "za-MOK", "lock", "kufuli", "mkazo kwenye silabi YA PILI", s=0)],
   [D("Wingi wa книга?", ["книги", "книгы", "книгов", "книга"], 0), D("Wingi wa окно?", ["окна", "окны", "окни", "окнов"], 0),
    D("Kivumishi cha 'книга' (kike)?", ["новая", "новый", "новое", "новые"], 0), D("Neno gani linamaanisha 'kufuli' (mkazo kwenye silabi ya pili)?", ["замо́к", "за́мок"], 0, "Kusogeza mkazo kunabadilisha maana."),
    D("Kwa nini mkazo ni muhimu?", ["Unaweza kubadilisha maana", "Haubadiliki kamwe", "Daima ni silabi ya kwanza", "Unaathiri tahajia tu"], 0)]),
 U("ru6", "Vitenzi na Kauli (Cases)", "🔧",
   "Wakati uliopo: kundi la 1 (читать): -ю -ешь -ет -ем -ете -ют. Kundi la 2 (говорить): -ю -ишь -ит -им -ите -ят. Kuna kauli sita zinazoonyesha kazi ya kila nomino: Nominative (nani), Genitive (wa), Dative (kwa), Accusative (nani/nini), Instrumental (kwa/pamoja na), Prepositional (kuhusu).",
   [I("я читаю", "ya chee-TAH-yu", "I read", "ninasoma"), I("ты читаешь", "ty chee-TAH-yesh", "you read", "unasoma"), I("мы читаем", "my chee-TAH-yem", "we read", "tunasoma"), I("они читают", "a-NEE chee-TAH-yut", "they read", "wanasoma"),
    I("я говорю", "ya ga-va-RYU", "I speak", "ninaongea"), I("ты говоришь", "ty ga-va-REESH", "you speak", "unaongea"), I("они говорят", "a-NEE ga-va-RYAT", "they speak", "wanaongea"),
    I("студент читает", "stoo-DYENT chee-TAH-yet", "The student is reading", "Mwanafunzi anasoma", "Nominative: kiima"), I("книга студента", "KNEE-ga stoo-DYEN-ta", "the student's book", "kitabu cha mwanafunzi", "Genitive: 'cha / wa'"),
    I("я вижу студента", "ya VEE-zhu stoo-DYEN-ta", "I see the student", "Namwona mwanafunzi", "Accusative: shamirisho")],
   [D("Kauli gani inaonyesha kiima?", ["Nominative", "Genitive", "Dative", "Instrumental"], 0), D("Kauli gani inajibu 'Cha nani?' (книга студента)?", ["Genitive", "Dative", "Accusative", "Prepositional"], 0),
    D("Kauli gani inamaanisha 'kwa kutumia / pamoja na'?", ["Instrumental", "Prepositional", "Nominative", "Dative"], 0), D("говорить ni la kundi gani?", ["Kundi la 2 (-ить)", "Kundi la 1 (-ать)", "Lisilo la kawaida tu", "Halibadiliki"], 0),
    D("Я ___ (читать)", ["читаю", "читаешь", "читает", "читают"], 0)]),
], stories=[
 ST("ru_s1", "Mama na Kitabu", "📚", [L("Привет! Это мама.", "pree-VYET! E-ta MAH-ma", "Hi! This is mom.", "Habari! Huyu ni mama."), L("Мама читает новую книгу.", "MAH-ma chee-TAH-yet NO-vu-yu KNEE-gu", "Mom is reading a new book.", "Mama anasoma kitabu kipya."),
    L("Я вижу окно и море.", "ya VEE-zhu ak-NOH ee MOH-rye", "I see a window and the sea.", "Naona dirisha na bahari."), L("Мы говорим о книге.", "my ga-va-REEM a KNEE-gye", "We talk about the book.", "Tunaongea kuhusu kitabu."), L("Пока!", "pa-KAH", "Bye!", "Kwaheri!")],
   [D("Mama anasoma nini?", ["Kitabu kipya", "Wimbo", "Barua", "Ramani"], 0), D("Ninaona nini?", ["Dirisha na bahari", "Nyumba na gari", "Jumba la makumbusho", "Wimbo"], 0), D("Wanaongea kuhusu nini?", ["Kitabu", "Bahari", "Dirisha", "Maji"], 0)])],
 songs=[SG("ru_g1", "Wimbo wa Herufi", "🎵", [L("А, Б, В, Г, Д — мы поём!", "ah, beh, veh, geh, deh — my pa-YOM", "A, B, V, G, D, we sing!", "A, B, V, G, D — tunaimba!"), L("Мама, дом, окно, вода,", "MAH-ma, dom, ak-NOH, va-DAH", "Mom, house, window, water,", "Mama, nyumba, dirisha, maji,"),
    L("Читаем, говорим, поём,", "chee-TAH-yem, ga-va-REEM, pa-YOM", "We read, we speak, we sing,", "Tunasoma, tunaongea, tunaimba,"), L("Русский язык — это игра!", "ROOS-kiy ya-ZYK E-ta ee-GRAH", "The Russian language is a game!", "Lugha ya Kirusi ni mchezo!")])])

for lang in (es, ja, zh, ru):
    (OUT / f"{lang['code']}.json").write_text(json.dumps(lang, ensure_ascii=False, indent=1))
    print(lang["code"], sum(len(u["items"]) for u in lang["units"]), "items", len(lang["units"]), "units")
