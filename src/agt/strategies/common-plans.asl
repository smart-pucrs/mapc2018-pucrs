+default::well(Name, Lat, Lon, Type, Team, Integrity)
	: default::team(MyTeam) & MyTeam \== Team
<-
	.print(">>>>>>>>>>>>>>>>>>>> I found a well that doesn't belong to my team");
	.

+default::lastAction(Action)
	: default::step(S) & S \== 0 & Action == noAction & new::noActionCount(Count)
<-
	-+new::noActionCount(Count+1);
	.print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> Step ",S-1," I have done ",Count+1," noActions.");
	-+metrics::noAction(Count+1);
	.


+!always_recharge <- !action::recharge_is_new_skip; !always_recharge.

