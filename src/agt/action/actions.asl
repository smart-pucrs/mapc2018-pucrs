	//{begin namespace(action, local)}

+!commitAction(Action)
	: default::actionID(S) & not action::action(S) & not action::hold_action(_)
<-
	+action::action(S);
//	.print("Doing action ",Action, " at step ",S," . Waiting for step ",S+1);
	if ( Action \== recharge & Action \== continue) {
		.print("Doing action ",Action, " at step ",S," . Waiting for step ",S+1);
	}
	action(Action);
	.wait( default::actionID(S2) & S2 \== S );
//	.print("Got out of wait from step ",S);
	?default::lastActionResult(Result);
//	.print("Last action result was: ",Result);
//	.wait( default::lastActionResult(Result) );
	-action::action(S);
		
	if (Action \== recharge & Action \== continue & not .substring("deliver",Action) & not .substring("assist_assemble",Action) & not .substring("buy",Action) & not .substring("bid_for_job",Action) & Result \== successful) {
//		.print("Failed to execute action ",Action," at step ",S," due to the 1% random error. Executing it again.");
		!commitAction(Action);
	}
	else {
		if (.substring("deliver",Action) & Result == failed ) { !commitAction(Action); }
		if (.substring("deliver",Action) & Result \== failed_job_status & default::winner(_, assemble(_, JobId, _))) { +strategies::jobDone(JobId); }
		if (action::next_action(Action2)) {
			-action::next_action(Action2);
//			.print("Removing next action ",Action2);
		}
		else { 
			if (strategies::free) { !!action::recharge_is_new_skip; }
		}
	}
	.
+!commitAction(Action) 
	: action::hold_action(_)
<- 
//	.print("Holding action ",Action);
	.wait(50);
//	.print("Trying action ",Action," again now.");
	!commitAction(Action);
	.
+!commitAction(Action) : Action == recharge.
+!commitAction(Action) 
	: Action \== recharge & metrics::next_actions(C) & not action::next_action(_)
<- 
	+action::next_action(Action); 
	-+metrics::next_actions(C+1); 
//	.print("Next action ",Action); 
	.wait( {-action::next_action(Action) }); 
	!commitAction(Action);
.
//+!commitAction(Action) <- .print("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ NO ",Action).
//{end}

// Goto (option 1)
// FacilityId must be a string
+!goto(FacilityId) : default::facility(FacilityId).
+!goto(FacilityId)
	: default::charge(0)
<-
	!recharge;
	!goto(FacilityId);
	.
+!goto(FacilityId)
	: default::routeLength(R) & R \== 0
<-	
	!continue;
	!goto(FacilityId);
	.
// Tests if there is enough battery to go to my goal AND to the nearest charging station around that goal	
+!goto(FacilityId)
: not .desire(action::go_charge(_)) & new::chargingList(List) & default::closest_facility(List, FacilityId, FacilityId2) & default::enough_battery(FacilityId, FacilityId2, Result)
<-	
    if (Result == "false") { !go_charge(FacilityId); }
    else { !action::commitAction(goto(FacilityId)); }
	!goto(FacilityId);
	.
//+!goto(FacilityId)
//	: true
//<-	
//	!action::commitAction(goto(FacilityId));
//	!goto(FacilityId);
//	.

// Goto (option 2)
// Lat and Lon must be floats
+!goto(Lat, Lon) : going(Lat,Lon) & default::routeLength(R) & R == 0 <- -going(Lat,Lon).
+!goto(Lat, Lon)
	: default::charge(0)
<-
	!recharge;
	!goto(Lat, Lon);
	.
+!goto(Lat, Lon)
	: going(Lat,Lon) & default::routeLength(R) & R \== 0
<-	
	!continue;
	!goto(Lat, Lon);
	.
