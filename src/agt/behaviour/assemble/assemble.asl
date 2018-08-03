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
	.
	
+!recover_from_failure(Action, failed_item_amount, Item, Qty)
	: not default::hasItem(Item,Qty)
<-	
	.print("Some agent must have failed assist assemble, trying to assemble again.");
	!action::assemble(Item,Qty);
	.
+!recover_from_failure(Action, Result, Item, Qty)
<-	
	.print("Action ",Action," failed because of ",Result);
	.