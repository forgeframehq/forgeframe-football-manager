extends Control

const GOLD = Color("#ecc56d")
const GOLD_DARK = Color("#b58d43")
const IVORY = Color("#f5f0df")
const MUTED = Color("#a4b8ae")
const GREEN = Color("#59db83")
const DARK = Color("#061613")
const PANEL = Color("#08271e")
const PANEL2 = Color("#10372b")
const BORDER = Color("#46684c")
const ERROR = Color("#f38c7e")
const DIVISIONS = [
	["Crown Premier", "Harbour City", "Westbridge United", "Ashford Rovers", "Valence Athletic", "Kingsport FC", "Riverside Albion", "Newcastle Vale", "Oldcastle City", "Meridian FC", "Briarwood", "Southport Wanderers", "Windsor Athletic"],
	["National Championship", "Northbridge FC", "Ironhaven Town", "Eastfield United", "Wexford City", "Everton Vale", "Portsmouth Athletic", "Lakeside Rovers", "Whitestone FC", "Cedar Town", "Blackwater United", "Hillcrest FC", "Redford City"]
]
const FIRST_NAMES = ["Mateo","Luca","Ethan","Noah","Oliver","Theo","Amir","Kai","Marco","Rafael","Leo","Daniel","Samir","Jude","Felix","Ivan","Alex","Gabriel","Milan","Hugo","Ben","Oscar","Dario","Luis","Dylan","Yusuf","Kenji","Andre"]
const LAST_NAMES = ["Silva","Mendez","Warren","Okafor","Sato","Hart","Rossi","Parker","Diallo","Torres","Bennett","Fischer","Mercer","Costa","Nordin","Brooks","Alvarez","Costa","Reed","Zoric","Walsh","Rivas","Moreau","Park","Hayes","Mensah","Duarte"]
const POSITIONS = ["GK","RB","CB","CB","LB","CDM","CM","CAM","RW","LW","ST","GK","RB","CB","LB","CM","CDM","RW","LW","ST","ST","CAM"]
const NAV = ["OFFICE","SQUAD","TACTICS","MARKET","CLUB"]
const NAV_ICONS = ["⌂","♙","▦","⇄","♜"]
const TABS = [
	["Overview","Table","Calendar","Inbox"],
	["First XI","All Players","Training","Contracts"],
	["Formation","Instructions","Set Pieces"],
	["Scout","Shortlist","Offers"],
	["Overview","Stadium","Facilities","Finances"]
]
var world = {}
var state = {}
var fixtures = []
var round_games = []
var active_match = {}
var shortlisted = []
var offers = []
var main_tab = 0
var sub_tab = 0
var root_col: VBoxContainer
var content: VBoxContainer
var header_club: Label
var timer: Timer
var notification = ""
var picked_player = -1
var selected_market = -1
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	_load_game()
	_build_shell()
	_redraw()

func _new_game() -> void:
	world = {"squads": {}, "tables": {}, "season": 2026, "division": 1, "round": 0}
	for league_index in range(2):
		for i in range(1, DIVISIONS[league_index].size()):
			var club: String = DIVISIONS[league_index][i]
			var players: Array = []
			for k in range(POSITIONS.size()):
				var rating = rng.randi_range(66,83) if league_index == 0 else rng.randi_range(55,73)
				var age = rng.randi_range(17,33)
				var name = FIRST_NAMES[rng.randi_range(0,FIRST_NAMES.size()-1)] + " " + LAST_NAMES[rng.randi_range(0,LAST_NAMES.size()-1)]
				players.append({"name":name,"pos":POSITIONS[k],"ovr":rating,"pot":mini(96,rating+rng.randi_range(1,17)),"age":age,"value":maxi(1,int(pow(float(rating-42),2.0)*0.018)),"wage":maxi(3,int(rating*0.6)),"morale":rng.randi_range(66,94),"fitness":100,"contract":rng.randi_range(1,5),"form":6.5})
			world.squads[club] = players
	_reset_standings()
	state = {"club":"","name":"Manager","funds":38,"coins":275,"training":2,"academy":2,"scouting":2,"stadium":12500,"attendance":77,"board":75,"chemistry":75,"morale":78,"formation":"4-2-3-1","mentality":"Balanced","pressing":"Medium","passing":"Short","line":"Standard","results":[],"inbox":["Welcome to the Touchline Dynasty football world."],"wins":0,"played":0,"goals":0,"against":0,"trophies":0,"year":2026,"week":0,"division":1}
	shortlisted.clear()
	offers.clear()
	_build_fixtures()

func _reset_standings() -> void:
	world.tables = {}
	for d in range(2):
		for i in range(1,DIVISIONS[d].size()):
			var name: String = DIVISIONS[d][i]
			world.tables[name] = {"p":0,"w":0,"d":0,"l":0,"gf":0,"ga":0,"pts":0}

func _build_fixtures() -> void:
	fixtures = []
	for d in range(2):
		var teams = DIVISIONS[d].slice(1)
		var n = teams.size()
		for r in range(n-1):
			for k in range(n/2):
				var home = str(teams[k])
				var away = str(teams[n-1-k])
				if (r+k)%2 != 0:
					var temp = home
					home = away
					away = temp
				fixtures.append({"week":r,"division":d,"home":home,"away":away})
				fixtures.append({"week":r+n-1,"division":d,"home":away,"away":home})
			var last = teams.pop_back()
			teams.insert(1,last)

