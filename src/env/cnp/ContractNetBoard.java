package cnp;

import jason.asSyntax.Literal;

import java.util.ArrayList;
import java.util.List;
import java.util.logging.Logger;

import cartago.*;

public class ContractNetBoard extends Artifact {
	
	private Logger logger = null;
	Boolean state;
	
	private List<Bid> bids;
	
	void init(String taskDescr, long duration, int agents){
		logger = Logger.getLogger(""+this.getId());
		state = true;
		bids = new ArrayList<Bid>();
		this.execInternalOp("checkDeadline", duration);
		this.execInternalOp("checkAllBids", agents);
	}
	
	@OPERATION void bid(String agent, int distance){
		if (state){
			bids.add(new Bid(agent,distance));
		} else {
			this.failed("cnp_closed");
		}
	}
	
	@OPERATION void bid(String agent, int distance, String shop, String item, int taskid){
		if (state){
			bids.add(new Bid(agent,distance,shop,item,taskid));
		} else {
			this.failed("cnp_closed");
		}
	}
	
	@INTERNAL_OPERATION void checkDeadline(long dt){
		await_time(dt);
		if(!isClosed()){
			state = false;
			logger.info("bidding stage closed by deadline.");
		}
	}
	
	@INTERNAL_OPERATION void checkAllBids(int agents){
		while(!isClosed() && !allAgentsMadeTheirBid(agents)){
			await_time(50);
		}
		if(!isClosed()){
			state = false;
//			logger.info("bidding stage closed by all agents bids.");
		}
	}
	
	@OPERATION void getBidsJob(OpFeedbackParam<Literal[]> bidList){
		await("biddingClosed");
		int i = 0;
		Literal[] aux= new Literal[bids.size()];
		for (Bid p: bids){
			aux[i] = Literal.parseLiteral("bid("+p.getAgent()+","+p.getDistance()+")");
			i++;
		}
		bidList.set(aux);
	}
	
	@OPERATION void getBidsTask(OpFeedbackParam<Literal[]> bidList){
		await("biddingClosed");
		int i = 0;
		Literal[] aux= new Literal[bids.size()];
		for (Bid p: bids){
			aux[i] = Literal.parseLiteral("bid("+p.getAgent()+","+p.getDistance()+","+p.getShop()+","+p.getItem()+","+p.getTaskId()+")");
			i++;
		}
		bidList.set(aux);
	}
	
	@OPERATION void remove(){
		try {
			this.dispose(this.getId());
		} catch (OperationException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
	}
	
	@GUARD boolean biddingClosed(){
		return isClosed();
	}
	
	private boolean isClosed(){
		return state.equals(false);
	}
	
	private boolean allAgentsMadeTheirBid(int agents){
		 return bids.size() == agents;
	}
	
	static public class Bid {
		
		private String agent;
		private int distance;
		private String shop;
		private int taskid;
		private String item;
		
		public Bid(String agent, int distance){
			this.agent = agent;
			this.distance = distance;
		}
		
		public Bid(String agent, int distance, String shop, String item, int taskid){
			this.agent = agent;
			this.distance = distance;
			this.shop = shop;
			this.taskid = taskid;
			this.item = item;
		}
		
		public String getAgent(){ return agent; }
		public int getDistance(){ return distance; }
		public String getShop(){ return shop; }
		public int getTaskId(){ return taskid; }
		public String getItem(){ return item; }
	}
	
}
