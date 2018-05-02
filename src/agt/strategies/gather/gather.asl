+!go_gather(node(NodeId,Lat,Lon)) 
<- 
	.print("I was sent to gather ",NodeId);
	!action::goto(Lat,Lon);
	!strategies::always_recharge;
	.