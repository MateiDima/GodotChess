extends Node

@export var pion_alb_scene : PackedScene
@export var pion_negru_scene : PackedScene
@export var cadran_negru_scene : PackedScene
@export var cadran_alb_scene : PackedScene
@export var tura_neagra_scene: PackedScene
@export var cal_negru_scene: PackedScene
@export var nebun_negru_scene: PackedScene
@export var regina_neagra_scene: PackedScene
@export var rege_negru_scene: PackedScene
@export var tura_alba_scene: PackedScene
@export var cal_alb_scene: PackedScene
@export var nebun_alb_scene: PackedScene
@export var regina_alba_scene: PackedScene
@export var rege_alb_scene: PackedScene

var player : int
var pasi : int
var piesa : int
var board_size : int
var cell_size : int
var grid_pos : Vector2i 
var grid_data : Array # matrice 8 pe 8
var start_pos : Vector2i # retine primul click dat / piesa pe care se doreste a muta
var start_piesa : int
var temp_marker
var enemy : Vector2i # ajuta la retinerea valorilor pieselor inamice
var ally : Vector2i
var piesa_mutare : int
var transformare_pion = false

var piese_albe = [] 
var piese_negre = []

var pos_rege_alb :  Vector2i
var pos_rege_negru : Vector2i
var pos_rege_actual : Vector2i

#cand simulez o mutare pentru a verifica daca pune regele in sah
#in grid_data la pozitia de start pun ca si gol
#pozitia unde se doreste deplasarea preia valoarea piesei de mutat
#la pozitia unde se deoreste deplasarea se poate afla o piesa inamica, aceea trebuie salvata 
#de aici vine "piesa_capturata"
var piesa_capturata : int

var numar_mutari_incercate : int
var player_care_a_incercat_o_miscare_precedent : int

# Called when the node enters the scene tree for the first time.
func _ready():
	board_size = 788 + 4
	# imparte board_size la 8 pentru a obtine dimensiunea fiecarei celule
	cell_size = board_size / 8
	new_game()
	piesa_mutare = 100 # valoare aberanta
	
	
	
#modul in care am gandit sfarsitul jocului
#imi e imposibil sa stiu cand se da un sah mat
# prin cod, regele nu se poate muta intr=o pozitie care il pune in sah
# o piesa nu se poate deplasa daca isi lasa descoperit in sah regele aliat

# daca regele se afla in sah, player-ul este obligat sa mute o piesa astfel incat sa iasa din sah altfel nu poate executa mutarea
#MODUL DE SFARSIRE JOC (pentru piese albe, e mai usor de explicat)
#jucatorul alb are la dispozitei 4 incercari de a deplasa o piesa, daca nu reuseste, se considera sah mat 

# _input(event) este functia principala unde se intampla magia
func _input(event): 
	if numar_mutari_incercate == 5:
		get_tree().paused=true
		$MeniuGameOver.show()
		if player == 1:
			$MeniuGameOver/LabelCastigator.text="Piesele negre au câștigat!"
		else: $MeniuGameOver/LabelCastigator.text="Piesele albe au câștigat!"
	if event is InputEventMouseButton :
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed :
			#verifica daca mouse-ul e pe tabla de joc
			if event.position.x < board_size:
				#convertire pozitie mouse in locatie grid
				grid_pos = Vector2i(event.position / cell_size) # grid_pos memoreza [coloana, linie]
				transformare_pion = false
				
				var auxiliar : Vector2i
				if player == 1:
					pos_rege_actual = pos_rege_alb
				else: 
					pos_rege_actual = pos_rege_negru
					
					
				if player_care_a_incercat_o_miscare_precedent == player and pasi ==2:
					print("SAU EXECUTAT ", numar_mutari_incercate, " INCERCARI" )
					if numar_mutari_incercate == 5 and se_afla_in_sah(pos_rege_actual) == true:
						print("")
						print("GAME OVER< PLAYERUL: ",player," A PIERDUT!!!!!!!!!!!!!!!!!!!!")
					numar_mutari_incercate +=1
				elif player_care_a_incercat_o_miscare_precedent != player: 
					player_care_a_incercat_o_miscare_precedent = player
					numar_mutari_incercate = 1 
				
				#miscari pentru pion alb
				if grid_data[grid_pos.y][grid_pos.x][0] == 6 and pasi == 1  and player == 1:
					selectare_piesa()
					piesa_mutare =  grid_data[grid_pos.y][grid_pos.x][0]
				#deplasare pion alb
				elif grid_pos != start_pos and grid_data[grid_pos.y][grid_pos.x][0] <= 0  and piesa_mutare == 6 and pasi ==2:
					# in grid_data sterg pozitia initiala a pionului, si o marchez pe cea finala 
					grid_data[start_pos.y][start_pos.x][0] = 0
					piesa_capturata = grid_data[grid_pos.y][grid_pos.x][0]
					grid_data[grid_pos.y][grid_pos.x][0] = piesa_mutare
					#verific daca teoretica mutare pune in pericol regele 
					print("pozitia regelui alb este " , pos_rege_alb)
					if se_afla_in_sah(pos_rege_alb) == true: # se anuleaza mutarea
						print("mutarea pionului pune in pericol regele alb ")
						# restitui grid_data asa cum a fost
						grid_data[start_pos.y][start_pos.x][0] = piesa_mutare
						grid_data[grid_pos.y][grid_pos.x][0] = piesa_capturata
					else:
						#restitui grid_data asa cum a fost
						grid_data[start_pos.y][start_pos.x][0] = piesa_mutare
						grid_data[grid_pos.y][grid_pos.x][0] = piesa_capturata
						#execut mutarea
						deplasare_pion_alb()
						
				#miscari pt pion negru
				if grid_data[grid_pos.y][grid_pos.x][0] == -6 and pasi == 1 and player == -1 :
					selectare_piesa()
					piesa_mutare =  grid_data[grid_pos.y][grid_pos.x][0]
				#deplasare pion negru
				elif grid_pos != start_pos and grid_data[grid_pos.y][grid_pos.x][0] >= 0 and piesa_mutare == -6 and pasi == 2:
					# in grid_data sterg pozitia initiala a pionului, si o marchez pe cea finala 
					grid_data[start_pos.y][start_pos.x][0] = 0
					piesa_capturata = grid_data[grid_pos.y][grid_pos.x][0] # retin ce se afla pe pozitia unde se doreste mutarea
					grid_data[grid_pos.y][grid_pos.x][0] = piesa_mutare
					#verific daca teoretica mutare pune in pericol regele 
					print("pozitia regelui negru este " , pos_rege_negru)
					if se_afla_in_sah(pos_rege_negru) == true: # se anuleaza mutarea
						print("mutarea pionului pune in pericol regele negru ")
						# restitui grid_data asa cum a fost
						grid_data[start_pos.y][start_pos.x][0] = piesa_mutare
						grid_data[grid_pos.y][grid_pos.x][0] = piesa_capturata
					else:
						#restitui grid_data asa cum a fost
						grid_data[start_pos.y][start_pos.x][0] = piesa_mutare
						grid_data[grid_pos.y][grid_pos.x][0] = piesa_capturata
						#execut mutarea
						deplasare_pion_negru()
					
						
						
				
				
				for i in range (1,6):
						if grid_data[grid_pos.y][grid_pos.x][0] == i*player and pasi == 1 :
							selectare_piesa()
							piesa_mutare =  grid_data[grid_pos.y][grid_pos.x][0]
							break
						elif grid_pos != start_pos and grid_data[grid_pos.y][grid_pos.x][0] >= enemy.x and grid_data[grid_pos.y][grid_pos.x][0] <= enemy.y   and piesa_mutare == i*player or\
							 grid_pos != start_pos and grid_data[grid_pos.y][grid_pos.x][0] == 0 and piesa_mutare == i*player: 
							if  pasi == 2:

								if piesa_mutare == 2 or piesa_mutare == -2:
									# in grid_data sterg pozitia initiala a pionului, si o marchez pe cea finala 
									grid_data[start_pos.y][start_pos.x][0] = 0
									piesa_capturata = grid_data[grid_pos.y][grid_pos.x][0] # retin ce se afla pe pozitia unde se doreste mutarea
									grid_data[grid_pos.y][grid_pos.x][0] = piesa_mutare
									#verific daca teoretica mutare pune in pericol regele 
									
									if se_afla_in_sah(grid_pos) == true: # regele nu se poate muta intr-o pozitie daca se pune in sah 
										print("Mutarea pune in pericol regele ")
										# restitui grid_data asa cum a fost
										grid_data[start_pos.y][start_pos.x][0] = piesa_mutare
										grid_data[grid_pos.y][grid_pos.x][0] = piesa_capturata
									else:
										#restitui grid_data asa cum a fost
										grid_data[start_pos.y][start_pos.x][0] = piesa_mutare
										grid_data[grid_pos.y][grid_pos.x][0] = piesa_capturata
										#execut mutarea
										
										var verificare = deplasare_rege()
										if verificare == true:
											if player == -1:
												pos_rege_alb = grid_pos
												print("regele alb se deplaseaza la pozitia", grid_pos)
											elif player == 1:
												pos_rege_negru = grid_pos
												print("regele negru se deplaseaza la pozitia", grid_pos)
								
								else:
								
									# in grid_data sterg pozitia initiala a pionului, si o marchez pe cea finala 
									grid_data[start_pos.y][start_pos.x][0] = 0
									piesa_capturata = grid_data[grid_pos.y][grid_pos.x][0] # retin ce se afla pe pozitia unde se doreste mutarea
									grid_data[grid_pos.y][grid_pos.x][0] = piesa_mutare
									#verific daca teoretica mutare pune in pericol regele 
								
									print("pozitia regelui este " , pos_rege_actual)
									
									if se_afla_in_sah(pos_rege_actual) == true: # se anuleaza mutarea
										print("mutarea pune in pericol regele jucatorului ",player )
										# restitui grid_data asa cum a fost
										grid_data[start_pos.y][start_pos.x][0] = piesa_mutare
										grid_data[grid_pos.y][grid_pos.x][0] = piesa_capturata
									else:
										#restitui grid_data asa cum a fost
										grid_data[start_pos.y][start_pos.x][0] = piesa_mutare
										grid_data[grid_pos.y][grid_pos.x][0] = piesa_capturata
										#execut mutarea
										if piesa_mutare == 1 or piesa_mutare == -1:
											deplasare_regina()
										elif piesa_mutare == 3 or piesa_mutare == -3:
											luare_piesa_diagonala()
										elif piesa_mutare == 4 or piesa_mutare == -4:
											deplasare_cal()
										elif piesa_mutare == 5 or piesa_mutare == -5:
											luare_piesa_linie_coloana()
								
								
				
				
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed :
			piesa_mutare = 99
			pasi = 1
			print("ATENTIE CLICK DREAPTA DE LA MOUSE ANULEAZA PIESA SELECTATA")
					
		
