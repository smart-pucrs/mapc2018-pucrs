find_shops(ItemId,[],[]).
find_shops(ItemId,[ShopId|List],[ShopId|Result]) :- shop(ShopId, _, _, _, ListItems) & .member(item(ItemId,_,_,_,_,_),ListItems) & find_shops(ItemId,List,Result).
find_shops(ItemId,[ShopId|List],Result) :- shop(ShopId, _, _, _, ListItems) & not .member(item(ItemId,_,_,_,_,_),ListItems) & find_shops(ItemId,List,Result).

find_shop_qty(item(ItemId, Qty),[],Buy,Aux,RouteShop,AuxRoute,AuxShop,Shop,Res) :- Buy = Aux & Shop = AuxShop & RouteShop = AuxRoute.
find_shop_qty(item(ItemId, Qty),[ShopId|List],Buy,Aux,RouteShop,AuxRoute,AuxShop,Shop,Res) :- shop(ShopId, _, _, Restock, ListItems) & .member(item(ItemId,_,Qty2,_,_,_),ListItems) & Restock <= Res & Qty / Qty2 < Aux & default::role(Role, Speed, _, _, _) & actions.route(Role,Speed,ShopId,Route) & find_shop_qty(item(ItemId, Qty),List,Buy,Qty/Qty2,RouteShop,Route,ShopId,Shop,Restock).
find_shop_qty(item(ItemId, Qty),[ShopId|List],Buy,Aux,RouteShop,AuxRoute,AuxShop,Shop,Res) :- shop(ShopId, _, _, Restock, ListItems) & .member(item(ItemId,_,Qty2,_,_,_),ListItems) & Restock <= Res & Qty / Qty2 == Aux & default::role(Role, Speed, _, _, _)  & actions.route(Role,Speed,ShopId,Route) & Route < AuxRoute & find_shop_qty(item(ItemId, Qty),List,Buy,Qty/Qty2,RouteShop,Route,ShopId,Shop,Restock).
find_shop_qty(item(ItemId, Qty),[ShopId|List],Buy,Aux,RouteShop,AuxRoute,AuxShop,Shop,Res) :- shop(ShopId, _, _, Restock, ListItems) & .member(item(ItemId,_,Qty2,_,_,_),ListItems) & AuxShop = "" & default::role(Role, Speed, _, _, _)  & actions.route(Role,Speed,ShopId,Route) & find_shop_qty(item(ItemId, Qty),List,Buy,Qty/Qty2,RouteShop,Route,ShopId,Shop,Restock).
find_shop_qty(item(ItemId, Qty),[ShopId|List],Buy,Aux,RouteShop,AuxRoute,AuxShop,Shop,Res) :- find_shop_qty(item(ItemId, Qty),List,Buy,Aux,RouteShop,AuxRoute,AuxShop,Shop,Res).

closest_facility(List, Facility) :- role(Role, _, _, _, _) & actions.closest(Role, List, Facility).
closest_facility(List, Facility1, Facility2) :- role(Role, _, _, _, _) & actions.closest(Role, List, Facility1, Facility2).
closest_facility(List, Lat, Lon, Facility2) :- role(Role, _, _, _, _) & actions.closest(Role, List, Lat, Lon, Facility2).

