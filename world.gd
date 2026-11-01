extends RefCounted

const MAP = [
	"tt....t....===....tt..t",
	"..######...===.#######.",
	"..#S..K#...===.#.T..W#.",
	"..#....#...===.#.....#.",
	"..#B...+...===.+.....#.",
	"..#...C#...===.#######.",
	"..###X##...===.........",
	"...........===....t....",
	"t.....R....===.........",
	"..t.L......===..######.",
	".......t...===..#..A.#.",
	".t..t......===..+....#.",
	"...t.....t.===..######.",
	"t....tt....===.......tt",
	"..t........===..t..t..."
]
const NAMES = {"S":"Печь","K":"Кухонный шкаф","B":"Кровать","C":"Старый стул","X":"Разбитое окно","R":"Дождевая бочка","L":"Дрова под навесом","T":"Ящик мастера","W":"Штабель досок","A":"Аптечка","+":"Дверь"}
const HINTS = {"S":"Печь сушит одежду, согревает дом и кипятит воду.","K":"На полке котелок и банка консервов.","B":"Двадцать минут отдыха восстановят немного здоровья.","C":"Из стула можно получить две доски и растопку.","X":"В щель тянет холодом. Пригодятся две доски, четыре гвоздя и молоток.","R":"Вода сырая. Наберите её в котелок и прокипятите.","L":"Под жестью сложены сухие дрова и доски.","T":"Внутри молоток и коробка гвоздей.","W":"В мастерской остались сухие доски и дрова.","A":"На полке бинты и консервы.","+":"Закрытая дверь скрывает вас и преграждает путь."}
const LOOT={"K":{"Котелок":1,"Консервы":1},"L":{"Дрова":3,"Доски":2},"T":{"Молоток":1,"Гвозди":6},"W":{"Дрова":2,"Доски":2},"A":{"Бинт":2,"Консервы":1},"C":{"Доски":2,"Дрова":1}}
var pos=Vector2i(4,3)
var turn:int=0
var hp:int=100
var wet:float=0
var cold:float=10
var thirst:float=25
var hunger:float=10
var fire:int=0
var raw:int=0
var clean:int=0
var fixed=false
var drank=false
var rested=false
var bag={"Спички":1,"Бинт":1,"Консервы":1}
var empty={}
var open_doors={}
var foes=[{"x":13,"y":8,"hp":2},{"x":19,"y":8,"hp":2}]
var logbook=["Дом на окраине. Вода на исходе. Через дорогу видна мастерская."]
func key(p): return "%d,%d" % [p.x,p.y]
func tile(p):
	if p.x<0 or p.y<0 or p.y>=MAP.size() or p.x>=MAP[p.y].length(): return "#"
	return MAP[p.y][p.x]
func dist(a,b): return absi(a.x-b.x)+absi(a.y-b.y)
func home(p): return Rect2i(3,2,4,4).has_point(p)
func indoors(p): return home(p) or Rect2i(16,2,5,3).has_point(p) or Rect2i(17,10,4,2).has_point(p)
func step_ok(p): return tile(p) not in ["#","t","X"] and (tile(p)!="+" or open_doors.has(key(p)))
func clock(): return "%02d:%02d" % [(16+turn/60)%24,turn%60]
func rain(): return turn%100<70
func won(): return fixed and drank and rested and hp>0
func note(s):
	logbook.append(clock()+"   "+s)
	if logbook.size()>12: logbook.pop_front()
func qty(s): return int(bag.get(s,0))
func give(s,n): bag[s]=qty(s)+n
func foe_at(p):
	for e in foes:
		if p==Vector2i(int(e.x),int(e.y)): return e
	return {}
func sees(a,b):
	var n=maxi(absi(a.x-b.x),absi(a.y-b.y))
	for i in range(1,n):
		var q=Vector2i(Vector2(a).lerp(Vector2(b),float(i)/n).round())
		if not step_ok(q) and tile(q)!="X": return false
	return true
func enemy_turn():
	for e in foes:
		var q=Vector2i(int(e.x),int(e.y))
		if dist(q,pos)==1:
			hp=maxi(0,hp-7)
			note("Мертвец ранил вас. −7 здоровья.")
		elif dist(q,pos)<=6 and sees(q,pos):
			for d in [Vector2i(signi(pos.x-q.x),0),Vector2i(0,signi(pos.y-q.y))]:
				var n=q+d
				if n!=q and step_ok(n) and foe_at(n).is_empty():
					e.x=n.x
					e.y=n.y
					break