func new_game():
	
	enemy = Vector2i(-6,-1)
	ally = Vector2i(1,6)
	
	pos_rege_alb =  Vector2i(0,3)
	pos_rege_negru = Vector2i(7,3)
	
	$MeniuGameOver.hide()
	get_tree().paused=false
	
	player = 1
	player_care_a_incercat_o_miscare_precedent = 1
	numar_mutari_incercate = 1
	
	#trebuie sterse toate piesele de la jocul anterior
	var i = 0
	while piese_albe.size() > 0 :
		piese_albe[i].queue_free()
		piese_albe.remove_at(i)
		
	while piese_negre.size() > 0 :
		piese_negre[i].queue_free()
		piese_negre.remove_at(i)
		
	piese_albe.clear() 
	piese_negre.clear()
	
	# [5,1] a doua valoare marcheaza culoarea chenarului tablei de joc, 7 = negru, 8 = alb
	grid_data = [
		[[5,7], [6,8], [0,7], [0,8], [0,7], [0,8], [-6,7], [-5,8]],
		[[4,8], [6,7], [0,8], [0,7], [0,8], [0,7], [-6,8], [-4,7]], 
		[[3,7], [6,8], [0,7], [0,8], [0,7], [0,8], [-6,7], [-3,8]],
		[[2,8], [6,7], [0,8], [0,7], [0,8], [0,7], [-6,8], [-2,7]],
		[[1,7], [6,8], [0,7], [0,8], [0,7], [0,8], [-6,7], [-1,8]],
		[[3,8], [6,7], [0,8], [0,7], [0,8], [0,7], [-6,8], [-3,7]],
		[[4,7], [6,8], [0,7], [0,8], [0,7], [0,8], [-6,7], [-4,8]],
		[[5,8], [6,7], [0,8], [0,7], [0,8], [0,7], [-6,8], [-5,7]]
		]
	
	
	pasi = 1
	# punerea pionilor albi pe tabla
	create_marker(6, Vector2i(1,0) * cell_size + Vector2i(cell_size /2, cell_size /2 ))
	create_marker(6, Vector2i(1,1) * cell_size + Vector2i(cell_size /2, cell_size /2 ))
	create_marker(6, Vector2i(1,2) * cell_size + Vector2i(cell_size /2, cell_size /2 ))
	create_marker(6, Vector2i(1,3) * cell_size + Vector2i(cell_size /2, cell_size /2 ))
	create_marker(6, Vector2i(1,4) * cell_size + Vector2i(cell_size /2, cell_size /2 ))
	create_marker(6, Vector2i(1,5) * cell_size + Vector2i(cell_size /2, cell_size /2 ))
	create_marker(6, Vector2i(1,6) * cell_size + Vector2i(cell_size /2, cell_size /2 ))
	create_marker(6, Vector2i(1,7) * cell_size + Vector2i(cell_size /2, cell_size /2 ))
	
	#punerea pionilor negri pe tabla
	create_marker(-6, Vector2i(6,0) * cell_size + Vector2i(cell_size /2, cell_size /2 ))
	create_marker(-6, Vector2i(6,1) * cell_size + Vector2i(cell_size /2, cell_size /2 ))
	create_marker(-6, Vector2i(6,2) * cell_size + Vector2i(cell_size /2, cell_size /2 ))
	create_marker(-6, Vector2i(6,3) * cell_size + Vector2i(cell_size /2, cell_size /2 ))
	create_marker(-6, Vector2i(6,4) * cell_size + Vector2i(cell_size /2, cell_size /2 ))
	create_marker(-6, Vector2i(6,5) * cell_size + Vector2i(cell_size /2, cell_size /2 ))
	create_marker(-6, Vector2i(6,6) * cell_size + Vector2i(cell_size /2, cell_size /2 ))
	create_marker(-6, Vector2i(6,7) * cell_size + Vector2i(cell_size /2, cell_size /2 ))
	
	#punerea turelor negre
	create_marker(-5, Vector2i(7,0) * cell_size + Vector2i(cell_size /2, cell_size /2))
	create_marker(-5, Vector2i(7,7) * cell_size + Vector2i(cell_size /2, cell_size /2))
	
	#punerea cailor negri
	create_marker(-4, Vector2i(7,1) * cell_size + Vector2i(cell_size /2, cell_size /2))
	create_marker(-4, Vector2i(7,6) * cell_size + Vector2i(cell_size /2, cell_size /2))
	
	#punerea nebunilor negri
	create_marker(-3, Vector2i(7,2) * cell_size + Vector2i(cell_size /2, cell_size /2))
	create_marker(-3, Vector2i(7,5) * cell_size + Vector2i(cell_size /2, cell_size /2))
	
	#punerea reginei si a regelui negru
	create_marker(-1, Vector2i(7,4) * cell_size + Vector2i(cell_size /2, cell_size /2))
	create_marker(-2, Vector2i(7,3) * cell_size + Vector2i(cell_size /2, cell_size /2))
	
	#punerea turelor albe
	create_marker(5, Vector2i(0,0) * cell_size + Vector2i(cell_size /2, cell_size /2))
	create_marker(5, Vector2i(0,7) * cell_size + Vector2i(cell_size /2, cell_size /2))
	
	#punerea cailor albi
	create_marker(4, Vector2i(0,1) * cell_size + Vector2i(cell_size /2, cell_size /2))
	create_marker(4, Vector2i(0,6) * cell_size + Vector2i(cell_size /2, cell_size /2))
	
	#punerea nebunilor albi
	create_marker(3, Vector2i(0,2) * cell_size + Vector2i(cell_size /2, cell_size /2))
	create_marker(3, Vector2i(0,5) * cell_size + Vector2i(cell_size /2, cell_size /2))
	
	#punerea reginei si a regelui alb 
	create_marker(1, Vector2i(0,4) * cell_size + Vector2i(cell_size /2, cell_size /2))
	create_marker(2, Vector2i(0,3) * cell_size + Vector2i(cell_size /2, cell_size /2))