func _load_game() -> void:
	if not FileAccess.file_exists("user://touchline_save.json"):
		_new_game()
		return
	var file = FileAccess.open("user://touchline_save.json",FileAccess.READ)
	var value = JSON.parse_string(file.get_as_text())
	if not (value is Dictionary) or not value.has("world") or not value.has("state"):
		_new_game()
		return
	world = value.world
	state = value.state
	shortlisted = value.get("shortlisted",[])
	offers = value.get("offers",[])
	_build_fixtures()
	active_match = value.get("active_match",{})

func _save() -> void:
	var file = FileAccess.open("user://touchline_save.json",FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({"world":world,"state":state,"shortlisted":shortlisted,"offers":offers,"active_match":active_match}))

func _style(fill:Color=PANEL,stroke:Color=BORDER,radius:int=16) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = fill
	s.border_color = stroke
	s.set_border_width_all(2)
	s.set_corner_radius_all(radius)
	s.content_margin_left = 16
	s.content_margin_right = 16
	s.content_margin_top = 12
	s.content_margin_bottom = 12
	return s

func _label(text:String,size:int=23,color:Color=IVORY,bold:bool=false) -> Label:
	var l=Label.new()
	l.text=text
	l.add_theme_color_override("font_color",color)
	l.add_theme_font_size_override("font_size",size)
	if bold:
		l.add_theme_color_override("font_shadow_color",Color(0,0,0,0.7))
		l.add_theme_constant_override("shadow_offset_y",2)
	l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	return l

func _button(text:String,call:Callable,primary:bool=false) -> Button:
	var b=Button.new()
	b.text=text
	b.custom_minimum_size=Vector2(95,64)
	b.add_theme_color_override("font_color",DARK if primary else IVORY)
	b.add_theme_color_override("font_hover_color",DARK if primary else GOLD)
	b.add_theme_color_override("font_pressed_color",DARK)
	b.add_theme_font_size_override("font_size",22)
	b.add_theme_stylebox_override("normal",_style(GOLD if primary else PANEL2,GOLD if primary else BORDER,13))
	b.add_theme_stylebox_override("hover",_style(GOLD if primary else Color("#1a4936"),GOLD,13))
	b.add_theme_stylebox_override("pressed",_style(GOLD_DARK,GOLD,13))
	b.pressed.connect(call)
	return b

func _card(parent:Node) -> PanelContainer:
	var p=PanelContainer.new()
	p.add_theme_stylebox_override("panel",_style())
	parent.add_child(p)
	return p

func _column(parent:Node,gap:int=12) -> VBoxContainer:
	var v=VBoxContainer.new()
	v.add_theme_constant_override("separation",gap)
	parent.add_child(v)
	return v

func _row(parent:Node,gap:int=12) -> HBoxContainer:
	var h=HBoxContainer.new()
	h.add_theme_constant_override("separation",gap)
	parent.add_child(h)
	return h

func _heading(text:String,small:String="") -> void:
	content.add_child(_label(text,40,GOLD,true))
	if small!="":
		content.add_child(_label(small,20,MUTED))

func _stat(parent:Node,title:String,value:String) -> void:
	var p=_card(parent)
	p.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var v=_column(p,5)
	v.add_child(_label(title.to_upper(),17,MUTED))
	v.add_child(_label(value,27,GOLD,true))

func _section(parent:Node,title:String) -> VBoxContainer:
	var v=_column(parent,8)
	v.add_child(_label(title.to_upper(),23,GOLD,true))
	return v

func _build_shell() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg=ColorRect.new()
	bg.color=DARK
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	root_col=_column(self,0)
	root_col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var top=PanelContainer.new()
	top.add_theme_stylebox_override("panel",_style(Color("#03100f"),GOLD_DARK,0))
	top.custom_minimum_size.y=118
	root_col.add_child(top)
	var head=_row(top,16)
	var badge=_label("TD",44,GOLD,true)
	badge.custom_minimum_size.x=86
	badge.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	head.add_child(badge)
	var clubbox=_column(head,2)
	clubbox.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	clubbox.add_child(_label("TOUCHLINE DYNASTY",20,GOLD,true))
	header_club=_label("",28,IVORY,true)
	clubbox.add_child(header_club)
	var money=_label("",20,GOLD)
	money.name="Money"
	money.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	head.add_child(money)
	var sc=ScrollContainer.new()
	sc.name="MainScroll"
	sc.size_flags_vertical=Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	root_col.add_child(sc)
	content=_column(sc,17)
	content.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	content.custom_minimum_size.x=720
	var nav=HBoxContainer.new()
	nav.name="Navigation"
	nav.add_theme_constant_override("separation",1)
	nav.custom_minimum_size.y=100
	root_col.add_child(nav)
	for i in range(NAV.size()):
		var n=i
		var b=_button(NAV_ICONS[i]+"\n"+NAV[i],func(): main_tab=n;sub_tab=0;_redraw())
		b.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size",17)
		nav.add_child(b)
	timer=Timer.new()
	timer.wait_time=0.8
	timer.timeout.connect(_tick_match)
	add_child(timer)

