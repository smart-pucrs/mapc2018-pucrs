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
	?hasItem(Item,Qtd+OldQtd);
	.
+!retrieve_items(Type,Item,Qtd,OldQtd)
<-
	!action::retrieve(Item,Qtd);
	?hasItem(Item,Qtd+OldQtd);
	.
-!retrieve_items(Type,Item,Qtd,CurrentQtd)[code(.fail(action(Action),result(Result)))]
<-
	!recover_from_failure(Action,Result);
	.

// ### STORE ###
+!store_items(Item,Qtd)
	: default::hasItem(Item,OldQtd)
<-
	!action::store(Item,Qtd);
	if(OldQtd - Qtd == 0){
		?default::hasItem(Item,_) == false;
	} else{
		?default::hasItem(Item,OldQtd-Qtd);
	}	
	.
-!store_items(Item,Qtd,CurrentQtd)[code(.fail(action(Action),result(Result)))]
<-
	!recover_from_failure(Action,Result);
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
	
+!store_items(Item,Qtd,Storage)
	: not default::facility(Storage)
<- 
	.print("I'm going to store ",Item," ",Qtd," at ",Storage);
	!action::goto(Storage);
	!store_items(Item,Qtd,Storage);
	.
+!store_items(Item,Qtd,Storage)
<- 
	!storage::store_items(Item,Qtd);
	.
	