#create_marker realizeaza creerea unui nod child al piesei specificate la pozitia specificata si il salveaza intr_o lista
# piese_albe sau piese_negre in functie de culoarea acesteia
func create_marker(piesa, position) :
	#creaza un marcker node si il adauga ca un child
	if piesa==-1:
		var regina_neagra = regina_neagra_scene.instantiate()
		regina_neagra.position=position
		add_child(regina_neagra)
		piese_negre.append(regina_neagra)
	if piesa==-2:
		var rege_negru = rege_negru_scene.instantiate()
		rege_negru.position=position
		add_child(rege_negru)
		piese_negre.append(rege_negru)
	if piesa==-3:
		var nebun_negru = nebun_negru_scene.instantiate()
		nebun_negru.position=position
		add_child(nebun_negru)
		piese_negre.append(nebun_negru)
	if piesa ==-4:
		var cal_negru = cal_negru_scene.instantiate()
		cal_negru.position=position
		add_child(cal_negru)
		piese_negre.append(cal_negru)
	if piesa == -5:
		var tura_neagra = tura_neagra_scene.instantiate()
		tura_neagra.position = position
		add_child(tura_neagra)
		piese_negre.append(tura_neagra)
	if piesa == -6 :
		var pion_negru = pion_negru_scene.instantiate()
		pion_negru.position = position 
		add_child(pion_negru)
		piese_negre.append(pion_negru)
	if piesa==1:
		var regina_alba=regina_alba_scene.instantiate()
		regina_alba.position=position
		add_child(regina_alba)
		piese_albe.append(regina_alba)
	if piesa==2:
		var rege_alb=rege_alb_scene.instantiate()
		rege_alb.position=position
		add_child(rege_alb)
		piese_albe.append(rege_alb)
	if piesa==3:
		var nebun_alb=nebun_alb_scene.instantiate()
		nebun_alb.position=position
		add_child(nebun_alb)
		piese_albe.append(nebun_alb)
	if piesa==4:
		var cal_alb=cal_alb_scene.instantiate()
		cal_alb.position=position
		add_child(cal_alb)
		piese_albe.append(cal_alb)
	if piesa == 5:
		var tura_alba = tura_alba_scene.instantiate()
		tura_alba.position=position
		add_child(tura_alba)
		piese_albe.append(tura_alba)
	if piesa == 6 :
		var pion_alb = pion_alb_scene.instantiate()
		pion_alb.position = position 
		add_child(pion_alb)
		piese_albe.append(pion_alb)
	if piesa == 7 :
		var cadran_negru = cadran_negru_scene.instantiate()
		cadran_negru.position = position
		add_child((cadran_negru)) 
	if piesa == 8 :
		var cadran_alb = cadran_alb_scene.instantiate()
		cadran_alb.position = position
		add_child((cadran_alb)) 

func selectare_piesa():
	start_piesa = grid_data[grid_pos.y][grid_pos.x][0]
	start_pos = grid_pos
	print(" ")
	print("player", player, "a apasat pe chenarul ", grid_pos )
	print("a fost selectata piesa ", start_piesa)
	pasi = 2

func deplasare_piesa():
	
			var index
			var index2 = 100
			piesa_capturata = 0
			if player == 1:
				#aflu care este piesa alba din memorie
				for i in range(piese_albe.size()):
					if Vector2i(piese_albe[i].position.x, piese_albe[i].position.y ) == start_pos * cell_size + Vector2i(cell_size /2, cell_size /2 ):
						print("este vorba de pionul", i)
						index = i
						break
				#caut daca pe pozitia finala exista o piesa neagra 
				for i in range(piese_negre.size()):
					if Vector2i(piese_negre[i].position.x, piese_negre[i].position.y ) == grid_pos * cell_size + Vector2i(cell_size /2, cell_size /2 ):
						index2 = i
						break
				#stergere din matrice pozitia veche a piesei albe
				grid_data[start_pos.y][start_pos.x][0] = 0
				
				if index2 != 100: # a fost gasita o piesa neagra, aceasta trebuei stearsa
					piese_negre[index2].queue_free()
					piese_negre.remove_at(index2)
					piesa_capturata = grid_data[grid_pos.y][grid_pos.x][0]
					
				#marcare noua pozitie a piesei albe in memoria matricei
				grid_data[grid_pos.y][grid_pos.x][0] = start_piesa
				
				#demarcare vechea pozitie a piesei prin deplasarea acesteia
				piese_albe[index].position = grid_pos * cell_size + Vector2i(cell_size /2, cell_size /2 )
					
				
			elif player == -1:
				for i in range(piese_negre.size()):
					if Vector2i(piese_negre[i].position.x, piese_negre[i].position.y ) == start_pos * cell_size + Vector2i(cell_size /2, cell_size /2 ):
						print("este vorba de pionul", i)
						index = i
						break
				
				#caut daca pe pozitia finala exista o piesa alba 
				for i in range(piese_albe.size()):
					if Vector2i(piese_albe[i].position.x, piese_albe[i].position.y ) == grid_pos * cell_size + Vector2i(cell_size /2, cell_size /2 ):
						index2 = i
						break
				#stergere din matrice pozitia veche a piesei negre
				grid_data[start_pos.y][start_pos.x][0] = 0
				
				if index2 != 100: # a fost gasita o piesa alba, aceasta trebuei stearsa
					piese_albe[index2].queue_free()
					piese_albe.remove_at(index2)
					piesa_capturata = grid_data[grid_pos.y][grid_pos.x][0]
					
				#marcare noua pozitie a piesei negre in memoria matricei
				grid_data[grid_pos.y][grid_pos.x][0] = start_piesa
				
				#demarcare vechea pozitie a piesei prin deplasarea acesteia
				piese_negre[index].position = grid_pos * cell_size + Vector2i(cell_size /2, cell_size /2 )
			
			
			print(grid_pos)
			print(grid_data)
			pasi = 1
			player *= -1
			set_ally_and_enemy()

