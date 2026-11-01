extends Control
const World=preload("res://world.gd")
const BASE=Vector2(28,102)
const CELL=34
const GOLD=Color("#edbd75")
const TEXT=Color("#e4e7da")
const FADE=Color("#a6bab1")
var w=World.new()
var pick=Vector2i(6,2)
var title: Label
var details: Label
var status: Label
var bag: Label
var goals: Label
var diary: Label
var verbs: VBoxContainer
var restart: ConfirmationDialog

func label(s,p,sz,px,ink=TEXT):
	var l=Label.new()
	l.text=s
	l.position=p
	l.size=sz
	l.add_theme_font_size_override("font_size",px)
	l.add_theme_color_override("font_color",ink)
	l.vertical_alignment=VERTICAL_ALIGNMENT_TOP
	l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	l.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(l)
	return l

func btn(parent,s,cb):
	var b=Button.new()
	b.text=s
	b.focus_mode=Control.FOCUS_NONE
	b.pressed.connect(cb)
	parent.add_child(b)
	return b

func row(p):
	var box=HBoxContainer.new()
	box.position=p
	add_child(box)
	return box

func _ready():
	var skin=Theme.new()
	var style=StyleBoxFlat.new()
	style.bg_color=Color("#334746")
	style.set_corner_radius_all(4)
	style.content_margin_left=9
	style.content_margin_right=9
	style.content_margin_top=5
	style.content_margin_bottom=5
	skin.set_stylebox("normal","Button",style)
	skin.default_font_size=14
	theme=skin
	label("ПЕРВОЕ УБЕЖИЩЕ",Vector2(28,21),Vector2(590,46),34)
	label("ПОЛЕВОЙ ДНЕВНИК    /    УЧАСТОК 01",Vector2(30,68),Vector2(590,23),14,GOLD)
	label("ОКРАИНА    /    ПЕРВЫЙ ДЕНЬ",Vector2(836,30),Vector2(337,26),14,GOLD)
	status=label("",Vector2(836,65),Vector2(336,75),15)
	title=label("",Vector2(837,158),Vector2(335,35),23)
	details=label("",Vector2(837,200),Vector2(335,88),15,FADE)
	verbs=VBoxContainer.new()
	verbs.position=Vector2(837,287)
	verbs.size.x=330
	add_child(verbs)
	label("РЮКЗАК",Vector2(837,390),Vector2(330,24),13,GOLD)
	bag=label("",Vector2(837,417),Vector2(335,78),15)
	var r=row(Vector2(837,499))
	for action in ["Пить","Есть","Бинт","Ждать"]:btn(r,action,use_item.bind(action))
	goals=label("",Vector2(837,556),Vector2(335,110),15)
	var files=row(Vector2(837,695))
	btn(files,"F5 Запись",save_game)
	btn(files,"F9 Загрузка",load_game)
	btn(files,"Сначала",func():restart.popup_centered())
	restart=ConfirmationDialog.new()
	restart.title="Начать заново?"
	restart.dialog_text="Текущий день начнётся сначала. Запись F5 сохранится."
	restart.confirmed.connect(func():w=World.new();pick=Vector2i(6,2);refresh())
	add_child(restart)
	label("WASD / стрелки — шаг     •     ЛКМ — осмотреть     •     E — выбрать рядом     •     Пробел — ждать",Vector2(29,621),Vector2(785,27),14,FADE)
	diary=label("",Vector2(29,661),Vector2(780,93),15)
	refresh()

