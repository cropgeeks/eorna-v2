package utils.transcriptomics;

import java.io.*;
import java.util.*;


/**
 * Class for computing the percentage length of the transcripts for a given gene relative to its longest transcript.
 * Takes as input a .fai file with transcript names in col 1 and lengths in col2. 
 */
public class FindLongestTranscript
{
	
	static HashMap<String,Gene> genes = new HashMap<String,Gene>();
	
	static FindLongestTranscript findLongestTranscript = null;
	
	final static String USAGE = "java -Xmx10g utils.transcriptomics.FindLongestTranscript <.fai file>";
	
	//---------------------------------------------------------------------------------------------------------------
	
	public static void main(String[] args)
	{
		if(args.length !=1)
		{
			System.out.println("ERROR: Wrong number of arguments supplied. Usage:\n" +USAGE);
		}
		
		findLongestTranscript = new FindLongestTranscript();
		
		File faiFile = new File(args[0]);
		
		try
		{
			parseFAI(faiFile);
			findLongestTranscript();
		}
		catch (Exception e)
		{
			e.printStackTrace();
		}
		
	}
	
	//---------------------------------------------------------------------------------------------------------------
	
	private static void findLongestTranscript()
	{
		//iterate over all our genes
		for (Gene gene : genes.values())
		{
			//the transcripts should already be sorted in descending size order
			//this means the first element in the sorted set should be the longest transcript
			Transcript longestTranscript = gene.transcripts.first();	

			//print the gene name
			System.out.print(gene.name + "\t");
			//print the transcript name
			System.out.print(longestTranscript.name + "\t");
			//print the length
			System.out.print(longestTranscript.length + "\t");

			//new line
			System.out.println();				

		}		
	}

	//---------------------------------------------------------------------------------------------------------------	
	
	/**
	 * .fai file looks like this:
		MSTRG.17.8gene=MSTRG.17 1625    146868  70      71
		MSTRG.18.1gene=MSTRG.18 2200    148542  70      71
		MSTRG.6.1gene=MSTRG.6   2190    150797  70      71
		
		or like this if it's Transdecoder output:
		MSTRG.1.1gene=MSTRG.1.p1	380	156	60	61
		MSTRG.1.2gene=MSTRG.1.p1	241	701	60	61
		MSTRG.1.3gene=MSTRG.1.p1	207	1103	60	61
		MSTRG.10.1gene=MSTRG.10.p1	147	1476	60	61
		MSTRG.10.2gene=MSTRG.10.p1	147	1788	60	61
		
		We need cols 1(transcript name) and 2 (transcript length in bp).
	 */
	private static void parseFAI(File faiFile) throws Exception
	{
		//parse the FAST index file
		BufferedReader reader = new BufferedReader(new FileReader(faiFile));		
		String line = null;
		while((line=reader.readLine())!=null)
		{
			String [] tokens = line.split("\t");
			
			String transcriptName = tokens[0];
			String geneName = transcriptName.substring(0,transcriptName.indexOf("."));			
			
//			String transcriptName = tokens[0].substring(0, tokens[0].indexOf("g"));
//			String geneName = transcriptName.substring(0,transcriptName.lastIndexOf("."));
			
			int length = Integer.parseInt(tokens[1]);
			
			//check if we already have this gene in our hashmap
			Gene gene = genes.get(geneName);
			//if we don't, create a new gene object and add it to the hashmap
			if(gene == null)
			{
				gene = findLongestTranscript.new Gene();
				gene.name = geneName;
				genes.put(geneName,gene);
			}
			Transcript transcript = findLongestTranscript.new Transcript();
			transcript.length = length;
			transcript.name = transcriptName;
			gene.transcripts.add(transcript);
			
		}	

		reader.close();
	}
	
	//---------------------------------------------------------------------------------------------------------------	
	
	class Gene
	{
		public String name;
		public TreeSet<Transcript> transcripts = new TreeSet<Transcript>();
		
	}
	
	//---------------------------------------------------------------------------------------------------------------	
	
	class Transcript implements Comparable<Transcript> 
	{
		public int length;
		public boolean isLongestTranscript = false;
		public String name;

		@Override
		//returns a negative integer, zero, or a positive integer as this object is less than, equal to, or greater than the specified object
		public int compareTo(Transcript compTrans)
		{
			if(this.length < compTrans.length)
				return 1;
			else if(this.length > compTrans.length)
				return -1;
			else
				return 0;
		}		
	}
	
	//---------------------------------------------------------------------------------------------------------------	
}
