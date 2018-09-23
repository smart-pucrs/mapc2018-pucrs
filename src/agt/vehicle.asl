{ include("common-cartago.asl") }
{ include("common-moise.asl") }
{ include("org-obedient.asl", org) }
{ include("action/actions.asl",action) }
{ include("behaviour/build/build.asl",build) }
{ include("behaviour/dismantle/dismantle.asl",attack) }
{ include("common-rules.asl",rules) }
{ include("behaviour/round/new-round.asl") }
{ include("behaviour/gather/gather.asl",gather) }
{ include("behaviour/explore/explore.asl",explore) }
{ include("strategy/common-plans.asl", strategies) }
{ include("behaviour/org/scheme-plans.asl", org) }
{ include("behaviour/stock/stock.asl", stock) }
{ include("behaviour/assemble/assemble.asl", assemble) }
{ include("behaviour/round/end-round.asl") }
{ include("behaviour/delivery/delivery.asl", delivery) }
{ include("behaviour/trade/trade.asl", trade) }
{ include("behaviour/reborn/reborn.asl", reborn) }
	
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

//+default::step(_)
//	: not initiator(_) & .my_name(Me) 
//<-  
//	actions.getAgentNumber(Me,Number);
//	.count(play(_,_,_), NoP);
//	+numberOfPlayers(NoP);
//	+initiator(Number);
//	.
//    
//+default::step(Step)
//	: initiator(Number) & Number == Step 
//<- 	
//	?numberOfPlayers(NoP);
//	-+initiator(Number + NoP);
//	.
//	
//+default::step(Step)
//	: initiator(Number) & Number < Step 
//<-  
//	?numberOfPlayers(NoP);
//	-+initiator(Number + NoP);
//	.

+default::name(ServerMe)
	: .my_name(Me)
<-
	addServerName(Me,ServerMe);
	.

+default::role(Role, BaseSpeed, MaxSpeed, BaseLoad, MaxLoad, BaseSkill, MaxSkill, BaseVision, MaxVision, BaseBattery, MaxBattery)
	: .my_name(Me) & play(Me,MyRole,g1)
<- 
	.wait( default::actionID(S) );
	.wait(500);
	if ( Me == vehicle1 ) {
		?default::map(Map);
		?default::cellSize(CellSize);
		?default::proximity(Proximity);
		initMap(Map,CellSize,Proximity);
		
		for(default::item(Item,_,_,parts([]))){
//			.print("base: ",Item);
			setDesiredBase(Item,1);
		}
		for(default::item(Item,_,_,parts(P)) & P \== []){
//			.print("compound: ",Item);
			setDesiredCompound(Item,1);
		}
	}
	!action::recharge_is_new_skip;
	?default::joined(org,OrgId);
	
	if ( Me \== vehicle1 ) { setMap; }
//	if ( Me == vehicle1 ) { org::createScheme("init_exp", exp, SchArtId)[wid(OrgId)]; }
	!action::recharge_is_new_skip;
	
//	!strategies::set_center_storage_workshop([]);
//	!strategies::set_center_storage_workshop;
	if ( Me == vehicle1 ) { 
		!strategies::set_center_storage_workshop([]); 
		!reborn::synchronise_team_artifact_environment;
	}
	
	!action::recharge_is_new_skip; // had to add skip another step to make sure it works on slower computers
	.wait(strategies::centerStorage(_));
	.wait(strategies::centerWorkshop(_));
	
	// update the code below for a different strategy	
	+strategies::should_become(MyRole);
	if(MyRole == explorer_drone){
		!explore::size_map; 
	}
	if (MyRole == builder){
		!build::choose_minimum_well_price;
		!build::make_well_types_ranking;
	}
	+strategies::team_ready;
	!!strategies::go_back_to_work;
	.print("Everything Set Up!");
    .
    