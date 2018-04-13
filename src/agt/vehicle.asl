{ include("$jacamoJar/templates/common-cartago.asl") }
{ include("$jacamoJar/templates/common-moise.asl") }
{ include("$jacamoJar/templates/org-obedient.asl", org) }
{ include("action/actions.asl",action) }
//{ include("common-rules.asl") }
//{ include("strategies/round/new-round.asl") }
//{ include("strategies/common-plans.asl", strategies) }
//{ include("strategies/scheme-plans.asl", org) }
//{ include("strategies/bidder.asl", bidder) }
//{ include("strategies/round/end-round.asl") }

//+!add_initiator
//<- 
//	.include("strategies/initiator.asl", initiator);
//	.
	
+!register(E)
	: .my_name(Me)
<- 
//	!new::new_round;
    .print("Registering...");
    register(E);
	.

+default::name(ServerMe)
	: .my_name(Me)
<-
	addServerName(Me,ServerMe);
	.
	
//+default::hasItem(Item,Qty)
//<- .print("Just got #",Qty," of ",Item).

//+default::role(Role,_,LoadCap,_,Tools)
//<-

// only send recharge
//+default::role(Role,_,LoadCap,_,Tools)
//<-
//	.wait( default::actionID(S) );
//	!!strategies::free;
//.

+default::role(Role, BaseSpeed, MaxSpeed, BaseLoad, MaxLoad, BaseSkill, MaxSkill, BaseVision, MaxVision, BaseBattery, MaxBattery)
	: .my_name(Me)
<- 
	.wait( default::actionID(S) );
	!always_recharge;
    .
    
+!always_recharge <- !action::recharge_is_new_skip; !always_recharge.
