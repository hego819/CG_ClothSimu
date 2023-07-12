extends MeshInstance

var mesh_arr = []
var t = 0.0333
var damping = 0.99
var Fg = Vector3(0, -9.8, 0)
var n = 21
var material = preload("res://Assets/Clothes.tres")
var pressed_button = 2

var vertices = PoolVector3Array()
var mesh_vertices = PoolVector3Array()
var mesh_normal = PoolVector3Array()
var mesh_indices = PoolIntArray()
var mesh_uv = PoolVector2Array()
var E = []
var V = []
var L = []
var mode = [1, 1, 0, 0]
var mode_ind = [0, 0, 0, 0]
var mode_vec = [Vector3(5.0, 0.0, 5.0), Vector3(-5.0, 0.0, 5.0), Vector3(5.0, 0.0, -5.0), Vector3(-5.0, 0.0, -5.0)]

func _ready():
	mesh_arr.resize(Mesh.ARRAY_MAX)
	
	for j in range(n):
		for i in range(n):
			vertices.append(Vector3(5.0 - 10.0 * i / (n - 1.0), 0.0, 
			5.0 - 10.0 * j / (n - 1.0)))
	
	var v = 0
	for j in range(n - 1):
		for i in range(n - 1):
			mesh_vertices.append(vertices[i + j * n])
			mesh_indices.append(v*6+0)
			mesh_uv.append(Vector2(i/(n-1.0), j/(n-1.0)))
			
			mesh_vertices.append(vertices[i + 1 + j * n])
			mesh_indices.append(v*6+1)
			mesh_uv.append(Vector2((i+1)/(n-1.0), j/(n-1.0)))
			
			mesh_vertices.append(vertices[i + 1 + (j + 1) * n])
			mesh_indices.append(v*6+2)
			mesh_uv.append(Vector2((i+1)/(n-1.0), (j+1)/(n-1.0)))
			
			mesh_vertices.append(vertices[i + j * n])
			mesh_indices.append(v*6+3)
			mesh_uv.append(Vector2(i/(n-1.0), j/(n-1.0)))
			
			mesh_vertices.append(vertices[i + 1 + (j + 1) * n])
			mesh_indices.append(v*6+4)
			mesh_uv.append(Vector2((i+1)/(n-1.0), (j+1)/(n-1.0)))
			
			mesh_vertices.append(vertices[i + (j + 1) * n])
			mesh_indices.append(v*6+5)
			mesh_uv.append(Vector2(i/(n-1.0), (j+1)/(n-1.0)))
			
			v += 1
			
	for _i in range(len(mesh_vertices)):
		mesh_normal.append(Vector3(0.0, 1.0, 0.0))
		
	mesh_arr[Mesh.ARRAY_VERTEX] = mesh_vertices
	mesh_arr[Mesh.ARRAY_INDEX] = mesh_indices
	mesh_arr[Mesh.ARRAY_TEX_UV] = mesh_uv
	mesh_arr[Mesh.ARRAY_NORMAL] = mesh_normal
	
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_arr)
	mesh.surface_set_material(0, material)
	
	var _E = []
	for i in range(0, len(mesh_vertices), 3):
		var tmp0 = vertices.find(mesh_vertices[i+0], 0)
		var tmp1 = vertices.find(mesh_vertices[i+1], 0)
		var tmp2 = vertices.find(mesh_vertices[i+2], 0)
		_E.append(tmp0)
		_E.append(tmp1)
		_E.append(tmp1)
		_E.append(tmp2)
		_E.append(tmp2)
		_E.append(tmp0)
	
	for i in range(0, len(_E), 2):
		if _E[i] > _E[i + 1]:
			var tmp = _E[i]
			_E[i] = _E[i + 1]
			_E[i + 1] = tmp
	
	for i in range(0, len(_E), 2):
		if (i==0) or (_E[i] != _E[i-2]) or (_E[i+1] != _E[i-1]):
			E.append(_E[i])
			E.append(_E[i+1])
	
	for e in range(0, len(E), 2):
		var i = E[e]
		var j = E[e + 1]
		L.append((vertices[i] - vertices[j]).length())
	
	for _i in range(len(vertices)):
		V.append(Vector3(0.0, 0.0, 0.0))
	
	mode_ind = [0, n-1, len(vertices)-1-(n-1), len(vertices)-1]
		