// Tests if there is enough battery to go to my goal AND to the nearest charging station around that goal	
+!goto(Lat, Lon)
: not .desire(go_charge(_,_)) & new::chargingList(List) & default::closest_facility(List, Lat, Lon, FacilityId2) & default::enough_battery(Lat, Lon, FacilityId2, Result)
<-	
    if (Result == "false") { !go_charge(Lat, Lon); }
    else { +going(Lat,Lon); !action::commitAction(goto(Lat,Lon)); }
	!goto(Lat, Lon);
	.
//+!goto(Lat, Lon)
//	: true
//<-
//	+going(Lat,Lon);
//	!action::commitAction(goto(Lat,Lon));
//	!goto(Lat, Lon);
//	.
	
// Charge
// No parameters
+!charge
	: default::charge(C) & default::role(Role,_,_,CCap,_) & (((Role == truck | Role == car) & C < math.round(CCap / 1.3)) | (Role \== truck & Role \== car & C < CCap))
<-
	!action::commitAction(charge);
	!charge;
	.
-!charge.

// Buy
// ItemId must be a string
// Amount must be an integer
+!buy(ItemId, Amount)
	: default::hasItem(ItemId,OldAmount)
<-	
	!buy_loop(ItemId, Amount, Amount, OldAmount);
	.
+!buy(ItemId, Amount)
	: true
<-	
	!buy_loop(ItemId, Amount, Amount, 0);
	.
+!buy_loop(ItemId, Total, Amount, OldAmount)
	: not default::hasItem(ItemId, Total+OldAmount) & default::facility(ShopId) & default::shop(ShopId, _, _, _, ListItems) & .member(item(ItemId,_,QtyAvailable,_,_,_),ListItems)
<-
	if (Amount <= QtyAvailable) {
//		.print("Trying to buy all.");
		!action::commitAction(buy(ItemId,Amount));
		if ( default::lastActionResult(successful) ) { !buy_loop(ItemId, Total, Total - Amount, OldAmount); }
		else { !buy_loop(ItemId, Total, Amount, OldAmount); }
	}
	else {
		if (QtyAvailable == 0) {
			!action::commitAction(recharge);
			!buy_loop(ItemId, Total, Amount, OldAmount);
			
		}
		else {
//			.print("Trying to buy available ",QtyAvailable);
			!action::commitAction(buy(ItemId,QtyAvailable));
			if ( default::lastActionResult(successful) ) { !buy_loop(ItemId, Total, Amount - QtyAvailable, OldAmount); }
			else { !buy_loop(ItemId, Total, Amount, OldAmount); }
		}
	}
	.
-!buy_loop(ItemId, Total, Amount, OldAmount). //: default::hasItem(ItemId, Qty) <- .print("Finished buy, I have: #",Qty," of ",ItemId).

// Give
// AgentId must be a string
// ItemId must be a string
// Amount must be an integer
+!give(AgentName, ItemId, Amount)
	: true
<-
	getServerName(AgentName,ServerName);
	?default::hasItem(ItemId, OldAmount);
	!action::commitAction(give(ServerName,ItemId,Amount));
	!giveLoop(ServerName, ItemId, Amount, OldAmount);
	.
+!giveLoop(AgentId, ItemId, Amount, OldAmount)
	: default::hasItem(ItemId,OldAmount)
<-
	!action::commitAction(give(AgentId,ItemId,Amount));
	!giveLoop(AgentId, ItemId, Amount, OldAmount);
	.
-!giveLoop(AgentId, ItemId, Amount, OldAmount).

// Receive
// No parameters
+!receive(ItemId,Amount)
	: default::hasItem(ItemId,OldAmount)
<-
	-strategies::free[source(_)];
	!action::commitAction(receive);
	!receiveLoop(ItemId,Amount,OldAmount);
	.
+!receive(ItemId,Amount)
	: true
<-
	-strategies::free[source(_)];
	!action::commitAction(receive);
	!receiveLoop(ItemId,Amount,0);
	.
+!receiveLoop(ItemId, Amount, OldAmount)
	: not default::hasItem(ItemId,Amount+OldAmount)
