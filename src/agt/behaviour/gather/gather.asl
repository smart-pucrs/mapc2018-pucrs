+!go_gather(Base)
	: default::resNode(NodeId,Lat,Lon,Base)
<- 
	.print("I am going to gather ",Base," at ",NodeId);
	!action::goto(Lat,Lon);
	!action::gather(Base);
	!strategies::always_recharge;
	.