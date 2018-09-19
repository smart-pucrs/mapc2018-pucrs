!configure_first_strategies.

+!configure_first_strategies
	: true
<-
	.wait( default::actionID(S) & S \== 0 );
	!choose_minimum_well_price;
	.
	
// ### PRINTS ###	
//@printdesirebase[atomic]
//+default::desired_base(DB)
////	: not ::message_base(_)
//<-
//	+::message_base("--- Desired Base: ");
//	for(.member(item(Percent,Item,DesiredQty),DB)){
//		?::message_base(Msg);
//		.concat(Msg,Item,"_",Percent,"%_",DesiredQty," ",String);
//		-+::message_base(String);
//	}
//	?::message_base(Msg);
//	.print(Msg);
//	-::message_base(_);
//	.
//@printdesirecompound[atomic]
//+default::desired_compound(DC)
////	: not ::message_compound(_)
//<-
//	+::message_compound("--- Desired Compound: ");
//	for(.member(item(Percent,Item,DesiredQty),DC)){
//		?::message_compound(Msg);
//		.concat(Msg,Item,"_",Percent,"%_",DesiredQty," ",String);
//		-+::message_compound(String);
//	}
//	?::message_compound(Msg);
//	.print(Msg);
//	-::message_compound(_);
//	.
//@printavailable[atomic]
//+default::available_items(Storage,A)
//<-
//	+::message_available("");
//	for(.member(item(Item,CurrentQty),A)){
//		?::message_available(Msg);
//		.concat(Msg,Item,"_",CurrentQty," ",String);
//		-+::message_available(String);
//	}
//	?::message_available(Msg);
//	.print("--- Available at ",Storage,": ",Msg);
//	-::message_available(_);
//	.
//@printstorage[atomic]
//+default::storage(Storage,_,_,_,_,A)
//<-
//	+::message_storage("");
//	for(.member(item(Item,CurrentQty,Delivered),A)){
//		?::message_storage(Msg);
//		.concat(Msg,Item,"_",CurrentQty," ",String);
//		-+::message_storage(String);
//	}
//	?::message_storage(Msg);
//	.print("--- MAPC at ",Storage,": ",Msg);
//	-::message_storage(_);
//	.
	
+!set_center_storage_workshop
	: default::minLat(MinLat) & default::minLon(MinLon) & default::maxLat(MaxLat) & default::maxLon(MaxLon) & CLat = (MinLat+MaxLat)/2 & CLon = (MinLon+MaxLon)/2 & new::storageList(SList) & new::workshopList(WList) & rules::closest_facility_truck(SList, CLat, CLon, Storage) & rules::closest_facility_truck(WList, Storage, Workshop)
<-
	+centerStorage(Storage);
	+centerWorkshop(Workshop);
	.print("Closest storage from the center is ",Storage);
	.print("Closest workshop from the storage above is ",Workshop);
	.

+default::well(Well,Lat,Lon,Type,Team,Integrity)
	: default::team(MyTeam) & not .substring(MyTeam,Team) & not default::enemyWell(Well,_,_)
<-
	.print(">>>>>>>>>>>>>>>>>>>> I found a well that doesn't belong to my team ",Well);	
	addEnemyWell(Well,Lat,Lon);
	.

+default::resNode(NodeId,Lat,Lon,Item)
	: not ::analysing_resource & .findall(Item,default::resNode(_,_,_,Item),List) & .length(List)==1 & .my_name(Me) & default::play(Me,gatherer,g1)
<- 
	+::analysing_resource;
	.print("Found resource node: ",NodeId," for item: ",Item,", I can go there");
	.wait({+default::actionID(_)});
	!!reconsider_gather;
	-::analysing_resource;
	.
+default::resNode(NodeId,Lat,Lon,Item)
<- 
	.print("Found resource node: ",NodeId," for item: ",Item);
	.

+default::lastAction(Action)
	: Action \== noAction
<-
	-+::noActionCount(0);
	.
+default::lastAction(Action)
	: default::step(S) & S \== 0 & Action == noAction & new::noActionCount(Count)