enough_battery(FacilityId1, FacilityId2, Result) :- role(Role, Speed, _, _, _) & actions.route(Role, Speed, FacilityId1, RouteLen1) & actions.route(Role, Speed, FacilityId1, FacilityId2, RouteLen2) & charge(Battery) & ((Battery > ((RouteLen1 * 10) + (RouteLen2 * 10) + 10) & Result = "true") | (Result = "false")).
enough_battery(Lat, Lon, FacilityId2, Result) :- role(Role, Speed, _, _, _) & actions.route(Role, Speed, Lat, Lon, _, _, _, RouteLen1) & actions.route(Role, Speed, Lat, Lon, FacilityId2, _, RouteLen2) & charge(Battery) & ((Battery > ((RouteLen1 * 10) + (RouteLen2 * 10) + 10) & Result = "true") | (Result = "false")).
enough_battery2(FacilityAux, FacilityId1, FacilityId2, Result, Battery) :- role(Role, Speed, _, _, _) & actions.route(Role, Speed, FacilityAux, FacilityId1, RouteLen1) & actions.route(Role, Speed, FacilityId1, FacilityId2, RouteLen2) & ((Battery > ((RouteLen1 * 10) + (RouteLen2 * 10) + 10) & Result = "true") | (Result = "false")).
enough_battery2(FacilityAux, Lat, Lon, FacilityId2, Result, Battery) :- role(Role, Speed, _, _, _) & actions.route(Role, Speed, FacilityAux, Lat, Lon, RouteLen1) & actions.route(Role, Speed, Lat, Lon, FacilityId2, _, RouteLen2) & ((Battery > ((RouteLen1 * 10) + (RouteLen2 * 10) + 10) & Result = "true") | (Result = "false")).
enough_battery_charging(FacilityId, Result) :- role(Role, Speed, _, _, _) & actions.route(Role, Speed, FacilityId, RouteLen) & charge(Battery) & ((Battery > ((RouteLen * 10) + 10) & Result = "true") | (Result = "false")).
enough_battery_charging2(FacilityAux, FacilityId, Result, Battery) :- role(Role, Speed, _, _, _) & actions.route(Role, Speed, FacilityAux, FacilityId, RouteLen) & ((Battery > ((RouteLen * 10) + 10) & Result = "true") | (Result = "false")).

select_bid([],bid(AuxBidAgent,AuxBid,AuxShopId),bid(BidAgentWinner,BidWinner,ShopIdWinner)) :- BidWinner = AuxBid & BidAgentWinner = AuxBidAgent & ShopIdWinner = AuxShopId.
select_bid([bid(BidAgent,Bid,ShopId,item(ItemId,Qty),TaskId)|Bids],bid(AuxBidAgent,AuxBid,AuxShopId),BidWinner) :- initiator::awarded(BidAgent,ShopId,_,_,TaskCount) & TaskCount < 2 & item(ItemId,Volume,_,_) & actions.getLoad(BidAgent,Load) & Load >= Volume*Qty & select_bid([],bid(BidAgent,Bid,ShopId),BidWinner).
select_bid([bid(BidAgent,Bid,ShopId,item(ItemId,Qty),TaskId)|Bids],bid(AuxBidAgent,AuxBid,AuxShopId),BidWinner) :- Bid \== -1 & Bid < AuxBid & ((initiator::awarded(BidAgent,_,_,_,TaskCount) & TaskCount < 2) | (initiator::awarded_assemble(BidAgent,_,_,_,_,AssTaskCount) & AssTaskCount < 3)) & item(ItemId,Volume,_,_) & actions.getLoad(BidAgent,Load) & Load >= Volume*Qty & select_bid(Bids,bid(BidAgent,Bid,ShopId),BidWinner).
select_bid([bid(BidAgent,Bid,ShopId,item(ItemId,Qty),TaskId)|Bids],bid(AuxBidAgent,AuxBid,AuxShopId),BidWinner) :- Bid \== -1 & not initiator::awarded_assemble(BidAgent,_,_,_,_,_) & not initiator::awarded(BidAgent,_,_,_,_) & Bid < AuxBid & select_bid(Bids,bid(BidAgent,Bid,ShopId),BidWinner).
select_bid([bid(BidAgent,Bid,ShopId,Item,TaskId)|Bids],bid(AuxBidAgent,AuxBid,AuxShopId),BidWinner) :- select_bid(Bids,bid(AuxBidAgent,AuxBid,AuxShopId),BidWinner).

