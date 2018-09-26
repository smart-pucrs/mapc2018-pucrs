+task(delivery_task(DeliveryPoint,Tasks),CNPBoard,TaskId)[source(A)]
<-
	-task(_,_,TaskId)[source(A)];
	.print("Received a bid request for ",TaskId);
	if (rules::can_I_bid){
		!create_bid(DeliveryPoint, Bid);
		.print("My bid for task delivery ",TaskId," is ",Bid);
    	manyBids(Bid)[artifact_name(CNPBoard)];	
    }
	ceaseBids[artifact_name(CNPBoard)];
	.
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