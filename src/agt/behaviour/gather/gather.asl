+!go_gather(node(NodeId,Lat,Lon,Item)) 
<- 
	.print("I am going to gather ",Item," at ",NodeId);
	!action::goto(Lat,Lon);
	!action::gather(Item);
	!strategies::always_recharge;
	.