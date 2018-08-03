{ include("strategy/beliefs_agents.asl") }

!configure_first_strategies.

+!configure_first_strategies
	: true
<-
	.wait( default::actionID(S) & S \== 0 );
	!choose_minimum_well_price;
	.

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
	
+default::massim(Money)
	: rules::my_role(builder,CurrentRole) & not .desire(build::_) & rules::enough_money
<-
	!action::forget_old_action(Id);
 	+action::committedToAction(Id);
	
	!build;
	.


+!always_recharge <- !action::recharge_is_new_skip; !always_recharge.

@free[atomic]
//+!free : not free <- +free; !!action::recharge_is_new_skip; .
+!free : not free <- +free; !!always_recharge; .
//+!free : not free <- .print("free added");+free; !!action::recharge_is_new_skip;.
//+!free : free <- !!action::recharge_is_new_skip.
+!free : free & not .desire(_::always_recharge) <- !!always_recharge.
+!free : free.
@notFree[atomic]
+!not_free <- -free.
//+!not_free <- .print("free removed");-free.

+!change_role(OldRole, NewRole)
<-
	leaveRole(OldRole);
	adoptRole(NewRole);
	.
	
// how do we pick a minimum money to start building wells
+!choose_minimum_well_price
	: .findall(Cost,default::wellType(_,Cost,_,_,_),Wells) & .sort(Wells,SortedWells) & .nth(0,SortedWells,MinimumCost)
<-
	-+minimum_money(MinimumCost);
	.
	
// what builders do
+!build 
	: not rules::enough_money & new::chargingList(List) & rules::farthest_facility(List, Facility)
<-
	.print("Going to my farthest charging station",Facility," to explore");
	!action::goto(Facility);
	!action::charge;
	!build;
	.
+!build
<-
	!build::buy_well; 	
	!build;
	.
	