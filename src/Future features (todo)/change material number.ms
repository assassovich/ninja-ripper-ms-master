on execute do
(
	local materialMod = materialModifier materialID:2
	
	for i in selection where isKindOf i GeometryClass do
	(
		addModifier i materialMod 
		convertToPoly i
	)
)