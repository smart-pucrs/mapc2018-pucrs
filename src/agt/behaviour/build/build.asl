get_suitable_well_type(SuitableType) :- default::wellType(SuitableType, Cost, Efficiency, InitialIntegrity, Integrity).

+!buy_well 
	: ::get_suitable_well_type(Type)
<-  
	!action::build(Type); 
	!build_well(Type);
	!strategies::always_recharge; // remove this once the rest of this behaviour is implemented
	.
	
// we need the Type term to know what is the maximum integrity of a well type
+!build_well(Type,Lat,Lon) 
	: rules::am_I_at_right_position(Lat,Lon)
<-
	.print("I'm not at the desired position, going to Lat(",Lat,") Lon(",Lon,")");
	!action::goto(Lat,Lon);
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