func _redraw() -> void:
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()
	header_club.text=state.get("club","") if str(state.get("club",""))!="" else "CREATE YOUR LEGACY"
	var m=root_col.get_child(0).find_child("Money",true,false)
	if m: m.text="€%dM\nSEASON %d" % [int(state.get("funds",0)),int(state.get("year",2026))]
	var nav=root_col.get_node("Navigation")
	nav.visible=state.get("club","")!=""
	if state.get("club","")=="":
		_club_selection()
		return
	if not active_match.is_empty():
		_live_match()
		return
	var title=["MANAGER'S OFFICE","YOUR SQUAD","TACTICAL BOARD","TRANSFER MARKET","YOUR CLUB"][main_tab]
	content.add_child(_label(title,42,IVORY,true))
	var strip=_row(content,5)
	for i in range(TABS[main_tab].size()):
		var chosen=i
		var bt=_button(TABS[main_tab][i],func():sub_tab=chosen;_redraw(),i==sub_tab)
		bt.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		bt.add_theme_font_size_override("font_size",19)
		strip.add_child(bt)
	match main_tab:
		0: _office()
		1: _squad()
		2: _tactics()
		3: _market()
		4: _club()
	if notification!="":
		var note=_card(content)
		note.add_child(_label(notification,19,GOLD))
		notification=""

func _club_selection() -> void:
	_heading("YOUR LEGACY STARTS HERE","Choose a club in the National Championship. Rise through the divisions.")
	var banner=_card(content)
	var v=_column(banner,7)
	v.add_child(_label("2026 / 27  •  SEASON ONE",22,GOLD))
	v.add_child(_label("TAKE THE TOUCHLINE",44,IVORY,true))
	v.add_child(_label("Scout. Negotiate. Build a dynasty.",22,MUTED))
	for i in range(1,DIVISIONS[1].size()):
		var club=DIVISIONS[1][i]
		var p=_card(content)
		var h=_row(p,14)
		var icon=_label("✦",37,GOLD)
		h.add_child(icon)
		var details=_column(h,3)
		details.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		details.add_child(_label(club,26,IVORY,true))
		details.add_child(_label("National Championship  •  Budget €%dM" % (48-i),18,MUTED))
		h.add_child(_button("MANAGE",func():_select_club(club,48-i),true))

func _select_club(club:String,budget:int) -> void:
	state.club=club
	state.funds=budget
	state.inbox=["Board: Finish in the top half this season.","Head scout: Your initial shortlist is ready.","Welcome to %s. Your football journey begins." % club]
	_save()
	_redraw()

func _next_fixture() -> Dictionary:
	for f in fixtures:
		if int(f.division)==int(state.division) and int(f.week)==int(state.week):
			if f.home==state.club or f.away==state.club:
				return f
	return {}

func _office() -> void:
	match sub_tab:
		0: _office_overview()
		1: _league_table()
		2: _calendar()
		3: _inbox()

func _office_overview() -> void:
	var top=_card(content)
	var v=_column(top,8)
	v.add_child(_label("SEASON %d/%02d     •     MATCHDAY %d / 22" % [int(state.year),int(state.year)%100+1,int(state.week)+1],20,GOLD))
	v.add_child(_label("THE ROAD TO THE TOP",35,IVORY,true))
	v.add_child(_label("Board target: Secure a top-half finish and develop the academy.",20,MUTED))
	var fx=_next_fixture()
	var opponent="End of season"
	if not fx.is_empty():
		opponent=fx.away if fx.home==state.club else fx.home
	var match_card=_card(content)
	var mv=_column(match_card,12)
	mv.add_child(_label("UPCOMING MATCH  ·  NATIONAL CHAMPIONSHIP",20,GOLD))
	mv.add_child(_label("%s\n          VS\n%s" % [str(state.club),opponent],32,IVORY,true))
	mv.add_child(_label("Tactical outlook: %s  •  %s" % [str(state.formation),str(state.mentality)],20,MUTED))
	mv.add_child(_button("⚽  PLAY MATCHDAY",func():_begin_match(),true))
	var metrics=_row(content)
	_stat(metrics,"League points",str(_my_table().pts))
	_stat(metrics,"Board",str(state.board)+"%")
	_stat(metrics,"Team morale",str(state.morale)+"%")
	var lower=_row(content)
	_stat(lower,"Transfer budget","€%dM" % int(state.funds))
	_stat(lower,"Chemistry",str(state.chemistry))
	_stat(lower,"Record","%dW / %dP" % [int(state.wins),int(state.played)])
	var actions=_row(content)
	for item in [["LEAGUE TABLE",1],["SQUAD",2],["SCOUTING",3]]:
		var tab=int(item[1])
		var btn=_button(str(item[0]),func():main_tab=0 if tab==1 else tab-1;sub_tab=1 if tab==1 else 0;_redraw())
		btn.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		actions.add_child(btn)
	if state.results.size()>0:
		var last=state.results.back()
		var result=_card(content)
		result.add_child(_label("LAST RESULT   %s" % str(last),22,IVORY))

func _my_table() -> Dictionary:
	return world.tables.get(state.club,{"pts":0,"p":0,"gf":0,"ga":0,"w":0,"d":0,"l":0})

