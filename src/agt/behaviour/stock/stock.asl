//+!go_store
//	: bidder::winner(_,_,Qty,Item,_,_,Storage,_,_)  & default::role(Role, _, _, _, _, _, _, _, _, _, _)
//<-
//	!action::goto(Storage);
//	!action::store(Item,Qty);
//	addAvailableItem(Storage,Item,Qty);
//	-bidder::winner(_,_,_,_,_,_,_,_,_)[source(_)];
//	.send(vehicle1,achieve,initiator::add_agent_to_free(Role));
//	!!strategies::free;
//	.
{begin namespace(storage, local)}
// ### RETRIEVE ###
+!retrieve_items(Type,Item,Qtd)
	: default::hasItem(Item,OldQtd)
<-
	!retrieve_items(Type,Item,Qtd,OldQtd);
	.
+!retrieve_items(Type,Item,Qtd)
<-
	!retrieve_items(Type,Item,Qtd,0);
	.
+!retrieve_items(delivered,Item,Qtd,OldQtd)
<-
	!action::retrieve_delivered(Item,Qtd);
	?default::hasItem(Item,Qtd+OldQtd);
	.
+!retrieve_items(Type,Item,Qtd,OldQtd)
<-
	!action::retrieve(Item,Qtd);
	?default::hasItem(Item,Qtd+OldQtd);
	.
-!retrieve_items(Type,Item,Qtd,CurrentQtd)[code(.fail(action(Action),result(Result)))]
<-
	!recover_from_failure(Action,Result);
	.
-!retrieve_items(Type,Item,Qtd,OldQtd)
<-
	.print("HOUSTON WE HAVE A BUG!");
	!retrieve_items(Type,Item,Qtd,OldQtd);
	.

// ### STORE ###
+!store_items(Storage,Item,Qtd)
	: default::hasItem(Item,OldQtd)
<-
	!action::store(Item,Qtd);
	if(OldQtd - Qtd == 0){
		?not default::hasItem(Item,_);
	} else{
		?default::hasItem(Item,OldQtd-Qtd);
	}	
	addAvailableItem(Storage,Item,Qtd);	
	.
-!store_items(Item,Qtd,CurrentQtd)[code(.fail(action(Action),result(Result)))]
<-
	!recover_from_failure(Action,Result);
	.

+!recover_from_failure(Action, failed_capacity)
<-	
	.print("HOUSTON WE HAVE A BUG! ",Action," failed_capacity");
	.wait(para);
	.	
+!recover_from_failure(Action, failed_location)
<-	
	.print("HOUSTON WE HAVE A BUG! ",Action," failed_location");
	.wait(para);
	.	
+!recover_from_failure(Action, failed_item_amount)
<-	
	.print("HOUSTON WE HAVE A BUG! ",Action," failed_item_amount");
	.wait(para);
	.
+!recover_from_failure(Action, Result)
<-	
	.print("Action ",Action," failed because of ",Result);
	.
{end}

+!retrieve_delivered_items(Item,Qtd,Storage)
	: not default::facility(Storage)
<- 
	.print("I'm going to get ",Item," ",Qtd," at ",Storage);
	!action::goto(Storage);
	!retrieve_delivered_items(Item,Qtd,Storage);
	.
+!retrieve_delivered_items(Type,Item,Qtd,Storage)
<- 
	!storage::retrieve_items(delivered,Item,Qtd);
	.

+!retrieve_items(Item,Qtd,Storage)
	: not default::facility(Storage)
<- 
	.print("I'm going to get ",Item," ",Qtd," at ",Storage);
	!action::goto(Storage);
	!retrieve_items(Item,Qtd,Storage);
	.
+!retrieve_items(Item,Qtd,Storage)
<- 
	!storage::retrieve_items(normal,Item,Qtd);
	.
	
+!store_all_items(Storage)
	: default::hasItem(Item,Qty)
<-
	!store_items(Item,Qty,Storage)
	!store_all_items(Storage);
	.
+!store_all_items(Storage).
+!store_items(Item,Qtd,Storage)
	: not default::facility(Storage)
<- 
	.print("I'm going to store ",Item," ",Qtd," at ",Storage);
	!action::goto(Storage);
	!store_items(Item,Qtd,Storage);
	.
+!store_items(Item,Qtd,Storage)
<- 
	!storage::store_items(Storage,Item,Qtd);
	.
	
+!store_manufactored_item(Item,Qty,Storage)
	: default::joined(vehicleart,WArtId)
<- 
	default::addManufactoredItem(Storage,Item,Qty)[wid(WArtId)];
	!storage::store_items(Storage,Item,Qty);
	.
	