func advance(n,interrupt=false):
	for i in range(n):
		if hp<=0: return false
		if interrupt:
			for e in foes:
				var q=Vector2i(int(e.x),int(e.y))
				if dist(q,pos)<=4 and sees(q,pos):
					note("Слишком близко мертвец. Работа остановлена.")
					return false
		turn+=1
		thirst=minf(100,thirst+0.18)
		hunger=minf(100,hunger+0.09)
		wet=clampf(wet+(2 if rain() and not indoors(pos) else (-3 if home(pos) and fire>0 else -0.4)),0,100)
		cold=clampf(cold+(-1.2 if home(pos) and (fixed or fire>0) else (0.45 if wet>30 else 0.025)),0,100)
		fire=maxi(0,fire-1)
		if thirst>=95 or cold>=90 or hunger>=95: hp=maxi(0,hp-1)
		if turn%2==0: enemy_turn()
	return hp>0
func walk(d):
	if hp<=0: return
	var n=pos+d
	var e=foe_at(n)
	if not e.is_empty():
		e.hp-=1
		if e.hp<=0:
			foes.erase(e)
			note("Путь свободен.")
		else: note("Вы оттолкнули и ранили мертвеца.")
	elif tile(n)=="+" and not open_doors.has(key(n)):
		open_doors[key(n)]=true
		note("Дверь открыта.")
	elif step_ok(n): pos=n
	else: return
	advance(1)
func actions(p):
	var t=tile(p)
	if dist(pos,p)>1 or hp<=0: return []
	if LOOT.has(t) and not empty.has(key(p)):
		if t=="C": return [["Разобрать стул · 8 мин","Нужен молоток" if qty("Молоток")==0 else ""]]
		return [["Забрать вещи · 2 мин",""]]
	match t:
		"R": return [["Наполнить котелок · 2 мин","Нужен пустой котелок" if qty("Котелок")==0 or raw+clean>0 else ""]]
		"S": return [["Растопить печь · 3 мин","Нужны дрова" if qty("Дрова")==0 else ""],["Кипятить воду · 10 мин","Нужна сырая вода и 10 мин огня" if raw==0 or fire<10 else ""]]
		"X":
			if not fixed: return [["Заделать окно · 12 мин","Молоток, 2 доски и 4 гвоздя" if qty("Молоток")==0 or qty("Доски")<2 or qty("Гвозди")<4 else ""]]
		"B": return [["Отдохнуть · 20 мин",""]]
		"+":
			if open_doors.has(key(p)): return [["Закрыть дверь","Проём занят" if p==pos or not foe_at(p).is_empty() else ""]]
			return [["Открыть дверь",""]]
	return []
func act(p,index=0):
	var opts=actions(p)
	if index<0 or index>=opts.size() or opts[index][1]!="": return
	var t=tile(p)
	if LOOT.has(t):
		if not advance(8 if t=="C" else 2,t=="C"): return
		for item in LOOT[t]:
			give(item,LOOT[t][item])
			note("%s +%d" % [item,LOOT[t][item]])
		empty[key(p)]=true
	elif t=="R":
		raw=3
		advance(2)
		note("Котелок полон. Воду ещё нужно прокипятить.")
	elif t=="S" and index==0:
		give("Дрова",-1)
		fire+=45
		advance(3)
		note("Печь разгорелась.")
	elif t=="S" and advance(10,true):
		clean=raw
		raw=0
		note("Вода безопасна для питья.")
	elif t=="X" and advance(12,true):
		give("Доски",-2)
		give("Гвозди",-4)
		fixed=true
		note("Окно закрыто досками. В доме стало теплее.")
	elif t=="B" and advance(20,true):
		rested=true
		hp=mini(100,hp+8)
		note("Вы отдохнули.")
	elif t=="+":
		if open_doors.has(key(p)): open_doors.erase(key(p))
		else: open_doors[key(p)]=true
		advance(1)
func consume(s):
	if hp<=0:return
	match s:
		"Пить":
			if clean<1: return note("Нет чистой воды.")
			clean-=1
			thirst=maxf(0,thirst-35)
			drank=true
		"Есть":
			if qty("Консервы")==0:return note("Консервы закончились.")
			give("Консервы",-1)
			hunger=maxf(0,hunger-40)
		"Бинт":
			if qty("Бинт")==0 or hp>=100:return note("Бинт не нужен или его нет.")
			give("Бинт",-1)
			hp=mini(100,hp+25)
	advance(1)
const FIELDS=["turn","hp","wet","cold","thirst","hunger","fire","raw","clean","fixed","drank","rested","bag","empty","open_doors","foes","logbook"]
func snapshot():
	var data={"version":1,"pos":[pos.x,pos.y]}
	for field in FIELDS:data[field]=get(field)
	return data
func restore(data):
	if not data is Dictionary or data.get("version")!=1:return false
	for field in FIELDS:
		if not data.has(field):return false
	if not data.get("pos") is Array or data.pos.size()!=2:return false
	for field in FIELDS:set(field,data[field])
	pos=Vector2i(int(data.pos[0]),int(data.pos[1]))
	return true