func _sorted_table() -> Array:
	var data=[]
	for i in range(1,DIVISIONS[int(state.division)].size()):
		var club=DIVISIONS[int(state.division)][i]
		data.append({"name":club,"stats":world.tables.get(club,{})})
	data.sort_custom(func(a,b):return int(a.stats.pts)>int(b.stats.pts) if a.stats.pts!=b.stats.pts else int(a.stats.gf)-int(a.stats.ga)>int(b.stats.gf)-int(b.stats.ga))
	return data

func _league_table() -> void:
	_heading("LEAGUE STANDINGS","Top two promoted  •  Bottom two relegated")
	var rank=1
	for t in _sorted_table():
		var line=_card(content)
		if t.name==state.club:
			line.add_theme_stylebox_override("panel",_style(Color("#3b3822"),GOLD))
		var h=_row(line,12)
		var nr=_label("%02d" % rank,22,GOLD,true)
		nr.custom_minimum_size.x=40
		h.add_child(nr)
		var name=_label(t.name,21,IVORY,t.name==state.club)
		name.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		h.add_child(name)
		h.add_child(_label("%dP   %dGD   %d" % [int(t.stats.p),int(t.stats.gf)-int(t.stats.ga),int(t.stats.pts)],19,GOLD))
		rank+=1

func _calendar() -> void:
	_heading("SEASON CALENDAR","Home and away fixtures")
	for f in fixtures:
		if int(f.division)!=int(state.division) or not (f.home==state.club or f.away==state.club):
			continue
		var p=_card(content)
		var h=_row(p,12)
		h.add_child(_label("MD %02d" % (int(f.week)+1),21,GOLD,true))
		var opponent=f.away if f.home==state.club else f.home
		var label=_label("%s   •   %s" % [opponent,"HOME" if f.home==state.club else "AWAY"],20)
		label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		h.add_child(label)
		h.add_child(_label("DONE" if int(f.week)<int(state.week) else "NEXT" if int(f.week)==int(state.week) else "—",17,MUTED))

func _inbox() -> void:
	_heading("CLUB INBOX","Board messages, scouting updates, transfer news")
	for message in state.inbox:
		var p=_card(content)
		p.add_child(_label("✉   "+str(message),21,IVORY))

func _my_players() -> Array:
	return world.squads[state.club]

func _squad() -> void:
	match sub_tab:
		0: _squad_first()
		1: _player_directory()
		2: _training()
		3: _contracts()

func _player_card(p:Dictionary,idx:int,show_detail:bool=true) -> void:
	var box=_card(content)
	var h=_row(box,14)
	var ov=_label(str(p.ovr),33,GOLD,true)
	ov.custom_minimum_size.x=58
	h.add_child(ov)
	var txt=_column(h,3)
	txt.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	txt.add_child(_label(str(p.name),22,IVORY,true))
	txt.add_child(_label("%s  •  AGE %s  •  POT %s" % [p.pos,p.age,p.pot],18,MUTED))
	if show_detail:
		h.add_child(_button("VIEW",func():_inspect_player(idx)))

func _inspect_player(idx:int) -> void:
	picked_player=idx
	var p=_my_players()[idx]
	notification="%s  |  OVR %d  |  Potential %d  |  Value €%dM  |  Wage €%dk/wk  |  Contract %dy" % [str(p.name),int(p.ovr),int(p.pot),int(p.value),int(p.wage),int(p.contract)]
	_redraw()

func _squad_first() -> void:
	_heading("FIRST TEAM","The selected XI and current team profile")
	var info=_row(content)
	_stat(info,"Avg rating",str(_avg_rating()))
	_stat(info,"Team chemistry",str(state.chemistry))
	_stat(info,"Morale",str(state.morale)+"%")
	for i in range(mini(11,_my_players().size())):
		_player_card(_my_players()[i],i)

func _avg_rating() -> int:
	var total=0
	for i in range(mini(11,_my_players().size())):
		total+=int(_my_players()[i].ovr)
	return int(round(float(total)/float(maxi(1,mini(11,_my_players().size())))))

func _player_directory() -> void:
	_heading("SQUAD DIRECTORY","Full squad, age, potential and market value")
	for i in range(_my_players().size()):
		_player_card(_my_players()[i],i)

func _training() -> void:
	_heading("DEVELOPMENT CENTRE","Your coaching facilities accelerate player growth")
	var p=_card(content)
	var v=_column(p,14)
	v.add_child(_label("TRAINING LEVEL %d / 10" % int(state.training),27,GOLD))
	v.add_child(_label("Players develop at the end of each season. Youth prospects improve faster at upgraded facilities.",20,MUTED))
	v.add_child(_button("TRAINING FOCUS: FITNESS",func():_train_now("fitness"),true))
	v.add_child(_button("TRAINING FOCUS: DEVELOPMENT",func():_train_now("development")))
	v.add_child(_button("TRAINING FOCUS: CHEMISTRY",func():_train_now("chemistry")))
	v.add_child(_label("Sessions cost €1M. Balance spending with wages and transfers.",19,MUTED))

func _train_now(focus:String) -> void:
	if int(state.funds)<1:
		notification="Not enough money to run a training camp."
	else:
		state.funds=int(state.funds)-1
		for p in _my_players():
			if focus=="fitness":p.fitness=mini(100,int(p.fitness)+rng.randi_range(5,15))
			if focus=="development" and int(p.ovr)<int(p.pot) and rng.randf()<0.18+float(state.training)*0.035:p.ovr=int(p.ovr)+1
			if focus=="chemistry":p.morale=mini(100,int(p.morale)+rng.randi_range(2,7))
		state.chemistry=mini(99,int(state.chemistry)+(4 if focus=="chemistry" else 1))
		notification="Training completed: %s." % focus.capitalize()
	_save()
	_redraw()