func set_ally_and_enemy():
	if player == 1:
		enemy = Vector2i(-6,-1)
		ally = Vector2i(1,6)
	else :
		enemy = Vector2i(1,6)
		ally = Vector2i(-6,-1)

#functiile deplasare_inainte_pion_alb() si deplasare_diagonala_pion_alb() sunt unite in functia deplasare_pion_alb()
func deplasare_inainte_pion_alb():
	if grid_pos.x == start_pos.x + 1 and  grid_pos.y == start_pos.y  :
		if pasi == 2:
			deplasare_piesa()
			if grid_pos.x == 7:
				#trebuie sters pionul de pe tabla
				var index = 100
				for i in range(piese_albe.size()):
					if Vector2i(piese_albe[i].position.x, piese_albe[i].position.y ) == grid_pos * cell_size + Vector2i(cell_size /2, cell_size /2 ):
						index = i
						break
				if index != 100: # a fost gasita o piesa alba, aceasta trebuei stearsa
					piese_albe[index].queue_free()
					piese_albe.remove_at(index)
			
				create_marker(1, grid_pos * cell_size + Vector2i(cell_size /2, cell_size /2) )
				grid_data[grid_pos.y][grid_pos.x][0] = 1
				transformare_pion = true
	elif grid_pos.x == start_pos.x + 2 and  grid_pos.y == start_pos.y and start_pos.x == 1 and grid_data[start_pos.y][start_pos.x + 1][0] == 0   :
		if pasi == 2 :
			deplasare_piesa()
func capturare_diagonala_pion_alb():
	if grid_pos.x == start_pos.x + 1  and  grid_pos.y  == start_pos.y + 1 or  grid_pos.x == start_pos.x + 1  and  grid_pos.y  == start_pos.y - 1 :
		if pasi == 2:
			deplasare_piesa()
			if grid_pos.x == 7:
				#trebuie sters pionul de pe tabla
				var index = 100
				for i in range(piese_albe.size()):
					if Vector2i(piese_albe[i].position.x, piese_albe[i].position.y ) == grid_pos * cell_size + Vector2i(cell_size /2, cell_size /2 ):
						index = i
						break
				if index != 100: # a fost gasita o piesa alba, aceasta trebuei stearsa
					piese_albe[index].queue_free()
					piese_albe.remove_at(index)
			
				create_marker(1, grid_pos * cell_size + Vector2i(cell_size /2, cell_size /2) )
				grid_data[grid_pos.y][grid_pos.x][0] = 1
				transformare_pion = true
func deplasare_pion_alb():
	if grid_pos != start_pos and grid_data[grid_pos.y][grid_pos.x][0] == 0:
		deplasare_inainte_pion_alb()
	elif grid_pos != start_pos and grid_data[grid_pos.y][grid_pos.x][0] <0:
		capturare_diagonala_pion_alb()

#functiile deplasare_inainte_pion_negru() si deplasare_diagonala_pion_negru() sunt unite in functia deplasare_pion_negru()
func deplasare_inainte_pion_negru():
	if grid_pos.x == start_pos.x - 1 and  grid_pos.y == start_pos.y  :
		if pasi == 2:
			deplasare_piesa()
			if grid_pos.x == 0:
				#trebuie sters pionul de pe tabla
				var index = 100
				for i in range(piese_negre.size()):
					if Vector2i(piese_negre[i].position.x, piese_negre[i].position.y ) == grid_pos * cell_size + Vector2i(cell_size /2, cell_size /2 ):
						index = i
						break
				if index != 100: # a fost gasita o piesa alba, aceasta trebuei stearsa
					piese_negre[index].queue_free()
					piese_negre.remove_at(index)
			
				create_marker(-1, grid_pos * cell_size + Vector2i(cell_size /2, cell_size /2) )
				grid_data[grid_pos.y][grid_pos.x][0] = -1
				transformare_pion = true
	elif grid_pos.x == start_pos.x - 2 and  grid_pos.y == start_pos.y and start_pos.x == 6 and grid_data[start_pos.y][start_pos.x - 1][0] == 0  :
		if pasi == 2 :
			deplasare_piesa()
func capturare_diagonala_pion_negru():
	if grid_pos.x == start_pos.x - 1   and  grid_pos.y  == start_pos.y + 1 or  grid_pos.x == start_pos.x - 1  and  grid_pos.y  == start_pos.y - 1 :
		if pasi == 2:
			deplasare_piesa()
			if grid_pos.x == 0:
				#trebuie sters pionul de pe tabla
				var index = 100
				for i in range(piese_negre.size()):
					if Vector2i(piese_negre[i].position.x, piese_negre[i].position.y ) == grid_pos * cell_size + Vector2i(cell_size /2, cell_size /2 ):
						index = i
						break
				if index != 100: # a fost gasita o piesa alba, aceasta trebuei stearsa
					piese_negre[index].queue_free()
					piese_negre.remove_at(index)
			
				create_marker(-1, grid_pos * cell_size + Vector2i(cell_size /2, cell_size /2) )
				grid_data[grid_pos.y][grid_pos.x][0] = -1
				transformare_pion = true
func deplasare_pion_negru():
	if grid_pos != start_pos and grid_data[grid_pos.y][grid_pos.x][0] == 0:
		deplasare_inainte_pion_negru()
	elif grid_pos != start_pos and grid_data[grid_pos.y][grid_pos.x][0] >0:
		capturare_diagonala_pion_negru()

#functiile luare_piesa_linie() si luare_piesa_coloana() sunt unite in functia luare_piesa_linie_coloana()
# functia luare_piesa_linie_coloana se refera la deplasarea turei si la capturarea pieselor de catrea aceasta
func luare_piesa_linie():
	# capturare piesa adversa pe linie
	var sens = 0
	if grid_pos.y == start_pos.y:
		print("esti in fucntia luare_piesa_linie")
		if grid_pos.x >= start_pos.x:
			sens = 1
			print("Sensul este ", sens)
			print("aliati player-ului ",player, " sunt ", ally )
			for i in range(start_pos.x + 1,grid_pos.x + 1, sens):
				print(i)
				print("esti in for loop")
				# detecteaza inamici pe
				if grid_data[grid_pos.y][i][0] >= enemy.x and grid_data[grid_pos.y][i][0] <= enemy.y :
					grid_pos.x = i
					print("Tura a intalnit un inamic in drum")
					print("tura ramane pe pozitia cu grid_pos.x = ", i, " si grid_pos.y = ", grid_pos.y)
					break
				if grid_data[grid_pos.y][i][0] >= ally.x and grid_data[grid_pos.y][i][0] <= ally.y :
					grid_pos.x = i - 1
					print("Tura a intalnic un aliat in drum")
					print("tura ramane pe pozitia cu grid_pos.x = ", i, " si grid_pos.y = ", grid_pos.y)
					break
		else: 
			sens = -1
			print("Sensul este ", sens)
			print("aliati player-ului ",player, " sunt ", ally )
			for i in range(start_pos.x - 1 ,grid_pos.x - 1, sens):
				print(i)
				print("Esti in for loop")
				# detecteaza inamici pe
				if grid_data[grid_pos.y][i][0] >= enemy.x and grid_data[grid_pos.y][i][0] <= enemy.y :
					grid_pos.x = i
					print("Tura a intalnit un inamic in drum")
					print("tura ramane pe pozitia cu grid_pos.x = ", i, " si grid_pos.y = ", grid_pos.y)
					break
				if grid_data[grid_pos.y][i][0] >= ally.x and grid_data[grid_pos.y][i][0] <= ally.y :
					grid_pos.x = i + 1
					print("Tura a intalnic un aliat in drum")
					print("tura ramane pe pozitia cu grid_pos.x = ", i, " si grid_pos.y = ", grid_pos.y)
					break
		if grid_pos != start_pos:
			deplasare_piesa()
		else:
			pasi = 2 # se permite iar mutarea deoarece prima nu a produs nici-o miscare
	print("parasire functie luare_piesa_linie")
