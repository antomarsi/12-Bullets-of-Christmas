class_name ViewUtil
extends RefCounted

# True when the node is inside the visible part of the world (plus a margin in world pixels).
static func on_screen(node: Node2D, margin := 32.0) -> bool:
	var viewport := node.get_viewport()
	if viewport == null:
		return true
	var view: Rect2 = viewport.get_canvas_transform().affine_inverse() * viewport.get_visible_rect()
	return view.grow(margin).has_point(node.global_position)
