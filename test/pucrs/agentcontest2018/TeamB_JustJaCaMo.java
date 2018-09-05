package pucrs.agentcontest2018;

import org.junit.Before;
import org.junit.Test;

import jacamo.infra.JaCaMoLauncher;
import jason.JasonException;
import massim.Server;


public class TeamB_JustJaCaMo {

	@Before
	public void setUp() {

		try {			
			JaCaMoLauncher.main(new String[] {"pucrs-mapc_teamB.jcm"});
		} catch (JasonException e) {
			System.out.println("Exception: "+e.getMessage());
			e.printStackTrace();
		}

	}

	@Test
	public void run() {
	}

}