<-
	-+new::noActionCount(Count+1);
	.print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> Step ",S-1," I have done ",Count+1," noActions.");
	-+metrics::noAction(Count+1);
	if (::noActionCount(C) & C+1 < 3){
		-+::noActionCount(C+1);
	} else{
		-+::noActionCount(0);
		.print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> I died");
//		!reborn::revive;
	}
	.
	
+default::massim(Money)
	: rules::my_role(builder,CurrentRole) & not .desire(build::_) & rules::enough_money
<-
	!action::forget_old_action;
 	+action::committedToAction(Id);
	
	!build;
	.

+!always_recharge <- !action::recharge_is_new_skip; !always_recharge.

+!change_role(OldRole,NewRole)
	: OldRole == NewRole
<-
	.print("I'm already ",NewRole);
	.
//@change_role(atomic)
+!change_role(OldRole, NewRole)
	: .my_name(Me) & default::group(_,team,GroupId)
<-
	.print("I was ",OldRole," becoming ",NewRole);
	leaveRole(OldRole)[artifact_id(GroupId)];
	adoptRole(NewRole)[artifact_id(GroupId)];
	.wait(default::play(Me,NewRole,g1));
	.
	
// how do we pick a minimum money to start building wells
+!choose_minimum_well_price
	: .findall(Cost,default::wellType(_,Cost,_,_,_),Wells) & .sort(Wells,SortedWells) & .nth(0,SortedWells,MinimumCost)
<-
	-+minimum_money(MinimumCost);
	.
	
// ### AWARD ###
+default::winner(Me,assembly,Duty,Tasks,TaskId)
	: .my_name(Me) & default::joined(org,OrgId) & .term2string(TaskId,STaskId) & default::play(Me,CurrentRole,g1)
<-
//	+action::reasoning_about_belief(TaskId);
	+::winner(Me,assembly,Duty,Tasks,TaskId);
	-default::winner(Me,assembly,Duty,Tasks,TaskId);
	.print("*************************************************** I'm winner ",TaskId," ",Duty," ",Tasks);

	!action::forget_old_action;
	.drop_desire(::gather(_));
//	.drop_desire(explore::_);
	
 	!change_role(CurrentRole,assembler);

 	!prepare_assembly(TaskId,Duty);
// 	-action::reasoning_about_belief(TaskId);
	.
+!prepare_assembly(TaskId,[]).
+!prepare_assembly(TaskId,[assemble(Item,Qty)|Duty])
//	: default::joined(org,OrgId) & .concat(TaskId,"_gr_",Item,GroupName) & .concat(TaskId,"_",Item,SchemeName) & .my_name(Me)
	: default::joined(org,OrgId) & .concat(TaskId,"_",Item,"_group",GroupName) & .concat(TaskId,"_",Item,SchemeName) & .my_name(Me)
<-
	org::createGroup(GroupName, manufactory, GroupId)[artifact_id(OrgId)];
	org::focus(GroupId)[wid(OrgId)];
	org::adoptRole(assembler)[artifact_name(GroupName)];
	org::createScheme(SchemeName, assembly, SchArtId)[wid(OrgId)];	
	org::setArgumentValue(item_manufactured,"Item",Item)[artifact_id(SchArtId)];
	org::setArgumentValue(item_manufactured,"Qty",Qty)[artifact_id(SchArtId)];
	org::focus(SchArtId)[wid(OrgId)];
	org::addScheme(SchemeName)[artifact_name(GroupName)];
	org::commitMission(mretrieve)[artifact_id(SchArtId)];
	org::commitMission(massemble)[artifact_id(SchArtId)];
   	!prepare_assembly(TaskId,Duty);
	.
+!prepare_assembly(TaskId,[assist(Assembler,Item)|Duty])
//	: default::joined(org,OrgId) & .concat(TaskId,"_gr_",Item,GroupName) & .concat(TaskId,"_",Item,SchemeName)
	: default::joined(org,OrgId) & .concat(TaskId,"_",Item,"_group",GroupName) & .concat(TaskId,"_",Item,SchemeName)
