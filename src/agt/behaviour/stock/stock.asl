+!retrieve_items(Type,[],Storage).
+!retrieve_items(Type,[item(Item,Qtd)|Items],Storage)
	: true
<- 
	!retrieve_items(Item,Qtd,Storage);
	!retrieve_items(Items,Storage);
	.
+!retrieve_items(Type,Item,Qtd,Storage)
	: true
<- 
	.print("I'm going to get ",Item," ",Qtd," at ",Storage);
	!action::goto(Storage);
	!retrieve_items(Item,Qtd);
	.

// ### RETRIEVE ###
+!retrieve_items(Type,Item,Qtd)
	: hasItem(Item,CurrentQtd)
<-
	!retrieve_items(Type,Item,Qtd,CurrentQtd);
	.
+!retrieve_items(Type,Item,Qtd)
<-
	!retrieve_items(Type,Item,Qtd,0);
	.
+!retrieve_items(delivered,Item,Qtd,CurrentQtd)
<-
	!action::retrieve_delivered(Item,Qtd);
	?hasItem(Item,Qtd+CurrentQtd);
	.
+!retrieve_items(Type,Item,Qtd,CurrentQtd)
<-
	!action::retrieve(Item,Qtd);
	?hasItem(Item,Qtd+CurrentQtd);
	.
-!retrieve_items(Type,Item,Qtd,CurrentQtd)[code(.fail(action(Action),result(Result)))]
<-
	!recover_from_failure(Action,Result);
	.
	
// ### STORE ###
+!store_items(Item,Qtd)
	: hasItem(Item,CurrentQtd)
<-
	!store_items(Type,Item,Qtd,CurrentQtd);
	.
+!store_items(Item,Qtd,CurrentQtd)
	: CurrentQtd - Qtd == 0
<-
	!action::store(Item,Qtd);
	?hasItem(Item,Qtd+CurrentQtd) == false;
	.
+!store_items(Item,Qtd,CurrentQtd)
<-
	!action::store(Item,Qtd);
	?hasItem(Item,Qtd-CurrentQtd);
	.
-!store_items(Item,Qtd,CurrentQtd)[code(.fail(action(Action),result(Result)))]
<-
	!recover_from_failure(Action,Result);
	.
	
+!recover_from_failure(Action, Result)
<-	
	.print("Action ",Action," failed because of ",Result);
	.