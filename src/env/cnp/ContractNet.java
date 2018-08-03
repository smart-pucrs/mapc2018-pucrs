package cnp;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.Set;
import java.util.logging.Logger;

import cartago.Artifact;
import cartago.GUARD;
import cartago.INTERNAL_OPERATION;
import cartago.OPERATION;
import cartago.OpFeedbackParam;
import cartago.OperationException;
import jason.asSyntax.ASSyntax;
import jason.asSyntax.Literal;
import jason.asSyntax.parser.ParseException;

public class ContractNet extends Artifact {	
	private Logger logger = null;
	Boolean state;
	
	private Set<String> bidders;
	private ArrayList<Literal> bids;
	
	void init(String taskDescr, long duration, int agents){
		logger = Logger.getLogger(""+this.getId());
		state = true;
		bids = new ArrayList<Literal>();
		bidders = new HashSet<String>();
		this.execInternalOp("checkDeadline", duration);
		this.execInternalOp("checkAllBids", agents);
	}
	
	@OPERATION void bid(String bid) throws ParseException{
		if (state){	
			String ag = getCurrentOpAgentId().getAgentName();
			Literal lbid = Literal.parseLiteral(bid).addTerms(ASSyntax.parseTerm(ag));
			bids.add(lbid);
		} else {
			this.failed("cnp_closed");
		}
	}
	
	@OPERATION void manyBids(Object[] bids) throws ParseException{
		if (state){	
			try {
			String ag = getCurrentOpAgentId().getAgentName();		
			for(int i=0;i<bids.length;i++) {
				logger.info(bids[i].toString());
				Literal lbid = Literal.parseLiteral(bids[i].toString()).addTerms(ASSyntax.parseTerm(ag));
				this.bids.add(lbid);
			}
			}
			catch (Exception e) {
				logger.info(e.getMessage());
			}
		} else {
			this.failed("cnp_closed");
		}
	}
	
	@OPERATION void ceaseBids(){
		bidders.add(getCurrentOpAgentId().getAgentName());
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
	
	@OPERATION void getBidsTask(OpFeedbackParam<Literal[]> bidList){
		await("biddingClosed");
		Literal[] aux= new Literal[bids.size()];
		bids.toArray(aux);
		bidList.set(aux);
	}
	
	@OPERATION void remove(){
		try {
			this.dispose(this.getId());
		} catch (OperationException e) {
			logger.info(e.getMessage());
		}
	}
	
	@GUARD boolean biddingClosed(){
		return isClosed();
	}
	
	private boolean isClosed(){
		return state.equals(false);
	}
	
	private boolean allAgentsMadeTheirBid(int agents){
		 return bidders.size() == agents;
	}
}