func count_normal():
	var sum_n = []
	for _i in range(len(mesh_vertices)):
		sum_n.append(0.0)
	for i in range(0, len(mesh_vertices), 3):
		var p0 = mesh_vertices[i]
		var p1 = mesh_vertices[i+1]
		var p2 = mesh_vertices[i+2]
		var normal = (p1 - p0).cross(p2 - p0)
		normal = normal.normalized()
		mesh_normal[i] += normal
		mesh_normal[i+1] += normal
		mesh_normal[i+2] += normal
		sum_n[i] += 1.0
		sum_n[i+1] += 1.0
		sum_n[i+2] += 1.0
	for i in range(len(mesh_vertices)):
		mesh_normal[i] = mesh_normal[i] / sum_n[i]
	
func Strain_Limiting():
	var sum_x = []
	var sum_n = []
	for _i in range(len(vertices)):
		sum_x.append(Vector3(0.0, 0.0, 0.0))
		sum_n.append(0)
	
# warning-ignore:integer_division
	for e in range(len(E)/2):
		var i = E[e*2+0]
		var j = E[e*2+1]
		var A = vertices[i] + vertices[j]
		var B = L[e] * (vertices[i] - vertices[j]).normalized()
		
		sum_x[i] += 0.5 * (A + B)
		sum_x[j] += 0.5 * (A - B)
		
		sum_n[i] += 1
		sum_n[j] += 1
	
	for vt in range(len(vertices)):
		var cont = 0
		for i in range(4):
			if mode[i] == 1:
				if vt==mode_ind[i]: cont = 1
		if cont==1:continue
		var A = vertices[vt] * 0.2 + sum_x[vt]
		var B = 0.2 + sum_n[vt]
		V[vt] += (A / B - vertices[vt]) / t
		vertices[vt] = A / B
		
func _process(_delta):
	for vt in range(len(vertices)):
		var cont = 0
		for i in range(4):
			if mode[i] == 1:
				if vt==mode_ind[i]: cont = 1
		if cont==1: continue
		V[vt] = V[vt] * damping
		V[vt] += t * Fg
		vertices[vt] = vertices[vt] + t * V[vt]
	
	for _i in range(32):
		Strain_Limiting()
	
	var v = 0
	for j in range(n - 1):
		for i in range(n - 1):
			mesh_vertices[v*6+0] = vertices[i + j * n]
			mesh_vertices[v*6+1] = vertices[i + 1 + j * n]
			mesh_vertices[v*6+2] = vertices[i + 1 + (j + 1) * n]
			mesh_vertices[v*6+3] = vertices[i + j * n]
			mesh_vertices[v*6+4] = vertices[i + 1 + (j + 1) * n]
			mesh_vertices[v*6+5] = vertices[i + (j + 1) * n]
			v += 1
			
	count_normal()
	mesh_arr[Mesh.ARRAY_VERTEX] = mesh_vertices
	mesh_arr[Mesh.ARRAY_NORMAL] = mesh_normal
	mesh.surface_remove(0)
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_arr)
	mesh.surface_set_material(0, material)



func _on_Button_pressed(coordinate):
	var ind = coordinate[0] + 2 * coordinate[1]
	if mode[ind] == 0:
		mode[ind] = 1
		vertices[mode_ind[ind]] = mode_vec[ind]
		pressed_button += 1
	elif mode[ind] == 1:
		mode[ind] = 0
		pressed_button -= 1
	