func refresh():
	var t=w.tile(pick)
	title.text=World.NAMES.get(t,{"#":"Стена","t":"Дерево","=":"Дорога"}.get(t,"Осмотр участка"))
	details.text=World.HINTS.get(t,"Под крышей одежда сохнет." if w.indoors(pick) else "Под дождём одежда промокает. Укрытие помогает согреться.")
	if t=="X" and w.fixed:
		title.text="Заделанное окно"
		details.text="Доски держатся крепко. Сквозняка нет."
	if w.empty.has(w.key(pick)):details.text="Здесь уже всё забрали."
	if t=="S":details.text+=" Осталось %d мин огня." % w.fire
	if not w.foe_at(pick).is_empty():
		title.text="Мертвец"
		details.text="Движется через ход. Шаг в его сторону с соседней клетки — удар."
	for child in verbs.get_children():
		verbs.remove_child(child)
		child.queue_free()
	var options=w.actions(pick)
	for i in range(options.size()):
		var o=options[i]
		var b=btn(verbs,o[0] if o[1]=="" else o[1],interact.bind(i))
		b.disabled=o[1]!=""
		b.tooltip_text=o[0]
	if w.dist(w.pos,pick)>1 and World.NAMES.has(t):details.text+=" Подойдите вплотную."
	status.text="%s   /   %s\nЗдоровье %d     Холод %d     Сырость %d\nЖажда %d     Голод %d" % [w.clock(),"Дождь" if w.rain() else "Прояснение",w.hp,w.cold,w.wet,w.thirst,w.hunger]
	var items=PackedStringArray()
	for item in w.bag:
		if w.qty(item)>0:items.append("%s ×%d" % [item,w.qty(item)])
	bag.text=" · ".join(items)+"\nВода: сырая %d  /  чистая %d" % [w.raw,w.clean]
	goals.text="К НОЧЛЕГУ\n%s  Выпить кипячёную воду\n%s  Заделать разбитое окно\n%s  Отдохнуть на кровати" % [tick(w.drank),tick(w.fixed),tick(w.rested)]
	if w.won():goals.text="УБЕЖИЩЕ ГОТОВО\nВ доме тепло, вода безопасна. Первый эпизод пройден. Можно исследовать район дальше."
	if w.hp<=0:goals.text="ВЫ НЕ ВЫЖИЛИ\nНажмите F9, чтобы вернуться к записи, или начните заново."
	diary.text="\n".join(w.logbook.slice(maxi(0,w.logbook.size()-4)))
	queue_redraw()
func tick(v):return "✓" if v else "○"
func interact(i):w.act(pick,i);refresh()
func use_item(action):w.consume(action);refresh()
func save_game():
	var f=FileAccess.open("user://day.json",FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(w.snapshot()))
		w.note("День сохранён.")
	else:w.note("Не удалось записать сохранение.")
	refresh()
func load_game():
	if FileAccess.file_exists("user://day.json") and w.restore(JSON.parse_string(FileAccess.get_file_as_string("user://day.json"))):
		pick=w.pos
		w.note("День загружен.")
	else:w.note("Подходящей записи нет.")
	refresh()
func _gui_input(ev):
	if ev is InputEventMouseButton and ev.pressed and ev.button_index==MOUSE_BUTTON_LEFT:
		if Rect2(BASE,Vector2(23,15)*CELL).has_point(ev.position):
			pick=Vector2i((ev.position-BASE)/CELL)
			refresh()
func _unhandled_key_input(ev):
	if not ev is InputEventKey or not ev.pressed or ev.echo or restart.visible:return
	match ev.physical_keycode:
		KEY_W,KEY_UP:w.walk(Vector2i.UP)
		KEY_S,KEY_DOWN:w.walk(Vector2i.DOWN)
		KEY_A,KEY_LEFT:w.walk(Vector2i.LEFT)
		KEY_D,KEY_RIGHT:w.walk(Vector2i.RIGHT)
		KEY_SPACE:w.consume("Ждать")
		KEY_F5:save_game()
		KEY_F9:load_game()
		KEY_E:
			var near=[]
			for d in [Vector2i.ZERO,Vector2i.LEFT,Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN]:
				if not w.actions(w.pos+d).is_empty():near.append(w.pos+d)
			if near.size():pick=near[(near.find(pick)+1)%near.size()]
	refresh()