<-
	!action::commitAction(receive);
	!receiveLoop(ItemId, Amount, OldAmount);
	.
-!receiveLoop(ItemId,Amount,OldAmount).

// Store
// ItemId must be a string
// Amount must be an integer
+!store(ItemId, Amount)
	: true
<-
	!action::commitAction(store(ItemId,Amount));
	.

// Retrieve
// ItemId must be a string
// Amount must be an integer
+!retrieve(ItemId, Amount)
	: true
<-
	!action::commitAction(retrieve(ItemId,Amount));
	.

// Retrieve delivered
// ItemId must be a string
// Amount must be an integer
+!retrieve_delivered(ItemId, Amount)
	: true
<-
	!action::commitAction(
		retrieve_delivered(
			item(ItemId),
			amount(Amount)
		)
	);
	.

// Dump
// ItemId must be a string
// Amount must be an integer
+!dump(ItemId, Amount)
	: true
<-
	!action::commitAction(dump(ItemId,Amount));
	.

// Assemble
// ItemId must be a string
+!assemble(ItemId)
	: default::hasItem(ItemId,OldAmount)
<-
	!action::commitAction(assemble(ItemId));
	!assembleLoop(ItemId,1,OldAmount);
	.
+!assemble(ItemId)
	: true
<-
	!action::commitAction(assemble(ItemId));
	!assembleLoop(ItemId,1,0);
	.
+!assembleLoop(ItemId, Amount, OldAmount)
	: not default::hasItem(ItemId,Amount+OldAmount)
<-
	!action::commitAction(assemble(ItemId));
	!assembleLoop(ItemId, Amount, OldAmount);
	.
-!assembleLoop(ItemId,Amount,OldAmount).

// Assist assemble
// AgentId must be a string
+!assist_assemble(AgentName)
	: true
<-
	getServerName(AgentName,ServerName);
	!assist_assemble_loop(ServerName);
	.
+!assist_assemble_loop(ServerName)
	: strategies::assembling
<-
	!action::commitAction(assist_assemble(ServerName));
	!assist_assemble_loop(ServerName);
	.
+!assist_assemble_loop(ServerName).
	
// Deliver job
// JobId must be a string
+!deliver_job(JobId)
	: true
<-
	!action::commitAction(deliver_job(JobId));
	.

// Bid for job
// JobId must be a string
// Price must be an integer
+!bid_for_job(JobId, Price)
	: true
<-
	!action::commitAction(bid_for_job(JobId,Price));
	.

// Post job (option 1)
// MaxPrice must be an integer
// Fine must be an integer
// ActiveSteps must be an integer
// AuctionSteps must be an integer
// StorageId must be a string
// Items must be a string "item1=item_id1 amount1=10 item2=item_id2 amount2=5 ..."
// Example: !post_job_auction(1000, 50, 1, 10, storage1, [item(base1,1), item(material1,2), item(tool1,3)]);
+!post_job_auction(MaxPrice, Fine, ActiveSteps, AuctionSteps, StorageId, Items)
	: true
<-
	!action::commitAction(
		post_job(
			type(auction),
			max_price(MaxPrice),
			fine(Fine),
			active_steps(ActiveSteps),
			auction_steps(AuctionSteps), 
			storage(StorageId),
			Items
		)
	);
	.

// Post job (option 2)
// Price must be an integer
// ActiveSteps must be an integer
// StorageId must be a string
// Items must be a string "item1=item_id1 amount1=10 item2=item_id2 amount2=5 ..."
// Example: !post_job_priced(1000, 50, storage1, [item(base1,1), item(material1,2), item(tool1,3)]);
+!post_job_priced(Price, ActiveSteps, StorageId, Items)
	: true
<-
	!action::commitAction(
		post_job(
			type(priced),
			price(Price),
			active_steps(ActiveSteps), 
			storage(StorageId),
			Items
		)
	);
	.

