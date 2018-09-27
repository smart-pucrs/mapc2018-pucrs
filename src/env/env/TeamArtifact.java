package env;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Iterator;
import java.util.ListIterator;
import java.util.Map;
import java.util.Set;
import java.util.logging.Logger;

import cartago.Artifact;
import cartago.OPERATION;
import cartago.ObsProperty;
import cartago.OpFeedbackParam;
import jason.asSyntax.ASSyntax;
import jason.asSyntax.Literal;
import jason.asSyntax.parser.ParseException;


public class TeamArtifact extends Artifact {

	private static Logger logger = Logger.getLogger(TeamArtifact.class.getName());
	
	private final String obspDesiredCompound = "desired_compound";
	private final String obspDesiredBase 	 = "desired_base";
	
	private static Map<String, String>  agentNames 	 	= new HashMap<String, String>();
	private static Map<String, String>  agentRoles 	 	= new HashMap<String, String>();
	private static Map<String, Integer> loads 			= new HashMap<String, Integer>();
	private static Map<String, Integer> duplicateLoads 	= new HashMap<String, Integer>();

	private Map<String, ArrayList<Literal>>  availableItems  = new HashMap<String,ArrayList<Literal>>();
	private Map<String, ArrayList<String>>   buyCoordination = new HashMap<String,ArrayList<String>>();
	private static Map<Integer, Set<String>> actionsByStep   = new HashMap<Integer, Set<String>>();

	private Map<String, DesiredItem> desiredBase 	 = new HashMap<String, DesiredItem>();
	private Map<String, DesiredItem> desiredCompound = new HashMap<String, DesiredItem>();
	
	void init(){
		logger.info("Team Artifact has been created!");
		this.defineObsProperty(this.obspDesiredCompound, new Object[0]);
		this.defineObsProperty(this.obspDesiredBase, new Object[0]);
	}
	
	@OPERATION
	void createAvailableList(String storage){
		availableItems.put(storage, new ArrayList<Literal>());
		String[] itemsAux = availableItems.get(storage).toArray(new String[availableItems.get(storage).size()]);
		this.defineObsProperty("available_items", Literal.parseLiteral(storage), itemsAux);
	}
	
	private int timesQtyCompundItem = 4;
	@OPERATION
	void setDesiredBase(String item, int qty)  {
		if (!this.desiredBase.containsKey(item))
			this.desiredBase.put(item, new DesiredItem(item));
		
		DesiredItem desired = this.desiredBase.get(item);
		desired.setDesiredQty(qty*timesQtyCompundItem);
		
		updateDesiredItemsBase(this.desiredBase, this.obspDesiredBase);
	}	
	@OPERATION
	void setDesiredCompound(String item, int qty)  {
		if (!this.desiredCompound.containsKey(item))
			this.desiredCompound.put(item, new DesiredItem(item));
		
		DesiredItem desired = this.desiredCompound.get(item);
		desired.setDesiredQty(qty*timesQtyCompundItem);
		
		updateDesiredItemsCompound(this.desiredCompound, this.obspDesiredCompound);
	}
	
	private void updateDesiredItemsCompound(Map<String,DesiredItem> desiredItems, String obspName) {
		Object[] itemsAux = desiredItems.entrySet().stream().map(d -> d.getValue().getLiteral()).toArray(Literal[]::new);
		this.removeObsProperty(obspName);
		this.defineObsProperty(obspName, new Object[] {itemsAux});
	}
	
	private void updateDesiredItemsBase(Map<String,DesiredItem> desiredItems, String obspName) {
		int totalDesiredItems = getTotalDesiredItems(desiredItems);
		Object[] itemsAux = desiredItems.entrySet().stream().map(d -> d.getValue().getLiteral(totalDesiredItems)).toArray(Literal[]::new);
		this.removeObsProperty(obspName);
		this.defineObsProperty(obspName, new Object[] {itemsAux});
	}
	
	private int getTotalDesiredItems(Map<String,DesiredItem> storedItems) {
		int total = 0;
		for (String key : storedItems.keySet()) {			
            DesiredItem desiredItem = storedItems.get(key);
            if(desiredItem.getCurrentQty() < desiredItem.getDesiredQty()) {
            	total = total + desiredItem.getPercentage();
            } else {
            	total = total + 1;
            }
		}
		return total;
	}
	
