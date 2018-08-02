+!go_gather(Base,NBase)
	: .my_name(Me) & default::play(Me,CurrentRole,_) & CurrentRole \== gatherer
<- 
	.print("I was a ",CurrentRole,", but I need to become a gatherer");
	!action::forget_old_action(Id);
 	+action::committedToAction(Id);
	
	!strategies::change_role(CurrentRole,gatherer);
	!go_gather(Base,NBase);
	.
+!go_gather(Base,NBase)
	: default::resNode(NodeId,Lat,Lon,Base)
<- 
	.print("I am going to gather ",Base," at ",NodeId);
	!action::goto(Lat,Lon);
	!action::gather(Base,NBase);
	?default::hasItem(Base,NGathered);
	.print("Gathered ",NGathered,"# of ",Base);
	.