extends Node

func calculate_ratio_as_fraction(aspect_ratio_string):
	var ratioArr = aspect_ratio_string.split(":")
	if ratioArr[0] == null || ratioArr[1] == null:
		push_error("invalid ratio given:" + aspect_ratio_string)
	var fraction = ratioArr[0].to_float() / ratioArr[1].to_float() 
	return fraction

# func calculate_acceleration_speed(defaultAccelerationSpeed, accelerationIncrement):

# Gets closest resolution in array
func get_closest_vector2_in_array(vector2Item, vector2_array):
	print(vector2_array[0])
	var smallestDistance = vector2_array[0].distance_to(vector2Item)
	var smallestDistanceItemIndex = -1
	for i in vector2_array.size():
		var distance = vector2_array[i].distance_to(vector2Item)
		if distance < smallestDistance:
			smallestDistance = distance
			smallestDistanceItemIndex = i
	if smallestDistanceItemIndex == -1:
		push_error("Looking for ${current_vector2} in ${vector2_array} gave indexing error")

	return {"vector2": vector2_array[smallestDistanceItemIndex], "distance": smallestDistance}
		
func append_fixed_array(item, array: Array, arraySizeLimit: int):
	assert(item != null, "Can't append_null_item_to_fixed_array: ${array}")
	if array.size() >= arraySizeLimit:
		array.pop_back()
	
	array.push_front(item)
	return array

# func calculate_acceleration_speed():
