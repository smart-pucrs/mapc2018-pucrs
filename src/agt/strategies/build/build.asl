+!buy_well 
	: default::wellType(Type, Cost, Efficiency, InitialIntegrity, Integrity)
<-  
	!action::build(Type); 
	!build_well(Type);
	.
	
+!build_well(Type) 
	: default::well(Id,Lat,Lon,Type,Team,Integrity) & default::wellType(Type,_,_,_,TotalIntegrity) & (Integrity < TotalIntegrity)
<- 
	.print("Building well ",Id);
	!action::buildExistingOne; 
	!build_well(Type);
	.
+!build_well(Type)
	: true
<- 
	.print("I finished the well of type ",Type);
	.