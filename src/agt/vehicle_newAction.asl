{ include("$jacamoJar/templates/common-cartago.asl") }
{ include("$jacamoJar/templates/common-moise.asl") }
{ include("$jacamoJar/templates/org-obedient.asl", org) }
{ include("action/actions_newAction.asl",action) }
{ include("behaviour/build/build.asl",build) }
{ include("behaviour/dismantle/dismantle.asl",attack) }
{ include("common-rules.asl",rules) }
{ include("behaviour/round/new-round.asl") }
{ include("behaviour/gather/gather.asl",gather) }
{ include("behaviour/explore/explore.asl",explore) }
{ include("strategy/common-plans.asl", strategies) }
//{ include("strategies/scheme-plans.asl", org) }
//{ include("strategies/bidder.asl", bidder) }
//{ include("strategies/round/end-round.asl") }
	
+!add_coordinator
<- 
	.include("behaviour/coordinator.asl", coordinator);
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
		!add_coordinator;
		?default::map(Map);
		?default::cellSize(CellSize);
		?default::proximity(Proximity);
		initMap(Map,CellSize,Proximity);
	}
	!action::recharge_is_new_skip;
	if ( Me \== vehicle1 ) { setMap; }
	!action::recharge_is_new_skip;
	!action::recharge_is_new_skip; // had to add skip another step to make sure it works on slowers computers
	// update the code below for a different strategy
	if ( (MyRole == worker) & (Role \== drone) ) { !!explore::go_explore_charging; }
	if ( (MyRole == worker) & (Role == drone) ) { !!explore::go_explore_edges; }
	if ( MyRole == builder ) { !!build::buy_well; }
    .
    
@job[atomic]
+default::job(Id, Storage, Reward, Start, End, Items)
	: .my_name(vehicle1) & not entrou 
<- 
	+action::reasoning_about_belief(Id);
	+entrou;	
	.print("pedindo ajuda");
	.send(vehicle30,tell,default::help(teste));
	-action::reasoning_about_belief(Id);
	. 
 +default::help(teste)
 	: default::actionID(Id) & default::step(S)
 <-
 	.print("I receive a help request ",S);
 	!action::forget_old_action(Id);
 	.print("I forgot my intention ");
 	+action::committedToAction(Id);
 	!strategies::always_recharge;
 	.print("Recharging ",S);
 	.

