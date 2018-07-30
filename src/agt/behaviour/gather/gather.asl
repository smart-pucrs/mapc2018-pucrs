+!go_gather(Base,NBase)
	: default::resNode(NodeId,Lat,Lon,Base)
<- 
	.print("I am going to gather ",Base," at ",NodeId);
	!action::goto(Lat,Lon);
	!action::gather(Base,NBase);
	?default::hasItem(Base,NGathered);
	.print("Gathered ",NGathered,"# of ",Base);
	.