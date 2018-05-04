try destroydialog get_objects_vertex_coordinates catch()
rollout get_objects_vertex_coordinates "Get objects vertex coordinates"
(
	edittext et_verts_coordinates width:640 pos:[5,30] height:170
	button btn_get "Get and Copy" pos:[5,5] width:100
	
	on btn_get pressed do
	(
		str=""
		for obj in selection where classof obj==Editable_Mesh do
		(
			n=getNumVerts obj
			if n>=4 do
			(
				for i=1 to 3 do (v=getvert obj i; str+=v as string; str+="/"); v=getvert obj 4; str+=v as string
			)--if n>=0 do
			str+="\n"
		)--for obj in selection where classof obj==Editable_Mesh do
		et_verts_coordinates.text=str; setClipBoardText str
	)--on btn_get pressed do
); createdialog get_objects_vertex_coordinates 650 200 style:#(#style_titlebar, #style_border, #style_sysmenu,#style_minimizebox)