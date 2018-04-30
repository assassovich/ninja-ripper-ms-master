-- duplicate_remover_ms.ms
-- By Igor Znag (igorznag@ukr.net)

clearlistener()

try destroydialog igorznag_duplicate_remover catch();
rollout igorznag_duplicate_remover "Duplicates"
(
	label lbl_bb "Bounding Box Size" pos:[5,5]
	spinner spn_threshold_bb "Threshold, %:" pos:[95,20] fieldwidth:35 type:#float range:[0.001,50,0.1]
	label lbl_verts "Vertex Count" pos:[5,40]
	spinner spn_threshold_verts "Threshold, %:" pos:[95,55] fieldwidth:35 type:#float range:[0.001,50,0.1]
	checkbox cb_uv_scale "UV Scale" pos:[5,85] checked:true
	spinner spn_uv_scale range:[0,1e9,0.000244] fieldwidth:60 pos:[70,85]
	button btn_uv_scale "UV Scale" pos:[160,80]
	checkbox cb_align_objects "Align Objects" pos:[5,110] checked:true
	button btn_align_objects "Align Objects" pos:[115,110] checked:true width:105
	button btn_delete_duplicates "Delete" pos:[5,140] width:215 
	
	on btn_align_objects pressed do
	(
		x_min=1e9; y_min=1e9; z_min=1e9; y_max=-1e9; z_max=-1e9
		for obj in geometry do
		(
			if obj.min.x<x_min do x_min=obj.min.x; if obj.min.y<y_min do y_min=obj.min.y; if obj.min.z<z_min do z_min=obj.min.z
			if obj.max.y>y_max do y_max=obj.max.y; if obj.max.z>z_max do z_max=obj.max.z	
		)--for obj in selection do
		x_pos=x_min; y_pos=1.0*(y_min+y_max)/2; 
		z_pos=z_min--1.0*(z_min+z_max)/2
		x_delta=x_min
		undo on
		for obj in geometry do
		(
			obj_x=obj.max.x-obj.min.x;
			obj.pos=[x_delta+obj.pos.x-obj.min.x,y_pos,z_pos]
			x_delta+=obj_x*1.2
		)--for obj in selection do
		redrawviews()
	)--on btn_align_objects pressed do
	
	on btn_uv_scale pressed do
	(	
		--Map channel 1
		for obj in geometry do
		(
			converttomesh obj; m=obj.mesh; n=getNumTVerts m
			--Scale
			for i=1 to n do (tv=getTVert m i;tv_new=tv*spn_uv_scale.value;settvert m i tv_new)
			update m;
		)--for obj in geometry do
		
		--Scale Mapchannel 2 if exists
		for obj in geometry do
		(
			--converttomesh obj; 
			m=obj.mesh; 
			nm=meshop.getNumMaps m
			if nm>=3 do
			(
				map_channel=2
				n=meshop.getNumMapVerts m map_channel
				--Scale
				for i=1 to n do (tv=meshop.getMapVert m map_channel i; tv_new=tv*spn_uv_scale.value; meshop.setMapVert m map_channel i tv_new)
				update m; 
			)--if nm>=3 do
		)--for obj in geometry do
		completeredraw()
	)--on btn_uv_align_and_scale pressed do
	
	on btn_delete_duplicates pressed do
	(
		undo on
		(
			objs_all=geometry as array; objs_duplicates_bb=#(); threshold_bb=spn_threshold_bb.value; threshold_bb=1.0*threshold_bb/100
			while objs_all.count!=0 do
			(
				obj1=objs_all[1]; obj_duplicates_bb=#()
				for obj2 in objs_all do
				(
					obj1x=obj1.max.x-obj1.min.x; obj1y=obj1.max.y-obj1.min.y; obj1z=obj1.max.z-obj1.min.z
					dx=obj1x*threshold_bb; dy=obj1y*threshold_bb;  dz=obj1z*threshold_bb; 
					obj2x=obj2.max.x-obj2.min.x; obj2y=obj2.max.y-obj2.min.y; obj2z=obj2.max.z-obj2.min.z
					if (abs(obj1x-obj2x))<=dx and (abs(obj1y-obj2y))<=dy and (abs(obj1z-obj2z))<=dz  do (  append obj_duplicates_bb obj2)
				)--for obj2 in objs_all where obj1!=obj2 do
				
				append objs_duplicates_bb obj_duplicates_bb
				for obj in obj_duplicates_bb do deleteitem objs_all (finditem objs_all obj)--delete used duplicate
			)----while objs_all.count!=0 
			
			objs_duplicates_bb_verts=#(); threshold_verts=spn_threshold_verts.value; threshold_verts=1.0*threshold_verts/100
			for i=1 to objs_duplicates_bb.count do
			(
				objs_duplicates_bb_all=objs_duplicates_bb[i];
				while objs_duplicates_bb_all.count!=0 do
				(
					obj1=objs_duplicates_bb_all[1]; obj_duplicates_bb_verts=#()
					for obj2 in objs_duplicates_bb_all do
					(
						obj1_verts_count=getNumVerts (obj1.mesh); d_verts_count=obj1_verts_count*threshold_verts; 
						obj2_verts_count=getNumVerts (obj2.mesh); 
						if (abs(obj1_verts_count-obj2_verts_count))<=d_verts_count do (append obj_duplicates_bb_verts obj2)
					)--for obj2 in objs_duplicates_bb_all do
					
					append objs_duplicates_bb_verts obj_duplicates_bb_verts
					for obj in obj_duplicates_bb_verts do deleteitem objs_duplicates_bb_all (finditem objs_duplicates_bb_all obj)--delete used duplicate
				)----while objs_all.count!=0 
			)--for i=1 to objs_duplicates_bb.count do
			
			objs_duplicates_to_delete=#()
			
			for i=1 to objs_duplicates_bb_verts.count do
			(
				obj_duplicate=objs_duplicates_bb_verts[i][1]
				for j=1 to objs_duplicates_bb_verts[i].count do
				(
					obj=objs_duplicates_bb_verts[i][j]; m=obj.material
					if m!=undefined do
					(
						if classof m==Standardmaterial then
						(
							if classof obj.material.diffusemap==Bitmaptexture	do
							(
								dmfn=obj.material.diffusemap.filename; dmfnf=getFilenameFile dmfn; dmfnt=getFilenameType dmfn
								if not (dmfnf=="setka" and dmfnt==".png") do (obj_duplicate=objs_duplicates_bb_verts[i][j]; exit)
							)--if classof obj.material.diffusemap==Bitmaptexture	do
						)else 
						(
							bmps=getclassinstances Bitmaptexture target:m
							if bmps.count>0 do (obj_duplicate=objs_duplicates_bb_verts[i][j]; exit)
						)--else if classof m==Standardmaterial then
					)--if m!=undefined do
					
				)--for j=1 to objs_duplicates_bb_verts[i].count do
				deleteitem objs_duplicates_bb_verts[i] (finditem objs_duplicates_bb_verts[i] obj_duplicate)
				join objs_duplicates_to_delete objs_duplicates_bb_verts[i]
			)--for i=1 to objs_duplicates_bb_verts.count do
			
			--select objs_duplicates_to_delete
			delete objs_duplicates_to_delete
			
			if cb_uv_scale.checked do btn_uv_scale.pressed()
			if cb_align_objects.checked do btn_align_objects.pressed()
		)--undo on
		completeredraw()
	)--on btn_delete_duplicates pressed do
); createdialog igorznag_duplicate_remover 225 165 style:#(#style_titlebar, #style_border, #style_sysmenu,#style_minimizebox)