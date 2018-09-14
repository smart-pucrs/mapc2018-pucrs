package pucrs.agentcontest2018;

import java.io.File;

import org.junit.After;
import org.junit.Before;
import org.junit.Test;

import jacamo.infra.JaCaMoLauncher;
import jade.util.leap.ArrayList;
import jade.util.leap.List;
import jason.JasonException;
import massim.Server;


public class ScenarioRun1simParis {
	
	public static void main(String[] args) {
				
		ScenarioRun1simParis deletefiles = new ScenarioRun1simParis();
		deletefiles.delete(5,".log");
		
	}
	
	public void delete(long days, String fileExtension) {
		
		File currentDir = new File("");
		String path = currentDir.getAbsolutePath();	
		
		String dir1 = path+"\\logs";
		
		File folder = new File(dir1);
		
		if(folder.exists()) {
			File[] listFiles = folder.listFiles();
			long eligible = System.currentTimeMillis() - (days * 24 * 60 * 60 * 1000);
			for (File listFile: listFiles) {
				if(listFile.getName().endsWith(fileExtension) &&
						listFile.lastModified() < eligible) {
					if(!listFile.delete()) {
						System.out.println("Failed");
					}
				}
			}
		}
		
	}

	String caminho = "\\logs\\MASSim-log-2018-09-03-13-44-28.log";
	
	@Before
	public void cleanUpFolders() {
		File currentDir 	= new File("");
		String path 		= currentDir.getAbsolutePath();			
		List arrayFolders 	= new ArrayList();		
		
		File file = new File("C:\\Competition\\mapc2018-pucrs\\logs\\MASSim-log-2018-09-03-13-53-18.log");
		if(file.delete()) {
			System.out.println("File deleted");
		} else {
			System.out.println("Failed");
		}
	}
	
	@Before
	public void setUp() {

		new Thread(new Runnable() {
			@Override
			public void run() {
				try {
					
					Server.main(new String[] {"-conf", "conf/1simConfigParis.json", "--monitor"});				
					
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