func _contracts() -> void:
	_heading("CONTRACTS","Renew deals before players become free agents")
	for i in range(_my_players().size()):
		var p=_my_players()[i]
		var box=_card(content)
		var h=_row(box,10)
		var txt=_column(h,3)
		txt.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		txt.add_child(_label(p.name,22,IVORY,true))
		txt.add_child(_label("%d years  •  €%dk / week" % [int(p.contract),int(p.wage)],18,MUTED))
		var index=i
		h.add_child(_button("RENEW €%dM" % maxi(1,int(p.value)/4),func():_renew_contract(index)))

func _renew_contract(idx:int) -> void:
	var p=_my_players()[idx]
	var fee=maxi(1,int(p.value)/4)
	if int(state.funds)<fee:
		notification="Insufficient funds to renew."
	else:
		state.funds=int(state.funds)-fee
		p.contract=int(p.contract)+3
		p.morale=mini(100,int(p.morale)+7)
		notification="Contract extended: "+str(p.name)
	_save()
	_redraw()

func _tactics() -> void:
	match sub_tab:
		0: _formation()
		1: _instructions()
		2: _set_pieces()

func _formation() -> void:
	_heading("TACTICAL BLUEPRINT","Build your identity. Control the pitch.")
	var chemistry=_row(content)
	_stat(chemistry,"Formation",str(state.formation))
	_stat(chemistry,"Chemistry",str(state.chemistry))
	var formations=_row(content,5)
	for f in ["4-3-3","4-2-3-1","4-4-2"]:
		var name=f
		var bt=_button(f,func():state.formation=name;state.chemistry=maxi(45,int(state.chemistry)-2);_save();_redraw(),state.formation==f)
		bt.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		formations.add_child(bt)
	_pitch_board()
	var approaches=_row(content,5)
	for m in ["Defensive","Balanced","Attacking"]:
		var val=m
		var bt=_button(m,func():state.mentality=val;_save();_redraw(),state.mentality==m)
		bt.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		approaches.add_child(bt)

func _pitch_board() -> void:
	var field=Panel.new()
	field.custom_minimum_size=Vector2(688,740)
	field.add_theme_stylebox_override("panel",_style(Color("#14613a"),Color("#9ccf87"),12))
	content.add_child(field)
	var turf=ColorRect.new()
	turf.color=Color("#226a3d")
	turf.position=Vector2(26,24)
	turf.size=Vector2(635,690)
	field.add_child(turf)
	for i in range(10):
		if i%2==0:
			var stripe=ColorRect.new()
			stripe.color=Color("#245d37")
			stripe.position=Vector2(26,24+i*69)
			stripe.size=Vector2(635,69)
			field.add_child(stripe)
	for y in [20,345,673]:
		var ln=ColorRect.new()
		ln.color=Color(1,1,1,0.5)
		ln.position=Vector2(28,y+24)
		ln.size=Vector2(633,3)
		field.add_child(ln)
	var pattern=[1,3,2,4,1]
	if state.formation=="4-3-3":pattern=[1,3,3,4,1]
	if state.formation=="4-4-2":pattern=[2,4,4,1]
	var ids=0
	for row_index in range(pattern.size()):
		var number=pattern[row_index]
		for col_index in range(number):
			if ids>=11:break
			var px=40.0+(float(col_index)+0.5)*(610.0/float(number))
			var py=75.0+float(row_index)*540.0/float(maxi(1,pattern.size()-1))
			var player=_my_players()[ids]
			var token=_button("%s\n%d" % [str(player.pos),int(player.ovr)],func():_inspect_player(ids))
			token.size=Vector2(95,69)
			token.position=Vector2(px-37,py-34)
			token.add_theme_font_size_override("font_size",20)
			token.add_theme_stylebox_override("normal",_style(Color("#03281b"),GOLD,9))
			field.add_child(token)
			ids+=1

func _instructions() -> void:
	_heading("TEAM INSTRUCTIONS","Decisions on matchday affect every result")
	_choice("MENTALITY",["Defensive","Balanced","Attacking"],"mentality")
	_choice("PRESSING INTENSITY",["Low","Medium","High"],"pressing")
	_choice("DEFENSIVE LINE",["Deep","Standard","High"],"line")
	_choice("PASSING DIRECTNESS",["Short","Mixed","Direct"],"passing")
	var info=_card(content)
	info.add_child(_label("High pressing and attacking football increase chance creation but also fatigue and defensive risk.",20,MUTED))

func _choice(title:String,values:Array,field:String) -> void:
	content.add_child(_label(title,21,GOLD,true))
	var row=_row(content,5)
	for v in values:
		var selected=str(v)
		var b=_button(selected,func():state[field]=selected;_save();_redraw(),str(state[field])==selected)
		b.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		row.add_child(b)

