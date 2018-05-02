{ include("$jacamoJar/templates/common-cartago.asl") }
{ include("$jacamoJar/templates/common-moise.asl") }
{ include("$jacamoJar/templates/org-obedient.asl", org) }
{ include("action/actions.asl",action) }
{ include("strategies/build/build.asl",build) }
{ include("common-rules.asl",rules) }
{ include("strategies/round/new-round.asl") }
{ include("strategies/gather/gather.asl",gather) }
{ include("strategies/common-plans.asl", strategies) }
//{ include("strategies/scheme-plans.asl", org) }
//{ include("strategies/bidder.asl", bidder) }
//{ include("strategies/round/end-round.asl") }

+!add_initiator
<- 
	.include("strategies/initiator.asl", initiator);
	.
	
+!add_coordinator
<- 
	.include("strategies/coordinator.asl", coordinator);
	.
	
+!register(E)
	: .my_name(Me)
<- 
	!new::new_round;
    .print("Registering...");
    register(E);
	.

+default::name(ServerMe)
	: .my_name(Me)
<-
	addServerName(Me,ServerMe);
	.

+default::role(Role, BaseSpeed, MaxSpeed, BaseLoad, MaxLoad, BaseSkill, MaxSkill, BaseVision, MaxVision, BaseBattery, MaxBattery)
	: .my_name(Me) & play(Me,MyRole,_)
<- 
	.wait( default::actionID(S) );
	.wait(500);
	if ( Me == vehicle1 ) {
		?default::map(Map);
		?default::cellSize(CellSize);
		?default::proximity(Proximity);
		initMap(Map,CellSize,Proximity);
	}
	!action::recharge_is_new_skip;
	if ( Me \== vehicle1 ) { setMap; }
	!action::recharge_is_new_skip;
	if ( Me == vehicle2 ) { !!coordinator::initial_coordination; }
//	.print(Me,"  ",Name,"  ",MRole,"  ");
	if (MyRole == builder ) { !!build::buy_well; }
    .

