+default::task(item(ItemId, Qty), CNPBoard, TaskId)[source(X)]
	: .my_name(Me)
<- 
	-default::task(item(ItemId, Qty), CNPBoard, TaskId)[source(X)];
    !create_bid_task(item(ItemId, Qty), Bid, Shop);
    bid(Me, Bid, Shop, item(ItemId, Qty), TaskId)[artifact_name(CNPBoard)];
  	.
-default::task(item(ItemId, Qty), CNPBoard, TaskId)[source(X)].
+default::task(tool(ItemId), CNPBoard, TaskId)[source(X)]
	: .my_name(Me)
<- 
	-default::task(tool(ItemId), CNPBoard, TaskId)[source(X)];
  	!create_bid_task(tool(ItemId), Bid, Shop);
	bid(Me, Bid, Shop, tool(ItemId), TaskId)[artifact_name(CNPBoard)];
	.
-default::task(tool(ItemId), CNPBoard, TaskId)[source(X)].
+default::task(assemble(StorageId, Items), CNPBoard, TaskId)[source(X)]
	: .my_name(Me)
<- 
	-default::task(assemble(StorageId, Items), CNPBoard, TaskId)[source(X)];
	!create_bid_task(assemble(StorageId, Items), Bid, Shop);
	bid(Me, Bid, Shop, assemble(StorageId), TaskId)[artifact_name(CNPBoard)];
	.
-default::task(assemble(StorageId, Items), CNPBoard, TaskId)[source(X)].

+!create_bid_task(item(ItemId, Qty), Bid, Shop)
	: default::load(MyLoad) & default::role(Role, Speed, LoadCap, _, Tools) & default::item(ItemId,Vol,_,_) & new::shopList(SList) 
<-
	if (LoadCap - MyLoad >= Vol * Qty) {
		.findall(Storage,default::available_items(StorageS,AvailableItemsS) & not .empty(AvailableItemsS) & default::convertListString2Term(AvailableItemsS,[],AvailableItems) & .member(item(ItemId,AvailableQty),AvailableItems) & AvailableQty >= Qty & .term2string(Storage,StorageS),StorageList);
//		.print(StorageList," for task #",Qty," of ",ItemId);
		if ( not .empty(StorageList) ) {
			actions.closest(Role,StorageList,Facility);
			actions.route(Role,Speed,Facility,Route);
		}
		else {
			?default::find_shop_qty(item(ItemId, Qty),SList,Buy,99999,Route,99999,"",Facility,99999);
		}
//		.print("The lowest amount of buy actions that I need to buy ",Qty,"# of",ItemId," is ",Buy," in ",Shop);
//		.print("####### Route: ",Route," role ",Role);
		Bid = Route;
		Shop = Facility;
	}
	else { Bid = -1; Shop = null; }
	.
+!create_bid_task(tool(ItemId), Bid, Shop)
	: default::role(Role, Speed, LoadCap, _, Tools) & default::load(MyLoad) & default::item(ItemId,Vol,_,_) & new::shopList(SList)
<-
	if (.member(ItemId,Tools) & LoadCap - MyLoad >= Vol) {
		.findall(Storage,default::available_items(StorageS,AvailableT) & .term2string(ItemId,ToolS) & .substring(ToolS,AvailableT) & .term2string(Storage,StorageS),StorageList);
		if ( StorageList \== [] ) {
			actions.closest(Role,StorageList,Facility);
			actions.route(Role,Speed,Facility,Route);
		}
		else {
			?default::find_shops(ItemId,SList,Shops);
			actions.closest(Role,Shops,Facility);
			actions.route(Role,Speed,Facility,Route);
		}
//		.print("####### Route: ",Route," role ",Role);
		for ( default::tools(_,T) ) {
			if (Role == drone & .member(ItemId,T) & not multiple_roles) { +multiple_roles }
		}
		if (multiple_roles) { -multiple_roles; Bid = Route*100; }
		else { Bid = Route; }
		Shop = Facility;
	}
	else { Bid = -1; Shop = null; }
	.
+!create_bid_task(assemble(StorageId, Items), Bid, Shop)
	: default::role(Role, Speed, LoadCap, _, _) & new::workshopList(WList) & default::load(MyLoad) & default::total_load(Items,0,Vol)
<-
	if (LoadCap - MyLoad >= Vol) {
		actions.closest(Role,WList,StorageId,ClosestWorkshop);
		actions.route(Role,Speed,ClosestWorkshop,RouteWorkshop);
//		.print("####### Route: ",RouteWorkshop," role ",Role);
		Bid = RouteWorkshop;
		Shop = StorageId;
	}
	else { Bid = -1; Shop = null; }
	.
+!create_bid_task(Task, Bid, Shop) <- .wait(500); !create_bid_task(Task, Bid, Shop).
	
+default::winner(TaskList, assist(Storage, Assembler, JobId))
	: default::joined(org,OrgId) & metrics::jobHaveWorked(Jobs)
<-
	!strategies::not_free;
	-+metrics::jobHaveWorked(Jobs+1);
	lookupArtifact(JobId,SchArtId)[wid(OrgId)];
	org::focus(SchArtId)[wid(OrgId)];
	.print("I won the tasks(",JobId,") ",TaskList);
	org::commitMission(massist)[artifact_id(SchArtId)];
	.
+default::winner(ItemsAssemble, assemble(Storage, JobId, TaskList))
	: default::joined(org,OrgId) & metrics::jobHaveWorked(Jobs)
<-
	!strategies::not_free;
	-+metrics::jobHaveWorked(Jobs+1);
	lookupArtifact(JobId,SchArtId)[wid(OrgId)];
	org::focus(SchArtId)[wid(OrgId)];
	.print("I won the tasks to assemble ",ItemsAssemble," and deliver to ",Storage," for ",JobId);
	if ( not .empty(TaskList) ) { .print("I also won the tasks(",JobId,") ",TaskList); }
	org::commitMission(massemble)[artifact_id(SchArtId)];
	.