	@OPERATION
	void addAvailableItem(String storage, String item, int qty){
		Literal litStorage = Literal.parseLiteral(storage);
		Literal litItem = Literal.parseLiteral("item");
		
		int finalQtd = 0;
		if (availableItems.get(storage).toString().contains(item+',')) { // we need to differentiate item1 from item11
			for (Iterator<Literal> iter = availableItems.get(storage).iterator(); iter.hasNext();) {
				Literal l = iter.next();
				if (l.toString().contains(item+',')) {
					iter.remove();
					finalQtd 	= qty +Integer.parseInt(l.getTerm(1).toString());
				}
			}
		}
		else { 
			finalQtd = qty;			
		}
		try {
			litItem.addTerm(ASSyntax.parseTerm(item));
			litItem.addTerm(ASSyntax.parseTerm(String.valueOf(finalQtd)));
		} catch (ParseException e) { logger.info("@@@@@@@@@ Adding available item "+item+" to storage "+storage+". Result = "+e.getMessage());}
		
		availableItems.get(storage).add(litItem);
		Literal[] itemsAux = availableItems.get(storage).toArray(new Literal[availableItems.get(storage).size()]);
		
		if (this.desiredBase.containsKey(item)) {
			this.desiredBase.get(item).addCurrentQty(qty);
			updateDesiredItemsBase(this.desiredBase, this.obspDesiredBase);
//			signal("baseStored");
		} else {
			this.desiredCompound.get(item).addCurrentQty(qty);
			updateDesiredItemsCompound(this.desiredCompound, this.obspDesiredCompound);
		}
		signal("baseStored");
		
		this.removeObsPropertyByTemplate("available_items", litStorage, null);
		this.defineObsProperty("available_items", litStorage, itemsAux);
	}
	
	@OPERATION
	void addManufactoredItem(String storage, String item, int qty){	
		this.desiredCompound.get(item).removeCurrentQty(qty);		
//		addAvailableItem(storage, item, qty);
		updateDesiredItemsCompound(this.desiredCompound, this.obspDesiredCompound);
		signal("compound_stored");
	}
	
	@OPERATION
	void manufactureItem(String item, int qty){
		this.desiredCompound.get(item).addCurrentQty(qty);
		updateDesiredItemsCompound(this.desiredCompound, this.obspDesiredCompound);
	}
	
	@OPERATION
	void removeAvailableItem(String storage, String item, int qty, OpFeedbackParam<String> res){
		Literal litStorage = Literal.parseLiteral(storage);
		int newqty = 0;
		String result = "false";
		if (availableItems.get(storage) != null && availableItems.get(storage).toString().contains(item+',')) {
			for (ListIterator<Literal> iter = availableItems.get(storage).listIterator(); iter.hasNext();) {
				Literal l = iter.next();
				if (l.toString().contains(item+',')) {
					result = "true"; 
					newqty = Integer.parseInt(l.getTerm(1).toString()) - qty;					
					if (newqty > 0) {
						Literal litItem = Literal.parseLiteral("item");
						try {							
							litItem.addTerm(ASSyntax.parseTerm(item));
							litItem.addTerm(ASSyntax.parseTerm(String.valueOf(newqty)));
						} catch (ParseException e) { logger.info("@@@@@@@@@ Adding available item "+item+" to storage "+storage+". Result = "+e.getMessage());}
						iter.set(litItem);						
					}
					else if (newqty == 0) {
						iter.remove();
					}
					else {
						result = "false"; 
					}
				}
			}
		}
		if (result.equals("true")) {
			if (this.desiredBase.containsKey(item)) {
				this.desiredBase.get(item).removeCurrentQty(qty);
				updateDesiredItemsBase(this.desiredBase, this.obspDesiredBase);
			} else {
				this.desiredCompound.get(item).removeCurrentQty(qty);
				updateDesiredItemsCompound(this.desiredCompound, this.obspDesiredCompound);
				signal("baseStored");
			}
			
			Literal[] itemsAux = availableItems.get(storage).toArray(new Literal[availableItems.get(storage).size()]);
			this.removeObsPropertyByTemplate("available_items", litStorage, null);
			this.defineObsProperty("available_items", litStorage, itemsAux);
		}
		
		res.set(result);
	}
	
	@OPERATION
	void addServerName(String agent, String agentServer){
		agentNames.put(agent,agentServer);
	}
	
	@OPERATION
	void getServerName(String agent, OpFeedbackParam<String> agentServer){
		agentServer.set(agentNames.get(agent));
	}
	
	@OPERATION
	void addRole(String agent, String role){
		agentRoles.put(agent,role);
	}
	
	@OPERATION
	void addLoad(String agent, int load){
		loads.put(agent,load);
	}
	
	@OPERATION
	void getLoad(String agent, OpFeedbackParam<Integer> load){
		load.set(loads.get(agent));
	}
	
	@OPERATION
	void saveDuplicateLoad(){
		duplicateLoads.putAll(loads);
	}
	
	@OPERATION
	void resetLoads(){
		loads.putAll(duplicateLoads);
	}
	
	public static int getLoad(String agent) {
		return loads.get(agent);
	}
	
