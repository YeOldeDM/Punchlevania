
extends RichTextLabel

# member variables here, example:
# var a=2
# var b="textvar"

func _ready():
	append_bbcode("[ol]")
	push_list(0)
	append_bbcode("thing")
	var a = parse_bbcode(get_bbcode())
	print(a)

	
	