// Continue
// No parameters
+!continue
	: true
<-
	!action::commitAction(continue);
	.

// Skip
// No parameters
+!skip
	: true
<-
	!action::commitAction(skip);
	.
	
// Recharge
// No parameters
+!recharge
	: default::charge(C) & default::role(_,_,_,CCap,_) & C < math.round(CCap / 5)
<-
	!action::commitAction(recharge);
	!recharge;
	.
-!recharge <- .print("Fully recharged.").

// Recharge New Skip
// No parameters
+!recharge_is_new_skip
	: true
<-
	!action::commitAction(recharge);
	.
	
// Gather
// No parameters
+!gather(Vol)
	: default::role(_,_,LoadCap,_,_) & default::load(Load) & Load + Vol <= LoadCap
<-
	!action::commitAction(gather);
	!gather(Vol);
	.
-!gather(Vol).

// Abort
// No parameters
+!abort
	: true
<-
	!action::commitAction(abort);
	.

//  for verifying battery and going to charging stations
+!go_charge(Flat,Flon)
	: new::chargingList(List) & default::lat(Lat) & default::lon(Lon) & default::role(_, Speed, _, BatteryCap, _)
<-
	+onMyWay([]);
	for(.member(ChargingId,List)){
		?default::chargingStation(ChargingId,Clat,Clon,_);
		if(math.sqrt((Lat-Flat)**2+(Lon-Flon)**2)>(math.sqrt((Lat-Clat)**2+(Lon-Clon)**2)) & math.sqrt((Lat-Flat)**2+(Lon-Flon)**2)>(math.sqrt((Clat-Flat)**2+(Clon-Flon)**2))){
			?onMyWay(AuxList);
			-onMyWay(AuxList);
			+onMyWay([ChargingId|AuxList]);
		}
	}
	?onMyWay(Aux2List);
	if(.empty(Aux2List)){
		?default::closest_facility(List,Facility);
		?default::closest_facility(List,Flat,Flon,FacilityId2);
		?default::enough_battery2(Facility, Flat, Flon, FacilityId2, Result, BatteryCap);
		if (Result == "false") {
			+impossible;
			.print("@@@@ Impossible route, going to try anyway.");
			+going(Flat,Flon);
			!action::commitAction(goto(Flat,Flon));
			!goto(Flat,Flon);
		}
		else {
			FacilityAux2 = Facility;
			.print("There is no charging station between me and my goal, going to the nearest one.");
		}
	}
	else{
		?default::closest_facility(Aux2List,Facility);
		?default::enough_battery_charging(Facility, Result);
		if (Result == "false") {
			?default::closest_facility(List,FacilityAux);
			?default::enough_battery_charging2(FacilityAux, Facility, Result2, BatteryCap);
			if (Result2 == "false") {
				+impossible;
				.print("@@@@ Impossible route, going to try anyway and hopefully call service breakdown.");
				+going(Flat,Flon);
				!action::commitAction(goto(Flat,Flon));
				!goto(Flat,Flon);
			}
			else {
				FacilityAux2 = FacilityAux;
				.print("There is no charging station between me and my goal, going to the nearest one.");
			}
		}
		else {
			?default::closest_facility(Aux2List,Flat,Flon,FacilityAux);
			?default::enough_battery_charging(FacilityAux, ResultAux);
			if (ResultAux == "true") {
				FacilityAux2 = FacilityAux;
			}
			else {
				.delete(FacilityAux,Aux2List,Aux2List2);
				!check_list_charging(Aux2List2,Flat,Flon);
				?charge_in(FacAux);
				-charge_in(FacAux);
				FacilityAux2 = FacAux;
			}
		}
	}
	-onMyWay(Aux2List);
	if (not action::impossible) {
		.print("**** Going to charge my battery at ", FacilityAux2);
		!action::commitAction(goto(FacilityAux2));
		!goto(FacilityAux2);
		!charge;		
	}
	else {
		-impossible;
	}
	.
