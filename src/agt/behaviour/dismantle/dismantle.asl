+!dismantle_well(Lat,Lon) 
	: not rules::am_I_at_right_position(Lat,Lon)
<-
	.print("I'm not at the desired position, going to Lat(",Lat,") Lon(",Lon,")");
	!action::goto(Lat,Lon);
	!dismantle_well(Lat,Lon);
	.

+!dismantle_well(Lat,Lon) 
	: default::well(Id,Lat,Lon,Type,Team,Integrity) & default::wellType(Type,_,_,_,TotalIntegrity)	& (Integrity > 0)	
<- 
	.print("Dismantling well ",Id);
	!action::dismantleWell; 
	!dismantle_well(Lat,Lon);
	.
+!dismantle_well(Lat,Lon)
	: true
<- 
	.print("Well dismantled!");
	.