{begin namespace(lNewRound, global)}

+!add_initiator_beliefs
	: true
<-
	+initiator::completed_jobs(0); // debugging
	+initiator::vehicle_job(truck,2);
	+initiator::max_bid_time(10000);
	+initiator::resourceList([]);
	+initiator::free_cars(car,[vehicle1,vehicle2,vehicle3,vehicle4]);
	+initiator::free_drones(drone,[vehicle5,vehicle6,vehicle7,vehicle8,vehicle9,vehicle10,vehicle11,vehicle12]);
	+initiator::free_motos(motorcycle,[vehicle13,vehicle14,vehicle15,vehicle16,vehicle17,vehicle18,vehicle19,vehicle20,vehicle21,vehicle22]);
	+initiator::free_trucks(truck,[vehicle23,vehicle24,vehicle25,vehicle26]);
	+initiator::role_check(0);
	
	+metrics::money(0);
	+metrics::completedJobs(0);
	+metrics::failedJobs(0);
	+metrics::failedFreeJobs(0);
	+metrics::completedAuctions(0);
	+metrics::failedAuctions(0);
	+metrics::lostAuctions(0);
	+metrics::completedMissions(0);
	+metrics::failedMissions(0);
	+metrics::finePaid(0);
	+metrics::failedEvalJobs(0);
	+metrics::noBids(0);
	+metrics::missBidAuction(0);
	
	//!!evaluation_auction::triggerFuturePlan;
	.

{end}

{begin namespace(new, global)}

+!new_round
	: .my_name(Me)
<-
	+chargingList([]);
	+dumpList([]);
	+storageList([]);
	+shopList([]);
	+workshopList([]);
	
	
	+noActionCount(0);
	
	+metrics::noAction(0);
	+metrics::jobHaveWorked(0);
	+metrics::next_actions(0);
	+metrics::jobHaveFailed(0);
	+metrics::missionHaveFailed(0);
	+metrics::auctionHaveFailed(0);
	
	+default::separateItemTool([],[],[]);
	+default::removeDuplicateTool([],[]);
	
	if (Me == vehicle1) { !lNewRound::add_initiator_beliefs; }
	setReady;
	.

@shopList[atomic]
+default::shop(ShopId, Lat, Lon)
	: shopList(List) & not .member(ShopId,List)
<-
	-+shopList([ShopId|List]);
	.

@storageListInit[atomic]
+default::storage(StorageId, Lat, Lon, TotCap, UsedCap, Items)
	: .my_name(vehicle1) & storageList(List) & not .member(StorageId,List)
<-
	createAvailableList(StorageId);
	-+storageList([StorageId|List]);
	.
@storageList[atomic]
+default::storage(StorageId, Lat, Lon, TotCap, UsedCap, Items)
	: storageList(List) & not .member(StorageId,List)
<-
	-+storageList([StorageId|List]);
	.

@chargingList[atomic]
+default::chargingStation(ChargingId,Lat,Lon,Rate) 
	:  chargingList(List) & not .member(ChargingId,List)
<-
	-+chargingList([ChargingId|List]);
	.
	
@workshopList[atomic]
+default::workshop(WorkshopId,Lat,Lon) 
	:  workshopList(List) & not .member(WorkshopId,List)
<- 
	-+workshopList([WorkshopId|List]);
	.

@dumpList[atomic]
+default::dump(DumpId,Lat,Lon) 
	:  dumpList(List) & not .member(DumpId,List)
<- 
	-+dumpList([DumpId|List]);
	.
	
@resource[atomic]
+default::resourceNode(NodeId,Lat,Lon,Item)
	: not default::resNode(NodeId,Lat,Lon,Item)
<-
	addResourceNode(NodeId,Lat,Lon,Item);
	.
	
{end}