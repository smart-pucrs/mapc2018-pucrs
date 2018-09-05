package pucrs.agentcontest2018;

import org.junit.Before;
import org.junit.Test;

import jacamo.infra.JaCaMoLauncher;
import jason.JasonException;
import massim.Server;


public class ConnectionTest_MAPC_SmartDell {

	@Before
	public void setUp() {
		new Thread(new Runnable() {
			@Override
			public void run() {
				try {
					Server.main(new String[] {"-conf", "conf/1sim2teamsConfigParis.json", "--monitor"});					
				} catch (Exception e) {
					e.printStackTrace();
				}
			}
		}).start();

		try {			
			JaCaMoLauncher.main(new String[] {"pucrs-mapc2018.jcm"});
		} catch (JasonException e) {
			System.out.println("Exception: "+e.getMessage());
			e.printStackTrace();
		}
	}

	@Test
	public void run() {
	}

}