func box(p,x,y,b,h,c):draw_rect(Rect2(p+Vector2(x,y),Vector2(b,h)),Color(c))
func dot(p,x,y,r,c):draw_circle(p+Vector2(x,y),r,Color(c))
func line(p,x,y,xx,yy,c,width=1):draw_line(p+Vector2(x,y),p+Vector2(xx,yy),Color(c),width)
func _draw():
	draw_rect(Rect2(820,16,370,727),Color("#192a2c"))
	draw_rect(Rect2(BASE-Vector2(2,2),Vector2(23,15)*CELL+Vector2(4,4)),Color("#566559"))
	for y in range(World.MAP.size()):
		for x in range(World.MAP[y].length()):
			var q=Vector2i(x,y)
			var p=BASE+Vector2(q)*CELL
			var t=w.tile(q)
			var mix=(x*31+y*17)%9
			var floor_t=w.indoors(q)
			var ground=Color("#6b6252") if floor_t else (Color("#495052") if t=="=" else Color("#455445"))
			draw_rect(Rect2(p,Vector2.ONE*CELL),ground.lightened(float(mix)/120))
			if floor_t:
				line(p,0,11,34,11,"#564e43")
				line(p,0,23,34,23,"#564e43")
				line(p,8+mix,0,8+mix,11,"#564e43")
			elif t=="=":
				if x==12 and y%3!=0:box(p,16,2,2,25,"#a4a187")
				line(p,3+mix,25,7+mix,22,"#3d4244")
			else:
				for j in range(3):
					var a=(x*3+y*7+j*11)%29
					var b=(x*9+y*2+j*13)%28+4
					line(p,a,b,a+2,b-4,"#76816a")
			match t:
				"#":
					box(p,0,4,34,30,"#363f3b")
					box(p,0,1,34,25,"#8c9183")
					line(p,1,3,33,3,"#bdbeab",2)
					line(p,0,14,34,14,"#70796e")
					line(p,10+mix,4,10+mix,13,"#70796e")
				"t":
					box(p,15,22,5,10,"#614e3c")
					dot(p,19,19,14,"#293e37")
					dot(p,13,14,12,"#50694e")
					dot(p,20,10,9,"#637a59")
				"+":
					box(p,3,1,4 if w.open_doors.has(w.key(q)) else 26,31,"#ae8864")
					if not w.open_doors.has(w.key(q)):dot(p,24,18,2,"#ecd290")
				"X":
					box(p,0,8,34,19,"#334243")
					if w.fixed:box(p,0,10,34,5,"#b58b62");box(p,0,19,34,5,"#b58b62")
					else:line(p,2,11,13,22,"#abcfcb",3);line(p,24,12,30,20,"#abcfcb",3)
				"B":
					box(p,4,2,25,30,"#463d34");box(p,6,4,21,25,"#819789");box(p,7,5,19,7,"#e0d8b9")
				"S":
					box(p,5,4,24,24,"#313b3a");dot(p,16,13,7,"#1a2022");box(p,9,22,16,4,"#eeb06a" if w.fire else "#152022")
				"R":
					dot(p,17,18,13,"#363c37");dot(p,16,14,12,"#92a99b");dot(p,16,14,9,"#526f76")
				"C","T","A","K","L","W":
					var used=w.empty.has(w.key(q))
					box(p,4,6,26,23,"#645b49" if used else "#ac8e62")
					box(p,6,9,22,16,"#554f41" if used else "#776143")
					if not used:draw_string(ThemeDB.fallback_font,p+Vector2(5,22),{"K":"К","A":"+","C":"С","T":"М","L":"Д","W":"Д"}[t],HORIZONTAL_ALIGNMENT_CENTER,23,15,TEXT)
	for e in w.foes:person(Vector2i(int(e.x),int(e.y)),false)
	person(w.pos,true)
	draw_rect(Rect2(BASE+Vector2(pick)*CELL+Vector2.ONE,Vector2(32,32)),GOLD,false,2)
func person(q,player):
	var p=BASE+Vector2(q)*CELL
	dot(p,18,23,11,"#333b35")
	box(p,10,20,5,9,"#313a3a");box(p,20,20,5,9,"#313a3a")
	dot(p,17,17,9,"#d8ac68" if player else "#975e54")
	dot(p,17,10,6,"#d5b59a" if player else "#acb399")
	if player:draw_arc(p+Vector2(17,17),15,0,TAU,30,GOLD,1.5)