<-	
	org::focusWhenAvailable(GroupName)[wid(OrgId)];
	org::adoptRole(assistant)[artifact_name(GroupName),wid(OrgId)];
	org::focusWhenAvailable(SchemeName)[wid(OrgId)];
	org::commitMission(mretrieve)[artifact_name(SchemeName),wid(OrgId)];
	org::commitMission(massist)[artifact_name(SchemeName),wid(OrgId)];
   	!prepare_assembly(TaskId,Duty);
	.
	
+default::winner(TaskId,Tasks,DeliveryPoint)
	: .my_name(Me) & default::joined(org,OrgId) & default::play(Me,CurrentRole,g1)
<-
	+::winner(TaskId,Tasks,DeliveryPoint);
	-default::winner(TaskId,Tasks,DeliveryPoint);
	.print("*************************************************** I'm winner ",TaskId," ",Tasks," at ",DeliveryPoint);
	
	!change_role(CurrentRole,deliveryagent);
	
	!action::forget_old_action;
	.drop_desire(::gather(_));
 	
 	.print("I was a ",CurrentRole);	
	
	!perform_delivery;
	.	
-default::job(JobId,Storage,Reward,Start,End,Items)
	: ::winner(JobId,_,_) & default::lastAction(LastAction) & .substring("deliver_job",LastAction) & default::lastActionResult(successful_partial)
<-
	.print("### I've delivered my part of Priced Job ",JobId," ###");
	.
-default::job(JobId,Storage,Reward,Start,End,Items)
	: ::winner(JobId,_,_) & default::lastAction(LastAction) & .substring("deliver_job",LastAction) & default::lastActionResult(successful)
<-
	.print("### Priced Job ",JobId," Done, ",Reward,"$ in cash ###");
//	-::winner(JobId,_,_);
	.
-default::job(JobId,_,Reward,Start,End,Items)
	: ::winner(JobId,_,_)
<-
	.print("### Priced Job ",JobId," has FAILED");
	!recover_delivery(JobId);
	.

-default::mission(MissionId,_,_,_,End,Fine,_,_,Items)
	: default::step(Step) & Step > End // the mission could be deliveried at the final step, then this context is wrong
<-
	.print("### Mission ",MissionId," has FAILED, ",Fine,"$ we have to pay ### ",Items);
	if (::winner(MissionId,_,_)){
		!recover_delivery(MissionId);
	}
	.
-default::mission(MissionId,_,Reward,_,_,_,_,_,_)
<-
	.print("### Mission ",MissionId," Done, ",Reward,"$ in cash ###");
//	-::winner(JobId,_,_);
	.
	
+!go_back_to_work
	: .my_name(Me) & default::play(Me,gatherer,g1)
<-
	!!gather;
	.
+!go_back_to_work
	: .my_name(Me) & default::play(Me,explorer_drone,g1)
<-
//	!!explore::size_map; 
	!!explore::go_walk;
	.
+!go_back_to_work
	: .my_name(Me) & default::play(Me,builder,g1)
<-
	!!strategies::build;
	.
	
// ### WHAT BUILDERS DO ###
select_random_facility(Facility)
:-
//	new::chargingList(CList) &
	new::dumpList(DList) &
	new::storageList(StList) &
	new::shopList(ShList) & 
	new::workshopList(WList) &
//	.concat(CList,DList,StList,ShList,WList,AllList) &
	.concat(DList,StList,ShList,WList,AllList) &
	.shuffle(AllList,List) &
	.nth(0,List,Facility)
	.
+!build 
	: default::enemyWell(Well,_,_)
<-
	.print("I was a builder, but there is an enemy well ",Well,", going to destroy it");
	!change_role(builder,attacker);	
	!!::attack;
	.
+!build 
	: 	new::chargingList(CList) & 
		rules::closest_facility(CList,Facility) & 
		default::charge(Charge) & 
		rules::my_route_closest_facility(CList,Facility,Route) &
		Route >= Charge+2
<-
	.print(Route," steps to the closest charging station ",Facility," but my charge is ",Charge,", going to recharge");
	!action::goto(Facility);
	!action::charge;
	!build;
	.
+!build 
//	: not rules::enough_money & new::chargingList(List) & rules::farthest_facility(List, Facility)
	: not rules::enough_money & select_random_facility(Facility)