select_bid_tool([],bid(AuxBidAgent,AuxBid,AuxShopId),bid(BidAgentWinner,BidWinner,ShopIdWinner)) :- BidWinner = AuxBid & BidAgentWinner = AuxBidAgent & ShopIdWinner = AuxShopId.
select_bid_tool([bid(BidAgent,Bid,ShopId,tool(ItemId),TaskId)|Bids],bid(AuxBidAgent,AuxBid,AuxShopId),BidWinner) :- initiator::awarded(BidAgent,ShopId,_,_,TaskCount) & TaskCount < 2 & item(ItemId,Volume,_,_) & actions.getLoad(BidAgent,Load) & Load >= Volume & select_bid([],bid(BidAgent,Bid,ShopId),BidWinner).
select_bid_tool([bid(BidAgent,Bid,ShopId,tool(ItemId),TaskId)|Bids],bid(AuxBidAgent,AuxBid,AuxShopId),BidWinner) :- Bid \== -1 & Bid < AuxBid & ((initiator::awarded(BidAgent,_,_,_,TaskCount) & TaskCount < 2) | (initiator::awarded_assemble(BidAgent,_,_,_,_,AssTaskCount) & AssTaskCount < 3)) & item(ItemId,Volume,_,_) & actions.getLoad(BidAgent,Load) & Load >= Volume & select_bid(Bids,bid(BidAgent,Bid,ShopId),BidWinner).
select_bid_tool([bid(BidAgent,Bid,ShopId,tool(ItemId),TaskId)|Bids],bid(AuxBidAgent,AuxBid,AuxShopId),BidWinner) :- Bid \== -1 & not initiator::awarded_assemble(BidAgent,_,_,_,_,_) & not initiator::awarded(BidAgent,_,_,_,_) & Bid < AuxBid & select_bid(Bids,bid(BidAgent,Bid,ShopId),BidWinner).
select_bid_tool([bid(BidAgent,Bid,ShopId,Task,TaskId)|Bids],bid(AuxBidAgent,AuxBid,AuxShopId),BidWinner) :- select_bid_tool(Bids,bid(AuxBidAgent,AuxBid,AuxShopId),BidWinner).

select_bid_assemble([],bid(AuxBidAgent,AuxBid),bid(BidAgentWinner,BidWinner)) :- BidWinner = AuxBid & BidAgentWinner = AuxBidAgent.
select_bid_assemble([bid(BidAgent,Bid,ShopId,assemble(Storage),TaskId)|Bids],bid(AuxBidAgent,AuxBid),BidWinner) :- Bid \== -1 & Bid < AuxBid & select_bid_assemble(Bids,bid(BidAgent,Bid),BidWinner).
select_bid_assemble([bid(BidAgent,Bid,ShopId,Task,TaskId)|Bids],bid(AuxBidAgent,AuxBid),BidWinner) :- select_bid_assemble(Bids,bid(AuxBidAgent,AuxBid),BidWinner).

find_shops_id([],Temp,Result) :- Result = Temp.
find_shops_id([shop(ShopId,_)|List],Temp,Result) :- find_shops_id(List,[ShopId|Temp],Result).

getFacility(FacilityId,Flat,Flon,LatAux,LonAux):- shop(FacilityId, LatAux, LonAux,_,_) & Flat=LatAux & Flon=LonAux.
getFacility(FacilityId,Flat,Flon,LatAux,LonAux):- storage(FacilityId, LatAux, LonAux,_,_,_) & Flat=LatAux & Flon=LonAux.
getFacility(FacilityId,Flat,Flon,LatAux,LonAux):- dump(FacilityId,LatAux,LonAux) & Flat=LatAux & Flon=LonAux.
getFacility(FacilityId,Flat,Flon,LatAux,LonAux):- workshop(FacilityId,LatAux,LonAux) & Flat=LatAux & Flon=LonAux.

convertListString2Term([],Temp,Result) :- Result = Temp.
convertListString2Term([String | ListString],Temp,Result) :- .term2string(Term,String) & convertListString2Term(ListString,[Term|Temp],Result).

findTools([],Temp, Result) :- Result = Temp.
findTools([Tool | ListOfTools],Temp,Result) :- .member(item(Tool,_),Temp) & findTools(ListOfTools, Temp,Result).
findTools([Tool | ListOfTools],Temp,Result) :- not .member(item(Tool,_),Temp) & findTools(ListOfTools, [item(Tool,1) | Temp],Result).
findParts(Qtd,[],Temp, Result) :- Result = Temp.
findParts(Qtd,[[PartName,PartQtd] | ListOfPart],Temp,Result) :- (NewQtd = Qtd*PartQtd) & item(PartName,_,tools(Tools),parts(Parts)) & decomposeItem(PartName,NewQtd,Tools,Parts,Temp,ListItensJob) & findParts(Qtd,ListOfPart,ListItensJob,Result).
decomposeItem(Item,Qtd,[],[],Temp,ListItensJob) :- ListItensJob = [item(Item,Qtd) | Temp].
decomposeItem(Item,Qtd,Tools,Parts,Temp,ListItensJob) :- findTools(Tools,Temp,NewTempTools) & findParts(Qtd,Parts,NewTempTools,NewTempParts) & ListItensJob = NewTempParts.
findPartsNoTools([],Temp, Result) :- Result = Temp.
findPartsNoTools([[PartName,_] | ListOfPart],Temp,Result) :- item(PartName,_,_,parts(Parts)) & decomposeItemNoTools(PartName,Parts,Temp,ListItensJob) & findPartsNoTools(ListOfPart,ListItensJob,Result).
decomposeItemNoTools(Item,[],Temp,ListItensJob) :- ListItensJob = [Item | Temp].
decomposeItemNoTools(Item,Parts,Temp,ListItensJob) :- findPartsNoTools(Parts,[],NewTempParts) & ListItensJob = NewTempParts.

