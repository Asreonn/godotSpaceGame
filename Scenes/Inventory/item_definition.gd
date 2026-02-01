class_name ItemDefinition
extends Resource

## Tek bir item turunu tanimlayan kaynak.
## Yeni item eklemek icin bu Resource'dan turet.

@export var id: String = ""
@export var display_name: String = ""
@export var icon: Texture2D
@export var capacity_cost: int = 1  ## Her birim ne kadar kapasite kaplar
@export var stack_limit: int = -1   ## -1 = sinirsiz, ileride kullanilabilir
@export var color_hint: Color = Color.WHITE  ## UI'da kullanilacak renk ipucu
