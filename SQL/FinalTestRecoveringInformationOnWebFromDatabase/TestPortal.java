




package portal;

public class TestPortal {

   // enable this to make pretty printing a bit more compact
   private static final boolean COMPACT_OBJECTS = false;

   // This class creates a portal connection and runs a few operation

   public static void main(String[] args) {
      try{
         PortalConnection c = new PortalConnection();
   
         // Write your tests here. Add/remove calls to pause() as desired. 
         // Use println instead of prettyPrint to get more compact output (if your raw JSON is already readable)
         
         
       //student info
         prettyPrint(c.getInfo("3333333333")); 
         pause();
      
         
         //register student for unrestricted course        
         System.out.println(c.register("3333333333", "CCC222")); 
         pause();
         
       //student info
         prettyPrint(c.getInfo("3333333333")); 
         pause();
         //REGISTER AGAIN
         System.out.println(c.register("3333333333", "CCC222")); 
         pause();
         prettyPrint(c.getInfo("3333333333")); 
         pause();
         //UNREGISTER TWICE
         System.out.println(c.unregister("3333333333", "CCC222")); 
         pause();
         prettyPrint(c.getInfo("3333333333")); 
         pause();
         System.out.println(c.unregister("3333333333", "CCC222")); 
         pause();
         prettyPrint(c.getInfo("3333333333")); 
         pause();
         //course that the student dont have prerequisites for
         prettyPrint(c.getInfo("3333333333")); 
         pause();
         System.out.println(c.register("3333333333", "CCC555")); 
         pause();
         prettyPrint(c.getInfo("3333333333")); 
         pause();
         //WAITINGLIST STUDENT
         System.out.println(c.register("5555555555", "CCC222")); 
         pause();
         System.out.println(c.register("3333333333", "CCC222")); 
         pause();
         System.out.println(c.register("6666666666", "CCC222")); 
         pause();
         System.out.println(c.unregister("5555555555", "CCC222")); 
         pause();
         System.out.println(c.register("5555555555", "CCC222")); 
         pause();
         //unregister and register same student
         System.out.println(c.unregister("5555555555", "CCC222")); 
         pause();
         System.out.println(c.register("5555555555", "CCC222")); 
         pause();
         //OVERFULL COURSE
         System.out.println(c.unregister("3333333333", "CCC555")); 
         pause();
         //sql injection
         System.out.println(c.unregister("3333333333", "x' OR 'a'='a")); 
         pause();
         
         
         



      
      } catch (ClassNotFoundException e) {
         System.err.println("ERROR!\nYou do not have the Postgres JDBC driver (e.g. postgresql-42.2.8.jar) in your runtime classpath!");
      } catch (Exception e) {
         e.printStackTrace();
      }
   }
   
   
   
   public static void pause() throws Exception{
     System.out.println("PRESS ENTER");
     while(System.in.read() != '\n');
   }
   
   // This is a truly horrible and bug-riddled hack for printing JSON. 
   // It is used only to avoid relying on additional libraries.
   // If you are a student, please avert your eyes.
   public static void prettyPrint(String json){
      System.out.print("Raw JSON:");
      System.out.println(json);
      System.out.println("Pretty-printed (possibly broken):");
      
      int indent = 0;
      json = json.replaceAll("\\r?\\n", " ");
      json = json.replaceAll(" +", " "); // This might change JSON string values :(
      json = json.replaceAll(" *, *", ","); // So can this
      
      for(char c : json.toCharArray()){
        if (c == '}' || c == ']') {
          indent -= 2;
          breakline(indent); // This will break string values with } and ]
        }
        
        System.out.print(c);
        
        if (c == '[' || c == '{') {
          indent += 2;
          breakline(indent);
        } else if (c == ',' && !COMPACT_OBJECTS) 
           breakline(indent);
      }
      
      System.out.println();
   }
   
   public static void breakline(int indent){
     System.out.println();
     for(int i = 0; i < indent; i++)
       System.out.print(" ");
   }   
}
