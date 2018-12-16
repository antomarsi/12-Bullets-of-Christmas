extends Label

var final_text

func _ready():
	final_text = text.split(" ", false)
	text = ""

func type_to_word(word_number):
	var new_text = ""
	for i in range(word_number):
		new_text = final_text[i] + " "
	text = new_text