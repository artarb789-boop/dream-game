extends SceneTree
const World=preload("res://world.gd")
var w=World.new()
var errors=0
func check(ok,msg):
	if not ok:
		errors+=1
		printerr(msg)
func travel(goal):
	var queue=[w.pos]
	var prev={w.pos:w.pos}
	while not queue.is_empty() and not prev.has(goal):
		var q=queue.pop_front()
		for d in [Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]:
			var n=q+d
			if not prev.has(n) and (w.step_ok(n) or w.tile(n)=="+"):
				prev[n]=q
				queue.append(n)
	if not prev.has(goal):
		check(false,"No route")
		return
	var path=[]
	var p=goal
	while p!=w.pos:
		path.push_front(p)
		p=prev[p]
	for n in path:
		for i in range(8):
			if w.pos==n:break
			w.walk(n-w.pos)
		check(w.pos==n,"Failed to reach "+str(n))
func _init():
	travel(Vector2i(5,2))
	w.act(Vector2i(6,2))
	travel(Vector2i(4,8))
	w.act(Vector2i(4,9))
	travel(Vector2i(6,7))
	w.act(Vector2i(6,8))
	travel(Vector2i(4,2))
	w.act(Vector2i(3,2),0)
	w.act(Vector2i(3,2),1)
	check(w.clean==3,"Boil three portions")
	w.consume("Пить")
	travel(Vector2i(17,3))
	w.act(Vector2i(17,2))
	travel(Vector2i(5,5))
	w.act(Vector2i(5,6))
	check(w.fixed and w.qty("Доски")==0 and w.qty("Гвозди")==2,"Repair consumes materials")
	travel(Vector2i(4,4))
	w.act(Vector2i(3,4))
	check(w.won(),"Complete episode")
	var saved=JSON.parse_string(JSON.stringify(w.snapshot()))
	var restored=World.new()
	check(restored.restore(saved),"Save round trip")
	restored.advance(1)
	check(restored.won() and restored.turn==w.turn+1,"Continue after load")
	print("Day complete: ",w.won(),"; turns: ",w.turn,"; HP: ",w.hp,"; failures: ",errors)
	quit(1 if errors else 0)
