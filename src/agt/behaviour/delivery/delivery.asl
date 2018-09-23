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
	team::available_items(Storage,Items) &
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
	
+task(delivery_task(DeliveryPoint,Tasks),CNPBoard,TaskId)[source(A)]
<-
	-task(_,_,TaskId)[source(A)];
	.print("Received a bid request for ",TaskId);
	if (rules::can_I_bid){
//		+default::biding(TaskId);
		!create_bid(DeliveryPoint, Bid);
		.print("My bid for task delivery ",TaskId," is ",Bid);
    	manyBids(Bid)[artifact_name(CNPBoard)];	
    }
	ceaseBids[artifact_name(CNPBoard)];
	.
//+!create_bid(StorageD,Bid)
//	: default::role(Role,_,_,_,_,_,_,_,_,_,_) & default::maxLoad(MaxLoad) & strategies::centerStorage(Storage) & default::speed(Speed)
//<-
//	actions.route(Role,Speed,Storage,RouteStorage);
//	actions.route(Role,Speed,Storage,StorageD,RouteStorage2);
//	Distance = RouteStorage + RouteStorage2;
//	Bid = [bid(Distance,MaxLoad)];
//	.
//+!create_bid(StorageD,Bid)
//<-
//	Bid = [];
//	.
+!create_bid(StorageD,Bid)
	: 	default::role(Role,_,_,_,_,_,_,_,_,_,_) & 
		default::maxLoad(MaxLoad) & 
		strategies::centerStorage(Storage) & 
		default::speed(Speed) &
		default::lat(Lat) &
		default::lon(Lon) &
		default::charge(Battery)
<-
	?rules::estimate_route(Role,Speed,Battery,location(Lat,Lon),[location(Storage),location(StorageD)],0,Distance);
	Bid = [bid(Distance,MaxLoad)];
	.
+!create_bid(StorageD,Bid)
<-
	Bid = [];
	.

+!delivery_job(Id,Stocks,StorageDestination)
	: .sort(Stocks,ItemsToGet) & .member(delivery(Storage,_,_),Stocks)
<- 
	.print("Going to retrieve items to delivery at ",Storage);
	!action::goto(Storage);
	!stock::store_all_items(Storage);
	!::has_items(ItemsToGet);
	.print("Going to delivery items at ",StorageDestination);
	!action::goto(StorageDestination);
	!action::deliver_job(Id);
	.

+!has_items([]).	
+!has_items([delivery(_,Item,Qty)|Stoks])
<-
	!action::retrieve(Item,Qty);
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