func _set_pieces() -> void:
	_heading("SET PIECES","Assign your specialists")
	var picks=["PENALTIES","FREE KICKS","CORNERS","CAPTAIN"]
	for i in range(picks.size()):
		var p=_card(content)
		var h=_row(p)
		h.add_child(_label(picks[i],22,GOLD,true))
		h.add_spacer(false)
		var player=_my_players()[[10,7,8,6][i]]
		h.add_child(_label(str(player.name),22))

func _market() -> void:
	match sub_tab:
		0: _scouting()
		1: _shortlist()
		2: _offers()

func _candidate_pool() -> Array:
	var pool=[]
	for club in world.squads.keys():
		if club==state.club:continue
		for p in world.squads[club]:
			var candidate=p.duplicate()
			candidate.club=club
			pool.append(candidate)
	pool.sort_custom(func(a,b):return int(a.pot)>int(b.pot))
	return pool

func _scouting() -> void:
	_heading("GLOBAL SCOUTING","Talent across two playable divisions")
	var info=_row(content)
	_stat(info,"Budget","€%dM" % int(state.funds))
	_stat(info,"Scout level",str(state.scouting))
	_stat(info,"Players",str(_candidate_pool().size()))
	var pool=_candidate_pool()
	var count=0
	for p in pool:
		if count>=24:break
		if p.name in shortlisted:continue
		_transfer_card(p)
		count+=1

func _transfer_card(p:Dictionary) -> void:
	var box=_card(content)
	var v=_column(box,10)
	var h=_row(v)
	var oval=_label(str(p.ovr),33,GOLD,true)
	oval.custom_minimum_size.x=62
	h.add_child(oval)
	var details=_column(h,3)
	details.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	details.add_child(_label(str(p.name),22,IVORY,true))
	details.add_child(_label("%s  •  AGE %d  •  POT %d  •  %s" % [p.pos,int(p.age),int(p.pot),str(p.club)],17,MUTED))
	var buttons=_row(v,8)
	var nm=str(p.name)
	buttons.add_child(_button("SHORTLIST",func():_shortlist_player(nm)))
	var fee=int(p.value)
	buttons.add_child(_button("OFFER €%dM" % fee,func():_offer_player(nm,fee),true))

func _shortlist_player(name:String) -> void:
	if not shortlisted.has(name):
		shortlisted.append(name)
	notification="Added %s to your shortlist." % name
	_save()
	_redraw()

func _shortlist() -> void:
	_heading("SCOUT SHORTLIST","Watch promising players before you buy")
	for p in _candidate_pool():
		if p.name in shortlisted:
			_transfer_card(p)

func _offer_player(name:String,fee:int) -> void:
	if int(state.funds)<fee:
		notification="Offer rejected: Insufficient transfer budget."
	else:
		var found={}
		var origin=""
		for club in world.squads.keys():
			if club==state.club:continue
			for p in world.squads[club]:
				if p.name==name:
					found=p
					origin=club
					break
			if not found.is_empty():break
		if found.is_empty():
			notification="This player has already moved."
		else:
			var probability=clampf(0.72+(float(fee)-float(found.value))*0.03+float(state.scouting)*0.01,0.15,0.98)
			if rng.randf()<=probability:
				world.squads[origin].erase(found)
				world.squads[state.club].append(found)
				state.funds=int(state.funds)-fee
				state.chemistry=maxi(50,int(state.chemistry)-3)
				offers.append("%s signed from %s for €%dM" % [name,origin,fee])
				state.inbox.push_front("Transfer completed: "+name)
				notification="TRANSFER CONFIRMED: "+name
			else:
				offers.append("%s: Offer rejected by %s" % [name,origin])
				notification="Offer rejected. Try another target."
	_save()
	_redraw()

func _offers() -> void:
	_heading("NEGOTIATION HISTORY","Completed deals and unsuccessful approaches")
	for o in offers:
		var p=_card(content)
		p.add_child(_label(str(o),21))

func _club() -> void:
	match sub_tab:
		0: _club_overview()
		1: _stadium()
		2: _facilities()
		3: _finances()

func _club_overview() -> void:
	_heading("THE CLUB","Build something bigger than football")
	var banner=_card(content)
	var v=_column(banner,10)
	v.add_child(_label(str(state.club).to_upper(),33,GOLD,true))
	v.add_child(_label("NATIONAL CHAMPIONSHIP  •  EST. 1908",18,MUTED))
	v.add_child(_label("STADIUM  |  THE FORTRESS",25,IVORY,true))
	v.add_child(_label("%s capacity   •   %d%% attendance" % [str(state.stadium),int(state.attendance)],21,MUTED))
	var stats=_row(content)
	_stat(stats,"Board confidence",str(state.board)+"%")
	_stat(stats,"Club funds","€%dM" % int(state.funds))
	var further=_row(content)
	_stat(further,"Training","Lv %d" % int(state.training))
	_stat(further,"Youth academy","Lv %d" % int(state.academy))
	_stat(further,"Scouting","Lv %d" % int(state.scouting))
	var controls=_row(content)
	for item in [["STADIUM",1],["FACILITIES",2],["FINANCES",3]]:
		var chosen=int(item[1])
		var btn=_button(str(item[0]),func():sub_tab=chosen;_redraw())
		btn.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		controls.add_child(btn)