decomposeRequirements([],Temp,Result):- Result = Temp.
//decomposeRequirements([required(Item,Qtd) | Requirements],Temp,Result):- item(Item,_,tools(Tools),parts(Parts)) & decomposeItem(Item,Qtd,Tools,Parts,Temp,ListItensJob) & decomposeRequirements(Requirements,ListItensJob,Result).
decomposeRequirements([required(Item,Qtd) | Requirements],Temp,Result):- item(Item,_,tools(Tools),parts(Parts)) & decomposeItem(Item,Qtd,Tools,Parts,[],ListItensJob) & decomposeRequirements(Requirements,[ListItensJob|Temp],Result).
decomposeRequirementsNoTools([],Temp,Result):- Result = Temp.
decomposeRequirementsNoTools([required(Item,_) | Requirements],Temp,Result):- item(Item,_,_,parts(Parts)) & decomposeItemNoTools(Item,Parts,[],ListItensJob) & .union(ListItensJob,Temp,New) & decomposeRequirementsNoTools(Requirements,New,Result).

separateItemTool([item(ItemId,Qty)|B],[item(ItemId,Qty)|ListTools],ListItems) :- .substring("tool",ItemId) & separateItemTool(B,ListTools,ListItems).
separateItemTool([item(ItemId,Qty)|B],ListTools,[item(ItemId,Qty)|ListItems]) :- .substring("item",ItemId) & separateItemTool(B,ListTools,ListItems).

removeDuplicateTool([item(ItemId,Qty)|B],ListTools) :- .member(item(ItemId,Qty),B) & removeDuplicateTool(B,ListTools).
removeDuplicateTool([item(ItemId,Qty)|B],[item(ItemId,Qty)|ListTools]) :- removeDuplicateTool(B,ListTools).

get_assemble([],Aux,AssembleList,Count) :- AssembleList = Aux.
get_assemble([required(ItemId,Qty)|TaskList],Aux,AssembleList,Count) :- item(ItemId,_,_,parts(Parts)) & Parts \== [] & get_parts(Parts,[],Assemble,Qty,Count,NewCount) & .concat([item(NewCount+1,ItemId,Qty)],Assemble,AssembleNew) & .concat(AssembleNew,Aux,NewAux) & get_assemble(TaskList,NewAux,AssembleList,NewCount+1).
get_assemble([required(ItemId,Qty)|TaskList],[item(Count+1,ItemId,Qty)|Aux],AssembleList,Count) :- get_assemble(TaskList,Aux,AssembleList,Count+1).
get_parts([],Aux,AssembleList,Qty,Count,NewCount) :- AssembleList = Aux & Count = NewCount.
get_parts([[Item,Qty]|Parts],Aux,AssembleList,Qty2,Count,NewCount) :- item(Item,_,_,parts(Parts2)) & Parts2 \== [] & get_parts(Parts2,[],Assemble,Qty*Qty2,Count,NewCount2) & .concat([item(NewCount2+1,Item,Qty*Qty2)],Assemble,AssembleNew) & .concat(AssembleNew,Aux,NewAux) & get_parts(Parts,NewAux,AssembleList,Qty2,NewCount2+1,NewCount).
get_parts([[Item,Qty]|Parts],Aux,AssembleList,Qty2,Count,NewCount) :- get_parts(Parts,Aux,AssembleList,Qty2,Count,NewCount).

getQuadLatLon(quad1,QLat,QLon) :- coalition::quad1(QLat,QLon).
getQuadLatLon(quad2,QLat,QLon) :- coalition::quad2(QLat,QLon).
getQuadLatLon(quad3,QLat,QLon) :- coalition::quad3(QLat,QLon).
getQuadLatLon(quad4,QLat,QLon) :- coalition::quad4(QLat,QLon).