+!check_list_charging(List,Lat,Lon)
<-
	?default::closest_facility(List,Lat,Lon,Facility);
	?default::enough_battery_charging(Facility, ResultC);
	if (ResultC == "true") {
		+charge_in(Facility);
	}
	else {
		.delete(Facility,List,ListAux);
		!check_list_charging(ListAux,Lat,Lon);
	}
	.
+!go_charge(FacilityId)
	: new::chargingList(List) & default::lat(Lat) & default::lon(Lon) & default::getFacility(FacilityId,Flat,Flon,Aux1,Aux2) & default::role(_, Speed, _, BatteryCap, _)
<-
	+onMyWay([]);
	?default::facility(Fac);
	if (.member(Fac,List)) {
		.delete(Fac,List,List2);
	}
	else {
		List2 = List;
	}
	for(.member(ChargingId,List2)){
		?default::chargingStation(ChargingId,Clat,Clon,_);
		if(math.sqrt((Lat-Flat)**2+(Lon-Flon)**2)>(math.sqrt((Lat-Clat)**2+(Lon-Clon)**2)) & math.sqrt((Lat-Flat)**2+(Lon-Flon)**2)>(math.sqrt((Clat-Flat)**2+(Clon-Flon)**2))){
			?onMyWay(AuxList);
			-onMyWay(AuxList);
			+onMyWay([ChargingId|AuxList]);
		}
	}
	?onMyWay(Aux2List);
	if(.empty(Aux2List)){
		?default::closest_facility(List2,Facility);
		?default::closest_facility(List,FacilityId,FacilityId2);
//		?enough_battery_charging2(Facility, FacilityId, Result, BatteryCap);
		?default::enough_battery2(Facility, FacilityId, FacilityId2, Result, BatteryCap);
		if (Result == "false") {
			+impossible;
			.print("@@@@ Impossible route, going to try anyway.");
			!action::commitAction(goto(FacilityId));
			!goto(FacilityId);
		}
		else {
			FacilityAux2 = Facility;
			.print("There is no charging station between me and my goal, going to the nearest one.");
		}
	}
	else{
		?default::closest_facility(Aux2List,Facility);
		?default::enough_battery_charging(Facility, Result);
		if (Result == "false") {
			?default::closest_facility(List2,FacilityAux);
			?default::enough_battery_charging2(FacilityAux, Facility, Result2, BatteryCap);
			if (Result2 == "false") {
				+impossible;
				.print("@@@@ Impossible route, going to try anyway and hopefully call service breakdown.");
				!action::commitAction(goto(FacilityId));
				!goto(FacilityId);
			}
			else {
				FacilityAux2 = FacilityAux;
				.print("There is no charging station between me and my goal, going to the nearest one.");
			}
		}
		else {
			?default::closest_facility(Aux2List,FacilityId,FacilityAux);
			?default::enough_battery_charging(FacilityAux, ResultAux);
			if (ResultAux == "true") {
				FacilityAux2 = FacilityAux;
			}
			else {
				.delete(FacilityAux,Aux2List,Aux2List2);
				!check_list_charging(Aux2List2,FacilityId);
				?charge_in(FacAux);
				-charge_in(FacAux);
				FacilityAux2 = FacAux;
			}
		}
	}
	-onMyWay(Aux2List);
	if (not action::impossible) {
		.print("**** Going to charge my battery at ", FacilityAux2);
		!action::commitAction(goto(FacilityAux2));
		!goto(FacilityAux2);
		!charge;		
	}
	else {
		-impossible;
	}
	.
+!check_list_charging(List,FacilityId)
<-
	?default::closest_facility(List,FacilityId,Facility);
	?default::enough_battery_charging(Facility, ResultC);
	if (ResultC == "true") {
		+charge_in(Facility);
	}
	else {
		.delete(Facility,List,ListAux);
		!check_list_charging(ListAux,FacilityId);
	}
	.
