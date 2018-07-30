{ include("reasoning-engine.asl") }

// ##### BUILD ACTION #####
// Uses zero (0) parameters to build up an existing well, or one (i) parameter to build a new well
+!buildExistingOne
<-	
	!action::commitAction(build);
	.
+!build(Type)
<-	
    !action::commitAction(build(Type));
	.

// ##### DISMANTLE ACTION #####
// Uses zero (0) parameters to dismantle an existing well. 
+!dismantleWell
<-		
	!action::commitAction(dismantle);
	.



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
// We should not test battery if we are already going to a charging station	
+!goto(FacilityId)
: not .desire(action::go_charge(_)) & new::chargingList(List) & .member(FacilityId,List)
<-	
    !action::commitAction(goto(FacilityId));
	!goto(FacilityId);
	.
// Tests if there is enough battery to go to my goal AND to the nearest charging station around that goal	
+!goto(FacilityId)
: not .desire(action::go_charge(_)) & new::chargingList(List) & rules::closest_facility(List, FacilityId, FacilityId2) & rules::enough_battery(FacilityId, FacilityId2, Result)
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
: not .desire(go_charge(_,_)) & new::chargingList(List) & rules::closest_facility(List, Lat, Lon, FacilityId2) & rules::enough_battery(Lat, Lon, FacilityId2, Result)
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
//& (((Role == truck | Role == car) & C < math.round(CCap / 1.3)) | (Role \== truck & Role \== car & C < CCap))
//not sure if the rule above is still effective, since recharge got nerfed, we will have to test it in the future
+!charge
	: default::charge(C) & default::role(_, _, _, _, _, _, _, _, _, BatteryCap, _) & C < BatteryCap
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
	: default::charge(C) & default::role(_, _, _, _, _, _, _, _, _, BatteryCap, _) & C < math.round(CCap / 5)
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
+!gather(Item)
	: default::role(_, _, _, LoadCap, _, _, _, _, _, _, _) & default::load(Load) & default::item(Item,Vol,_,_) & Load + Vol <= LoadCap
<-
	!action::commitAction(gather);
	!gather(Vol);
	.
+!gather(Item)
<-
	.print("My load is full.");
	.
	
+!gather(Item,NItem)
	: not default::hasItem(Item,_) | (default::hasItem(Item,NItemNew) & NItemNew < NItem)
<-
	!action::commitAction(gather);
	!gather(Item,NItem);
	.
+!gather(Item,NItem).

// Abort
// No parameters
+!abort
	: true
<-
	!action::commitAction(abort);
	.

//  for verifying battery and going to charging stations
+!go_charge(Flat,Flon)
	: new::chargingList(List) & default::lat(Lat) & default::lon(Lon) & default::role(_, Speed, _, _, _, _, _, _, _, BatteryCap, _)
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
		?rules::closest_facility(List,Facility);
		?rules::closest_facility(List,Flat,Flon,FacilityId2);
		?rules::enough_battery2(Facility, Flat, Flon, FacilityId2, Result, BatteryCap);
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
		?rules::closest_facility(Aux2List,Facility);
		?rules::enough_battery_charging(Facility, Result);
		if (Result == "false") {
			?rules::closest_facility(List,FacilityAux);
			?rules::enough_battery_charging2(FacilityAux, Facility, Result2, BatteryCap);
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
			?rules::closest_facility(Aux2List,Flat,Flon,FacilityAux);
			?rules::enough_battery_charging(FacilityAux, ResultAux);
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
	?rules::closest_facility(List,Lat,Lon,Facility);
	?rules::enough_battery_charging(Facility, ResultC);
	if (ResultC == "true") {
		+charge_in(Facility);
	}
	else {
		.delete(Facility,List,ListAux);
		!check_list_charging(ListAux,Lat,Lon);
	}
	.

+!go_charge(FacilityId)
	: new::chargingList(List) & default::lat(Lat) & default::lon(Lon) & rules::getFacility(FacilityId,Flat,Flon,Aux1,Aux2) & default::role(_, Speed, _, _, _, _, _, _, _, BatteryCap, _)
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
		?rules::closest_facility(List2,Facility);
		?rules::closest_facility(List,FacilityId,FacilityId2);
//		?enough_battery_charging2(Facility, FacilityId, Result, BatteryCap);
		?rules::enough_battery2(Facility, FacilityId, FacilityId2, Result, BatteryCap);
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
		?rules::closest_facility(Aux2List,Facility);
		?rules::enough_battery_charging(Facility, Result);
		if (Result == "false") {
			?rules::closest_facility(List2,FacilityAux);
			?rules::enough_battery_charging2(FacilityAux, Facility, Result2, BatteryCap);
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
			?rules::closest_facility(Aux2List,FacilityId,FacilityAux);
			?rules::enough_battery_charging(FacilityAux, ResultAux);
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
	?rules::closest_facility(List,FacilityId,Facility);
	?rules::enough_battery_charging(Facility, ResultC);
	if (ResultC == "true") {
		+charge_in(Facility);
	}
	else {
		.delete(Facility,List,ListAux);
		!check_list_charging(ListAux,FacilityId);
	}
	.