check_buy_list([],Result) :- Result = "true".
check_buy_list([item(ItemId,Qty)|Items],Result) :- actions.getItemQty(ItemId,Qty2) & Qty <= Qty2 * 3 & check_buy_list(Items,Result).
check_buy_list([item(ItemId,Qty)|Items],Result) :- actions.getItemQty(ItemId,Qty2) & Qty > Qty2 * 3 & Result = "false".

check_multiple_buy([],AddSteps) :- AddSteps = 0.
check_multiple_buy([item(ItemId,Qty)|Items],AddSteps) :- actions.getItemQty(ItemId,Qty2) & Qty <= Qty2 & check_multiple_buy(Items,AddSteps).
check_multiple_buy([item(ItemId,Qty)|Items],AddSteps) :- actions.getItemQty(ItemId,Qty2) & Qty > Qty2 & AddSteps = Qty * 5. // 5 is the maximum restock 5 steps to add 1 item

check_price([],[],Aux,Result) :- Result = Aux.
check_price([],[item(ItemId,Qty)|Items],Aux,Result) :- actions.getItemPrice(ItemId,Price) & check_price([],Items,Aux+Price*Qty,Result).
check_price([item(Tool,_)|Tools],Items,Aux,Result) :- actions.getItemPrice(Tool,Price) & check_price(Tools,Items,Aux+Price,Result).

total_load([],Aux,Vol) :- Vol = Aux.
total_load([required(ItemId,Qty)|Items],Aux,Vol) :- default::item(ItemId,Vol2,_,_) & Aux2 = Aux + (Vol2 * Qty) & total_load(Items,Aux2,Vol).

get_roles([],Aux,Roles) :- Roles = Aux.
get_roles([Agent|FreeAgents],Aux,Roles) :- actions.getAgentRole(Agent,Role) & not .member(Role,Aux) & get_roles(FreeAgents,[Role|Aux],Roles).
get_roles([Agent|FreeAgents],Aux,Roles) :- get_roles(FreeAgents,Aux,Roles).

get_tools([],Aux,T) :- T = Aux.
get_tools([Role|Roles],Aux,T) :- (default::role(Role,_,_,_,Tools) | default::tools(Role,Tools)) & .union(Tools,Aux,AuxNew) & get_tools(Roles,AuxNew,T).
get_tools([Role|Roles],Aux,T) :- get_tools(Roles,Aux,T).

check_tools([],AvailableTools,Result) :- Result = "true".
check_tools([item(Tool,_)|ListToolsNew],AvailableTools,Result) :- .member(Tool,AvailableTools) & check_tools(ListToolsNew,AvailableTools,Result).
check_tools([item(Tool,_)|ListToolsNew],AvailableTools,Result) :- not .member(Tool,AvailableTools) & Result = "false".

concat_bases([],Aux,ListItemsConcat) :- ListItemsConcat = Aux.
concat_bases([item(ItemId,Qty)|ListItems],Aux,ListItemsConcat) :- .findall(Qty2,.member(item(ItemId,Qty2),ListItems),QtyList) & not .empty(QtyList) & deleteall(ItemId,ListItems,ListItemsNew) & concat_bases(ListItemsNew,[item(ItemId,math.sum(QtyList)+Qty)|Aux],ListItemsConcat).
concat_bases([item(ItemId,Qty)|ListItems],Aux,ListItemsConcat) :- not .member(item(ItemId,Qty2),ListItems) & concat_bases(ListItems,[item(ItemId,Qty)|Aux],ListItemsConcat).

deleteall(ItemId,ListItems,ListItemsNew) :- .member(item(ItemId,_),ListItems) & .delete(item(ItemId,_),ListItems,ListItemsNewAux) & deleteall(ItemId,ListItemsNewAux,ListItemsNew).
deleteall(ItemId,ListItems,ListItemsNew) :- not .member(item(ItemId,_),ListItems) & ListItemsNew = ListItems.

check_bases([],Result) :- Result = "false".
check_bases([required(ItemId,Qty)|Items],Result) :- default::item(ItemId,_,_,parts(Parts)) & Parts \== [] & check_bases(Items,Result).
check_bases([required(ItemId,Qty)|Items],Result) :- default::item(ItemId,_,_,parts(Parts)) & Parts == [] & Result = "true".

