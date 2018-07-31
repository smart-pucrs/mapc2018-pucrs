+!dismantle_well(Id)
	: default::well(Id,Lat,Lon,_,_,_)
<-  
	if (not rules::am_I_at_right_position(Lat,Lon)){
		.print("I'm not at the desired position, going to Lat(",Lat,") Lon(",Lon,")");
		!action::goto(Lat,Lon);
	}
	!attack(Id);
	!strategies::free; // remove this once the rest of this behaviour is implemented
	.
	
+!attack(Id)
	: default::well(Id,_,_,_,_,_)
<-
	!action::dismantleWell;
	!attack(Id);
	.
+!attack(Id)
<-
	.print("I have destroyed the opponent's well ",Id);
	.