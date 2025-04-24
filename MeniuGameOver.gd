extends CanvasLayer
signal restart

func _on_buton_restart_pressed():
	restart.emit()

