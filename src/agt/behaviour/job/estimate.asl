// given a list of storages, return the itemized available items; return pattern item(Item,Qtd)
get_available_items([],Temp,ListItems)
:- 
	ListItems = Temp.
get_available_items([Storage|Storages],Temp,ListItems)
:-
	default::available_items(Storage,Items) & 
	.concat(Items,Temp,NewList)&
	get_available_items(Storages,NewList,ListItems) 
	.
// given a list of items, sums up all items of the same type
sum_up_items([],Temp,ListItems)
:-
	ListItems = Temp
	.
sum_up_items([item(Item,Qtd)|Items],Temp,ListItems)
:- 
	.member(item(Item,OldQtd),Temp) & 
	.difference(Temp,[item(Item,OldQtd)],NewList) &
	sum_up_items(Items,[item(Item,Qtd+OldQtd)|NewList],ListItems)
	.
sum_up_items([item(Item,Qtd)|Items],Temp,ListItems)
:- 
	not .member(item(Item,_),Temp) & 
	sum_up_items(Items,[item(Item,Qtd)|Temp],ListItems)
	.
// given a list of required items and quantities "required(Item,Qtd)", and another list of available items and quantities "item(Item,Qtd)", evaluates the difference taking into account the quantities
difference_in_quantities([],_):-true.
difference_in_quantities([required(Item,ReqQtd)|RequiredItems],AvailableItems)
:-
	.member(item(Item,AvaQtd),AvailableItems) &
	AvaQtd >= ReqQtd &
	difference_in_quantities(RequiredItems,AvailableItems)
	.
	
evaluate_items(Items,StoragesToLook)
:- 	
	get_available_items(StoragesToLook,[],ItemizedAvailableItems)&
	sum_up_items(ItemizedAvailableItems,[],AvailableItems)&
	difference_in_quantities(Items,AvailableItems)
	.
evaluate_steps
:-
	true
	.

+!priced_estimate(Id,Items)
	: new::storageList(SList)
<-
	?evaluate_items(Items,SList);
	?evaluate_steps;
	.print(Id," is feasible");
	.
//-!priced_estimate(Id,Storage,Items)[error_msg(Message)]
//<-
//	maybe perform the metrics for failed evaluation here
//	.fail;
//	.
