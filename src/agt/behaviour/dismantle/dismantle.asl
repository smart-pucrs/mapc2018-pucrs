can_I_attack_well(Well)
:-
	team::enemyWell(Well,Lat,Lon,_) &
	rules::desired_pos_is_valid(Lat,Lon)
	.

+!dismantle_well(Id)
	: can_I_attack_well(Id) & team::enemyWell(Id,Lat,Lon,_)
<-  
	if (not rules::am_I_at_right_position(Lat,Lon)){
		.print("I'm not at the desired position, going to Lat(",Lat,") Lon(",Lon,")");
		!action::goto(Lat,Lon);
	}
	!attack(Id);
	.
+!dismantle_well(Id)
<-
	.print(Id," has been destroyed or I cannot attack well");
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
-!attack(Id)[code(.fail(action(Action),result(Result)))]
<-
	!recover_from_failure(Action,Result);
	.
	
+!recover_from_failure(Action, Result)
<-	
	.print("Action ",Action," failed because of ",Result);
	.