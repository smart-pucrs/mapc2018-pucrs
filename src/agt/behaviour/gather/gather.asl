+!go_gather(node(NodeId,Lat,Lon,Item)) 
<- 
	.print("I am going to gather ",Item," at ",NodeId);
	!action::goto(Lat,Lon);
	!action::gather(Item);
	!strategies::always_recharge;
	.
	
+!go_explore
	: new::chargingList(List) & rules::closest_facility(List, Facility)
<-
	.print("Going to my closest charging station",Facility," to explore");
	!action::goto(Facility);
	!action::charge;
	!strategies::always_recharge;
	.