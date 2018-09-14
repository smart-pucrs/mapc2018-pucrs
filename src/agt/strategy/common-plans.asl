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

+default::well(Well, Lat, Lon, Type, Team, Integrity)
	: default::team(MyTeam) & not .substring(MyTeam, Team) & .my_name(Me) & default::play(Me,builder,g1) & not .desire(build::_)
<-
	!change_role(builder,attacker);
	.print(">>>>>>>>>>>>>>>>>>>> I found a well that doesn't belong to my team ",Id);
	
	!action::forget_old_action;	
	
	!::attack;	
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
	: default::step(S) & S \== 0 & Action == noAction & new::noActionCount(Count)
<-
	-+new::noActionCount(Count+1);
	.print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> Step ",S-1," I have done ",Count+1," noActions.");
	-+metrics::noAction(Count+1);
	.
	
+default::massim(Money)
	: rules::my_role(builder,CurrentRole) & not .desire(build::_) & rules::enough_money
<-
	!action::forget_old_action;
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

@change_role(atomic)
+!change_role(OldRole, NewRole)
	: default::group(_,team,GroupId)
<-
	leaveRole(OldRole)[artifact_id(GroupId)];
	adoptRole(NewRole)[artifact_id(GroupId)];
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
	: default::joined(org,OrgId) & .concat(TaskId,"_gr_",Item,GroupName) & .concat(TaskId,"_",Item,SchemeName) & .my_name(Me)
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
	: default::joined(org,OrgId) & .concat(TaskId,"_gr_",Item,GroupName) & .concat(TaskId,"_",Item,SchemeName)
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

// what attackers do 
+!attack
	: default::well(Well,_,_,_,Team,_) & default::team(MyTeam) & not .substring(MyTeam, Team)
<-
	!attack::dismantle_well(Well);
	-default::well(Well,_,_,_,Team,_)[source(_)];
	!attack;
	.
+!attack
<-
	!change_role(attacker,builder);
	!!build;
	.
	
// what delivery agents do 
+!perform_delivery
	: ::winner(JobId,Deliveries,DeliveryPoint)
<-
	.print("I won the tasks to ",Deliveries," at ",DeliveryPoint);	
	
	!delivery::delivery_job(JobId,Deliveries,DeliveryPoint);
	
	-::winner(JobId,Deliveries,DeliveryPoint);
	
	.print("I've finished my deliveries'");
	!change_role(deliveryagent,gatherer);
	!!strategies::gather;
	.
	
// what gathers do
+!reconsider_gather
	: .desire(action::goto(_,_)) 
<-
	.print("Reconsidering gather");
	!action::forget_old_action;
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
	