func _stadium() -> void:
	_heading("STADIUM EXPANSION","More seats, more fans, more matchday revenue")
	var p=_card(content)
	var v=_column(p,13)
	v.add_child(_label("THE FORTRESS",36,GOLD,true))
	v.add_child(_label("%d SEATS" % int(state.stadium),32,IVORY,true))
	v.add_child(_label("Average attendance  %d%%" % int(state.attendance),22,MUTED))
	v.add_child(_label("Expansion: +5,000 seats  •  Cost €12M",22,GOLD))
	v.add_child(_button("APPROVE STADIUM EXPANSION",func():_upgrade("stadium",12),true))
	v.add_child(_label("A bigger stadium increases home match income.",19,MUTED))

func _facilities() -> void:
	_heading("CLUB INFRASTRUCTURE","Invest in the foundations of a dynasty")
	for facility in ["training","academy","scouting"]:
		var p=_card(content)
		var v=_column(p,9)
		v.add_child(_label(facility.capitalize()+" Facilities",29,IVORY,true))
		v.add_child(_label("LEVEL %d / 10" % int(state[facility]),22,GOLD))
		v.add_child(_label("Cost €%dM" % [5+int(state[facility])*3],20,MUTED))
		var key=facility
		v.add_child(_button("UPGRADE "+facility.to_upper(),func():_upgrade(key,5+int(state[key])*3),true))

func _finances() -> void:
	_heading("FINANCIAL REPORT","Every signing and stadium decision matters")
	_stat(content,"Available funds","€%dM" % int(state.funds))
	_stat(content,"Weekly wage bill","€%dk" % _wage_bill())
	_stat(content,"Matchday income","€%.1fM" % (float(state.stadium)*float(state.attendance)/100.0/25000.0))
	_stat(content,"Club reputation","%d / 100" % int(state.board))

func _wage_bill() -> int:
	var total=0
	for p in _my_players():
		total+=int(p.wage)
	return total

func _upgrade(facility:String,cost:int) -> void:
	if int(state.funds)<cost:
		notification="Insufficient funds. Required €%dM." % cost
	elif facility!="stadium" and int(state[facility])>=10:
		notification="Facility is already at the highest level."
	else:
		state.funds=int(state.funds)-cost
		if facility=="stadium":
			state.stadium=int(state.stadium)+5000
		else:
			state[facility]=int(state[facility])+1
		state.board=mini(99,int(state.board)+2)
		notification="Investment completed: "+facility.capitalize()
	_save()
	_redraw()

func _begin_match() -> void:
	var fx=_next_fixture()
	if fx.is_empty():
		_finish_season()
		return
	active_match={"home":fx.home,"away":fx.away,"minute":0,"home_score":0,"away_score":0,"events":["0' Kick-off at the stadium"],"finished":false}
	timer.start()
	_save()
	_redraw()

func _live_match() -> void:
	_heading("MATCHDAY LIVE","TACTICAL SIMULATION  •  %s" % str(state.mentality).to_upper())
	var p=_card(content)
	var v=_column(p,18)
	v.add_child(_label("MATCH MINUTE  %02d'" % int(active_match.minute),25,GOLD,true))
	v.add_child(_label("%s  %d : %d  %s" % [active_match.home,int(active_match.home_score),int(active_match.away_score),active_match.away],30,IVORY,true))
	v.add_child(_label("Control the touchline. A live event arrives every few seconds.",19,MUTED))
	if active_match.finished:
		v.add_child(_button("FULL TIME  •  CONTINUE",func():_close_match(),true))
	else:
		var actions=_row(v)
		actions.add_child(_button("DEFEND",func():state.mentality="Defensive";_save()))
		actions.add_child(_button("BALANCED",func():state.mentality="Balanced";_save()))
		actions.add_child(_button("ATTACK",func():state.mentality="Attacking";_save(),true))
	for event in active_match.events:
		var line=_card(content)
		line.add_child(_label(str(event),21,IVORY))

func _team_strength(club:String) -> float:
	var players:Array=world.squads.get(club,[])
	if players.is_empty():return 60.0
	var sum=0.0
	for i in range(mini(11,players.size())):
		sum+=float(players[i].ovr)*float(players[i].fitness)/100.0
	var strength=sum/float(mini(11,players.size()))
	if club==state.club:
		strength+=float(state.chemistry-75)*0.05
		if state.mentality=="Attacking":strength+=1.4
		if state.mentality=="Defensive":strength-=0.8
	return strength

func _tick_match() -> void:
	if active_match.is_empty() or active_match.finished:
		timer.stop()
		return
	active_match.minute=mini(90,int(active_match.minute)+5)
	var home=active_match.home
	var away=active_match.away
	var h=_team_strength(home)
	var a=_team_strength(away)
	var attack_mod=1.0
	if state.mentality=="Attacking":attack_mod=1.22
	if state.mentality=="Defensive":attack_mod=0.82
	var my_home=home==state.club
	var hh=attack_mod if my_home else 1.0/attack_mod
	var aa=attack_mod if not my_home else 1.0/attack_mod
	var home_chance=clampf((0.085+(h-a)*0.003)*hh,0.015,0.23)
	var away_chance=clampf((0.075+(a-h)*0.003)*aa,0.015,0.23)
	var event=""
	if rng.randf()<home_chance:
		active_match.home_score=int(active_match.home_score)+1
		event="%d'  ⚽ GOAL! %s" % [int(active_match.minute),home]
	elif rng.randf()<away_chance:
		active_match.away_score=int(active_match.away_score)+1
		event="%d'  ⚽ GOAL! %s" % [int(active_match.minute),away]
	else:
		var lines=["The midfield battle continues.","A dangerous counter attack breaks down.","The goalkeeper makes a routine save.","A quick passing move opens space.","The crowd roars as possession changes.","A defender makes a crucial tackle."]
		event="%d'  %s" % [int(active_match.minute),lines[rng.randi_range(0,lines.size()-1)]]
	active_match.events.push_front(event)
	if int(active_match.minute)>=90:
		active_match.finished=true
		active_match.events.push_front("90'  FULL TIME")
		timer.stop()
	_save()
	_redraw()