func luare_piesa_coloana():
	#capturare piesa pe coloanna
	var sens = 0
	if grid_pos.x == start_pos.x:
		print("esti in functia luare_piesa_coloana")
		if grid_pos.y >= start_pos.y:
			sens = 1
			print("Sensul este ", sens)
			print("aliati player-ului ",player, " sunt ", ally )
			for i in range(start_pos.y + 1,grid_pos.y + 1, sens):
				print(i)
				print("esti in for loop")
				if grid_data[i][grid_pos.x][0] >= enemy.x and grid_data[i][grid_pos.x][0] <= enemy.y :
					grid_pos.y = i
					print("Tura a intalnit un inamic in drum")
					print("tura ramane pe pozitia cu grid_pos.x = ", grid_pos.x, " si grid_pos.y = ", i)
					break
				if grid_data[i][grid_pos.x][0] >= ally.x and grid_data[i][grid_pos.x][0] <= ally.y :
					grid_pos.x = i - 1
					print("Tura a intalnic un aliat in drum")
					print("tura ramane pe pozitia cu grid_pos.x = ", grid_pos.x, " si grid_pos.y= ", i)
					break
		else: 
			sens = -1
			print("Sensul este ", sens)
			print("aliati player-ului ",player, " sunt ", ally )
			for i in range(start_pos.y - 1,grid_pos.y -1,sens):
				print(i)
				print("Esti in for loop")
				if grid_data[i][grid_pos.x][0] >= enemy.x and grid_data[i][grid_pos.x][0] <= enemy.y :
					grid_pos.y = i
					print("Tura a intalnit un inamic in drum")
					print("tura ramane pe pozitia cu grid_pos.x = ", grid_pos.x, " si grid_pos.y = ", i)
					break
				if grid_data[i][grid_pos.x][0] >= ally.x and grid_data[i][grid_pos.x][0] <= ally.y :
					grid_pos.y = i + 1
					print("tura ramane pe pozitia cu grid_pos.x = ", grid_pos.x, " si grid_pos.y = ", i)
					print("Tura a intalnic un aliat in drum")
					break
		
		
		
		if grid_pos != start_pos:
			deplasare_piesa()
		else:
			pasi = 2 # se permite iar mutarea deoarece prima nu a produs nici-o miscare
	print("parasirea functie luare_piesa_coloana")
func luare_piesa_linie_coloana():
	luare_piesa_linie()
	luare_piesa_coloana() 
	print("parasier functie luare_piesa_linie_coloana")

#functia deplasare_cal() verifica daca pozitia indicata de player este aceasi cu una dintre cele 8 mutari posibile ale calului
#daca pe acea pozitie se afla o piesa adversara sau este o pozitie goala, se executa mutarea
func deplasare_cal():
	var sens = 1 # deplasare la dreapta de poz initiala cal
	print(" ")
	print("intrare infunctia deplasare_cal")
	
	#verificare mutare ca fiind pe tabla
	if grid_pos.x >= 0 and grid_pos.x <=7 and grid_pos.y >= 0 and grid_pos.y <=7 :
		print("Mutarea apare pe tabla: (linie,coloana) ", grid_pos.y, " ", grid_pos.x )
		#verificare mutari partea dreapta fata de poz initiala cal
		#verificare mutare (linie , coloana) (-2, +1)
		if grid_pos.x == start_pos.x + (1*sens)  and grid_pos.y == start_pos.y -2 :
			print("calul este mutat la pozitia (linie,coloana) ", grid_pos.y, " ", grid_pos.x )
			deplasare_piesa()
		#verificare mutare (-1, +2)
		if grid_pos.x == start_pos.x + (2*sens)  and grid_pos.y == start_pos.y -1 :
			print("calul este mutat la pozitia (linie,coloana) ", grid_pos.y, " ", grid_pos.x )
			deplasare_piesa()
		#verificare mutare (+1, +2)
		if grid_pos.x == start_pos.x + (2*sens)  and grid_pos.y == start_pos.y +1 :
			print("calul este mutat la pozitia (linie,coloana) ", grid_pos.y, " ", grid_pos.x )
			deplasare_piesa()
			#verificare mutare(+2,+1)
		if grid_pos.x == start_pos.x + (1*sens)  and grid_pos.y == start_pos.y +2 :
			print("calul este mutat la pozitia (linie,coloana) ", grid_pos.y, " ", grid_pos.x )
			deplasare_piesa()
		
		sens = -1
		#verificare mutari partea stanga 
		#verificare mutare (linie , coloana) (-2, -1)
		if grid_pos.x == start_pos.x + (1*sens)  and grid_pos.y == start_pos.y -2 :
			print("calul este mutat la pozitia (linie,coloana) ", grid_pos.y, " ", grid_pos.x )
			deplasare_piesa()
		#verificare mutare (-1, -2)
		if grid_pos.x == start_pos.x + (2*sens)  and grid_pos.y == start_pos.y -1 :
			print("calul este mutat la pozitia (linie,coloana) ", grid_pos.y, " ", grid_pos.x )
			deplasare_piesa()
		#verificare mutare (+1, -2)
		if grid_pos.x == start_pos.x + (2*sens)  and grid_pos.y == start_pos.y +1 :
			print("calul este mutat la pozitia (linie,coloana) ", grid_pos.y, " ", grid_pos.x )
			deplasare_piesa()
			#verificare mutare(+2,-1)
		if grid_pos.x == start_pos.x + (1*sens)  and grid_pos.y == start_pos.y +2 :
			print("calul este mutat la pozitia (linie,coloana) ", grid_pos.y, " ", grid_pos.x )
			deplasare_piesa()