	public static String getAgentRole(String agent) {
		return agentRoles.get(agent);
	}
	
		
	@OPERATION
	void addResourceNode(String resourceId, double lat, double lon, String resource){
		Literal litResourceId = Literal.parseLiteral(resourceId);
		Literal litResource = Literal.parseLiteral(resource);
		
		ObsProperty prop = this.getObsPropertyByTemplate("resNode", litResourceId,lat,lon,litResource);
		if (prop == null) {
			this.defineObsProperty("resNode",litResourceId,lat,lon,litResource);
		}
	}
	
	@OPERATION
	void addEnemyWell(String wellId, double lat, double lon,String type){
		Literal litWellId 	= Literal.parseLiteral(wellId);
		Literal litType 	= Literal.parseLiteral(type);
		
		ObsProperty prop = this.getObsPropertyByTemplate("enemyWell",litWellId,null,null,null);
		if (prop == null) {
			this.defineObsProperty("enemyWell",litWellId,lat,lon,litType);
		}
	}
	@OPERATION
	void removeEnemyWell(String wellId){
		Literal litWellId = Literal.parseLiteral(wellId);
		
		ObsProperty prop = this.getObsPropertyByTemplate("enemyWell",litWellId,null,null,null);
		if (prop != null) {
			this.removeObsPropertyByTemplate("enemyWell",litWellId,null,null,null);
		}
	}
	
	@OPERATION
	void clearMaps() {
		agentNames.clear();
		agentRoles.clear();
		loads.clear();
		duplicateLoads.clear();
		availableItems.clear();
		buyCoordination.clear();
		actionsByStep.clear();
		desiredBase.clear();
		desiredCompound.clear();
		this.removeObsProperty(obspDesiredCompound);
		this.removeObsProperty(obspDesiredBase);
		this.init();
	}
	
	@OPERATION
	void chosenAction(int step) {
		String agent = getCurrentOpAgentId().getAgentName();
		
		Set<String> agents = actionsByStep.remove(step);
		if (agents == null)
			agents = new HashSet<String>();
		
		if (!agents.contains(agent)) {
			agents.add(agent);
			actionsByStep.put(step, agents);
			
			if (this.getObsPropertyByTemplate("chosenActions", step,null) != null)
				this.removeObsPropertyByTemplate("chosenActions", step, null);
			this.defineObsProperty("chosenActions", step, agents.toArray());
			
//			clean belief
			if (actionsByStep.containsKey(step-3)) {
				actionsByStep.remove(step-3);
				this.removeObsPropertyByTemplate("chosenActions", step-3, null);
			}
		}	
	}
	
	class DesiredItem{
		
		private String name;
		private int desiredQty;
		private int currentQty;
		private int percentage;
		
		public DesiredItem(String name) {
			this.name = name;
			this.desiredQty = 0;
			this.currentQty = 0;
		}
		
		public int getCurrentQty() {
			return this.currentQty;
		}

		public int getPercentage() {
			return 100 - this.percentage;
		}
		
		public int getDesiredQty() {
			return this.desiredQty;
		}

		public void setDesiredQty(int desiredQty) {
			this.desiredQty = desiredQty;
			updatePercentual();
		}
		
		public void addCurrentQty(int qty) {
			this.currentQty = this.currentQty+qty;
			updatePercentual();
		}
		
		public void removeCurrentQty(int qty) {
			this.currentQty = this.currentQty-qty;
			updatePercentual();
		}
		
		private void updatePercentual() {
			int percent = (this.currentQty*100)/this.desiredQty;
			if (percent >= 100) 
				this.percentage = 99;
			else
				this.percentage = percent;
		}

		public Literal getLiteral() {
			Literal l = null;
			try {
				l = ASSyntax.parseLiteral("item");
				l.addTerm(ASSyntax.parseTerm(String.valueOf(this.percentage)));
				l.addTerm(ASSyntax.parseTerm(this.name));
				l.addTerm(ASSyntax.parseTerm(String.valueOf(this.desiredQty)));				
			} catch (ParseException e) {
				logger.info(e.getMessage());
			}
			return l;
		}
		
		public Literal getLiteral(int total) {
			Literal l = null;
			try {
				l = ASSyntax.parseLiteral("item"); 
				if (this.currentQty >= this.desiredQty)
					l.addTerm(ASSyntax.parseTerm(String.valueOf(1))); // Priority percent %
				else
					l.addTerm(ASSyntax.parseTerm(String.valueOf(1+(this.getPercentage()*100)/total))); // Priority percent %
				l.addTerm(ASSyntax.parseTerm(this.name));
				l.addTerm(ASSyntax.parseTerm(String.valueOf(this.desiredQty)));				
			} catch (ParseException e) {
				logger.info(e.getMessage());
			}
			return l;
		}
	}
}