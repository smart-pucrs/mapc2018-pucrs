// ### BIDS ###
+default::task(Agents,assemble(_),ContractNetName,TaskId)
	: .my_name(Me) & .member(Me,Agents)
<-
	.print("Received a bid request for ",TaskId);
	if (rules::can_I_bid){
		!create_bid(Bid);
		.print("My bid for task assemble ",TaskId," is ",Bid);
	    manyBids(Bid)[artifact_name(ContractNetName)];
	}	
	ceaseBids[artifact_name(ContractNetName)];
	.print(ContractNetName);
	.

+!create_bid(Bid)
	: 	default::role(Role,_,_,_,_,_,_,_,_,_,_) & 
		default::maxLoad(MaxLoad) & 
		strategies::centerStorage(Storage) & 
		strategies::centerWorkshop(Workshop) & 
		default::speed(Speed) & 
		default::lat(Lat) &
		default::lon(Lon) &
		default::charge(Battery)
<-
	?rules::estimate_route(Role,Speed,Battery,location(Lat,Lon),[location(Storage),location(Workshop),location(Storage)],0,Distance);
	Bid = [bid(Distance,MaxLoad,Role)];
	.
+!create_bid(Bid)
<-
	Bid = [];
	.

// ### ASSEMBLE ###
+!assemble(Item,Qty)
	: true
<-
	!action::assemble(Item,Qty);
	.
-!assemble(Item,Qty)[code(.fail(action(Action),result(Result)))]
<-
	!recover_from_failure(Action,Result,Item,Qty);
	.	
	
+!assist_assemble(Assembler)
	: true
<-
	!action::assist_assemble(Assembler);
	!assist_assemble(Assembler);
	.
-!assist_assemble(Assembler)[code(.fail(action(Action),result(Result)))]
<-
	!recover_from_failure(Action,Result,Assembler);
	.	
	
+!recover_from_failure(Action, Result, Item, Qty)
	: not default::hasItem(Item,Qty) & (Result == failed_item_amount | Result == failed_tools)
<-	
	.print("Some agent must have failed assist assemble, trying to assemble again.");
	!assemble(Item,Qty);
	.
	
+!recover_from_failure(Action, Result, Item, Qty)
<-	
	.print("Action ",Action," failed because of ",Result);
	.
+!recover_from_failure(Action, Result, Assembler)
<-	
	.print("Action ",Action," failed because of ",Result);
	.