# functia luare_piesa_diagonala() verifica daca pozitia indicata de player se afla in diagonala cu pozitia piesei 
# si apoi verifica daca de la piesa pana la pozitia indicata se gaseste alta piesa care ii blocheaza calea
# daca este o piesa inamica, o captureaza si ii ocupa pozitia
#daca este o piesa aliata, ocupa un patratel inaintea ei 
func luare_piesa_diagonala():
	var dx = abs(grid_pos.x - start_pos.x)
	var dy = abs(grid_pos.y - start_pos.y)
	#verific daca pozitia data este pe diagonala cu pozitia initiala
	if dx == dy and dx > 0 : 
		
		
		if grid_pos.y < start_pos.y  and grid_pos.x > start_pos.x : 
			print("pozitie initiala la diagonala dreapta sus")
			print("esti in for loop")
			for i in range(1,8):
				if(start_pos.x + i > 7):
					print(" break deoarece start_pos.x + i > 7")
					break
				if(start_pos.x + i > grid_pos.x):
					print("break deoarece start_pos.x + i > grid_pos.x")
					break
				if(start_pos.y - i < 0):
					print(" break deoarece start_pos.y - i < 0")
					break
				if(start_pos.y  - i < grid_pos.y):
					print("break deoarece start_pos.y - i < grid_pos.y")
					break
				print(i)
				# detecteaza inamici 
				if grid_data[start_pos.y - i][start_pos.x + i][0] >= enemy.x and grid_data[start_pos.y - i][start_pos.x + i][0] <= enemy.y :
					grid_pos.x = start_pos.x + i
					grid_pos.y = start_pos.y - i
					print("Nebunul a intalnit un inamic in drum")
					print("Nebunul ramane pe pozitia cu grid_pos.x = ", grid_pos.x, " si grid_pos.y = ", grid_pos.y)
					break
				#detecteaza aliat
				if  grid_data[start_pos.y - i][start_pos.x + i][0] >= ally.x and  grid_data[start_pos.y - i][start_pos.x + i][0] <= ally.y :
					grid_pos.x = start_pos.x + i - 1
					grid_pos.y = start_pos.y - i + 1
					print("Nebunul a intalnic un aliat in drum")
					print("Nebunul ramane pe pozitia cu grid_pos.x = ", grid_pos.x, " si grid_pos.y = ", grid_pos.y)
					break
					
		elif grid_pos.y > start_pos.y  and grid_pos.x < start_pos.x: # pozitie initiala la diagonala stanga jos
			print("pozitie initiala la diagonala stanga jos")
			print("esti in for loop")
			for i in range(1,8):
				if(start_pos.y + i > 7):
					print(" break deoarece start_pos.y + i > 7")
					break
				if(start_pos.y + i > grid_pos.y):
					print("break deoarece start_pos.y + i > grid_pos.x")
					break
				if(start_pos.x - i < 0): 
					print(" break deoarece start_pos.x - i < 0")
					break
				if(start_pos.x - i < grid_pos.x):
					print("break deoarece start_pos.x - i < grid_pos.x")
					break
				print(i)
				# detecteaza inamici 
				if grid_data[start_pos.y + i][start_pos.x - i][0] >= enemy.x and grid_data[start_pos.y + i][start_pos.x - i][0] <= enemy.y :
					grid_pos.x = start_pos.x - i 
					grid_pos.y = start_pos.y + i
					print("Nebunul a intalnit un inamic in drum")
					print("Nebunul ramane pe pozitia cu grid_pos.x = ", grid_pos.x, " si grid_pos.y = ", grid_pos.y)
					break
				#detecteaza aliat
				if  grid_data[start_pos.y + i][start_pos.x - i][0] >= ally.x and  grid_data[start_pos.y + i][start_pos.x - i][0] <= ally.y :
					grid_pos.x = start_pos.x - i + 1
					grid_pos.y = start_pos.y + i - 1
					print("Nebunul a intalnic un aliat in drum")
					print("Nebunul ramane pe pozitia cu grid_pos.x = ", grid_pos.x, " si grid_pos.y = ", grid_pos.y)
					break
		
		elif grid_pos.y > start_pos.y  and grid_pos.x > start_pos.x :
			print("pozitie initiala la diagonala dreapta jos")
			print("esti in for loop")
			for i in range(1,8):
				if(start_pos.x + i > 7):
					print(" break deoarece start_pos.x + i > 7")
					break
				if(start_pos.x + i > grid_pos.x):
					print("break deoarece start_pos.x + i > grid_pos.x")
					break
				print(i)
				# detecteaza inamici 
				if grid_data[start_pos.y + i][start_pos.x + i][0] >= enemy.x and grid_data[start_pos.y + i][start_pos.x + i][0] <= enemy.y :
					grid_pos.x = start_pos.x + i
					grid_pos.y = start_pos.y + i
					print("Nebunul a intalnit un inamic in drum")
					print("Nebunul ramane pe pozitia cu grid_pos.x = ", grid_pos.x, " si grid_pos.y = ", grid_pos.y)
					break
				#detecteaza aliat
				if  grid_data[start_pos.y + i][start_pos.x + i][0] >= ally.x and  grid_data[start_pos.y + i][start_pos.x + i][0] <= ally.y :
					grid_pos.x = start_pos.x + i - 1
					grid_pos.y = start_pos.y + i - 1
					print("Nebunul a intalnic un aliat in drum")
					print("Nebunul ramane pe pozitia cu grid_pos.x = ", grid_pos.x, " si grid_pos.y = ", grid_pos.y)
					break
					
		elif grid_pos.y < start_pos.y  and grid_pos.x < start_pos.x:
			print("pozitie initiala la diagonala stanga sus")
			print("esti in for loop")
			for i in range(1,8):
				if(start_pos.x - i < 0):
					print(" break deoarece start_pos.x - i < 0")
					break
				if(start_pos.x  - i < grid_pos.x):
					print("break deoarece start_pos.x - i < grid_pos.x")
					break
				print(i)
				# detecteaza inamici 
				if grid_data[start_pos.y - i][start_pos.x - i][0] >= enemy.x and grid_data[start_pos.y - i][start_pos.x - i][0] <= enemy.y :
					grid_pos.x = start_pos.x - i
					grid_pos.y = start_pos.y - i
					print("Nebunul a intalnit un inamic in drum")
					print("Nebunul ramane pe pozitia cu grid_pos.x = ", grid_pos.x, " si grid_pos.y = ", grid_pos.y)
					break
				#detecteaza aliat
				if  grid_data[start_pos.y - i][start_pos.x - i][0] >= ally.x and  grid_data[start_pos.y - i][start_pos.x - i][0] <= ally.y :
					grid_pos.x = start_pos.x - i + 1
					grid_pos.y = start_pos.y - i + 1
					print("Nebunul a intalnic un aliat in drum")
					print("Nebunul ramane pe pozitia cu grid_pos.x = ", grid_pos.x, " si grid_pos.y = ", grid_pos.y)
					break
		
		if grid_pos != start_pos:
			deplasare_piesa()
		else:
			pasi = 2 # se permite iar mutarea deoarece prima nu a produs nici-o miscare
	print("parasire functie luare_piesa_diagonala")

# functia deplasare_regina() reuneste functiile luare_piesa_diagonala() si luare_piesa_linie_coloana()
func deplasare_regina():
	luare_piesa_linie_coloana()
	luare_piesa_diagonala()

# functia deplasare_rege() este inca rudimentara,
#aceasta verifica daca ozitia dorita de player este libera sau ocupata de un inamic si realizeaza mutarea regelui acolo
func deplasare_rege() ->bool:
	print(" ")
	print("Ai intrat in functia deplasare_rege")
	var sens
	sens = 1
	# verificare pozitie dreapta sus
	if grid_pos.y == start_pos.y - 1 and grid_pos.x == start_pos.x + (1 * sens):
		print("Regele mutat la pozitia grid_pos.x = ", grid_pos.x, " si grid_pos.y = ", grid_pos.y) 
		deplasare_piesa()
		pos_rege_actual = grid_pos
		return true
		
	# verificare pozitie dreapta
	if grid_pos.y == start_pos.y and grid_pos.x == start_pos.x + (1 * sens):
		print("Regele mutat la pozitia grid_pos.x = ", grid_pos.x, " si grid_pos.y = ", grid_pos.y) 
		deplasare_piesa()
		pos_rege_actual = grid_pos
		return true
	#verificare pozitie dreapta jos
	if grid_pos.y == start_pos.y + 1 and grid_pos.x == start_pos.x + (1 * sens):
		print("Regele mutat la pozitia grid_pos.x = ", grid_pos.x, " si grid_pos.y = ", grid_pos.y) 
		deplasare_piesa()
		pos_rege_actual = grid_pos
		return true
	#verificare pozitie jos
	if grid_pos.y == start_pos.y + (1 * sens) and grid_pos.x == start_pos.x:
		print("Regele mutat la pozitia grid_pos.x = ", grid_pos.x, " si grid_pos.y = ", grid_pos.y) 
		deplasare_piesa()
		pos_rege_actual = grid_pos
		return true
		
	sens = - 1 # pastea stanga si sus de poitii
	
	#verificare pozitie stanga sus
	if grid_pos.y == start_pos.y - 1 and grid_pos.x == start_pos.x + (1 * sens):
		print("Regele mutat la pozitia grid_pos.x = ", grid_pos.x, " si grid_pos.y = ", grid_pos.y) 
		deplasare_piesa()
		pos_rege_actual = grid_pos
		return true
	# verificare pozitie stanga
	if grid_pos.y == start_pos.y and grid_pos.x == start_pos.x + (1 * sens):
		print("Regele mutat la pozitia grid_pos.x = ", grid_pos.x, " si grid_pos.y = ", grid_pos.y) 
		deplasare_piesa()
		pos_rege_actual = grid_pos
		return true
	#verificare pozitie stanga jos
	if grid_pos.y == start_pos.y + 1 and grid_pos.x == start_pos.x + (1 * sens):
		print("Regele mutat la pozitia grid_pos.x = ", grid_pos.x, " si grid_pos.y = ", grid_pos.y) 
		deplasare_piesa()
		pos_rege_actual = grid_pos
		return true
	#verificare pozitie sus
	if grid_pos.y == start_pos.y + (1 * sens) and grid_pos.x == start_pos.x:
		print("Regele mutat la pozitia grid_pos.x = ", grid_pos.x, " si grid_pos.y = ", grid_pos.y) 
		deplasare_piesa()
		pos_rege_actual = grid_pos
		return true
	return false

