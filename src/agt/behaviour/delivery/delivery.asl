current_load_item([],0).
current_load_item([item(Item,Qtd)|Items],(Vol*Qtd)+Load)
:-
	default::item(Item,Vol,_,_) &
	current_load_item(Items,Load)
	.
current_load([],0).
current_load([delivery(_,Items,_)|Deliveries],ItemsLoad+Load)
:-
	current_load_item(Items,ItemsLoad) &
	current_load(Deliveries,Load)
	.
predicted_load(Load)
:-
	.findall(Delivery,strategies::winner(_,Delivery,_),Deliveries) &
	current_load(Delivery,Load)
	.

steps_to_storages(Destination,Item,[],Temp,Result)
:-
	Result = Temp
	.
steps_to_storages(Destination,Item,[Storage|Storages],Temp,Result)
:-
	default::available_items(Storage,Items) &
	.member(item(Item,_),Items) &
	default::role(Role,_,_,_,_,_,_,_,_,_,_) &
	default::speed(Speed) &
	actions.route(Role, Speed, Storage, RouteStorage) &
	actions.route(Role, Speed, Storage, Destination, StorageDelivery) &
	steps_to_storages(Destination,Item,Storages,[bid(RouteStorage+StorageDelivery,Storage)|Temp],Result)
	.
steps_to_storages(Destination,Item,[Storage|Storages],Temp,Result)
:-
	steps_to_storages(Destination,Item,Storages,Temp,Result)
	.
	
+task(delivery_task(StorageD,Item,Qtd),CNPBoard,TaskId)
<-
	!create_bid_task(StorageD,Item, Qtd, Bid);
	.print("My bid for task ",TaskId," is ",Bid);
    manyBids(Bid)[artifact_name(CNPBoard)];
	ceaseBids[artifact_name(CNPBoard)];
	.
+!create_bid_task(StorageD, ItemId, Qty, Bid)
	: default::load(MyLoad) & predicted_load(PredLoad) & default::maxLoad(LoadCap) & default::item(ItemId,Vol,_,_) & new::storageList(SList)
<-
	.print("CL: ",MyLoad," pred: ",PredLoad);
	if (LoadCap - (PredLoad + MyLoad) >= Vol * Qty) {
		?steps_to_storages(StorageD,ItemId,SList,[],Bid);
	}
	else { Bid = []; }
	.

+!delivery_job(Id,Stocks,StorageDestination)
	: .sort(Stocks,ItemsToGet)
<- 
	!has_items(ItemsToGet);
	!action::goto(StorageDestination);
	!action::deliver_job(Id);
	.

+!has_items([]).	
+!has_items([delivery(Storage,Items)|Stoks])
<-
	!action::goto(Storage);
	for(.member(item(Item,Qtd),Items)){
		.print("I am going to get ",Qtd," units of ",Item," at ",Storage);
		!action::retrieve(Item,Qtd);
	}
	!has_items(Stoks);
	.
-!has_items(Stoks)[code(.fail(action(Action),result(Result)))]
<-
	!recover_from_failure(Action,Result);
	.

	
+!recover_from_failure(Action, Result)
<-	
	.print("Action ",Action," failed because of ",Result);
	.