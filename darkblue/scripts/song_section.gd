extends Sequence
class_name SongSection

@export var beat:float = 0
static var current_section:SongSection

func start():
    current_section = self
    super.start()
