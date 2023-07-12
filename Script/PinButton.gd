extends TextureButton

export(Vector2) var coordinate
signal send_c(coordinate)


func _on_TextureButton_pressed():
	if not self.is_pressed():
		var clothes = $"/root/main/Clothes"
		if clothes.pressed_button == 1:
			self.pressed = true
			return 0
	emit_signal("send_c", coordinate)