func _close_match() -> void:
	var week=int(state.week)
	for f in fixtures:
		if int(f.week)!=week:continue
		var hs=0
		var ascore=0
		if f.home==active_match.home and f.away==active_match.away:
			hs=int(active_match.home_score)
			ascore=int(active_match.away_score)
		else:
			var strength_home=_team_strength(f.home)
			var strength_away=_team_strength(f.away)
			hs=maxi(0,int(round(rng.randfn(1.35+(strength_home-strength_away)*0.05,1.1))))
			ascore=maxi(0,int(round(rng.randfn(1.15+(strength_away-strength_home)*0.05,1.1))))
		_apply_result(f.home,f.away,hs,ascore)
		if f.home==state.club or f.away==state.club:
			var scored=hs if f.home==state.club else ascore
			var conceded=ascore if f.home==state.club else hs
			state.results.append("%s %d - %d %s" % [f.home,hs,ascore,f.away])
			state.played=int(state.played)+1
			state.goals=int(state.goals)+scored
			state.against=int(state.against)+conceded
			if scored>conceded:
				state.wins=int(state.wins)+1
				state.morale=mini(100,int(state.morale)+4)
				state.board=mini(100,int(state.board)+2)
			elif scored<conceded:
				state.morale=maxi(30,int(state.morale)-4)
				state.board=maxi(10,int(state.board)-2)
			var income=maxi(1,int(float(state.stadium)*float(state.attendance)/100.0/12000.0))
			state.funds=int(state.funds)+income
	for p in _my_players():
		p.fitness=maxi(55,int(p.fitness)-rng.randi_range(3,10))
	state.week=week+1
	active_match={}
	if int(state.week)>=22:
		_finish_season()
	else:
		state.inbox.push_front("Matchday %d completed. Review league standings." % (week+1))
	_save()
	_redraw()

func _apply_result(home:String,away:String,hs:int,ascore:int) -> void:
	var a=world.tables[home]
	var b=world.tables[away]
	a.p=int(a.p)+1
	b.p=int(b.p)+1
	a.gf=int(a.gf)+hs
	a.ga=int(a.ga)+ascore
	b.gf=int(b.gf)+ascore
	b.ga=int(b.ga)+hs
	if hs>ascore:
		a.w=int(a.w)+1
		a.pts=int(a.pts)+3
		b.l=int(b.l)+1
	elif hs<ascore:
		b.w=int(b.w)+1
		b.pts=int(b.pts)+3
		a.l=int(a.l)+1
	else:
		a.d=int(a.d)+1
		b.d=int(b.d)+1
		a.pts=int(a.pts)+1
		b.pts=int(b.pts)+1

func _finish_season() -> void:
	var ranked=_sorted_table()
	var position=1
	for i in range(ranked.size()):
		if ranked[i].name==state.club:position=i+1
	var prize=maxi(2,26-position*2)
	state.funds=int(state.funds)+prize
	state.board=clampi(int(state.board)+(7 if position<=4 else -7),12,100)
	state.inbox.push_front("Season complete! Finished #%d. Prize money €%dM." % [position,prize])
	if position<=2 and int(state.division)==1:
		state.division=0
		state.inbox.push_front("PROMOTION! The club is heading to the Crown Premier.")
		_swap_division(state.club,0)
		state.trophies=int(state.trophies)+1
	elif position>=11 and int(state.division)==0:
		state.division=1
		state.inbox.push_front("Relegation. The board expects an immediate response.")
		_swap_division(state.club,1)
	for p in _my_players():
		p.age=int(p.age)+1
		p.contract=maxi(0,int(p.contract)-1)
		if int(p.age)<28 and int(p.ovr)<int(p.pot) and rng.randf()<0.28+float(state.training)*0.045:
			p.ovr=int(p.ovr)+1
		elif int(p.age)>32 and rng.randf()<0.25:
			p.ovr=maxi(40,int(p.ovr)-1)
		p.fitness=100
	state.year=int(state.year)+1
	state.week=0
	state.morale=75
	state.chemistry=mini(95,int(state.chemistry)+3)
	_reset_standings()
	_build_fixtures()
	notification="SEASON ENDED: Finished #%d. €%dM awarded." % [position,prize]
	_save()
	_redraw()

func _swap_division(name:String,to:int) -> void:
	var from=1-to
	var old=DIVISIONS[from]
	var new=DIVISIONS[to]
	var idx=old.find(name)
	if idx==-1:return
	var replacement=new[new.size()-1]
	old[idx]=replacement
	new[new.size()-1]=name
	# DIVISIONS is a const array; its contained arrays can be changed at runtime.