<-
//	.print("Going to my farthest charging station",Facility," to explore");
	.print("Going to ",Facility," to explore");
	!action::goto(Facility);
//	!action::charge;
	!build;
	.
+!build
<-
	!build::buy_well; 	
	!build;
	.

// ### WHAT ATTACKERS DO ###
//+!attack
//	: default::well(Well,_,_,_,Team,_) & default::team(MyTeam) & not .substring(MyTeam, Team)
//<-
//	!attack::dismantle_well(Well);
//	-default::well(Well,_,_,_,Team,_)[source(_)];
//	!attack;
//	.
+default::enemyWell(Well,Lat,Lon)
	:  not ::becoming_atacker & ::team_ready & .my_name(Me) & default::play(Me,Role,g1) & ((Role==builder & not .desire(build::_)) | (Role==gatherer))
<-	
	+::becoming_atacker;
	.print("Some teammate has discovered a well ",Well," at ",Lat," ",Lon,", becoming attacker");	
	!become_attacker(Role);
	-::becoming_atacker;
	.
-default::enemyWell(Well,_,_)
	: .desire(attack::dismantle_well(Well))
<-
	.print("I was going to dismantle ",Well,", but it's not necessary anymore");
	.wait({+default::actionID(_)});
	!!reconsider_attack(Well);
	.
+!become_attacker(Role)
<-
	!change_role(Role,attacker);	
	!action::forget_old_action;	
	!!::attack;	
	.
+!reconsider_attack(Well)
	: .my_name(Me) & default::play(Me,attacker,g1) & .desire(attack::dismantle_well(Well)) & .desire(action::goto(_,_))
<-
	.print("Reconsidering attack");
	!action::forget_old_action;	
	!action::clean_route;
	!::attack;
	.
+!reconsider_attack(Well).
+!attack
	: default::enemyWell(Well,_,_)
<-
	.print("I'm going to attack ",Well);
	!attack::dismantle_well(Well);
	removeEnemyWell(Well);
	!attack;
	.
+!attack
	: ::should_become(Role)
<-
	!change_role(attacker,Role);
	!go_back_to_work;
	.
	
// ### WHAT DELIVERY AGENTS DO ###
+!perform_delivery
	: ::winner(JobId,Deliveries,DeliveryPoint)
<-
	.print("I won the tasks to ",Deliveries," at ",DeliveryPoint);	
	
	!delivery::delivery_job(JobId,Deliveries,DeliveryPoint);
	
	-::winner(JobId,Deliveries,DeliveryPoint);
	
	.print("I've finished my deliveries'");
	?::should_become(Role);
	!change_role(deliveryagent,Role);
	!go_back_to_work;
	.
+!recover_delivery(JobId)
<-
	!action::forget_old_action;
	
	!give_back_delivery;
	
	-::winner(JobId,_,_);
	
	?::should_become(Role);
	!change_role(deliveryagent,Role);
	!go_back_to_work;
	.
+!give_back_delivery
	: default::hasItem(_,_) & strategies::centerStorage(Storage) 
<-
	.print("I'm carrying some items, going to store ");
	!stock::store_all_items(Storage);
	.
+!give_back_delivery
<-
	.print("I have to do nothing");
	.
	
// ### WHAT GATHERS DO ###
+!reconsider_gather
	: .my_name(Me) & default::play(Me,gatherer,g1) & .desire(action::goto(_,_))
<-
	.print("Reconsidering gather");
	!action::forget_old_action;
	!action::clean_route;
	!gather;
	.
+!reconsider_gather.
+!gather
	: rules::select_resource_node(SelectedResource) & .literal(SelectedResource)
<-
	!gather(SelectedResource);
	.
+!gather <- !gather::initial_gather.
+!gather(ResourceNode)
	: default::resNode(ResourceNode,Lat,Lon,Base) & strategies::centerStorage(Storage)
<-
	.print("Going to resource node ",ResourceNode," to gather ",Base);
	!action::goto(Lat,Lon);
	!gather::gather_full(Base);
	.print("Going to storage ",Storage," to store items");
	!action::goto(Storage);
	!stock::store_all_items(Storage);
	!gather;
	.
	