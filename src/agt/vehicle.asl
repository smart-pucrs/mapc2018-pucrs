{ include("$jacamoJar/templates/common-cartago.asl") }
{ include("$jacamoJar/templates/common-moise.asl") }
{ include("$jacamoJar/templates/org-obedient.asl", org) }
{ include("action/actions.asl",action) }
{ include("behaviour/build/build.asl",build) }
//{ include("behaviour/dismantle/dismantle.asl",dismantle) }
{ include("common-rules.asl",rules) }
{ include("behaviour/round/new-round.asl") }
{ include("behaviour/gather/gather.asl",gather) }
{ include("behaviour/explore/explore.asl",explore) }
{ include("strategy/common-plans.asl", strategies) }
//{ include("strategies/scheme-plans.asl", org) }
//{ include("strategies/bidder.asl", bidder) }
//{ include("strategies/round/end-round.asl") }
	
//+!add_coordinator
//<- 
//	.include("behaviour/coordinator.asl", coordinator);
//	.
	
+!add_initiator
<- 
	.include("behaviour/cnp/initiator.asl", initiator);
	.
	
+!register(E)
	: .my_name(Me)
<- 
	!new::new_round;
    .print("Registering...");
    register(E);
	.

+default::step(_)
	: not initiator(_) & .my_name(Me) 
<-  
	actions.getAgentNumber(Me,Number);
	.count(play(_,_,_), NoP);
	+numberOfPlayers(NoP);
	+initiator(Number);
	.
    
+default::step(Step)
	: initiator(Number) & Number == Step 
<- 	
	?numberOfPlayers(NoP);
	-+initiator(Number + NoP);
	.
	
+default::step(Step)
	: initiator(Number) & Number < Step 
<-  
	?numberOfPlayers(NoP);
	-+initiator(Number + NoP);
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
	!action::recharge_is_new_skip; // had to add skip another step to make sure it works on slower computers
	// update the code below for a different strategy
	
	if ( Me == vehicle1 ) { !initiator::create_initial_tasks; }
	
//	if ( (MyRole == worker) & (Role \== drone) ) { !!explore::go_explore_charging; }
//	if ( (MyRole == worker) & (Role == drone) ) { !!explore::go_explore_edges; }
	if ( MyRole == builder ) { !!build::buy_well; }

    .


	