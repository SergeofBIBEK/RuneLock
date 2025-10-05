@tool
extends Node

enum ColorId { RED, GREEN, BLUE }

const CELL_SIZE: int = 64

const COLOR_MAP := {
	ColorId.RED: Color(0.8, 0.3, 0.3),
	ColorId.BLUE: Color(0.3, 0.3, 1),
	ColorId.GREEN: Color(0.3, 0.8, 0.3)
}
