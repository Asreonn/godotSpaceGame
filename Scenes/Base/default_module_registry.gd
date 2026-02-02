class_name DefaultModuleRegistry

## Varsayilan modul tanimlarini olusturan fabrika.
## ModularBaseManager'dan veri ayrimi saglar.

static func register_defaults(manager: ModularBaseManager) -> void:
	_register_main_base(manager)

static func _register_main_base(manager: ModularBaseManager) -> void:
	var main_base := ModuleDefinition.new()
	main_base.id = "main_base"
	main_base.display_name = "Main Base"
	main_base.description = "Temel us modulu. Sag, sol ve alt yonlere genisletilebilir."
	main_base.build_cost = {"iron": 2}
	main_base.available_directions = [
		Vector2i.RIGHT,   # (1, 0)
		Vector2i.LEFT,    # (-1, 0)
		Vector2i.DOWN,    # (0, 1)
	]
	main_base.sprite_sheet = preload("res://Assets/BaseMainSpriteSheet.png")
	main_base.frame_size = Vector2i(400, 400)
	main_base.h_frames = 8
	# Baglanti -> frame index mapping
	# Sira: Index 0=bos, 1=R, 2=D, 3=L, 4=RD, 5=LD, 6=RL, 7=RLD
	main_base.connection_to_frame = {
		"": 0,       # Hic baglanti yok
		"R": 1,      # Sag
		"D": 2,      # Alt
		"L": 3,      # Sol
		"RD": 4,     # Sag + Alt
		"DL": 5,     # Sol + Alt  (siralama: R, D, L, U)
		"RL": 6,     # Sag + Sol
		"RDL": 7,    # Sag + Sol + Alt
	}
	manager.register_module_def(main_base)