#pentru pozitia oferita functiei, se_afla_in_sah returneaza true daca acea pozitie se afla in sah si false in caz contrar
func se_afla_in_sah(pozitie : Vector2i)-> bool:
	
	# verificam daca pe linie se afla piese ce pot pune in pericol pozitia
	# mai exact ture si regine
	print("")
	print("Intrare in functia se_afla_in_sah")
	print("Se verifica daca sunt inamici pe aceasi linie")
	var sens = 0
	var grid_pos = Vector2i(7,pozitie.y)
	# de la pozitie la dreapta
	sens = 1 
	#print("Sensul este ", sens)
	#print("aliati player-ului ",player, " sunt ", ally )
	for i in range(pozitie.x + 1,grid_pos.x + 1, sens):
		#print(i)
		#print("esti in for loop")
		# detecteaza inamici 
		if grid_data[grid_pos.y][i][0] >= enemy.x and grid_data[grid_pos.y][i][0] <= enemy.y :
			if grid_data[grid_pos.y][i][0] == -1 * player or grid_data[grid_pos.y][i][0] == -5 * player:
				print("Piesa a intalnit un inamic pe linie la dreapta pozitiei ")
				return true
			if grid_data[grid_pos.y][i][0] == -2 * player and i == pozitie.x + 1:
				print("Aliatii player-ului sunt " ,ally)
				print("Piesa a intalnit un rege pe linie la dreapta pozitiei ")
				return true
			break
		if grid_data[grid_pos.y][i][0] >= ally.x and grid_data[grid_pos.y][i][0] <= ally.y :
			print("pe linie la drepta pozitiei se afla un aliat", grid_pos.y, i )
			break
	# de la pozitie la stanga		
	grid_pos = Vector2i(0,pozitie.y) 
	sens = -1
	#print("Sensul este ", sens)
	#print("aliati player-ului ",player, " sunt ", ally )
	for i in range(pozitie.x-1 ,grid_pos.x - 1, sens):
		#print(i)
		#print("Esti in for loop")
		# detecteaza inamici 
		if grid_data[grid_pos.y][i][0] >= enemy.x and grid_data[grid_pos.y][i][0] <= enemy.y :
			if grid_data[grid_pos.y][i][0] == -1 * player or grid_data[grid_pos.y][i][0] == -5 * player:
				print("Piesa a intalnit un inamic pe linie la stanga pozitiei ")
				return true
			if grid_data[grid_pos.y][i][0] == -2 * player and i == pozitie.x - 1:
				print("Piesa a intalnit un rege pe linie la stanga pozitiei ")
				return true
			break
		if grid_data[grid_pos.y][i][0] >= ally.x and grid_data[grid_pos.y][i][0] <= ally.y :
			print("pe linie la stanga pozitiei se afla un aliat", grid_pos.y , i )
			break
	# verificam daca pe clooana se afla piese ce pot pune in pericol pozitia
	print("")
	print("Se verifica daca sunt inamici pe aceasi coloana")
	sens = 0
	grid_pos = Vector2i(pozitie.x,7)
	# de la pozitie in jos
	sens = 1 
	#print("Sensul este ", sens)
	#print("aliati player-ului ",player, " sunt ", ally )
	for i in range(pozitie.y + 1,grid_pos.y + 1, sens):
	#	print(i)
	#	print("esti in for loop")
		# detecteaza inamici 
		if grid_data[i][grid_pos.x][0] >= enemy.x and grid_data[i][grid_pos.x][0] <= enemy.y :
			if grid_data[i][grid_pos.x][0] == -1 * player or grid_data[i][grid_pos.x][0] == -5 * player:
				print("Piesa a intalnit un inamic pe coloana sub pozitie ")
				return true
			if grid_data[i][grid_pos.x][0] == -2 * player and i == pozitie.y + 1 :
				print("Piesa a intalnit un rege pe coloana sub pozitie ")
				return true
			break
		if grid_data[i][grid_pos.x][0] >= ally.x and grid_data[i][grid_pos.x][0] <= ally.y :
			print("pe coloana sub pozitiei se afla un aliat", i,grid_pos.x)
			break
	# de la pozitie in sus		
	grid_pos = Vector2i(pozitie.x, 0  ) 
	sens = -1
	#print("Sensul este ", sens)
	#print("aliati player-ului ",player, " sunt ", ally )
	#print(pozitie.y-1 ,  "    " ,grid_pos.y - 1)
	for i in range(pozitie.y-1 ,grid_pos.y - 1, sens):
	#	print(i)
	#	print("Esti in for loop")
		# detecteaza inamici 
		if grid_data[i][grid_pos.x][0] >= enemy.x and grid_data[i][grid_pos.x][0] <= enemy.y :
			if grid_data[i][grid_pos.x][0] == -1 * player or grid_data[i][grid_pos.x][0] == -5 * player:
				print("Piesa a intalnit un inamic pe coloana mai sus de pozitie ")
				return true
			if grid_data[i][grid_pos.x][0] == -2 * player and i == pozitie.y - 1:
				print("Piesa a intalnit un rege pe coloana mai sus de pozitie ")
				return true
			break
		if grid_data[i][grid_pos.x][0] >= ally.x and grid_data[i][grid_pos.x][0] <= ally.y :
			print("pe coloana mai sus de pozitiei se afla un aliat",i,grid_pos.x)
			break
	
	
	
	#verificam daca pe diagonala de la pozitie la dreapta jos
	print(" ")
	print("se verifica daca sunt inamici pe diagonala principala")
	var no_treat = true
	#diagonala dreapta jos
	var j = 1
	while no_treat == true:
		
		if pozitie.x + j == 8:
			break
		elif pozitie.y + j == 8:
			break
		elif grid_data[pozitie.y + j][pozitie.x + j][0] == -1 * player or  grid_data[pozitie.y + j][pozitie.x + j][0] == -3 * player:  ## verificam pentru regina si nebun
			print("pe diagonala dreapta jos se afla o regina sau nebun")
			return true
		# din dreapta jos doar regele alb poate fii atacat de catre un pion negru
		elif (grid_data[pozitie.y + j][pozitie.x + j][0] == - 6 and j == 1 and player == 1)  or (grid_data[pozitie.y + j][pozitie.x + j][0] == -2 * player and j == 1):  
			print("pe diagonala dreapta jos se afla un pion sau rege")
			return true
		elif grid_data[pozitie.y + j][pozitie.x + j][0] >= enemy.x and  grid_data[pozitie.y + j][pozitie.x + j][0] <=enemy.y:
			break
		elif grid_data[pozitie.y + j][pozitie.x + j][0] >= ally.x and  grid_data[pozitie.y + j][pozitie.x + j][0] <=ally.y:
			print("pe diagonala dreapta jos se afla un aliat",pozitie.y + j, pozitie.x + j)
			break
		j  += 1 
		
	#diagonala stanga sus
	j = 1
	while no_treat == true:
		if pozitie.x - j == -1:
			break
		elif pozitie.y - j == -1:
			break
		elif grid_data[pozitie.y - j][pozitie.x - j][0] == -1 * player or grid_data[pozitie.y - j][pozitie.x - j][0] == -3 * player : # verificam pentru regina si nebun
			print("pe diagonala stanga sus se afla o regina sau nebun")
			return true
		# din stanga sus doar regele negru poate fii atacat de catre un pion alb
		elif (grid_data[pozitie.y - j][pozitie.x - j][0] == 6 and j == 1 and player == -1) or (grid_data[pozitie.y - j][pozitie.x - j][0] == -2*player and j == 1) :  
			print("pe diagonala sstanga sus se afla un pion sau rege")
			return true
		elif grid_data[pozitie.y - j][pozitie.x - j][0] >= enemy.x and grid_data[pozitie.y - j][pozitie.x - j][0] <= enemy.y:
			break
		elif grid_data[pozitie.y - j][pozitie.x - j][0] >= ally.x and grid_data[pozitie.y - j][pozitie.x - j][0] <= ally.y:
			print("pe diagonala stanga sus se afla un aliat", pozitie.y - j, pozitie.x - j)
			break
		j +=1
	
	
	print("Se verifica daca sunt inamici pe diagonala secundara")
	# diagonala dreapta sus
	j = 1
	while no_treat == true:
		if pozitie.x + j == 8:
			break
		elif pozitie.y -j == -1:
			break
		if grid_data[pozitie.y - j ][pozitie.x + j][0] == -1 * player or  grid_data[pozitie.y - j ][pozitie.x + j][0] == -3 * player: #verificam pentru regina si nebun
			print("pe diagonala dreapta sus se afla o regina sau un nebun")
			return true
			# din dreapta sus doar regele alb poate fii atacat de catre un pion negru
		elif (grid_data[pozitie.y - j ][pozitie.x + j][0] == -6 and j == 1 and player == 1) or (grid_data[pozitie.y - j ][pozitie.x + j][0] == -2*player and j == 1) :
				print("pe diagonala drapta sus se afla un pion sau rege")
				return true
		elif grid_data[pozitie.y - j ][pozitie.x + j][0] >= enemy.x and grid_data[pozitie.y - j ][pozitie.x + j][0]<= enemy.y:
			break
		elif grid_data[pozitie.y - j ][pozitie.x + j][0] >= ally.x and grid_data[pozitie.y - j ][pozitie.x + j][0]<= ally.y:
			print("pe diagonala dreapta sus se afla un aliat", pozitie.y - j, pozitie.x + j)
			break
		j +=1
		
	#diagonala stanga jos
	j = 1
	while no_treat == true:
		if pozitie.x - j == -1:
			break
		elif pozitie.y + j == 8:
			break
		elif grid_data[pozitie.y + j ][pozitie.x - j][0] == -1 * player or  grid_data[pozitie.y + j ][pozitie.x - j][0] == -3 * player: #verificam pentru regina si nebun
			print("pe diagonala stanga jos se afla o regina sau un nebun")
			return true
		elif (grid_data[pozitie.y + j ][pozitie.x - j][0] == 6 and j == 1 and player == -1) or grid_data[pozitie.y + j ][pozitie.x - j][0] == -2*player and j == 1 :
				print("pe diagonala stanga jos se afla un pion sau rege")
				return true
		elif grid_data[pozitie.y + j ][pozitie.x - j][0] >= enemy.x and grid_data[pozitie.y + j ][pozitie.x - j][0] <= enemy.y:
			break
		elif grid_data[pozitie.y + j ][pozitie.x - j][0] >= ally.x and grid_data[pozitie.y + j ][pozitie.x - j][0] <= ally.y:
			print("pe diagonala stanga jos se afla un aliat",pozitie.y + j,pozitie.x - j)
			break
		
		j +=1
		
		
		
	# se verifica daca pe una din cele 8 pozitii din care poate ataca un cal,se afla un cal inamic 
	sens = 1 # se verifica mutarile la dreapta de rege
	#verificare mutare (linie , coloana) (-2, +1)
	if pozitie.x + (1*sens) in range(0,8) and pozitie.y -2 in range(0,8) :
		if grid_data[pozitie.y -2][pozitie.x + (1*sens)][0] == -4*player:
			print("calul care ameninta regele (linie,coloana) ", pozitie.y -2, " ", pozitie.x + (1*sens) )
			return true
	#verificare mutare (-1, +2)
	if pozitie.x + (2*sens) in range(0,8) and pozitie.y - 1 in range(0,8):
		if grid_data[pozitie.y - 1][pozitie.x + (2*sens)][0] == -4 * player :
			print("calul care ameninta regele (linie,coloana) ", pozitie.y - 1, " ", pozitie.x + (2*sens) )
			return true
	#verificare mutare (+1, +2)
	if pozitie.x + (2*sens) in range(0,8) and pozitie.y + 1 in range(0,8) :
		if grid_data[pozitie.y + 1][pozitie.x + (2*sens)][0] == -4* player :
			print("calul care ameninta regele (linie,coloana) ", pozitie.y + 1, " ", pozitie.x + (2*sens) )
			return true
		#verificare mutare(+2,+1)
	if pozitie.x + (1*sens) in range (0,8) and pozitie.y +2 in range(0,8):
		if grid_data[pozitie.y +2][pozitie.x + (1*sens)][0] == -4*player :
			print("calul care ameninta regele (linie,coloana) ", pozitie.y +2, " ", pozitie.x + (1*sens) )
			return true
	
	sens = -1 # se verifica mutarile la stanga de rege
	#verificare mutare (linie , coloana) (-2, -1)
	if pozitie.x + (1*sens) in range(0,8) and pozitie.y -2 in range(0,8) :
		if grid_data[pozitie.y -2][pozitie.x + (1*sens)][0] == -4*player:
			print("calul care ameninta regele (linie,coloana) ", pozitie.y -2, " ", pozitie.x + (1*sens) )
			return true
	#verificare mutare (-1, -2)
	if pozitie.x + (2*sens) in range(0,8) and pozitie.y - 1 in range(0,8):
		if grid_data[pozitie.y - 1][pozitie.x + (2*sens)][0] == -4 * player :
			print("calul care ameninta regele (linie,coloana) ", pozitie.y - 1, " ", pozitie.x + (2*sens) )
			return true
	#verificare mutare (+1, -2)
	if pozitie.x + (2*sens) in range(0,8) and pozitie.y + 1 in range(0,8) :
		if grid_data[pozitie.y + 1][pozitie.x + (2*sens)][0] == -4* player :
			print("calul care ameninta regele (linie,coloana) ", pozitie.y + 1, " ", pozitie.x + (2*sens) )
			return true
		#verificare mutare(+2,-1)
	if pozitie.x + (1*sens) in range (0,8) and pozitie.y +2 in range(0,8):
		if grid_data[pozitie.y +2][pozitie.x + (1*sens)][0] == -4*player :
			print("calul care ameninta regele (linie,coloana) ", pozitie.y +2, " ", pozitie.x + (1*sens) )
			return true
		
	return false

func _on_meniu_game_over_restart():
	print("butonul de restart a fost apasat")
	new_game()
