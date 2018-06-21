+default::well(Well, Lat, Lon, Type, Team, Integrity)
//	: not ataque & .print("aqui") & default::team(MyTeam) & MyTeam == Team & my_role(builder) & default::actionID(Id) 
: default::team(MyTeam) & not .substring(MyTeam, Team) & rules::my_role(builder,CurrentRole) & default::actionID(Id)
<-
	.print(">>>>>>>>>>>>>>>>>>>> I found a well that doesn't belong to my team ",Id);
	!action::forget_old_action(Id);
 	+action::committedToAction(Id);
	
	!change_role(CurrentRole,attacker);
	!attack::dismantle_well(Well);
	!change_role(attacker,CurrentRole);
	.

+default::lastAction(Action)
	: default::step(S) & S \== 0 & Action == noAction & new::noActionCount(Count)
<-
	-+new::noActionCount(Count+1);
	.print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> Step ",S-1," I have done ",Count+1," noActions.");
	-+metrics::noAction(Count+1);
	.


+!always_recharge <- !action::recharge_is_new_skip; !always_recharge.

+!change_role(OldRole, NewRole)
<-
	leaveRole(OldRole);
	adoptRole(NewRole);
	.

